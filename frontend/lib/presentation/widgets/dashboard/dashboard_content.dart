import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/dashboard_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';

// Screens
import '../../screens/advance payment/advance_payment_screen.dart';
import '../../screens/category/category_screen.dart';
import '../../screens/customer/customer_screen.dart';
import '../../screens/expenses/expenses_screen.dart';
import '../../screens/invoices/invoice_management_screen.dart';
import '../../screens/labor/labor_screen.dart';
import '../../screens/order/order_screen.dart';
import '../../screens/payables/payables_screen.dart';
import '../../screens/payment/payment_screen.dart';
import '../../screens/principal acc/principal_acc_screen.dart';
import '../../screens/product/product_screen.dart';
import '../../screens/profit loss/profit_loss_screen.dart';
import '../../screens/purchases/purchases_screen.dart';
import '../../screens/receipts/receipt_management_screen.dart';
import '../../screens/receivables/receivables_screen.dart';
import '../../screens/returns/return_management_screen.dart';
import '../../screens/sales/sales_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/tax_management_screen.dart';
import '../../screens/vendor/vendor_screen.dart';
import '../../screens/zakat/zakat_screen.dart';
import '../../screens/sale_reports/sale_reports_screen.dart';

import '../../screens/real_estate/project_screen.dart';
import '../../screens/real_estate/plot_screen.dart';
import '../../screens/real_estate/dealer_screen.dart';
import '../../screens/real_estate/real_estate_sale_screen.dart';
import '../../screens/real_estate/finance_screen.dart';
import '../../screens/real_estate/financial_reports_screen.dart';
import '../../screens/real_estate/real_estate_dashboard_screen.dart';

// Dashboard Widgets
import 'sales_overview_chart.dart';
import 'recent_orders_card.dart';
import 'sales_chart_card.dart';
import 'stats_card.dart';

class DashboardContent extends StatelessWidget {
  final int selectedIndex;

  const DashboardContent({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    switch (selectedIndex) {
      case 0:
      case 27:
        return const RealEstateDashboardScreen();
      case 1:
        return const ProjectPage();
      case 2:
        return const PlotPage();
      case 3:
        return const DealerPage();
      case 4:
        return const RealEstateSalePage();
      case 9:
        return const CustomerPage();
      case 25:
        return const RealEstateFinanceScreen();
      case 26:
        return const RealEstateFinancialReportScreen();
      case 24:
        return const SettingsScreen();
      default:
        return _buildPlaceholderContent(context);
    }
  }

  Widget _buildPlaceholderContent(BuildContext context) {
    final title = 'Unknown';

    return Container(
      padding: context.pagePadding,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: context.dialogWidth * 0.5,
              height: context.dialogWidth * 0.5,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
                ),
                borderRadius: BorderRadius.circular(
                  context.borderRadius('large'),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryMaroon.withOpacity(0.3),
                    blurRadius: context.shadowBlur('heavy'),
                    offset: Offset(0, context.smallPadding),
                  ),
                ],
              ),
              child: Icon(
                Icons.construction_rounded,
                size: context.iconSize('xl'),
                color: AppTheme.pureWhite,
              ),
            ),

            SizedBox(height: context.formFieldSpacing * 4),

            Text(
              '$title Page',
              style: TextStyle(
                fontSize: context.headingFontSize,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoalGray,
              ),
            ),

            SizedBox(height: context.formFieldSpacing * 2),

            Text(
              'This page is under construction\nComing soon',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w400,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
