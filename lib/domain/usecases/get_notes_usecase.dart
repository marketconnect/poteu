import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/note.dart';
import '../repositories/notes_repository.dart';

class GetNotesUseCase extends UseCase<List<Note>, GetNotesParams> {
  final NotesRepository _notesRepository;

  GetNotesUseCase(this._notesRepository);

  @override
  Future<Stream<List<Note>>> buildUseCaseStream(GetNotesParams? params) async {
    final controller = StreamController<List<Note>>();

    try {
      final notes = await _notesRepository.getAllNotes();

      // Apply sorting if specified
      if (params != null && params.sortByColor) {
        notes.sort((a, b) => a.link.color.value.compareTo(b.link.color.value));
      } else {
        // Sort by date (most recent first)
        notes.sort((a, b) => b.lastTouched.compareTo(a.lastTouched));
      }

      controller.add(notes);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }

    return controller.stream;
  }
}

class GetNotesParams {
  final bool sortByColor;

  GetNotesParams({this.sortByColor = false});
}
