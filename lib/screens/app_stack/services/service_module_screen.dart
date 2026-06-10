import 'package:flutter/material.dart';

import '../modules/module_web_view_screen.dart';
import 'service_scaffold.dart';

class ServiceModuleScreen extends StatelessWidget {
  const ServiceModuleScreen({
    super.key,
    required this.moduleId,
    this.bundleUrl,
    this.url,
    this.title,
  });

  final String moduleId;
  final String? bundleUrl;
  final String? url;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return ModuleWebViewScreen(
        title: title ?? 'Module',
        url: url!,
        moduleId: moduleId,
      );
    }

    return ServiceScaffold(
      title: 'Service Module',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('moduleId: $moduleId'),
          const SizedBox(height: 8),
          Text('bundleUrl: ${bundleUrl ?? '(none)'}'),
          const SizedBox(height: 16),
          const Text('Provide a url param to open the module in WebView.'),
        ],
      ),
    );
  }
}
