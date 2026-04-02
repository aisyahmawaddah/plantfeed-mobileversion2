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
  State<PlantLinkChartViewerScreen> createState() =>
      _PlantLinkChartViewerScreenState();
}

class _PlantLinkChartViewerScreenState
    extends State<PlantLinkChartViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _isLoading = false),
      ))
      ..loadRequest(Uri.parse(widget.embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chartTitle),
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (widget.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.cyan.shade50,
              child: Text(widget.description,
                  style: const TextStyle(fontSize: 14)),
            ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                      child: CircularProgressIndicator(color: Colors.cyan)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
