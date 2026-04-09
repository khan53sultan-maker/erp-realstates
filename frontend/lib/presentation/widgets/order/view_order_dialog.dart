import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';

class ViewOrderDialog extends StatefulWidget {
  final OrderModel order;

  const ViewOrderDialog({super.key, required this.order});

  @override
  State<ViewOrderDialog> createState() => _ViewOrderDialogState();
}

class _ViewOrderDialogState extends State<ViewOrderDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 95.w, small: 90.w, medium: 85.w, large: 75.w, ultrawide: 65.w),
                  maxHeight: 90.h,
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(child: _buildContent()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.indigo, Colors.indigoAccent]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Icon(Icons.visibility_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout ? l10n.viewOrder : l10n.orderDetails,
                  style: TextStyle(
                    fontSize: context.headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!context.isTablet) ...[
                  SizedBox(height: context.smallPadding / 2),
                  Text(
                    l10n.completeOrderInformation,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.pureWhite.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: context.smallPadding / 2),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          '${l10n.orderID}: ${widget.order.id.substring(0, 8)}...',
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                        ),
                      ),
                      SizedBox(width: context.smallPadding / 2),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.order.status).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(widget.order.status),
                          style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleClose,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding),
                child: Icon(Icons.close_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderInfoSection(),

            SizedBox(height: context.cardPadding),

            _buildCustomerInfoSection(),

            SizedBox(height: context.cardPadding),

            _buildFinancialInfoSection(),

            SizedBox(height: context.cardPadding),

            _buildOrderItemsSection(),

            SizedBox(height: context.cardPadding),

            _buildDeliveryInfoSection(),

            SizedBox(height: context.cardPadding),

            _buildAdditionalInfoSection(),

            SizedBox(height: context.mainPadding),

            ResponsiveBreakpoints.responsive(
              context,
              tablet: _buildCompactButton(),
              small: _buildCompactButton(),
              medium: _buildDesktopButton(),
              large: _buildDesktopButton(),
              ultrawide: _buildDesktopButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.orderInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          _buildInfoRow(l10n.orderID, widget.order.id),
          _buildInfoRow(l10n.description, widget.order.description),
          if (widget.order.createdBy != null) _buildInfoRow(l10n.createdBy, widget.order.createdBy!),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: Colors.green, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.customerInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          _buildInfoRow(l10n.customerName, widget.order.customerName),
          _buildInfoRow(l10n.phone, widget.order.customerPhone),
          _buildInfoRow(l10n.email, widget.order.customerEmail),
        ],
      ),
    );
  }

  Widget _buildFinancialInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, color: Colors.orange, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.financialInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          _buildInfoRow(l10n.totalAmount, 'PKR ${widget.order.totalAmount.toStringAsFixed(2)}'),
          _buildInfoRow(l10n.advancePayment, 'PKR ${widget.order.advancePayment.toStringAsFixed(2)}'),
          _buildInfoRow(l10n.remainingAmount, 'PKR ${widget.order.remainingAmount.toStringAsFixed(2)}'),
          _buildInfoRow(l10n.paymentPercentage, '${widget.order.paymentPercentage}%'),
          _buildInfoRow(l10n.fullyPaid, widget.order.isFullyPaid ? l10n.yes : l10n.no),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.purple.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart_outlined, color: Colors.purple, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.orderItems,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple, size: 20),
                SizedBox(width: context.smallPadding),
                Expanded(
                  child: Text(
                    l10n.orderItemsManagedSeparately,
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w400, color: Colors.purple[700]),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: context.cardPadding),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.totalItems}:',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              ),
              Text(
                '${widget.order.orderSummary['total_items'] ?? 0}',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${l10n.totalQuantity}:',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
              ),
              Text(
                '${widget.order.orderSummary['total_quantity'] ?? 0}',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.purple.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: Colors.purple, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.deliveryInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          if (widget.order.expectedDeliveryDate != null) _buildInfoRow(l10n.expectedDelivery, _formatDate(widget.order.expectedDeliveryDate!)),
          _buildInfoRow(l10n.daysSinceOrdered, '${widget.order.daysSinceOrdered} ${l10n.days}'),
          if (widget.order.expectedDeliveryDate != null) _buildInfoRow(l10n.daysUntilDelivery, '${widget.order.daysUntilDelivery} ${l10n.days}'),
          _buildInfoRow(l10n.isOverdue, widget.order.isOverdue ? l10n.yes : l10n.no),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.teal.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.more_horiz, color: Colors.teal, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.additionalInformation,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),

          _buildInfoRow(l10n.conversionStatus, widget.order.conversionStatus),
          _buildInfoRow(l10n.convertedSalesAmount, 'PKR ${widget.order.convertedSalesAmount.toStringAsFixed(2)}'),
          if (widget.order.conversionDate != null) _buildInfoRow(l10n.conversionDate, _formatDate(widget.order.conversionDate!)),
          _buildInfoRow(l10n.isActive, widget.order.isActive ? l10n.yes : l10n.no),
          _buildInfoRow(l10n.createdAt, _formatDateTime(widget.order.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.smallPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButton() {
    final l10n = AppLocalizations.of(context)!;

    return PremiumButton(
      text: l10n.close,
      onPressed: _handleClose,
      height: context.buttonHeight,
      icon: Icons.close_rounded,
      backgroundColor: Colors.grey[600],
    );
  }

  Widget _buildDesktopButton() {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: SizedBox(
        width: 200,
        child: PremiumButton(
          text: l10n.close,
          onPressed: _handleClose,
          height: context.buttonHeight / 1.5,
          icon: Icons.close_rounded,
          backgroundColor: Colors.grey[600],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return Colors.orange;
      case OrderStatus.CONFIRMED:
        return Colors.blue;
      case OrderStatus.IN_PRODUCTION:
        return Colors.indigo;
      case OrderStatus.READY:
        return Colors.green;
      case OrderStatus.DELIVERED:
        return Colors.purple;
      case OrderStatus.CANCELLED:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case OrderStatus.PENDING:
        return l10n.pending;
      case OrderStatus.CONFIRMED:
        return l10n.confirmed;
      case OrderStatus.IN_PRODUCTION:
        return l10n.inProduction;
      case OrderStatus.READY:
        return l10n.ready;
      case OrderStatus.DELIVERED:
        return l10n.delivered;
      case OrderStatus.CANCELLED:
        return l10n.cancelled;
    }
  }
}
