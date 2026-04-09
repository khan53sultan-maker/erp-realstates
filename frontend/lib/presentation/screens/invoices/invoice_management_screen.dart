import 'package:flutter/material.dart';
import 'package:frontend/src/theme/app_theme.dart';
import '../../widgets/sales/invoice_management_widget.dart';

class InvoiceManagementScreen extends StatelessWidget {
  const InvoiceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      appBar: AppBar(
        title: const Text('Invoice Management'),
        backgroundColor: AppTheme.primaryMaroon,
        foregroundColor: AppTheme.pureWhite,
        elevation: 0,
      ),
      body: const InvoiceManagementWidget(),
    );
  }
}
