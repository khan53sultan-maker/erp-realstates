import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/real_estate/real_estate_sale_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/services/real_estate_print_service.dart';
import '../../screens/real_estate/receipt_preview_screen.dart';

class PartnerPayoutDialog extends StatefulWidget {
  final RealEstateSale sale;

  const PartnerPayoutDialog({super.key, required this.sale});

  @override
  State<PartnerPayoutDialog> createState() => _PartnerPayoutDialogState();
}

class _PartnerPayoutDialogState extends State<PartnerPayoutDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(context.mainPadding),
      child: Container(
        width: context.dialogWidth * 1.3,
        constraints: BoxConstraints(maxHeight: 90.h, maxWidth: 900),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(context.borderRadius('large')),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.borderRadius('large')),
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabBar(context),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDealerTab(context),
                    _buildLandownerShareTab(context),
                    _buildCompanyCommTab(context),
                  ],
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: const BoxDecoration(
        color: AppTheme.primaryMaroon,
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Partner Ledger & Company Income',
                  style: TextStyle(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Plot: ${widget.sale.plotNumber} | Customer: ${widget.sale.customerName}',
                  style: TextStyle(color: AppTheme.pureWhite.withOpacity(0.8), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.pureWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      color: AppTheme.creamWhite,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryMaroon,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryMaroon,
        indicatorWeight: 3,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Dealer Comm.', icon: Icon(Icons.handshake_rounded, size: 18)),
          Tab(text: 'L/O Share Payout', icon: Icon(Icons.outbox_rounded, size: 18)),
          Tab(text: 'Company Income', icon: Icon(Icons.trending_up_rounded, size: 18)),
        ],
      ),
    );
  }

  Widget _buildDealerTab(BuildContext context) {
    final sale = widget.sale;
    return Column(
      children: [
        _buildSummaryCard(
          context,
          title: 'DEALER COMMISSION (PAYOUT)',
          color: Colors.green,
          items: [
            _summaryItem(context, 'Total Comm.', currencyFormat.format(sale.dealerCommission), hasReceipts: true, onTap: () => _viewFullStatement(context, 'DEALER')),
            _summaryItem(context, 'Earned', currencyFormat.format(sale.currentDealerCommission), isBold: true, hasReceipts: true, onTap: () => _viewFullStatement(context, 'DEALER')),
            _summaryItem(context, 'Paid', currencyFormat.format(sale.dealerPaidAmount), color: Colors.green, hasReceipts: true, onTap: () => _viewFullStatement(context, 'DEALER')),
            _summaryItem(context, 'Balance', currencyFormat.format(sale.dealerCommissionRemaining), color: Colors.red, hasReceipts: true, onTap: () => _viewFullStatement(context, 'DEALER')),
          ],
        ),
        _buildHistoryTitle('COMMISSION PAYOUT HISTORY'),
        Expanded(
          child: sale.dealerPayments.isEmpty
              ? _buildEmptyState('No payments made to dealer yet.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sale.dealerPayments.length,
                  itemBuilder: (context, index) {
                    final p = sale.dealerPayments[index];
                    return _buildPayoutItem(
                      context,
                      date: p.date,
                      amount: p.amount,
                      remarks: p.remarks,
                      color: Colors.green,
                      partnerType: 'DEALER',
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLandownerShareTab(BuildContext context) {
    final sale = widget.sale;
    return Column(
      children: [
        _buildSummaryCard(
          context,
          title: 'LANDOWNER SHARE (PAYOUT)',
          color: Colors.purple,
          items: [
            _summaryItem(context, 'Total Share', currencyFormat.format(sale.landownerTotalShare), hasReceipts: true, onTap: () => _viewFullStatement(context, 'LANDOWNER_SHARE')),
            _summaryItem(context, 'From Client', currencyFormat.format(sale.landownerShareReceived), color: Colors.blue, hasReceipts: true, onTap: () => _viewFullStatement(context, 'LANDOWNER_SHARE')),
            _summaryItem(context, 'Paid to L/O', currencyFormat.format(sale.landownerPaidAmount), color: Colors.purple, isBold: true, hasReceipts: true, onTap: () => _viewFullStatement(context, 'LANDOWNER_SHARE')),
            _summaryItem(context, 'Balance', currencyFormat.format(sale.landownerShareRemaining), color: Colors.red, hasReceipts: true, onTap: () => _viewFullStatement(context, 'LANDOWNER_SHARE')),
          ],
        ),
        _buildHistoryTitle('SHARE PAYOUT HISTORY'),
        Expanded(
          child: sale.landownerPayments.isEmpty
              ? _buildEmptyState('No share payouts made to landowner yet.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sale.landownerPayments.length,
                  itemBuilder: (context, index) {
                    final p = sale.landownerPayments[index];
                    return _buildPayoutItem(
                      context,
                      date: p.date,
                      amount: p.amount,
                      remarks: p.remarks,
                      color: Colors.purple,
                      partnerType: 'LANDOWNER_SHARE',
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCompanyCommTab(BuildContext context) {
    final sale = widget.sale;
    return Column(
      children: [
        _buildSummaryCard(
          context,
          title: 'COMPANY COMMISSION (INCOME)',
          color: Colors.blue,
          items: [
            _summaryItem(context, 'Required', currencyFormat.format(sale.landownerCommission), hasReceipts: true, onTap: () => _viewFullStatement(context, 'LANDOWNER_COMM')),
            _summaryItem(context, 'Received', currencyFormat.format(sale.landownerCommissionReceived), color: Colors.blue, isBold: true, hasReceipts: true, onTap: () => _viewFullStatement(context, 'LANDOWNER_COMM')),
            _summaryItem(context, 'Remaining', currencyFormat.format(sale.landownerCommissionRemaining), color: Colors.orange, hasReceipts: true, onTap: () => _viewFullStatement(context, 'LANDOWNER_COMM')),
          ],
        ),
        _buildHistoryTitle('COMPANY INCOME HISTORY'),
        Expanded(
          child: sale.landownerCommissionHistory.isEmpty
              ? _buildEmptyState('No commission received by company yet.')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sale.landownerCommissionHistory.length,
                  itemBuilder: (context, index) {
                    final p = sale.landownerCommissionHistory[index];
                    return _buildPayoutItem(
                      context,
                      date: p.date,
                      amount: p.amount,
                      remarks: p.remarks,
                      color: Colors.blue,
                      partnerType: 'LANDOWNER_COMM',
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.history_rounded, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {required String title, required List<Widget> items, required Color color}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: items,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(BuildContext context, String label, String value, {Color? color, bool isBold = false, bool hasReceipts = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                if (hasReceipts && onTap != null) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.receipt_long_rounded, size: 12, color: color?.withOpacity(0.7) ?? Colors.grey),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: color ?? AppTheme.charcoalGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutItem(BuildContext context, {required String date, required double amount, String? remarks, required Color color, required String partnerType}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(partnerType == 'LANDOWNER_COMM' ? Icons.trending_up_rounded : Icons.file_upload_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currencyFormat.format(amount), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: color)),
                Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          if (remarks != null && remarks.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                remarks,
                style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: AppTheme.charcoalGray),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          IconButton(
            icon: Icon(Icons.remove_red_eye_rounded, color: color, size: 20),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RealEstateReceiptPreviewScreen(
              sale: widget.sale,
              partnerAmount: amount,
              partnerType: partnerType,
              partnerRemarks: remarks ?? 'Company Commission Received',
            ))),
            tooltip: 'View Receipt',
          ),
          IconButton(
            icon: Icon(Icons.print_rounded, color: color, size: 20),
            onPressed: () {
              if (partnerType == 'DEALER') {
                RealEstatePrintService.printDealerPaymentReceipt(sale: widget.sale, amountPaid: amount, remarks: remarks);
              } else if (partnerType == 'LANDOWNER_SHARE') {
                RealEstatePrintService.printLandownerPaymentReceipt(sale: widget.sale, amountPaid: amount, remarks: remarks);
              } else {
                RealEstatePrintService.printLandownerPaymentReceipt(sale: widget.sale, amountPaid: amount, remarks: remarks ?? 'Company Commission Received');
              }
            },
            tooltip: 'Print Receipt',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.withOpacity(0.6), fontSize: 13)),
        ],
      ),
    );
  }

  void _viewFullStatement(BuildContext context, String type) {
    if ((type == 'DEALER' && widget.sale.dealerPayments.isEmpty) ||
        (type == 'LANDOWNER_SHARE' && widget.sale.landownerPayments.isEmpty) ||
        (type == 'LANDOWNER_COMM' && widget.sale.landownerCommissionHistory.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No historical records found for this category.')));
      return;
    }

    double totalAmount = 0;
    String remarks = "Full Summary Statement";

    if (type == 'DEALER') totalAmount = widget.sale.dealerPaidAmount;
    if (type == 'LANDOWNER_SHARE') totalAmount = widget.sale.landownerPaidAmount;
    if (type == 'LANDOWNER_COMM') totalAmount = widget.sale.landownerCommissionReceived;

    Navigator.push(context, MaterialPageRoute(builder: (context) => RealEstateReceiptPreviewScreen(
      sale: widget.sale,
      partnerAmount: totalAmount,
      partnerType: type,
      partnerRemarks: remarks,
      isFullStatement: true,
    )));
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.charcoalGray, foregroundColor: Colors.white),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
