import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';

class CreatePaymentLinkUseCase extends UseCase<String, String> {
  final SubscriptionRepository _subscriptionRepository;

  CreatePaymentLinkUseCase(this._subscriptionRepository);

  @override
  Future<Stream<String>> buildUseCaseStream(String? planType) async {
    final controller = StreamController<String>();
    try {
      if (planType == null) {
        throw ArgumentError("planType cannot be null");
      }
      final url = await _subscriptionRepository.createPaymentLink(planType);
      controller.add(url);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
