import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/domain/usecases/create_payment_link_usecase.dart';

class SubscriptionPresenter extends Presenter {
  late Function(String) onPaymentLinkCreated;
  late Function(dynamic) onError;

  final CreatePaymentLinkUseCase _createPaymentLinkUseCase;

  SubscriptionPresenter(subscriptionRepository)
      : _createPaymentLinkUseCase =
            CreatePaymentLinkUseCase(subscriptionRepository);

  void createPaymentLink(String planType) {
    _createPaymentLinkUseCase.execute(
        _CreatePaymentLinkObserver(this), planType);
  }

  @override
  void dispose() {
    _createPaymentLinkUseCase.dispose();
  }
}

class _CreatePaymentLinkObserver extends Observer<String> {
  final SubscriptionPresenter _presenter;
  _CreatePaymentLinkObserver(this._presenter);

  @override
  void onComplete() {}

  @override
  void onError(e) {
    _presenter.onError(e);
  }

  @override
  void onNext(String? response) {
    if (response != null) {
      _presenter.onPaymentLinkCreated(response);
    }
  }
}
