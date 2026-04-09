import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../widgets/product/add_product_dialog.dart';

import '../../widgets/product/delete_product_dialog.dart';
import '../../widgets/product/edit_product_dialog.dart';
import '../../widgets/product/filter_product_dialog.dart';
import '../../widgets/product/product_table.dart';
import '../../widgets/product/view_product_dialog.dart';
import '../../../l10n/app_localizations.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the provider when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddProductDialog(),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditProductDialog(product: product),
    );
  }

  void _showDeleteProductDialog(ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteProductDialog(product: product),
    );
  }

  void _showViewProductDialog(ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewProductDetailsDialog(product: product),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const FilterProductsDialog(),
    );
  }

  // Export functionality removed

  Future<void> _refreshProducts() async {
    await context.read<ProductProvider>().refreshProducts();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: SingleChildScrollView( // Make entire screen scrollable
          child: Padding(
            padding: EdgeInsets.all(context.mainPadding / 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Use minimum size
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
                Consumer<ProductProvider>(
                  builder: (context, provider, child) {
                    // Show error message if any
                    if (provider.errorMessage != null) {
                      return _buildErrorWidget(provider.errorMessage!);
                    }

                    return context.statsCardColumns == 2
                        ? _buildMobileStatsGrid(provider)
                        : _buildDesktopStatsRow(provider);
                  },
                ),
                SizedBox(height: context.cardPadding * 0.5),
                _buildSearchSection(),
                SizedBox(height: context.cardPadding * 0.5),
                // Remove Expanded and add height constraint to table
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6, // Max 60% of screen height
                  ),
                  child: EnhancedProductTable(
                    onEdit: _showEditProductDialog,
                    onDelete: _showDeleteProductDialog,
                    onView: _showViewProductDialog,
                  ),
                ),
                // Add bottom padding for scroll space
                SizedBox(height: context.mainPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: context.iconSize('medium'),
          ),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                color: Colors.red[700],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<ProductProvider>().clearError();
              _refreshProducts();
            },
            child: Text(
              AppLocalizations.of(context)!.retry,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
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
              Icon(
                Icons.screen_rotation_outlined,
                size: 15.w,
                color: Colors.grey[400],
              ),
              SizedBox(height: 3.h),
              Text(
                AppLocalizations.of(context)!.screenTooSmall,
                style: TextStyle(
                  fontSize: 6.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                AppLocalizations.of(context)!.screenTooSmallMessage,
                style: TextStyle(
                  fontSize: 3.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.productsManagement,
                style: TextStyle(
                  fontSize: context.headingFontSize / 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.cardPadding / 4),
              Text(
                AppLocalizations.of(context)!.productManagementDescription,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildTabletHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.productsManagement,
          style: TextStyle(
            fontSize: context.headingFontSize / 1.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          AppLocalizations.of(context)!.manageInventory,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: context.cardPadding),
        SizedBox(width: double.infinity, child: _buildAddButton()),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.products,
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          AppLocalizations.of(context)!.manageInventory,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: context.cardPadding),
        SizedBox(width: double.infinity, child: _buildAddButton()),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
        ),
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddProductDialog,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.cardPadding * 0.5,
              vertical: context.cardPadding / 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: AppTheme.pureWhite,
                  size: context.iconSize('medium'),
                ),
                SizedBox(width: context.smallPadding),
                Text(
                  context.isTablet
                      ? AppLocalizations.of(context)!.add
                      : AppLocalizations.of(context)!.addProduct,
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

  Widget _buildDesktopStatsRow(ProductProvider provider) {
    final stats = provider.productStats;
    return Row(
      children: [
        Expanded(
          child: _buildStatsCard(
            AppLocalizations.of(context)!.totalProducts,
            stats['total'].toString(),
            Icons.inventory_rounded,
            Colors.blue,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            AppLocalizations.of(context)!.inStock,
            stats['inStock'].toString(),
            Icons.check_circle_rounded,
            Colors.green,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            AppLocalizations.of(context)!.totalValue,
            'PKR ${stats['totalValue']}',
            Icons.attach_money_rounded,
            Colors.purple,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            AppLocalizations.of(context)!.lowStock,
            stats['lowStock'].toString(),
            Icons.warning_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatsGrid(ProductProvider provider) {
    final stats = provider.productStats;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                AppLocalizations.of(context)!.total,
                stats['total'].toString(),
                Icons.inventory_rounded,
                Colors.blue,
              ),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                AppLocalizations.of(context)!.inStock,
                stats['inStock'].toString(),
                Icons.check_circle_rounded,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                AppLocalizations.of(context)!.value,
                'PKR ${stats['totalValue']}',
                Icons.attach_money_rounded,
                Colors.purple,
              ),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                AppLocalizations.of(context)!.lowStock,
                stats['lowStock'].toString(),
                Icons.warning_rounded,
                Colors.orange,
              ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, context.smallPadding),
          ),
        ],
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
        Expanded(flex: 1, child: _buildSearchBar()),
        SizedBox(width: context.cardPadding),
        Expanded(flex: 1, child: _buildFilterButton()),
        SizedBox(width: context.smallPadding),

        SizedBox(width: context.smallPadding),
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
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: context.buttonHeight / 1.5,
      child: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          return TextField(
            controller: _searchController,
            onChanged: provider.searchProducts,
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: AppTheme.charcoalGray,
            ),
            decoration: InputDecoration(
              hintText: context.isTablet
                  ? AppLocalizations.of(context)!.searchProductsShortHint
                  : AppLocalizations.of(context)!.searchProductsHint,
              hintStyle: TextStyle(
                fontSize: context.bodyFontSize * 0.9,
                color: Colors.grey[500],
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey[500],
                size: context.iconSize('medium'),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        provider.searchProducts('');
                      },
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey[500],
                        size: context.iconSize('small'),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.cardPadding / 2,
                vertical: context.cardPadding / 2,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      height: context.buttonHeight / 1.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showFilterDialog,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
            decoration: BoxDecoration(
              color: AppTheme.lightGray.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  color: AppTheme.primaryMaroon,
                  size: context.iconSize('medium'),
                ),
                if (!context.isTablet) ...[
                  SizedBox(width: context.smallPadding),
                  Text(
                    AppLocalizations.of(context)!.filter,
                    style: TextStyle(
                      fontSize: context.bodyFontSize,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryMaroon,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Export button removed

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: context.statsCardHeight / 1.5,
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, context.smallPadding),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                context.borderRadius('small'),
              ),
            ),
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
                  style: TextStyle(
                    fontSize: ResponsiveBreakpoints.getDashboardCaptionFontSize(context), // Use dashboard-specific size
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
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
