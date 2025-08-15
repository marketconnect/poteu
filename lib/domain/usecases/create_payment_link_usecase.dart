import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';

class CreatePaymentLinkUseCase
    extends UseCase<String, CreatePaymentLinkParams> {
  final SubscriptionRepository _subscriptionRepository;

  CreatePaymentLinkUseCase(this._subscriptionRepository);

  @override
  Future<Stream<String>> buildUseCaseStream(
      CreatePaymentLinkParams? params) async {
    final controller = StreamController<String>();
    try {
      if (params == null) {
        throw ArgumentError("params cannot be null");
      }
      final url = await _subscriptionRepository.createPaymentLink(
          params.planType, params.email);
      controller.add(url);
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}

class CreatePaymentLinkParams {
  final String planType;
  final String email;

  CreatePaymentLinkParams({required this.planType, required this.email});
}
