import 'package:flutter/material.dart';
import 'package:frontend/src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/sales/return_management_widget.dart';

class ReturnManagementScreen extends StatelessWidget {
  const ReturnManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      appBar: AppBar(
        title: Text(l10n.returnManagement),
        backgroundColor: AppTheme.primaryMaroon,
        foregroundColor: AppTheme.pureWhite,
        elevation: 0,
      ),
      body: const ReturnManagementWidget(),
    );
  }
}
