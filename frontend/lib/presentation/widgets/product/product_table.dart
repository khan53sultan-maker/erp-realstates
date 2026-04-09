import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class EnhancedProductTable extends StatefulWidget {
  final Function(ProductModel) onEdit;
  final Function(ProductModel) onDelete;
  final Function(ProductModel) onView;

  const EnhancedProductTable({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  State<EnhancedProductTable> createState() => _EnhancedProductTableState();
}

class _EnhancedProductTableState extends State<EnhancedProductTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
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
          )
        ],
      ),
      child: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: SizedBox(
                width: ResponsiveBreakpoints.responsive(context, tablet: 3.w, small: 6.w, medium: 3.w, large: 4.w, ultrawide: 3.w),
                height: ResponsiveBreakpoints.responsive(context, tablet: 3.w, small: 6.w, medium: 3.w, large: 4.w, ultrawide: 3.w),
                child: const CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 3),
              ),
            );
          }

          if (provider.products.isEmpty) {
            return _buildEmptyState(context);
          }

          // Use LayoutBuilder to get the available height for the table
          return LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: _getTableWidth(context),
                      maxHeight: constraints.maxHeight, // Force height to fill parent
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Use minimum size
                      children: [
                        // 1. Fixed Header Section
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
                              horizontal: context.cardPadding / 2
                          ),
                          child: _buildTableHeader(context),
                        ),

                        // 2. Scrollable Data Section - Use Flexible instead of Expanded
                        Flexible(
                          child: Container(
                            width: _getTableWidth(context),
                            child: Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              child: ListView.builder(
                                controller: _verticalController,
                                physics: const ClampingScrollPhysics(),
                                itemCount: provider.products.length,
                                itemBuilder: (context, index) {
                                  final product = provider.products[index];
                                  return _buildTableRow(context, product, index);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  double _getTableWidth(BuildContext context) {
    return ResponsiveBreakpoints.responsive(
      context,
      tablet: 1800.0 + 120.0,
      small: 1900.0 + 120.0,
      medium: 2000.0 + 120.0,
      large: 2100.0 + 120.0,
      ultrawide: 2200.0 + 120.0,
    );
  }


  Widget _buildTableHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Row(
      children: [
        Container(width: columnWidths[0], child: _buildHeaderCell(context, l10n.productName)),
        Container(width: columnWidths[1], child: _buildHeaderCell(context, l10n.details)),
        Container(width: columnWidths[2], child: _buildHeaderCell(context, l10n.price)),
        Container(width: columnWidths[3], child: _buildHeaderCell(context, l10n.costPrice)),
        Container(width: columnWidths[4], child: _buildHeaderCell(context, 'Barcode')),
        Container(width: columnWidths[5], child: _buildHeaderCell(context, 'SKU')),
        Container(width: columnWidths[6], child: _buildHeaderCell(context, l10n.color)),
        Container(width: columnWidths[7], child: _buildHeaderCell(context, l10n.type)),
        Container(width: columnWidths[8], child: _buildHeaderCell(context, l10n.quantity)),
        Container(width: columnWidths[9], child: _buildHeaderCell(context, l10n.stockStatus)),
        Container(width: columnWidths[10], child: _buildHeaderCell(context, l10n.pieces)),
        Container(width: columnWidths[11], child: _buildHeaderCell(context, l10n.createdDate)),
        Container(width: columnWidths[12], child: _buildHeaderCell(context, l10n.actions)),
      ],
    );
  }

  List<double> _getColumnWidths(BuildContext context) {
    return [
      200.0, 250.0, 120.0, 120.0, 120.0, 120.0, 120.0, 120.0, 100.0, 130.0, 180.0, 150.0, 280.0,
    ];
  }

  Widget _buildHeaderCell(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray, letterSpacing: 0.2),
    );
  }

  Widget _buildTableRow(BuildContext context, ProductModel product, int index) {
    final l10n = AppLocalizations.of(context)!;
    final columnWidths = _getColumnWidths(context);

    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.2),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      padding: EdgeInsets.symmetric(vertical: context.cardPadding / 2),
      child: Row(
        children: [
          // Product Name
          Container(
            width: columnWidths[0],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              product.name,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Product Details
          Container(
            width: columnWidths[1],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: product.detail.isNotEmpty
                ? Text(
              product.detail,
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
                : Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                l10n.noDetails,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

          // Price
          Container(
            width: columnWidths[2],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              product.formattedPrice,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
            ),
          ),

          // Cost Price
          Container(
            width: columnWidths[3],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              product.formattedCostPrice,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w600,
                color: product.costPrice != null ? AppTheme.charcoalGray : Colors.grey[500],
              ),
            ),
          ),

          // Barcode
          Container(
            width: columnWidths[4],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: product.hasBarcode ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                product.displayBarcode,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  fontWeight: FontWeight.w500,
                  color: product.hasBarcode ? Colors.blue[600] : Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // SKU
          Container(
            width: columnWidths[5],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: product.hasSku ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                product.displaySku,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  fontWeight: FontWeight.w500,
                  color: product.hasSku ? Colors.green[600] : Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Color
          Container(
            width: columnWidths[6],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: _getColorFromName(product.color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(color: _getColorFromName(product.color).withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: _getColorFromName(product.color), shape: BoxShape.circle),
                  ),
                  SizedBox(width: context.smallPadding / 2),
                  Expanded(
                    child: Text(
                      product.color,
                      style: TextStyle(
                        fontSize: context.captionFontSize,
                        fontWeight: FontWeight.w500,
                        color: _getColorFromName(product.color),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Type
          Container(
            width: columnWidths[7],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(color: Colors.brown.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Text(
                product.fabric,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.brown[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Quantity
          Container(
            width: columnWidths[8],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Text(
              '${product.quantity}',
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
            ),
          ),

          // Stock Status
          Container(
            width: columnWidths[9],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: product.stockStatusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                product.stockStatusText,
                style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: product.stockStatusColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Pieces
          Container(
            width: columnWidths[10],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: product.pieces.isNotEmpty
                ? Wrap(
              spacing: context.smallPadding / 2,
              runSpacing: context.smallPadding / 2,
              children: product.pieces.take(2).map((piece) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMaroon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                    border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3), width: 1),
                  ),
                  child: Text(
                    piece,
                    style: TextStyle(
                      fontSize: context.captionFontSize * 0.9,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryMaroon,
                    ),
                  ),
                );
              }).toList()
                ..addAll(
                  product.pieces.length > 2
                      ? [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                      ),
                      child: Text(
                        '+${product.pieces.length - 2}',
                        style: TextStyle(
                          fontSize: context.captionFontSize * 0.9,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ]
                      : [],
                ),
            )
                : Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding / 2, vertical: context.smallPadding / 4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
              ),
              child: Text(
                l10n.noPieces,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

          // Created Date
          Container(
            width: columnWidths[11],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(product.createdAt),
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                ),
                Text(
                  _getRelativeDate(context, product.createdAt),
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Actions
          Container(
            width: columnWidths[12],
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding),
            child: _buildActions(context, product),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, ProductModel product) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onView(product),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.visibility_outlined, color: Colors.purple, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Edit Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onEdit(product),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.edit_outlined, color: Colors.blue, size: context.iconSize('small')),
            ),
          ),
        ),

        SizedBox(width: context.smallPadding / 2),

        // Delete Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onDelete(product),
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.all(context.smallPadding * 0.5),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
              child: Icon(Icons.delete_outline, color: Colors.red, size: context.iconSize('small')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            height: ResponsiveBreakpoints.responsive(context, tablet: 15.w, small: 20.w, medium: 12.w, large: 10.w, ultrawide: 8.w),
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(context.borderRadius('xl'))),
            child: Icon(Icons.inventory_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
          ),

          SizedBox(height: context.mainPadding),

          Text(
            l10n.noProductRecordsFound,
            style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
          ),

          SizedBox(height: context.smallPadding),

          Container(
            constraints: BoxConstraints(
              maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 80.w, small: 70.w, medium: 60.w, large: 50.w, ultrawide: 40.w),
            ),
            child: Text(
              l10n.startByAddingYourFirstProductToManageInventoryEfficiently,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),

        ],
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'pink': return Colors.pink;
      case 'black': return Colors.black;
      case 'white': return Colors.grey;
      case 'brown': return Colors.brown;
      case 'gray': return Colors.grey;
      case 'navy': return Colors.indigo;
      case 'maroon': return const Color(0xFF800000);
      case 'gold': return const Color(0xFFFFD700);
      case 'silver': return Colors.grey[400]!;
      case 'beige': return const Color(0xFFF5F5DC);
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getRelativeDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    if (difference == 0) return l10n.today;
    if (difference == 1) return l10n.yesterday;
    if (difference < 7) return l10n.daysAgo(difference);
    if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? l10n.oneWeekAgo : l10n.weeksAgo(weeks);
    }
    if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? l10n.oneMonthAgo : l10n.monthsAgo(months);
    }
    final years = (difference / 365).floor();
    return years == 1 ? l10n.oneYearAgo : l10n.yearsAgo(years);
  }
}
