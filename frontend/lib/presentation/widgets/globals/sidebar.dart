import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/providers/category_provider.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/providers/purchase_provider.dart';
import '../../../src/providers/labor_provider.dart';
import '../../../src/providers/receivables_provider.dart';
import '../../../src/providers/payables_provider.dart';
import '../../../src/providers/advance_payment_provider.dart';
import '../../../src/providers/payment_provider.dart';
import '../../../src/providers/expenses_provider.dart';
import '../../../src/providers/zakat_provider.dart';
import '../../../src/providers/return_provider.dart';
import '../../../src/providers/invoice_provider.dart';
import '../../../src/providers/receipt_provider.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
import '../../../src/providers/dashboard_provider.dart';

class LogoutDialogWidget extends StatefulWidget {
  final bool isExpanded;

  const LogoutDialogWidget({super.key, required this.isExpanded});

  @override
  _LogoutDialogWidgetState createState() => _LogoutDialogWidgetState();
}

class _LogoutDialogWidgetState extends State<LogoutDialogWidget> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.borderRadius('medium')),
          ),
          backgroundColor: AppTheme.creamWhite,
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppTheme.primaryMaroon,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                AppLocalizations.of(context)!.confirmLogout,
                style: TextStyle(
                  fontSize: context.headerFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.logoutMessage,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.pureWhite,
                                ),
                              ),
                            ),
                            SizedBox(width: context.smallPadding),
                            Text(
                              AppLocalizations.of(context)!.loggingOut,
                              style: TextStyle(
                                fontSize: context.captionFontSize,
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AppTheme.primaryMaroon,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.borderRadius('medium'),
                          ),
                        ),
                        margin: EdgeInsets.all(context.mainPadding),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                      // 1. Stop background processes and reset menu
                      final dashboardProvider = context.read<DashboardProvider>();
                      dashboardProvider.stopPolling();
                      dashboardProvider.selectMenu(27); // Reset to Dashboard
                      
                      // 2. Clear UI state
                      Navigator.of(dialogContext).pop();
                      
                      // 3. Trigger logout in background
                      authProvider.logout();

                      // 4. Force immediate navigation to login
                      debugPrint('🔵 Redirecting to login...');
                      HiBlankitsApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                      debugPrint('✅ Navigation command sent');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    foregroundColor: AppTheme.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.borderRadius(),
                      ),
                    ),
                    elevation: 2,
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.pureWhite,
                      ),
                    ),
                  )
                      : Text(
                    AppLocalizations.of(context)!.logout,
                    style: TextStyle(
                      fontSize: context.bodyFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: Container(
          padding: EdgeInsets.all(
            widget.isExpanded
                ? context.smallPadding / 1.5
                : context.smallPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(context.borderRadius()),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
          ),
          child: widget.isExpanded
              ? Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red.shade300,
                size: context.iconSize('small'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                AppLocalizations.of(context)!.logout,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite,
                ),
              ),
            ],
          )
              : Icon(
            Icons.logout_rounded,
            color: Colors.red.shade300,
            size: context.iconSize('medium'),
          ),
        ),
      ),
    );
  }
}

class PremiumSidebar extends StatelessWidget {
  final bool isExpanded;
  final int selectedIndex;
  final Function(int) onMenuSelected;
  final VoidCallback onToggle;

  const PremiumSidebar({
    super.key,
    required this.isExpanded,
    required this.selectedIndex,
    required this.onMenuSelected,
    required this.onToggle,
  });

  List<Map<String, dynamic>> getMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final salesCount = context.watch<SalesProvider>().sales.length.toString();
    final purchasesCount = context.watch<PurchaseProvider>().purchases.length.toString();
    final productsCount = context.watch<ProductProvider>().products.length.toString();
    final categoriesCount = context.watch<CategoryProvider>().categories.length.toString();
    final customersCount = context.watch<CustomerProvider>().customers.length.toString();
    final vendorsCount = context.watch<VendorProvider>().vendors.length.toString();
    final laborsCount = context.watch<LaborProvider>().labors.length.toString();
    final receivablesCount = context.watch<ReceivablesProvider>().receivables.length.toString();
    final payablesCount = context.watch<PayablesProvider>().payables.length.toString();
    final advancePaymentsCount = context.watch<AdvancePaymentProvider>().advancePayments.length.toString();
    final paymentsCount = context.watch<PaymentProvider>().payments.length.toString();
    final expensesCount = context.watch<ExpensesProvider>().expenses.length.toString();
    final zakatCount = context.watch<ZakatProvider>().zakatRecords.length.toString();
    final returnsCount = context.watch<ReturnProvider>().returns.length.toString();
    final invoicesCount = context.watch<InvoiceProvider>().invoices.length.toString();
    final receiptsCount = context.watch<ReceiptProvider>().receipts.length.toString();
    final projectsCount = context.watch<RealEstateProvider>().projects.length.toString();
    final plotsCount = context.watch<RealEstateProvider>().plots.length.toString();
    final dealersCount = context.watch<RealEstateProvider>().dealers.length.toString();
    final incomesCount = context.watch<RealEstateProvider>().incomes.length.toString();
    final expensesLogCount = context.watch<RealEstateProvider>().expenses.length.toString();

    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.currentUser?.role ?? 'ADMIN';

