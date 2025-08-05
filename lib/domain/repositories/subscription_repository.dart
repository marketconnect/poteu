import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<String> getUserId();
  Future<String> createPaymentLink(String planType);
  Future<Subscription> checkSubscriptionStatus();
  Future<void> saveSubscriptionStatus(Subscription subscription);
  Future<Subscription> getCachedSubscriptionStatus();
}
