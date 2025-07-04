import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/entities/search_result.dart';
import '../../../domain/usecases/search_usecase.dart';
import '../../../domain/repositories/regulation_repository.dart';

class SearchPresenter extends Presenter {
  final SearchUseCase _searchUseCase;

  // Functions to be called when search completes
  Function(List<SearchResult>)? onSearchComplete;
  Function(dynamic)? onSearchError;

  SearchPresenter(RegulationRepository regulationRepository)
      : _searchUseCase = SearchUseCase(regulationRepository);

  void search(int regulationId, String query) {
    _searchUseCase.execute(
      _SearchObserver(this),
      SearchUseCaseParams(
        regulationId: regulationId,
        query: query,
      ),
    );
  }

  @override
  void dispose() {
    _searchUseCase.dispose();
  }
}

class _SearchObserver implements Observer<List<SearchResult>> {
  final SearchPresenter presenter;

  _SearchObserver(this.presenter);

  @override
  void onComplete() {}

  @override
  void onError(e) {
    if (presenter.onSearchError != null) {
      presenter.onSearchError!(e);
    }
  }

  @override
  void onNext(List<SearchResult>? response) {
    if (presenter.onSearchComplete != null) {
      presenter.onSearchComplete!(response ?? []);
    }
  }
}
