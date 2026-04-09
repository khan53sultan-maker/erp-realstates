import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/real_estate/plot_table.dart';
import '../../widgets/real_estate/add_plot_dialog.dart';
import '../../../src/services/real_estate_ledger_export_service.dart';

class PlotPage extends StatefulWidget {
  const PlotPage({super.key});

  @override
  State<PlotPage> createState() => _PlotPageState();
}

class _PlotPageState extends State<PlotPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RealEstateProvider>().fetchPlots();
      context.read<RealEstateProvider>().fetchProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Consumer<RealEstateProvider>(
        builder: (context, provider, child) {
          final filteredPlots = provider.plots.where((plot) {
            final query = _searchQuery.toLowerCase();
            return plot.plotNumber.toLowerCase().contains(query) ||
                   (plot.projectName?.toLowerCase().contains(query) ?? false) ||
                   (plot.customerName?.toLowerCase().contains(query) ?? false);
          }).toList();

          // Calculate stats for Plot screen
          int totalPlots = provider.plots.length;
          int availablePlots = provider.plots.where((p) => p.status == 'AVAILABLE').length;
          int soldPlots = provider.plots.where((p) => p.status == 'SOLD').length;
          int reservedPlots = provider.plots.where((p) => p.status == 'RESERVED').length;
          double totalValue = provider.plots.fold(0, (sum, p) => sum + p.totalPrice);

          return Padding(
            padding: EdgeInsets.all(context.mainPadding),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),

                  // Summary Cards
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _summaryCard('TOTAL PLOTS', totalPlots.toDouble(), Colors.blue.shade800, Icons.grid_view_rounded, isCurrency: false),
                      _summaryCard('AVAILABLE', availablePlots.toDouble(), Colors.green.shade700, Icons.check_circle_outline, isCurrency: false),
                      _summaryCard('SOLD', soldPlots.toDouble(), Colors.red.shade700, Icons.shopping_cart_checkout, isCurrency: false),
                      _summaryCard('RESERVED', reservedPlots.toDouble(), Colors.orange.shade800, Icons.pending_actions_rounded, isCurrency: false),
                      _summaryCard('TOTAL INVENTORY VALUE', totalValue, Colors.indigo, Icons.account_balance_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SEARCH BAR
                  _buildSearchBar(),
                  const SizedBox(height: 20),

                  // Table Section
                  provider.isLoading && provider.plots.isEmpty
                      ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                      : PlotTable(filteredPlots: filteredPlots),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plot Management',
              style: TextStyle(
                fontSize: context.headingFontSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryMaroon,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track plot availability, pricing and ownership',
              style: TextStyle(
                fontSize: context.bodyFontSize,
                color: AppTheme.charcoalGray.withOpacity(0.7),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildExportButton(context),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddPlotDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Plot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                foregroundColor: AppTheme.pureWhite,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.charcoalGray, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search by Plot #, Project or Customer name...',
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.normal),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryMaroon),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey), onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                })
              : null,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, double value, Color color, IconData icon, {bool isCurrency = true}) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade600, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  isCurrency ? 'Rs.${value.toStringAsFixed(0)}' : value.toInt().toString(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.charcoalGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) async {
        if (_isExporting) return;
        setState(() => _isExporting = true);

        final provider = context.read<RealEstateProvider>();
        final isPdf = val == 'pdf';
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Generating plots report...'), duration: Duration(seconds: 2)),
        );

        final path = await provider.exportReport(
          isPdf: isPdf, 
          reportType: 'plots',
          // Optionally pass projectId if you want filtered export
        );

        if (path != null && context.mounted) {
           ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Report exported successfully!'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () => RealEstateLedgerExportService.openFile(path),
              ),
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to export. Please try again.'), backgroundColor: Colors.red),
          );
        }
        
        if (mounted) {
          setState(() => _isExporting = false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: const [
            Icon(Icons.download, color: AppTheme.primaryMaroon, size: 20),
            SizedBox(width: 8),
            Text('Export List', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf, color: Colors.red), title: Text('Export PDF'))),
        const PopupMenuItem(value: 'excel', child: ListTile(leading: Icon(Icons.table_chart, color: Colors.green), title: Text('Export Excel'))),
      ],
    );
  }

  void _showAddPlotDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddPlotDialog(),
    );
  }
}
