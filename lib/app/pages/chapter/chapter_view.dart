import 'dart:developer' as dev;
import 'dart:async';
import 'package:flutter/material.dart' hide View;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../domain/entities/paragraph.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../widgets/regulation_app_bar.dart';

import '../../utils/text_utils.dart';
import 'chapter_controller.dart';

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

class ChapterView extends View {
  final int regulationId;
  final int initialChapterOrderNum;
  final int? scrollToParagraphId;
  final SettingsRepository settingsRepository;
  final TTSRepository ttsRepository;
  final RegulationRepository regulationRepository;

  const ChapterView({
    Key? key,
    required this.regulationId,
    required this.initialChapterOrderNum,
    required this.settingsRepository,
    required this.ttsRepository,
    required this.regulationRepository,
    this.scrollToParagraphId,
  }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  ChapterViewState createState() => ChapterViewState(
        ChapterController(
          regulationId: regulationId,
          initialChapterOrderNum: initialChapterOrderNum,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
          regulationRepository: regulationRepository,
          scrollToParagraphId: scrollToParagraphId,
        ),
      );
}

class ChapterViewState extends ViewState<ChapterView, ChapterController> {
  ChapterViewState(ChapterController controller) : super(controller);

  String _removeInvalidLinks(String html) {
    if (html.isEmpty) return '';

    final document = html_parser.parseFragment(html);
    final isValidHref = RegExp(r'^\d+(?:/\d+)*$'); // только цифры и '/'

    for (final a in document.querySelectorAll('a').toList()) {
      final href = a.attributes['href'];
      final isValid = href != null && isValidHref.hasMatch(href);

      if (!isValid) {
        // Заменяем <a> на <span>, переносим детей и базовые стили, чтобы текст остался
        final replacement = dom.Element.tag('span');

        final classAttr = a.attributes['class'];
        if (classAttr != null && classAttr.isNotEmpty) {
          replacement.attributes['class'] = classAttr;
        }
        final styleAttr = a.attributes['style'];
        if (styleAttr != null && styleAttr.isNotEmpty) {
          replacement.attributes['style'] = styleAttr;
        }

        replacement.nodes.addAll(a.nodes.toList());
        a.replaceWith(replacement);
      }
    }

    return document.outerHtml;
  }

