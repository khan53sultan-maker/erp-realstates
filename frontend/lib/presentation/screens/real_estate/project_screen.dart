import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/real_estate/project_table.dart';
import '../../widgets/real_estate/add_project_dialog.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RealEstateProvider>();
      provider.fetchProjects();
      provider.fetchPlots();
      provider.fetchSales();
      provider.fetchInstallments();
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
          final filteredProjects = provider.projects.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                   p.location.toLowerCase().contains(query) ||
                   p.landownerName.toLowerCase().contains(query);
          }).toList();

          double totalSaleValue = 0;
          double totalReceived = 0;
          for (var sale in provider.sales) {
            totalSaleValue += sale.totalPrice;
            totalReceived += sale.totalReceived;
          }
          double totalRemaining = totalSaleValue - totalReceived;

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
                      _summaryCard('TOTAL PROJECTS', provider.projects.length.toDouble(), Colors.blue.shade800, Icons.business_center_rounded, isCurrency: false),
                      _summaryCard('TOTAL SALE VALUE', totalSaleValue, Colors.indigo, Icons.monetization_on_rounded),
                      _summaryCard('TOTAL RECEIVED', totalReceived, Colors.green.shade700, Icons.account_balance_wallet_rounded),
                      _summaryCard('TOTAL REMAINING', totalRemaining, Colors.red.shade700, Icons.pending_actions_rounded),
                      _summaryCard('LANDOWNERS', provider.projects.map((e) => e.landownerName).toSet().length.toDouble(), Colors.orange.shade800, Icons.people_rounded, isCurrency: false),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // SEARCH BAR
                  _buildSearchBar(),
                  const SizedBox(height: 20),

                  // Table Section
                  provider.isLoading && provider.projects.isEmpty
                      ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                      : ProjectTable(projects: filteredProjects),
                  
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
              'Project Management',
              style: TextStyle(
                fontSize: context.headingFontSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryMaroon,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage real estate projects and land distributions',
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
              onPressed: () => _showAddProjectDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Project'),
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
          hintText: 'Search by Project Name, Location or Landowner...',
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
    return InkWell(
      onTap: () {
        // Add export logic here if needed
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: const [
            // Icon(Icons.download, color: AppTheme.primaryMaroon, size: 20),
            // SizedBox(width: 8),
            Text('Export Projects', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddProjectDialog(),
    );
  }
}
