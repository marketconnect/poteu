import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import '../../../domain/entities/search_result.dart';
import '../../../domain/usecases/search_usecase.dart';
import '../../../domain/repositories/regulation_repository.dart';

class SearchPresenter extends Presenter {
  late Function(List<SearchResult>?) onSearchComplete;
  late Function(dynamic error) onSearchError;

  final SearchUseCase _searchUseCase;

  SearchPresenter(RegulationRepository regulationRepository)
      : _searchUseCase = SearchUseCase(regulationRepository);

  void search(String query) {
    _searchUseCase.execute(_SearchUseCaseObserver(this), query);
  }

  @override
  void dispose() {
    _searchUseCase.dispose();
  }
}

class _SearchUseCaseObserver extends Observer<List<SearchResult>?> {
  final SearchPresenter presenter;

  _SearchUseCaseObserver(this.presenter);

  @override
  void onComplete() {}

  @override
  void onError(e) {
    presenter.onSearchError(e);
  }

  @override
  void onNext(List<SearchResult>? response) {
    presenter.onSearchComplete(response);
  }
}
