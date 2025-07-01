import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../repositories/regulation_repository.dart';

class GetNotesUseCase extends UseCase<List<Map<String, dynamic>>?, void> {
  final RegulationRepository _regulationRepository;

  GetNotesUseCase(this._regulationRepository);

  @override
  Future<Stream<List<Map<String, dynamic>>?>> buildUseCaseStream(
      void params) async {
    final StreamController<List<Map<String, dynamic>>?> controller =
        StreamController();
    try {
      final notes = await _regulationRepository.getNotes();
      controller.add(notes);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}

class SaveNoteUseCase extends UseCase<void, SaveNoteUseCaseParams?> {
  final RegulationRepository _regulationRepository;

  SaveNoteUseCase(this._regulationRepository);

  @override
  Future<Stream<void>> buildUseCaseStream(SaveNoteUseCaseParams? params) async {
    final StreamController<void> controller = StreamController();
    try {
      if (params == null) {
        controller.addError(ArgumentError('Note parameters are required'));
        return controller.stream;
      }
      await _regulationRepository.saveNote(params.chapterId, params.note);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}

class DeleteNoteUseCase extends UseCase<void, DeleteNoteUseCaseParams?> {
  final RegulationRepository _regulationRepository;

  DeleteNoteUseCase(this._regulationRepository);

  @override
  Future<Stream<void>> buildUseCaseStream(
      DeleteNoteUseCaseParams? params) async {
    final StreamController<void> controller = StreamController();
    try {
      if (params == null) {
        controller.addError(ArgumentError('Note ID is required'));
        return controller.stream;
      }
      await _regulationRepository.deleteNote(params.noteId);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}

class SaveNoteUseCaseParams {
  final int chapterId;
  final String note;

  SaveNoteUseCaseParams({
    required this.chapterId,
    required this.note,
  });
}

class DeleteNoteUseCaseParams {
  final int noteId;

  DeleteNoteUseCaseParams(this.noteId);
}
