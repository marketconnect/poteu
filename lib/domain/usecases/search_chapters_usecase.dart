import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/regulation_repository.dart';

class SearchChaptersUseCase
    extends UseCase<List<Map<String, dynamic>>, SearchChaptersUseCaseParams?> {
  final RegulationRepository _regulationRepository;

  SearchChaptersUseCase(this._regulationRepository);

  @override
  Future<Stream<List<Map<String, dynamic>>>> buildUseCaseStream(
      SearchChaptersUseCaseParams? params) async {
    final StreamController<List<Map<String, dynamic>>> controller =
        StreamController();
    try {
      if (params == null) {
        controller.addError(ArgumentError('Search query is required'));
        return controller.stream;
      }
      final results = await _regulationRepository.searchChapters(params.query);
      controller.add(results);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}

class SearchChaptersUseCaseParams {
  final String query;

  SearchChaptersUseCaseParams(this.query);
}
