import "package:sqflite/sqflite.dart";
import "package:path/path.dart";
import '../../domain/entities/chapter.dart';
import '../../domain/entities/regulation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    await _insertInitialData();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'poteu.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        regulationId INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        order_num INTEGER NOT NULL,
        level INTEGER NOT NULL DEFAULT 1,
        parentId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE paragraphs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        original_id INTEGER NOT NULL,
        chapter_id INTEGER NOT NULL,
        num INTEGER NOT NULL,
        content TEXT NOT NULL,
        text_to_speech TEXT,
        is_table INTEGER NOT NULL DEFAULT 0,
        is_nft INTEGER NOT NULL DEFAULT 0,
        paragraph_class TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE regulations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        lastUpdated TEXT NOT NULL,
        isDownloaded INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_chapters_regulation ON chapters(regulationId)
    ''');

    await db.execute('''
      CREATE INDEX idx_paragraphs_chapter ON paragraphs(chapter_id)
    ''');

    await db.execute('''
      CREATE VIRTUAL TABLE chapters_fts USING fts4(
        content="chapters",
        title,
        content
      )
    ''');

    await db.execute('''
      CREATE TRIGGER chapters_ai AFTER INSERT ON chapters BEGIN
        INSERT INTO chapters_fts(docid, title, content)
        VALUES (new.id, new.title, new.content);
      END
    ''');

    await db.execute('''
      CREATE TRIGGER chapters_ad AFTER DELETE ON chapters BEGIN
        DELETE FROM chapters_fts WHERE docid = old.id;
      END
    ''');

    await db.execute('''
      CREATE TRIGGER chapters_au AFTER UPDATE ON chapters BEGIN
        DELETE FROM chapters_fts WHERE docid = old.id;
        INSERT INTO chapters_fts(docid, title, content)
        VALUES (new.id, new.title, new.content);
      END
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Check which columns exist and only add missing ones
      final tableInfo = await db.rawQuery("PRAGMA table_info(chapters)");
      final existingColumns =
          tableInfo.map((row) => row['name'] as String).toSet();

      // Add missing columns one by one, checking if they exist first
      if (!existingColumns.contains('regulationId')) {
        await db
            .execute('ALTER TABLE chapters ADD COLUMN regulationId INTEGER');
      }

      if (!existingColumns.contains('order_num')) {
        await db.execute(
            'ALTER TABLE chapters ADD COLUMN order_num INTEGER DEFAULT 1');
      }

      if (!existingColumns.contains('level')) {
        await db
            .execute('ALTER TABLE chapters ADD COLUMN level INTEGER DEFAULT 1');
      }

      if (!existingColumns.contains('parentId')) {
        await db.execute('ALTER TABLE chapters ADD COLUMN parentId INTEGER');
      }

      // Create the index if it doesn't exist
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_chapters_regulation ON chapters(regulationId)
      ''');

      // Update existing chapters with default values
      await db.execute(
          'UPDATE chapters SET regulationId = 1 WHERE regulationId IS NULL');
      await db.execute(
          'UPDATE chapters SET order_num = id WHERE order_num IS NULL');
      await db.execute('UPDATE chapters SET level = 1 WHERE level IS NULL');
    }

    if (oldVersion < 3) {
      // Create paragraphs table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS paragraphs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          original_id INTEGER NOT NULL,
          chapter_id INTEGER NOT NULL,
          num INTEGER NOT NULL,
          content TEXT NOT NULL,
          text_to_speech TEXT,
          is_table INTEGER NOT NULL DEFAULT 0,
          is_nft INTEGER NOT NULL DEFAULT 0,
          paragraph_class TEXT
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_paragraphs_chapter ON paragraphs(chapter_id)
      ''');
    }

    if (oldVersion < 4) {
      // Clear and reload all data
      await db.execute('DELETE FROM paragraphs');
      await db.execute('DELETE FROM chapters');
      await db.execute('DELETE FROM regulations');

      // Force reload of initial data
      await _insertPoteuData(db);
    }
  }

  Future<void> _insertInitialData() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM regulations'),
    );

    if (count == 0) {
      await _insertPoteuData(db);
    }
  }

  Future<void> _insertPoteuData(Database db) async {
    // Insert POTEU regulation
    final regulationId = await db.insert('regulations', {
      'title': 'ПРАВИЛА ПО ОХРАНЕ ТРУДА ПРИ ЭКСПЛУАТАЦИИ ЭЛЕКТРОУСТАНОВОК',
      'description':
          'Правила по охране труда при эксплуатации электроустановок (далее - Правила) устанавливают государственные нормативные требования охраны труда при эксплуатации электроустановок.',
      'lastUpdated': DateTime.now().toIso8601String(),
      'isDownloaded': 1,
      'isFavorite': 0,
    });

    // Insert chapters with real data
    await _insertPoteuChapters(db, regulationId);
  }

  Future<void> _insertPoteuChapters(Database db, int regulationId) async {
    // Chapter 1: Общие положения
    final chapter1Id = await db.insert('chapters', {
      'regulationId': regulationId,
      'title': 'Общие положения',
      'content': 'I. Общие положения',
      'order_num': 1,
      'level': 1,
    });

    await _insertChapter1Paragraphs(db, chapter1Id);

    // Chapter 2: Требования к работникам
    final chapter2Id = await db.insert('chapters', {
      'regulationId': regulationId,
      'title':
          'Требования к работникам, допускаемым к выполнению работ в электроустановках',
      'content':
          'II. Требования к работникам, допускаемым к выполнению работ в электроустановках',
      'order_num': 2,
      'level': 1,
    });

    await _insertChapter2Paragraphs(db, chapter2Id);

    // Chapter 3: Охрана труда при осмотрах
    final chapter3Id = await db.insert('chapters', {
      'regulationId': regulationId,
      'title':
          'Охрана труда при осмотрах, оперативном обслуживании и технологическом управлении электроустановок',
      'content':
          'III. Охрана труда при осмотрах, оперативном обслуживании и технологическом управлении электроустановок',
      'order_num': 3,
      'level': 1,
    });

    await _insertChapter3Paragraphs(db, chapter3Id);

    // Chapter 4: Таблица допустимых расстояний
    final chapter4Id = await db.insert('chapters', {
      'regulationId': regulationId,
      'title':
          'Таблица N 1. Допустимые расстояния до токоведущих частей электроустановок, находящихся под напряжением',
      'content':
          'Таблица N 1. Допустимые расстояния до токоведущих частей электроустановок, находящихся под напряжением',
      'order_num': 4,
      'level': 1,
    });

    await _insertChapter4Paragraphs(db, chapter4Id);

    // Chapter 5: Охрана труда при производстве работ
    final chapter5Id = await db.insert('chapters', {
      'regulationId': regulationId,
      'title':
          'Охрана труда при производстве работ в действующих электроустановках',
      'content':
          'IV. Охрана труда при производстве работ в действующих электроустановках',
      'order_num': 5,
      'level': 1,
    });

    await _insertChapter5Paragraphs(db, chapter5Id);

    // Chapter 6: Организационные мероприятия
    final chapter6Id = await db.insert('chapters', {
      'regulationId': regulationId,
      'title':
          'Организационные мероприятия по обеспечению безопасного проведения работ в электроустановках',
      'content':
          'V. Организационные мероприятия по обеспечению безопасного проведения работ в электроустановках',
      'order_num': 6,
      'level': 1,
    });

    await _insertChapter6Paragraphs(db, chapter6Id);
  }

  Future<void> _insertChapter1Paragraphs(Database db, int chapterId) async {
    final paragraphs = [
      {
        'original_id': 334350,
        'num': 2,
        'content':
            '1.1. Правила по охране труда при эксплуатации электроустановок (далее - Правила) устанавливают государственные нормативные требования охраны труда при эксплуатации электроустановок.',
        'text_to_speech':
            '1.1. Правила по охране труда при эксплуатации электроустановок (далее - Правила) устанавливают государственные нормативные требования охраны труда при эксплуатации электроустановок.',
      },
      {
        'original_id': 334352,
        'num': 3,
        'content':
            'Требования Правил распространяются на работодателей - юридических и физических лиц независимо от их организационно-правовых форм и работников из числа электротехнического, электротехнологического и неэлектротехнического персонала организаций (далее - работники), занятых техническим обслуживанием электроустановок, проводящих в них оперативные переключения, организующих и выполняющих строительные, монтажные, наладочные, ремонтные работы, испытания и измерения, в том числе работы с приборами учета электроэнергии, измерительными приборами и средствами автоматики, а также осуществляющих управление технологическими режимами работы объектов электроэнергетики и энергопринимающих установок потребителей.',
        'text_to_speech':
            'Требования Правил распространяются на работодателей - юридических и физических лиц независимо от их организационно-правовых форм и работников из числа электротехнического, электротехнологического и неэлектротехнического персонала организаций.',
      },
      {
        'original_id': 334356,
        'num': 5,
        'content':
            '1.2. Обязанности по обеспечению безопасных условий и охраны труда возлагаются на работодателя.',
        'text_to_speech':
            '1.2. Обязанности по обеспечению безопасных условий и охраны труда возлагаются на работодателя.',
      },
      {
        'original_id': 334365,
        'num': 9,
        'content':
            '1.3. Машины, аппараты, линии и вспомогательное оборудование (вместе с сооружениями и помещениями, в которых они установлены), предназначенные для производства, преобразования, трансформации, передачи, распределения электрической энергии и преобразования ее в другой вид энергии (далее - электроустановки) должны находиться в технически исправном состоянии, обеспечивающем безопасные условия труда.',
        'text_to_speech':
            '1.3. Машины, аппараты, линии и вспомогательное оборудование должны находиться в технически исправном состоянии, обеспечивающем безопасные условия труда.',
      },
    ];

    for (final paragraph in paragraphs) {
      await db.insert('paragraphs', {
        'original_id': paragraph['original_id'],
        'chapter_id': chapterId,
        'num': paragraph['num'],
        'content': paragraph['content'],
        'text_to_speech': paragraph['text_to_speech'],
        'is_table': 0,
        'is_nft': 0,
        'paragraph_class': '',
      });
    }
  }

  Future<void> _insertChapter2Paragraphs(Database db, int chapterId) async {
    final paragraphs = [
      {
        'original_id': 334374,
        'num': 1,
        'content':
            '2.1. Работники обязаны проходить обучение безопасным методам и приемам выполнения работ в электроустановках.',
        'text_to_speech':
            '2.1. Работники обязаны проходить обучение безопасным методам и приемам выполнения работ в электроустановках.',
      },
      {
        'original_id': 334376,
        'num': 2,
        'content':
            '2.2. Работники должны проходить обучение по оказанию первой помощи пострадавшему на производстве до допуска к самостоятельной работе.',
        'text_to_speech':
            '2.2. Работники должны проходить обучение по оказанию первой помощи пострадавшему на производстве до допуска к самостоятельной работе.',
      },
      {
        'original_id': 334381,
        'num': 4,
        'content':
            '2.3. Работники, относящиеся к электротехническому персоналу и электротехнологическому персоналу, а также должностные лица, осуществляющие контроль и надзор за соблюдением требований безопасности при эксплуатации электроустановок, специалисты по охране труда, контролирующие электроустановки, должны пройти проверку знаний требований Правил и других требований безопасности, предъявляемых к организации и выполнению работ в электроустановках в пределах требований, предъявляемых к соответствующей должности или профессии, и иметь соответствующую группу по электробезопасности.',
        'text_to_speech':
            '2.3. Работники, относящиеся к электротехническому персоналу и электротехнологическому персоналу, должны пройти проверку знаний требований Правил.',
      },
      {
        'original_id': 334387,
        'num': 7,
        'content':
            'Группа I по электробезопасности присваивается неэлектротехническому персоналу. Перечень должностей, рабочих мест, на которых для выполнения работы необходимо присвоение работникам группы I по электробезопасности, определяет руководитель организации. Присвоение группы I по электробезопасности производится путем проведения инструктажа, который должен завершаться проверкой знаний в форме устного опроса.',
        'text_to_speech':
            'Группа 1 по электробезопасности присваивается неэлектротехническому персоналу.',
      },
    ];

    for (final paragraph in paragraphs) {
      await db.insert('paragraphs', {
        'original_id': paragraph['original_id'],
        'chapter_id': chapterId,
        'num': paragraph['num'],
        'content': paragraph['content'],
        'text_to_speech': paragraph['text_to_speech'],
        'is_table': 0,
        'is_nft': 0,
        'paragraph_class': '',
      });
    }
  }

  Future<void> _insertChapter3Paragraphs(Database db, int chapterId) async {
    final paragraphs = [
      {
        'original_id': 334530,
        'num': 1,
        'content':
            '3.1. Оперативное обслуживание электроустановок должны выполнять работники субъекта электроэнергетики (потребителя электрической энергии), из числа оперативного и оперативно-ремонтного персонала, а также работники из числа административно-технического персонала в случаях предоставления соответствующих прав оперативного (оперативно-ремонтного) персонала, имеющие V группу по электробезопасности при эксплуатации электроустановок напряжением выше 1000 В, IV группу по электробезопасности при эксплуатации электроустановок напряжением до 1000 В.',
        'text_to_speech':
            '3.1. Оперативное обслуживание электроустановок должны выполнять работники субъекта электроэнергетики из числа оперативного и оперативно-ремонтного персонала.',
      },
      {
        'original_id': 334534,
        'num': 4,
        'content':
            '3.2. В электроустановках напряжением выше 1000 В работники из числа оперативного персонала, единолично обслуживающие электроустановки, и старшие по смене должны иметь группу по электробезопасности не ниже IV, остальные работники в смене - группу не ниже III.',
        'text_to_speech':
            '3.2. В электроустановках напряжением выше 1000 В работники из числа оперативного персонала должны иметь группу по электробезопасности не ниже 4.',
      },
      {
        'original_id': 334538,
        'num': 6,
        'content':
            '3.3. При осмотрах электроустановок, перемещении техники и грузов не допускается приближение людей, механизмов и подъемных сооружений к находящимся под напряжением неогражденным или неизолированным токоведущим частям на расстояния менее указанных в таблице N 1.',
        'text_to_speech':
            '3.3. При осмотрах электроустановок не допускается приближение людей, механизмов и подъемных сооружений к находящимся под напряжением токоведущим частям на расстояния менее указанных в таблице N 1.',
      },
    ];

    for (final paragraph in paragraphs) {
      await db.insert('paragraphs', {
        'original_id': paragraph['original_id'],
        'chapter_id': chapterId,
        'num': paragraph['num'],
        'content': paragraph['content'],
        'text_to_speech': paragraph['text_to_speech'],
        'is_table': 0,
        'is_nft': 0,
        'paragraph_class': '',
      });
    }
  }

  Future<void> _insertChapter4Paragraphs(Database db, int chapterId) async {
    final paragraphs = [
      {
        'original_id': 334541,
        'num': 1,
        'content': 'Таблица N 1',
        'text_to_speech': 'Таблица N 1',
      },
      {
        'original_id': 334543,
        'num': 2,
        'content':
            'Допустимые расстояния до токоведущих частей электроустановок, находящихся под напряжением',
        'text_to_speech':
            'Допустимые расстояния до токоведущих частей электроустановок, находящихся под напряжением',
      },
      {
        'original_id': 334628,
        'num': 3,
        'content': '''<table>
<tr><td>Напряжение электроустановок, кВ</td><td>Расстояние от работников, м</td><td>Расстояния от механизмов, м</td></tr>
<tr><td>ВЛ до 1</td><td>0,6</td><td>1,0</td></tr>
<tr><td>до 1</td><td>не нормируется</td><td>1,0</td></tr>
<tr><td>1 - 35</td><td>0,6</td><td>1,0</td></tr>
<tr><td>60 - 110</td><td>1,0</td><td>1,5</td></tr>
<tr><td>150</td><td>1,5</td><td>2,0</td></tr>
<tr><td>220</td><td>2,0</td><td>2,5</td></tr>
<tr><td>330</td><td>2,5</td><td>3,5</td></tr>
<tr><td>400 - 500</td><td>3,5</td><td>4,5</td></tr>
<tr><td>750</td><td>5,0</td><td>6,0</td></tr>
<tr><td>1150</td><td>8,0</td><td>10,0</td></tr>
</table>''',
        'text_to_speech':
            'Таблица допустимых расстояний до токоведущих частей электроустановок',
      },
    ];

    for (final paragraph in paragraphs) {
      await db.insert('paragraphs', {
        'original_id': paragraph['original_id'],
        'chapter_id': chapterId,
        'num': paragraph['num'],
        'content': paragraph['content'],
        'text_to_speech': paragraph['text_to_speech'],
        'is_table': paragraph['num'] == 3 ? 1 : 0,
        'is_nft': 0,
        'paragraph_class': paragraph['num'] == 3 ? 'doc-table' : '',
      });
    }
  }

  Future<void> _insertChapter5Paragraphs(Database db, int chapterId) async {
    final paragraphs = [
      {
        'original_id': 334712,
        'num': 1,
        'content':
            '4.1. Работы в действующих электроустановках должны проводиться:',
        'text_to_speech':
            '4.1. Работы в действующих электроустановках должны проводиться:',
      },
      {
        'original_id': 334714,
        'num': 2,
        'content':
            'по заданию на производство работы, определяющему содержание, место работы, время ее начала и окончания, условия безопасного проведения, состав бригады и работников, ответственных за безопасное выполнение работы (далее - наряд-допуск);',
        'text_to_speech':
            'по заданию на производство работы, определяющему содержание, место работы, время ее начала и окончания (далее - наряд-допуск);',
      },
      {
        'original_id': 334732,
        'num': 11,
        'content':
            '4.5. В электроустановках напряжением до 1000 В при работе под напряжением необходимо: снять напряжение с расположенных вблизи рабочего места других токоведущих частей; работать в диэлектрических галошах или стоя на изолирующей подставке; применять изолированный или изолирующий инструмент и пользоваться диэлектрическими перчатками.',
        'text_to_speech':
            '4.5. В электроустановках напряжением до 1000 В при работе под напряжением необходимо применять средства защиты.',
      },
      {
        'original_id': 334767,
        'num': 27,
        'content':
            '4.13. Работники, работающие в помещениях с электрооборудованием, в ЗРУ и ОРУ, в подземных сооружениях, колодцах, туннелях, траншеях и котлованах, а также участвующие в обслуживании и ремонте ВЛ, должны пользоваться защитными касками.',
        'text_to_speech':
            '4.13. Работники должны пользоваться защитными касками.',
      },
    ];

    for (final paragraph in paragraphs) {
      await db.insert('paragraphs', {
        'original_id': paragraph['original_id'],
        'chapter_id': chapterId,
        'num': paragraph['num'],
        'content': paragraph['content'],
        'text_to_speech': paragraph['text_to_speech'],
        'is_table': 0,
        'is_nft': 0,
        'paragraph_class': '',
      });
    }
  }

  Future<void> _insertChapter6Paragraphs(Database db, int chapterId) async {
    final paragraphs = [
      {
        'original_id': 334802,
        'num': 1,
        'content':
            '5.1. Организационными мероприятиями, обеспечивающими безопасность работ в электроустановках, являются:',
        'text_to_speech':
            '5.1. Организационными мероприятиями, обеспечивающими безопасность работ в электроустановках, являются:',
      },
      {
        'original_id': 334804,
        'num': 2,
        'content':
            'оформление работ нарядом-допуском, распоряжением или перечнем работ, выполняемых в порядке текущей эксплуатации;',
        'text_to_speech':
            'оформление работ нарядом-допуском, распоряжением или перечнем работ, выполняемых в порядке текущей эксплуатации;',
      },
      {
        'original_id': 334813,
        'num': 6,
        'content':
            '5.2. Работниками, ответственными за безопасное ведение работ в электроустановках, являются: выдающий наряд-допуск, ответственный руководитель работ, допускающий, производитель работ, наблюдающий, члены бригады.',
        'text_to_speech':
            '5.2. Работниками, ответственными за безопасное ведение работ в электроустановках, являются: выдающий наряд-допуск, ответственный руководитель работ, допускающий, производитель работ.',
      },
    ];

    for (final paragraph in paragraphs) {
      await db.insert('paragraphs', {
        'original_id': paragraph['original_id'],
        'chapter_id': chapterId,
        'num': paragraph['num'],
        'content': paragraph['content'],
        'text_to_speech': paragraph['text_to_speech'],
        'is_table': 0,
        'is_nft': 0,
        'paragraph_class': '',
      });
    }
  }

  Future<List<Regulation>> getRegulations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('regulations');
    return Future.wait(maps.map((map) async {
      final chapters = await getChapters(map['id']);
      return Regulation(
        id: map['id'],
        title: map['title'],
        description: map['description'],
        lastUpdated: DateTime.parse(map['lastUpdated']),
        isDownloaded: map['isDownloaded'] == 1,
        isFavorite: map['isFavorite'] == 1,
        chapters: chapters,
      );
    }).toList());
  }

  Future<Chapter> getChapter(int chapterId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      where: 'id = ?',
      whereArgs: [chapterId],
    );
    if (maps.isEmpty) {
      throw Exception('Chapter not found');
    }
    return Chapter(
      id: maps[0]['id'],
      regulationId: maps[0]['regulationId'],
      title: maps[0]['title'],
      content: maps[0]['content'],
      level: maps[0]['level'],
    );
  }

  Future<List<Chapter>> getChapters(int regulationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      where: 'regulationId = ?',
      whereArgs: [regulationId],
      orderBy: 'level ASC',
    );
    return maps
        .map((map) => Chapter(
              id: map['id'],
              regulationId: map['regulationId'],
              title: map['title'],
              content: map['content'],
              level: map['level'],
            ))
        .toList();
  }

  Future<List<Chapter>> searchChapters(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.*
      FROM chapters c
      INNER JOIN chapters_fts f ON c.id = f.docid
      WHERE chapters_fts MATCH ?
      ORDER BY docid
    ''', [query]);
    return maps
        .map((map) => Chapter(
              id: map['id'],
              regulationId: map['regulationId'],
              title: map['title'],
              content: map['content'],
              level: map['level'],
            ))
        .toList();
  }

  Future<void> toggleFavorite(int regulationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'regulations',
      columns: ['isFavorite'],
      where: 'id = ?',
      whereArgs: [regulationId],
    );
    if (maps.isEmpty) {
      throw Exception('Regulation not found');
    }
    final currentValue = maps[0]['isFavorite'] as int;
    await db.update(
      'regulations',
      {'isFavorite': currentValue == 0 ? 1 : 0},
      where: 'id = ?',
      whereArgs: [regulationId],
    );
  }

  Future<void> downloadRegulation(int regulationId) async {
    final db = await database;
    await db.update(
      'regulations',
      {'isDownloaded': 1},
      where: 'id = ?',
      whereArgs: [regulationId],
    );
  }

  Future<void> deleteRegulation(int regulationId) async {
    final db = await database;
    await db.delete(
      'regulations',
      where: 'id = ?',
      whereArgs: [regulationId],
    );
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<List<Map<String, dynamic>>> getParagraphs(int chapterId) async {
    final db = await database;
    final result = await db.query(
      'paragraphs',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      orderBy: 'num ASC',
    );
    return result;
  }

  Future<Map<String, dynamic>?> getParagraph(int paragraphId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'paragraphs',
      where: 'id = ?',
      whereArgs: [paragraphId],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<List<Map<String, dynamic>>> searchParagraphs(String query) async {
    final db = await database;
    return await db.query(
      'paragraphs',
      where: 'content LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'chapter_id, num ASC',
    );
  }

  Future<int> getParagraphsCount(int chapterId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
          'SELECT COUNT(*) FROM paragraphs WHERE chapter_id = ?', [chapterId]),
    );
    return count ?? 0;
  }
}
