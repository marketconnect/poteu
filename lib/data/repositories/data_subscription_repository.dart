import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:poteu/app/services/user_id_service.dart';
import 'package:poteu/domain/entities/subscription.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;

class DataSubscriptionRepository implements SubscriptionRepository {
  // TODO: Move to config
  final String _baseUrl = 'http://192.168.0.13:8080';
  final http.Client _client;
  final UserIdService _userIdService;

  static const _subscriptionCacheKey = 'subscription_status_cache';

  DataSubscriptionRepository(this._client, this._userIdService);

  @override
  Future<String> getUserId() async {
    return await _userIdService.getUserId();
  }

  @override
  Future<String> createPaymentLink(String planType) async {
    final userId = await getUserId();
    final uri = Uri.parse('$_baseUrl/api/v1/subscriptions/request-payment');
    dev.log('Requesting payment link for userId: $userId, plan: $planType');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId, 'planType': planType}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final url = data['paymentUrl'];
      dev.log('Received payment URL: $url');
      return url;
    } else {
      dev.log(
          'Failed to get payment link. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Не удалось создать ссылку на оплату');
    }
  }

  @override
  Future<Subscription> checkSubscriptionStatus() async {
    final userId = await getUserId();
    final uri = Uri.parse('$_baseUrl/api/v1/subscriptions/status?userId=$userId');
    dev.log('Checking subscription status for userId: $userId');

    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final subscription = Subscription.fromJson(data);
        await saveSubscriptionStatus(subscription); // Cache the new status
        dev.log(
            'Subscription status from server: isActive=${subscription.isActive}, expires=${subscription.expirationDate}');
        return subscription;
      } else {
        dev.log(
            'Failed to check subscription status. Status: ${response.statusCode}, Body: ${response.body}');
        // In case of server error, return cached status
        return await getCachedSubscriptionStatus();
      }
    } catch (e) {
      dev.log('Network error checking subscription status: $e');
      // In case of network error, return cached status
      return await getCachedSubscriptionStatus();
    }
  }

  @override
  Future<void> saveSubscriptionStatus(Subscription subscription) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(subscription.toJson());
    await prefs.setString(_subscriptionCacheKey, jsonString);
    dev.log('Subscription status cached.');
  }

  @override
  Future<Subscription> getCachedSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_subscriptionCacheKey);
    if (jsonString != null) {
      final subscription = Subscription.fromJson(json.decode(jsonString));
      dev.log(
          'Loaded cached subscription: isActive=${subscription.isActive}, expires=${subscription.expirationDate}');
      return subscription;
    }
    dev.log('No cached subscription found.');
    return Subscription.inactive();
  }
}
