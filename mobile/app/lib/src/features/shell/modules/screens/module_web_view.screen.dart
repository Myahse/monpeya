import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/themes/module_shell.theme.dart';
import 'package:app/src/core/modules/controllers/module_web_view.controller.dart' as web;
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/shell/scopes/app_stack.scope.dart';

/// Full-screen module host. Flutter owns the chrome; web content is edge-to-edge.
class ModuleWebViewScreen extends StatefulWidget {
  const ModuleWebViewScreen({
    super.key,
    required this.title,
    required this.url,
    this.moduleId,
    this.isAssetModule = false,
    this.assetPath,
    this.partnerId,
    this.moduleKey,
  });

  final String title;
  final String url;
  final String? moduleId;
  final bool isAssetModule;
  final String? assetPath;
  final String? partnerId;
  final String? moduleKey;

  factory ModuleWebViewScreen.fromModule(AppModule module) {
    return ModuleWebViewScreen(
      title: module.name,
      url: module.url,
      moduleId: module.id.toString(),
      isAssetModule: module.isAssetModule,
      assetPath: module.isAssetModule ? module.assetPath : null,
      partnerId: module.partnerId,
      moduleKey: module.moduleKey,
    );
  }

  @override
  State<ModuleWebViewScreen> createState() => _ModuleWebViewScreenState();
}

class _ModuleWebViewScreenState extends State<ModuleWebViewScreen> {
  WebViewController? _mobileController;
  WebviewController? _windowsController;

  var _loading = true;
  var _mainFrameLoaded = false;
  var _contentVisible = false;
  String? _error;
  Timer? _loadTimeout;

  bool get _useWindowsWebView => !kIsWeb && Platform.isWindows;

  bool get _useMobileWebView =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    _startLoadTimeout();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_useWindowsWebView) {
        _initWindowsWebView();
      } else if (_useMobileWebView) {
        _initMobileWebView();
      } else {
        setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    _windowsController?.dispose();
    super.dispose();
  }

  void _startLoadTimeout() {
    _loadTimeout?.cancel();
    _loadTimeout = Timer(const Duration(seconds: 25), () {
      if (!mounted || _mainFrameLoaded || _error != null) return;
      setState(() {
        _loading = false;
        _error =
            'Délai dépassé.\n\n'
            '• Vite: rental :3001, construction :3002, collection :3003\n'
            '• Téléphone et PC sur le même Wi-Fi\n'
            '• URL: ${widget.url}';
      });
    });
  }

  Future<void> _initMobileWebView() async {
    await web.ensureWebViewPlatformsInitialized();

    if (!mounted) return;
    final shellTheme = ModuleShellTheme.fromContext(context);
    final bg = Theme.of(context).colorScheme.surface;
    final token = await AuthStore.authToken();

    final controller = web.createModuleWebViewController(
      backgroundColor: bg,
      onProgress: (_) {},
      onPageStarted: (_) {
        if (!mounted) return;
        setState(() {
          _loading = true;
          _error = null;
          _mainFrameLoaded = false;
          _contentVisible = false;
        });
        _startLoadTimeout();
      },
      onPageFinished: (_) => _markLoaded(),
      onError: (err) {
        if (!mounted) return;
        if (err.isForMainFrame == false) return;
        _loadTimeout?.cancel();
        setState(() {
          _loading = false;
          _error = err.description;
        });
      },
      onShellMessage: _onShellMessage,
    );

    _mobileController = controller;
    await _loadMobileContent(controller, token, shellTheme);
    if (mounted) setState(() {});
  }

  ModuleShellTheme _shellTheme() => ModuleShellTheme.fromContext(context);

  Future<void> _initWindowsWebView() async {
    final token = await AuthStore.authToken();
    final controller = WebviewController();
    await controller.initialize();

    if (!controller.value.isInitialized) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'WebView2 indisponible sur Windows.';
      });
      return;
    }

    controller.loadingState.listen((state) {
      if (!mounted) return;
      if (state == LoadingState.navigationCompleted) {
        _markLoaded();
      } else if (state == LoadingState.loading) {
        setState(() => _loading = true);
      }
    });

    _windowsController = controller;

    try {
      if (widget.isAssetModule) {
        setState(() {
          _loading = false;
          _error = 'Les modules locaux (asset) ne sont pas supportés sur Windows.';
        });
        return;
      }

      final uri = web.buildModuleRequestUri(
        url: widget.url,
        moduleKey: widget.moduleKey,
        partnerId: widget.partnerId,
        token: token,
        theme: _shellTheme(),
      );
      await controller.loadUrl(uri.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMobileContent(
    WebViewController controller,
    String? token,
    ModuleShellTheme theme,
  ) async {
    if (widget.isAssetModule && widget.assetPath != null) {
      await controller.loadFlutterAsset(widget.assetPath!);
      return;
    }

    final uri = web.buildModuleRequestUri(
      url: widget.url,
      moduleKey: widget.moduleKey,
      partnerId: widget.partnerId,
      token: token,
      theme: theme,
    );
    await controller.loadRequest(uri);
  }

  Future<void> _markLoaded() async {
    _loadTimeout?.cancel();
    final theme = _shellTheme();
    if (_mobileController != null) {
      await web.injectNativeBridge(_mobileController!, theme: theme);
    }
    if (!mounted) return;
    setState(() {
      _mainFrameLoaded = true;
      _loading = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (mounted) setState(() => _contentVisible = true);
  }

  void _onShellMessage(JavaScriptMessage message) {
    try {
      final raw = message.message;
      if (raw.startsWith('{') && raw.contains('"close"')) {
        _handleBack();
      }
    } catch (_) {}
  }

  Future<void> _handleBack() async {
    final appStack = AppStackScope.maybeOf(context);

    if (_mobileController != null && await _mobileController!.canGoBack()) {
      await _mobileController!.goBack();
      return;
    }

    if (appStack != null) {
      appStack.exitModule();
      return;
    }
  }

  Future<void> _reload() async {
    setState(() {
      _error = null;
      _loading = true;
      _mainFrameLoaded = false;
      _contentVisible = false;
    });
    _startLoadTimeout();

    if (_useWindowsWebView && _windowsController != null) {
      final token = await AuthStore.authToken();
      final uri = web.buildModuleRequestUri(
        url: widget.url,
        moduleKey: widget.moduleKey,
        partnerId: widget.partnerId,
        token: token,
        theme: _shellTheme(),
      );
      await _windowsController!.loadUrl(uri.toString());
      return;
    }

    final controller = _mobileController;
    if (controller == null) return;
    final token = await AuthStore.authToken();
    await _loadMobileContent(controller, token, _shellTheme());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: _buildBody(cs),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_error != null) {
      return _ModuleErrorState(message: _error!, onRetry: _reload);
    }

    if (_useWindowsWebView && _windowsController != null) {
      return Webview(_windowsController!);
    }

    if (_useMobileWebView) {
      final controller = _mobileController;
      if (controller == null) {
        return Center(child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2));
      }
      return Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _contentVisible ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: ColoredBox(
              color: cs.surface,
              child: WebViewWidget(controller: controller),
            ),
          ),
          if (_loading && !_mainFrameLoaded)
            ColoredBox(
              color: cs.surface,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: cs.primary,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'WebView non disponible sur cette plateforme.',
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _ModuleErrorState extends StatelessWidget {
  const _ModuleErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger le module',
              style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
