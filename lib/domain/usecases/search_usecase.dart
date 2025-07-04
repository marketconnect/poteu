import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/search_result.dart';
import '../repositories/regulation_repository.dart';

class SearchUseCase extends UseCase<List<SearchResult>, String?> {
  final RegulationRepository _regulationRepository;

  SearchUseCase(this._regulationRepository);

  @override
  Future<Stream<List<SearchResult>?>> buildUseCaseStream(String? query) async {
    final StreamController<List<SearchResult>?> controller = StreamController();
    try {
      if (query == null || query.isEmpty) {
        controller.add(null);
        controller.close();
        return controller.stream;
      }

      final results = await _regulationRepository.searchChapters(query);
      final searchResults = results
          .map((result) => SearchResult(
                chapterId: result['chapterId'] as int,
                chapterOrderNum: result['chapterOrderNum'] as int,
                chapterTitle: result['chapterTitle'] as String,
                paragraphId: result['paragraphId'] as int,
                paragraphContent: result['paragraphContent'] as String,
                highlightedText: result['highlightedText'] as String,
              ))
          .toList();

      controller.add(searchResults);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
