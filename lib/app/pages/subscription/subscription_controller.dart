import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:poteu/domain/entities/subscription_plan.dart';
import 'package:poteu/domain/repositories/subscription_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_presenter.dart';
import 'dart:developer' as dev;
import 'payment_webview_page.dart';

class SubscriptionController extends Controller {
  final SubscriptionPresenter _presenter;
  bool _isLoading = false;
  String? _error;

  // New state for plans
  bool _isLoadingPlans = true;
  List<SubscriptionPlan> _plans = [];
  static const String _lastPlansFetchDateKey =
      'subscription_plans_last_fetch_date';
  static const String _plansCacheKey = 'subscription_plans_cache';

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoadingPlans => _isLoadingPlans;
  List<SubscriptionPlan> get plans => _plans;

  SubscriptionController(SubscriptionRepository subscriptionRepository)
      : _presenter = SubscriptionPresenter(subscriptionRepository) {
    initListeners();
    fetchPlans();
  }

  @override
  void initListeners() {
    _presenter.onPaymentLinkCreated = (String url) async {
      dev.log('Payment link received: $url');
      _isLoading = false;
      refreshUI();

      final result = await Navigator.of(getContext()).push<bool>(
        MaterialPageRoute(
          builder: (context) => PaymentWebviewPage(url: url),
        ),
      );

      if (result == true) {
        // Payment successful, navigate back or show success message
        // For now, just pop the subscription page
        Navigator.of(getContext()).pop(true); // Pop with a success result
      } else if (result == false) {
        // Payment failed or was cancelled by the user
        _error = 'Оплата не удалась или была отменена.';
        refreshUI();
      }
      // If result is null (e.g. user presses back button), do nothing.
    };

    _presenter.onError = (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      refreshUI();
      dev.log('Error creating payment link: $e');
    };

    _presenter.onPlansLoaded = (List<SubscriptionPlan> plans) async {
      dev.log('Subscription plans loaded from network: ${plans.length}');
      _plans = plans;
      _isLoadingPlans = false;
      _error = null;
      refreshUI();
      // Cache the new plans
      try {
        final prefs = await SharedPreferences.getInstance();
        final plansJson = json.encode(plans.map((p) => p.toJson()).toList());
        await prefs.setString(_plansCacheKey, plansJson);
        final today = DateTime.now().toIso8601String().substring(0, 10);
        await prefs.setString(_lastPlansFetchDateKey, today);
        dev.log('Subscription plans cached.');
      } catch (e) {
        dev.log('Failed to cache subscription plans: $e');
      }
    };

    _presenter.onPlansError = (e) {
      dev.log('Error loading subscription plans: $e');
      _error = e.toString();
      _isLoadingPlans = false;
      refreshUI();
    };
  }

  Future<void> fetchPlans() async {
    _isLoadingPlans = true;
    _error = null;
    refreshUI();

    final prefs = await SharedPreferences.getInstance();
    final lastFetchDate = prefs.getString(_lastPlansFetchDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastFetchDate == today) {
      dev.log('Loading subscription plans from cache.');
      final cachedPlansJson = prefs.getString(_plansCacheKey);
      if (cachedPlansJson != null) {
        try {
          final List<dynamic> decodedList = json.decode(cachedPlansJson);
          _plans =
              decodedList.map((p) => SubscriptionPlan.fromJson(p)).toList();
          _isLoadingPlans = false;
          refreshUI();
          dev.log('Successfully loaded plans from cache.');
          return;
        } catch (e) {
          dev.log('Failed to load plans from cache: $e. Fetching from network.');
        }
      }
    }

    dev.log('Fetching subscription plans from network.');
    _presenter.getPlans();
  }

  void purchase(String planType) async {
    _isLoading = true;
    _error = null;
    refreshUI();
    // The backend requires an email for the receipt, as per Tinkoff API.
    // We'll construct a dummy email from the user ID since we don't collect it.
    final userId = await _presenter.subscriptionRepository.getUserId();
    final userEmail = '$userId@poteu.app';
    _presenter.createPaymentLink(planType, userEmail);
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}
