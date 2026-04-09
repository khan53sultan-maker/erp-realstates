import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/sale_reports_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class SaleReportsScreen extends StatefulWidget {
  const SaleReportsScreen({super.key});

  @override
  State<SaleReportsScreen> createState() => _SaleReportsScreenState();
}

class _SaleReportsScreenState extends State<SaleReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<SaleReportsProvider>(context, listen: false);
      await provider.initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Consumer<SaleReportsProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: EdgeInsets.all(context.mainPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(provider),
                SizedBox(height: context.cardPadding),
                _buildPeriodSelector(provider),
                SizedBox(height: context.cardPadding),
                if (provider.hasError) _buildErrorDisplay(provider),
                Expanded(
                  child: provider.isLoading
                      ? _buildLoadingState()
                      : provider.currentReport == null
                          ? _buildEmptyState()
                          : _buildReportContent(provider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnsupportedScreen() {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.screen_rotation_outlined, size: 15.w, color: Colors.grey[400]),
              SizedBox(height: 3.h),
              Text(
                l10n.screenTooSmall,
                style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(SaleReportsProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.smallPadding),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
                      ),
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                    ),
                    child: Icon(Icons.analytics_rounded, color: Colors.white, size: context.iconSize('large')),
                  ),
                  SizedBox(width: context.cardPadding),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.saleReports,
                        style: TextStyle(
                          fontSize: context.headerFontSize,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.charcoalGray,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (!context.isTablet)
                        Text(
                          l10n.saleReportsAnalyticsSubtitle,
                          style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ],
              ),
              if (provider.currentReport != null) ...[
                SizedBox(height: context.smallPadding),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMaroon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Text(
                    provider.currentPeriodDisplay,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryMaroon,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildExportButton(provider),
      ],
    );
  }

  Widget _buildExportButton(SaleReportsProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentGold, AppTheme.accentGold.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: provider.isLoading ? null : () async {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    const SizedBox(width: 12),
                    Text('Preparing PDF export...', style: TextStyle(color: Colors.white)),
                  ],
                ),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );

            await provider.exportPdf();
            
            if (mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              if (provider.hasSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.successMessage ?? l10n.exportPdf),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                provider.clearSuccess(); // Clear persistent success banner
              } else if (provider.hasError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Export failed'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                provider.clearError(); // Clear persistent error banner
              }
            }
          },
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.cardPadding,
              vertical: context.cardPadding / 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded, color: Colors.white, size: context.iconSize('medium')),
                SizedBox(width: context.smallPadding),
                Text(
                  l10n.exportPdf,
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(SaleReportsProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final periods = [
      {'type': 'daily', 'label': l10n.daily, 'icon': Icons.today_rounded},
      {'type': 'weekly', 'label': l10n.weekly, 'icon': Icons.view_week_rounded},
      {'type': 'monthly', 'label': l10n.monthly, 'icon': Icons.calendar_month_rounded},
      {'type': 'yearly', 'label': l10n.yearly, 'icon': Icons.calendar_today_rounded},
    ];

    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: periods.map((period) {
          final isSelected = provider.selectedReportType == period['type'];
          return Expanded(
            child: GestureDetector(
              onTap: () => provider.setReportType(period['type'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: context.cardPadding / 2),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon])
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      period['icon'] as IconData,
                      size: context.iconSize('small'),
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    Text(
                      period['label'] as String,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 8.w,
            height: 8.w,
            child: const CircularProgressIndicator(
              color: AppTheme.primaryMaroon,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            l10n.generatingReport,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(context.borderRadius('xl')),
            ),
            child: Icon(Icons.analytics_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),
          SizedBox(height: context.mainPadding),
          Text(
            l10n.noReportDataAvailable,
            style: TextStyle(
              fontSize: context.headerFontSize * 0.8,
              fontWeight: FontWeight.w600,
              color: AppTheme.charcoalGray,
            ),
          ),
          SizedBox(height: context.smallPadding),
          Text(
            l10n.selectPeriodViewAnalytics,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(SaleReportsProvider provider) {
    return Container(
      margin: EdgeInsets.only(bottom: context.cardPadding),
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: context.iconSize('medium')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              provider.errorMessage ?? 'An error occurred',
              style: TextStyle(fontSize: context.bodyFontSize, color: Colors.red.shade700),
            ),
          ),
          IconButton(
            onPressed: () => provider.clearError(),
            icon: Icon(Icons.close_rounded, color: Colors.red.shade600, size: context.iconSize('small')),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDisplay(SaleReportsProvider provider) {
    return Container(
      margin: EdgeInsets.only(bottom: context.cardPadding),
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: context.iconSize('medium')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              provider.successMessage ?? 'Success',
              style: TextStyle(fontSize: context.bodyFontSize, color: Colors.green.shade700),
            ),
          ),
          IconButton(
            onPressed: () => provider.clearSuccess(),
            icon: Icon(Icons.close, color: Colors.green.shade600, size: context.iconSize('small')),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(SaleReportsProvider provider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSummaryCards(provider),
          SizedBox(height: context.cardPadding),
          _buildGrowthSection(provider),
          SizedBox(height: context.cardPadding),
          _buildPaymentBreakdown(provider),
          SizedBox(height: context.cardPadding),
          _buildTopProductsSection(provider),
          SizedBox(height: context.cardPadding),
          _buildTopCustomersSection(provider),
          SizedBox(height: context.cardPadding),
          _buildSellerPerformance(provider),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(SaleReportsProvider provider) {
    final report = provider.currentReport!;
    final summary = report.summary;

    final l10n = AppLocalizations.of(context)!;
    final cards = [
      {
        'title': l10n.totalSales,
        'value': '${summary.totalSales}',
        'subtitle': l10n.orders,
        'icon': Icons.shopping_cart_rounded,
        'color': Colors.blue,
      },
      {
        'title': l10n.revenue,
        'value': summary.formattedRevenue,
        'subtitle': l10n.grossIncome,
        'icon': Icons.attach_money_rounded,
        'color': Colors.green,
      },
      {
        'title': l10n.profit,
        'value': summary.formattedProfit,
        'subtitle': '${summary.formattedMargin} ${l10n.margin}',
        'icon': Icons.trending_up_rounded,
        'color': summary.totalProfit >= 0 ? Colors.teal : Colors.red,
      },
      {
        'title': l10n.avgOrder,
        'value': summary.formattedAOV,
        'subtitle': l10n.perOrder,
        'icon': Icons.receipt_long_rounded,
        'color': Colors.orange,
      },
    ];

    return Row(
      children: cards.map((card) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: context.smallPadding / 2),
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              boxShadow: [
                BoxShadow(
                  color: (card['color'] as Color).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: (card['color'] as Color).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.smallPadding / 2),
                      decoration: BoxDecoration(
                        color: (card['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                      ),
                      child: Icon(card['icon'] as IconData, color: card['color'] as Color, size: context.iconSize('medium')),
                    ),
                  ],
                ),
                SizedBox(height: context.cardPadding),
                Text(
                  card['value'] as String,
                  style: TextStyle(
                    fontSize: context.bodyFontSize * 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  card['title'] as String,
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  card['subtitle'] as String,
                  style: TextStyle(
                    fontSize: context.captionFontSize * 0.9,
                    color: card['color'] as Color,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrowthSection(SaleReportsProvider provider) {
    if (provider.comparison == null) return const SizedBox.shrink();

    final growth = provider.comparison!.growth;

    final l10n = AppLocalizations.of(context)!;
    final metrics = [
      {
        'label': l10n.revenueGrowth,
        'value': growth.formattedRevenueGrowth,
        'isUp': growth.isRevenueUp,
        'color': growth.isRevenueUp ? Colors.green : Colors.red,
      },
      {
        'label': l10n.salesGrowth,
        'value': growth.formattedSalesGrowth,
        'isUp': growth.isSalesUp,
        'color': growth.isSalesUp ? Colors.green : Colors.red,
      },
      {
        'label': l10n.profitGrowth,
        'value': growth.formattedProfitGrowth,
        'isUp': growth.isProfitUp,
        'color': growth.isProfitUp ? Colors.green : Colors.red,
      },
    ];

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryMaroon.withOpacity(0.05),
            AppTheme.secondaryMaroon.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.growthVsPreviousPeriod,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: metrics.map((metric) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: context.smallPadding / 2),
                  padding: EdgeInsets.all(context.cardPadding),
                  decoration: BoxDecoration(
                    color: AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            (metric['isUp'] as bool) ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: metric['color'] as Color,
                            size: context.iconSize('small'),
                          ),
                          SizedBox(width: context.smallPadding / 2),
                          Text(
                            metric['value'] as String,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              fontWeight: FontWeight.w700,
                              color: metric['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.smallPadding / 2),
                      Text(
                        metric['label'] as String,
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(SaleReportsProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final payments = provider.currentReport!.paymentBreakdown;
    if (payments.isEmpty) return const SizedBox.shrink();

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal];

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.paymentMethods,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          ...payments.asMap().entries.map((entry) {
            final payment = entry.value;
            final color = colors[entry.key % colors.length];
            final total = provider.currentReport!.summary.totalRevenue;
            final percentage = total > 0 ? (payment.total / total * 100) : 0.0;

            return Padding(
              padding: EdgeInsets.only(bottom: context.smallPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          SizedBox(width: context.smallPadding),
                          Text(
                            payment.method,
                            style: TextStyle(
                              fontSize: context.subtitleFontSize,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.charcoalGray,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        payment.formattedTotal,
                        style: TextStyle(
                          fontSize: context.subtitleFontSize,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.smallPadding / 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                  SizedBox(height: context.smallPadding / 4),
                  Text(
                    '${payment.count} ${l10n.ordersLabel} (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: context.captionFontSize, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection(SaleReportsProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final products = provider.currentReport!.topProducts;
    if (products.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.topSellingProducts,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          ...products.take(5).toList().asMap().entries.map((entry) {
            final product = entry.value;
            final rank = entry.key + 1;

            return Container(
              margin: EdgeInsets.only(bottom: context.smallPadding),
              padding: EdgeInsets.all(context.smallPadding),
              decoration: BoxDecoration(
                color: rank == 1 ? Colors.amber.withOpacity(0.1) : AppTheme.lightGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: rank == 1 ? Border.all(color: Colors.amber.withOpacity(0.3)) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: rank == 1 ? Colors.amber : AppTheme.primaryMaroon.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          fontWeight: FontWeight.w700,
                          color: rank == 1 ? Colors.white : AppTheme.primaryMaroon,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: context.cardPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: context.subtitleFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.charcoalGray,
                          ),
                        ),
                        Text(
                          '${product.quantity} ${l10n.unitsSold}',
                          style: TextStyle(
                            fontSize: context.captionFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    product.formattedRevenue,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopCustomersSection(SaleReportsProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final customers = provider.currentReport!.topCustomers;
    if (customers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_rounded, color: Colors.blue, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.topCustomers,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          ...customers.take(5).toList().asMap().entries.map((entry) {
            final customer = entry.value;

            return Container(
              margin: EdgeInsets.only(bottom: context.smallPadding),
              padding: EdgeInsets.all(context.smallPadding),
              decoration: BoxDecoration(
                color: AppTheme.lightGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    radius: 18,
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'W',
                      style: TextStyle(
                        fontSize: context.subtitleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  SizedBox(width: context.cardPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontSize: context.subtitleFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.charcoalGray,
                          ),
                        ),
                        Text(
                          '${customer.orders} ${l10n.ordersLabel}',
                          style: TextStyle(
                            fontSize: context.captionFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    customer.formattedRevenue,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSellerPerformance(SaleReportsProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final sellers = provider.currentReport!.sellerPerformance;
    if (sellers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.sellerPerformance,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          ...sellers.map((seller) {
            return Container(
              margin: EdgeInsets.only(bottom: context.smallPadding),
              padding: EdgeInsets.all(context.smallPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryMaroon.withOpacity(0.05), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryMaroon,
                    radius: 18,
                    child: Text(
                      seller.name.isNotEmpty ? seller.name[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: context.cardPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seller.name,
                          style: TextStyle(
                            fontSize: context.subtitleFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.charcoalGray,
                          ),
                        ),
                        Text(
                          '${seller.sales} ${l10n.salesLabel}',
                          style: TextStyle(
                            fontSize: context.captionFontSize,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        seller.formattedRevenue,
                        style: TextStyle(
                          fontSize: context.subtitleFontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${l10n.profit}: ${seller.formattedProfit}',
                        style: TextStyle(
                          fontSize: context.captionFontSize,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
