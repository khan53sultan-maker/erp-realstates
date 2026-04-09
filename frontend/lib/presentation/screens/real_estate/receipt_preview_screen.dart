import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/real_estate/real_estate_sale_model.dart';
import '../../../src/models/real_estate/installment_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/services/real_estate_print_service.dart';

class RealEstateReceiptPreviewScreen extends StatelessWidget {
  final RealEstateSale sale;
  final RealEstateInstallment? installment;
  final List<RealEstateInstallment>? allInstallments;
  final int? installmentNumber;
  final bool isFullStatement;
  final bool isBookingReceipt;
  // Partner Payment Fields
  final double? partnerAmount;
  final String? partnerType; // 'DEALER', 'LANDOWNER_COMM', 'LANDOWNER_SHARE'
  final String? partnerRemarks;

  const RealEstateReceiptPreviewScreen({
    super.key,
    required this.sale,
    this.installment,
    this.allInstallments,
    this.installmentNumber,
    this.isFullStatement = false,
    this.isBookingReceipt = false,
    this.partnerAmount,
    this.partnerType,
    this.partnerRemarks,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final String title = isFullStatement 
        ? 'Full Payment Statement' 
        : (isBookingReceipt ? 'Booking Receipt' : (partnerType != null ? '${partnerType?.replaceAll('_', ' ')} Receipt' : 'Installment Receipt'));
    
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.primaryMaroon,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              if (isFullStatement) {
                // Full statement print
              } else if (isBookingReceipt) {
                RealEstatePrintService.printDownPaymentReceipt(sale: sale);
              } else if (partnerType == 'DEALER') {
                RealEstatePrintService.printDealerPaymentReceipt(sale: sale, amountPaid: partnerAmount ?? 0, remarks: partnerRemarks);
              } else if (partnerType != null) {
                RealEstatePrintService.printLandownerPaymentReceipt(sale: sale, amountPaid: partnerAmount ?? 0, remarks: partnerRemarks);
              } else if (installment != null) {
                RealEstatePrintService.printSingleInstallmentReceipt(
                  sale: sale,
                  installment: installment!,
                  installmentNumber: installmentNumber ?? 0,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: screenWidth > 800 ? 500 : 90.w,
            margin: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, spreadRadius: 5),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      if (partnerType != null) _buildPartnerReceiptContent(currencyFormat)
                      else if (isFullStatement) _buildFullStatementContent(currencyFormat)
                      else _buildSingleReceiptContent(currencyFormat),
                      
                      const SizedBox(height: 50),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text('Thank you for choosing Iconic Estate', 
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      const SizedBox(height: 40),
                      _buildSignature(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.primaryMaroon,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 25,
            child: Icon(Icons.business, color: AppTheme.primaryMaroon),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Iconic Estate', 
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text('A Sign of Trust', 
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleReceiptContent(NumberFormat formatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(isBookingReceipt ? 'BOOKING RECEIPT' : 'PAYMENT RECEIPT', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryMaroon)),
        ),
        const SizedBox(height: 10),
        if (isBookingReceipt)
          Center(child: Text('(Down Payment Paid at Booking)', style: TextStyle(fontSize: 10, color: Colors.grey[600]))),
        const SizedBox(height: 20),
        _row(isBookingReceipt ? 'Booking No:' : 'Receipt No:', 
            isBookingReceipt 
                ? (sale.receiptNumber != null && sale.receiptNumber!.isNotEmpty
                    ? sale.receiptNumber!
                    : 'BK-${sale.id?.substring(0, 8).toUpperCase() ?? 'NEW'}')
                : (installment?.paymentHistory.isNotEmpty == true && installment!.paymentHistory.last.receiptNumber != null && installment!.paymentHistory.last.receiptNumber!.isNotEmpty
                    ? installment!.paymentHistory.last.receiptNumber!
                    : 'RE-${installment?.id?.substring(0, 8).toUpperCase() ?? 'NEW'}')),
        _row('Date:', isBookingReceipt 
            ? (sale.saleDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()))
            : (installment?.paidDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()))),
        const Divider(height: 30),
        _row('Customer:', sale.customerName ?? 'N/A'),
        _row('Project:', sale.projectName ?? 'N/A'),
        _row('Plot Number:', sale.plotNumber ?? 'N/A'),
        if (!isBookingReceipt) _row('Installment:', '#${installmentNumber ?? 'N/A'}'),
        if (isBookingReceipt) _row('Plot Price:', formatter.format(sale.totalPrice)),
        const Divider(height: 30),
        
        if (!isBookingReceipt && installment != null && installment!.paymentHistory.isNotEmpty) ...[
          const Text('PAYMENT HISTORY:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.charcoalGray)),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: const [
                  Padding(padding: EdgeInsets.all(4), child: Text('Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(4), child: Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(4), child: Text('Receipt #', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(4), child: Text('Remarks', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
              ...installment!.paymentHistory.map((p) => TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(4), child: Text(p.paymentDate, style: const TextStyle(fontSize: 10))),
                  Padding(padding: const EdgeInsets.all(4), child: Text(formatter.format(p.amount), style: const TextStyle(fontSize: 10))),
                  Padding(padding: const EdgeInsets.all(4), child: Text((p.receiptNumber != null && p.receiptNumber!.isNotEmpty) ? p.receiptNumber! : 'RE-${p.id?.substring(0, 8).toUpperCase() ?? "NEW"}', style: const TextStyle(fontSize: 10))),
                  Padding(padding: const EdgeInsets.all(4), child: Text(p.remarks ?? '-', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic))),
                ],
              )),
            ],
          ),
          const SizedBox(height: 20),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(isBookingReceipt ? 'DOWN PAYMENT PAID:' : 'TOTAL PAID:', 
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(formatter.format(isBookingReceipt ? sale.receivedDownPayment : installment?.paidAmount ?? 0), 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.green.shade800)),
          ],
        ),
        if (isBookingReceipt && sale.receivedDownPayment < sale.downPayment) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('REMAINING DP:', style: TextStyle(fontSize: 10, color: Colors.red)),
              Text(formatter.format(sale.downPayment - sale.receivedDownPayment), 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ],
        if (!isBookingReceipt && installment != null && installment!.paidAmount < installment!.amount) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('REMAINING IN THIS INST:', style: TextStyle(fontSize: 10, color: Colors.red)),
              Text(formatter.format(installment!.amount - installment!.paidAmount), 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ],
        const SizedBox(height: 10),
        if (isBookingReceipt)
           _row('Balance Price:', formatter.format(sale.totalPrice - sale.receivedDownPayment), color: AppTheme.charcoalGray)
        else
           Text('Status: ${installment?.status ?? 'PENDING'}', 
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: installment?.status == 'PAID' ? Colors.green : Colors.orange)),
      ],
    );
  }

  Widget _buildFullStatementContent(NumberFormat formatter) {
    final remaining = sale.currentBalance;
    final totalInstallments = allInstallments?.length ?? 0;
    
    final paidList = allInstallments?.where((i) => i.status == 'PAID') ?? [];
    final paidCount = paidList.length;
    final paidSubtotal = paidList.fold(0.0, (sum, i) => sum + i.amount);
    
    final pendingList = allInstallments?.where((i) => i.status != 'PAID') ?? [];
    final pendingCount = pendingList.length;
    final pendingSubtotal = pendingList.fold(0.0, (sum, i) => sum + i.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text('FINANCIAL STATEMENT', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryMaroon)),
        ),
        const SizedBox(height: 30),
        _row('Customer:', sale.customerName ?? 'N/A'),
        _row('Plot:', '${sale.plotNumber} (${sale.plotSize})'),
        _row('Project:', sale.projectName ?? 'N/A'),
        const Divider(height: 30),
        
        // Installment Summary Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.creamWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              _summaryRow('Total Installments:', '$totalInstallments'),
              _summaryRow('Paid ($paidCount):', formatter.format(paidSubtotal), color: Colors.green),
              _summaryRow('Pending ($pendingCount):', formatter.format(pendingSubtotal), color: Colors.orange.shade900),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _row('Total Plot Price:', formatter.format(sale.totalPrice)),
        _row('Down Payment:', formatter.format(sale.downPayment)),
        _row('Total Received:', formatter.format(sale.totalReceived), color: Colors.green.shade800),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('REMAINING BALANCE:', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              Text(formatter.format(remaining), 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerReceiptContent(NumberFormat formatter) {
    String subTitle = '';
    Color themeColor = AppTheme.primaryMaroon;
    String voucherType = '';
    List<dynamic> history = [];
    String partnerLabel = '';
    
    if (partnerType == 'DEALER') {
      subTitle = isFullStatement ? 'DEALER PAYMENT STATEMENT' : 'DEALER PAYMENT VOUCHER';
      voucherType = 'DC';
      themeColor = Colors.green.shade800;
      history = sale.dealerPayments;
      partnerLabel = 'Dealer: ${sale.dealerName ?? 'N/A'}';
    } else if (partnerType == 'LANDOWNER_COMM') {
      subTitle = isFullStatement ? 'COMPANY INCOME STATEMENT' : 'COMPANY INCOME VOUCHER';
      voucherType = 'LC';
      themeColor = Colors.blue.shade800;
      history = sale.landownerCommissionHistory;
      partnerLabel = 'Project: ${sale.projectName ?? 'N/A'}';
    } else {
      subTitle = isFullStatement ? 'LANDOWNER SETTLEMENT STATEMENT' : 'LANDOWNER SETTLEMENT VOUCHER';
      voucherType = 'LP';
      themeColor = Colors.purple.shade800;
      history = sale.landownerPayments;
      partnerLabel = 'Landowner Account';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(subTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: themeColor)),
        ),
        const SizedBox(height: 20),
        _row('Voucher No:', '$voucherType-${sale.id?.substring(0, 5).toUpperCase() ?? 'NEW'}'),
        _row('Ref Plot:', sale.plotNumber ?? 'N/A'),
        _row('Date Printed:', DateFormat('dd MMM yyyy').format(DateTime.now())),
        const Divider(height: 20),
        _row('Category:', partnerLabel),
        _row('Customer Ref:', sale.customerName ?? 'N/A'),
        const Divider(height: 20),
        
        if (isFullStatement && history.isNotEmpty) ...[
          Text('TRANSACTION HISTORY:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeColor)),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: themeColor.withOpacity(0.05)),
                children: const [
                  Padding(padding: EdgeInsets.all(6), child: Text('Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(6), child: Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Padding(padding: EdgeInsets.all(6), child: Text('Notes', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
              ...history.map((p) => TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(p.date, style: const TextStyle(fontSize: 10))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(formatter.format(p.amount), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(p.remarks ?? '-', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic))),
                ],
              )),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL RECORDED:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(formatter.format(partnerAmount ?? 0), 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: themeColor)),
            ],
          ),
        ] else ...[
          // Single receipt view
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AMOUNT PAID:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(formatter.format(partnerAmount ?? 0), 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: themeColor)),
            ],
          ),
          const SizedBox(height: 10),
          if (partnerRemarks != null && partnerRemarks!.isNotEmpty) ...[
            const Text('REMARKS / NOTES:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            Text(partnerRemarks!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
        
        const SizedBox(height: 30),
        const Text('SUMMARY STATUS:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 5),
        if (partnerType == 'DEALER') ...[
          _row('Total Expected:', formatter.format(sale.dealerCommission)),
          _row('Paid so far:', formatter.format(sale.dealerPaidAmount)),
          _row('Balance:', formatter.format(sale.dealerCommissionRemaining), color: Colors.red),
        ] else if (partnerType == 'LANDOWNER_SHARE') ...[
          _row('Plot Total Share:', formatter.format(sale.landownerTotalShare)),
          _row('Already Paid:', formatter.format(sale.landownerPaidAmount)),
          _row('Remaining:', formatter.format(sale.landownerShareRemaining), color: Colors.red),
        ] else if (partnerType == 'LANDOWNER_COMM') ...[
          _row('Expected Commission:', formatter.format(sale.landownerCommission)),
          _row('Received so far:', formatter.format(sale.landownerCommissionReceived)),
          _row('Remaining:', formatter.format(sale.landownerCommissionRemaining), color: Colors.orange.shade900),
        ]
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildSignature() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          children: [
            Container(width: 150, height: 1, color: Colors.black),
            const SizedBox(height: 5),
            const Text('Authorized Signature', style: TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }
}
