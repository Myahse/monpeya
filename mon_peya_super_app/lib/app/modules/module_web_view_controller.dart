import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'module_api_config.dart';
import 'module_shell_theme.dart';

/// Ensures WebView platform implementations are registered before first use.
Future<void> ensureWebViewPlatformsInitialized() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (WebViewPlatform.instance != null) return;

  if (Platform.isAndroid) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  } else if (Platform.isIOS || Platform.isMacOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }
}

WebViewController createModuleWebViewController({
  required void Function(int progress) onProgress,
  required void Function(String url) onPageStarted,
  required void Function(String url) onPageFinished,
  required void Function(WebResourceError error) onError,
  required void Function(JavaScriptMessage message) onShellMessage,
  required Color backgroundColor,
}) {
  late final PlatformWebViewControllerCreationParams params;
  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    params = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
  } else {
    params = const PlatformWebViewControllerCreationParams();
  }

  final controller = WebViewController.fromPlatformCreationParams(params)
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(backgroundColor)
    ..addJavaScriptChannel('DjoganaShell', onMessageReceived: onShellMessage)
    ..setNavigationDelegate(
      NavigationDelegate(
        onProgress: onProgress,
        onPageStarted: onPageStarted,
        onPageFinished: onPageFinished,
        onWebResourceError: onError,
      ),
    );

  if (controller.platform is AndroidWebViewController) {
    final android = controller.platform as AndroidWebViewController;
    android.setMediaPlaybackRequiresUserGesture(false);
    android.setTextZoom(100);
  }

  if (controller.platform is WebKitWebViewController) {
    final ios = controller.platform as WebKitWebViewController;
    ios.setAllowsBackForwardNavigationGestures(true);
  }

  return controller;
}

/// Builds the final URL with embedded shell query params.
Uri buildModuleRequestUri({
  required String url,
  String? moduleKey,
  String? partnerId,
  String? token,
  ModuleShellTheme? theme,
}) {
  if (url.startsWith('asset:')) {
    throw ArgumentError('Asset URLs cannot be loaded via HTTP request.');
  }

  final uri = Uri.parse(url);
  final params = Map<String, String>.from(uri.queryParameters);
  params.putIfAbsent('embedded', () => '1');
  params.putIfAbsent('platform', () => 'flutter');
  if (moduleKey != null && moduleKey.isNotEmpty) {
    params['moduleKey'] = moduleKey;
  }
  if (partnerId != null && partnerId.isNotEmpty) {
    params['partnerId'] = partnerId;
  }
  if (token != null && token.isNotEmpty) {
    params['token'] = token;
  }
  if (theme != null) {
    params.addAll(theme.queryParams);
  }
  final apiBase = ModuleApiConfig.apiBaseForModuleUrl(url);
  if (apiBase != null && apiBase.isNotEmpty) {
    params.putIfAbsent('apiBase', () => apiBase);
  }
  return uri.replace(queryParameters: params);
}

Future<void> injectNativeBridge(
  WebViewController controller, {
  required ModuleShellTheme theme,
}) {
  final bg = theme.background;
  final vars = theme.cssVariables.replaceAll('\n', ' ');
  return controller.runJavaScript('''
    (function() {
      document.documentElement.classList.add('djogana-embedded');
      document.documentElement.style.cssText += '$vars';
      document.documentElement.style.setProperty('-webkit-tap-highlight-color', 'transparent');
      document.documentElement.style.setProperty('overscroll-behavior-y', 'auto');
      document.documentElement.style.height = 'auto';
      document.documentElement.style.overflowY = 'auto';
      if (document.body) {
        document.body.style.backgroundColor = '$bg';
        document.body.style.height = 'auto';
        document.body.style.overflowY = 'auto';
        document.body.style.minHeight = '100%';
      }
      var meta = document.querySelector('meta[name="viewport"]');
      if (!meta) {
        meta = document.createElement('meta');
        meta.name = 'viewport';
        document.head.appendChild(meta);
      }
      meta.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover';
      window.DjoganaShell = window.DjoganaShell || {
        postMessage: function(payload) {
          DjoganaShell.postMessage(typeof payload === 'string' ? payload : JSON.stringify(payload));
        },
        setTitle: function(title) { DjoganaShell.postMessage(JSON.stringify({ type: 'setTitle', title: title })); },
        close: function() { DjoganaShell.postMessage(JSON.stringify({ type: 'close' })); }
      };
    })();
  ''');
}
