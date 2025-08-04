import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/regulation_repository.dart';
import '../entities/chapter.dart';

class GetTableOfContents extends UseCase<List<Chapter>?, int> {
  final RegulationRepository _regulationRepository;

  GetTableOfContents(this._regulationRepository);

  @override
  Future<Stream<List<Chapter>?>> buildUseCaseStream(int? params) async {
    final StreamController<List<Chapter>?> controller = StreamController();
    try {
      if (params == null) {
        throw ArgumentError("regulationId is required");
      }
      final chapters = await _regulationRepository.getChapters(params);
      controller.add(chapters);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
