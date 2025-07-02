import 'package:flutter/material.dart' hide View;
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../domain/entities/paragraph.dart';
import '../../widgets/regulation_app_bar.dart';
import '../../utils/text_utils.dart';
import 'chapter_controller.dart';
import 'dart:ui';

class ChapterView extends View {
  final int regulationId;
  final int initialChapterOrderNum;
  final int? scrollToParagraphId;

  const ChapterView({
    Key? key,
    required this.regulationId,
    required this.initialChapterOrderNum,
    this.scrollToParagraphId,
  }) : super(key: key);

  @override
  ChapterViewState createState() => ChapterViewState(
        ChapterController(
          regulationId: regulationId,
          initialChapterOrderNum: initialChapterOrderNum,
          scrollToParagraphId: scrollToParagraphId,
        ),
      );
}

class ChapterViewState extends ViewState<ChapterView, ChapterController> {
  ChapterViewState(ChapterController controller) : super(controller);

  @override
  Widget get view {
    print('=== BUILDING CHAPTER VIEW ===');
    return ControlledWidgetBuilder<ChapterController>(
      builder: (context, controller) {
        print('=== CONTROLLED WIDGET BUILDER ===');
        print('Controller state:');
        print('  isLoading: ${controller.isLoading}');
        print('  error: ${controller.error}');
        print('  isBottomBarExpanded: ${controller.isBottomBarExpanded}');
        print('  selectedParagraph: ${controller.selectedParagraph?.id}');
        print('  lastSelectedText: "${controller.lastSelectedText}"');
        print('  currentChapterOrderNum: ${controller.currentChapterOrderNum}');

        // Listen to errors like SaveParagraphCubit listener in original
        if (controller.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorSnackBar(controller.error!);
            // Clear error after showing
          });
        }

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
          body: OrientationBuilder(
            builder: (context, orientation) {
              print('=== BUILDING BODY WITH ORIENTATION: $orientation ===');
              double height = MediaQuery.of(context).size.height;
              double bottomBarBlackHeight = orientation == Orientation.portrait
                  ? height * 0.4
                  : height * 0.6;
              double bottomBarWhiteHeight = orientation == Orientation.portrait
                  ? height * 0.32
                  : height * 0.48;

              print('Screen height: $height');
              print('Bottom bar black height: $bottomBarBlackHeight');
              print('Bottom bar white height: $bottomBarWhiteHeight');
              print(
                  'Is bottom bar expanded: ${controller.isBottomBarExpanded}');

              return Stack(
                children: [
                  _buildPageView(controller),
                  // Bottom Bar Stack like in original
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    bottom: controller.isBottomBarExpanded
                        ? 0
                        : -bottomBarBlackHeight,
                    child: SizedBox(
                      height: bottomBarBlackHeight,
                      width: MediaQuery.of(context).size.width,
                      child: Stack(
                        children: [
                          _buildBottomBarBlack(
                            controller,
                            bottomBarBlackHeight,
                            orientation == Orientation.portrait
                                ? height * 0.025
                                : height * 0.04,
                          ),
                          _buildBottomBarWhite(
                            controller,
                            bottomBarWhiteHeight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
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

  Widget _buildPageView(ChapterController controller) {
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

    return GestureDetector(
      onTap: () {
        // Close bottom bar when tapping outside
        if (controller.isBottomBarExpanded) {
          controller.collapseBottomBar();
        }
      },
      child: PageView.builder(
        controller: controller.pageController,
        itemCount: controller.totalChapters,
        onPageChanged: (index) {
          controller.onPageChanged(index + 1);
        },
        itemBuilder: (context, index) {
          final chapterOrderNum = index + 1;
          return _buildChapterPage(controller, chapterOrderNum);
        },
      ),
    );
  }

  Widget _buildChapterPage(ChapterController controller, int chapterOrderNum) {
    final chapterData = controller.getChapterData(chapterOrderNum);

    if (chapterData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get the item scroll controller for this chapter (for precise scrolling)
    final itemScrollController =
        controller.getItemScrollControllerForChapter(chapterOrderNum);

    // Calculate bottom padding based on bottom bar state
    double bottomPadding = 20.0; // Default padding
    if (controller.isBottomBarExpanded) {
      // Add extra padding when bottom bar is expanded to prevent content from being hidden
      final screenHeight = MediaQuery.of(context).size.height;
      final expandedBottomBarHeight =
          screenHeight * 0.45; // Same as in main widget
      bottomPadding += expandedBottomBarHeight;
    }

    return ScrollablePositionedList.builder(
      itemCount: chapterData['paragraphs'].length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(
                top: 50.0, bottom: 20.0, left: 20.0, right: 20.0),
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

        return Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: _buildParagraphCard(paragraph, controller),
        );
      },
      scrollDirection: Axis.vertical,
      itemScrollController: itemScrollController,
      padding: EdgeInsets.only(bottom: bottomPadding),
    );
  }

  Widget _buildParagraphCard(
      Paragraph paragraph, ChapterController controller) {
    final bool isSelected = controller.selectedParagraph?.id == paragraph.id;
    final bool hasFormatting = controller.hasFormatting(paragraph);
    final bool bottomBarExpanded = controller.isBottomBarExpanded;

    print('=== BUILDING PARAGRAPH CARD ===');
    print(
        'Paragraph ${paragraph.id}: selected=$isSelected, hasFormatting=$hasFormatting, bottomBarExpanded=$bottomBarExpanded');

    // If bottom bar is expanded or paragraph is table/NFT, don't show context menu
    if (bottomBarExpanded || paragraph.isTable || paragraph.isNft) {
      print(
          'Building paragraph WITHOUT context menu (expanded=$bottomBarExpanded, table=${paragraph.isTable}, nft=${paragraph.isNft})');
      return Card(
        elevation: 0,
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : hasFormatting
                ? Colors.yellow.withOpacity(0.1)
                : Theme.of(context).scaffoldBackgroundColor,
        margin: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: _buildParagraphContent(paragraph, controller,
              isSelectable: controller.isBottomBarExpanded),
        ),
      );
    }

    // Show context menu on tap when bottom bar is collapsed
    print('Building paragraph WITH context menu');
    return _buildParagraphWithContextMenu(
      paragraph,
      controller,
      isSelected,
      hasFormatting,
    );
  }

  Widget _buildParagraphContent(
      Paragraph paragraph, ChapterController controller,
      {bool isSelectable = false}) {
    print('Building regular content for paragraph ${paragraph.id}:');
    print('  Content: "${paragraph.content}"');
    print('  isSelectable: $isSelectable');
    print('  Has formatting: ${controller.hasFormatting(paragraph)}');
    print('  Current selectedParagraph: ${controller.selectedParagraph?.id}');
    print(
        '  Current selection: start=${controller.selectionStart}, end=${controller.selectionEnd}');
    print('  Last selected text: "${controller.lastSelectedText}"');

    // Handle paragraph class styles
    switch (paragraph.paragraphClass?.toLowerCase()) {
      case 'indent':
        return const SizedBox(height: 15);
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
              ? _buildNftContent(paragraph.content, controller)
              : _buildRegularContent(
                  paragraph, textAlign, controller, isSelectable),
    );
  }

  Widget _buildRegularContent(Paragraph paragraph, TextAlign? textAlign,
      ChapterController controller, bool isSelectable) {
    print('Building regular content for paragraph ${paragraph.id}:');
    print('  Content: "${paragraph.content}"');
    print('  isSelectable: $isSelectable');
    print('  Has formatting: ${controller.hasFormatting(paragraph)}');
    print('  Current selectedParagraph: ${controller.selectedParagraph?.id}');
    print(
        '  Current selection: start=${controller.selectionStart}, end=${controller.selectionEnd}');
    print('  Last selected text: "${controller.lastSelectedText}"');

    if (isSelectable) {
      // Use SelectableText with plain text for selection mode
      String plainText = TextUtils.parseHtmlString(paragraph.content);
      print('  Plain text for selection: "$plainText"');

      return SelectableText(
        plainText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 16.0,
            ),
        textAlign: textAlign,
        onSelectionChanged: (selection, cause) {
          print('=== TEXT SELECTION CHANGED ===');
          print('Selection: $selection');
          print('Cause: $cause');

          try {
            // Multiple safety checks
            if (selection == null) {
              print('Selection is null, returning');
              return;
            }

            if (selection.baseOffset != selection.extentOffset &&
                selection.baseOffset >= 0 &&
                selection.extentOffset >= 0) {
              int start = selection.baseOffset;
              int end = selection.extentOffset;

              // Ensure proper order
              if (start > end) {
                int temp = start;
                start = end;
                end = temp;
              }

              // Validate against actual text length with extra margin
              if (plainText.isNotEmpty &&
                  start >= 0 &&
                  start < plainText.length &&
                  end > start &&
                  end <= plainText.length) {
                print(
                    'Valid selection: start=$start, end=$end, textLength=${plainText.length}');
                print('Selected text: "${plainText.substring(start, end)}"');
                controller.setTextSelection(paragraph, start, end);
              } else {
                print(
                    'Invalid selection bounds ignored: start=$start, end=$end, textLength=${plainText.length}');
              }
            } else {
              print('No text selected or invalid offsets');
            }
          } catch (e) {
            print('Selection change error: $e');
            // Don't crash the app, just ignore the selection
          }
        },
      );
    } else {
      // Use HtmlWidget for normal display
      print('  Displaying HTML content with HtmlWidget');
      return HtmlWidget(
        paragraph.content,
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 16.0,
            ),
        customStylesBuilder: textAlign != null
            ? (element) => {
                  'text-align':
                      textAlign == TextAlign.right ? 'right' : 'center'
                }
            : null,
        onTapUrl: (url) => _handleInternalLink(url, controller),
        onErrorBuilder: (context, element, error) {
          print('HtmlWidget error: $error');
          return Text('Error displaying content: $error');
        },
      );
    }
  }

  Widget _buildTableContent(String content) {
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

  Widget _buildNftContent(String content, ChapterController controller) {
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
        onTapUrl: (url) => _handleInternalLink(url, controller),
      ),
    );
  }

  Widget _parseAndDisplayTable(String content) {
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

  // ========== BOTTOM BAR COMPONENTS (like original) ==========

  Widget _buildBottomBarBlack(
      ChapterController controller, double height, double iconSize) {
    print('=== BUILDING BOTTOM BAR BLACK ===');
    print('Height: $height, iconSize: $iconSize');
    print(
        'Controller state: expanded=${controller.isBottomBarExpanded}, selectedParagraph=${controller.selectedParagraph?.id}');

    return Positioned(
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          color: Colors.black.withOpacity(0.8),
        ),
        width: MediaQuery.of(context).size.width,
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: height * 0.2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Underline button
                  _buildBlackBarButton(
                    Icons.format_underline,
                    iconSize,
                    () async {
                      print('UNDERLINE BUTTON TAPPED!');
                      await controller.underlineText();
                      if (controller.error != null) {
                        _showErrorSnackBar(controller.error!);
                      } else {
                        _showSnackBar('Текст подчеркнут');
                      }
                    },
                  ),
                  _buildDivider(iconSize),
                  // Mark button
                  _buildBlackBarButton(
                    Icons.brush,
                    iconSize,
                    () async {
                      print('MARK BUTTON TAPPED!');
                      await controller.markText();
                      if (controller.error != null) {
                        _showErrorSnackBar(controller.error!);
                      } else {
                        _showSnackBar('Текст выделен');
                      }
                    },
                  ),
                  _buildDivider(iconSize),
                  // Clean button
                  _buildBlackBarButton(
                    Icons.cleaning_services,
                    iconSize,
                    () async {
                      print('CLEAR BUTTON TAPPED!');
                      await controller.clearFormatting();
                      if (controller.error != null) {
                        _showErrorSnackBar(controller.error!);
                      } else {
                        _showSnackBar('Форматирование очищено');
                      }
                    },
                  ),
                  _buildDivider(iconSize),
                  // Close button
                  _buildBlackBarButton(
                    Icons.close,
                    iconSize,
                    () async {
                      print('CLOSE BUTTON TAPPED!');
                      await controller.saveColors();
                      controller.collapseBottomBar();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBarWhite(ChapterController controller, double height) {
    print('=== BUILDING BOTTOM BAR WHITE ===');
    print('Height: $height');
    print(
        'Controller state: lastSelectedText="${controller.lastSelectedText}", colorsList length=${controller.colorsList.length}');

    return Positioned(
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        width: MediaQuery.of(context).size.width,
        height: height,
        child: Column(
          children: [
            SizedBox(height: height * 0.1),
            // Selected text display
            if (controller.lastSelectedText.isNotEmpty)
              _buildSelectedTextDisplay(controller, height),
            SizedBox(height: height * 0.1),
            // Colors list
            _buildColorsListView(controller, height),
            SizedBox(height: height * 0.2),
            // Color picker circle and slider
            Row(
              children: [
                SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                _buildColorPickerCircle(controller, height),
                _buildColorSlider(
                    controller, MediaQuery.of(context).size.width * 0.7),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlackBarButton(
      IconData icon, double size, VoidCallback onPressed) {
    print('=== BUILDING BLACK BAR BUTTON ===');
    print('Icon: $icon, size: $size');

    return GestureDetector(
      onTap: () {
        print('=== GESTURE DETECTOR ON TAP ===');
        print('Button with icon $icon was tapped');
        onPressed();
      },
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            icon,
            size: size * 0.5, // Reduced from 0.6 to 0.5
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(double height) {
    return Container(
      height: height,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildSelectedTextDisplay(
      ChapterController controller, double height) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Выделено: "${controller.lastSelectedText.length > 50 ? '${controller.lastSelectedText.substring(0, 50)}...' : controller.lastSelectedText}"',
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildColorsListView(ChapterController controller, double height) {
    return SizedBox(
      height: height * 0.15,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.07),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => index != controller.colorsList.length
            ? _buildColorCircle(
                Color(controller.colorsList[index]),
                index,
                controller.activeColorIndex == index,
                height,
                controller,
              )
            : _buildAddColorButton(height, controller),
        itemCount: controller.colorsList.length + 1,
        separatorBuilder: (context, index) => SizedBox(
          width: MediaQuery.of(context).size.width * 0.03,
        ),
      ),
    );
  }

  Widget _buildColorCircle(Color color, int index, bool isActive, double height,
      ChapterController controller) {
    return GestureDetector(
      onTap: () => controller.setActiveColorIndex(index),
      onLongPress: () => _showDeleteColorDialog(index, controller),
      child: Container(
        width: height * 0.15,
        height: height * 0.15,
        decoration: BoxDecoration(
          border: isActive ? Border.all(color: Colors.white) : null,
          shape: BoxShape.circle,
          color: color,
        ),
        child: isActive
            ? const Icon(
                Icons.check,
                color: Colors.white,
              )
            : Container(),
      ),
    );
  }

  Widget _buildAddColorButton(double height, ChapterController controller) {
    return GestureDetector(
      onTap: () => controller.addColor(),
      child: Container(
        width: height * 0.15,
        height: height * 0.15,
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: const Color(0xFF8d8d8d)),
          shape: BoxShape.circle,
          color: const Color(0xFFf9f9f9),
        ),
        child: const Icon(
          Icons.add,
          color: Color(0xFF8d8d8d),
        ),
      ),
    );
  }

  Widget _buildColorPickerCircle(ChapterController controller, double height) {
    return Container(
      height: height * 0.2,
      width: height * 0.2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFf2f2f2)),
      ),
      child: IconButton(
        onPressed: () => _showColorPicker(controller),
        icon: Image.asset(
          'assets/images/colors.png',
          width: height * 0.1,
          height: height * 0.1,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.palette,
            color: Theme.of(context).primaryColor,
            size: height * 0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildColorSlider(ChapterController controller, double width) {
    // Simplified color slider - in original it was more complex
    return Container(
      width: width,
      height: 15,
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: Colors.grey),
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
          ],
        ),
      ),
    );
  }

  // ========== DIALOGS AND MENUS ==========

  void _showEditDialog(Paragraph paragraph, ChapterController controller) {
    final textController = TextEditingController(
        text: TextUtils.parseHtmlString(paragraph.content));

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
            onPressed: () async {
              if (textController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                // Note: This needs to be implemented properly with saveEditedParagraph
                _showSnackBar('Параграф сохранен');
              } else {
                _showSnackBar('Текст не может быть пустым');
              }
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
                            TextUtils.parseHtmlString(paragraph.content)
                                        .length >
                                    100
                                ? '${TextUtils.parseHtmlString(paragraph.content).substring(0, 100)}...'
                                : TextUtils.parseHtmlString(paragraph.content),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          onTap: () {
                            Navigator.pop(context);
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

  void _showColorPicker(ChapterController controller) {
    final List<Color> predefinedColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите цвет'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: predefinedColors.length,
            itemBuilder: (context, index) {
              final color = predefinedColors[index];
              return GestureDetector(
                onTap: () {
                  controller.setActiveColor(color.value);
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showDeleteColorDialog(int index, ChapterController controller) {
    if (controller.colorsList.length <= 1) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Удалить цвет?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteColor(index);
            },
            child: const Text('Да'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Нет'),
          ),
        ],
      ),
    );
  }

  // ========== UTILITY METHODS ==========

  Future<void> _shareText(String text) async {
    try {
      await Share.share(text);
    } catch (e) {
      print('Share error: $e');
      try {
        await Clipboard.setData(ClipboardData(text: text));
        _showSnackBar('Текст скопирован в буфер обмена');
      } catch (clipboardError) {
        _showSnackBar('Ошибка при попытке поделиться: $e');
      }
    }
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildParagraphWithContextMenu(Paragraph paragraph,
      ChapterController controller, bool isSelected, bool hasFormatting) {
    print('=== BUILDING PARAGRAPH WITH CONTEXT MENU ===');
    print(
        'Paragraph ${paragraph.id}: selected=$isSelected, hasFormatting=$hasFormatting');

    return GestureDetector(
      onTap: () {
        print('=== PARAGRAPH TAPPED ===');
        print('Paragraph ${paragraph.id} tapped - showing context menu');
        _showParagraphContextMenu(context, paragraph, controller);
      },
      child: Card(
        elevation: 0,
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : hasFormatting
                ? Colors.yellow.withOpacity(0.1)
                : Theme.of(context).scaffoldBackgroundColor,
        margin: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: _buildParagraphContent(paragraph, controller,
              isSelectable: controller.isBottomBarExpanded),
        ),
      ),
    );
  }

  void _handleMenuAction(
      String action, Paragraph paragraph, ChapterController controller) {
    print('=== MENU ACTION CALLED ===');
    print('Action: $action');
    print('Paragraph ID: ${paragraph.id}');

    switch (action) {
      case 'edit':
        print('Opening edit dialog');
        _showEditDialog(paragraph, controller);
        break;
      case 'share':
        print('Sharing text');
        _shareText(TextUtils.parseHtmlString(paragraph.content));
        break;
      case 'listen':
        print('Opening TTS bottom sheet');
        _showTTSBottomSheet(paragraph, controller);
        break;
      case 'notes':
        print('Opening notes mode');
        controller.expandBottomBar();
        controller.selectParagraphForFormatting(paragraph);
        print('Notes mode should be active now');
        break;
    }
  }

  void _showParagraphContextMenu(
      BuildContext context, Paragraph paragraph, ChapterController controller) {
    print('=== SHOWING CONTEXT MENU ===');
    print('Paragraph ID: ${paragraph.id}');

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width * 0.1,
        MediaQuery.of(context).size.height * 0.3,
        MediaQuery.of(context).size.width * 0.1,
        MediaQuery.of(context).size.height * 0.3,
      ),
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Редактировать'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Поделиться'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'listen',
          child: ListTile(
            leading: const Icon(Icons.hearing_rounded),
            title: const Text('Прослушать'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'notes',
          child: ListTile(
            leading: const Icon(Icons.note_alt_outlined),
            title: const Text('Заметки'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      print('Context menu selection: $value');
      if (value != null) {
        _handleMenuAction(value, paragraph, controller);
      } else {
        print('Context menu cancelled');
      }
    });
  }

  void _showTTSBottomSheet(Paragraph paragraph, ChapterController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Paragraph option
            _buildTTSOption(
              context,
              icon: Icons.article_outlined,
              title: 'Абзац',
              onTap: () {
                Navigator.pop(context);
                controller.playTTS(paragraph);
              },
            ),
            _buildTTSDivider(),
            // Chapter option
            _buildTTSOption(
              context,
              icon: Icons.feed_outlined,
              title: 'Главу',
              onTap: () {
                Navigator.pop(context);
                controller.playChapterTTS();
              },
            ),
            _buildTTSDivider(),
            // Cancel option
            _buildTTSOption(
              context,
              icon: Icons.close,
              title: 'Отменить',
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTTSOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        height: 70,
        width: MediaQuery.of(context).size.width * 0.95,
        child: Row(
          children: [
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            Icon(
              icon,
              color: Theme.of(context).iconTheme.color,
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTTSDivider() {
    return Container(
      height: 1,
      width: MediaQuery.of(context).size.width * 0.95,
      color: Theme.of(context).dividerColor,
    );
  }

  Future<bool> _handleInternalLink(
      String url, ChapterController controller) async {
    print('=== INTERNAL LINK TAPPED ===');
    print('URL: $url');

    try {
      // Check for chapter#paragraphId format (like "76#340571")
      if (url.contains('#') && !url.startsWith('#')) {
        final parts = url.split('#');
        if (parts.length == 2) {
          final chapterStr = parts[0];
          final paragraphIdStr = parts[1];

          print(
              'Split URL: chapter="$chapterStr", paragraphId="$paragraphIdStr"');

          final chapterNum = int.tryParse(chapterStr);
          final paragraphId = int.tryParse(paragraphIdStr);

          if (chapterNum != null && paragraphId != null) {
            print(
                'Navigating to chapter $chapterNum, paragraph ID $paragraphId');

            // First navigate to the chapter
            controller.goToChapter(chapterNum);

            // Then scroll to the paragraph after a delay
            Future.delayed(const Duration(milliseconds: 1500), () {
              controller.goToParagraph(paragraphId);
            });

            return true; // Prevent default behavior
          }
        }
      }

      // Check if it's a simple numeric chapter reference (like "56")
      if (!url.contains('#') &&
          !url.contains('.') &&
          !url.startsWith('http') &&
          !url.startsWith('mailto:') &&
          !url.startsWith('tel:')) {
        final chapterNum = int.tryParse(url.trim());
        if (chapterNum != null &&
            chapterNum > 0 &&
            chapterNum <= controller.totalChapters) {
          print('Navigating to chapter: $chapterNum');
          controller.goToChapter(chapterNum);
          return true; // Prevent default behavior
        }
      }

      // Check if it's an anchor link (like #paragraph_123)
      if (url.startsWith('#')) {
        final anchorId = url.substring(1);
        print('Anchor link detected: $anchorId');

        // Try to extract paragraph ID from anchor
        if (anchorId.startsWith('paragraph_')) {
          final paragraphIdStr = anchorId.substring('paragraph_'.length);
          final paragraphId = int.tryParse(paragraphIdStr);
          if (paragraphId != null) {
            print('Navigating to paragraph ID: $paragraphId');
            controller.goToParagraph(paragraphId);
            return true; // Prevent default behavior
          }
        }

        // Try to handle other anchor formats
        final paragraphId = int.tryParse(anchorId);
        if (paragraphId != null) {
          print('Navigating to numeric anchor ID: $paragraphId');
          controller.goToParagraph(paragraphId);
          return true;
        }
      }

      // Handle paragraph references in various formats
      if (url.contains('п.') || url.contains('пункт') || url.contains('p.')) {
        print('Paragraph reference detected in URL: $url');

        // Try multiple regex patterns for paragraph references
        final patterns = [
          RegExp(r'п\.?\s*(\d+)\.(\d+)'), // п.1.2, п. 1.2
          RegExp(r'пункт\s*(\d+)\.(\d+)'), // пункт 1.2
          RegExp(r'p\.?\s*(\d+)\.(\d+)'), // p.1.2, p. 1.2
          RegExp(r'(\d+)\.(\d+)'), // Simple 1.2 format
        ];

        for (final regex in patterns) {
          final match = regex.firstMatch(url);
          if (match != null) {
            final chapter = int.tryParse(match.group(1) ?? '');
            final paragraph = int.tryParse(match.group(2) ?? '');
            print('Pattern matched: chapter $chapter, paragraph $paragraph');

            if (chapter != null && paragraph != null) {
              // Navigate to specific chapter
              print('Navigating to chapter $chapter');
              controller.goToChapter(chapter);
              return true;
            }
          }
        }
      }

      // Handle chapter references with text
      if (url.contains('глав') || url.contains('chapter')) {
        final chapterRegex = RegExp(r'(\d+)');
        final match = chapterRegex.firstMatch(url);
        if (match != null) {
          final chapter = int.tryParse(match.group(1) ?? '');
          if (chapter != null) {
            print('Navigating to chapter: $chapter');
            controller.goToChapter(chapter);
            return true;
          }
        }
      }

      // As a last resort, try to find paragraph by ID (for complex cases)
      final numericRegex = RegExp(r'\d+');
      final numericMatches = numericRegex.allMatches(url);
      if (numericMatches.isNotEmpty) {
        final firstNumber = int.tryParse(numericMatches.first.group(0) ?? '');
        if (firstNumber != null) {
          print('Trying numeric ID as paragraph ID: $firstNumber');
          controller.goToParagraph(firstNumber);
          return true;
        }
      }

      // For any other internal-looking links, try to handle them
      if (!url.startsWith('http') &&
          !url.startsWith('mailto:') &&
          !url.startsWith('tel:')) {
        print('Internal-looking link: $url (unhandled format)');
        return true; // Prevent default behavior
      }

      // For external links, return false to allow default handling
      print('External link, allowing default handling');
      return false;
    } catch (e) {
      print('Error handling link: $e');
      return false;
    }
  }
}
