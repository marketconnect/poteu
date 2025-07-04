import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/entities/chapter.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/entities/search_result.dart';
import 'search_presenter.dart';

class SearchController extends Controller {
  final RegulationRepository _regulationRepository;
  final SettingsRepository _settingsRepository;
  final TTSRepository _ttsRepository;
  final SearchPresenter _presenter;

  bool _isLoading = false;
  String? _error;
  List<SearchResult>? _results;
  String _query = '';

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SearchResult>? get results => _results;

  SearchController(
    this._regulationRepository,
    this._settingsRepository,
    this._ttsRepository,
  )   : _presenter = SearchPresenter(_regulationRepository),
        super();

  @override
  void initListeners() {
    _presenter.onSearchComplete = (results) {
      _results = results;
      _isLoading = false;
      refreshUI();
    };

    _presenter.onSearchError = (error) {
      _results = null;
      _isLoading = false;
      refreshUI();
    };
  }

  void onSearchQueryChanged(String query) {
    _query = query;
    if (query.length >= 3) {
      _isLoading = true;
      refreshUI();
      _presenter.search(query);
    } else {
      _results = null;
      refreshUI();
    }
  }

  void onSearchSubmitted() {
    if (_query.isNotEmpty) {
      _isLoading = true;
      refreshUI();
      _presenter.search(_query);
    }
  }

  void onChapterSelected(Map<String, dynamic> chapter) {
    // TODO: Implement chapter selection
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
