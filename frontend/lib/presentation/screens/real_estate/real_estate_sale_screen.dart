import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../widgets/real_estate/sale_table.dart';
import '../../widgets/real_estate/add_sale_dialog.dart';
import '../../../src/services/real_estate_ledger_export_service.dart';
import '../../../main.dart';

class RealEstateSalePage extends StatefulWidget {
  const RealEstateSalePage({super.key});

  @override
  State<RealEstateSalePage> createState() => _RealEstateSalePageState();
}

class _RealEstateSalePageState extends State<RealEstateSalePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedProjectId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RealEstateProvider>().fetchSales();
      context.read<RealEstateProvider>().fetchPlots(status: 'AVAILABLE');
      context.read<RealEstateProvider>().fetchDealers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider>().currentUser?.role ?? 'ADMIN';
    final isManager = role == 'MANAGER';

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Consumer<RealEstateProvider>(
        builder: (context, provider, child) {
          final filteredSales = provider.sales.where((sale) {
            final query = _searchQuery.toLowerCase();
            final matchesSearch = (sale.customerName?.toLowerCase().contains(query) ?? false) ||
                (sale.plotNumber?.toLowerCase().contains(query) ?? false) ||
                (sale.registrationNumber?.toLowerCase().contains(query) ?? false) ||
                (sale.dealerName?.toLowerCase().contains(query) ?? false);
            
            final matchesProject = _selectedProjectId == null || sale.projectId == _selectedProjectId;
            
            return matchesSearch && matchesProject;
          }).toList();

          double totalSales = 0;
          double totalReceived = 0;
          double totalRemaining = 0;
          double totalCoComm = 0;
          double coCommRecv = 0;
          double totalDealerComm = 0;
          double dealerCommPaid = 0;

          for (var sale in filteredSales) {
            totalSales += sale.totalPrice;
            totalReceived += sale.totalReceived;
            totalRemaining += sale.currentBalance;
            totalCoComm += sale.landownerCommission;
            coCommRecv += sale.landownerCommissionReceived;
            totalDealerComm += sale.dealerCommission;
            dealerCommPaid += sale.dealerPaidAmount;
          }

          return Padding(
            padding: EdgeInsets.all(context.mainPadding),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12),
                  
                  // Summary Cards Section
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _summaryCard('TOTAL SALES VALUE', totalSales, Colors.blue.shade800, Icons.monetization_on_rounded),
                      _summaryCard('TOTAL RECEIVED', totalReceived, Colors.green.shade700, Icons.account_balance_wallet_rounded),
                      _summaryCard('TOTAL REMAINING', totalRemaining, Colors.red.shade700, Icons.pending_actions_rounded),
                      if (!isManager) _summaryCard('NET PROFIT', coCommRecv - dealerCommPaid, Colors.indigo, Icons.trending_up),
                      if (!isManager) _summaryCard('COMPANY COMMISSION', totalCoComm, Colors.purple.shade700, Icons.business_center),
                      if (!isManager) _summaryCard('COMM. RECEIVED', coCommRecv, Colors.teal, Icons.download_done),
                      _summaryCard('DEALER COMMISSIONS', totalDealerComm, Colors.orange.shade800, Icons.groups_rounded),
                      _summaryCard('DEALER REMAINING', totalDealerComm - dealerCommPaid, Colors.deepOrange, Icons.history),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filters & Search
                  _buildFiltersBar(provider),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 20),

                  // Table Section
                  provider.isLoading && provider.sales.isEmpty
                      ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                      : SaleTable(sales: filteredSales),
                  
                  const SizedBox(height: 40), // Bottom padding for comfortable scrolling
                ],
              ),
            ),
          );
        },
      ),
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
          hintText: 'Search by Customer, Plot #, Reg # or Dealer...',
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.normal),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryMaroon),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
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

  Widget _buildExportButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) async {
        if (_isExporting) return;
        setState(() => _isExporting = true);

        final provider = context.read<RealEstateProvider>();
        final type = val.split('_')[0]; // 'commission' or 'sales'
        final isPdf = val.split('_')[1] == 'pdf';
        
        try {
          HiBlankitsApp.scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text('Preparing ${type.toUpperCase()} report...', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: AppTheme.primaryMaroon,
            ),
          );

          final path = await provider.exportReport(
            isPdf: isPdf, 
            reportType: type,
            projectId: _selectedProjectId,
          );

          if (path != null && mounted) {
            HiBlankitsApp.scaffoldMessengerKey.currentState?.clearSnackBars();
            HiBlankitsApp.scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text('${type.toUpperCase()} report saved successfully!'),
                backgroundColor: Colors.green.shade700,
                action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
              ),
            );
          } else if (mounted) {
            HiBlankitsApp.scaffoldMessengerKey.currentState?.clearSnackBars();
            HiBlankitsApp.scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text('Failed to export ${type} report'), backgroundColor: Colors.red),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isExporting = false);
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'sales_pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf, color: Colors.indigo), title: Text('Sales Report (PDF)'))),
        const PopupMenuItem(value: 'sales_excel', child: ListTile(leading: Icon(Icons.table_chart, color: Colors.indigo), title: Text('Sales Report (Excel)'))),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'commission_pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf, color: Colors.green), title: Text('Commission Report (PDF)'))),
        const PopupMenuItem(value: 'commission_excel', child: ListTile(leading: Icon(Icons.table_chart, color: Colors.green), title: Text('Commission Report (Excel)'))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryMaroon.withOpacity(0.05),
          border: Border.all(color: AppTheme.primaryMaroon),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.summarize_rounded, color: AppTheme.primaryMaroon, size: 20),
            const SizedBox(width: 8),
            const Text('Export Reports', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold)),
            const Icon(Icons.arrow_drop_down, color: AppTheme.primaryMaroon),
          ],
        ),
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
              'Real Estate Sales',
              style: TextStyle(
                fontSize: context.headingFontSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryMaroon,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage plot sales and commissions',
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
              onPressed: () => _showAddSaleDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Sale'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                foregroundColor: AppTheme.pureWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersBar(RealEstateProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.business_outlined, color: AppTheme.primaryMaroon, size: 18),
              const SizedBox(width: 8),
              Text(
                'Select Project to View Records:', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 13)
              ),
            ],
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(), // High-end bouncy scrolling
            itemCount: provider.projects.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final project = isAll ? null : provider.projects[index - 1];
              final isSelected = isAll ? _selectedProjectId == null : _selectedProjectId == project?.id;
              
              return Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 5),
                child: InkWell(
                  onTap: () => setState(() => _selectedProjectId = project?.id),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryMaroon : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryMaroon : Colors.grey.shade300,
                        width: 2
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected ? AppTheme.primaryMaroon.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3)
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        isAll ? 'ALL BLOCKS' : project!.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.charcoalGray,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.5
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, double value, Color color, IconData icon) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
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
                  'Rs.${value.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.charcoalGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSaleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddSaleDialog(),
    );
  }
}
