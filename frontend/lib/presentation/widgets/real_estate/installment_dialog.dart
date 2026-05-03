import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/models/real_estate/real_estate_sale_model.dart';
import '../../../src/models/real_estate/installment_model.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/services/real_estate_print_service.dart';
import '../../../src/models/real_estate/payout_history_model.dart';
import '../../screens/real_estate/receipt_preview_screen.dart';

class InstallmentDialog extends StatefulWidget {
  final RealEstateSale sale;

  const InstallmentDialog({super.key, required this.sale});

  @override
  State<InstallmentDialog> createState() => _InstallmentDialogState();
}

class _InstallmentDialogState extends State<InstallmentDialog> {
  bool _showDownPaymentHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RealEstateProvider>().fetchInstallments(saleId: widget.sale.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(context.mainPadding),
      child: Container(
        width: context.dialogWidth * 1.2,
        constraints: BoxConstraints(maxHeight: 90.h, maxWidth: 850),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(context.borderRadius('large')),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.borderRadius('large')),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              _buildSummaryHeader(context, currencyFormat),
              Flexible(child: _buildInstallmentList(context, currencyFormat)),
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
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Installment Payment Plan',
                  style: TextStyle(
                    color: AppTheme.pureWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Plot: ${widget.sale.plotNumber} | ${widget.sale.customerName}',
                  style: TextStyle(
                    color: AppTheme.pureWhite.withOpacity(0.8),
                    fontSize: 12,
                  ),
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

  Widget _buildSummaryHeader(BuildContext context, NumberFormat formatter) {
    return Consumer<RealEstateProvider>(
      builder: (context, provider, child) {
        // Find current sale from provider to get updated received_down_payment
        final currentSale = provider.sales.firstWhere((s) => s.id == widget.sale.id, orElse: () => widget.sale);
        
        final paidInstallments = provider.installments
            .where((i) => i.status == 'PAID' || i.status == 'PARTIAL')
            .fold(0.0, (sum, i) => sum + i.paidAmount);
        
        final totalReceived = currentSale.receivedDownPayment + paidInstallments;
        final remaining = currentSale.totalPrice - totalReceived;

        return Container(
          padding: EdgeInsets.all(context.cardPadding),
          color: AppTheme.creamWhite,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Price', formatter.format(currentSale.totalPrice), Colors.black87),
              _buildSummaryItem('Paid Amount', formatter.format(totalReceived), Colors.green),
              _buildSummaryItem('Remaining', formatter.format(remaining), Colors.red),
            ],
          ),
        );
      },
    );
  }



