### **Чеклист: Добавление нового приложения (флейвора)**

Предположим, вы добавляете новое приложение с техническим именем флейвора **`new_doc`**.

#### **Подготовка (0-й шаг)**

Прежде чем трогать код, подготовьте все необходимое:
1.  **Техническое имя флейвора:** Короткое, на английском, в нижнем регистре (например, `new_doc`).
2.  **Имя приложения для пользователя:** Как оно будет отображаться на устройстве (например, `"Новый Документ 123"`).
3.  **Имя пакета (Application ID):** Уникальное для Google Play (например, `com.i_rm.new_doc`).
4.  **Файл базы данных:** Готовый `regulations.duckdb` для нового документа.
5.  **Иконки:** Набор иконок в папках `mipmap-*`.
6.  **Уникальный `regulationId`:** Узнайте, какой `id` у вашего нового документа в таблице `rules` внутри его базы данных.

---

#### **Шаг 1: Файлы и папки проекта**

1.  **Добавить базу данных:**
    *   Создайте папку: `assets/new_doc/data/`
    *   Положите в нее ваш новый файл `regulations.duckdb`.

2.  **Добавить иконки:**
    *   Создайте папку: `android/app/src/new_doc/res/`
    *   Скопируйте в нее ваши папки с иконками (`mipmap-hdpi`, `mipmap-mdpi` и т.д.).

3.  **Зарегистрировать ассеты:**
    *   Откройте `pubspec.yaml`.
    *   В секцию `assets:` добавьте новый путь:
        ```yaml
        assets:
          - assets/poteu/data/
          - assets/height_rules/data/
          - assets/pteep/data/
          - assets/new_doc/data/ # <-- ВАША НОВАЯ СТРОКА
        ```

---

#### **Шаг 2: Конфигурация Android (Gradle)**

1.  **Указать версию:**
    *   Откройте `android/versions.properties`.
    *   Добавьте две новые строки для версий вашего приложения:
        ```properties
        # Версии для нового документа
        NEW_DOC_VERSION_CODE=1
        NEW_DOC_VERSION_NAME=1.0.0
        ```

2.  **Определить флейвор:**
    *   Откройте `android/app/build.gradle.kts`.
    *   Внутри блока `productFlavors { ... }` скопируйте существующий флейвор и измените его для нового приложения:
        ```kotlin
        create("new_doc") { // <-- Техническое имя
            dimension = "default"
            applicationId = "com.i_rm.new_doc" // <-- Уникальное имя пакета
            resValue("string", "app_name", "Новый Документ 123") // <-- Имя для пользователя
            
            // Ссылки на версии из versions.properties
            versionCode = versionsProperties["NEW_DOC_VERSION_CODE"].toString().toInt()
            versionName = versionsProperties["NEW_DOC_VERSION_NAME"] as String
        }
        ```

---

#### **Шаг 3: Конфигурация Flutter (Dart-код)**

1.  **Научить приложение "знать" о новом флейворе:**
    *   Откройте `lib/config.dart`.
    *   В методе `initialize` добавьте новый блок `else if`:
        ```dart
        } else if (flavor == 'new_doc') { // <-- Техническое имя
          dbPath = 'assets/new_doc/data/regulations.duckdb'; // <-- Путь к БД
          name = 'Новый Документ 123'; // <-- Имя для заголовков в приложении
          regulationId = 4; // <-- ВАЖНО: Уникальный ID из таблицы `rules`
        }
        ```

---

#### **Шаг 4: Настройка среды разработки (IDE)**

1.  **Добавить конфигурацию запуска:**
    *   Откройте `.vscode/launch.json`.
    *   Скопируйте существующую конфигурацию и измените ее для нового флейвора:
        ```json
        {
            "name": "Новый Документ (new_doc)", // <-- Имя для списка в IDE
            "request": "launch",
            "type": "dart",
            "flutterMode": "debug",
            "args": [
                "--flavor",
                "new_doc" // <-- Техническое имя
            ]
        }
        ```

---

#### **Шаг 5: Сборка и релиз**

1.  **Запуск для отладки:**
    *   Выберите `"Новый Документ (new_doc)"` в вашем редакторе и нажмите `F5`.

2.  **Сборка для Google Play:**
    *   Выполните в терминале:
        ```bash
        flutter build appbundle --flavor new_doc
        ```
    *   Ваш файл будет лежать здесь: `build/app/outputs/bundle/new_docRelease/app-new_doc-release.aab`.

---

### **Финальная проверка**

Перед сборкой быстро проверьте, что вы использовали **одно и то же техническое имя** (`new_doc` в нашем примере) в **пяти** ключевых местах:
1.  Имя папки в `assets/` -> (`new_doc`)
2.  Имя папки в `android/app/src/` -> (`new_doc`)
3.  Имя флейвора в `build.gradle.kts` -> (`create("new_doc")`)
4.  Условие в `lib/config.dart` -> (`if (flavor == 'new_doc')`)
5.  Аргумент в `launch.json` и команде сборки -> (`--flavor new_doc`)

Если все совпадает, все будет работать как часы.