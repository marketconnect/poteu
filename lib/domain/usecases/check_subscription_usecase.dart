import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/domain/entities/subscription.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';

class CheckSubscriptionUseCase extends UseCase<Subscription, void> {
  final SubscriptionRepository _subscriptionRepository;

  CheckSubscriptionUseCase(this._subscriptionRepository);

  @override
  Future<Stream<Subscription>> buildUseCaseStream(void params) async {
    final controller = StreamController<Subscription>();
    try {
      final status = await _subscriptionRepository.checkSubscriptionStatus();
      controller.add(status);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
