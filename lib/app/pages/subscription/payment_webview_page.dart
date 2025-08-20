import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:developer' as dev;
import 'package:url_launcher/url_launcher.dart';

class PaymentWebviewPage extends StatefulWidget {
  final String url;

  const PaymentWebviewPage({Key? key, required this.url}) : super(key: key);

  @override
  State<PaymentWebviewPage> createState() => _PaymentWebviewPageState();
}

class _PaymentWebviewPageState extends State<PaymentWebviewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            dev.log('WebView page started loading: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            dev.log('WebView page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) async {
            dev.log('WebView navigating to: ${request.url}');
            final uri = Uri.parse(request.url);

            // Handle success/fail URLs first, as they are the final state.
            if (request.url.contains('success')) {
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            if (request.url.contains('fail')) {
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }

            // Handle deep links to banking apps (like Tinkoff)
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                dev.log('Could not launch deep link: ${uri.toString()}. Error: $e');
              }
              // ALWAYS prevent the webview from trying to handle the deep link itself.
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оплата')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
