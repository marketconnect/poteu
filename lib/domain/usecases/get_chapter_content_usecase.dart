import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../repositories/regulation_repository.dart';

class GetChapterContentUseCaseParams {
  final int chapterId;
  GetChapterContentUseCaseParams(this.chapterId);
}

class GetChapterContentUseCase
    extends UseCase<Map<String, dynamic>?, GetChapterContentUseCaseParams> {
  final RegulationRepository _repository;

  GetChapterContentUseCase(this._repository);

  @override
  Future<Stream<Map<String, dynamic>?>> buildUseCaseStream(
      GetChapterContentUseCaseParams? params) async {
    final StreamController<Map<String, dynamic>?> controller =
        StreamController();
    try {
      if (params != null) {
        final chapter = await _repository.getChapter(params.chapterId);
        controller.add(chapter);
      }
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
