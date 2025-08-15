import '../entities/subscription.dart';
import '../entities/subscription_plan.dart';

abstract class SubscriptionRepository {
  Future<String> getUserId();
  Future<String> createPaymentLink(String planType, String email);
  Future<Subscription> checkSubscriptionStatus();
  Future<void> saveSubscriptionStatus(Subscription subscription);
  Future<Subscription> getCachedSubscriptionStatus();
  Future<List<SubscriptionPlan>> getSubscriptionPlans();
}
