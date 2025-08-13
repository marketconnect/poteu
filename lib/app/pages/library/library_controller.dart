import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/app/services/active_regulation_service.dart';
import 'package:poteu/domain/entities/subscription.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';
import 'package:poteu/domain/usecases/check_subscription_usecase.dart';
import 'package:poteu/domain/usecases/handle_expired_subscription_usecase.dart';
import '../../../domain/entities/regulation.dart';
import 'package:poteu/config.dart';
import 'library_presenter.dart';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LibraryController extends Controller {
  final LibraryPresenter _presenter;
  final SubscriptionRepository _subscriptionRepository;

  // Usecases
  late final CheckSubscriptionUseCase _checkSubscriptionUseCase;
  late final HandleExpiredSubscriptionUseCase _handleExpiredSubscriptionUseCase;
  static const String lastFetchDateKey = 'library_last_fetch_date';
  static const String regulationsCacheKey = 'library_regulations_cache';

  List<Regulation> _regulations = [];
  bool _isLoading = true;
  String? _error;
  Regulation? _selectedRegulation;
  bool _isCheckingCache = false;
  bool _isDownloading = false;
  Subscription _subscription = Subscription.inactive();

  List<Regulation> get regulations => _regulations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Regulation? get selectedRegulation => _selectedRegulation;
  bool get isCheckingCache => _isCheckingCache;
  bool get isDownloading => _isDownloading;
  bool get isSubscribed => _subscription.isActive;

  final ActiveRegulationService _activeRegulationService;

  LibraryController(this._subscriptionRepository)
      : _presenter = LibraryPresenter(),
        _activeRegulationService = ActiveRegulationService(),
        super() {
    _checkSubscriptionUseCase =
        CheckSubscriptionUseCase(_subscriptionRepository);
    _handleExpiredSubscriptionUseCase = HandleExpiredSubscriptionUseCase(
        _subscriptionRepository, _presenter.regulationRepository);

    initListeners();
    // Check subscription status first
    checkSubscriptionStatus();
    // Then load regulations
    loadRegulationsWithCache();
  }

  @override
  void initListeners() {
    _presenter.onRegulationsLoaded = (List<Regulation> regulations) {
      // Process regulations: ensure the main document is not treated as premium.
      var processedRegulations = regulations.map((r) {
        if (r.id == AppConfig.instance.regulationId) {
          return r.copyWith(isPremium: false);
        }
        return r;
      }).toList();

      // Sort regulations: downloaded (saved) first, then alphabetically by title.
      processedRegulations.sort((a, b) {
        if (a.isDownloaded && !b.isDownloaded) {
          return -1; // a (downloaded) comes before b (not downloaded)
        } else if (!a.isDownloaded && b.isDownloaded) {
          return 1; // b (downloaded) comes before a (not downloaded)
        } else {
          // If both have the same download status, sort alphabetically by title.
          return a.title.compareTo(b.title);
        }
      });

      _regulations = processedRegulations;
      _isLoading = false;
      _error = null;
      refreshUI();
      _cacheRegulations(regulations);
      _presenter.saveRegulations(regulations);
    };

    _presenter.onError = (e) {
      _error = e.toString();
      _isLoading = false;
      _selectedRegulation = null;
      refreshUI();
    };

    _presenter.onIsCachedResult = (bool isCached) {
      _isCheckingCache = false;
      if (isCached) {
        dev.log(
            'Regulation ${_selectedRegulation!.id} is already cached. Proceeding.');
        _proceedToSetActiveRegulation();
      } else {
        dev.log(
            'Regulation ${_selectedRegulation!.id} not cached. Starting download.');
        _isDownloading = true;
        refreshUI();
        _presenter.downloadRegulationData(_selectedRegulation!.id);
      }
    };

    _presenter.onDownloadComplete = () {
      dev.log(
          'Download complete for regulation ${_selectedRegulation!.id}. Proceeding.');
      _isDownloading = false;
      // Update the regulation in the list to mark it as downloaded
      if (_selectedRegulation != null) {
        final index =
            _regulations.indexWhere((r) => r.id == _selectedRegulation!.id);
        if (index != -1) {
          _regulations[index] =
              _regulations[index].copyWith(isDownloaded: true);
          // Re-cache the updated list of regulations to persist the downloaded state
          _cacheRegulations(_regulations);
        }
        _selectedRegulation = _selectedRegulation!.copyWith(isDownloaded: true);
      }
      _proceedToSetActiveRegulation();
    };

    _presenter.onDownloadError = (e) {
      dev.log('Error downloading regulation: $e');
      _isCheckingCache = false;
      _isDownloading = false;
      _error = "Ошибка загрузки документа: $e";
      _selectedRegulation = null; // Deselect on error
      refreshUI();
    };

    _presenter.onRegulationsSaved = () {
      dev.log("Local rules table updated successfully.");
    };

    _presenter.onSaveRegulationsError = (e) {
      dev.log("Error updating local rules table: $e");
    };
  }

  void _cacheRegulations(List<Regulation> regulations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final regulationsJsonList = regulations.map((r) => r.toJson()).toList();
      final regulationsJsonString = json.encode(regulationsJsonList);
      await prefs.setString(lastFetchDateKey, today);
      await prefs.setString(regulationsCacheKey, regulationsJsonString);
      dev.log('Regulations cached for date: $today');
    } catch (e) {
      dev.log('Failed to cache regulations: $e');
    }
  }

  void loadRegulationsWithCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchDate = prefs.getString(lastFetchDateKey);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (false && lastFetchDate == today) {
        dev.log('Loading regulations from cache for date: $today');
        final cachedJson = prefs.getString(regulationsCacheKey);
        if (cachedJson != null) {
          final List<dynamic> decodedList = json.decode(cachedJson);
          final cachedRegulations = decodedList
              .map((jsonItem) =>
                  Regulation.fromJson(jsonItem as Map<String, dynamic>))
              .toList();
          _presenter.onRegulationsLoaded(cachedRegulations);
          return;
        }
      }
    } catch (e) {
      dev.log('Failed to load from cache: $e. Fetching from network.');
    }
    dev.log('Cache is old or invalid. Fetching regulations from network.');
    _presenter.getAvailableRegulations();
  }

  void checkSubscriptionStatus() {
    _isLoading = true;
    refreshUI();

    _checkSubscriptionUseCase.execute(_CheckSubscriptionObserver(this));
  }

  void _onSubscriptionStatusChecked(Subscription status) {
    _subscription = status;
    dev.log('Subscription status updated: isActive=${status.isActive}');

    // If subscription has expired, handle it
    if (!status.isActive && status.expirationDate != null) {
      if (status.expirationDate!.isBefore(DateTime.now())) {
        dev.log('Subscription expired. Handling cleanup...');
        _handleExpiredSubscriptionUseCase.execute(_HandleExpiredObserver(this));
      }
    }

    refreshUI();
  }

  Future<void> selectRegulation(Regulation regulation) async {
    _selectedRegulation = regulation;
    _isCheckingCache = true;
    _error = null;
    refreshUI();
    _presenter.isRegulationCached(regulation.id);
  }

  void _proceedToSetActiveRegulation() async {
    if (_selectedRegulation == null) return;

    await _activeRegulationService.setActiveRegulation(_selectedRegulation!);

    Navigator.of(getContext())
        .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
  }

  void refreshRegulations() {
    _isLoading = true;
    _error = null;
    _selectedRegulation = null;
    refreshUI();
    // Сначала проверяем статус подписки
    checkSubscriptionStatus();
    // Затем пытаемся загрузить документы, используя логику кэширования.
    // Это вызовет сетевой запрос только если кэш устарел.
    loadRegulationsWithCache();
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    _checkSubscriptionUseCase.dispose();
    _handleExpiredSubscriptionUseCase.dispose();
    super.onDisposed();
  }
}

class _CheckSubscriptionObserver extends Observer<Subscription> {
  final LibraryController _controller;
  _CheckSubscriptionObserver(this._controller);

  @override
  void onComplete() {}
  @override
  void onError(e) =>
      _controller._onSubscriptionStatusChecked(Subscription.inactive());
  @override
  void onNext(Subscription? response) => _controller
      ._onSubscriptionStatusChecked(response ?? Subscription.inactive());
}

class _HandleExpiredObserver extends Observer<void> {
  final LibraryController _controller;
  _HandleExpiredObserver(this._controller);

  @override
  void onComplete() => _controller.refreshRegulations();
  @override
  void onError(e) => dev.log('Error handling expired subscription: $e');
  @override
  void onNext(void response) {}
}
