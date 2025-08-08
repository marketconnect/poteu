import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/domain/entities/subscription_plan.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';
import 'package:poteu/domain/usecases/create_payment_link_usecase.dart';
import 'package:poteu/domain/usecases/get_subscription_plans_usecase.dart';

class SubscriptionPresenter extends Presenter {
  late Function(String) onPaymentLinkCreated;
  late Function(dynamic) onError;
  late Function(List<SubscriptionPlan>) onPlansLoaded;
  late Function(dynamic) onPlansError;

  final CreatePaymentLinkUseCase _createPaymentLinkUseCase;
  final GetSubscriptionPlansUseCase _getSubscriptionPlansUseCase;

  SubscriptionPresenter(SubscriptionRepository subscriptionRepository)
      : _createPaymentLinkUseCase =
            CreatePaymentLinkUseCase(subscriptionRepository),
        _getSubscriptionPlansUseCase =
            GetSubscriptionPlansUseCase(subscriptionRepository);

  void createPaymentLink(String planType) {
    _createPaymentLinkUseCase.execute(
        _CreatePaymentLinkObserver(this), planType);
  }

  void getPlans() {
    _getSubscriptionPlansUseCase.execute(
        _GetSubscriptionPlansObserver(this), null);
  }

  @override
  void dispose() {
    _createPaymentLinkUseCase.dispose();
    _getSubscriptionPlansUseCase.dispose();
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

class _GetSubscriptionPlansObserver extends Observer<List<SubscriptionPlan>> {
  final SubscriptionPresenter _presenter;
  _GetSubscriptionPlansObserver(this._presenter);

  @override
  void onComplete() {}

  @override
  void onError(e) {
    _presenter.onPlansError(e);
  }

  @override
  void onNext(List<SubscriptionPlan>? response) {
    if (response != null) {
      _presenter.onPlansLoaded(response);
    }
  }
}
