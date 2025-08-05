import 'dart:async';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/domain/entities/subscription.dart';
import 'package:poteu/domain/repositories/regulation_repository.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';

class HandleExpiredSubscriptionUseCase extends CompletableUseCase<void> {
  final SubscriptionRepository _subscriptionRepository;
  final RegulationRepository _regulationRepository;

  HandleExpiredSubscriptionUseCase(
      this._subscriptionRepository, this._regulationRepository);

  @override
  Future<Stream<void>> buildUseCaseStream(void params) async {
    final controller = StreamController<void>();
    try {
      // Set local status to inactive
      await _subscriptionRepository.saveSubscriptionStatus(Subscription.inactive());
      // Delete downloaded premium documents
      await _regulationRepository.deletePremiumContent();
      controller.close();
    } catch (e) {
      controller.addError(e);
    }
    return controller.stream;
  }
}
