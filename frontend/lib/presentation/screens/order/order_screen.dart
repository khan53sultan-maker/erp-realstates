import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/order/order_table.dart';
import '../../widgets/order/add_order_dialog.dart';
import '../../widgets/order/edit_order_dialog.dart';
import '../../widgets/order/delete_order_dialog.dart';
import '../../widgets/order/view_order_dialog.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial data - OrderProvider initializes data in constructor
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOrderDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const AddOrderDialog());
  }

  void _showEditOrderDialog(OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditOrderDialog(order: order),
    );
  }

  void _showDeleteOrderDialog(OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteOrderDialog(order: order),
    );
  }

  void _showViewOrderDialog(OrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ViewOrderDialog(order: order),
    );
  }

  Future<void> _handleRefresh() async {
    // Refresh data from provider
    final provider = context.read<OrderProvider>();
    await provider.refreshData();

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                'Data refreshed successfully',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
        ),
      );
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          // Show loading state
          if (provider.isLoading && provider.orders.isEmpty) {
            return _buildLoadingState();
          }

          // Show error state if there's an error and no orders
          if (provider.errorMessage != null && provider.orders.isEmpty) {
            return _buildErrorState(provider.errorMessage!);
          }

          // Show empty state if no orders and no search query (let table handle search results)
          if (!provider.isLoading && provider.orders.isEmpty && provider.searchQuery.isEmpty) {
            return _buildEmptyState();
          }

          // Show normal content
          return _buildNormalContent(provider);
        },
      ),
    );
  }

  Widget _buildUnsupportedScreen() {
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
                'Screen Too Small',
                style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                'This application requires a minimum screen width of 750px for optimal experience. Please use a larger screen or rotate your device.',
                style: TextStyle(fontSize: 3.sp, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 10.w, color: Colors.red[400]),
            SizedBox(height: 2.h),
            Text(
              'Error: $message',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Please try again later or contact support.',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400, color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: () {
                final provider = context.read<OrderProvider>();
                provider.refreshData();
              },
              icon: Icon(Icons.refresh_rounded, color: AppTheme.pureWhite),
              label: Text(
                'Retry',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        // Page Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Management',
                style: TextStyle(
                  fontSize: context.headingFontSize / 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.cardPadding / 4),
              Text(
                'Track and manage customer orders with comprehensive tools',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Add Order Button
        _buildAddButton(),
      ],
    );
  }

  Widget _buildTabletHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Title
        Text(
          'Order Management',
          style: TextStyle(
            fontSize: context.headingFontSize / 1.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          'Track and manage customer orders',
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
        ),
        SizedBox(height: context.cardPadding),

        // Add Order Button (full width on tablet)
        SizedBox(width: double.infinity, child: _buildAddButton()),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Page Title
        Text(
          'Orders',
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          'Manage customer orders',
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
        ),
        SizedBox(height: context.cardPadding),

        // Add Order Button (full width)
        SizedBox(width: double.infinity, child: _buildAddButton()),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddOrderDialog,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding * 0.5, vertical: context.cardPadding / 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
                SizedBox(width: context.smallPadding),
                Text(
                  context.isTablet ? 'Add' : 'Add Order',
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

  Widget _buildDesktopStatsRow(OrderProvider provider) {
    final stats = provider.orderStats;
    return Row(
      children: [
        Expanded(child: _buildStatsCard('Total Orders', stats['total'].toString(), Icons.shopping_cart_rounded, Colors.blue)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard('Pending', stats['pending'].toString(), Icons.pending_rounded, Colors.orange)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard('In Progress', stats['inProgress'].toString(), Icons.work_rounded, AppTheme.primaryMaroon)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard('Completed', stats['completed'].toString(), Icons.check_circle_rounded, Colors.green)),
      ],
    );
  }

  Widget _buildMobileStatsGrid(OrderProvider provider) {
    final stats = provider.orderStats;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatsCard('Total', stats['total'].toString(), Icons.shopping_cart_rounded, Colors.blue)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildStatsCard('Pending', stats['pending'].toString(), Icons.pending_rounded, Colors.orange)),
          ],
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildStatsCard('In Progress', stats['inProgress'].toString(), Icons.work_rounded, AppTheme.primaryMaroon)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildStatsCard('Completed', stats['completed'].toString(), Icons.check_circle_rounded, Colors.green)),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchSection(OrderProvider provider) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: ResponsiveBreakpoints.responsive(
        context,
        tablet: _buildTabletSearchLayout(provider),
        small: _buildMobileSearchLayout(provider),
        medium: _buildDesktopSearchLayout(provider),
        large: _buildDesktopSearchLayout(provider),
        ultrawide: _buildDesktopSearchLayout(provider),
      ),
    );
  }

  Widget _buildDesktopSearchLayout(OrderProvider provider) {
    return Row(
      children: [
        // Search Bar
        Expanded(flex: 3, child: _buildSearchBar(provider)),

        SizedBox(width: context.cardPadding),

        // Status Filter
        Expanded(flex: 1, child: _buildStatusFilter(provider)),

        SizedBox(width: context.smallPadding),

        // Refresh Button
        _buildRefreshButton(provider),

        SizedBox(width: context.smallPadding),
      ],
    );
  }

  Widget _buildTabletSearchLayout(OrderProvider provider) {
    return Column(
      children: [
        _buildSearchBar(provider),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildStatusFilter(provider)),
            SizedBox(width: context.cardPadding),
            _buildRefreshButton(provider),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileSearchLayout(OrderProvider provider) {
    return Column(
      children: [
        _buildSearchBar(provider),
        SizedBox(height: context.smallPadding),
        Row(
          children: [
            Expanded(child: _buildStatusFilter(provider)),
            SizedBox(width: context.smallPadding),
            _buildRefreshButton(provider),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(OrderProvider provider) {
    return SizedBox(
      height: context.buttonHeight / 1.5,
      child: TextField(
        controller: _searchController,
        onChanged: provider.searchOrders,
        style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
        decoration: InputDecoration(
          hintText: context.isTablet ? 'Search orders...' : 'Search orders by customer, product, description...',
          hintStyle: TextStyle(fontSize: context.bodyFontSize * 0.9, color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500], size: context.iconSize('medium')),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    provider.searchOrders('');
                  },
                  icon: Icon(Icons.clear_rounded, color: Colors.grey[500], size: context.iconSize('small')),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2, vertical: context.cardPadding / 2),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(OrderProvider provider) {
    // Check if there's an active status filter
    final hasActiveFilter = provider.currentStatusFilter != null;

    return Container(
      height: context.buttonHeight / 1.5,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      decoration: BoxDecoration(
        color: hasActiveFilter ? AppTheme.accentGold.withOpacity(0.1) : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: hasActiveFilter ? AppTheme.accentGold.withOpacity(0.3) : Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        onTap: () => _showStatusFilterDialog(provider),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasActiveFilter ? Icons.filter_alt : Icons.filter_list_rounded,
              color: hasActiveFilter ? AppTheme.accentGold : Colors.grey[600],
              size: context.iconSize('medium'),
            ),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                hasActiveFilter ? 'Status: ${_getStatusDisplayName(provider.currentStatusFilter)}' : 'Filter Status',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: hasActiveFilter ? AppTheme.accentGold : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusDisplayName(String? status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'inProgress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'delivered':
        return 'Delivered';
      default:
        return 'All';
    }
  }

  void _showStatusFilterDialog(OrderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter by Status',
          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusOption('All Status', null, provider),
            _buildStatusOption('Pending', 'pending', provider),
            _buildStatusOption('In Progress', 'inProgress', provider),
            _buildStatusOption('Completed', 'completed', provider),
            _buildStatusOption('Cancelled', 'cancelled', provider),
            _buildStatusOption('Delivered', 'delivered', provider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String label, String? value, OrderProvider provider) {
    final isSelected = provider.currentStatusFilter == value;

    return InkWell(
      onTap: () {
        provider.filterOrdersByStatus(value);
        Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
        margin: EdgeInsets.only(bottom: context.smallPadding / 2),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryMaroon.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
          border: Border.all(color: isSelected ? AppTheme.primaryMaroon.withOpacity(0.3) : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryMaroon, size: context.iconSize('small'))
            else
              Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: context.iconSize('small')),
            SizedBox(width: context.smallPadding),
            Text(
              label,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton(OrderProvider provider) {
    return Container(
      height: context.buttonHeight / 1.5,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        onTap: _handleRefresh,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh_rounded, color: Colors.grey[600], size: context.iconSize('medium')),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                'Refresh',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
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
            child: Icon(icon, color: color, size: context.iconSize('medium')),
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
                      tablet: 10.8.sp,
                      small: 11.2.sp,
                      medium: 11.5.sp,
                      large: 11.8.sp,
                      ultrawide: 12.2.sp,
                    ),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoalGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
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

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 2.w),
            SizedBox(height: 2.h),
            Text(
              'Loading orders...',
              style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Please wait while we fetch your data',
              style: TextStyle(fontSize: 3.sp, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 9.w, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'No orders found',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your filters or adding new orders.',
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: () {
                final provider = context.read<OrderProvider>();
                provider.refreshData();
              },
              icon: Icon(Icons.refresh_rounded, color: AppTheme.pureWhite),
              label: Text(
                'Refresh Data',
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalContent(OrderProvider provider) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.primaryMaroon,
      child: Padding(
        padding: EdgeInsets.all(context.mainPadding / 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Header Section
            ResponsiveBreakpoints.responsive(
              context,
              tablet: _buildTabletHeader(),
              small: _buildMobileHeader(),
              medium: _buildDesktopHeader(),
              large: _buildDesktopHeader(),
              ultrawide: _buildDesktopHeader(),
            ),

            SizedBox(height: context.mainPadding),

            // Responsive Stats Cards
            context.statsCardColumns == 2 ? _buildMobileStatsGrid(provider) : _buildDesktopStatsRow(provider),

            SizedBox(height: context.cardPadding * 0.5),

            // Responsive Search Section
            _buildSearchSection(provider),

            SizedBox(height: context.cardPadding * 0.5),

            // Active Filters Section (show when filters are active)
            if (provider.searchQuery.isNotEmpty || provider.currentStatusFilter != null) _buildActiveFilters(provider),

            SizedBox(height: context.cardPadding * 0.5),

            // Enhanced Order Table
            Expanded(
              child: EnhancedOrderTable(onEdit: _showEditOrderDialog, onDelete: _showDeleteOrderDialog, onView: _showViewOrderDialog),
            ),
          ],
        ),
      ),
    );
  }

  /// Build active filters section showing current filters with clear options
  Widget _buildActiveFilters(OrderProvider provider) {
    final activeFilters = <String>[];

    if (provider.searchQuery.isNotEmpty) {
      activeFilters.add('Search: "${provider.searchQuery}"');
    }
    if (provider.currentStatusFilter != null) {
      activeFilters.add('Status: ${_getStatusDisplayName(provider.currentStatusFilter)}');
    }

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt_rounded, color: Colors.green, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding),
              Text(
                'Active Filters',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: Colors.green[700]),
              ),
              const Spacer(),
              InkWell(
                onTap: () => provider.clearFilters(),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_all_rounded, color: Colors.red[700], size: context.iconSize('small')),
                      SizedBox(width: context.smallPadding / 2),
                      Text(
                        'Clear All',
                        style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          Wrap(
            spacing: context.smallPadding,
            runSpacing: context.smallPadding / 2,
            children: activeFilters.map((filterText) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filterText,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: AppTheme.primaryMaroon),
                    ),
                    SizedBox(width: context.smallPadding / 2),
                    InkWell(
                      onTap: () => _clearSpecificFilter(filterText, provider),
                      borderRadius: BorderRadius.circular(context.borderRadius('small')),
                      child: Icon(Icons.close_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('small')),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Clear specific filter
  void _clearSpecificFilter(String filterText, OrderProvider provider) {
    if (filterText.startsWith('Search:')) {
      _searchController.clear();
      provider.searchOrders('');
    } else if (filterText.startsWith('Status:')) {
      provider.filterOrdersByStatus(null);
    }
  }
}
