import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/domain/entities/subscription_plan.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';

class GetSubscriptionPlansUseCase
    extends UseCase<List<SubscriptionPlan>, void> {
  final SubscriptionRepository _subscriptionRepository;

  GetSubscriptionPlansUseCase(this._subscriptionRepository);

  @override
  Future<Stream<List<SubscriptionPlan>>> buildUseCaseStream(void params) async {
    final controller = StreamController<List<SubscriptionPlan>>();
    try {
      final plans = await _subscriptionRepository.getSubscriptionPlans();
      controller.add(plans);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
