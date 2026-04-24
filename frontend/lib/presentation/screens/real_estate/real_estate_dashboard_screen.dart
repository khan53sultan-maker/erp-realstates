import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../src/providers/real_estate_provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/models/real_estate/real_estate_finance_models.dart';

class RealEstateDashboardScreen extends StatefulWidget {
  const RealEstateDashboardScreen({super.key});

  @override
  State<RealEstateDashboardScreen> createState() => _RealEstateDashboardScreenState();
}

class _RealEstateDashboardScreenState extends State<RealEstateDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RealEstateProvider>().fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Consumer<RealEstateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.dashboardData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = provider.dashboardData;
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No dashboard data available'),
                  ElevatedButton(
                    onPressed: () => provider.fetchDashboardData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchDashboardData(),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(context.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: context.cardPadding),
                  _buildSummaryCards(context, data),
                  SizedBox(height: context.cardPadding),
                  // Moved up for visibility
                  _buildProjectSalesSection(context, data),
                  SizedBox(height: context.cardPadding * 2),
                  _buildChartsSection(context, data),
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
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real Estate Dashboard',
              style: TextStyle(
                fontSize: context.headingFontSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.charcoalGray,
              ),
            ),
            Text(
              'Real-time overview of your real estate business',
              style: TextStyle(
                fontSize: context.bodyFontSize,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildExportButton(context),
        SizedBox(width: context.smallPadding),
        ElevatedButton.icon(
          onPressed: () => context.read<RealEstateProvider>().fetchDashboardData(),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Statistics'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryMaroon,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildExportButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (val) async {
        final provider = context.read<RealEstateProvider>();
        String? path;
        
        if (val == 'pdf') {
          path = await provider.exportReport(isPdf: true);
        } else if (val == 'excel') {
          path = await provider.exportReport(isPdf: false);
        }

        if (path != null && mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Dashboard report saved successfully!',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to export dashboard report'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'pdf', child: ListTile(leading: Icon(Icons.picture_as_pdf, color: Colors.red), title: Text('Commission Report (PDF)'))),
        const PopupMenuItem(value: 'excel', child: ListTile(leading: Icon(Icons.table_chart, color: Colors.green), title: Text('Commission Report (Excel)'))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryMaroon),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.download, color: AppTheme.primaryMaroon, size: 20),
            const SizedBox(width: 8),
            Text('Export Reports', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, RealEstateDashboardData data) {
    final cur = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    // Check if user is MANAGER to hide profit/loss info
    final role = context.read<AuthProvider>().currentUser?.role ?? 'ADMIN';
    final isManager = role == 'MANAGER';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Financial Metrics - 2 Columns to ensure wrapping
        Text('Financial Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: isMobile ? 1 : 2, // 2 columns for desktop, 1 for mobile
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 3.5 : 4, 
          children: [
            _buildStatCard(context, 'Total Sale Value', cur.format(data.totalSalesAllTime), Icons.sell, Colors.blue),
            _buildStatCard(context, 'Total Received', cur.format(data.totalSalesAllTime - data.totalReceivables), Icons.payments, Colors.green),
            _buildStatCard(context, 'Total Remaining', cur.format(data.totalReceivables), Icons.account_balance, Colors.redAccent),
            if (!isManager) _buildStatCard(context, 'Net Profit', cur.format(data.netProfit), Icons.trending_up, Colors.indigo),
          ],
        ),
        
        const SizedBox(height: 24),
        Text('Operational Stats', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 12),
        
        // Secondary Metrics in a standard grid
        GridView.count(
          crossAxisCount: context.statsCardColumns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: context.cardPadding,
          mainAxisSpacing: context.cardPadding,
          childAspectRatio: 2.8,
          children: [
            if (!isManager) _buildStatCard(context, 'Today\'s Income', cur.format(data.today['income'] ?? 0), Icons.input, Colors.teal),
            if (!isManager) _buildStatCard(context, 'Today\'s Expenses', cur.format(data.today['expense'] ?? 0), Icons.output, Colors.red),
            _buildStatCard(context, 'Commission Received', cur.format(data.totalCommissionReceived), Icons.account_balance_wallet, Colors.blueAccent),
            _buildStatCard(context, 'Commission Paid', cur.format(data.totalCommissionPaid), Icons.money_off, Colors.orange),
            _buildStatCard(context, 'Available Plots', '${data.availablePlots}', Icons.map, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding / 1.5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Icon(icon, color: color, size: context.iconSize('medium')),
          ),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.subtitleFontSize,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.charcoalGray,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, RealEstateDashboardData data) {
    final role = context.read<AuthProvider>().currentUser?.role ?? 'ADMIN';
    final isManager = role == 'MANAGER';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildMonthlySalesChart(context, data.charts['monthly_sales'] ?? []),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              flex: 1,
              child: _buildDealerPerformanceChart(context, data.charts['dealer_performance'] ?? []),
            ),
          ],
        ),
        if (!isManager) ...[
          SizedBox(height: context.cardPadding * 2),
          _buildIncomeVsExpenseChart(
            context,
            data.charts['monthly_income'] ?? [],
            data.charts['monthly_expense'] ?? [],
          ),
        ],
      ],
    );
  }

  Widget _buildMonthlySalesChart(BuildContext context, List<dynamic> sales) {
    return Container(
      height: 35.h,
      padding: EdgeInsets.all(context.cardPadding),
      decoration: _chartDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartTitle('Monthly Sales Trend'),
          SizedBox(height: context.cardPadding),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMax(sales, 'total') * 1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() < sales.length) {
                          final date = DateTime.parse(sales[val.toInt()]['month']);
                          return Text(DateFormat('MMM').format(date));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(sales.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: double.tryParse((sales[index]['total'] ?? 0).toString()) ?? 0,
                        color: AppTheme.primaryMaroon,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerPerformanceChart(BuildContext context, List<dynamic> performance) {
    return Container(
      height: 35.h,
      padding: EdgeInsets.all(context.cardPadding),
      decoration: _chartDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartTitle('Top Dealers Performance'),
          SizedBox(height: context.cardPadding),
          Expanded(
            child: performance.isEmpty 
              ? const Center(child: Text('No dealer data'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMax(performance, 'sales_val') * 1.2,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            if (val.toInt() < performance.length) {
                              final name = performance[val.toInt()]['name'] as String;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(name.length > 5 ? name.substring(0, 5) : name, style: const TextStyle(fontSize: 10)),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(performance.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: double.tryParse((performance[index]['sales_val'] ?? 0).toString()) ?? 0,
                            color: Colors.blueAccent,
                            width: 15,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeVsExpenseChart(BuildContext context, List<dynamic> income, List<dynamic> expense) {
    return Container(
      height: 40.h,
      padding: EdgeInsets.all(context.cardPadding),
      decoration: _chartDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chartTitle('Income vs Expense Trend'),
              const Spacer(),
              _legendItem('Income', Colors.green),
              SizedBox(width: context.cardPadding),
              _legendItem('Expense', Colors.red),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Expanded(
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(enabled: true),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        // Logic to find corresponding month tag
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 45)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getSpots(income),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: _getSpots(expense),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.charcoalGray,
      ),
    );
  }

  BoxDecoration _chartDecoration(BuildContext context) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(context.borderRadius()),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProjectSalesSection(BuildContext context, RealEstateDashboardData data) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    
    if (data.projectSales.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(context.cardPadding),
          child: Column(
            children: [
              _chartTitle('Project-wise Sales Distribution'),
              const SizedBox(height: 20),
              const Center(child: Text('No project sales recorded yet', style: TextStyle(color: Colors.black, fontSize: 16))),
            ],
          ),
        ),
      );
    }

    final projectSalesContent = [
      // Left Side: Pie Chart
      Expanded(
        flex: isMobile ? 0 : 1,
        child: Container(
          height: 350,
          padding: EdgeInsets.all(context.cardPadding),
          decoration: _chartDecoration(context),
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: data.projectSales.map((ps) {
                final value = double.tryParse((ps['total_sales'] ?? 0).toString()) ?? 0;
                final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
                final index = data.projectSales.indexOf(ps) % colors.length;
                
                return PieChartSectionData(
                  color: colors[index],
                  value: value <= 0 ? 0.1 : value,
                  title: '${ps['name']}\n${(value / (data.totalSalesAllTime > 0 ? data.totalSalesAllTime : 1) * 100).toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      if (isMobile) const SizedBox(height: 16) else SizedBox(width: context.cardPadding),
      // Right Side: Details Cards
      Expanded(
        flex: isMobile ? 0 : 2,
        child: Container(
          height: isMobile ? null : 350,
          child: ListView.builder(
            shrinkWrap: true,
            physics: isMobile ? const NeverScrollableScrollPhysics() : const ScrollPhysics(),
            itemCount: data.projectSales.length,
            itemBuilder: (context, index) {
              final ps = data.projectSales[index];
              final totalSales = double.tryParse((ps['total_sales'] ?? 0).toString()) ?? 0;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryMaroon,
                    child: Text((index + 1).toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(ps['name']?.toString() ?? 'N/A', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                  subtitle: Text('Sales Count: ${ps['sales_count'] ?? 0}', 
                    style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(NumberFormat.currency(symbol: 'Rs. ').format(totalSales),
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${(totalSales / (data.totalSalesAllTime > 0 ? data.totalSalesAllTime : 1) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Removed RAW DATA DEBUG text as requested
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _chartTitle('Project-wise Sales Distribution'),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primaryMaroon),
              onPressed: () => context.read<RealEstateProvider>().fetchDashboardData(),
            ),
          ],
        ),
        SizedBox(height: context.smallPadding),
        if (isMobile)
          Column(children: projectSalesContent)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: projectSalesContent,
          ),
      ],
    );
  }

  double _getMax(List<dynamic> list, String key) {
    if (list.isEmpty) return 1000;
    double max = 0;
    for (var item in list) {
      double val = double.tryParse((item[key] ?? 0).toString()) ?? 0;
      if (val > max) max = val;
    }
    return max == 0 ? 1000 : max;
  }

  List<FlSpot> _getSpots(List<dynamic> data) {
    return List.generate(data.length, (index) {
      return FlSpot(index.toDouble(), double.tryParse((data[index]['total'] ?? 0).toString()) ?? 0);
    });
  }
}
