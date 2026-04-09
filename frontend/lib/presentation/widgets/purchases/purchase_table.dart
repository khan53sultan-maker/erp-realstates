import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/models/purchase_model.dart';
import '../../../src/providers/purchase_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import 'purchase_table_helpers.dart';
import 'view_purchase_details_dialog.dart';
import 'edit_purchase_dialog.dart';
import 'delete_purchase_dialog.dart';
import 'purchase_filter_dialog.dart';

class PurchaseTable extends StatefulWidget {
  final PurchaseFilter? filter;

  const PurchaseTable({super.key, this.filter});

  @override
  State<PurchaseTable> createState() => _PurchaseTableState();
}

class _PurchaseTableState extends State<PurchaseTable> {
  // 1. Define separate controllers for robust scrolling
  final ScrollController _headerHorizontalController = ScrollController();
  final ScrollController _contentHorizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 2. Link the header and content scrolling (Two-way sync)
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

  /// Get filtered purchases based on the applied filter
  List<PurchaseModel> _getFilteredPurchases(List<PurchaseModel> allPurchases) {
    if (widget.filter == null) {
      return allPurchases;
    }

    List<PurchaseModel> filtered = List.from(allPurchases);

    // Filter by vendor
    if (widget.filter!.vendorId != null && widget.filter!.vendorId!.isNotEmpty) {
      filtered = filtered.where((purchase) => purchase.vendor == widget.filter!.vendorId).toList();
    }

    // Filter by status
    if (widget.filter!.status != null && widget.filter!.status!.isNotEmpty) {
      filtered = filtered.where((purchase) => purchase.status.toLowerCase() == widget.filter!.status!.toLowerCase()).toList();
    }

    // Filter by date range
    if (widget.filter!.startDate != null) {
      filtered = filtered.where((purchase) {
        return purchase.purchaseDate.isAfter(widget.filter!.startDate!.subtract(Duration(days: 1)));
      }).toList();
    }

    if (widget.filter!.endDate != null) {
      filtered = filtered.where((purchase) {
        return purchase.purchaseDate.isBefore(widget.filter!.endDate!.add(Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        child: Column(
          children: [
            // --- Table Header (Fixed Top) ---
            Container(
              decoration: BoxDecoration(
                color: AppTheme.lightGray.withOpacity(0.5),
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: SingleChildScrollView(
                controller: _headerHorizontalController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Container(
                  width: _calculateTotalWidth(),
                  padding: EdgeInsets.symmetric(
                    vertical: context.cardPadding * 0.75,
                  ),
                  child: Row(
                    children: _buildHeaderCells(context),
                  ),
                ),
              ),
            ),

            // --- Table Body (Scrollable Vertical & Horizontal) ---
            Expanded(
              child: Consumer<PurchaseProvider>(
                builder: (context, provider, _) {
                  // 1. Loading
                  if (provider.isLoading && provider.purchases.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryMaroon),
                    );
                  }

                  // 2. Empty
                  if (provider.purchases.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // Get filtered purchases
                  final filteredPurchases = _getFilteredPurchases(provider.purchases);

                  if (filteredPurchases.isEmpty) {
                    return _buildEmptyState(context, message: l10n.noPurchasesMatchFilter);
                  }

                  // 3. Data
                  return Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      scrollDirection: Axis.vertical,
                      child: Scrollbar(
                        controller: _contentHorizontalController,
                        thumbVisibility: true,
                        notificationPredicate: (notification) => notification.depth == 1,
                        child: SingleChildScrollView(
                          controller: _contentHorizontalController,
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          child: Container(
                            width: _calculateTotalWidth(),
                            child: Column(
                              children: filteredPurchases.asMap().entries.map((entry) {
                                return _buildTableRow(context, entry.value, entry.key);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Configuration ---
  List<double> get _colWidths => [
    110.0, // 0. Date
    130.0, // 1. Invoice
    180.0, // 2. Vendor
    110.0, // 3. Subtotal
    100.0, // 4. Tax
    120.0, // 5. Total
    110.0, // 6. Status
    140.0, // 7. Actions
  ];

  double _calculateTotalWidth() => _colWidths.reduce((a, b) => a + b);

  List<Widget> _buildHeaderCells(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Localized Headers
    final headers = [
      l10n.date,
      l10n.invoiceHash, // "Invoice #"
      l10n.vendor,
      l10n.subTotal,
      l10n.tax,
      l10n.total,
      l10n.status,
      l10n.action // or l10n.actions
    ];

    return List.generate(headers.length, (index) {
      final isNumeric = index >= 3 && index <= 5;

      return Container(
        width: _colWidths[index],
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          headers[index].toUpperCase(),
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: 0.5,
          ),
        ),
      );
    });
  }

  Widget _buildTableRow(BuildContext context, PurchaseModel purchase, int index) {
    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      padding: EdgeInsets.symmetric(vertical: context.cardPadding / 2.5),
      child: Row(
        children: [
          // 0. Date
          _textCell(DateFormat('dd-MM-yyyy').format(purchase.purchaseDate), 0, context),

          // 1. Invoice #
          _textCell(purchase.invoiceNumber, 1, context, isBold: true),

          // 2. Vendor
          _textCell(purchase.vendorName ?? purchase.vendor ?? 'Unknown', 2, context),

          // 3. Subtotal (Right Aligned)
          _textCell(purchase.subtotal.toStringAsFixed(2), 3, context, isNumeric: true),

          // 4. Tax (Right Aligned)
          _textCell(purchase.tax.toStringAsFixed(2), 4, context, isNumeric: true),

          // 5. Total (Right Aligned, Bold)
          _textCell(
              purchase.total.toStringAsFixed(2),
              5,
              context,
              isNumeric: true,
              isBold: true,
              color: AppTheme.primaryMaroon
          ),

          // 6. Status
          Container(
            width: _colWidths[6],
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: PurchaseTableHelpers.buildStatusBadge(context, purchase.status),
          ),

          // 7. Actions
          _actionCell(context, purchase, 7),
        ],
      ),
    );
  }

  Widget _textCell(String text, int index, BuildContext context, {
    bool isBold = false,
    Color? color,
    bool isNumeric = false,
  }) {
    return Container(
      width: _colWidths[index],
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: isNumeric ? Alignment.centerRight : Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.bodyFontSize,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          color: color ?? AppTheme.charcoalGray,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _actionCell(BuildContext context, PurchaseModel purchase, int index) {
    return Container(
      width: _colWidths[index],
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _iconButton(Icons.visibility_outlined, Colors.blue, () {
            showDialog(context: context, builder: (_) => ViewPurchaseDetailsDialog(purchase: purchase));
          }),
          const SizedBox(width: 8),
          _iconButton(Icons.edit_outlined, Colors.orange, () {
            showDialog(context: context, builder: (_) => EditPurchaseDialog(purchase: purchase));
          }),
          const SizedBox(width: 8),
          _iconButton(Icons.delete_outline, Colors.red, () {
            showDialog(context: context, builder: (_) => DeletePurchaseDialog(purchase: purchase));
          }),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {String? message}) {
    final l10n = AppLocalizations.of(context)!;
    final displayMessage = message ?? l10n.noPurchasesFound;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            displayMessage,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
