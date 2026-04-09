import 'package:url_launcher/url_launcher.dart';
import '../models/sales/sale_model.dart';
import 'package:intl/intl.dart';

class WhatsAppService {
  /// Send invoice details via WhatsApp
  static Future<void> sendInvoiceViaWhatsApp(SaleModel sale) async {
    final String phoneNumber = sale.customerPhone.trim();
    if (phoneNumber.isEmpty) {
      throw 'Customer phone number is missing';
    }

    // Format phone number: remove non-numeric chars and ensure it has country code
    // If it starts with 0, replace with +92 (assuming Pakistan as per company info)
    String formattedPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '92${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('92') && formattedPhone.length == 10) {
      formattedPhone = '92$formattedPhone';
    }

    final String message = _generateInvoiceMessage(sale);
    final Uri whatsappUrl = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  static String _generateInvoiceMessage(SaleModel sale) {
    final String dateStr = DateFormat('dd MMM yyyy').format(sale.dateOfSale);
    final String currencyFormat = NumberFormat('#,###').format(sale.grandTotal);
    
    StringBuffer buffer = StringBuffer();
    buffer.writeln('📜 *INVOICE: ${sale.invoiceNumber}*');
    buffer.writeln('📅 Date: $dateStr');
    buffer.writeln('👤 Client: ${sale.customerName}');
    buffer.writeln('--------------------------------');
    
    for (var item in sale.saleItems) {
      buffer.writeln('• ${item.productName} (x${item.quantity}) - Rs.${NumberFormat('#,###').format(item.lineTotal)}');
    }
    
    buffer.writeln('--------------------------------');
    buffer.writeln('💰 *Total Amount: Rs.$currencyFormat*');
    buffer.writeln('✅ Status: ${sale.statusDisplay}');
    buffer.writeln('--------------------------------');
    buffer.writeln('Thank you for shopping at *HI BLANKETS*!');
    buffer.writeln('Visit again! 😊');
    
    return buffer.toString();
  }
}
