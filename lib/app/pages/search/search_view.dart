import 'package:flutter/material.dart' hide View, SearchController;
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/repositories/subscription_repository.dart';
import '../../widgets/regulation_app_bar.dart';
import '../chapter/chapter_view.dart';
import 'search_controller.dart';
import '../../../domain/entities/search_result.dart';

class SearchView extends View {
  final RegulationRepository regulationRepository;
  final SettingsRepository settingsRepository;
  final TTSRepository ttsRepository;
  final SubscriptionRepository subscriptionRepository;

  const SearchView({
    Key? key,
    required this.regulationRepository,
    required this.settingsRepository,
    required this.ttsRepository,
    required this.subscriptionRepository,
  }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  SearchViewState createState() => SearchViewState(
        SearchPageController(
          regulationRepository: regulationRepository,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
          subscriptionRepository: subscriptionRepository,
        ),
      );
}

class SearchViewState extends ViewState<SearchView, SearchPageController> {
  SearchViewState(SearchPageController controller) : super(controller);

  @override
  Widget get view {
    return ControlledWidgetBuilder<SearchPageController>(
      builder: (context, controller) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(
                Theme.of(context).appBarTheme.toolbarHeight ?? 74.0),
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
                        size:
                            Theme.of(context).appBarTheme.iconTheme?.size ?? 27,
                        color: Theme.of(context).appBarTheme.iconTheme?.color,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 15.0),
                        child: TextField(
                          autofocus: true,
                          controller: controller.searchController,
                          cursorColor:
                              Theme.of(context).appBarTheme.foregroundColor,
                          style: Theme.of(context).appBarTheme.toolbarTextStyle,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            prefixIconConstraints: const BoxConstraints(
                                minWidth: 22, maxHeight: 22),
                            prefixIcon: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Icon(
                                Icons.search,
                                color: Theme.of(context)
                                    .appBarTheme
                                    .foregroundColor,
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
                          onChanged: (_) => controller.search(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: controller.isLoading && controller.searchResults.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: SegmentedButton<SearchScope>(
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          side: MaterialStateProperty.all(
                            BorderSide(color: theme.shadowColor),
                          ),
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return theme.navigationRailTheme.indicatorColor;
                              }
                              return theme.navigationRailTheme.backgroundColor;
                            },
                          ),
                          foregroundColor:
                              MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (states.contains(MaterialState.selected)) {
                                return theme
                                    .navigationRailTheme.selectedIconTheme?.color;
                              }
                              return theme.navigationRailTheme
                                  .unselectedLabelTextStyle?.color;
                            },
                          ),
                        ),
                        segments: <ButtonSegment<SearchScope>>[
                          const ButtonSegment<SearchScope>(
                              value: SearchScope.currentDocument,
                              label: Text('В текущем')),
                          ButtonSegment<SearchScope>(
                            value: SearchScope.allDocuments,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Во всех'),
                                if (!controller.isSubscribed) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.lock, size: 16),
                                ]
                              ],
                            ),
                          ),
                        ],
                        selected: <SearchScope>{controller.searchScope},
                        onSelectionChanged: (Set<SearchScope> newSelection) {
                          final newScope = newSelection.first;
                          if (newScope == SearchScope.allDocuments &&
                              !controller.isSubscribed) {
                            FocusScope.of(context).unfocus();
                            Navigator.of(context).pushNamed('/subscription');
                          } else {
                            controller.setSearchScope(newScope);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: controller.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : controller.searchResults.isEmpty
                              ? Container(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  child: Center(
                                    child: Text(
                                      'По вашему запросу ничего не найдено.',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: controller.searchResults.length,
                                  itemBuilder: (context, index) {
                                    final result =
                                        controller.searchResults[index];
                                    return Card(
                                      elevation: 0,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                      margin: EdgeInsets.zero,
                                      shape: Border(
                                        bottom: BorderSide(
                                          width: 1.0,
                                          color: Theme.of(context).shadowColor,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          // Navigate to chapter with search result
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChapterView(
                                                regulationId:
                                                    result.regulationId,
                                                initialChapterOrderNum:
                                                    result.chapterOrderNum,
                                                scrollToParagraphId:
                                                    result.paragraphId,
                                                settingsRepository:
                                                    widget.settingsRepository,
                                                ttsRepository:
                                                    widget.ttsRepository,
                                                regulationRepository:
                                                    widget.regulationRepository,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                            MediaQuery.of(context).size.width *
                                                0.06,
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                            MediaQuery.of(context).size.width *
                                                0.05,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (controller.searchScope ==
                                                      SearchScope
                                                          .allDocuments &&
                                                  result.regulationTitle !=
                                                      null)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 8.0),
                                                  child: Text(
                                                    result.regulationTitle!,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              RichText(
                                                text: _buildHighlightedText(
                                                    context, result),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  TextSpan _buildHighlightedText(BuildContext context, SearchResult result) {
    final theme = Theme.of(context);
    final defaultStyle = theme.textTheme.bodyMedium;
    final highlightStyle = defaultStyle?.copyWith(
      backgroundColor: Colors.yellow,
      fontWeight: FontWeight.bold,
    );

    return TextSpan(
      children: [
        TextSpan(
          text: result.text.substring(0, result.matchStart),
          style: defaultStyle,
        ),
        TextSpan(
          text: result.text.substring(
            result.matchStart,
            result.matchEnd,
          ),
          style: highlightStyle,
        ),
        TextSpan(
          text: result.text.substring(result.matchEnd),
          style: defaultStyle,
        ),
      ],
    );
  }
}