  @override
  Widget get view {
    return ControlledWidgetBuilder<ChapterController>(
      builder: (context, controller) {
        // Listen to errors like SaveParagraphCubit listener in original
        if (controller.error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showErrorSnackBar(controller.error!);
            // Clear error after showing
          });
        }

        return Theme(
          data: Theme.of(context),
          child: Scaffold(
            key: globalKey,
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
                double height = MediaQuery.of(context).size.height;
                double bottomBarBlackHeight =
                    orientation == Orientation.portrait
                        ? height * 0.4
                        : height * 0.6;
                double bottomBarWhiteHeight =
                    orientation == Orientation.portrait
                        ? height * 0.32
                        : height * 0.48;

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
            floatingActionButton: controller.isTTSActive
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (controller.isTTSPlaying) ...[
                        // Pause button when playing
                        FloatingActionButton(
                          onPressed: controller.pauseTTS,
                          backgroundColor: Theme.of(context).primaryColor,
                          heroTag: "pause",
                          child: const Icon(Icons.pause, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        // Stop button when playing
                        FloatingActionButton(
                          onPressed: controller.stopTTS,
                          backgroundColor: Colors.red,
                          heroTag: "stop",
                          child: const Icon(Icons.stop, color: Colors.white),
                        ),
                      ] else if (controller.isTTSPaused) ...[
                        // Resume button when paused
                        FloatingActionButton(
                          onPressed: controller.resumeTTS,
                          backgroundColor: Colors.green,
                          heroTag: "resume",
                          child:
                              const Icon(Icons.play_arrow, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        // Stop button when paused
                        FloatingActionButton(
                          onPressed: controller.stopTTS,
                          backgroundColor: Colors.red,
                          heroTag: "stop",
                          child: const Icon(Icons.stop, color: Colors.white),
                        ),
                      ],
                    ],
                  )
                : null,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            resizeToAvoidBottomInset: false,
          ),
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
                ? Theme.of(context).appBarTheme.iconTheme?.color
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
            style: TextStyle(
                color: Theme.of(context).appBarTheme.titleTextStyle?.color),
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
                    color: Theme.of(context).appBarTheme.titleTextStyle?.color,
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
                ? Theme.of(context).appBarTheme.iconTheme?.color
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

    if (controller.loadingError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            // Text(
            //   controller.loadingError!,
            //   textAlign: TextAlign.center,
            //   style: Theme.of(context).textTheme.bodyMedium,
            // ),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Загрузка главы $chapterOrderNum...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
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
                top: 20.0, bottom: 20.0, left: 20.0, right: 20.0),
            child: Center(
              child: Text(
                chapterData['num'] != null && chapterData['num'] != ''
                    ? '${chapterData['num']}. ${chapterData['title']}'
                    : chapterData['title'],
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize:
                          Theme.of(context).textTheme.displayLarge?.fontSize ??
                              20,
                    ),
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
    final bool isCurrentTTSParagraph =
        controller.currentTTSParagraph?.id == paragraph.id;

    // Debug info for TTS highlighting - только если есть TTS параграф
    if (controller.currentTTSParagraph != null && isCurrentTTSParagraph) {
      dev.log('🎵 UI: TTS highlighting paragraph ${paragraph.id}');
    }

    // If bottom bar is expanded or paragraph is table/NFT, don't show context menu
    if (bottomBarExpanded || paragraph.isTable || paragraph.isNft) {
      Color cardColor;
      BoxDecoration? decoration;

      if (isCurrentTTSParagraph) {
        cardColor = Colors.green
            .withAlpha((255 * 0.2).round()); // Приятный зелёный цвет для TTS
        decoration = BoxDecoration(
          border: Border.all(color: Colors.green, width: 3), // Зелёная рамка
          borderRadius: BorderRadius.circular(4),
        );
      } else if (isSelected) {
        cardColor =
            Theme.of(context).primaryColor.withAlpha((255 * 0.1).round());
        decoration = BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
          borderRadius: BorderRadius.circular(4),
        );
      } else if (hasFormatting) {
        cardColor = Colors.yellow.withAlpha((255 * 0.1).round());
        decoration = BoxDecoration(borderRadius: BorderRadius.circular(4));
      } else {
        cardColor = Theme.of(context).scaffoldBackgroundColor;
        decoration = BoxDecoration(borderRadius: BorderRadius.circular(4));
      }

      return Card(
        elevation: 0,
        color: cardColor,
        margin: EdgeInsets.zero,
        child: Container(
          decoration: decoration,
          child: _buildParagraphContent(paragraph, controller,
              isSelectable: controller.isBottomBarExpanded),
        ),
      );
    }

    // Show context menu on tap when bottom bar is collapsed
    return _buildParagraphWithContextMenu(
      paragraph,
      controller,
      isSelected,
      hasFormatting,
      isCurrentTTSParagraph,
    );
  }

  Widget _buildParagraphContent(
      Paragraph paragraph, ChapterController controller,
      {bool isSelectable = false}) {
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

    final bool isCurrentTTSParagraph =
        controller.currentTTSParagraph?.id == paragraph.id;

    Widget content = paragraph.isTable
        ? _buildTableContent(paragraph.content)
        : paragraph.isNft
            ? _buildNftContent(paragraph.content, controller)
            : _buildRegularContent(
                paragraph, textAlign, controller, isSelectable);

    // Determine container alignment based on text alignment
    Alignment containerAlignment;
    switch (textAlign) {
      case TextAlign.right:
        containerAlignment = Alignment.centerRight;
        break;
      case TextAlign.center:
        containerAlignment = Alignment.center;
        break;
      default:
        containerAlignment = Alignment.centerLeft;
    }

    return Container(
      alignment: containerAlignment,
      padding: padding,
      child: isCurrentTTSParagraph && !paragraph.isTable && !paragraph.isNft
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TTS indicator icon
                Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 2.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green, // Зелёный цвет для TTS иконки
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4.0),
                    child: const Icon(
                      Icons.volume_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Paragraph content
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  Widget _buildRegularContent(Paragraph paragraph, TextAlign? textAlign,
      ChapterController controller, bool isSelectable) {
    if (isSelectable) {
      // Use SelectableText with plain text for selection mode.

      String plainText = TextUtils.parseHtmlString(paragraph.content);

      return SelectableText(
        plainText,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: textAlign,
        onSelectionChanged: (selection, cause) {
          try {
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
                controller.setTextSelection(paragraph, start, end);
              }
            }
          } catch (e) {
            // Don't crash the app, just ignore the selection
          }
        },
      );
    } else {
      // Use HtmlWidget for normal display
      return HtmlWidget(
        _removeInvalidLinks(paragraph.content),
        textStyle: Theme.of(context).textTheme.bodyMedium,
        customStylesBuilder: textAlign != null
            ? (element) => {
                  'text-align':
                      textAlign == TextAlign.right ? 'right' : 'center'
                }
            : null,
        onTapUrl: (url) => _handleInternalLink(url, controller),
        onErrorBuilder: (context, element, error) {
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: _parseAndDisplayTable(content),
        ),
      ),
    );
  }

  Widget _buildNftContent(String content, ChapterController controller) {
    if (content == '\n') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        // borderRadius: BorderRadius.circular(8),
        // border: Border.all(
        //   color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        // ),
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
    try {
      // Parse HTML table using HtmlWidget for better compatibility
      return HtmlWidget(
        content,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        customStylesBuilder: (element) {
          if (element.localName == 'table') {
            return {
              'border-collapse': 'collapse',
              'width': '100%',
              'border': '1px solid #ccc',
              'font-size': '14px',
            };
          }
          if (element.localName == 'td' || element.localName == 'th') {
            return {
              'border': '1px solid #ccc',
              'padding': '8px 12px',
              'text-align': 'center',
              'vertical-align': 'middle',
              'min-width': '80px',
            };
          }
          if (element.localName == 'tr') {
            return {
              'background-color': 'transparent',
            };
          }
          if (element.localName == 'p') {
            return {
              'margin': '0',
              'padding': '0',
            };
          }
          return null;
        },
        onErrorBuilder: (context, element, error) {
          return Text('Ошибка отображения таблицы: $error');
        },
      );
    } catch (e) {
      // Fallback to simple text display if parsing fails
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Ошибка при отображении таблицы: $e',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
              ),
        ),
      );
    }
  }

