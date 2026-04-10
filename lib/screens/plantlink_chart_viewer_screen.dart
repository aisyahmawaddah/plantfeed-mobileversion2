import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PlantLinkChartViewerScreen extends StatefulWidget {
  final String embedUrl;
  final String chartTitle;
  final String description;

  const PlantLinkChartViewerScreen({
    Key? key,
    required this.embedUrl,
    required this.chartTitle,
    required this.description,
  }) : super(key: key);

  @override
  State<PlantLinkChartViewerScreen> createState() => _PlantLinkChartViewerScreenState();
}

class _PlantLinkChartViewerScreenState extends State<PlantLinkChartViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
        onWebResourceError: (error) => debugPrint('WebView error: ${error.description}'),
        onNavigationRequest: (request) {
          debugPrint('Navigating to: ${request.url}');
          return NavigationDecision.navigate;
        },
      ));

    if (widget.embedUrl.isNotEmpty) {
      _controller.loadRequest(
        Uri.parse(widget.embedUrl),
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
    } else {
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chartTitle),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (widget.description.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              color: Colors.green.shade50,
              child: Text(widget.description),
            ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.green)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
