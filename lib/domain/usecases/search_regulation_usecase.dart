import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/regulation_repository.dart';

class SearchRegulationUseCase
    extends UseCase<List<Map<String, dynamic>>, String> {
  final RegulationRepository _regulationRepository;

  SearchRegulationUseCase(this._regulationRepository);

  @override
  Future<Stream<List<Map<String, dynamic>>>> buildUseCaseStream(
      String? params) async {
    final controller = StreamController<List<Map<String, dynamic>>>();
    try {
      final chapters = await _regulationRepository.searchChapters(params ?? '');
      controller.add(chapters);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
