import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:url_launcher/url_launcher.dart';
import 'subscription_presenter.dart';
import 'dart:developer' as dev;

class SubscriptionController extends Controller {
  final SubscriptionPresenter _presenter;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  SubscriptionController(subscriptionRepository)
      : _presenter = SubscriptionPresenter(subscriptionRepository) {
    initListeners();
  }

  @override
  void initListeners() {
    _presenter.onPaymentLinkCreated = (String url) async {
      dev.log('Payment link received: $url');
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _error = 'Не удалось открыть ссылку на оплату.';
        dev.log('Could not launch $url');
      }
      _isLoading = false;
      refreshUI();
    };

    _presenter.onError = (e) {
      _error = e.toString();
      _isLoading = false;
      refreshUI();
      dev.log('Error creating payment link: $e');
    };
  }

  void purchase(String planType) {
    _isLoading = true;
    _error = null;
    refreshUI();
    _presenter.createPaymentLink(planType);
  }

  @override
  void onDisposed() {
    _presenter.dispose();
    super.onDisposed();
  }
}