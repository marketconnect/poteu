import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/paragraph.dart';
import '../repositories/regulation_repository.dart';

class GetChapterContentParams {
  final int regulationId;
  final int chapterOrderNum;

  GetChapterContentParams({
    required this.regulationId,
    required this.chapterOrderNum,
  });
}

class GetChapterContentUseCase
    extends UseCase<List<Paragraph>, GetChapterContentParams> {
  final RegulationRepository _regulationRepository;

  GetChapterContentUseCase(this._regulationRepository);

  @override
  Future<Stream<List<Paragraph>>> buildUseCaseStream(
      GetChapterContentParams? params) async {
    final controller = StreamController<List<Paragraph>>();
    try {
      if (params == null) {
        controller.add([]);
        controller.close();
        return controller.stream;
      }

      final paragraphs =
          await _regulationRepository.getParagraphsByChapterOrderNum(
        params.regulationId,
        params.chapterOrderNum,
      );

      controller.add(paragraphs);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