  Widget _buildDownPaymentCard(BuildContext context, NumberFormat formatter) {
    return Consumer<RealEstateProvider>(
      builder: (context, provider, child) {
        final currentSale = provider.sales.firstWhere((s) => s.id == widget.sale.id, orElse: () => widget.sale);
        final isFullyPaid = currentSale.receivedDownPayment >= currentSale.downPayment;

        return Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFullyPaid ? [Colors.green.shade50, Colors.white] : [Colors.blue.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (isFullyPaid ? Colors.green : Colors.blue).withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: (isFullyPaid ? Colors.green : Colors.blue).withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(color: (isFullyPaid ? Colors.green.shade100 : Colors.blue.shade100), shape: BoxShape.circle),
                        child: Icon(Icons.account_balance_wallet_rounded, color: (isFullyPaid ? Colors.green.shade800 : Colors.blue.shade800), size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('DOWN PAYMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: (isFullyPaid ? Colors.green.shade900 : Colors.blue.shade900))),
                                if (currentSale.downPaymentHistory.isNotEmpty)
                                  IconButton(
                                    constraints: BoxConstraints(),
                                    padding: EdgeInsets.only(left: 4),
                                    icon: Icon(_showDownPaymentHistory ? Icons.expand_less : Icons.history, size: 16, color: Colors.blueGrey),
                                    onPressed: () => setState(() => _showDownPaymentHistory = !_showDownPaymentHistory),
                                  ),
                              ],
                            ),
                            Text(
                              '${formatter.format(currentSale.receivedDownPayment)} / ${formatter.format(currentSale.downPayment)}', 
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentSale.receivedDownPayment > 0) ...[
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RealEstateReceiptPreviewScreen(
                                      sale: currentSale,
                                      isBookingReceipt: true,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.remove_red_eye_rounded, color: AppTheme.primaryMaroon),
                              tooltip: 'View Receipt',
                            ),
                            IconButton(
                              onPressed: () => RealEstatePrintService.printDownPaymentReceipt(sale: currentSale),
                              icon: const Icon(Icons.print_rounded, color: Colors.green),
                              tooltip: 'Print Receipt',
                            ),
                            IconButton(
                              onPressed: () => setState(() => _showDownPaymentHistory = !_showDownPaymentHistory),
                              icon: Icon(_showDownPaymentHistory ? Icons.history_toggle_off : Icons.history, color: Colors.blueGrey),
                              tooltip: 'Payment History',
                            ),
                          ],
                          if (!isFullyPaid)
                            ElevatedButton(
                              onPressed: () => _payDownPayment(context, currentSale),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: currentSale.receivedDownPayment > 0 ? Colors.orange : AppTheme.primaryMaroon,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: Text(currentSale.receivedDownPayment > 0 ? 'Add Pay' : 'Pay', style: const TextStyle(fontSize: 10)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                              child: const Text('PAID', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (_showDownPaymentHistory && currentSale.downPaymentHistory.isNotEmpty) ...[
                    const Divider(height: 20),
                    ...currentSale.downPaymentHistory.map((h) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                        border: Border.all(color: Colors.blue.withOpacity(0.1)),
                      ),
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(h.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                  Text(formatter.format(h.amount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryMaroon)),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                    onPressed: () => _handleEditDownPayment(context, h, currentSale.id),
                                    tooltip: 'Edit Payment',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                    onPressed: () => _handleDeleteDownPayment(context, h.id, currentSale.id),
                                    tooltip: 'Delete Payment',
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if ((h.receiptNumber != null && h.receiptNumber!.isNotEmpty) || (h.remarks != null && h.remarks!.isNotEmpty))
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  if (h.receiptNumber != null && h.receiptNumber!.isNotEmpty) ...[
                                    const Icon(Icons.receipt_long_rounded, size: 10, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('Ref: ${h.receiptNumber}', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    if (h.remarks != null && h.remarks!.isNotEmpty) const SizedBox(width: 12),
                                  ],
                                  if (h.remarks != null && h.remarks!.isNotEmpty) ...[
                                    const Icon(Icons.info_outline_rounded, size: 10, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text('Remarks: ${h.remarks}', style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic))),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    )).toList(),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.black87.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildInstallmentList(BuildContext context, NumberFormat formatter) {
    return Consumer<RealEstateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.installments.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryMaroon));
        }

        if (provider.installments.isEmpty) {
          return const Center(child: Text('No installments found.'));
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: context.cardPadding),
          itemCount: provider.installments.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildDownPaymentCard(context, formatter);
            }
            final inst = provider.installments[index - 1];
            final actualIndex = index - 1;
            final isPaid = inst.status == 'PAID';
            final isPartial = inst.status == 'PARTIAL';
            final isPending = inst.status == 'PENDING';

            final isBalloon = (actualIndex + 1) % 6 == 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isPaid ? Colors.green.withOpacity(0.05) : (isPartial ? Colors.orange.withOpacity(0.05) : (isBalloon ? Colors.deepOrange.withOpacity(0.02) : AppTheme.pureWhite)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isPaid 
                    ? Colors.green.withOpacity(0.3) 
                    : (isPartial 
                        ? Colors.orange.withOpacity(0.3) 
                        : (isBalloon ? Colors.deepOrange.withOpacity(0.5) : Colors.grey.withOpacity(0.2))),
                  width: isBalloon ? 1.5 : 1.0,
                ),
              ),
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                collapsedShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                tilePadding: const EdgeInsets.only(left: 12, right: 8),
                leading: CircleAvatar(
                  backgroundColor: isPaid ? Colors.green : (isPartial ? Colors.orange : Colors.orange.withOpacity(0.2)),
                  child: Text('${actualIndex + 1}', style: TextStyle(color: (isPaid || isPartial) ? Colors.white : Colors.orange.shade900, fontWeight: FontWeight.bold)),
                ),
                title: Row(
                  children: [
                    Text(formatter.format(inst.amount), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87)),
                    if (isBalloon) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BALLOON PAYMENT', 
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                    if (isPartial) ...[
                      const SizedBox(width: 8),
                      Text('(Paid: ${formatter.format(inst.paidAmount)})', style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due: ${inst.dueDate}${(isPaid || isPartial) ? ' | Last Paid: ${inst.paidDate}' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (inst.paymentHistory.isNotEmpty)
                      const Text(
                        'Click to view history',
                        style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                trailing: !isPending 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RealEstateReceiptPreviewScreen(
                                  sale: widget.sale,
                                  installment: inst,
                                  installmentNumber: actualIndex + 1,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.remove_red_eye_rounded, color: AppTheme.primaryMaroon),
                        ),
                        IconButton(
                          onPressed: () => RealEstatePrintService.printSingleInstallmentReceipt(
                            sale: widget.sale,
                            installment: inst,
                            installmentNumber: actualIndex + 1,
                          ),
                          icon: const Icon(Icons.print_rounded, color: Colors.green),
                        ),
                        if (isPartial) 
                          ElevatedButton(
                            onPressed: () => _markAsPaid(context, inst),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                            child: const Text('Add Pay', style: TextStyle(fontSize: 10)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                            child: const Text('PAID', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () => _markAsPaid(context, inst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMaroon,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mark Paid'),
                    ),
                children: [
                  if (inst.paymentHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey)),
                          const SizedBox(height: 8),
                          ...inst.paymentHistory.map((h) => Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(h.paymentDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    Text(formatter.format(h.amount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryMaroon)),
                                    if (h.remarks != null && h.remarks!.isNotEmpty)
                                      Text(h.remarks!, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (h.receiptNumber != null && h.receiptNumber!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Text('Ref: ${h.receiptNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                      onPressed: () => _handleEditInstallmentPayment(context, h, widget.sale.id),
                                      tooltip: 'Edit Payment',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                      onPressed: () => _handleDeleteInstallmentPayment(context, h.id, widget.sale.id),
                                      tooltip: 'Delete Payment',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )).toList(),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              final provider = context.read<RealEstateProvider>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RealEstateReceiptPreviewScreen(
                    sale: widget.sale,
                    allInstallments: provider.installments,
                    isFullStatement: true,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.remove_red_eye_rounded),
            label: const Text('View Statement'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryMaroon,
              side: const BorderSide(color: AppTheme.primaryMaroon),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              final provider = context.read<RealEstateProvider>();
              RealEstatePrintService.printInstallmentPlan(
                sale: widget.sale,
                installments: provider.installments,
              );
            },
            icon: const Icon(Icons.print_rounded),
            label: const Text('Print Schedule'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _markAsPaid(BuildContext rootContext, RealEstateInstallment installment) async {
    final TextEditingController amountController = TextEditingController(
      text: (installment.amount - installment.paidAmount).toStringAsFixed(0)
    );
    final TextEditingController receiptController = TextEditingController();
    final TextEditingController remarksController = TextEditingController();
    
    DateTime selectedDate = DateTime.now();
    bool showCalendar = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          double? amountToPay = double.tryParse(amountController.text) ?? 0;
          double remainingAfterThis = installment.amount - installment.paidAmount - amountToPay;
          
          return AlertDialog(
            title: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryMaroon,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              ),
              child: const Text('Make Payment', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            titlePadding: const EdgeInsets.all(0),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _dialogInfoRow('Installment Total:', 'Rs. ${installment.amount.toStringAsFixed(0)}', Colors.black87),
                          _dialogInfoRow('Already Paid:', 'Rs. ${installment.paidAmount.toStringAsFixed(0)}', Colors.green),
                          _dialogInfoRow('Pending Balance:', 'Rs. ${(installment.amount - installment.paidAmount).toStringAsFixed(0)}', Colors.red),
                          const Divider(height: 20),
                          
                          const Text('Payment Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                showCalendar = !showCalendar;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.pureWhite,
                                border: Border.all(color: AppTheme.primaryMaroon, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit_calendar, color: AppTheme.primaryMaroon),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('EEEE, dd MMM yyyy').format(selectedDate),
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryMaroon, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          if (showCalendar) ...[
                            const SizedBox(height: 10),
                            Container(
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: SfDateRangePicker(
                                onSelectionChanged: (args) {
                                  setDialogState(() {
                                    selectedDate = args.value;
                                    showCalendar = false;
                                  });
                                },
                                selectionMode: DateRangePickerSelectionMode.single,
                                initialSelectedDate: selectedDate,
                                headerStyle: const DateRangePickerHeaderStyle(
                                  textAlign: TextAlign.center,
                                  textStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMaroon)
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        fontFamilyFallback: ['Jameel Noori Nastaleeq', 'Noto Nastaliq Urdu'],
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                           amountToPay = double.tryParse(val) ?? 0;
                           remainingAfterThis = installment.amount - installment.paidAmount - amountToPay!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Amount to Pay Now',
                        labelStyle: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(),
                        prefixText: 'Rs. ',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: receiptController,
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        fontFamilyFallback: ['Jameel Noori Nastaleeq', 'Noto Nastaliq Urdu'],
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Receipt / Voucher Number',
                        labelStyle: TextStyle(color: Colors.black87),
                        border: OutlineInputBorder(),
                        hintText: 'Enter manual receipt number...',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.receipt_long_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarksController,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        fontFamilyFallback: ['Jameel Noori Nastaleeq', 'Noto Nastaliq Urdu'],
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Remarks (e.g. Cash, Bank Transfer)',
                        labelStyle: TextStyle(color: Colors.black87),
                        border: OutlineInputBorder(),
                        hintText: 'Any specific details...',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: remainingAfterThis <= 0 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Balance After This:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rs. ${remainingAfterThis.clamp(0, double.infinity).toStringAsFixed(0)}', 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: remainingAfterThis <= 0 ? Colors.green : Colors.red,
                              fontSize: 16
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext), 
                child: const Text('Cancel', style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, {
                    'amount': double.tryParse(amountController.text),
                    'remarks': remarksController.text,
                    'receipt_number': receiptController.text,
                    'date': selectedDate,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );

    if (result == null || result['amount'] == null || result['amount'] <= 0) return;

    final double amountToPayResult = result['amount'];
    final String remarks = result['remarks'];
    final String receiptNumber = result['receipt_number'];
    final DateTime paymentDate = result['date'];

    final dateStr = '${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.day.toString().padLeft(2, '0')}';
    
    final newPaidAmount = installment.paidAmount + amountToPayResult;
    final String newStatus = newPaidAmount >= installment.amount ? 'PAID' : 'PARTIAL';

    final success = await rootContext.read<RealEstateProvider>().updateInstallment(
      installment.id!,
      {
        'status': newStatus,
        'paid_date': dateStr,
        'paid_amount': newPaidAmount.toString(),
        'receipt_number': receiptNumber,
        'payment_remarks': remarks,
      },
    );

    if (success) {
      if (mounted) {
        rootContext.read<RealEstateProvider>().fetchSales(); // Refresh totals
        rootContext.read<RealEstateProvider>().fetchInstallments(saleId: widget.sale.id); // Refresh history
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            content: Text(newStatus == 'PAID' ? 'Installment fully paid!' : 'Partial payment recorded successfully!')
          ),
        );
      }
    }
  }

  void _payDownPayment(BuildContext rootContext, RealEstateSale sale) async {
    final TextEditingController amountController = TextEditingController(
      text: (sale.downPayment - sale.receivedDownPayment).toStringAsFixed(0)
    );
    final TextEditingController receiptController = TextEditingController();
    final TextEditingController remarksController = TextEditingController();
    
    DateTime selectedDate = DateTime.now();
    bool showCalendar = false;

    final result = await showDialog<Map<String, dynamic>>(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          double? amountToPay = double.tryParse(amountController.text) ?? 0;
          double remainingAfterThis = sale.downPayment - sale.receivedDownPayment - amountToPay;
          
          return AlertDialog(
            title: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryMaroon,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
              ),
              child: const Text('Pay Down Payment', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            titlePadding: const EdgeInsets.all(0),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _dialogInfoRow('Total Down Payment:', 'Rs. ${sale.downPayment.toStringAsFixed(0)}', Colors.black87),
                          _dialogInfoRow('Already Paid:', 'Rs. ${sale.receivedDownPayment.toStringAsFixed(0)}', Colors.green),
                          _dialogInfoRow('Pending Balance:', 'Rs. ${(sale.downPayment - sale.receivedDownPayment).toStringAsFixed(0)}', Colors.red),
                          const Divider(height: 20),
                          
                          const Text('Payment Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                showCalendar = !showCalendar;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.pureWhite,
                                border: Border.all(color: AppTheme.primaryMaroon, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.edit_calendar, color: AppTheme.primaryMaroon),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('EEEE, dd MMM yyyy').format(selectedDate),
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primaryMaroon, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          if (showCalendar) ...[
                            const SizedBox(height: 10),
                            Container(
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: SfDateRangePicker(
                                onSelectionChanged: (args) {
                                  setDialogState(() {
                                    selectedDate = args.value;
                                    showCalendar = false;
                                  });
                                },
                                selectionMode: DateRangePickerSelectionMode.single,
                                initialSelectedDate: selectedDate,
                                headerStyle: const DateRangePickerHeaderStyle(
                                  textAlign: TextAlign.center,
                                  textStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMaroon)
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        fontFamilyFallback: ['Jameel Noori Nastaleeq', 'Noto Nastaliq Urdu'],
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                           amountToPay = double.tryParse(val) ?? 0;
                           remainingAfterThis = sale.downPayment - sale.receivedDownPayment - amountToPay!;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Amount to Pay Now',
                        labelStyle: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(),
                        prefixText: 'Rs. ',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: receiptController,
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        fontFamilyFallback: ['Jameel Noori Nastaleeq', 'Noto Nastaliq Urdu'],
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Receipt / Voucher Number',
                        labelStyle: TextStyle(color: AppTheme.primaryMaroon),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.primaryMaroon),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarksController,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 18,
                        fontFamilyFallback: ['Jameel Noori Nastaleeq', 'Noto Nastaliq Urdu'],
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Remarks',
                        labelStyle: TextStyle(color: AppTheme.primaryMaroon),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: remainingAfterThis <= 0 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Balance After This:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rs. ${remainingAfterThis.clamp(0, double.infinity).toStringAsFixed(0)}', 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: remainingAfterThis <= 0 ? Colors.green : Colors.red,
                              fontSize: 16
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext), 
                child: const Text('Cancel')
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, {
                    'amount': double.tryParse(amountController.text),
                    'remarks': remarksController.text,
                    'receipt_number': receiptController.text,
                    'payment_date': selectedDate,
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon),
                child: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );

    if (result == null || result['amount'] == null || result['amount'] <= 0) return;

    final double amount = result['amount'];
    final String remarks = result['remarks'];
    final String receiptNumber = result['receipt_number'];
    final DateTime paymentDate = result['payment_date'];

    final dateStr = '${paymentDate.year}-${paymentDate.month.toString().padLeft(2, '0')}-${paymentDate.day.toString().padLeft(2, '0')}';
    
    final success = await rootContext.read<RealEstateProvider>().payDownPayment(
      sale.id!,
      {
        'amount': amount,
        'payment_date': dateStr,
        'receipt_number': receiptNumber,
        'remarks': remarks,
      },
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Down payment recorded successfully!'))
        );
      }
    }
  }

  Widget _dialogInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  void _handleDeleteDownPayment(BuildContext rootContext, String? paymentId, String? saleId) async {
    if (paymentId == null || saleId == null) return;
    
    final confirm = await showDialog<bool>(
      context: rootContext,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this down payment record? This will revert the sale balance and remove it from financial logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final success = await rootContext.read<RealEstateProvider>().deleteDownPaymentPayment(paymentId, saleId: saleId);
      if (success) {
        if (mounted) {
           ScaffoldMessenger.of(rootContext).showSnackBar(const SnackBar(content: Text('Payment deleted successfully'), backgroundColor: Colors.green));
        }
      }
    }
  }

  void _handleDeleteInstallmentPayment(BuildContext rootContext, String? paymentId, String? saleId) async {
    if (paymentId == null || saleId == null) return;
    
    final confirm = await showDialog<bool>(
      context: rootContext,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this installment payment record? This will revert the installment balance and remove it from financial logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final success = await rootContext.read<RealEstateProvider>().deleteInstallmentPayment(paymentId, saleId: saleId);
      if (success) {
        if (mounted) {
           rootContext.read<RealEstateProvider>().fetchInstallments(saleId: saleId);
           ScaffoldMessenger.of(rootContext).showSnackBar(const SnackBar(content: Text('Payment deleted successfully'), backgroundColor: Colors.green));
        }
      }
    }
  }

  void _handleEditDownPayment(BuildContext rootContext, DownPaymentRec payment, String? saleId) async {
    if (saleId == null) return;
    final TextEditingController amountController = TextEditingController(text: payment.amount.toStringAsFixed(0));
    final TextEditingController remarksController = TextEditingController(text: payment.remarks);
    final TextEditingController receiptController = TextEditingController(text: payment.receiptNumber);

    final result = await showDialog<Map<String, dynamic>>(
      context: rootContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.primaryMaroon,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: const Text('Edit Down Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: AppTheme.primaryMaroon),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.money_rounded, color: AppTheme.primaryMaroon),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: receiptController,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Receipt Number',
                labelStyle: const TextStyle(color: AppTheme.primaryMaroon),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.receipt_rounded, color: AppTheme.primaryMaroon),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              maxLines: 2,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Remarks',
                labelStyle: const TextStyle(color: AppTheme.primaryMaroon),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.notes_rounded, color: AppTheme.primaryMaroon),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'amount': double.tryParse(amountController.text),
              'remarks': remarksController.text,
              'receipt_number': receiptController.text,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && result['amount'] != null) {
      final success = await rootContext.read<RealEstateProvider>().updateDownPaymentPayment(
        payment.id!,
        {
          'amount': result['amount'].toString(),
          'remarks': result['remarks'],
          'receipt_number': result['receipt_number'],
        },
        saleId: saleId,
      );
      if (success) {
        if (mounted) {
           ScaffoldMessenger.of(rootContext).showSnackBar(const SnackBar(content: Text('Payment updated successfully'), backgroundColor: Colors.green));
        }
      }
    }
  }

  void _handleEditInstallmentPayment(BuildContext rootContext, InstallmentPayment payment, String? saleId) async {
    if (saleId == null) return;
    final TextEditingController amountController = TextEditingController(text: payment.amount.toStringAsFixed(0));
    final TextEditingController remarksController = TextEditingController(text: payment.remarks);
    final TextEditingController receiptController = TextEditingController(text: payment.receiptNumber);

    final result = await showDialog<Map<String, dynamic>>(
      context: rootContext,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: AppTheme.primaryMaroon,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: const Text('Edit Installment Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: const TextStyle(color: AppTheme.primaryMaroon),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.money_rounded, color: AppTheme.primaryMaroon),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: receiptController,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Receipt Number',
                labelStyle: const TextStyle(color: AppTheme.primaryMaroon),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.receipt_rounded, color: AppTheme.primaryMaroon),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              maxLines: 2,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Remarks',
                labelStyle: const TextStyle(color: AppTheme.primaryMaroon),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.notes_rounded, color: AppTheme.primaryMaroon),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {
              'amount': double.tryParse(amountController.text),
              'remarks': remarksController.text,
              'receipt_number': receiptController.text,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != null && result['amount'] != null) {
      final success = await rootContext.read<RealEstateProvider>().updateInstallmentPayment(
        payment.id!,
        {
          'amount': result['amount'].toString(),
          'remarks': result['remarks'],
          'receipt_number': result['receipt_number'],
        },
        saleId: saleId,
      );
      if (success) {
        if (mounted) {
           rootContext.read<RealEstateProvider>().fetchInstallments(saleId: saleId);
           ScaffoldMessenger.of(rootContext).showSnackBar(const SnackBar(content: Text('Payment updated successfully'), backgroundColor: Colors.green));
        }
      }
    }
  }
}