  // ========== BOTTOM BAR COMPONENTS (like original) ==========

  Widget _buildBottomBarBlack(
      ChapterController controller, double height, double iconSize) {
    return Positioned(
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          color: Colors.black.withAlpha((255 * 0.8).round()),
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
    return GestureDetector(
      onTap: () {
        onPressed();
      },
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          border: Border.all(
              color: Colors.white.withAlpha((255 * 0.3).round()), width: 1),
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
      color: Colors.white.withAlpha((255 * 0.3).round()),
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
        icon: Icon(
          Icons.palette,
          color: Theme.of(context).primaryColor,
          size: height * 0.1,
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
              final editedText = textController.text.trim();
              if (editedText.isNotEmpty) {
                Navigator.pop(context);
                await controller.saveEditedParagraph(paragraph, editedText);
                if (controller.error != null) {
                  _showErrorSnackBar(controller.error!);
                } else {
                  _showSnackBar('Параграф сохранен');
                }
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SearchScreen(
          controller: controller,
          regulationId: widget.regulationId,
          settingsRepository: widget.settingsRepository,
          ttsRepository: widget.ttsRepository,
          regulationRepository: widget.regulationRepository,
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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildParagraphWithContextMenu(
      Paragraph paragraph,
      ChapterController controller,
      bool isSelected,
      bool hasFormatting,
      bool isCurrentTTSParagraph) {
    Color cardColor;
    BoxDecoration? decoration;

    if (isCurrentTTSParagraph) {
      cardColor = Colors.green
          .withAlpha((255 * 0.2).round()); // Приятный зелёный цвет для TTS
      decoration = BoxDecoration(
        border: Border.all(color: Colors.green, width: 3), // Зелёная рамка
        borderRadius: BorderRadius.circular(4),
      );
    } else if (isSelected) {
      cardColor = Theme.of(context).primaryColor.withAlpha((255 * 0.1).round());
      decoration = BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        borderRadius: BorderRadius.circular(4),
      );
    } else if (hasFormatting) {
      cardColor = Colors.yellow.withAlpha((255 * 0.1).round());
      decoration = BoxDecoration(borderRadius: BorderRadius.circular(4));
    } else {
      cardColor = Theme.of(context).scaffoldBackgroundColor;
      decoration = BoxDecoration(borderRadius: BorderRadius.circular(4));
    }

    return GestureDetector(
      onTap: () {
        _showParagraphContextMenu(context, paragraph, controller);
      },
      child: Card(
        elevation: 0,
        color: cardColor,
        margin: EdgeInsets.zero,
        child: Container(
          decoration: decoration,
          child: _buildParagraphContent(paragraph, controller,
              isSelectable: controller.isBottomBarExpanded),
        ),
      ),
    );
  }

  void _handleMenuAction(
      String action, Paragraph paragraph, ChapterController controller) {
    switch (action) {
      case 'edit':
        _showEditDialog(paragraph, controller);
        break;
      case 'share':
        _shareText(TextUtils.parseHtmlString(paragraph.content));
        break;
      case 'listen':
        _showTTSBottomSheet(paragraph, controller);
        break;
      case 'notes':
        controller.expandBottomBar();
        controller.selectParagraphForFormatting(paragraph);
        break;
    }
  }

  void _showParagraphContextMenu(
      BuildContext context, Paragraph paragraph, ChapterController controller) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width * 0.1,
        MediaQuery.of(context).size.height * 0.3,
        MediaQuery.of(context).size.width * 0.1,
        MediaQuery.of(context).size.height * 0.3,
      ),
      color: Theme.of(context).drawerTheme.backgroundColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: Theme.of(context).iconTheme.color),
            title: Text('Редактировать',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: ListTile(
            leading:
                Icon(Icons.share, color: Theme.of(context).iconTheme.color),
            title: Text('Поделиться',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'listen',
          child: ListTile(
            leading: Icon(Icons.hearing_rounded,
                color: Theme.of(context).iconTheme.color),
            title: Text('Прослушать',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'notes',
          child: ListTile(
            leading: Icon(Icons.note_alt_outlined,
                color: Theme.of(context).iconTheme.color),
            title: Text('Заметки',
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleMenuAction(value, paragraph, controller);
      } else {}
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
    try {
      dev.log('url: $url');

      // Handle new format: documentId/chapterNumber/paragraphNumber
      if (url.contains('/')) {
        final parts = url.split('/');
        if (parts.length == 3) {
          final documentId = int.tryParse(parts[0]);
          final chapterNum = int.tryParse(parts[1]);
          final paragraphNum = int.tryParse(parts[2]);

          if (documentId != null &&
              chapterNum != null &&
              paragraphNum != null) {
            // If it's the same document
            if (documentId == widget.regulationId) {
              // If it's the same chapter
              if (chapterNum == controller.currentChapterOrderNum) {
                // Ищем параграф только в текущей главе
                controller.goToParagraph(paragraphNum);
              } else {
                // Open new chapter page with specific paragraph
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChapterView(
                      regulationId: widget.regulationId,
                      initialChapterOrderNum: chapterNum,
                      scrollToParagraphId: paragraphNum,
                      settingsRepository: widget.settingsRepository,
                      ttsRepository: widget.ttsRepository,
                      regulationRepository: widget.regulationRepository,
                    ),
                  ),
                );
              }
            } else {
              await controller.navigateToDifferentDocument(
                  documentId, chapterNum, paragraphNum);
            }
            return true;
          }
        }
      }

      // Handle anchor links (like #paragraph_123)
      if (url.startsWith('#')) {
        final anchorId = url.substring(1);

        // Try to extract paragraph ID from anchor
        if (anchorId.startsWith('paragraph_')) {
          final paragraphIdStr = anchorId.substring('paragraph_'.length);
          final paragraphId = int.tryParse(paragraphIdStr);
          if (paragraphId != null) {
            controller.goToParagraph(paragraphId);
            return true;
          }
        }

        // Try to handle other anchor formats
        final paragraphId = int.tryParse(anchorId);
        if (paragraphId != null) {
          controller.goToParagraph(paragraphId);
          return true;
        }
      }

      // For external links, return false to allow default handling
      if (url.startsWith('http') ||
          url.startsWith('mailto:') ||
          url.startsWith('tel:')) {
        return false;
      }

      return true; // Prevent default behavior for any other internal-looking links
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      dev.log('Error handling internal link: $e');
      return false;
    }
  }
}

class _SearchScreen extends StatefulWidget {
  final ChapterController controller;
  final int regulationId;
  final SettingsRepository settingsRepository;
  final TTSRepository ttsRepository;
  final RegulationRepository regulationRepository;

  const _SearchScreen({
    required this.controller,
    required this.regulationId,
    required this.settingsRepository,
    required this.ttsRepository,
    required this.regulationRepository,
  });

  @override
  State<_SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<_SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) {
        _debounce!.cancel();
      }
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.controller.search(_searchController.text);
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          Theme.of(context).appBarTheme.toolbarHeight ?? 74.0,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            right: MediaQuery.of(context).size.width * 0.1,
          ),
          child: RegulationAppBar(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    size: Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
                    color: Theme.of(context).appBarTheme.iconTheme?.color,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15.0),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      cursorColor:
                          Theme.of(context).appBarTheme.foregroundColor,
                      style: Theme.of(context).appBarTheme.toolbarTextStyle,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 22,
                          maxHeight: 22,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Icon(
                            Icons.search,
                            color:
                                Theme.of(context).appBarTheme.foregroundColor,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).iconTheme.color!,
                          ),
                        ),
                        isDense: true,
                        hintText: 'Поиск',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<void>(
        stream: Stream.periodic(const Duration(milliseconds: 100), (_) {}),
        builder: (context, snapshot) {
          final controller = widget.controller;

          if (controller.isSearching) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.searchResults.isEmpty &&
              controller.searchQuery.isNotEmpty) {
            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Text(
                  'По вашему запросу ничего не найдено.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: controller.searchResults.length,
            itemBuilder: (context, index) {
              final result = controller.searchResults[index];
              final width = MediaQuery.of(context).size.width;

              return Card(
                elevation: 0,
                color: Theme.of(context).scaffoldBackgroundColor,
                margin: EdgeInsets.zero,
                shape: Border(
                  bottom: BorderSide(
                    width: 1.0,
                    color: Theme.of(context).shadowColor,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    width * 0.01,
                    width * 0.06,
                    width * 0.01,
                    width * 0.05,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              // Navigate to the chapter with the search result
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChapterView(
                                    regulationId: widget.regulationId,
                                    initialChapterOrderNum:
                                        result.chapterOrderNum,
                                    scrollToParagraphId: result.paragraphId,
                                    settingsRepository:
                                        widget.settingsRepository,
                                    ttsRepository: widget.ttsRepository,
                                    regulationRepository:
                                        widget.regulationRepository,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                SizedBox(width: width * 0.05),
                                SizedBox(
                                  width: width * 0.85,
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: result.text
                                              .substring(0, result.matchStart),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        TextSpan(
                                          text: result.text.substring(
                                            result.matchStart,
                                            result.matchEnd,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                backgroundColor: Colors.yellow,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        TextSpan(
                                          text: result.text
                                              .substring(result.matchEnd),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
