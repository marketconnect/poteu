import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/chapter.dart';
import '../repositories/regulation_repository.dart';

class GetChapterUseCase extends UseCase<Chapter?, GetChapterUseCaseParams?> {
  final RegulationRepository _regulationRepository;

  GetChapterUseCase(this._regulationRepository);

  @override
  Future<Stream<Chapter?>> buildUseCaseStream(
      GetChapterUseCaseParams? params) async {
    final StreamController<Chapter?> controller = StreamController();
    try {
      if (params == null) {
        controller.addError(ArgumentError('Chapter ID is required'));
        return controller.stream;
      }
      final chapterData =
          await _regulationRepository.getChapter(params.chapterId);
      final chapter = Chapter(
        id: chapterData['id'] as int,
        num: chapterData['num'] as String,
        regulationId: chapterData['regulationId'] as int,
        title: chapterData['title'] as String,
        content: chapterData['content'] as String,
        level: chapterData['level'] as int,
      );
      controller.add(chapter);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}

class GetChapterUseCaseParams {
  final int chapterId;

  GetChapterUseCaseParams(this.chapterId);
}
