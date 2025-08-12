import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../data/repositories/cloud_regulation_repository.dart';
import '../../../data/repositories/data_regulation_repository.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/entities/regulation.dart';
import '../../../domain/usecases/get_available_regulations_usecase.dart';
import '../../../domain/usecases/is_regulation_cached_usecase.dart';
import '../../../domain/usecases/download_regulation_data_usecase.dart'; 

class LibraryPresenter extends Presenter {
  late Function(List<Regulation>) onRegulationsLoaded;
  late Function(dynamic) onError;
  late Function(bool) onIsCachedResult;
  late Function onDownloadComplete;
  late Function(dynamic) onDownloadError;
  // For saving regulations
  Function? onRegulationsSaved;
  Function(dynamic)? onSaveRegulationsError;

  final GetAvailableRegulationsUseCase _getAvailableRegulationsUseCase;
  final IsRegulationCachedUseCase _isRegulationCachedUseCase;
  final DownloadRegulationDataUseCase _downloadRegulationDataUseCase;

  // Expose the repository for use cases in the controller
  final RegulationRepository regulationRepository = DataRegulationRepository();
  final SaveRegulationsUseCase _saveRegulationsUseCase;

  LibraryPresenter()
      : _getAvailableRegulationsUseCase =
            GetAvailableRegulationsUseCase(DataCloudRegulationRepository()),
        _isRegulationCachedUseCase =
            IsRegulationCachedUseCase(DataCloudRegulationRepository()),
        _downloadRegulationDataUseCase =
            DownloadRegulationDataUseCase(DataCloudRegulationRepository()),
        _saveRegulationsUseCase =
            SaveRegulationsUseCase(DataRegulationRepository());

  void getAvailableRegulations() {
    _getAvailableRegulationsUseCase.execute(
        _GetAvailableRegulationsObserver(this), null);
  }

  void isRegulationCached(int ruleId) {
    _isRegulationCachedUseCase.execute(_IsCachedObserver(this), ruleId);
  }

  void downloadRegulationData(int ruleId) {
    _downloadRegulationDataUseCase.execute(_DownloadObserver(this), ruleId);
  }

  void saveRegulations(List<Regulation> regulations) {
    _saveRegulationsUseCase.execute(_SaveRegulationsObserver(this), regulations);
  }

  @override
  void dispose() {
    _getAvailableRegulationsUseCase.dispose();
    _isRegulationCachedUseCase.dispose();
    _downloadRegulationDataUseCase.dispose();
    _saveRegulationsUseCase.dispose();
  }
}

class _GetAvailableRegulationsObserver extends Observer<List<Regulation>> {
  final LibraryPresenter _presenter;

  _GetAvailableRegulationsObserver(this._presenter);

  @override
  void onComplete() {}

  @override
  void onError(e) {
    _presenter.onError(e);
  }

  @override
  void onNext(List<Regulation>? response) {
    if (response != null) {
      _presenter.onRegulationsLoaded(response);
    }
  }
}

class _IsCachedObserver extends Observer<bool> {
  final LibraryPresenter _presenter;
  _IsCachedObserver(this._presenter);
  @override
  void onComplete() {}
  @override
  void onError(e) => _presenter.onError(e);
  @override
  void onNext(bool? response) {
    if (response != null) {
      _presenter.onIsCachedResult(response);
    }
  }
}

class _DownloadObserver extends Observer<void> {
  final LibraryPresenter _presenter;
  _DownloadObserver(this._presenter);
  @override
  void onComplete() => _presenter.onDownloadComplete();
  @override
  void onError(e) => _presenter.onDownloadError(e);
  @override
  void onNext(void response) {}
}

class _SaveRegulationsObserver extends Observer<void> {
  final LibraryPresenter _presenter;
  _SaveRegulationsObserver(this._presenter);

  @override
  void onComplete() {
    _presenter.onRegulationsSaved?.call();
  }

  @override
  void onError(e) {
    _presenter.onSaveRegulationsError?.call(e);
  }

  @override
  void onNext(void response) {}
}