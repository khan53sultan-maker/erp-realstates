// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:sizer/sizer.dart';
//
// import '../../../l10n/app_localizations.dart';
// import '../../../src/providers/dashboard_provider.dart';
// import '../../../src/theme/app_theme.dart';
// import '../../../src/utils/responsive_breakpoints.dart';
//
// // Screens
// import '../../screens/advance payment/advance_payment_screen.dart';
// import '../../screens/category/category_screen.dart';
// import '../../screens/customer/customer_screen.dart';
// import '../../screens/expenses/expenses_screen.dart';
// import '../../screens/invoices/invoice_management_screen.dart';
// import '../../screens/labor/labor_screen.dart';
// import '../../screens/order/order_screen.dart';
// import '../../screens/payables/payables_screen.dart';
// import '../../screens/payment/payment_screen.dart';
// import '../../screens/principal acc/principal_acc_screen.dart';
// import '../../screens/product/product_screen.dart';
// import '../../screens/profit loss/profit_loss_screen.dart';
// import '../../screens/purchases/purchases_screen.dart';
// import '../../screens/receipts/receipt_management_screen.dart';
// import '../../screens/receivables/receivables_screen.dart';
// import '../../screens/returns/return_management_screen.dart';
// import '../../screens/sales/sales_screen.dart';
// import '../../screens/settings/settings_screen.dart';
// import '../../screens/tax_management_screen.dart';
// import '../../screens/vendor/vendor_screen.dart';
// import '../../screens/zakat/zakat_screen.dart';
//
// // Dashboard Widgets
// // import 'quick_actions_card.dart'; // REMOVED: 4 colored boxes
// import 'recent_orders_card.dart';
// import 'sales_chart_card.dart';
// import 'stats_card.dart';
//
// class DashboardContent extends StatelessWidget {
//   final int selectedIndex;
//
//   const DashboardContent({super.key, required this.selectedIndex});
//
//   @override
//   Widget build(BuildContext context) {
//     switch (selectedIndex) {
//       case 0:
//         return _buildDashboard(context);
//       case 1:
//         return const SalesPage();
//       case 2:
//         return const OrderPage();
//       case 3:
//         return const PurchasesScreen();
//       case 4:
//         return const ProductPage();
//       case 5:
//         return const CategoryPage();
//       case 6:
//         return const CustomerPage();
//       case 7:
//         return const VendorPage();
//       case 8:
//         return const LaborPage();
//       case 9:
//         return const ReceivablesPage();
//       case 10:
//         return const PayablesPage();
//       case 11:
//         return const AdvancePaymentPage();
//       case 12:
//         return const PaymentPage();
//       case 13:
//         return const ExpensesPage();
//       case 14:
//         return const PrincipalAccountPage();
//       case 15:
//         return const ZakatPage();
//       case 16:
//         return const ProfitLossPage();
//       case 17:
//         return const TaxManagementScreen();
//       case 18:
//         return const ReturnManagementScreen();
//       case 19:
//         return const InvoiceManagementScreen();
//       case 20:
//         return const ReceiptManagementScreen();
//       case 21:
//         return const SettingsScreen();
//       default:
//         return _buildPlaceholderContent(context);
//     }
//   }
//
//   Widget _buildDashboard(BuildContext context) {
//     return Consumer<DashboardProvider>(
//       builder: (context, provider, child) {
//
//         // 1. Initial Loading State
//         if (provider.isLoading && provider.analytics == null) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         // 2. Error State
//         if (provider.errorMessage != null && provider.analytics == null) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Failed to load dashboard data',
//                   style: TextStyle(color: Colors.grey[700], fontSize: 16),
//                 ),
//                 SizedBox(height: 2.h),
//                 ElevatedButton(
//                   onPressed: () => provider.loadDashboardAnalytics(),
//                   child: const Text('Retry'),
//                 ),
//               ],
//             ),
//           );
//         }
//
//         // 3. Real Data
//         final stats = provider.dashboardStats;
//
//         return Container(
//           padding: context.pagePadding / 2.5,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Welcome Section
//                 _buildWelcomeSection(context),
//
//                 SizedBox(height: context.formFieldSpacing * 3),
//
//                 // --- STATS CARDS (RESTORED & ACTIVE) ---
//                 LayoutBuilder(
//                   builder: (context, constraints) {
//                     final cardCount = context.statsCardColumns.clamp(2, 4);
//                     final cardWidth =
//                         (constraints.maxWidth -
//                             context.cardPadding * (cardCount - 1)) /
//                             cardCount;
//                     return Wrap(
//                       spacing: context.cardPadding,
//                       runSpacing: context.formFieldSpacing,
//                       children: [
//                         SizedBox(
//                           width: cardWidth,
//                           child: StatsCard(
//                             title: AppLocalizations.of(context)!.totalSales,
//                             value: stats['totalSales']['value'],
//                             change: stats['totalSales']['change'],
//                             isPositive: stats['totalSales']['isPositive'],
//                             icon: Icons.trending_up_rounded,
//                             color: Colors.green,
//                           ),
//                         ),
//                         SizedBox(
//                           width: cardWidth,
//                           child: StatsCard(
//                             title: AppLocalizations.of(context)!.totalOrders,
//                             value: stats['totalOrders']['value'],
//                             change: stats['totalOrders']['change'],
//                             isPositive: stats['totalOrders']['isPositive'],
//                             icon: Icons.shopping_bag_rounded,
//                             color: Colors.blue,
//                           ),
//                         ),
//                         SizedBox(
//                           width: cardWidth,
//                           child: StatsCard(
//                             title: AppLocalizations.of(context)!.activeCustomers,
//                             value: stats['activeCustomers']['value'],
//                             change: stats['activeCustomers']['change'],
//                             isPositive: stats['activeCustomers']['isPositive'],
//                             icon: Icons.people_rounded,
//                             color: Colors.indigo,
//                           ),
//                         ),
//                         SizedBox(
//                           width: cardWidth,
//                           child: StatsCard(
//                             title: AppLocalizations.of(context)!.activeVendors,
//                             value: stats['activeVendors']['value'],
//                             change: stats['activeVendors']['change'],
//                             isPositive: stats['activeVendors']['isPositive'],
//                             icon: Icons.store_rounded,
//                             color: Colors.teal,
//                           ),
//                         ),
//                         SizedBox(
//                           width: cardWidth,
//                           child: StatsCard(
//                             title: AppLocalizations.of(context)!.pendingOrders,
//                             value: stats['pendingOrders']?['value'] ?? '0',
//                             change: stats['pendingOrders']?['change'] ?? '0',
//                             isPositive: stats['pendingOrders']?['isPositive'] ?? false,
//                             icon: Icons.pending_actions_rounded,
//                             color: Colors.orange,
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//
//                 SizedBox(height: context.formFieldSpacing * 3),
//
//                 // --- Main Content Row (Charts & Recent Orders) ---
//                 // Removed QuickActionsCard (the 4 colored boxes)
//                 LayoutBuilder(
//                   builder: (context, constraints) {
//                     // Responsive layout
//                     if (constraints.maxWidth < 900) {
//                       return Column(
//                         children: [
//                           // Sales Chart (Restored)
//                           const SizedBox(
//                             height: 400,
//                             child: SalesChartCard(),
//                           ),
//
//                           SizedBox(height: context.formFieldSpacing * 2),
//
//                           // Recent Orders (Restored)
//                           const RecentOrdersCard(),
//                         ],
//                       );
//                     }
//
//                     return Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Left Column (Sales Chart Only)
//                         Expanded(
//                           flex: context.tableColumnFlexes[0],
//                           child: Column(
//                             children: [
//                               // Sales Chart (Restored)
//                               SizedBox(
//                                 height: context.chartHeight,
//                                 child: const SalesChartCard(),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         SizedBox(width: context.cardPadding),
//
//                         // Right Column (Recent Orders Restored)
//                         Expanded(
//                           flex: context.tableColumnFlexes[1],
//                           child: const RecentOrdersCard(),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//
//                 SizedBox(height: context.formFieldSpacing * 2),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildWelcomeSection(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(context.cardPadding),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
//         ),
//         borderRadius: BorderRadius.circular(context.borderRadius()),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   AppLocalizations.of(context)!.welcomeToPos,
//                   style: TextStyle(
//                     fontSize: context.headingFontSize,
//                     fontWeight: FontWeight.w700,
//                     color: AppTheme.pureWhite,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//                 SizedBox(height: context.formFieldSpacing),
//                 Text(
//                   AppLocalizations.of(context)!.welcomeTagline,
//                   style: TextStyle(
//                     fontSize: context.bodyFontSize,
//                     fontWeight: FontWeight.w300,
//                     color: AppTheme.pureWhite.withOpacity(0.9),
//                     height: 1.4,
//                   ),
//                 ),
//                 SizedBox(height: context.formFieldSpacing * 2),
//                 Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: context.cardPadding,
//                     vertical: context.smallPadding,
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppTheme.accentGold,
//                     borderRadius: BorderRadius.circular(
//                       context.borderRadius('small'),
//                     ),
//                   ),
//                   child: Text(
//                     '${AppLocalizations.of(context)!.today}: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
//                     style: TextStyle(
//                       fontSize: context.captionFontSize,
//                       fontWeight: FontWeight.w600,
//                       color: AppTheme.primaryMaroon,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             width: context.dialogWidth / 5,
//             height: context.dialogWidth / 5,
//             decoration: BoxDecoration(
//               color: AppTheme.pureWhite.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(context.cardPadding),
//             ),
//             child: Image.asset('assets/images/hiBlankits.png'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPlaceholderContent(BuildContext context) {
//     final List<String> pageNames = [
//       AppLocalizations.of(context)!.dashboard,
//       AppLocalizations.of(context)!.sales,
//       AppLocalizations.of(context)!.orders,
//       AppLocalizations.of(context)!.orderItems,
//       AppLocalizations.of(context)!.products,
//       AppLocalizations.of(context)!.category,
//       AppLocalizations.of(context)!.customers,
//       AppLocalizations.of(context)!.vendor,
//       AppLocalizations.of(context)!.labor,
//       AppLocalizations.of(context)!.receivables,
//       AppLocalizations.of(context)!.payables,
//       AppLocalizations.of(context)!.advancePayment,
//       AppLocalizations.of(context)!.payments,
//       AppLocalizations.of(context)!.expenses,
//       AppLocalizations.of(context)!.principalAccount,
//       AppLocalizations.of(context)!.zakat,
//       AppLocalizations.of(context)!.profitLoss,
//       AppLocalizations.of(context)!.taxManagement,
//       AppLocalizations.of(context)!.returns,
//       AppLocalizations.of(context)!.invoices,
//       AppLocalizations.of(context)!.receipts,
//       AppLocalizations.of(context)!.settings,
//     ];
//
//     final title = (selectedIndex >= 0 && selectedIndex < pageNames.length)
//         ? pageNames[selectedIndex]
//         : 'Unknown';
//
//     return Container(
//       padding: context.pagePadding,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: context.dialogWidth * 0.5,
//               height: context.dialogWidth * 0.5,
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
//                 ),
//                 borderRadius: BorderRadius.circular(
//                   context.borderRadius('large'),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppTheme.primaryMaroon.withOpacity(0.3),
//                     blurRadius: context.shadowBlur('heavy'),
//                     offset: Offset(0, context.smallPadding),
//                   ),
//                 ],
//               ),
//               child: Icon(
//                 Icons.construction_rounded,
//                 size: context.iconSize('xl'),
//                 color: AppTheme.pureWhite,
//               ),
//             ),
//
//             SizedBox(height: context.formFieldSpacing * 4),
//
//             Text(
//               '$title ${AppLocalizations.of(context)!.page}',
//               style: TextStyle(
//                 fontSize: context.headingFontSize,
//                 fontWeight: FontWeight.w700,
//                 color: AppTheme.charcoalGray,
//               ),
//             ),
//
//             SizedBox(height: context.formFieldSpacing * 2),
//
//             Text(
//               '${AppLocalizations.of(context)!.underConstruction}\n${AppLocalizations.of(context)!.comingSoon}',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: context.bodyFontSize,
//                 fontWeight: FontWeight.w400,
//                 color: Colors.grey[600],
//                 height: 1.5,
//               ),
//             ),
//
//             SizedBox(height: context.formFieldSpacing * 4),
//
//             Material(
//               color: Colors.transparent,
//               child: InkWell(
//                 onTap: () {
//                   Provider.of<DashboardProvider>(
//                     context,
//                     listen: false,
//                   ).selectMenu(0);
//                 },
//                 borderRadius: BorderRadius.circular(context.borderRadius()),
//                 child: Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: context.cardPadding,
//                     vertical: context.buttonHeight * 0.3,
//                   ),
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                       colors: [
//                         AppTheme.primaryMaroon,
//                         AppTheme.secondaryMaroon,
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(context.borderRadius()),
//                     boxShadow: [
//                       BoxShadow(
//                         color: AppTheme.primaryMaroon.withOpacity(0.3),
//                         blurRadius: context.shadowBlur(),
//                         offset: Offset(0, context.smallPadding),
//                       ),
//                     ],
//                   ),
//                   child: Text(
//                     'Back to Dashboard',
//                     style: TextStyle(
//                       fontSize: context.subtitleFontSize,
//                       fontWeight: FontWeight.w500,
//                       color: AppTheme.pureWhite,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
