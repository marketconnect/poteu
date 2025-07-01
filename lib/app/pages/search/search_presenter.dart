import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/repositories/regulation_repository.dart';
import '../../../domain/repositories/settings_repository.dart';
import '../../../domain/repositories/tts_repository.dart';
import '../../../domain/usecases/search_chapters_usecase.dart';

class SearchPresenter extends Presenter {
  late Function(List<Map<String, dynamic>>) onSearchResults;
  late Function(dynamic) onError;

  final SearchChaptersUseCase _searchChaptersUseCase;

  SearchPresenter(RegulationRepository regulationRepository)
      : _searchChaptersUseCase = SearchChaptersUseCase(regulationRepository);

  void search(String query) {
    _searchChaptersUseCase.execute(
      _SearchChaptersUseCaseObserver(this),
      SearchChaptersUseCaseParams(query),
    );
  }

  @override
  void dispose() {
    _searchChaptersUseCase.dispose();
  }
}

class _SearchChaptersUseCaseObserver
    extends Observer<List<Map<String, dynamic>>> {
  final SearchPresenter presenter;

  _SearchChaptersUseCaseObserver(this.presenter);

  @override
  void onComplete() {}

  @override
  void onError(dynamic e) {
    presenter.onError(e);
  }

  @override
  void onNext(List<Map<String, dynamic>>? response) {
    if (response != null) {
      presenter.onSearchResults(response);
    }
  }
}
