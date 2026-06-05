import 'package:flutter/material.dart';

import 'service_scaffold.dart';

class ServiceModuleScreen extends StatelessWidget {
  const ServiceModuleScreen({super.key, required this.moduleId, this.bundleUrl});
  final String moduleId;
  final String? bundleUrl;

  @override
  Widget build(BuildContext context) {
    return ServiceScaffold(
      title: 'Service Module',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('moduleId: $moduleId'),
          const SizedBox(height: 8),
          Text('bundleUrl: ${bundleUrl ?? '(none)'}'),
          const SizedBox(height: 16),
          const Text('Next step: load the module bundle natively.'),
        ],
      ),
    );
  }
}

