import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/models/customer/customer_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../screens/customer_ledger_screen/customer_ledger.dart';

class EnhancedCustomerTable extends StatefulWidget {
  final Function(Customer) onEdit;
  final Function(Customer) onDelete;
  final Function(Customer) onView;

  const EnhancedCustomerTable({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  State<EnhancedCustomerTable> createState() => _EnhancedCustomerTableState();
}

class _EnhancedCustomerTableState extends State<EnhancedCustomerTable> {
  // Define controllers
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _contentHorizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Link header and content scrolling
    _headerHorizontalController.addListener(() {
      if (_contentHorizontalController.hasClients &&
          _headerHorizontalController.offset != _contentHorizontalController.offset) {
        _contentHorizontalController.jumpTo(_headerHorizontalController.offset);
      }
    });

    _contentHorizontalController.addListener(() {
      if (_headerHorizontalController.hasClients &&
          _contentHorizontalController.offset != _headerHorizontalController.offset) {
        _headerHorizontalController.jumpTo(_contentHorizontalController.offset);
      }
    });
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _contentHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.customers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  color: AppTheme.primaryMaroon,
                  strokeWidth: 3,
                ),
              ),
            );
          }

          if (provider.customers.isEmpty) {
            return _buildEmptyState(context);
          }

          return Column(
            children: [
              // Unified Table Header and Content with single horizontal scroll
              Expanded(
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    child: Scrollbar(
                      controller: _contentHorizontalController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 8,
                      radius: const Radius.circular(4),
                      child: SingleChildScrollView(
                        controller: _contentHorizontalController,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Container(
                              width: _getTableWidth(context),
                              decoration: BoxDecoration(
                                color: AppTheme.lightGray.withOpacity(0.5),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(context.borderRadius('large')),
                                  topRight: Radius.circular(context.borderRadius('large')),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: context.cardPadding * 0.85,
                                horizontal: context.cardPadding / 2,
                              ),
                              child: _buildTableHeader(context),
                            ),
                            // Body
                            SizedBox(
                              width: _getTableWidth(context),
                              child: Column(
                                children: provider.customers.asMap().entries.map((entry) {
                                  return _buildTableRow(context, entry.value, entry.key);
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _getTableWidth(BuildContext context) {
    // Dynamically calculate width from columns + horizontal padding
    final widths = _getColumnWidths(context);
    final totalColumnsWidth = widths.reduce((a, b) => a + b);
    return totalColumnsWidth + context.cardPadding; 
  }

  Widget _buildTableHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Row(
      children: [
        SizedBox(width: columnWidths[0], child: _buildSortableHeaderCell(context, l10n.name, 'name')),
        SizedBox(width: columnWidths[1], child: _buildHeaderCell(context, l10n.fatherName)),
        SizedBox(width: columnWidths[2], child: _buildHeaderCell(context, l10n.cnic)),
        SizedBox(width: columnWidths[3], child: _buildHeaderCell(context, l10n.phone)),
        SizedBox(width: columnWidths[4], child: _buildHeaderCell(context, l10n.email)),
        SizedBox(width: columnWidths[5], child: _buildHeaderCell(context, l10n.type)),
        SizedBox(width: columnWidths[6], child: _buildHeaderCell(context, l10n.status)),
        SizedBox(width: columnWidths[7], child: _buildHeaderCell(context, l10n.city)),
        SizedBox(width: columnWidths[8], child: _buildHeaderCell(context, l10n.totalSales)),
        SizedBox(width: columnWidths[9], child: _buildSortableHeaderCell(context, l10n.lastPurchase, 'last_order_date')),
        SizedBox(width: columnWidths[10], child: _buildSortableHeaderCell(context, l10n.since, 'created_at')),
        SizedBox(width: columnWidths[11], child: _buildHeaderCell(context, l10n.ledger)),
        SizedBox(width: columnWidths[12], child: _buildHeaderCell(context, l10n.actions)),
      ],
    );
  }

  List<double> _getColumnWidths(BuildContext context) {
    return [
      160.0, // Name
      140.0, // Father Name
      140.0, // CNIC
      130.0, // Phone
      200.0, // Email
      100.0, // Type
      100.0, // Status
      120.0, // City
      100.0, // Total Sales
      130.0, // Last Purchase
      130.0, // Since
      80.0,  // Ledger (Increased from 70)
      200.0, // Actions (Increased from 180)
    ];
  }

  Widget _buildHeaderCell(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: context.bodyFontSize,
        fontWeight: FontWeight.w600,
        color: AppTheme.charcoalGray,
        letterSpacing: 0.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSortableHeaderCell(BuildContext context, String title, String sortKey) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final isCurrentSort = provider.sortBy == sortKey;

        return InkWell(
          onTap: () => provider.setSortBy(sortKey),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: isCurrentSort ? AppTheme.primaryMaroon : AppTheme.charcoalGray,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isCurrentSort
                      ? (provider.sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                      : Icons.sort,
                  size: 16,
                  color: isCurrentSort ? AppTheme.primaryMaroon : Colors.grey[500],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableRow(BuildContext context, Customer customer, int index) {
    final columnWidths = _getColumnWidths(context);

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.2),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      padding: EdgeInsets.symmetric(
        vertical: context.cardPadding / 2,
        horizontal: context.cardPadding / 2, // Added to match header padding
      ),
      child: Row(
        children: [
          // Name
          SizedBox(
            width: columnWidths[0],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Text(
                customer.name,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Father Name
          SizedBox(
            width: columnWidths[1],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Text(
                customer.fatherName ?? 'N/A',
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  color: AppTheme.charcoalGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // CNIC
          SizedBox(
            width: columnWidths[2],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Text(
                customer.cnic ?? 'N/A',
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  color: AppTheme.charcoalGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Phone
          SizedBox(
            width: columnWidths[3],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Text(
                customer.phone,
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.charcoalGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Email
          SizedBox(
            width: columnWidths[4],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Text(
                customer.email,
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.charcoalGray,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Customer Type
          SizedBox(
            width: columnWidths[5],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: customer.customerType == 'BUSINESS'
                        ? AppTheme.primaryMaroon.withOpacity(0.1)
                        : AppTheme.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: customer.customerType == 'BUSINESS'
                          ? AppTheme.primaryMaroon.withOpacity(0.3)
                          : AppTheme.accentGold.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    customer.customerTypeDisplay,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w600,
                      color: customer.customerType == 'BUSINESS'
                          ? AppTheme.primaryMaroon
                          : AppTheme.accentGold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),

          // Status
          SizedBox(
            width: columnWidths[6],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(customer.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _getStatusColor(customer.status).withOpacity(0.3),
                        width: 1),
                  ),
                  child: Text(
                    customer.statusDisplay,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(customer.status),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),

          // City
          SizedBox(
            width: columnWidths[7],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Text(
                customer.city ?? 'N/A',
                style: TextStyle(
                  fontSize: context.subtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: customer.city != null ? AppTheme.charcoalGray : Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Total Sales
          SizedBox(
            width: columnWidths[8],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: 16,
                    color: customer.totalSalesCount > 0 ? AppTheme.primaryMaroon : Colors.grey[400],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${customer.totalSalesCount}',
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: customer.totalSalesCount > 0 ? AppTheme.primaryMaroon : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Last Purchase
          SizedBox(
            width: columnWidths[9],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.lastPurchase != null
                        ? 'PKR ${customer.lastPurchase!.toStringAsFixed(0)}'
                        : customer.totalSalesAmount.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: customer.lastPurchase != null ? AppTheme.charcoalGray : Colors.grey[500],
                      fontStyle: customer.lastPurchase == null ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  if (customer.lastPurchaseDate != null) ...[
                    Text(
                      _formatDate(customer.lastPurchaseDate!),
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Customer Since
          SizedBox(
            width: columnWidths[10],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(customer.createdAt),
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoalGray,
                    ),
                  ),
                  Text(
                    customer.relativeCreatedAt,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ledger Button Column
          SizedBox(
            width: columnWidths[11],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 4), // Further reduced padding
              child: Center(
                child: Tooltip(
                  message: AppLocalizations.of(context)!.viewLedger,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerLedgerScreen(
                            customerId: customer.id,
                            customerName: customer.name,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    child: Container(
                      padding: EdgeInsets.all(context.smallPadding * 0.5),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.blue,
                        size: context.iconSize('small'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Actions
          SizedBox(
            width: columnWidths[12],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2), // Reduced padding
              child: _buildActions(context, customer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Customer customer) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context, 
          icon: Icons.visibility_outlined, 
          color: Colors.purple, 
          tooltip: l10n.viewProfile,
          onTap: () => widget.onView(customer),
        ),
        SizedBox(width: context.smallPadding / 2),
        _buildActionButton(
          context, 
          icon: Icons.edit_outlined, 
          color: Colors.blue, 
          tooltip: l10n.editClient,
          onTap: () => widget.onEdit(customer),
        ),
        SizedBox(width: context.smallPadding / 2),
        _buildActionButton(
          context, 
          icon: Icons.delete_outline, 
          color: Colors.red, 
          tooltip: l10n.deleteClient,
          onTap: () => widget.onDelete(customer),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.people_outlined,
                size: 50,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              l10n.noCustomersFound,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.charcoalGray,
              ),
            ),
            SizedBox(height: 1.h),
            Container(
              constraints: BoxConstraints(maxWidth: 400),
              child: Text(
                l10n.adjustFilters,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return AppTheme.accentGold;
      case 'REGULAR':
        return AppTheme.primaryMaroon;
      case 'VIP':
        return AppTheme.secondaryMaroon;
      case 'INACTIVE':
        return Colors.grey[600]!;
      case 'ACTIVE':
        return Colors.green;
      default:
        return AppTheme.charcoalGray;
    }
  }
}
