import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../entities/chapter.dart';
import '../repositories/regulation_repository.dart';

class SearchChapters {
  final RegulationRepository _regulationRepository;

  SearchChapters(this._regulationRepository);

  Future<List<Map<String, dynamic>>> execute(String query) async {
    return _regulationRepository.searchChapters(query);
  }

  void dispose() {}
}
