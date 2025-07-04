import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/search_result.dart';
import '../repositories/regulation_repository.dart';

class SearchUseCase extends UseCase<List<SearchResult>, SearchUseCaseParams> {
  final RegulationRepository _regulationRepository;

  SearchUseCase(this._regulationRepository);

  @override
  Future<Stream<List<SearchResult>>> buildUseCaseStream(
      SearchUseCaseParams? params) async {
    final controller = StreamController<List<SearchResult>>();
    try {
      if (params == null || params.query.isEmpty) {
        controller.add([]);
        controller.close();
        return controller.stream;
      }

      final results = await _regulationRepository.searchInRegulation(
        regulationId: params.regulationId,
        query: params.query,
      );

      controller.add(results);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}

class SearchUseCaseParams {
  final int regulationId;
  final String query;

  SearchUseCaseParams({
    required this.regulationId,
    required this.query,
  });
}
