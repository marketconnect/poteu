import 'package:flutter/material.dart' hide View, SearchController;
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../widgets/regulation_app_bar.dart';
import 'search_controller.dart';

class SearchView extends View {
  final RegulationRepository regulationRepository;
  final SettingsRepository settingsRepository;
  final TTSRepository ttsRepository;

  const SearchView({
    Key? key,
    required this.regulationRepository,
    required this.settingsRepository,
    required this.ttsRepository,
  }) : super(key: key);

  @override
  SearchViewState createState() => SearchViewState(
        SearchPageController(
          regulationRepository: regulationRepository,
          settingsRepository: settingsRepository,
          ttsRepository: ttsRepository,
        ),
      );
}

class SearchViewState extends ViewState<SearchView, SearchPageController> {
  SearchViewState(SearchPageController controller) : super(controller);

  @override
  Widget get view {
    return ControlledWidgetBuilder<SearchPageController>(
      builder: (context, controller) {
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
          body: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : controller.searchResults.isEmpty
                  ? Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Center(
                        child: Text(
                          'По вашему запросу ничего не найдено.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: controller.searchResults.length,
                      itemBuilder: (context, index) {
                        final result = controller.searchResults[index];
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
                              MediaQuery.of(context).size.width * 0.01,
                              MediaQuery.of(context).size.width * 0.06,
                              MediaQuery.of(context).size.width * 0.01,
                              MediaQuery.of(context).size.width * 0.05,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () =>
                                          controller.goToSearchResult(result),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.85,
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: result.text.substring(
                                                        0, result.matchStart),
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
                                                          backgroundColor:
                                                              Colors.yellow,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  TextSpan(
                                                    text: result.text.substring(
                                                        result.matchEnd),
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
                    ),
        );
      },
    );
  }
}
