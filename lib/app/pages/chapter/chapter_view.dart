import 'package:flutter/material.dart' hide View;
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../../domain/entities/paragraph.dart';
import '../../widgets/regulation_app_bar.dart';
import 'chapter_controller.dart';
import 'dart:ui';

class ChapterView extends View {
  final int regulationId;
  final int initialChapterOrderNum;

  const ChapterView({
    Key? key,
    required this.regulationId,
    required this.initialChapterOrderNum,
  }) : super(key: key);

  @override
  ChapterViewState createState() => ChapterViewState(
        ChapterController(
          regulationId: regulationId,
          initialChapterOrderNum: initialChapterOrderNum,
        ),
      );
}

class ChapterViewState extends ViewState<ChapterView, ChapterController> {
  ChapterViewState(ChapterController controller) : super(controller);

  @override
  Widget get view {
    return ControlledWidgetBuilder<ChapterController>(
      builder: (context, controller) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
              Theme.of(context).appBarTheme.toolbarHeight ?? 74.0,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
              ),
              child: RegulationAppBar(
                child: _buildAppBar(controller),
              ),
            ),
          ),
          body: _buildBody(controller),
          floatingActionButton: controller.isTTSPlaying
              ? FloatingActionButton(
                  onPressed: controller.stopTTS,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.stop, color: Colors.white),
                )
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          resizeToAvoidBottomInset: false,
        );
      },
    );
  }

  Widget _buildAppBar(ChapterController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            controller.stopTTS();
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            size: Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
          ),
        ),
        _buildPaginationWidget(controller),
        IconButton(
          onPressed: () {
            _showSearchDialog(controller);
          },
          icon: Icon(
            Icons.search,
            size: Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationWidget(ChapterController controller) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Кнопка "Предыдущая глава"
        IconButton(
          onPressed: controller.canGoPreviousChapter
              ? () => controller.goToPreviousChapter()
              : null,
          icon: Icon(
            Icons.arrow_back_ios,
            size: Theme.of(context).iconTheme.size,
            color: controller.canGoPreviousChapter
                ? Theme.of(context).iconTheme.color
                : Colors.grey,
          ),
        ),
        // Поле ввода номера главы как в оригинале
        SizedBox(
          height: 30,
          width: 30,
          child: TextFormField(
            controller: controller.pageTextController,
            onEditingComplete: () async {
              FocusScope.of(context).unfocus();
            },
            onFieldSubmitted: (value) {
              final chapterNum = int.tryParse(value);
              if (chapterNum == null) return;

              if (chapterNum > controller.totalChapters) {
                _showSnackBar(
                    '$chapterNum-ой главы не существует, глав в документе всего ${controller.totalChapters}!');
                return;
              }

              if (chapterNum < 1) {
                _showSnackBar('$chapterNum-ой главы не существует!');
                return;
              }

              controller.goToChapter(chapterNum);
            },
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).iconTheme.color),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7.0),
              ),
            ),
          ),
        ),
        // Текст "стр. из X"
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text.rich(
            TextSpan(
              text: ' стр. из ',
              style: Theme.of(context).appBarTheme.toolbarTextStyle,
              children: <InlineSpan>[
                TextSpan(
                  text: '${controller.totalChapters}',
                  style: TextStyle(
                    color:
                        Theme.of(context).appBarTheme.titleTextStyle?.color ??
                            Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Кнопка "Следующая глава"
        IconButton(
          onPressed: controller.canGoNextChapter
              ? () => controller.goToNextChapter()
              : null,
          icon: Icon(
            Icons.arrow_forward_ios,
            size: Theme.of(context).iconTheme.size,
            color: controller.canGoNextChapter
                ? Theme.of(context).iconTheme.color
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ChapterController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              controller.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: controller.loadAllChapters,
              icon: const Icon(Icons.refresh),
              label: const Text('Попробовать снова'),
            ),
          ],
        ),
      );
    }

    // PageView для листания между главами как в оригинале
    return PageView.builder(
      controller: controller.pageController,
      itemCount: controller.totalChapters,
      onPageChanged: (index) {
        controller.onPageChanged(index + 1);
      },
      itemBuilder: (context, index) {
        final chapterOrderNum = index + 1;
        return _buildChapterPage(controller, chapterOrderNum);
      },
    );
  }

  Widget _buildChapterPage(ChapterController controller, int chapterOrderNum) {
    final chapterData = controller.getChapterData(chapterOrderNum);

    if (chapterData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: chapterData['paragraphs'].length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          // Chapter header
          return Padding(
            padding: const EdgeInsets.only(top: 50.0, bottom: 20.0),
            child: Center(
              child: Text(
                chapterData['title'],
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final paragraph = chapterData['paragraphs'][index - 1] as Paragraph;
        return _buildParagraphCard(paragraph, controller);
      },
    );
  }

  Widget _buildParagraphCard(
      Paragraph paragraph, ChapterController controller) {
    return FocusedMenuHolder(
      menuItems: [
        FocusedMenuItem(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text("Редактировать"),
          onPressed: () => _showEditDialog(paragraph, controller),
          trailingIcon: Icon(
            Icons.edit,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        FocusedMenuItem(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text("Поделиться"),
          onPressed: () {
            controller.shareParagraph(paragraph);
            _showSnackBar('Параграф скопирован');
          },
          trailingIcon: Icon(
            Icons.share,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        FocusedMenuItem(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text("Прослушать"),
          onPressed: () => _showTTSBottomSheet(paragraph, controller),
          trailingIcon: Icon(
            Icons.hearing_rounded,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        FocusedMenuItem(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text("Заметки"),
          onPressed: () => _showSnackBar('Функция заметок в разработке'),
          trailingIcon: Icon(
            Icons.note_alt_outlined,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
      onPressed: () {}, // Empty onPressed for FocusedMenuHolder
      bottomBorderColor: Colors.transparent,
      openWithTap: true, // Открывать по тапу как в оригинале
      menuWidth: MediaQuery.of(context).size.width * 0.9,
      blurBackgroundColor: Theme.of(context).focusColor,
      menuOffset: 10,
      blurSize: 1,
      menuItemExtent: 60,
      child: Card(
        elevation: 0,
        color: Theme.of(context).scaffoldBackgroundColor,
        margin: EdgeInsets.zero,
        child: _buildParagraphContent(paragraph, controller),
      ),
    );
  }

  Widget _buildParagraphContent(
      Paragraph paragraph, ChapterController controller) {
    // Handle paragraph class styles like original
    switch (paragraph.paragraphClass?.toLowerCase()) {
      case 'indent':
        return const SizedBox(height: 15); // Just spacing
      default:
        break;
    }

    EdgeInsets padding;
    TextAlign? textAlign;

    switch (paragraph.paragraphClass?.toLowerCase()) {
      case 'align_right':
      case 'align_right no-indent':
        padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0);
        textAlign = TextAlign.right;
        break;
      case 'align_center':
        padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0);
        textAlign = TextAlign.center;
        break;
      default:
        padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0);
        textAlign = null;
    }

    return Container(
      alignment: Alignment.centerLeft,
      padding: padding,
      child: paragraph.isTable
          ? _buildTableContent(paragraph.content)
          : paragraph.isNft
              ? _buildNftContent(paragraph.content)
              : _buildRegularContent(paragraph, textAlign),
    );
  }

  Widget _buildRegularContent(Paragraph paragraph, TextAlign? textAlign) {
    return HtmlWidget(
      paragraph.content,
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 16.0, // Default font size, could be made configurable
          ),
      customStylesBuilder: textAlign != null
          ? (element) =>
              {'text-align': textAlign == TextAlign.right ? 'right' : 'center'}
          : null,
    );
  }

  Widget _buildTableContent(String content) {
    // For tables, use a container with border
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _parseAndDisplayTable(content),
      ),
    );
  }

  Widget _buildNftContent(String content) {
    // NFT content with special styling
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: HtmlWidget(
        content,
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _parseAndDisplayTable(String content) {
    // Basic table parsing - create a DataTable with sample data for now
    return DataTable(
      border: TableBorder.all(color: Colors.grey[300]!),
      columns: const [
        DataColumn(label: Text('Напряжение, кВ')),
        DataColumn(label: Text('Расстояние от работников, м')),
        DataColumn(label: Text('Расстояния от механизмов, м')),
      ],
      rows: [
        const DataRow(cells: [
          DataCell(Text('ВЛ до 1')),
          DataCell(Text('0,6')),
          DataCell(Text('1,0')),
        ]),
        const DataRow(cells: [
          DataCell(Text('до 1')),
          DataCell(Text('не нормируется')),
          DataCell(Text('1,0')),
        ]),
        const DataRow(cells: [
          DataCell(Text('1 - 35')),
          DataCell(Text('0,6')),
          DataCell(Text('1,0')),
        ]),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showEditDialog(Paragraph paragraph, ChapterController controller) {
    final textController = TextEditingController(text: paragraph.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Text('Редактировать параграф'),
        content: TextFormField(
          controller: textController,
          style: Theme.of(context).textTheme.bodyLarge,
          keyboardType: TextInputType.multiline,
          minLines: 2,
          maxLines: 25,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Введите текст параграфа...',
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement save edited paragraph
              // controller.saveEditedParagraph(paragraph, textController.text);
            },
            child: const Text('Сохранить'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отменить'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(ChapterController controller) {
    final searchController = TextEditingController();
    List<Paragraph> searchResults = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text('Поиск по главе'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: searchController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Введите текст для поиска...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchResults = controller.searchInCurrentChapter(value);
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (searchResults.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final paragraph = searchResults[index];
                        return ListTile(
                          title: Text(
                            paragraph.content.length > 100
                                ? '${paragraph.content.substring(0, 100)}...'
                                : paragraph.content,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            // TODO: Scroll to paragraph
                            _showSnackBar('Переход к параграфу');
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTTSBottomSheet(Paragraph paragraph, ChapterController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // TTS Controls
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Озвучивание параграфа',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  // TTS content preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      paragraph.textToSpeech ?? paragraph.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // TTS controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          controller.playTTS(paragraph);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Воспроизвести'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          controller.stopTTS();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.stop),
                        label: const Text('Остановить'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Кастомные классы для FocusedMenuHolder как в оригинале
class FocusedMenuHolder extends StatefulWidget {
  final Widget child;
  final double? menuItemExtent;
  final double? menuWidth;
  final List<FocusedMenuItem> menuItems;
  final bool? animateMenuItems;
  final BoxDecoration? menuBoxDecoration;
  final Function onPressed;
  final Duration? duration;
  final double? blurSize;
  final Color? blurBackgroundColor;
  final Color? bottomBorderColor;
  final double? bottomOffsetHeight;
  final double? menuOffset;

  /// Open with tap instead of long press.
  final bool openWithTap;

  const FocusedMenuHolder({
    Key? key,
    required this.child,
    required this.onPressed,
    required this.menuItems,
    this.duration,
    this.menuBoxDecoration,
    this.menuItemExtent,
    this.animateMenuItems,
    this.blurSize,
    this.blurBackgroundColor,
    this.menuWidth,
    this.bottomOffsetHeight,
    this.menuOffset,
    this.openWithTap = false,
    this.bottomBorderColor,
  }) : super(key: key);

  @override
  _FocusedMenuHolderState createState() => _FocusedMenuHolderState();
}

class _FocusedMenuHolderState extends State<FocusedMenuHolder> {
  GlobalKey containerKey = GlobalKey();
  Offset childOffset = const Offset(0, 0);
  Size? childSize;

  getOffset() {
    RenderBox renderBox =
        containerKey.currentContext!.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    setState(() {
      childOffset = Offset(offset.dx, offset.dy);
      childSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: containerKey,
      onTap: () async {
        widget.onPressed();
        if (widget.openWithTap) {
          await openMenu(context);
        }
      },
      onLongPress: () async {
        if (!widget.openWithTap) {
          await openMenu(context);
        }
      },
      child: widget.child,
    );
  }

  Future openMenu(BuildContext context) async {
    getOffset();
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration:
            widget.duration ?? const Duration(milliseconds: 100),
        pageBuilder: (context, animation, secondaryAnimation) {
          animation = Tween(begin: 0.0, end: 1.0).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: FocusedMenuDetails(
              itemExtent: widget.menuItemExtent,
              menuBoxDecoration: widget.menuBoxDecoration,
              bottomBorderColor: widget.bottomBorderColor,
              childOffset: childOffset,
              childSize: childSize,
              menuItems: widget.menuItems,
              blurSize: widget.blurSize,
              menuWidth: widget.menuWidth,
              blurBackgroundColor: widget.blurBackgroundColor,
              animateMenu: widget.animateMenuItems ?? true,
              bottomOffsetHeight: widget.bottomOffsetHeight ?? 0,
              menuOffset: widget.menuOffset ?? 0,
              child: widget.child,
            ),
          );
        },
        fullscreenDialog: true,
        opaque: false,
      ),
    );
  }
}

class FocusedMenuDetails extends StatelessWidget {
  final List<FocusedMenuItem> menuItems;
  final BoxDecoration? menuBoxDecoration;
  final Offset childOffset;
  final double? itemExtent;
  final Size? childSize;
  final Widget child;
  final bool animateMenu;
  final double? blurSize;
  final double? menuWidth;
  final Color? blurBackgroundColor;
  final Color? bottomBorderColor;
  final double? bottomOffsetHeight;
  final double? menuOffset;

  const FocusedMenuDetails({
    Key? key,
    required this.menuItems,
    required this.child,
    required this.childOffset,
    required this.childSize,
    required this.menuBoxDecoration,
    required this.itemExtent,
    required this.animateMenu,
    required this.blurSize,
    required this.blurBackgroundColor,
    required this.menuWidth,
    this.bottomOffsetHeight,
    this.menuOffset,
    this.bottomBorderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final maxMenuHeight = size.height * 0.45;
    final listHeight = menuItems.length * (itemExtent ?? 50.0);

    final maxMenuWidth = menuWidth ?? (size.width * 0.70);
    final menuHeight = listHeight < maxMenuHeight ? listHeight : maxMenuHeight;
    final leftOffset = (childOffset.dx + maxMenuWidth) < size.width
        ? childOffset.dx
        : (childOffset.dx - maxMenuWidth + childSize!.width);
    final topOffset = (childOffset.dy + menuHeight + childSize!.height) <
            size.height - bottomOffsetHeight!
        ? childOffset.dy + childSize!.height + menuOffset!
        : childOffset.dy - menuHeight - menuOffset!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: blurSize ?? 4, sigmaY: blurSize ?? 4),
              child: Container(
                color: (blurBackgroundColor ?? Colors.black).withOpacity(0.7),
              ),
            ),
          ),
          Positioned(
            top: topOffset,
            left: leftOffset,
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 200),
              builder: (BuildContext context, dynamic value, Widget? child) {
                return Transform.scale(
                  scale: value,
                  alignment: Alignment.center,
                  child: child,
                );
              },
              tween: Tween(begin: 0.0, end: 1.0),
              child: Container(
                width: maxMenuWidth,
                height: menuHeight,
                decoration: menuBoxDecoration ??
                    BoxDecoration(
                      color: bottomBorderColor ?? Colors.grey.shade200,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(5.0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      FocusedMenuItem item = menuItems[index];
                      Widget listItem = GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          item.onPressed();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(bottom: 1),
                          color: item.backgroundColor ?? Colors.white,
                          height: itemExtent ?? 50.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                item.title,
                                if (item.trailingIcon != null) ...[
                                  item.trailingIcon!
                                ]
                              ],
                            ),
                          ),
                        ),
                      );
                      if (animateMenu) {
                        return TweenAnimationBuilder(
                          builder: (context, dynamic value, child) {
                            return Transform(
                              transform: Matrix4.rotationX(1.5708 * value),
                              alignment: Alignment.bottomCenter,
                              child: child,
                            );
                          },
                          tween: Tween(begin: 1.0, end: 0.0),
                          duration: Duration(milliseconds: index * 200),
                          child: listItem,
                        );
                      } else {
                        return listItem;
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: childOffset.dy,
            left: childOffset.dx,
            child: AbsorbPointer(
              absorbing: true,
              child: SizedBox(
                width: childSize!.width,
                height: childSize!.height,
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FocusedMenuItem {
  Color? backgroundColor;
  Widget title;
  Icon? trailingIcon;
  Function onPressed;

  FocusedMenuItem({
    this.backgroundColor,
    required this.title,
    this.trailingIcon,
    required this.onPressed,
  });
}
