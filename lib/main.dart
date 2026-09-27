import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Android specific WebView features
import 'package:webview_flutter_android/webview_flutter_android.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    title: 'LB AI',
    debugShowCheckedModeBanner: false,
    home: LbAiApp(),
  ));
}

class LbAiApp extends StatefulWidget {
  const LbAiApp({super.key});

  @override
  State<LbAiApp> createState() => _LbAiAppState();
}

class _LbAiAppState extends State<LbAiApp> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  final String targetUrl =
      'https://ais-pre-dsn6hdpglhqplkpao3jfk6-672525115817.europe-west1.run.app';

  @override
  void initState() {
    super.initState();

    final PlatformWebViewControllerCreationParams params =
        const PlatformWebViewControllerCreationParams();

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF04060C))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            // تجاهل أخطاء الكاش العابرة
            if (error.errorCode != -1) {
              setState(() {
                _errorMessage = 'خطأ في الاتصال: ${error.description}';
                _isLoading = false;
              });
            }
          },
        ),
      );

    // تفعيل التخزين المحلي والـ DOM Storage لنظام أندرويد
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadRequest(Uri.parse(targetUrl));
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060C),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Container(
                color: const Color(0xFF04060C),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'LB AI Super-Engine Loading...',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_errorMessage != null)
              Container(
                color: const Color(0xFF04060C),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5FF),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          _controller.reload();
                        },
                        child: const Text('إعادة المحاولة (Retry)'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
