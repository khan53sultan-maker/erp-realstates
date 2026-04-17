import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/models/real_estate/real_estate_finance_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart';
class RealEstateFinancialReportScreen extends StatefulWidget {
  const RealEstateFinancialReportScreen({super.key});

  @override
  State<RealEstateFinancialReportScreen> createState() => _RealEstateFinancialReportScreenState();
}

class _RealEstateFinancialReportScreenState extends State<RealEstateFinancialReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'all_time';
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  void _fetchData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RealEstateProvider>().fetchReportSummary(
        period: _selectedPeriod,
        projectId: _selectedProjectId,
      );
      context.read<RealEstateProvider>().fetchProjectProfitReport();
      context.read<RealEstateProvider>().fetchProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: const Text('Financial Reports'),
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: AppTheme.pureWhite,
              floating: true,
              pinned: true,
              forceElevated: innerBoxIsScrolled,
              actions: [
                IconButton(
                  icon: const Icon(Icons.download_for_offline_rounded, size: 28, color: AppTheme.accentGold),
                  tooltip: 'Export Reports',
                  onPressed: () => _showExportDialog(context),
                ),
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Period Summary'),
                  Tab(text: 'Project-wise Profit'),
                ],
                indicatorColor: AppTheme.accentGold,
                labelColor: AppTheme.pureWhite,
                unselectedLabelColor: AppTheme.pureWhite.withOpacity(0.5),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPeriodSummaryTab(),
            _buildProjectProfitTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSummaryTab() {
    return Consumer<RealEstateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.reportSummary == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = provider.reportSummary;
        if (summary == null) return const Center(child: Text('No data found'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilters(),
              const SizedBox(height: 24),
              _buildSummaryHeader(summary),
              const SizedBox(height: 24),
              // ResponsiveBreakpoints.responsive(
              //   context,
              //   tablet: Column(
              //     children: [
              //       _buildBreakdownCard('Income Breakdown', summary.incomeBreakdown, Colors.green, 'income_type'),
              //       const SizedBox(height: 16),
              //       _buildBreakdownCard('Expense Breakdown', summary.expenseBreakdown, Colors.red, 'category'),
              //     ],
              //   ),
              //   small: Row(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Expanded(child: _buildBreakdownCard('Income Breakdown', summary.incomeBreakdown, Colors.green, 'income_type')),
              //       const SizedBox(width: 16),
              //       Expanded(child: _buildBreakdownCard('Expense Breakdown', summary.expenseBreakdown, Colors.red, 'category')),
              //     ],
              //   ),
              //   medium: Row(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Expanded(child: _buildBreakdownCard('Income Breakdown', summary.incomeBreakdown, Colors.green, 'income_type')),
              //       const SizedBox(width: 16),
              //       Expanded(child: _buildBreakdownCard('Expense Breakdown', summary.expenseBreakdown, Colors.red, 'category')),
              //     ],
              //   ),
              //   large: Row(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Expanded(child: _buildBreakdownCard('Income Breakdown', summary.incomeBreakdown, Colors.green, 'income_type')),
              //       const SizedBox(width: 16),
              //       Expanded(child: _buildBreakdownCard('Expense Breakdown', summary.expenseBreakdown, Colors.red, 'category')),
              //     ],
              //   ),
              //   ultrawide: Row(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Expanded(child: _buildBreakdownCard('Income Breakdown', summary.incomeBreakdown, Colors.green, 'income_type')),
              //       const SizedBox(width: 16),
              //       Expanded(child: _buildBreakdownCard('Expense Breakdown', summary.expenseBreakdown, Colors.red, 'category')),
              //     ],
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedPeriod,
                decoration: const InputDecoration(labelText: 'Report Period', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily Summary')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly (7 Days)')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly (This Month)')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly (Jan-Dec)')),
                  DropdownMenuItem(value: 'all_time', child: Text('All Time (Total)')),
                ],
                onChanged: (v) {
                  setState(() => _selectedPeriod = v!);
                  _fetchData();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Consumer<RealEstateProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<String?>(
                    value: _selectedProjectId,
                    decoration: const InputDecoration(labelText: 'Project (Optional)', border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Projects')),
                      ...provider.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedProjectId = v);
                      _fetchData();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(FinancialSummary summary) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatBox('Total Income', 'Rs. ${summary.totalIncome.toStringAsFixed(0)}', Icons.arrow_upward, Colors.green),
        _buildStatBox('Total Expense', 'Rs. ${summary.totalExpense.toStringAsFixed(0)}', Icons.arrow_downward, Colors.red),
        _buildStatBox('Net Profit', 'Rs. ${summary.netProfit.toStringAsFixed(0)}', Icons.account_balance_wallet, AppTheme.primaryMaroon),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.charcoalGray)),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(String title, List<dynamic> breakdown, Color color, String key) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.charcoalGray)),
            const Divider(),
            if (breakdown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No entries for this period')),
              )
            else
              ...breakdown.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatTypeLabel(item[key].toString()), style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('Rs. ${double.parse(item['total'].toString()).toStringAsFixed(0)}', 
                        style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _formatTypeLabel(String label) {
    return label.replaceAll('_', ' ').toLowerCase().split(' ').map((s) => s[0].toUpperCase() + s.substring(1)).join(' ');
  }

  Widget _buildProjectProfitTab() {
    return Consumer<RealEstateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.projectProfitReport.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final report = provider.projectProfitReport;
        if (report.isEmpty) return const Center(child: Text('No projects found'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Project-wise Profitability', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.charcoalGray)),
              const SizedBox(height: 16),
              ...report.map((item) => _buildProjectStatCard(item)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectStatCard(dynamic item) {
    final profit = double.parse(item['profit'].toString());
    final isProfitable = profit >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['project_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryMaroon)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isProfitable ? Colors.green : Colors.red).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isProfitable ? 'PROFITABLE' : 'LOSS',
                    style: TextStyle(color: isProfitable ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                _buildProjectMiniStat('Income', 'Rs. ${double.parse(item['total_income'].toString()).toStringAsFixed(0)}', Colors.green),
                _buildProjectMiniStat('Expense', 'Rs. ${double.parse(item['total_expense'].toString()).toStringAsFixed(0)}', Colors.red),
                _buildProjectMiniStat('Net Profit', 'Rs. ${profit.toStringAsFixed(0)}', profit >= 0 ? Colors.green : Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RealEstateExportDialog(),
    );
  }
}

class RealEstateExportDialog extends StatefulWidget {
  const RealEstateExportDialog({super.key});

  @override
  State<RealEstateExportDialog> createState() => _RealEstateExportDialogState();
}

class _RealEstateExportDialogState extends State<RealEstateExportDialog> {
  String _reportType = 'sales';
  String _format = 'pdf';
  String? _selectedProjectId;
  String? _selectedDealerId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  final Map<String, String> _reportTypes = {
    'sales': 'Detailed Sales Report',
    'commission': 'Company Brokerage Report',
    'dealer_commission': 'Dealer Commission Ledger',
    'landowner_payout': 'Landowner (Malik) Share Ledger',
    'client_payment': 'Client Payment History',
    'profit_loss': 'Overall Profit & Loss',
    'cash_flow': 'Daily Cash Flow',
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RealEstateProvider>();
    
    return AlertDialog(
      backgroundColor: AppTheme.creamWhite,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Icon(Icons.summarize, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
          const SizedBox(width: 12),
          const Text('Export Report', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMaroon)),
        ],
      ),
      content: DefaultTextStyle(
        style: TextStyle(color: Colors.black, fontSize: context.bodyFontSize, fontFamily: 'Inter'),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Report Type:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: _reportType,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                items: _reportTypes.entries.map((e) => DropdownMenuItem(
                  value: e.key, 
                  child: Text(e.value, style: const TextStyle(color: Colors.black))
                )).toList(),
                onChanged: (v) => setState(() => _reportType = v!),
              ),
              const SizedBox(height: 16),
              const Text('Format:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      activeColor: AppTheme.primaryMaroon,
                      title: const Text('PDF', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      value: 'pdf',
                      groupValue: _format,
                      onChanged: (v) => setState(() => _format = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      activeColor: AppTheme.primaryMaroon,
                      title: const Text('Excel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      value: 'excel',
                      groupValue: _format,
                      onChanged: (v) => setState(() => _format = v!),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.grey),
              const Text('Filters (Optional):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _selectedProjectId,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Project', 
                  labelStyle: TextStyle(color: AppTheme.primaryMaroon.withOpacity(0.7)),
                  border: const OutlineInputBorder()
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Projects', style: TextStyle(color: Colors.black))),
                  ...provider.projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, style: const TextStyle(color: Colors.black)))),
                ],
                onChanged: (v) => setState(() => _selectedProjectId = v),
              ),
              if (_reportType == 'dealer_commission') ...[
                const SizedBox(height: 12),
                // Removed persistent success display
                DropdownButtonFormField<String?>(
                  value: _selectedDealerId,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Dealer', 
                    labelStyle: TextStyle(color: AppTheme.primaryMaroon.withOpacity(0.7)),
                    border: const OutlineInputBorder()
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Dealers', style: TextStyle(color: Colors.black))),
                    ...provider.dealers.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name, style: const TextStyle(color: Colors.black)))),
                  ],
                  onChanged: (v) => setState(() => _selectedDealerId = v),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context, 
                          initialDate: DateTime.now(), 
                          firstDate: DateTime(2020), 
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primaryMaroon,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (d != null) setState(() => _startDate = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          _startDate == null ? 'Start Date' : DateFormat('yyyy-MM-dd').format(_startDate!),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context, 
                          initialDate: DateTime.now(), 
                          firstDate: DateTime(2020), 
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primaryMaroon,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (d != null) setState(() => _endDate = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          _endDate == null ? 'End Date' : DateFormat('yyyy-MM-dd').format(_endDate!),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMaroon, fontSize: 15))
        ),
        ElevatedButton(
          onPressed: _isExporting ? null : () async {
            final scaffoldMessenger = HiBlankitsApp.scaffoldMessengerKey.currentState;
            
            // Show preparing snackbar
            scaffoldMessenger?.clearSnackBars();
            scaffoldMessenger?.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text(AppLocalizations.of(context)!.generatingReport, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                backgroundColor: AppTheme.primaryMaroon,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );

            setState(() => _isExporting = true);
            final path = await provider.exportReport(
              isPdf: _format == 'pdf',
              reportType: _reportType,
              projectId: _selectedProjectId,
              dealerId: _selectedDealerId,
              startDate: _startDate,
              endDate: _endDate,
            );

            setState(() => _isExporting = false);
            scaffoldMessenger?.clearSnackBars();
            HiBlankitsApp.navigatorKey.currentState?.pop(); // Close dialog

            if (path != null) {
              scaffoldMessenger?.showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Report saved correctly at: $path',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green.shade700,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () => scaffoldMessenger?.hideCurrentSnackBar(),
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryMaroon, 
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isExporting 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
            : const Text('Export Now', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
