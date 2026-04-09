import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/invoice_provider.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../widgets/globals/text_field.dart';
import '../../widgets/globals/drop_down.dart';
import '../../widgets/globals/text_button.dart';
import '../../widgets/globals/custom_date_picker.dart';

class CreateInvoiceDialog extends StatefulWidget {
  const CreateInvoiceDialog({super.key});

  @override
  State<CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<CreateInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _termsController = TextEditingController();

  String? _selectedSaleId;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDueDate = DateTime.now().add(const Duration(days: 30));

    // Load sales if empty with delay to prevent API spam
    Future.microtask(() {
      final salesProvider = context.read<SalesProvider>();
      debugPrint('🔍 [CreateInvoiceDialog] Checking SalesProvider state...');
      debugPrint('🔍 [CreateInvoiceDialog] Sales count: ${salesProvider.sales.length}');
      debugPrint('🔍 [CreateInvoiceDialog] Is loading: ${salesProvider.isLoading}');
      
      if (salesProvider.sales.isEmpty) {
        debugPrint('🔍 [CreateInvoiceDialog] Loading sales...');
        salesProvider.loadSales();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill terms if needed
    if (_termsController.text.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      _termsController.text = l10n.standardTermsAndConditionsApply ?? "Standard terms apply";
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius('large'))),
      backgroundColor: Colors.white,
      child: Container(
        width: 500, // Fixed width for dialog consistency
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMaroon.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.receipt_long, color: AppTheme.primaryMaroon),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.createNewInvoice ?? "Create New Invoice",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 32),

              // 1. Select Sale Dropdown
              Consumer<SalesProvider>(
                builder: (context, salesProvider, child) {
                  debugPrint('🔍 [CreateInvoiceDialog] SalesProvider has ${salesProvider.sales.length} sales');
                  debugPrint('🔍 [CreateInvoiceDialog] SalesProvider loading: ${salesProvider.isLoading}');
                  
                  final eligibleSales = salesProvider.sales
                      .where((sale) => sale.status != 'INVOICED')
                      .toList();
                  
                  debugPrint('🔍 [CreateInvoiceDialog] Found ${eligibleSales.length} eligible sales for invoicing');
                  
                  if (eligibleSales.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              salesProvider.sales.isEmpty 
                                  ? 'No sales found. Please create some sales first.'
                                  : 'No eligible sales found. All sales have been invoiced.',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return PremiumDropdownField<String>(
                    label: l10n.selectSaleRequired ?? "Select Sale (Required)",
                    hint: "Choose a sale to create invoice",
                    value: _selectedSaleId,
                    items: eligibleSales.map((sale) {
                      return DropdownItem(
                        value: sale.id,
                        label: '${sale.invoiceNumber} - ${sale.customerName} (${sale.grandTotal.toStringAsFixed(2)})',
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedSaleId = value),
                    validator: (value) => value == null ? (l10n.pleaseSelectASale ?? "Required") : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // 2. Due Date Picker
              InkWell(
                onTap: () {
                  context.showSyncfusionDateTimePicker(
                    initialDate: _selectedDueDate ?? DateTime.now(),
                    initialTime: TimeOfDay.now(),
                    showTimeInline: false,
                    onDateTimeSelected: (date, _) => setState(() => _selectedDueDate = date),
                  );
                },
                child: IgnorePointer(
                  child: PremiumTextField(
                    label: l10n.dueDate ?? "Due Date",
                    controller: TextEditingController(
                      text: _selectedDueDate != null
                          ? "${_selectedDueDate!.day}-${_selectedDueDate!.month}-${_selectedDueDate!.year}"
                          : "",
                    ),
                    prefixIcon: Icons.calendar_today,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Notes
              PremiumTextField(
                label: l10n.notes ?? "Notes",
                hint: "Additional notes...",
                controller: _notesController,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // 4. Terms
              PremiumTextField(
                label: l10n.termsAndConditions ?? "Terms",
                controller: _termsController,
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PremiumButton(
                    text: l10n.cancel ?? "Cancel",
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: Colors.grey,
                    width: 100,
                  ),
                  const SizedBox(width: 12),
                  Consumer<SalesProvider>(
                    builder: (context, salesProvider, child) {
                      final eligibleSales = salesProvider.sales
                          .where((sale) => sale.status != 'INVOICED')
                          .toList();
                      
                      return PremiumButton(
                        text: l10n.createInvoice ?? "Create",
                        onPressed: eligibleSales.isEmpty ? null : _createInvoice,
                        isLoading: _isLoading,
                        width: 140,
                        icon: Icons.check,
                        backgroundColor: eligibleSales.isEmpty ? Colors.grey : AppTheme.primaryMaroon,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      debugPrint('🔍 [CreateInvoiceDialog] Creating invoice for sale: $_selectedSaleId');
      debugPrint('🔍 [CreateInvoiceDialog] Due date: $_selectedDueDate');
      debugPrint('🔍 [CreateInvoiceDialog] Notes: ${_notesController.text}');
      
      final success = await context.read<InvoiceProvider>().createInvoice(
        saleId: _selectedSaleId!,
        dueDate: _selectedDueDate,
        // Send null if empty string to be cleaner
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      debugPrint('🔍 [CreateInvoiceDialog] Create invoice success: $success');

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invoice Created Successfully"), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create invoice"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('❌ [CreateInvoiceDialog] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
