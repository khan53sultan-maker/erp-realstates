import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/models/real_estate/real_estate_sale_model.dart';
import '../../../src/models/real_estate/plot_model.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/providers/real_estate_provider.dart';
import 'installment_dialog.dart';
import 'add_sale_dialog.dart';
import 'partner_payout_dialog.dart';
import '../../../src/services/real_estate_ledger_export_service.dart';
import '../../../src/services/customer_service.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/models/customer/customer_model.dart';


class SaleTable extends StatefulWidget {
  final List<RealEstateSale> sales;

  const SaleTable({super.key, required this.sales});

  @override
  State<SaleTable> createState() => _SaleTableState();
}

class _SaleTableState extends State<SaleTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  bool _isExporting = false;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RealEstateProvider>(
      builder: (context, provider, child) {
        final salesList = widget.sales;
        final allPlots = provider.plots;
        final userRole = context.read<AuthProvider>().currentUser?.role ?? 'ADMIN';
        final isManager = userRole == 'MANAGER';
        final double totalTableWidth = isManager ? 1800.0 : 3326.0;

        if (salesList.isEmpty) {
          return Center(
            child: Text(
              'No sales found',
              style: TextStyle(color: AppTheme.charcoalGray.withOpacity(0.5)),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(context.borderRadius()),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Gradient
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryMaroon, AppTheme.primaryMaroon.withOpacity(0.8)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag_rounded, color: AppTheme.accentGold, size: context.iconSize('small')),
                    SizedBox(width: context.smallPadding),
                    Text(
                      'Sales Records',
                      style: TextStyle(
                        color: AppTheme.pureWhite,
                        fontWeight: FontWeight.w900,
                        fontSize: context.bodyFontSize,
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable Table Area (Horizontal ONLY)
              Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 8,
                radius: const Radius.circular(4),
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FIXED TABLE HEADER
                      Container(
                        width: 3326, 
                        color: AppTheme.creamWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            _buildFixedHeaderCell('S/N', 60),
                            _buildFixedHeaderCell('Date', 120),
                            _buildFixedHeaderCell('Client Name', 180),
                            _buildFixedHeaderCell('Reg #', 120),
                            _buildFixedHeaderCell('Plot #', 100),
                            _buildFixedHeaderCell('Marla', 80),
                            _buildFixedHeaderCell('Plot Price', 150),
                            _buildFixedHeaderCell('Received', 150),
                            _buildFixedHeaderCell('Remaining', 150),
                            if (!isManager) ...[
                              _buildFixedHeaderCell('Co. Comm', 150),
                              _buildFixedHeaderCell('Co. Recv', 150),
                            ],
                            _buildFixedHeaderCell('Sold By', 150),
                            _buildFixedHeaderCell('Req. Down', 150),
                            _buildFixedHeaderCell('Recv. Down', 150),
                            if (!isManager) ...[
                              _buildFixedHeaderCell('Dealer Comm', 150),
                              _buildFixedHeaderCell('Earned', 150),
                              _buildFixedHeaderCell('Dealer Paid', 150),
                              _buildFixedHeaderCell('Dealer Rem.', 150),
                              _buildFixedHeaderCell('L/O Share', 150),
                              _buildFixedHeaderCell('L/O Paid', 150),
                              _buildFixedHeaderCell('L/O Rem.', 150),
                            ],
                            _buildFixedHeaderCell('Status', 120),
                            _buildFixedHeaderCell('Actions', 280),
                          ],
                        ),
                      ),
                      // TABLE BODY (Rows stack vertically, they don't scroll internally)
                      ...salesList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final sale = entry.value;
                        return Container(
                          width: 3326,
                          decoration: BoxDecoration(
                            color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.2),
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          child: Row(
                            children: [
                              _buildFixedDataCell((index + 1).toString(), 60),
                              _buildFixedDataCell(sale.saleDate ?? '-', 120),
                              _buildFixedDataCell(sale.customerName ?? 'N/A', 180, isBold: true),
                              _buildFixedDataCell(sale.registrationNumber ?? '-', 120, isBold: true),
                              _buildFixedDataCell(sale.plotNumber ?? 'N/A', 100, isBold: true),
                              _buildFixedDataCell(sale.plotSize ?? '-', 80),
                              _buildFixedDataCell('Rs.${sale.totalPrice.toStringAsFixed(0)}', 150, isBold: true),
                              _buildFixedDataCell('Rs.${sale.totalReceived.toStringAsFixed(0)}', 150, color: Colors.green.shade700, hasIcon: true),
                              _buildFixedDataCell('Rs.${sale.currentBalance.toStringAsFixed(0)}', 150, color: Colors.redAccent, isBold: true),
                              if (!isManager) ...[
                                _buildFixedDataCell('Rs.${sale.landownerCommission.toStringAsFixed(0)}', 150, color: Colors.blue.shade900),
                                _buildFixedDataCell('Rs.${sale.landownerCommissionReceived.toStringAsFixed(0)}', 150, color: Colors.blue.shade700, hasIcon: true),
                              ],
                              _buildFixedDataCell(sale.dealerName ?? '-', 150),
                              _buildFixedDataCell('Rs.${sale.downPayment.toStringAsFixed(0)}', 150),
                              _buildFixedDataCell('Rs.${sale.receivedDownPayment.toStringAsFixed(0)}', 150, color: Colors.green.shade900),
                              if (!isManager) ...[
                                _buildFixedDataCell('Rs.${sale.dealerCommission.toStringAsFixed(0)}', 150, color: Colors.orange.shade900),
                                _buildFixedDataCell('Rs.${sale.currentDealerCommission.toStringAsFixed(0)}', 150, color: Colors.deepOrange, isBold: true),
                                _buildFixedDataCell('Rs.${sale.dealerPaidAmount.toStringAsFixed(0)}', 150, color: Colors.green, hasIcon: true),
                                _buildFixedDataCell('Rs.${sale.dealerCommissionRemaining.toStringAsFixed(0)}', 150, color: Colors.red),
                                _buildFixedDataCell('Rs.${sale.landownerTotalShare.toStringAsFixed(0)}', 150, color: Colors.purple.shade900),
                                _buildFixedDataCell('Rs.${sale.landownerPaidAmount.toStringAsFixed(0)}', 150, color: Colors.purple.shade700, hasIcon: true),
                                _buildFixedDataCell('Rs.${sale.landownerShareRemaining.toStringAsFixed(0)}', 150, color: Colors.red.shade900, isBold: true),
                              ],
                              SizedBox(
                                width: 120,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: _getStatusColor(sale.commissionStatus).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Text(sale.commissionStatus, style: TextStyle(color: _getStatusColor(sale.commissionStatus), fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                ),
                              ),
                              SizedBox(
                                width: 280,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildActionButton(
                                      context, 
                                      icon: Icons.receipt_long_rounded, 
                                      color: AppTheme.primaryMaroon, 
                                      tooltip: 'Manage Installments',
                                      onTap: () => _viewInstallments(context, sale),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      context, 
                                      icon: Icons.file_download_outlined, 
                                      color: Colors.teal, 
                                      tooltip: 'Export Statement',
                                      onTap: () => _exportExecutiveStatement(context, sale),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      context, 
                                      icon: Icons.payments_rounded, 
                                      color: Colors.blueAccent, 
                                      tooltip: 'Partner Payouts Ledger',
                                      onTap: () => _viewPartnerPayouts(context, sale),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      context, 
                                      icon: Icons.edit_note_rounded, 
                                      color: Colors.indigo, 
                                      tooltip: 'Edit Sale',
                                      onTap: () => _handleEdit(context, sale),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      context, 
                                      icon: Icons.delete_outline, 
                                      color: Colors.red, 
                                      tooltip: 'Delete Sale',
                                      onTap: () => _handleDelete(context, sale),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedHeaderCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.primaryMaroon,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFixedDataCell(String text, double width, {bool isBold = false, Color? color, bool hasIcon = false}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: color ?? AppTheme.charcoalGray,
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasIcon) ...[
              const SizedBox(width: 4),
              Icon(Icons.receipt_long_rounded, size: 10, color: color?.withOpacity(0.5) ?? Colors.grey),
            ],
          ],
        ),
      ),
    );
  }

  TextStyle _rowStyle(BuildContext context, {bool isBold = false, Color? color}) {
    return TextStyle(
      color: color ?? AppTheme.charcoalGray,
      fontSize: context.captionFontSize,
      fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PAID': return Colors.green;
      case 'PARTIAL': return Colors.orange;
      case 'PENDING': return Colors.red;
      default: return AppTheme.charcoalGray;
    }
  }

  Future<void> _exportExecutiveStatement(BuildContext context, RealEstateSale sale) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryMaroon)),
    );

    try {
      final realEstateProvider = context.read<RealEstateProvider>();
      final path = await realEstateProvider.exportReport(
        isPdf: false,
        reportType: 'executive_statement',
        saleId: sale.id,
      );

      // Close loading dialog safely
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report exported successfully! Opening...'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => RealEstateLedgerExportService.openFile(path),
            ),
          ),
        );
        RealEstateLedgerExportService.openFile(path);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate report. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _viewInstallments(BuildContext context, RealEstateSale sale) {

    showDialog(
      context: context,
      builder: (context) => InstallmentDialog(sale: sale),
    );
  }

  void _viewPartnerPayouts(BuildContext context, RealEstateSale sale) {
    showDialog(
      context: context,
      builder: (context) => PartnerPayoutDialog(sale: sale),
    );
  }

  void _handleEdit(BuildContext context, RealEstateSale sale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddSaleDialog(sale: sale),
    );
  }

  void _handleDelete(BuildContext context, RealEstateSale sale) {
    if (sale.id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this sale for ${sale.customerName}? This will NOT automatically free the plot (mark it as AVAILABLE manually if needed).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<RealEstateProvider>().deleteSale(sale.id!);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sale deleted'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
