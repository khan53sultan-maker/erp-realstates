import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/real_estate/real_estate_sale_model.dart';
import '../models/real_estate/installment_model.dart';

class RealEstatePrintService {
  /// Generate and print a professional PDF installment plan
  static Future<void> printInstallmentPlan({
    required RealEstateSale sale,
    required List<RealEstateInstallment> installments,
    String companyName = 'Iconic Estate',
    String companyTagline = 'A Sign of Trust',
  }) async {
    final pdf = pw.Document();

    final paidAmount = installments
        .where((i) => i.status == 'PAID')
        .fold(0.0, (sum, i) => sum + i.amount);
    
    // Total received includes down payment + paid installments
    final totalReceived = sale.downPayment + paidAmount;
    final remainingBalance = sale.totalPrice - totalReceived;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(companyName,
                          style: pw.TextStyle(
                              fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                      pw.Text(companyTagline,
                          style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INSTALLMENT PLAN',
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.red900),
              pw.SizedBox(height: 20),

              // Customer & Plot Details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Customer:', sale.customerName ?? 'N/A'),
                        _buildInfoRow('Registration:', sale.registrationNumber ?? 'N/A'),
                        _buildInfoRow('Sale Date:', sale.saleDate ?? 'N/A'),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Project:', sale.projectName ?? 'N/A'),
                        _buildInfoRow('Plot Number:', sale.plotNumber ?? 'N/A'),
                        _buildInfoRow('Plot Size:', sale.plotSize ?? 'N/A'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Financial Summary Table
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Price', 'Rs. ${sale.totalPrice.toStringAsFixed(0)}'),
                    _buildStatItem('Down Payment', 'Rs. ${sale.downPayment.toStringAsFixed(0)}'),
                    _buildStatItem('Paid (Inst)', 'Rs. ${paidAmount.toStringAsFixed(0)}'),
                    _buildStatItem('Total Received', 'Rs. ${totalReceived.toStringAsFixed(0)}', color: PdfColors.green900),
                    _buildStatItem('Remaining', 'Rs. ${remainingBalance.toStringAsFixed(0)}', color: PdfColors.red900),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Installment Table
              pw.Text('Payment Schedule',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.red900),
                    children: [
                      _buildHeaderCell('#'),
                      _buildHeaderCell('Due Date'),
                      _buildHeaderCell('Amount'),
                      _buildHeaderCell('Paid'),
                      _buildHeaderCell('Remaining'),
                      _buildHeaderCell('Status'),
                      _buildHeaderCell('Paid Date'),
                      _buildHeaderCell('Receipt #'),
                    ],
                  ),
                  // Table Rows
                  ...installments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final inst = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildCell((index + 1).toString()),
                        _buildCell(inst.dueDate),
                        _buildCell('Rs. ${inst.amount.toStringAsFixed(0)}'),
                        _buildCell('Rs. ${inst.paidAmount.toStringAsFixed(0)}', color: PdfColors.green900),
                        _buildCell('Rs. ${(inst.amount - inst.paidAmount).toStringAsFixed(0)}', color: PdfColors.red900),
                        _buildCell(inst.status, 
                            color: inst.status == 'PAID' ? PdfColors.green900 : PdfColors.orange900),
                        _buildCell(inst.paidDate ?? '-'),
                        _buildCell((inst.receiptNumber != null && inst.receiptNumber!.isNotEmpty) 
                            ? inst.receiptNumber! 
                            : (inst.status == 'PAID' ? 'RE-${inst.id?.substring(0, 5).toUpperCase() ?? "N/A"}' : '-')),
                      ],
                    );
                  }).toList(),
                ],
              ),
              
              pw.Spacer(),
              
              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by Iconic Estate Management System',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  pw.Text('Signature: ____________________',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Installment_Plan_${sale.plotNumber}.pdf',
    );
  }

  /// Print a professional receipt for a single installment payment
  static Future<void> printSingleInstallmentReceipt({
    required RealEstateSale sale,
    required RealEstateInstallment installment,
    required int installmentNumber,
    String companyName = 'Iconic Estate',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Receipt format
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(companyName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('A Sign of Trust', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 5),
                    pw.Text('PAYMENT RECEIPT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              _buildReceiptRow('Receipt No:', (installment.paymentHistory.isNotEmpty == true && installment.paymentHistory.last.receiptNumber != null && installment.paymentHistory.last.receiptNumber!.isNotEmpty) 
                  ? installment.paymentHistory.last.receiptNumber!
                  : 'RE-${installment.id?.substring(0, 5).toUpperCase() ?? 'N/A'}'),
              _buildReceiptRow('Date:', installment.paidDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now())),
              pw.Divider(thickness: 0.5),
              _buildReceiptRow('Client:', sale.customerName ?? 'N/A'),
              _buildReceiptRow('Project:', sale.projectName ?? 'N/A'),
              _buildReceiptRow('Plot No:', sale.plotNumber ?? 'N/A'),
              _buildReceiptRow('Inst. No:', '#$installmentNumber'),
              pw.Divider(thickness: 0.5),
              
              if (installment.paymentHistory.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text('PAYMENT HISTORY:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Date', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Amount', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Receipt #', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Remarks', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...installment.paymentHistory.map((p) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(p.paymentDate, style: const pw.TextStyle(fontSize: 6))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(p.amount.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 6))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text((p.receiptNumber != null && p.receiptNumber!.isNotEmpty) ? p.receiptNumber! : 'RE-${p.id?.substring(0, 5).toUpperCase() ?? "N/A"}', style: const pw.TextStyle(fontSize: 6))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(p.remarks ?? '-', style: pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic))),
                      ],
                    )),
                  ],
                ),
                pw.SizedBox(height: 10),
              ],

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL PAID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('Rs. ${installment.paidAmount.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                ],
              ),
              if (installment.paidAmount < installment.amount) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('REMAINING IN INST:', style: pw.TextStyle(fontSize: 8, color: PdfColors.red900)),
                    pw.Text('Rs. ${(installment.amount - installment.paidAmount).toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 8, color: PdfColors.red900, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Text('Status: ${installment.status}', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Thank you for choosing Iconic Estate', style: const pw.TextStyle(fontSize: 7)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Receipt_${sale.plotNumber}_Inst_$installmentNumber.pdf',
    );
  }

  /// Print a receipt specifically for the Down Payment
  static Future<void> printDownPaymentReceipt({
    required RealEstateSale sale,
    String companyName = 'Iconic Estate',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(companyName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('A Sign of Trust', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 5),
                    pw.Text('BOOKING RECEIPT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    pw.Text('(Down Payment)', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              _buildReceiptRow('Booking No:', (sale.receiptNumber != null && sale.receiptNumber!.isNotEmpty)
                  ? sale.receiptNumber!
                  : 'BK-${sale.id?.substring(0, 5).toUpperCase() ?? 'N/A'}'),
              _buildReceiptRow('Date:', sale.saleDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now())),
              pw.Divider(thickness: 0.5),
              _buildReceiptRow('Client:', sale.customerName ?? 'N/A'),
              _buildReceiptRow('Project:', sale.projectName ?? 'N/A'),
              _buildReceiptRow('Plot No:', sale.plotNumber ?? 'N/A'),
              _buildReceiptRow('Plot Price:', 'Rs. ${sale.totalPrice.toStringAsFixed(0)}'),
              pw.Divider(thickness: 0.5),
              
              if (sale.downPaymentHistory.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text('PAYMENT HISTORY:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Date', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Amount', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Receipt #', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Remarks', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...sale.downPaymentHistory.map((p) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(p.date, style: const pw.TextStyle(fontSize: 6))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('Rs. ${p.amount.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 6))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text((p.receiptNumber != null && p.receiptNumber!.isNotEmpty) ? p.receiptNumber! : 'DP-${sale.id?.substring(0, 5).toUpperCase() ?? "N/A"}', style: const pw.TextStyle(fontSize: 6))),
                        pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(p.remarks ?? '-', style: pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic))),
                      ],
                    )),
                  ],
                ),
                pw.SizedBox(height: 10),
              ],

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('DOWN PAYMENT PAID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('Rs. ${sale.receivedDownPayment.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ],
              ),
              if (sale.receivedDownPayment < sale.downPayment) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('REMAINING DP:', style: pw.TextStyle(fontSize: 8, color: PdfColors.red900)),
                    pw.Text('Rs. ${(sale.downPayment - sale.receivedDownPayment).toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 8, color: PdfColors.red900, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
              pw.SizedBox(height: 10),
              _buildReceiptRow('Balance Price:', 'Rs. ${(sale.totalPrice - sale.receivedDownPayment).toStringAsFixed(0)}'),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text('Registration Number: ${sale.registrationNumber ?? "N/A"}', style: const pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Thank you for choosing Iconic Estate', style: const pw.TextStyle(fontSize: 7)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'DownPayment_Receipt_${sale.plotNumber}.pdf',
    );
  }

  /// Print a receipt for payment made to a Dealer (Commission)
  static Future<void> printDealerPaymentReceipt({
    required RealEstateSale sale,
    required double amountPaid,
    String? remarks,
    String companyName = 'Iconic Estate',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(companyName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('A Sign of Trust', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 5),
                    pw.Text('COMMISSION VOUCHER', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    pw.Text('(Dealer Payment)', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              _buildReceiptRow('Voucher No:', 'DC-${sale.id?.substring(0, 5).toUpperCase() ?? 'N/A'}'),
              _buildReceiptRow('Date:', DateFormat('dd MMM yyyy').format(DateTime.now())),
              pw.Divider(thickness: 0.5),
              _buildReceiptRow('Dealer Name:', sale.dealerName ?? 'N/A'),
              _buildReceiptRow('Project:', sale.projectName ?? 'N/A'),
              _buildReceiptRow('Plot No:', sale.plotNumber ?? 'N/A'),
              _buildReceiptRow('Reg. No:', sale.registrationNumber ?? 'N/A'),
              pw.Divider(thickness: 0.5),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('AMOUNT PAID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('Rs. ${amountPaid.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                ],
              ),
              pw.SizedBox(height: 5),
              if (remarks != null && remarks.isNotEmpty) ...[
                pw.Text('REMARKS: $remarks', style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 5),
              ],
              
              _buildReceiptRow('Total Commission:', 'Rs. ${sale.dealerCommission.toStringAsFixed(0)}'),
              _buildReceiptRow('Total Paid so far:', 'Rs. ${sale.dealerPaidAmount.toStringAsFixed(0)}'),
              _buildReceiptRow('Remaining Bal:', 'Rs. ${sale.dealerCommissionRemaining.toStringAsFixed(0)}'),
              
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [
                    pw.Divider(thickness: 0.5, color: PdfColors.grey),
                    pw.Text('Issued By', style: const pw.TextStyle(fontSize: 7)),
                  ]),
                  pw.Column(children: [
                    pw.Divider(thickness: 0.5, color: PdfColors.grey),
                    pw.Text('Receiver Sig.', style: const pw.TextStyle(fontSize: 7)),
                  ]),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Thank you for your partnership', style: const pw.TextStyle(fontSize: 7)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Dealer_Receipt_${sale.dealerName}.pdf',
    );
  }

  /// Print a receipt for payment made to a Landowner (Plot Share)
  static Future<void> printLandownerPaymentReceipt({
    required RealEstateSale sale,
    required double amountPaid,
    String? remarks,
    String companyName = 'Iconic Estate',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(companyName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('A Sign of Trust', style: const pw.TextStyle(fontSize: 8)),
                    pw.SizedBox(height: 5),
                    pw.Text('LANDOWNER PAYMENT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                    pw.Text('(Plot Share Payout)', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              _buildReceiptRow('Voucher No:', 'LP-${sale.id?.substring(0, 5).toUpperCase() ?? 'N/A'}'),
              _buildReceiptRow('Date:', DateFormat('dd MMM yyyy').format(DateTime.now())),
              pw.Divider(thickness: 0.5),
              _buildReceiptRow('Project:', sale.projectName ?? 'N/A'),
              _buildReceiptRow('Plot No:', sale.plotNumber ?? 'N/A'),
              _buildReceiptRow('Customer:', sale.customerName ?? 'N/A'),
              pw.Divider(thickness: 0.5),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('AMOUNT PAID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('Rs. ${amountPaid.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
                ],
              ),
              pw.SizedBox(height: 5),
              if (remarks != null && remarks.isNotEmpty) ...[
                pw.Text('REMARKS: $remarks', style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 5),
              ],
              
              _buildReceiptRow('Total Share:', 'Rs. ${sale.landownerTotalShare.toStringAsFixed(0)}'),
              _buildReceiptRow('Paid so far:', 'Rs. ${sale.landownerPaidAmount.toStringAsFixed(0)}'),
              _buildReceiptRow('Balance:', 'Rs. ${sale.landownerShareRemaining.toStringAsFixed(0)}'),
              
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [
                    pw.Divider(thickness: 0.5, color: PdfColors.grey),
                    pw.Text('Authorized Sig.', style: const pw.TextStyle(fontSize: 7)),
                  ]),
                  pw.Column(children: [
                    pw.Divider(thickness: 0.5, color: PdfColors.grey),
                    pw.Text('Landowner Sig.', style: const pw.TextStyle(fontSize: 7)),
                  ]),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Document generated by Management System', style: const pw.TextStyle(fontSize: 7)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Landowner_Payment_${sale.id?.substring(0, 5)}.pdf',
    );
  }

  static pw.Widget _buildReceiptRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text('$label ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildStatItem(String label, String value, {PdfColor? color}) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold, color: color ?? PdfColors.black)),
      ],
    );
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
          textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _buildCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 10, color: color ?? PdfColors.black),
          textAlign: pw.TextAlign.center),
    );
  }
}
