import 'package:flutter/material' hide View;
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/repositories/regulation_repository.dart';
import 'search_controller.dart';

class SearchPage extends View {
  final RegulationRepository regulationRepository;

  const SearchPage({
    required this.regulationRepository,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _SearchPageState(regulationRepository);
}

class _SearchPageState extends ViewState<SearchPage, SearchController> {
  _SearchPageState(RegulationRepository regulationRepository)
      : super(SearchController(regulationRepository));

  @override
  Widget get view {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ControlledWidgetBuilder<SearchController>(
              builder: (context, controller) {
                return TextField(
                  onChanged: controller.onSearchQueryChanged,
                  onSubmitted: (_) => controller.onSearchSubmitted(),
                  decoration: const InputDecoration(
                    hintText: 'Введите текст для поиска...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ControlledWidgetBuilder<SearchController>(
              builder: (context, controller) {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final results = controller.results;
                if (results == null) {
                  return const Center(
                    child: Text('Введите минимум 3 символа для поиска'),
                  );
                }

                if (results.isEmpty) {
                  return const Center(
                    child: Text('Ничего не найдено'),
                  );
                }

                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return ListTile(
                      title: Text(
                          'Глава ${result.chapterOrderNum}: ${result.chapterTitle}'),
                      subtitle: Text(
                        result.highlightedText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        // TODO: Navigate to the specific paragraph
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
