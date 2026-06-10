import 'package:flutter/material.dart';

import '../create_tenant_wizard.dart';

export '../create_tenant_wizard.dart';

/// Entry screen for tenant creation — opens [CreateTenantWizard].
class CreateTenantScreen extends StatelessWidget {
  const CreateTenantScreen({
    super.key,
    required this.onClose,
    this.onCreated,
  });

  final VoidCallback onClose;
  final VoidCallback? onCreated;

  @override
  Widget build(BuildContext context) {
    return CreateTenantWizard(onClose: onClose, onCreated: onCreated);
  }
}
