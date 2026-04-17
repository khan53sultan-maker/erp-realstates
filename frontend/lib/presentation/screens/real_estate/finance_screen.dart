import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/models/real_estate/real_estate_finance_models.dart';
import '../../../src/models/real_estate/project_model.dart';
import '../../../src/models/real_estate/real_estate_sale_model.dart';

class RealEstateFinanceScreen extends StatefulWidget {
  const RealEstateFinanceScreen({super.key});

  @override
  State<RealEstateFinanceScreen> createState() => _RealEstateFinanceScreenState();
}

class _RealEstateFinanceScreenState extends State<RealEstateFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RealEstateProvider>().fetchIncomes();
      context.read<RealEstateProvider>().fetchExpenses();
      context.read<RealEstateProvider>().fetchProjects();
      context.read<RealEstateProvider>().fetchSales(); // Loading sales for landowner payout
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
              title: const Text('Income & Expenses'),
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: AppTheme.pureWhite,
              floating: true,
              pinned: true,
              forceElevated: innerBoxIsScrolled,
              bottom: TabBar(
                controller: _tabController,
                tabs: const [Tab(text: 'Income List'), Tab(text: 'Expense List')],
                indicatorColor: AppTheme.accentGold,
                labelColor: AppTheme.pureWhite,
                unselectedLabelColor: AppTheme.pureWhite.withOpacity(0.5),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildOverallSummary(),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildIncomeTab(),
            _buildExpenseTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(_tabController.index == 0),
        backgroundColor: AppTheme.primaryMaroon,
        child: const Icon(Icons.add, color: AppTheme.pureWhite),
      ),
    );
  }

  Widget _buildOverallSummary() {
    final cur = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    return Consumer<RealEstateProvider>(
      builder: (context, provider, child) {
        final totalIncome = provider.incomes.fold(0.0, (sum, item) => sum + item.amount);
        final totalExpense = provider.expenses.fold(0.0, (sum, item) => sum + item.amount);
        final netProfit = totalIncome - totalExpense;

        final authProvider = context.read<AuthProvider>();
        if (authProvider.currentUser?.role == 'MANAGER') {
          return const SizedBox.shrink();
        }
        
        final todayIncome = provider.incomes.where((i) => i.date == todayStr).fold(0.0, (sum, item) => sum + item.amount);
        final todayExpense = provider.expenses.where((e) => e.date == todayStr).fold(0.0, (sum, item) => sum + item.amount);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem('Net Profit (Total)', cur.format(netProfit), netProfit >= 0 ? Colors.indigo : Colors.deepOrange, isBold: true, fontSize: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('TODAY\'S ACTIVITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey[400], letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('+ ${cur.format(todayIncome)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 8),
                            Text('- ${cur.format(todayExpense)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _subSummaryItem('Total Income', cur.format(totalIncome), Colors.green),
                    Container(width: 1, height: 20, color: Colors.grey[200]),
                    _subSummaryItem('Total Expense', cur.format(totalExpense), Colors.red),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _subSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _summaryItem(String label, String value, Color color, {bool isBold = false, double fontSize = 14}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildIncomeTab() {
    return Consumer<RealEstateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.incomes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.incomes.isEmpty) return const Center(child: Text('No income logs found'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.incomes.length,
          itemBuilder: (context, index) {
            final income = provider.incomes[index];
            return _buildFinanceCard(
              item: income,
              title: income.incomeType.replaceAll('_', ' '),
              amount: income.amount,
              date: income.date,
              description: income.description,
              projectName: income.projectName,
              isIncome: true,
            );
          },
        );
      },
    );
  }

  Widget _buildExpenseTab() {
    return Consumer<RealEstateProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.expenses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.expenses.isEmpty) return const Center(child: Text('No expense logs found'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.expenses.length,
          itemBuilder: (context, index) {
            final expense = provider.expenses[index];
            return _buildFinanceCard(
              item: expense,
              title: expense.category.replaceAll('_', ' '),
              amount: expense.amount,
              date: expense.date,
              description: expense.description,
              projectName: expense.projectName,
              isIncome: false,
            );
          },
        );
      },
    );
  }

  Widget _buildFinanceCard({
    required dynamic item,
    required String title,
    required double amount,
    required String date,
    String? description,
    String? projectName,
    required bool isIncome,
  }) {
    final color = isIncome ? Colors.green : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showAddDialog(isIncome, item: item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        title.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      '${isIncome ? '+' : '-'} Rs. ${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                  ),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    if (projectName != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMaroon.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.business_outlined, size: 12, color: AppTheme.primaryMaroon),
                            const SizedBox(width: 4),
                            Text(
                              projectName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryMaroon,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                      onPressed: () => _handleDelete(isIncome, item.id!),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog(bool isIncome, {dynamic item}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FinanceAddDialog(isIncome: isIncome, item: item),
    );
  }

  void _handleDelete(bool isIncome, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this ${isIncome ? 'income' : 'expense'} record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<RealEstateProvider>();
              final success = isIncome ? await provider.deleteIncome(id) : await provider.deleteExpense(id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Operation completed successfully!',
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
                }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class FinanceAddDialog extends StatefulWidget {
  final bool isIncome;
  final dynamic item;
  const FinanceAddDialog({super.key, required this.isIncome, this.item});

  @override
  State<FinanceAddDialog> createState() => _FinanceAddDialogState();
}

class _FinanceAddDialogState extends State<FinanceAddDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descController;
  late final TextEditingController _dateController;
  
  String? _selectedProjectId;
  String? _selectedCategory;
  RealEstateSale? _selectedSale;
  final TextEditingController _plotSearchController = TextEditingController();
  final TextEditingController _projectSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.item?.amount.toString());
    _descController = TextEditingController(text: widget.item?.description);
    _dateController = TextEditingController(text: widget.item?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    _selectedCategory = widget.isIncome ? (widget.item as RealEstateIncome?)?.incomeType : (widget.item as RealEstateExpense?)?.category;
    _selectedProjectId = widget.item?.projectId;

    if (widget.item != null) {
      if (widget.isIncome) {
        final income = widget.item as RealEstateIncome;
        if (income.saleId != null && income.incomeType == 'COMMISSION_RECEIVED') {
          final provider = context.read<RealEstateProvider>();
          try {
            _selectedSale = provider.sales.firstWhere((s) => s.id == income.saleId);
          } catch (_) {}
        }
      } else {
        final expense = widget.item as RealEstateExpense;
        if (expense.saleId != null && (expense.category == 'LANDOWNER_PAYOUT' || expense.category == 'COMMISSION_PAID')) {
          final provider = context.read<RealEstateProvider>();
          try {
            _selectedSale = provider.sales.firstWhere((s) => s.id == expense.saleId);
          } catch (_) {}
        }
      }
    }

    _projectSearchController.text = widget.item?.projectName ?? 'General / Other';

    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _dateController.dispose();
    _plotSearchController.dispose();
    _projectSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RealEstateProvider>();
    final types = widget.isIncome 
        ? ['COMMISSION_RECEIVED', 'INSTALLMENT_PAYMENT', 'OTHER']
        : ['LANDOWNER_PAYOUT', 'COMMISSION_PAID', 'OFFICE_RENT', 'SALARY', 'MARKETING', 'UTILITY', 'MISC'];
    final themeColor = widget.isIncome ? Colors.green : Colors.red;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.isIncome ? Icons.add_chart : Icons.receipt_long, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        widget.item == null 
                            ? (widget.isIncome ? 'Add New Income' : 'Add New Expense')
                            : (widget.isIncome ? 'Edit Income Entry' : 'Edit Expense Entry'),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildDialogField(
                        label: widget.isIncome ? 'Income Type' : 'Expense Category',
                        icon: Icons.category,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            dropdownColor: Colors.white,
                            style: const TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.w900, fontSize: 16),
                            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                            items: types.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
                             onChanged: (v) => setState(() {
                               _selectedCategory = v;
                               _selectedSale = null;
                             }),
                             validator: (v) => v == null ? 'Required' : null,
                           ),
                         ),
                       ),
                       if ((widget.isIncome && _selectedCategory == 'COMMISSION_RECEIVED') || 
                           (!widget.isIncome && (_selectedCategory == 'LANDOWNER_PAYOUT' || _selectedCategory == 'COMMISSION_PAID'))) ...[
                         const SizedBox(height: 20),
                         _buildDialogField(
                           label: 'Search & Select Plot / Sale',
                           icon: Icons.landscape,
                           child: Autocomplete<RealEstateSale>(
                             displayStringForOption: (s) => '${s.plotNumber ?? "N/A"} - ${s.customerName ?? "Unknown"}',
                             initialValue: _selectedSale != null ? TextEditingValue(text: '${_selectedSale!.plotNumber ?? "N/A"} - ${_selectedSale!.customerName ?? "Unknown"}') : null,
                             optionsBuilder: (textEditingValue) {
                               if (textEditingValue.text.isEmpty) return provider.sales;
                               return provider.sales.where((s) {
                                 final plot = (s.plotNumber ?? "").toLowerCase();
                                 final cust = (s.customerName ?? "").toLowerCase();
                                 final proj = (s.projectName ?? "").toLowerCase();
                                 final query = textEditingValue.text.toLowerCase();
                                 return plot.contains(query) || cust.contains(query) || proj.contains(query);
                               });
                             },
                             onSelected: (v) {
                               setState(() {
                                 _selectedSale = v;
                                 if (widget.isIncome) {
                                    _descController.text = 'Commission received from Plot ${v.plotNumber} - ${v.customerName}';
                                 } else {
                                    _descController.text = _selectedCategory == 'LANDOWNER_PAYOUT'
                                      ? 'Landowner payout for Plot ${v.plotNumber} - ${v.customerName}'
                                      : 'Dealer commission for Plot ${v.plotNumber} - ${v.dealerName ?? v.customerName}';
                                 }
                                 if (v.projectId != null) {
                                   _selectedProjectId = v.projectId;
                                   _projectSearchController.text = v.projectName ?? 'General / Other';
                                 }
                               });
                             },
                             fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                               return TextFormField(
                                 controller: controller,
                                 focusNode: focusNode,
                                 style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoalGray),
                                 decoration: const InputDecoration(
                                   hintText: 'Type plot # or name...',
                                   hintStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.grey),
                                   border: InputBorder.none,
                                   focusedBorder: InputBorder.none,
                                   enabledBorder: InputBorder.none,
                                   isDense: true,
                                   contentPadding: EdgeInsets.symmetric(vertical: 10),
                                 ),
                               );
                             },
                             optionsViewBuilder: (context, onSelected, options) {
                               return Align(
                                 alignment: Alignment.topLeft,
                                 child: Material(
                                   elevation: 8.0,
                                   borderRadius: BorderRadius.circular(12),
                                   child: Container(
                                     width: 452,
                                     constraints: const BoxConstraints(maxHeight: 250),
                                     child: ListView.builder(
                                       padding: EdgeInsets.zero,
                                       shrinkWrap: true,
                                       itemCount: options.length,
                                       itemBuilder: (context, index) {
                                         final option = options.elementAt(index);
                                         return ListTile(
                                           title: Text('${option.plotNumber ?? "N/A"} - ${option.customerName ?? "Unknown"}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                           subtitle: Text(option.projectName ?? "General Project", style: const TextStyle(fontSize: 12)),
                                           onTap: () => onSelected(option),
                                         );
                                       },
                                     ),
                                   ),
                                 ),
                               );
                             },
                           ),
                         ),
                         if (_selectedSale != null)
                           Padding(
                             padding: const EdgeInsets.only(top: 8),
                             child: Builder(
                               builder: (context) {
                                 final amountTyped = double.tryParse(_amountController.text) ?? 0;
                                 final originalAmount = widget.item?.amount ?? 0.0;
                                 double liveRemaining = widget.isIncome 
                                     ? _selectedSale!.landownerCommissionRemaining + originalAmount - amountTyped
                                     : (_selectedCategory == 'LANDOWNER_PAYOUT' 
                                         ? _selectedSale!.landownerShareRemaining + originalAmount - amountTyped
                                         : _selectedSale!.dealerCommissionRemaining + originalAmount - amountTyped);
                                 String label = widget.isIncome ? 'Live Remaining' : (_selectedCategory == 'LANDOWNER_PAYOUT' ? 'Landowner Remaining' : 'Dealer Remaining');
                                 
                                 return Text(
                                   '$label: Rs. ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(liveRemaining)}',
                                   style: TextStyle(color: liveRemaining < 0 ? Colors.red : Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                                 );
                               },
                             ),
                           ),
                       ],
                       const SizedBox(height: 20),
                       _buildDialogField(
                         label: 'Project (Optional)',
                         icon: Icons.business,
                         child: Autocomplete<RealEstateProject>(
                           displayStringForOption: (p) => p.name,
                           initialValue: TextEditingValue(text: provider.projects.any((p) => p.id == _selectedProjectId) 
                               ? provider.projects.firstWhere((p) => p.id == _selectedProjectId).name 
                               : 'General / Other'),
                           optionsBuilder: (textEditingValue) {
                             final generalOption = RealEstateProject(name: 'General / Other', location: '', landownerName: '', totalPlots: 0, plotSizes: '');
                             final list = [generalOption, ...provider.projects];
                             if (textEditingValue.text.isEmpty) return list;
                             return list.where((p) => p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                           },
                           onSelected: (p) {
                             setState(() {
                               _selectedProjectId = (p.name == 'General / Other') ? null : p.id;
                             });
                           },
                           fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                             // Sync the internal controller with our member controller
                             if (controller.text != _projectSearchController.text && _projectSearchController.text != 'Search Project...') {
                                Future.microtask(() => controller.text = _projectSearchController.text);
                             }
                             return TextFormField(
                               controller: controller,
                               focusNode: focusNode,
                               style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoalGray),
                               decoration: const InputDecoration(
                                 hintText: 'Search Project...',
                                 hintStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.grey),
                                 border: InputBorder.none,
                                 focusedBorder: InputBorder.none,
                                 enabledBorder: InputBorder.none,
                                 isDense: true,
                                 contentPadding: EdgeInsets.symmetric(vertical: 10),
                               ),
                             );
                           },
                           optionsViewBuilder: (context, onSelected, options) {
                             return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 8.0,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 452,
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final RealEstateProject option = options.elementAt(index);
                                        return ListTile(
                                          title: Text(option.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                           },
                         ),
                       ),
                       const SizedBox(height: 20),
                       _buildDialogField(
                         label: 'Amount (PKR)',
                         icon: Icons.payments,
                         child: TextFormField(
                           controller: _amountController,
                           style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
                           decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00', contentPadding: EdgeInsets.symmetric(vertical: 10)),
                           keyboardType: TextInputType.number,
                           validator: (v) {
                             if (v?.isEmpty == true) return 'Required';
                             final amount = double.tryParse(v!);
                             if (amount == null) return 'Invalid';
                             if (_selectedSale != null) {
                                final originalAmount = widget.item?.amount ?? 0.0;
                                if (widget.isIncome && _selectedCategory == 'COMMISSION_RECEIVED') {
                                   final maxPossible = _selectedSale!.landownerCommissionRemaining + originalAmount;
                                   if (amount > maxPossible) return 'Exceeds remaining: ${maxPossible.toInt()}';
                                } else if (!widget.isIncome) {
                                  if (_selectedCategory == 'LANDOWNER_PAYOUT') {
                                    final maxPossible = _selectedSale!.landownerShareRemaining + originalAmount;
                                    if (amount > maxPossible) return 'Exceeds share (Max: ${maxPossible.toInt()})';
                                  } else if (_selectedCategory == 'COMMISSION_PAID') {
                                    final maxPossible = _selectedSale!.dealerCommissionRemaining + originalAmount;
                                    if (amount > maxPossible) return 'Exceeds commission (Max: ${maxPossible.toInt()})';
                                  }
                                }
                             }
                             return null;
                           },
                         ),
                       ),
                       const SizedBox(height: 20),
                       _buildDialogField(
                         label: 'Transaction Date',
                         icon: Icons.calendar_month,
                         child: TextFormField(
                           controller: _dateController,
                           style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
                           decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                           readOnly: true,
                           onTap: () async {
                             final picked = await showDatePicker(
                               context: context,
                               initialDate: DateTime.now(),
                               firstDate: DateTime(2020),
                               lastDate: DateTime(2030),
                               builder: (context, child) => Theme(
                                 data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primaryMaroon, onPrimary: Colors.white, onSurface: Colors.black)),
                                 child: child!,
                               ),
                             );
                             if (picked != null) setState(() => _dateController.text = DateFormat('yyyy-MM-dd').format(picked));
                           },
                         ),
                       ),
                       const SizedBox(height: 20),
                       _buildDialogField(
                         label: 'Description / Remarks',
                         icon: Icons.notes,
                         child: TextFormField(
                           controller: _descController,
                           style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 15),
                           decoration: const InputDecoration(border: InputBorder.none, hintText: 'Add details here...', contentPadding: EdgeInsets.symmetric(vertical: 10)),
                           maxLines: 2,
                         ),
                       ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState?.validate() == true) {
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);

                              try {
                                bool success;
                                if (widget.isIncome) {
                                  final income = RealEstateIncome(
                                    id: (widget.item as RealEstateIncome?)?.id,
                                    incomeType: _selectedCategory!,
                                    amount: double.parse(_amountController.text),
                                    date: _dateController.text,
                                    projectId: _selectedProjectId,
                                    description: _descController.text,
                                    saleId: _selectedSale?.id,
                                  );
                                  success = widget.item == null ? await provider.addIncome(income) : await provider.updateIncome(widget.item.id!, income);
                                } else {
                                  final expense = RealEstateExpense(
                                    id: (widget.item as RealEstateExpense?)?.id,
                                    category: _selectedCategory!,
                                    amount: double.parse(_amountController.text),
                                    date: _dateController.text,
                                    projectId: _selectedProjectId,
                                    description: _descController.text,
                                    saleId: _selectedSale?.id,
                                  );
                                  success = widget.item == null ? await provider.addExpense(expense) : await provider.updateExpense(widget.item.id!, expense);
                                }
                                if (success) {
                                  provider.fetchDashboardData();
                                  provider.fetchSales();
                                  navigator.pop();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('${widget.item == null ? "Entry saved" : "Entry updated"} successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(provider.errorMessage ?? 'Failed to save entry'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(widget.item == null ? 'Save Entry' : 'Update Entry', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
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

  Widget _buildDialogField({required String label, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
