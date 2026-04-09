import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/payables_provider.dart';
import '../../../src/models/payable/payable_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/payables/add_payable_dialog.dart';
import '../../widgets/payables/delete_payable_dialog.dart';
import '../../widgets/payables/edit_payable_dialog.dart';
import '../../widgets/payables/view_payable_details.dart';
import '../../widgets/payables/enhanced_payables_table.dart';
import '../../widgets/payables/payable_filter_dialog.dart';

class PayablesPage extends StatefulWidget {
  const PayablesPage({super.key});

  @override
  State<PayablesPage> createState() => _PayablesPageState();
}

class _PayablesPageState extends State<PayablesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PayablesProvider>();
      provider.loadStatistics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddPayableDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const AddPayableDialog());
  }

  void _showEditPayableDialog(Payable payable) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditPayableDialog(payable: payable),
    );
  }

  void _showDeletePayableDialog(Payable payable) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeletePayableDialog(payable: payable),
    );
  }

  void _showViewDetailsDialog(Payable payable) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewPayableDetailsDialog(payable: payable),
    );
  }

  void _showFilterDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const PayableFilterDialog());
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section (now scrolls with content)
            Container(
              padding: EdgeInsets.all(context.mainPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveBreakpoints.responsive(
                    context,
                    tablet: _buildTabletHeader(),
                    small: _buildMobileHeader(),
                    medium: _buildDesktopHeader(),
                    large: _buildDesktopHeader(),
                    ultrawide: _buildDesktopHeader(),
                  ),
                  SizedBox(height: context.mainPadding),
                  Consumer<PayablesProvider>(
                    builder: (context, provider, child) {
                      return context.statsCardColumns == 2 ? _buildMobileStatsGrid(provider) : _buildDesktopStatsRow(provider);
                    },
                  ),
                  SizedBox(height: context.cardPadding * 0.5),
                  _buildSearchSection(),
                  SizedBox(height: context.cardPadding * 0.5),
                ],
              ),
            ),
            // Table Section with fixed height
            Container(
              height: 60.h, // Fixed height for the table
              padding: EdgeInsets.symmetric(horizontal: context.mainPadding),
              child: EnhancedPayablesTable(
                onEdit: _showEditPayableDialog, 
                onDelete: _showDeletePayableDialog, 
                onView: _showViewDetailsDialog
              ),
            ),
          ],
        ),
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
              SizedBox(height: 2.h),
              Text(
                l10n.screenTooSmallMessage,
                style: TextStyle(fontSize: 3.sp, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.payablesManagement,
                style: TextStyle(
                  fontSize: context.headerFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.cardPadding / 4),
              Text(
                l10n.payablesManagementDescription,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildTabletHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.payables,
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.manageCreditorPayables,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
        ),
        SizedBox(height: context.cardPadding),
        SizedBox(width: double.infinity, child: _buildAddButton()),
      ],
    );
  }

  Widget _buildMobileHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.payables,
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.creditorPayables,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
        ),
        SizedBox(height: context.cardPadding),
        SizedBox(width: double.infinity, child: _buildAddButton()),
      ],
    );
  }

  Widget _buildAddButton() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddPayableDialog,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding * 0.5, vertical: context.cardPadding / 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
                SizedBox(width: context.smallPadding),
                Text(
                  context.isTablet ? l10n.add : '${l10n.add} ${l10n.payable}',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.pureWhite,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopStatsRow(PayablesProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _buildStatsCard(l10n.totalPayables, provider.payables.length.toString(), Icons.account_balance_wallet_rounded, AppTheme.primaryMaroon),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            l10n.totalBorrowed,
            'PKR ${provider.totalAmountBorrowed.toStringAsFixed(2)}',
            Icons.trending_up_rounded,
            AppTheme.accentGold,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(l10n.totalPaid, 'PKR ${provider.totalAmountPaid.toStringAsFixed(2)}', Icons.trending_down_rounded, Colors.green),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            l10n.balanceDue,
            'PKR ${provider.totalBalanceRemaining.toStringAsFixed(2)}',
            Icons.account_balance_rounded,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatsGrid(PayablesProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(l10n.total, provider.payables.length.toString(), Icons.account_balance_wallet_rounded, AppTheme.primaryMaroon),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                l10n.borrowed,
                'PKR ${provider.totalAmountBorrowed.toStringAsFixed(2)}',
                Icons.trending_up_rounded,
                AppTheme.accentGold,
              ),
            ),
          ],
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildStatsCard(l10n.paid, 'PKR ${provider.totalAmountPaid.toStringAsFixed(2)}', Icons.trending_down_rounded, Colors.green)),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(l10n.due, 'PKR ${provider.totalBalanceRemaining.toStringAsFixed(2)}', Icons.account_balance_rounded, Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: ResponsiveBreakpoints.responsive(
        context,
        tablet: _buildTabletSearchLayout(),
        small: _buildMobileSearchLayout(),
        medium: _buildDesktopSearchLayout(),
        large: _buildDesktopSearchLayout(),
        ultrawide: _buildDesktopSearchLayout(),
      ),
    );
  }

  Widget _buildDesktopSearchLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildSearchBar()),
        SizedBox(width: context.cardPadding),
        Expanded(flex: 1, child: _buildFilterButton()),
        SizedBox(width: context.smallPadding),
        Expanded(flex: 1, child: _buildRefreshButton()),
      ],
    );
  }

  Widget _buildTabletSearchLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildFilterButton()),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildRefreshButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileSearchLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        SizedBox(height: context.smallPadding),
        Row(
          children: [
            Expanded(child: _buildFilterButton()),
            SizedBox(width: context.smallPadding),
            Expanded(child: _buildRefreshButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: context.buttonHeight / 1.5,
      child: Consumer<PayablesProvider>(
        builder: (context, provider, child) {
          return TextField(
            controller: _searchController,
            onChanged: provider.setSearchQuery,
            style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
            decoration: InputDecoration(
              hintText: context.isTablet ? '${l10n.search} ${l10n.payables}...' : l10n.searchPayablesHint,
              hintStyle: TextStyle(fontSize: context.bodyFontSize * 0.9, color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500], size: context.iconSize('medium')),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
                icon: Icon(Icons.clear_rounded, color: Colors.grey[500], size: context.iconSize('small')),
              )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2, vertical: context.cardPadding / 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton() {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: _showFilterDialog,
      borderRadius: BorderRadius.circular(context.borderRadius()),
      child: Container(
        height: context.buttonHeight / 1.5,
        padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                l10n.filter,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.primaryMaroon),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<PayablesProvider>(
      builder: (context, provider, child) {
        return InkWell(
          onTap: () {
            provider.refreshPayables();
          },
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Container(
            height: context.buttonHeight / 1.5,
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryMaroon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
                if (!context.isTablet) ...[
                  SizedBox(width: context.smallPadding),
                  Text(
                    l10n.refresh,
                    style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.primaryMaroon),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: context.statsCardHeight / 1.5,
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Icon(icon, color: color, size: context.dashboardIconSize('medium')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveBreakpoints.responsive(
                      context,
                      tablet: 10.8.sp, // Original size
                      small: 11.2.sp, // Original size
                      medium: 11.5.sp, // Original size
                      large: 11.8.sp, // Original size
                      ultrawide: 12.2.sp, // Original size
                    ),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoalGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: ResponsiveBreakpoints.getDashboardCaptionFontSize(context), fontWeight: FontWeight.w400, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
