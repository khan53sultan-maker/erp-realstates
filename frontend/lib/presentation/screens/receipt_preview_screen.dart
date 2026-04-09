import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import '../../src/models/sales/sale_model.dart';
import '../../src/theme/app_theme.dart';
import '../../src/services/pdf_invoice_service.dart';
import 'package:printing/printing.dart';
import '../../src/services/whatsapp_service.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final SaleModel? sale;

  const ReceiptPreviewScreen({super.key, this.sale});

  @override
  Widget build(BuildContext context) {
    // Fallback data if no sale is provided
    final String invoiceNo = sale?.invoiceNumber ?? 'INV-2026-001';
    final String dateStr = sale != null 
        ? DateFormat('dd MMM yyyy').format(sale!.dateOfSale)
        : '07 Feb 2026';
    final String timeStr = sale != null 
        ? DateFormat('hh:mm a').format(sale!.dateOfSale)
        : '12:30 PM';
    final String customerName = sale?.customerName ?? 'Walk-in Customer';
    final String sellerName = sale?.createdByName ?? 'Admin User';
    
    final double subtotal = sale?.subtotal ?? 10700;
    final double tax = sale?.taxAmount ?? 0;
    final double discount = sale?.overallDiscount ?? 200;
    final double grandTotal = sale?.grandTotal ?? 10500;
    final String paymentMethod = sale?.paymentMethodDisplay ?? 'Cash';
    final String status = sale?.statusDisplay ?? 'Paid';
    final bool isPaid = sale?.status == 'PAID';

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(sale != null ? 'Invoice #$invoiceNo' : 'Premium Receipt Preview'),
        backgroundColor: AppTheme.primaryMaroon,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              if (sale != null) {
                PdfInvoiceService.previewAndPrintInvoice(sale!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No sale data to print")),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              if (sale != null) {
                PdfInvoiceService.shareInvoice(sale!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No sale data to share")),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: () async {
              if (sale != null) {
                try {
                  await WhatsAppService.sendInvoiceViaWhatsApp(sale!);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No sale data to send via WhatsApp")),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 85.w, // Slightly wider for better fit
            margin: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header section with App Brand Colors
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Actual Logo Asset
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/iconic_logo.png',
                          height: 70,
                          width: 70,
                          errorBuilder: (context, error, stackTrace) => CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.business, size: 40, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 25),
                      // Company Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Iconic Estate',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                                'A Sign of Trust',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Info Section
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoItem('Invoice No:', '#$invoiceNo'),
                          _infoItem('Date:', dateStr),
                          _infoItem('Time:', timeStr),
                        ],
                      ),
                      const Divider(height: 40, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoItem('Seller Name:', sellerName),
                          _infoItem('Customer Name:', customerName),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Item Table Header
                      Container(
                        decoration: const BoxDecoration(
                            color: AppTheme.primaryMaroon,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                        child: Row(
                          children: [
                            _tableCell('Item Name', flex: 4, isHeader: true),
                            _tableCell('Qty', flex: 1, isHeader: true, align: TextAlign.center),
                            _tableCell('Price', flex: 2, isHeader: true, align: TextAlign.right),
                            _tableCell('Total', flex: 2, isHeader: true, align: TextAlign.right),
                          ],
                        ),
                      ),

                      // Item Rows
                      if (sale != null && sale!.saleItems.isNotEmpty)
                        ...sale!.saleItems.map((item) => 
                          _buildItemRow(
                            item.productName, 
                            item.quantity.toString(), 
                            NumberFormat('#,###').format(item.unitPrice), 
                            NumberFormat('#,###').format(item.lineTotal)
                          )
                        ).toList()
                      else ...[
                        _buildItemRow('Sufi Cooking Oil 5L', '2', '2,450', '4,900'),
                        _buildItemRow('Basmati Rice Super 10kg', '1', '4,200', '4,200'),
                        _buildItemRow('Dal Chana (Premium) 1kg', '5', '320', '1,600'),
                      ],
                      
                      const SizedBox(height: 30),
                      const Divider(thickness: 1.5),

                      // Calculation Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 250,
                            child: Column(
                              children: [
                                _calcRow('Subtotal:', '${NumberFormat('#,###').format(subtotal)} PKR'),
                                if (tax > 0)
                                  _calcRow('Tax:', '${NumberFormat('#,###').format(tax)} PKR'),
                                if (discount > 0)
                                  _calcRow('Discount:', '${NumberFormat('#,###').format(discount)} PKR'),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryMaroon,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppTheme.accentGold.withOpacity(0.5), width: 1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Grand Total:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('${NumberFormat('#,###').format(grandTotal)} PKR', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                         _footerItem('Payment Method:', paymentMethod),
                         _footerItem('Status:', '$status ${isPaid ? '✓' : ''}', isSuccess: isPaid),
                        ],
                      ),

                      const SizedBox(height: 80),
                      const Text(
                        'Thank you for your business!',
                        style: TextStyle(
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryMaroon,
                        ),
                      ),
                      const Text('Visit Again :)', style: TextStyle(fontSize: 16)),
                      
                      const SizedBox(height: 60),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(width: 200, height: 1, color: Colors.blueGrey),
                                const SizedBox(height: 8),
                                const Text('Authorized Signature', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _tableCell(String text, {required int flex, bool isHeader = false, TextAlign align = TextAlign.start}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          color: isHeader ? Colors.white : Colors.black87,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildItemRow(String name, String qty, String price, String total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          _tableCell(name, flex: 4),
          _tableCell(qty, flex: 1, align: TextAlign.center),
          _tableCell(price, flex: 2, align: TextAlign.right),
          _tableCell(total, flex: 2, align: TextAlign.right),
        ],
      ),
    );
  }

  Widget _calcRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _footerItem(String label, String value, {bool isSuccess = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isSuccess ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}

