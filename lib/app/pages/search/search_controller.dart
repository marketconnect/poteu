import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';

import '../../../domain/entities/search_result.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../navigation/app_navigator.dart';

class SearchPageController extends Controller {
  final RegulationRepository _regulationRepository;
  final SettingsRepository _settingsRepository;
  final TTSRepository _ttsRepository;
  final TextEditingController _searchController;
  final List<String> _searchQueries = [];
  int _searchQueriesIndex = 0;
  Timer? _debounceTimer;
  bool _isLoading = false;
  List<SearchResult> _searchResults = [];

  SearchPageController({
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
  })  : _regulationRepository = regulationRepository,
        _settingsRepository = settingsRepository,
        _ttsRepository = ttsRepository,
        _searchController = TextEditingController();

  TextEditingController get searchController => _searchController;
  bool get isLoading => _isLoading;
  List<SearchResult> get searchResults => _searchResults;

  @override
  void initListeners() {}

  void search() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_searchController.text.isEmpty) {
        _searchResults = [];
        refreshUI();
        return;
      }

      _isLoading = true;
      refreshUI();

      try {
        _searchResults = await _regulationRepository.searchInRegulation(
          regulationId: 1, // POTEU regulation ID
          query: _searchController.text,
        );
      } catch (e) {
        print('Search error: $e');
        _searchResults = [];
      }

      _isLoading = false;
      refreshUI();
    });
  }

  void goToSearchResult(SearchResult result) {
    AppNavigator.navigateToChapter(
      getContext(),
      1, // POTEU regulation ID
      result.chapterOrderNum,
      scrollToParagraphId: result.paragraphId,
      settingsRepository: _settingsRepository,
      ttsRepository: _ttsRepository,
    );
  }

  @override
  void onDisposed() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.onDisposed();
  }
}
