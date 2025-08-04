import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/app/services/active_regulation_service.dart';
import '../../../domain/entities/regulation.dart';
import 'library_presenter.dart';
import 'dart:developer' as dev;

class LibraryController extends Controller {
  final LibraryPresenter _presenter;
  List<Regulation> _regulations = [];
  bool _isLoading = true;
  String? _error;
  Regulation? _selectedRegulation;
  bool _isCheckingCache = false;
  bool _isDownloading = false;

  List<Regulation> get regulations => _regulations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Regulation? get selectedRegulation => _selectedRegulation;
  bool get isCheckingCache => _isCheckingCache;
  bool get isDownloading => _isDownloading;

  final ActiveRegulationService _activeRegulationService;

  LibraryController()
      : _presenter = LibraryPresenter(),
        _activeRegulationService = ActiveRegulationService() {
    initListeners();
    _presenter.getAvailableRegulations();
  }

  @override
  void initListeners() {
    _presenter.onRegulationsLoaded = (List<Regulation> regulations) {
      _regulations = regulations;
      _isLoading = false;
      _error = null;
      refreshUI();
    };

    _presenter.onError = (e) {
      _error = e.toString();
      _isLoading = false;
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
    _presenter.getAvailableRegulations();
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
