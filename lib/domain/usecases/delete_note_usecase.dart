import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class DeleteNoteUseCase extends CompletableUseCase<DeleteNoteParams> {
  final NotesRepository _notesRepository;

  DeleteNoteUseCase(this._notesRepository);

  @override
  Future<Stream<void>> buildUseCaseStream(DeleteNoteParams? params) async {
    final controller = StreamController<void>();

    try {
      if (params == null) {
        throw Exception('DeleteNoteParams is required');
      }

      await _notesRepository.deleteNote(params.note);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }

    return controller.stream;
  }
}

class DeleteNoteParams {
  final Note note;

  DeleteNoteParams({required this.note});
}
