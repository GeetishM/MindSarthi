import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shimmer/shimmer.dart';

class SpotifyPlayerScreen extends StatefulWidget {
  final String playlistId;

  const SpotifyPlayerScreen({super.key, required this.playlistId});

  @override
  State<SpotifyPlayerScreen> createState() => _SpotifyPlayerScreenState();
}

class _SpotifyPlayerScreenState extends State<SpotifyPlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://open.spotify.com/embed/playlist/${widget.playlistId}'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      appBar: AppBar(
        title: const Text('Relaxing Music'),
        backgroundColor: Colors.deepPurple[100],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: WebViewWidget(controller: _controller),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.deepPurple[50],
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 20,
                        width: 200,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 20,
                        width: 150,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
