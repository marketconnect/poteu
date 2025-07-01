import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart'
    as clean;
import 'search_controller.dart' as app;
import '../../../domain/entities/chapter.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';

class SearchPage extends clean.View {
  final RegulationRepository regulationRepository;
  final SettingsRepository settingsRepository;
  final TTSRepository ttsRepository;

  const SearchPage({
    Key? key,
    required this.regulationRepository,
    required this.settingsRepository,
    required this.ttsRepository,
  }) : super(key: key);

  @override
  SearchPageState createState() => SearchPageState(
        regulationRepository,
        settingsRepository,
        ttsRepository,
      );
}

class SearchPageState
    extends clean.ViewState<SearchPage, app.SearchController> {
  final RegulationRepository regulationRepository;
  final SettingsRepository settingsRepository;
  final TTSRepository ttsRepository;
  List<Map<String, dynamic>> _searchResults = [];

  SearchPageState(
    this.regulationRepository,
    this.settingsRepository,
    this.ttsRepository,
  ) : super(app.SearchController(
          regulationRepository,
          settingsRepository,
          ttsRepository,
        ));

  List<Map<String, dynamic>> get searchResults => _searchResults;

  @override
  Widget get view {
    return clean.ControlledWidgetBuilder<app.SearchController>(
      builder: (context, controller) {
        return Scaffold(
          appBar: AppBar(
            title: TextField(
              onChanged: controller.onSearchQueryChanged,
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: _buildBody(controller),
        );
      },
    );
  }

  Widget _buildBody(app.SearchController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(controller.error!),
            ElevatedButton(
              onPressed: controller.search,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (controller.results.isEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    return ListView.builder(
      itemCount: controller.results.length,
      itemBuilder: (context, index) {
        final chapter = controller.results[index];
        return _buildSearchResultTile(chapter, controller);
      },
    );
  }

  Widget _buildSearchResultTile(
      Map<String, dynamic> chapter, app.SearchController controller) {
    return ListTile(
      title: Text(chapter['title']),
      subtitle: Text(
        chapter['content'],
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => controller.onChapterSelected(chapter),
    );
  }

  void onChapterSelected(Map<String, dynamic> chapter) {
    // TODO: Navigate to chapter detail
    Navigator.pushNamed(
      context,
      '/chapter',
      arguments: chapter,
    );
  }
}
