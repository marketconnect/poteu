import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';

class SearchController extends Controller {
  final RegulationRepository _regulationRepository;
  final SettingsRepository _settingsRepository;
  final TTSRepository _ttsRepository;

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];
  String _query = '';

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get results => _results;

  SearchController(
    this._regulationRepository,
    this._settingsRepository,
    this._ttsRepository,
  );

  @override
  void initListeners() {}

  void onSearchQueryChanged(String query) {
    _query = query;
    if (query.length >= 3) {
      search();
    } else {
      _results = [];
      refreshUI();
    }
  }

  Future<void> search() async {
    if (_query.isEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    refreshUI();

    try {
      _results = await _regulationRepository.searchChapters(_query);
      _isLoading = false;
      refreshUI();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      refreshUI();
    }
  }

  void onChapterSelected(Map<String, dynamic> chapter) {
    // TODO: Implement chapter selection
  }
}
