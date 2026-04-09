import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/models/real_estate/real_estate_sale_model.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/models/real_estate/plot_model.dart';
import '../../../src/services/real_estate_print_service.dart';
import 'partner_payout_dialog.dart';
import '../../screens/real_estate/receipt_preview_screen.dart';

class AddSaleDialog extends StatefulWidget {
  final RealEstateSale? sale;
  const AddSaleDialog({super.key, this.sale});

  @override
  State<AddSaleDialog> createState() => _AddSaleDialogState();
}

class _AddSaleDialogState extends State<AddSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProjectId;
  String? _selectedPlotId;
  String? _selectedCustomerId;
  String? _selectedDealerId;
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;
  bool _isSaving = false;
  final _registrationNumberController = TextEditingController();
  final _downPaymentController = TextEditingController(); // Required (30%)
  final _receivedDownPaymentController = TextEditingController(); // Actual
  final _receiptNumberController = TextEditingController(); // Manual Receipt No
  final _installmentsCountController = TextEditingController(text: '12');
  final _semiAnnualBalloonPaymentController = TextEditingController(text: '0');
  
  double _currentPlotPrice = 0;
  double _remainingBalance = 0;
  double _totalCommission = 0;
  
  // Tracking for incremental payments
  double _initialDealerPaid = 0;
  double _initialLandownerPaidCommission = 0;
  double _initialLandownerPaidShare = 0;
  final _newDealerPaymentController = TextEditingController(text: '0');
  final _newLandownerCommPaymentController = TextEditingController(text: '0');
  final _newLandownerSharePaymentController = TextEditingController(text: '0');
  final _landownerRemarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _downPaymentController.addListener(_calculateRemaining);
    _newDealerPaymentController.addListener(() => setState(() {}));
    _newLandownerCommPaymentController.addListener(() => setState(() {}));
    _newLandownerSharePaymentController.addListener(() => setState(() {}));
    _semiAnnualBalloonPaymentController.addListener(_calculateRemaining);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers(pageSize: 10000);
      context.read<RealEstateProvider>().fetchProjects();
      if (widget.sale != null) {
        context.read<RealEstateProvider>().fetchPlots(projectId: widget.sale!.projectId);
      } else {
        context.read<RealEstateProvider>().fetchPlots();
      }

      if (widget.sale != null) {
        _selectedCustomerId = widget.sale!.customerId.trim();
        _selectedDealerId = widget.sale!.dealerId?.trim();
        _selectedProjectId = widget.sale!.projectId?.trim();
        _selectedPlotId = widget.sale!.plotId.trim();
        _registrationNumberController.text = widget.sale!.registrationNumber ?? '';
        _downPaymentController.text = widget.sale!.downPayment.toString();
        _receivedDownPaymentController.text = widget.sale!.receivedDownPayment.toString();
        _receiptNumberController.text = widget.sale!.receiptNumber ?? '';
        _installmentsCountController.text = widget.sale!.installmentsCount.toString();
        _semiAnnualBalloonPaymentController.text = widget.sale!.semiAnnualBalloonPayment.toString();
        _currentPlotPrice = widget.sale!.totalPrice;
        _remainingBalance = widget.sale!.remainingBalance;
        _totalCommission = widget.sale!.dealerCommission;
        
        _initialDealerPaid = widget.sale!.dealerPaidAmount;
        _initialLandownerPaidCommission = widget.sale!.landownerCommissionReceived;
        _initialLandownerPaidShare = widget.sale!.landownerPaidAmount;
        
        _newDealerPaymentController.text = '';
        _newLandownerCommPaymentController.text = '';
        _newLandownerSharePaymentController.text = '';
        
        if (widget.sale?.saleDate != null) {
          try {
            _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.sale!.saleDate!);
          } catch (e) {
            _selectedDate = DateTime.now();
          }
        }
        setState(() {
          _landownerRemarksController.text = widget.sale!.landownerPaymentRemarks ?? '';
        });
      }
    });
  }

  void _calculateRemaining() {
    final dp = double.tryParse(_downPaymentController.text) ?? 0;
    
    // Remaining Balance should be the TOTAL outstanding (Total - DP)
    // The backend will split this between monthly and balloon installments
    setState(() {
      _remainingBalance = _currentPlotPrice - dp;
    });
  }

  @override
  void dispose() {
    _registrationNumberController.dispose();
    _downPaymentController.dispose();
    _receivedDownPaymentController.dispose();
    _receiptNumberController.dispose();
    _installmentsCountController.dispose();
    _newDealerPaymentController.dispose();
    _newLandownerCommPaymentController.dispose();
    _newLandownerSharePaymentController.dispose();
    _semiAnnualBalloonPaymentController.dispose();
    _landownerRemarksController.dispose();
    super.dispose();
  }

  void _saveSale() async {
    if (_isSaving) return;
    if (_formKey.currentState?.validate() == true && _selectedPlotId != null && _selectedCustomerId != null) {
      setState(() => _isSaving = true);
      final provider = context.read<RealEstateProvider>();
      
      try {
        // Calculate New Totals
        final newDealerPay = double.tryParse(_newDealerPaymentController.text) ?? 0;
        final newLandownerCommPay = double.tryParse(_newLandownerCommPaymentController.text) ?? 0;
        final newLandownerSharePay = double.tryParse(_newLandownerSharePaymentController.text) ?? 0;
        
        final finalDealerTotal = _initialDealerPaid + newDealerPay;
        final finalLandownerCommTotal = _initialLandownerPaidCommission + newLandownerCommPay;
        final finalLandownerShareTotal = _initialLandownerPaidShare + newLandownerSharePay;

        String status = 'PENDING';
        
        final balloon = double.tryParse(_semiAnnualBalloonPaymentController.text) ?? 0;
        final insCount = int.tryParse(_installmentsCountController.text) ?? 12;
        final totalBalloonsAmount = balloon * (insCount ~/ 6);
        final baseMonthly = (_remainingBalance - totalBalloonsAmount) / (insCount == 0 ? 1 : insCount);

        final saleData = RealEstateSale(
          id: widget.sale?.id,
          plotId: _selectedPlotId!,
          customerId: _selectedCustomerId!,
          dealerId: _selectedDealerId,
          registrationNumber: _registrationNumberController.text,
          downPayment: double.tryParse(_downPaymentController.text) ?? 0,
          receivedDownPayment: double.tryParse(_receivedDownPaymentController.text) ?? 0,
          receiptNumber: _receiptNumberController.text,
          installmentsCount: int.tryParse(_installmentsCountController.text) ?? 12,
          totalPrice: _currentPlotPrice,
          remainingBalance: _remainingBalance,
          dealerPaidAmount: finalDealerTotal,
          landownerCommissionReceived: finalLandownerCommTotal,
          landownerPaidAmount: finalLandownerShareTotal,
          landownerPaymentRemarks: _landownerRemarksController.text,
          semiAnnualBalloonPayment: double.tryParse(_semiAnnualBalloonPaymentController.text) ?? 0,
          saleDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
          commissionStatus: status,
          dealerPayments: widget.sale?.dealerPayments ?? const [],
          landownerPayments: widget.sale?.landownerPayments ?? const [],
          landownerCommissionHistory: widget.sale?.landownerCommissionHistory ?? const [],
        );
        
        bool success;
        if (widget.sale == null) {
          success = await provider.addSale(saleData);
        } else {
          success = await provider.updateSale(widget.sale!.id!, saleData);
        }

        if (success && mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.sale == null ? 'Sale recorded successfully' : 'Sale updated successfully')),
          );
        } else if (mounted) {
          // Show error if failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to save sale record'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.sale == null ? 'Record New Sale' : 'Edit Sale Record', style: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: context.dialogWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date Selection Row
                InkWell(
                  onTap: () => setState(() => _showCalendar = !_showCalendar),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryMaroon, width: 2),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryMaroon.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryMaroon, size: 24),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sale Date (Click to View Calendar):', 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryMaroon),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          _showCalendar ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, 
                          color: AppTheme.primaryMaroon
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (_showCalendar) ...[
                  const SizedBox(height: 10),
                  Container(
                    height: 280,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: SfDateRangePicker(
                      showNavigationArrow: true, // Arrows for easy month flip
                      allowViewNavigation: true, // Allows jumping to Year/Decade
                      headerHeight: 50,
                      onSelectionChanged: (args) {
                        setState(() {
                          _selectedDate = args.value;
                          _showCalendar = false; 
                        });
                      },
                      selectionMode: DateRangePickerSelectionMode.single,
                      initialSelectedDate: _selectedDate,
                      headerStyle: const DateRangePickerHeaderStyle(
                        textAlign: TextAlign.center,
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: AppTheme.primaryMaroon, 
                          fontSize: 16
                        )
                      ),
                      monthCellStyle: const DateRangePickerMonthCellStyle(
                        todayTextStyle: TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold),
                      ),
                      selectionColor: AppTheme.primaryMaroon,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _receiptNumberController,
                  style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                  decoration: const InputDecoration(
                    labelText: 'Booking Receipt No (Manual)',
                    prefixIcon: Icon(Icons.receipt, color: AppTheme.primaryMaroon),
                    hintText: 'Enter manual receipt number for booking...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Project Selection First
                Consumer<RealEstateProvider>(
                  builder: (context, provider, child) {
                    final projectItems = provider.projects;
                    // Ensure selected value exists in the current list to avoid crash
                    final currentVal = projectItems.any((p) => p.id?.toString().toLowerCase().trim() == _selectedProjectId?.toString().toLowerCase().trim()) 
                        ? projectItems.firstWhere((p) => p.id?.toString().toLowerCase().trim() == _selectedProjectId?.toString().toLowerCase().trim()).id 
                        : null;
                    
                    return DropdownButtonFormField<String>(
                      menuMaxHeight: 300,
                      value: currentVal,
                      dropdownColor: AppTheme.pureWhite,
                      style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                      decoration: InputDecoration(
                        labelText: 'Select Project',
                        prefixIcon: Icon(Icons.business, size: context.iconSize('medium')),
                      ),
                      items: projectItems.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: widget.sale != null ? null : (v) { // Disable if editing
                        setState(() {
                          _selectedProjectId = v;
                          _selectedPlotId = null;
                          _currentPlotPrice = 0;
                          _remainingBalance = 0;
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                ),
                SizedBox(height: context.smallPadding),
                
                // Then Plot Selection
                Consumer<RealEstateProvider>(
                  builder: (context, provider, child) {
                    final filteredPlots = provider.plots.where((p) {
                      final pId = p.id?.toString().toLowerCase().trim();
                      final sId = widget.sale?.plotId.toString().toLowerCase().trim();
                      final pProjId = p.projectId.toString().toLowerCase().trim();
                      final sProjId = _selectedProjectId?.toString().toLowerCase().trim();
                      
                      final isSelectedPlot = (sId != null && pId == sId);
                      final isAvailable = (p.status == 'AVAILABLE' || p.status == 'RESERVED');
                      final projectMatches = (sProjId != null && pProjId == sProjId);
                      
                      return (projectMatches && isAvailable) || isSelectedPlot;
                    }).toList();
                    
                    // Safety check for plot value
                    final currentPlotVal = filteredPlots.any((p) => p.id?.toString().toLowerCase().trim() == _selectedPlotId?.toString().toLowerCase().trim()) 
                        ? filteredPlots.firstWhere((p) => p.id?.toString().toLowerCase().trim() == _selectedPlotId?.toString().toLowerCase().trim()).id 
                        : null;

                    return DropdownButtonFormField<String>(
                      menuMaxHeight: 300,
                      value: currentPlotVal,
                      dropdownColor: AppTheme.pureWhite,
                      style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                      decoration: InputDecoration(
                        labelText: 'Select Plot',
                        prefixIcon: Icon(Icons.location_on, size: context.iconSize('medium')),
                      ),
                      items: filteredPlots.map((p) => DropdownMenuItem(
                        value: p.id, 
                        child: Text('${p.plotNumber} - Rs.${p.totalPrice.toStringAsFixed(0)} (${p.plotSize})')
                      )).toList(),
                      onChanged: widget.sale != null ? null : (v) { // Disable if editing
                        final plot = filteredPlots.firstWhere((p) => p.id == v);
                        final project = provider.projects.firstWhere((p) => p.id == _selectedProjectId);
                        final dpPercent = project.downPaymentPercentage / 100.0;
                        
                        setState(() {
                          _selectedPlotId = v;
                          _currentPlotPrice = plot.totalPrice;
                          // Auto calculate based on project's down payment percentage
                          _downPaymentController.text = (plot.totalPrice * dpPercent).toStringAsFixed(0);
                          _receivedDownPaymentController.text = _downPaymentController.text;
                          _calculateRemaining(); 
                        });
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                ),
                SizedBox(height: context.smallPadding),

                Consumer<CustomerProvider>(
                  builder: (context, provider, child) {
                    final customerList = provider.allCustomers;
                    final currentCustomerVal = customerList.any((c) => c.id?.toString().toLowerCase().trim() == _selectedCustomerId?.toString().toLowerCase().trim()) 
                        ? customerList.firstWhere((c) => c.id?.toString().toLowerCase().trim() == _selectedCustomerId?.toString().toLowerCase().trim()).id 
                        : null;
                    
                    return DropdownButtonFormField<String>(
                      menuMaxHeight: 300,
                      value: currentCustomerVal,
                      dropdownColor: AppTheme.pureWhite,
                      style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                      decoration: InputDecoration(
                        labelText: l10n.customers,
                        prefixIcon: Icon(Icons.person, size: context.iconSize('medium')),
                      ),
                      items: customerList.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                      onChanged: (v) => setState(() => _selectedCustomerId = v),
                      validator: (v) => v == null ? 'Required' : null,
                    );
                  },
                ),
                SizedBox(height: context.smallPadding),

                Consumer<RealEstateProvider>(
                  builder: (context, provider, child) {
                    final dealerList = provider.dealers;
                    final currentDealerVal = dealerList.any((d) => d.id?.toString().toLowerCase().trim() == _selectedDealerId?.toString().toLowerCase().trim()) 
                        ? dealerList.firstWhere((d) => d.id?.toString().toLowerCase().trim() == _selectedDealerId?.toString().toLowerCase().trim()).id 
                        : null;

                    return DropdownButtonFormField<String>(
                      menuMaxHeight: 300,
                      value: currentDealerVal,
                      dropdownColor: AppTheme.pureWhite,
                      style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                      decoration: InputDecoration(
                        labelText: l10n.dealers,
                        prefixIcon: Icon(Icons.handshake, size: context.iconSize('medium')),
                      ),
                      items: dealerList.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))).toList(),
                      onChanged: (v) => setState(() => _selectedDealerId = v),
                    );
                  },
                ),
                
                SizedBox(height: context.smallPadding),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.primaryMaroon.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Plot Total Price:', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Rs.${_currentPlotPrice.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.normal)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Remaining Balance:', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Rs.${_remainingBalance.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Base Monthly Installment:', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                          Text(
                            'Rs.${(((_remainingBalance - (double.tryParse(_semiAnnualBalloonPaymentController.text) ?? 0) * ((int.tryParse(_installmentsCountController.text) ?? 1) ~/ 6)) / ((int.tryParse(_installmentsCountController.text) ?? 1) - ((int.tryParse(_installmentsCountController.text) ?? 1) ~/ 6))).isNaN || ((int.tryParse(_installmentsCountController.text) ?? 1) - ((int.tryParse(_installmentsCountController.text) ?? 1) ~/ 6)) <= 0 ? 0 : ((_remainingBalance - (double.tryParse(_semiAnnualBalloonPaymentController.text) ?? 0) * ((int.tryParse(_installmentsCountController.text) ?? 1) ~/ 6)) / ((int.tryParse(_installmentsCountController.text) ?? 1) - ((int.tryParse(_installmentsCountController.text) ?? 1) ~/ 6)))).toStringAsFixed(0)}', 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Balloon Month Payment (Total):', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.deepOrange)),
                          Text(
                            'Rs.${(double.tryParse(_semiAnnualBalloonPaymentController.text) ?? 0).toStringAsFixed(0)}', 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: context.smallPadding),
                SizedBox(height: context.smallPadding),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _registrationNumberController,
                        style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                        decoration: InputDecoration(labelText: 'Reg No (e.g. 1,001)', prefixIcon: Icon(Icons.numbers)),
                      ),
                    ),
                    SizedBox(width: context.smallPadding),
                    Expanded(
                      child: TextFormField(
                        controller: _installmentsCountController,
                        style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                        decoration: InputDecoration(labelText: 'Installments', prefixIcon: Icon(Icons.repeat)),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.smallPadding),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _downPaymentController,
                        style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                        decoration: InputDecoration(labelText: 'Required Down (30%)', prefixIcon: Icon(Icons.payments)),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calculateRemaining(),
                      ),
                    ),
                    SizedBox(width: context.smallPadding),
                    Expanded(
                      child: TextFormField(
                        controller: _receivedDownPaymentController,
                        style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                        decoration: InputDecoration(labelText: 'Received Down Payment', prefixIcon: Icon(Icons.account_balance_wallet)),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.smallPadding),
                TextFormField(
                  controller: _semiAnnualBalloonPaymentController,
                  style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                  decoration: const InputDecoration(
                    labelText: 'Semi-Annual Balloon Payment (Every 6 Months)',
                    prefixIcon: Icon(Icons.event_repeat, color: Colors.deepOrange),
                    hintText: 'Enter amount to pay extra every 6 months',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateRemaining(),
                ),

                const Divider(height: 32),


                if (widget.sale != null) ...[
                  SizedBox(height: context.mediumPadding),
                  const Divider(thickness: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('FINANCIAL UPDATES & SETTLEMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
                        TextButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => PartnerPayoutDialog(sale: widget.sale!),
                          ),
                          icon: const Icon(Icons.receipt_long_rounded, size: 18),
                          label: const Text('View Partner Ledger', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryMaroon),
                        ),
                      ],
                    ),
                  ),
                  
                  // Company Commission Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withOpacity(0.2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('COMPANY COMMISSION (INCOME)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _commissionSummaryRow('Required', (widget.sale?.landownerCommission ?? 0), hasIcon: true, onTap: () => _viewFullStatement(context, 'LANDOWNER_COMM'))),
                            Expanded(child: _commissionSummaryRow('Received', _initialLandownerPaidCommission, color: Colors.blue, hasIcon: true, onTap: () => _viewFullStatement(context, 'LANDOWNER_COMM'))),
                            Expanded(child: _commissionSummaryRow('Remaining', (widget.sale?.landownerCommission ?? 0) - _initialLandownerPaidCommission - (double.tryParse(_newLandownerCommPaymentController.text) ?? 0), color: Colors.orange, isBold: true, hasIcon: true, onTap: () => _viewFullStatement(context, 'LANDOWNER_COMM'))),
                          ],
                        ),
                        const SizedBox(height: 12),
                         TextFormField(
                          controller: _newLandownerCommPaymentController,
                          style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                          decoration: InputDecoration(
                            labelText: 'Add New Commission Received', 
                            prefixIcon: const Icon(Icons.add_circle, color: Colors.blue),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.blue),
                                  onPressed: () {
                                    final amt = double.tryParse(_newLandownerCommPaymentController.text) ?? 0;
                                    if (amt <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount first')));
                                      return;
                                    }
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => RealEstateReceiptPreviewScreen(
                                      sale: widget.sale!,
                                      partnerAmount: amt,
                                      partnerType: 'LANDOWNER_COMM',
                                      partnerRemarks: 'Company Commission Received',
                                    )));
                                  },
                                  tooltip: 'View Receipt',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.print, color: Colors.blue),
                                  onPressed: () {
                                    final amt = double.tryParse(_newLandownerCommPaymentController.text) ?? 0;
                                    if (amt <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount first')));
                                      return;
                                    }
                                    RealEstatePrintService.printLandownerPaymentReceipt(
                                      sale: widget.sale!,
                                      amountPaid: amt,
                                      remarks: 'Company Commission Received',
                                    );
                                  },
                                  tooltip: 'Print Receipt',
                                ),
                              ],
                            ),
                            hintText: 'Enter recovery amount',
                            suffixText: 'PKR',
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                        if (widget.sale?.landownerCommissionHistory.isNotEmpty ?? false)
                           _buildPayoutHistory(
                            context: context,
                            title: 'Company Income History',
                            payments: widget.sale!.landownerCommissionHistory.map((p) => {
                              'date': p.date,
                              'amount': p.amount,
                              'remarks': p.remarks,
                              'onView': () => Navigator.push(context, MaterialPageRoute(builder: (context) => RealEstateReceiptPreviewScreen(
                                sale: widget.sale!,
                                partnerAmount: p.amount,
                                partnerType: 'LANDOWNER_COMM',
                                partnerRemarks: p.remarks,
                              ))),
                              'onPrint': () => RealEstatePrintService.printLandownerPaymentReceipt(
                                sale: widget.sale!,
                                amountPaid: p.amount,
                                remarks: p.remarks,
                              )
                            }).toList(),
                            color: Colors.blue,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.smallPadding),
                  
                  // Landowner Share Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.purple.withOpacity(0.2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('LANDOWNER PLOT SHARE SETTLEMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple)),
                        const SizedBox(height: 12),
                        _commissionSummaryRow('Total Landowner Share:', (widget.sale?.landownerTotalShare ?? 0)),
                        _commissionSummaryRow('Landowner Recovery (from Customer):', (widget.sale?.landownerShareReceived ?? 0), color: Colors.blue),
                        _commissionSummaryRow('Already Paid to Landowner:', _initialLandownerPaidShare, color: Colors.green),
                        const Divider(height: 15),
                        _commissionSummaryRow(
                          'Remaining to Pay Landowner:', 
                          (widget.sale?.landownerTotalShare ?? 0) - _initialLandownerPaidShare - (double.tryParse(_newLandownerSharePaymentController.text) ?? 0),
                          color: Colors.red,
                          isBold: true
                        ),
                        const SizedBox(height: 12),
                          TextFormField(
                            controller: _newLandownerSharePaymentController,
                            style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                            decoration: InputDecoration(
                              labelText: 'Pay New Amount to Landowner', 
                              prefixIcon: const Icon(Icons.outbox, color: Colors.purple),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.purple),
                                    onPressed: () {
                                      final amt = double.tryParse(_newLandownerSharePaymentController.text) ?? 0;
                                      if (amt <= 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount first')));
                                        return;
                                      }
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => RealEstateReceiptPreviewScreen(
                                        sale: widget.sale!,
                                        partnerAmount: amt,
                                        partnerType: 'LANDOWNER_SHARE',
                                        partnerRemarks: _landownerRemarksController.text,
                                      )));
                                    },
                                    tooltip: 'View Receipt',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.print, color: Colors.purple),
                                    onPressed: () {
                                      final amt = double.tryParse(_newLandownerSharePaymentController.text) ?? 0;
                                      if (amt <= 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount first')));
                                        return;
                                      }
                                      RealEstatePrintService.printLandownerPaymentReceipt(
                                        sale: widget.sale!,
                                        amountPaid: amt,
                                        remarks: _landownerRemarksController.text,
                                      );
                                    },
                                    tooltip: 'Print Receipt',
                                  ),
                                ],
                              ),
                              hintText: 'Enter cash given to landowner',
                              suffixText: 'PKR',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        const SizedBox(height: 8),
                        if (widget.sale?.landownerPayments.isNotEmpty ?? false)
                           _buildPayoutHistory(
                            context: context,
                            title: 'Payout History',
                            payments: widget.sale!.landownerPayments.map((p) => {
                              'date': p.date,
                              'amount': p.amount,
                              'remarks': p.remarks,
                              'onView': () => Navigator.push(context, MaterialPageRoute(builder: (context) => RealEstateReceiptPreviewScreen(
                                sale: widget.sale!,
                                partnerAmount: p.amount,
                                partnerType: 'LANDOWNER_SHARE',
                                partnerRemarks: p.remarks,
                              ))),
                              'onPrint': () => RealEstatePrintService.printLandownerPaymentReceipt(
                                sale: widget.sale!,
                                amountPaid: p.amount,
                                remarks: p.remarks,
                              )
                            }).toList(),
                            color: Colors.purple,
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _landownerRemarksController,
                          style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                          decoration: InputDecoration(
                            labelText: 'Payment Remarks (e.g., Cash, Bank Transfer)', 
                            prefixIcon: const Icon(Icons.comment, color: Colors.purple),
                            hintText: 'Enter payment mode or details',
                            fillColor: Colors.white,
                            filled: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (_selectedDealerId != null) ...[
                    SizedBox(height: context.smallPadding),
                    // Dealer Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withOpacity(0.2))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SALE PARTNER (DEALER) COMMISSION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _commissionSummaryRow('Total', _totalCommission, hasIcon: true, onTap: () => _viewFullStatement(context, 'DEALER'))),
                              Expanded(child: _commissionSummaryRow('Paid', _initialDealerPaid, color: Colors.green, hasIcon: true, onTap: () => _viewFullStatement(context, 'DEALER'))),
                              Expanded(child: _commissionSummaryRow('Remaining', _totalCommission - _initialDealerPaid - (double.tryParse(_newDealerPaymentController.text) ?? 0), color: Colors.red, isBold: true, hasIcon: true, onTap: () => _viewFullStatement(context, 'DEALER'))),
                            ],
                          ),
                          const SizedBox(height: 12),
                           TextFormField(
                            controller: _newDealerPaymentController,
                            style: TextStyle(color: AppTheme.charcoalGray, fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
                            decoration: InputDecoration(
                              labelText: 'Pay New Amount to Dealer', 
                              prefixIcon: const Icon(Icons.add_card, color: Colors.green),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.green),
                                    onPressed: () {
                                      final amt = double.tryParse(_newDealerPaymentController.text) ?? 0;
                                      if (amt <= 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount first')));
                                        return;
                                      }
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => RealEstateReceiptPreviewScreen(
                                        sale: widget.sale!,
                                        partnerAmount: amt,
                                        partnerType: 'DEALER',
                                        partnerRemarks: 'Commission Payment',
                                      )));
                                    },
                                    tooltip: 'View Receipt',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.print, color: Colors.green),
                                    onPressed: () {
                                      final amt = double.tryParse(_newDealerPaymentController.text) ?? 0;
                                      if (amt <= 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an amount first')));
                                        return;
                                      }
                                      RealEstatePrintService.printDealerPaymentReceipt(
                                        sale: widget.sale!,
                                        amountPaid: amt,
                                        remarks: 'Commission Payment',
                                      );
                                    },
                                    tooltip: 'Print Receipt',
                                  ),
                                ],
                              ),
                              hintText: 'Enter new payment amount',
                              suffixText: 'PKR',
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 8),
                          if (widget.sale?.dealerPayments.isNotEmpty ?? false)
                             _buildPayoutHistory(
                              context: context,
                              title: 'Commission Payout History',
                              payments: widget.sale!.dealerPayments.map((p) => {
                                'date': p.date,
                                'amount': p.amount,
                                'remarks': p.remarks,
                                'onView': () => Navigator.push(context, MaterialPageRoute(builder: (context) => RealEstateReceiptPreviewScreen(
                                  sale: widget.sale!,
                                  partnerAmount: p.amount,
                                  partnerType: 'DEALER',
                                  partnerRemarks: p.remarks,
                                ))),
                                'onPrint': () => RealEstatePrintService.printDealerPaymentReceipt(
                                  sale: widget.sale!,
                                  amountPaid: p.amount,
                                  remarks: p.remarks,
                                )
                              }).toList(),
                              color: Colors.green,
                            ),
                          const SizedBox(height: 4),
                          const Text('Enter ONLY the amount you are paying now. It will be added to the "Paid so far" total.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ], // if dealer
                ], // if sale
              ], // main children
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMaroon),
          onPressed: _isSaving ? null : _saveSale,
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(widget.sale == null ? l10n.save : 'Update Record'),
        ),
      ],
    );
  }

  void _viewFullStatement(BuildContext context, String type) {
    if (widget.sale == null) return;
    
    double totalAmount = 0;
    if (type == 'DEALER') totalAmount = widget.sale!.dealerPaidAmount;
    if (type == 'LANDOWNER_SHARE') totalAmount = widget.sale!.landownerPaidAmount;
    if (type == 'LANDOWNER_COMM') totalAmount = widget.sale!.landownerCommissionReceived;

    Navigator.push(context, MaterialPageRoute(builder: (context) => RealEstateReceiptPreviewScreen(
      sale: widget.sale!,
      partnerAmount: totalAmount,
      partnerType: type,
      partnerRemarks: "Full Summary Statement",
      isFullStatement: true,
    )));
  }

  Widget _commissionSummaryRow(String label, double amount, {Color? color, bool isBold = false, bool hasIcon = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                if (hasIcon) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.receipt_long_rounded, size: 10, color: color?.withOpacity(0.5) ?? Colors.grey),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Rs.${amount.toStringAsFixed(0)}', 
              style: TextStyle(
                fontSize: 13, 
                fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, 
                color: color ?? AppTheme.charcoalGray
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutHistory({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> payments,
    required Color color,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        dense: true,
        tilePadding: EdgeInsets.zero,
        children: payments.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.1))),
          child: Row(
            children: [
              Text(p['date'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(child: Text(p['remarks'] ?? '-', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis)),
              Text('Rs.${p['amount'].toStringAsFixed(0)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                IconButton(
                  icon: Icon(Icons.remove_red_eye_rounded, size: 16, color: color),
                  onPressed: p['onView'] ?? () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'View Receipt',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.print, size: 16, color: color),
                  onPressed: p['onPrint'],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Reprint Receipt',
                ),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
