import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../src/models/real_estate/plot_model.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import 'add_plot_dialog.dart';

class PlotTable extends StatefulWidget {
  final List<RealEstatePlot>? filteredPlots;
  const PlotTable({super.key, this.filteredPlots});

  @override
  State<PlotTable> createState() => _PlotTableState();
}

class _PlotTableState extends State<PlotTable> {
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
        final plotsToShow = widget.filteredPlots ?? provider.plots;

        if (plotsToShow.isEmpty) {
          return Center(
            child: Text('No plots found', style: TextStyle(color: AppTheme.charcoalGray.withOpacity(0.5))),
          );
        }

        const double totalTableWidth = 1300.0; // Slightly increased for safety

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
                    const Icon(Icons.map_rounded, color: AppTheme.accentGold, size: 20),
                    const SizedBox(width: 8),
                    const Text('Plot Distribution', style: TextStyle(color: AppTheme.pureWhite, fontWeight: FontWeight.w900, fontSize: 14)),
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
                      Container(
                        width: totalTableWidth,
                        color: AppTheme.creamWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Row(
                          children: [
                            _buildHeaderCell('Plot #', 100),
                            _buildHeaderCell('Project', 180),
                            _buildHeaderCell('Size', 100),
                            _buildHeaderCell('Price', 150),
                            _buildHeaderCell('Status', 120),
                            _buildHeaderCell('Customer', 180),
                            _buildHeaderCell('Sale Date', 120),
                            _buildHeaderCell('Dealer', 150),
                            _buildHeaderCell('Actions', 180), 
                          ],
                        ),
                      ),
                      // Rows stack vertically, no internal vertical scroll
                      ...plotsToShow.asMap().entries.map((entry) {
                        final index = entry.key;
                        final plot = entry.value;
                        return Container(
                          width: totalTableWidth,
                          decoration: BoxDecoration(
                            color: index.isEven ? AppTheme.pureWhite : AppTheme.lightGray.withOpacity(0.1),
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          child: Row(
                            children: [
                              _buildDataCell(plot.plotNumber, 100, isBold: true),
                              _buildDataCell(plot.projectName ?? '-', 180),
                              _buildDataCell(plot.plotSize, 100),
                              _buildDataCell('Rs.${plot.totalPrice.toStringAsFixed(0)}', 150, isBold: true, color: AppTheme.primaryMaroon),
                              SizedBox(width: 120, child: Center(child: _buildStatusChip(plot.status))),
                              _buildDataCell(plot.customerName ?? '-', 180),
                              _buildDataCell(plot.saleDate ?? '-', 120),
                              _buildDataCell(plot.dealerName ?? '-', 150),
                              SizedBox(
                                width: 180,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _actionBtn(Icons.edit_note_rounded, Colors.indigo, () => _handleEdit(context, plot)),
                                    const SizedBox(width: 12),
                                    _actionBtn(Icons.delete_sweep_rounded, Colors.redAccent, () => _handleDelete(context, plot)),
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
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)));
  }

  Widget _buildStatusChip(String status) {
    Color color = status == 'AVAILABLE' ? Colors.green : (status == 'SOLD' ? Colors.red : Colors.orange);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color, width: 1)), child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)));
  }

  void _handleEdit(BuildContext context, RealEstatePlot plot) {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AddPlotDialog(plot: plot));
  }

  void _handleDelete(BuildContext context, RealEstatePlot plot) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirm'), content: const Text('Delete this plot?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: () async { Navigator.pop(ctx); await context.read<RealEstateProvider>().deletePlot(plot.id!); }, child: const Text('Delete'))]));
  }
}
