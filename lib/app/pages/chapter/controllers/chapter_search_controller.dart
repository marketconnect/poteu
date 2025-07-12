import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../../domain/entities/search_result.dart';
import '../../../../data/repositories/static_regulation_repository.dart';
import '../search_presenter.dart';

class ChapterSearchController extends Controller {
  final SearchPresenter _searchPresenter;

  bool _isSearching = false;
  List<SearchResult> _searchResults = [];
  String _searchQuery = '';
  String? _error;

  // Getters
  bool get isSearching => _isSearching;
  List<SearchResult> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  String? get error => _error;

  ChapterSearchController({required StaticRegulationRepository repository})
      : _searchPresenter = SearchPresenter(repository) {
    _initializeSearchPresenter();
  }

  void _initializeSearchPresenter() {
    _searchPresenter.onSearchComplete = (List<SearchResult> results) {
      _searchResults = results;
      _isSearching = false;
      _error = null;
      refreshUI();
    };

    _searchPresenter.onSearchError = (e) {
      _error = e.toString();
      _isSearching = false;
      refreshUI();
    };
  }

  @override
  void initListeners() {
    // Search presenter listeners already initialized in constructor
  }

  // Search Methods
  void search(String query, int regulationId) {
    _searchQuery = query;

    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      _error = null;
      refreshUI();
      return;
    }

    _isSearching = true;
    _error = null;
    refreshUI();

    _searchPresenter.search(regulationId, query);
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    _error = null;
    refreshUI();
  }

  void goToSearchResult(SearchResult result) {
    // This method will be called by the main controller to navigate to the result
    // The actual navigation logic is handled by the paging controller
    print('🔍 Navigating to search result: ${result.paragraphId}');

    // Clear search results after navigation
    _searchResults = [];
    _searchQuery = '';
    refreshUI();
  }

  // Utility methods
  bool get hasSearchResults => _searchResults.isNotEmpty;

  bool get hasSearchQuery => _searchQuery.isNotEmpty;

  int get searchResultsCount => _searchResults.length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    refreshUI();
  }

  void setSearchResults(List<SearchResult> results) {
    _searchResults = results;
    refreshUI();
  }

  void setSearching(bool searching) {
    _isSearching = searching;
    refreshUI();
  }

  void clearError() {
    _error = null;
    refreshUI();
  }

  @override
  void onDisposed() {
    _searchPresenter.dispose();
    super.onDisposed();
  }
}
