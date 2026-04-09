import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/models/real_estate/dealer_model.dart';
import 'add_dealer_dialog.dart';

class DealerTable extends StatefulWidget {
  final List<RealEstateDealer>? dealers;
  const DealerTable({super.key, this.dealers});

  @override
  State<DealerTable> createState() => _DealerTableState();
}

class _DealerTableState extends State<DealerTable> {
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
    return Consumer<RealEstateProvider>(
      builder: (context, provider, child) {
        final dealersToShow = widget.dealers ?? provider.dealers;

        if (dealersToShow.isEmpty) {
          return Center(child: Text('No dealers found', style: TextStyle(color: AppTheme.charcoalGray.withOpacity(0.5))));
        }

        const double totalTableWidth = 1100.0;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.primaryMaroon.withOpacity(0.8)]),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, color: AppTheme.accentGold, size: 20),
                    const SizedBox(width: 8),
                    const Text('Dealer Network', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w900, fontSize: 14)),
                  ],
                ),
              ),
              Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
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
                        width: totalTableWidth,
                        color: AppTheme.creamWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            _buildHeaderCell('Name', 150),
                            _buildHeaderCell('Type', 100),
                            _buildHeaderCell('Phone', 120),
                            _buildHeaderCell('Comm. %', 100),
                            _buildHeaderCell('Sales', 80),
                            _buildHeaderCell('Earned', 130),
                            _buildHeaderCell('Paid', 130),
                            _buildHeaderCell('Pending', 130),
                            _buildHeaderCell('Actions', 100),
                          ],
                        ),
                      ),
                      // Rows stack vertically
                      ...dealersToShow.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dealer = entry.value;

                        return Container(
                          width: totalTableWidth,
                          decoration: BoxDecoration(
                            color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.1),
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          child: Row(
                            children: [
                              _buildDataCell(dealer.name, 150, isBold: true),
                              SizedBox(width: 100, child: Center(child: _buildTypeChip(dealer.type))),
                              _buildDataCell(dealer.phone, 120),
                              _buildDataCell('${dealer.commissionPercentage}%', 100),
                              _buildDataCell(dealer.totalSalesCount.toString(), 80),
                              _buildDataCell('Rs.${dealer.totalCommissionEarned.toStringAsFixed(0)}', 130, isBold: true),
                              _buildDataCell('Rs.${dealer.paidAmount.toStringAsFixed(0)}', 130, color: Colors.green),
                              _buildDataCell('Rs.${dealer.pendingAmount.toStringAsFixed(0)}', 130, color: AppTheme.primaryMaroon, isBold: true),
                              SizedBox(
                                width: 100,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _actionBtn(Icons.edit_note_rounded, Colors.indigo, () => _handleEdit(context, dealer)),
                                    const SizedBox(width: 8),
                                    _actionBtn(Icons.delete_sweep_rounded, Colors.redAccent, () => _handleDelete(context, dealer)),
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

  Widget _buildHeaderCell(String label, double width) {
    return SizedBox(width: width, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Text(label, style: const TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.w900, fontSize: 13), textAlign: TextAlign.center)));
  }

  Widget _buildDataCell(String text, double width, {bool isBold = false, Color? color}) {
    return SizedBox(width: width, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: Text(text, style: TextStyle(color: color ?? AppTheme.charcoalGray, fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)));
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Icon(icon, color: color, size: 18)));
  }

  Widget _buildTypeChip(String type) {
    Color color;
    String label;
    switch (type) {
      case 'TEAM_MEMBER': color = Colors.blue; label = 'Member'; break;
      case 'SUB_AGENT': color = Colors.orange; label = 'Sub-agent'; break;
      default: color = Colors.green; label = 'Dealer';
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color, width: 1)), child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)));
  }

  void _handleEdit(BuildContext context, RealEstateDealer dealer) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AddDealerDialog(dealer: dealer));
  }

  void _handleDelete(BuildContext context, RealEstateDealer dealer) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirm'), content: const Text('Delete this dealer?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async { Navigator.pop(ctx); await context.read<RealEstateProvider>().deleteDealer(dealer.id!); }, child: const Text('Delete'))]));
  }
}