    final List<Map<String, dynamic>> allItems = [
      {'icon': Icons.dashboard_rounded, 'title': l10n.dashboard, 'badge': null, 'index': 27, 'roles': ['ADMIN', 'MANAGER', 'SALES_AGENT', 'ACCOUNTANT']},
      {'icon': Icons.business_rounded, 'title': l10n.projects, 'badge': projectsCount, 'index': 1, 'roles': ['ADMIN', 'MANAGER', 'SALES_AGENT']},
      {'icon': Icons.map_rounded, 'title': l10n.plots, 'badge': plotsCount, 'index': 2, 'roles': ['ADMIN', 'MANAGER', 'SALES_AGENT']},
      {'icon': Icons.people_rounded, 'title': l10n.customers, 'badge': customersCount, 'index': 9, 'roles': ['ADMIN', 'MANAGER', 'SALES_AGENT']},
      {'icon': Icons.point_of_sale_rounded, 'title': l10n.realEstateSales, 'badge': null, 'index': 4, 'roles': ['ADMIN', 'MANAGER', 'SALES_AGENT']},
      {'icon': Icons.people_outline_rounded, 'title': l10n.dealers, 'badge': dealersCount, 'index': 3, 'roles': ['ADMIN', 'MANAGER', 'SALES_AGENT']},
      {
        'icon': Icons.account_balance_wallet_outlined,
        'title': 'Income & Expenses',
        'badge': (int.parse(incomesCount) + int.parse(expensesLogCount)).toString(),
        'index': 25,
        'roles': ['ADMIN', 'MANAGER', 'ACCOUNTANT']
      },
      {'icon': Icons.bar_chart_rounded, 'title': 'Finance Reports', 'badge': null, 'index': 26, 'roles': ['ADMIN', 'MANAGER', 'ACCOUNTANT']},
    ];

    return allItems.where((item) => (item['roles'] as List<String>).contains(userRole)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isExpanded
          ? context.sidebarExpandedWidth
          : context.sidebarCollapsedWidth,
      height: 100.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.charcoalGray, Color(0xFF141E30)], // Deep Blue-Gray
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(context.cardPadding / 1.5),
            decoration: BoxDecoration(
              color: AppTheme.primaryMaroon.withOpacity(0.15),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.pureWhite.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8), // Clean spacing for the new logo

                // Premium Icon Logo
                Container(
                  width: isExpanded ? 64 : 48,
                  height: isExpanded ? 64 : 48,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentGold.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/iconic_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                if (isExpanded) ...[
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Iconic Estate",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.pureWhite,
                            letterSpacing: 1.2,
                            fontFamily: 'Outfit', // Using premium font if available
                          ),
                        ),
                        Text(
                          "A SIGN OF TRUST",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accentGold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    isExpanded
                        ? Icons.arrow_back_ios_new_rounded
                        : Icons.arrow_forward_ios_rounded,
                    color: AppTheme.accentGold,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: Builder(
              builder: (context) {
                final menuItems = getMenuItems(context);
                final l10n = AppLocalizations.of(context)!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final itemIndex = item['index'] ?? index;
                    final isSelected = itemIndex == selectedIndex;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onMenuSelected(itemIndex),
                          borderRadius: BorderRadius.circular(8),
                          hoverColor: AppTheme.pureWhite.withOpacity(0.08),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: isExpanded ? 12 : 8,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accentGold.withOpacity(0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: AppTheme.accentGold, width: 2)
                                  : Border.all(color: Colors.transparent, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item['icon'],
                                  color: isSelected ? AppTheme.accentGold : AppTheme.pureWhite,
                                  size: 22,
                                ),
                                if (isExpanded) ...[
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      item['title'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                        color: AppTheme.pureWhite,
                                      ),
                                    ),
                                  ),
                                  if (item['badge'] != null && item['badge'] != '0')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryMaroon,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.pureWhite.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        item['badge'],
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.pureWhite,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.pureWhite.withOpacity(0.1),
                  width: 0.1.w,
                ),
              ),
            ),
            child: Column(
              children: [
                if (isExpanded) ...[
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final l10n = AppLocalizations.of(context)!;
                      final user = authProvider.currentUser;
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: context.iconSize('medium') / 2,
                            backgroundColor: AppTheme.accentGold,
                            child: Text(
                              user?.fullName.isNotEmpty == true
                                  ? user!.fullName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: context.bodyFontSize,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryMaroon,
                              ),
                            ),
                          ),
                          SizedBox(width: context.smallPadding),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? l10n.guest,
                                  style: TextStyle(
                                    fontSize: context.bodyFontSize * 1.1,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.pureWhite,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user?.email ?? l10n.noActiveSession,
                                  style: TextStyle(
                                    fontSize: context.captionFontSize * 1.1,
                                    fontWeight: FontWeight.w300,
                                    color: AppTheme.pureWhite.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const LogoutDialogWidget(isExpanded: true),
                        ],
                      );
                    },
                  ),
                ] else ...[
                  const LogoutDialogWidget(isExpanded: false),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
