import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class GetNotesUseCase extends UseCase<List<Note>, void> {
  final NotesRepository _notesRepository;

  GetNotesUseCase(this._notesRepository);

  @override
  Future<Stream<List<Note>>> buildUseCaseStream(void params) async {
    final controller = StreamController<List<Note>>();
    try {
      final notes = await _notesRepository.getNotes();
      controller.add(notes);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
