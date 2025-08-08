import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/app/services/active_regulation_service.dart';
import 'package:poteu/domain/entities/subscription.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';
import 'package:poteu/domain/usecases/check_subscription_usecase.dart';

import '../../../domain/entities/search_result.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import 'dart:developer' as dev;

enum SearchScope { currentDocument, allDocuments }

class SearchPageController extends Controller {
  final RegulationRepository _regulationRepository;
  final SubscriptionRepository _subscriptionRepository;
  // final SettingsRepository _settingsRepository;
  // final TTSRepository _ttsRepository;
  final TextEditingController _searchController;
  // final List<String> _searchQueries = [];
  // int _searchQueriesIndex = 0;
  Timer? _debounceTimer;
  bool _isLoading = false;
  List<SearchResult> _searchResults = [];
  SearchScope _searchScope = SearchScope.currentDocument;
  late final CheckSubscriptionUseCase _checkSubscriptionUseCase;
  bool _isSubscribed = false;

  // Callback for navigation
  Function(SearchResult)? onResultSelected;

  SearchPageController({
    required RegulationRepository regulationRepository,
    required SettingsRepository settingsRepository,
    required TTSRepository ttsRepository,
    required SubscriptionRepository subscriptionRepository,
  })  : _regulationRepository = regulationRepository,
        _subscriptionRepository = subscriptionRepository,
        // _settingsRepository = settingsRepository,
        // _ttsRepository = ttsRepository,
        _searchController = TextEditingController() {
    _checkSubscriptionUseCase = CheckSubscriptionUseCase(_subscriptionRepository);
    checkSubscriptionStatus();
  }

  TextEditingController get searchController => _searchController;
  bool get isLoading => _isLoading;
  List<SearchResult> get searchResults => _searchResults;
  SearchScope get searchScope => _searchScope;
  bool get isSubscribed => _isSubscribed;

  void checkSubscriptionStatus() {
    _isLoading = true;
    refreshUI();
    _checkSubscriptionUseCase.execute(
      _CheckSubscriptionObserver(this),
    );
  }

  void _onSubscriptionStatusChecked(Subscription status) {
    _isSubscribed = status.isActive;
    dev.log('Subscription status in search: $_isSubscribed');
    _isLoading = false;
    refreshUI();
  }

  void setSearchScope(SearchScope scope) {
    if (scope == SearchScope.allDocuments && !_isSubscribed) {
      // Let the view handle navigation to subscription page
      return;
    }
    _searchScope = scope;
    search();
    refreshUI();
  }

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
        if (_searchScope == SearchScope.currentDocument) {
          _searchResults = await _regulationRepository.searchInRegulation(
            regulationId: ActiveRegulationService().currentRegulationId,
            query: _searchController.text,
          );
        } else {
          _searchResults = await _regulationRepository.searchInAllRegulations(
            query: _searchController.text,
          );
        }
      } catch (e) {
        dev.log('Search error: $e');
        _searchResults = [];
      }

      _isLoading = false;
      refreshUI();
    });
  }

  void goToSearchResult(SearchResult result) {
    if (onResultSelected != null) {
      onResultSelected!(result);
    }
  }

  @override
  void onDisposed() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.onDisposed();
  }
}

class _CheckSubscriptionObserver extends Observer<Subscription> {
  final SearchPageController _controller;
  _CheckSubscriptionObserver(this._controller);

  @override
  void onComplete() {}

  @override
  void onError(e) {
    _controller._onSubscriptionStatusChecked(Subscription.inactive());
  }

  @override
  void onNext(Subscription? response) {
    _controller._onSubscriptionStatusChecked(response ?? Subscription.inactive());
  }
}
