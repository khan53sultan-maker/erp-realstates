import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/sales/sale_model.dart';
import '../utils/debug_helper.dart';

class PdfInvoiceService {
  static const String companyName = 'HI BLANKETS';
  static const String companyAddress = 'Block 10 DG Khan';
  static const List<String> companyPhones = ['03344891100', '03336461731'];
  
  // App Brand Colors
  static const PdfColor primaryGreen = PdfColor.fromInt(0xFF265D5E);
  static const PdfColor accentGold = PdfColor.fromInt(0xFFE6AF2E);

  /// Generate and save PDF invoice
  static Future<String> generateInvoicePdf(SaleModel sale) async {
    try {
      DebugHelper.printInfo('PdfInvoiceService', 'Generating PDF invoice for sale: ${sale.invoiceNumber}');

      // Create PDF document
      final pdf = pw.Document();

      // Load fonts (using default fonts for now, can be customized later)
      final regularFont = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      // Build PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildInvoiceInfo(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildItemsTable(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildTotalsSection(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildFooter(regularFont, boldFont),
            ];
          },
        ),
      );

      // Save PDF to file
      final fileName = 'Invoice_${sale.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      DebugHelper.printSuccess('PdfInvoiceService', 'PDF invoice saved to: $filePath');
      return filePath;
    } catch (e) {
      DebugHelper.printError('PdfInvoiceService', e);
      rethrow;
    }
  }

  /// Preview and print PDF invoice
  static Future<void> previewAndPrintInvoice(SaleModel sale) async {
    try {
      DebugHelper.printInfo('PdfInvoiceService', 'Opening PDF preview for sale: ${sale.invoiceNumber}');

      final pdf = pw.Document();

      // Load fonts
      final regularFont = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      // Build PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildInvoiceInfo(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildItemsTable(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildTotalsSection(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildFooter(regularFont, boldFont),
            ];
          },
        ),
      );

      // Show print preview
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Invoice_${sale.invoiceNumber}',
      );
    } catch (e) {
      DebugHelper.printError('PdfInvoiceService', e);
      rethrow;
    }
  }

  /// Share PDF invoice
  static Future<void> shareInvoice(SaleModel sale) async {
    try {
      DebugHelper.printInfo('PdfInvoiceService', 'Sharing PDF for sale: ${sale.invoiceNumber}');

      final pdf = pw.Document();
      final regularFont = pw.Font.helvetica();
      final boldFont = pw.Font.helveticaBold();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildHeader(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildInvoiceInfo(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildCustomerInfo(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildItemsTable(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildTotalsSection(sale, regularFont, boldFont),
              pw.SizedBox(height: 20),
              _buildFooter(regularFont, boldFont),
            ];
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Invoice_${sale.invoiceNumber}.pdf',
      );
    } catch (e) {
      DebugHelper.printError('PdfInvoiceService', e);
      rethrow;
    }
  }

  /// Build header section
  static pw.Widget _buildHeader(SaleModel sale, pw.Font regularFont, pw.Font boldFont) {
    return pw.Container(
      padding: pw.EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [primaryGreen, PdfColor.fromInt(0xFF007A4D)],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Center(
               child: pw.Text('HB', style: pw.TextStyle(color: primaryGreen, fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
          ),
          pw.SizedBox(width: 25),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                companyName,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  font: boldFont,
                  color: PdfColors.white,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                companyAddress,
                style: pw.TextStyle(fontSize: 11, font: regularFont, color: PdfColors.white),
              ),
              pw.Text(
                'Phone: ${companyPhones.join(', ')}',
                style: pw.TextStyle(fontSize: 11, font: regularFont, color: PdfColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build invoice information section
  static pw.Widget _buildInvoiceInfo(SaleModel sale, pw.Font regularFont, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: boldFont,
                  color: primaryGreen,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Invoice #: ${sale.invoiceNumber}',
                style: pw.TextStyle(fontSize: 14, font: boldFont),
              ),
              pw.Text(
                'Date: ${DateFormat('dd MMM yyyy').format(sale.dateOfSale)}',
                style: pw.TextStyle(fontSize: 12, font: regularFont),
              ),
              pw.Text(
                'Time: ${DateFormat('hh:mm a').format(sale.dateOfSale)}',
                style: pw.TextStyle(fontSize: 12, font: regularFont),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildStatusBadge(sale.status, regularFont, boldFont),
              pw.SizedBox(height: 8),
              pw.Text(
                'Payment: ${sale.paymentMethodDisplay}',
                style: pw.TextStyle(fontSize: 12, font: regularFont),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build customer information section
  static pw.Widget _buildCustomerInfo(SaleModel sale, pw.Font regularFont, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Client Information',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (sale.createdByName != null && sale.createdByName!.isNotEmpty) ...[
                      pw.Text(
                        'Seller Name: ${sale.createdByName}',
                        style: pw.TextStyle(fontSize: 12, font: regularFont),
                      ),
                      pw.SizedBox(height: 4),
                    ],
                    pw.Text(
                      '👤 Client: ${sale.customerName}',
                      style: pw.TextStyle(fontSize: 12, font: regularFont),
                    ),
                    if (sale.customerPhone.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Phone: ${sale.customerPhone}',
                        style: pw.TextStyle(fontSize: 12, font: regularFont),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build items table
  static pw.Widget _buildItemsTable(SaleModel sale, pw.Font regularFont, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Order Details',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            font: boldFont,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FixedColumnWidth(25),  // Sr#
            1: const pw.FlexColumnWidth(3),   // Product
            2: const pw.FixedColumnWidth(45), // Qty
            3: const pw.FixedColumnWidth(85), // Price
            4: const pw.FixedColumnWidth(95), // Total
          },
          children: [
            // Table header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: primaryGreen),
              children: [
                _buildTableHeaderCell('Sr#', boldFont, color: PdfColors.white),
                _buildTableHeaderCell('Product', boldFont, color: PdfColors.white),
                _buildTableHeaderCell('Qty', boldFont, color: PdfColors.white),
                _buildTableHeaderCell('Price', boldFont, color: PdfColors.white),
                _buildTableHeaderCell('Total', boldFont, color: PdfColors.white),
              ],
            ),
            // Table rows
            ...sale.saleItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final formatter = NumberFormat('#,###');
              return pw.TableRow(
                children: [
                  _buildTableCell('${index + 1}', align: pw.TextAlign.center),
                  _buildTableCell(item.productName),
                  _buildTableCell('${item.quantity}', align: pw.TextAlign.center),
                  _buildTableCell('Rs.${formatter.format(item.unitPrice)}', align: pw.TextAlign.right),
                  _buildTableCell('Rs.${formatter.format(item.lineTotal)}', align: pw.TextAlign.right),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  /// Build totals section
  static pw.Widget _buildTotalsSection(SaleModel sale, pw.Font regularFont, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Subtotal:',
                style: pw.TextStyle(fontSize: 10, font: regularFont),
              ),
              pw.Text(
                'Rs.${NumberFormat('#,###').format(sale.subtotal)}',
                style: pw.TextStyle(fontSize: 10, font: regularFont),
              ),
            ],
          ),
          if (sale.overallDiscount > 0) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Discount:',
                  style: pw.TextStyle(fontSize: 10, font: regularFont),
                ),
                pw.Text(
                  '-Rs.${NumberFormat('#,###').format(sale.overallDiscount)}',
                  style: pw.TextStyle(fontSize: 10, font: regularFont),
                ),
              ],
            ),
          ],
          if (sale.taxConfiguration.hasTaxes) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Tax (${sale.taxSummaryDisplay}):',
                  style: pw.TextStyle(fontSize: 10, font: regularFont),
                ),
                pw.Text(
                  'Rs.${NumberFormat('#,###').format(sale.taxAmount)}',
                  style: pw.TextStyle(fontSize: 10, font: regularFont),
                ),
              ],
            ),
          ],
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: primaryGreen,
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: accentGold, width: 1),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Grand Total:',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    font: boldFont,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'Rs.${NumberFormat('#,###').format(sale.grandTotal)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    font: boldFont,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          if (sale.amountPaid > 0) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Amount Paid:',
                  style: pw.TextStyle(fontSize: 10, font: regularFont),
                ),
                pw.Text(
                  'Rs.${sale.amountPaid.toStringAsFixed(0)}',
                  style: pw.TextStyle(fontSize: 10, font: regularFont),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Balance Due:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: boldFont,
                    color: sale.remainingAmount > 0 ? PdfColors.red800 : PdfColors.green800,
                  ),
                ),
                pw.Text(
                  'Rs.${sale.remainingAmount.toStringAsFixed(0)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    font: boldFont,
                    color: sale.remainingAmount > 0 ? PdfColors.red800 : PdfColors.green800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build footer section
  static pw.Widget _buildFooter(pw.Font regularFont, pw.Font boldFont) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 12),
        pw.Center(
          child: pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              font: boldFont,
              color: primaryGreen,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            'This is a computer-generated invoice and does not require a signature.',
            style: pw.TextStyle(fontSize: 10, font: regularFont),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, font: regularFont),
          ),
        ),
      ],
    );
  }

  /// Build table cell
  static pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  /// Build table header cell
  static pw.Widget _buildTableHeaderCell(String text, pw.Font boldFont, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          font: boldFont,
          fontSize: 12,
          color: color ?? PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Build status badge
  static pw.Widget _buildStatusBadge(String status, pw.Font regularFont, pw.Font boldFont) {
    PdfColor badgeColor;
    String displayText;

    switch (status.toUpperCase()) {
      case 'PAID':
      case 'DELIVERED':
        badgeColor = PdfColors.green800;
        displayText = 'PAID';
        break;
      case 'PARTIAL':
      case 'INVOICED':
        badgeColor = PdfColors.orange800;
        displayText = 'PARTIAL';
        break;
      case 'UNPAID':
      case 'DRAFT':
        badgeColor = PdfColors.red800;
        displayText = 'UNPAID';
        break;
      case 'CANCELLED':
        badgeColor = PdfColors.grey600;
        displayText = 'CANCELLED';
        break;
      default:
        badgeColor = PdfColors.grey600;
        displayText = status;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: badgeColor,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Text(
        displayText,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          font: boldFont,
        ),
      ),
    );
  }
}
