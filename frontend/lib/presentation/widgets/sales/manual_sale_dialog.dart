import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/models/sales/request_models.dart';
import '../../../src/models/customer/customer_model.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_field.dart';
import '../globals/text_button.dart';

class ManualSaleDialog extends StatefulWidget {
  const ManualSaleDialog({super.key});

  @override
  State<ManualSaleDialog> createState() => _ManualSaleDialogState();
}

class _ManualSaleDialogState extends State<ManualSaleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  CustomerModel? _selectedCustomer;
  String _paymentMethod = 'CASH';
  bool _isLoading = false;

  final List<Map<String, String>> _paymentMethods = [
    {'value': 'CASH', 'label': 'Cash'},
    {'value': 'CARD', 'label': 'Card'},
    {'value': 'BANK_TRANSFER', 'label': 'Bank Transfer'},
    {'value': 'MOBILE_PAYMENT', 'label': 'Mobile Payment'},
    {'value': 'CREDIT', 'label': 'Credit'},
  ];

  @override
  void initState() {
    super.initState();
    // Load customers for selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _invoiceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryMaroon,
              onPrimary: Colors.white,
              onSurface: AppTheme.charcoalGray,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final salesProvider = context.read<SalesProvider>();
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      // Because the backend requires at least one item, we'll search for 
      // a "Manual Entry" product or use the first available product 
      // as a placeholder if necessary. For now, we'll try to find any product
      // to link the manual entry to.
      
      if (salesProvider.products.isEmpty) {
        await salesProvider.loadProducts();
      }

      if (salesProvider.products.isEmpty) {
        throw Exception('No products found in system. Please add at least one product first.');
      }

      // Use the first product as a dummy container for manual entry
      final dummyProduct = salesProvider.products.first;

      final request = CreateSaleRequest(
        customerId: _selectedCustomer!.id,
        overallDiscount: 0,
        taxConfiguration: TaxConfiguration(taxes: {}),
        paymentMethod: _paymentMethod,
        amountPaid: amount,
        notes: _notesController.text.trim(),
        dateOfSale: _selectedDate,
        invoiceNumber: _invoiceController.text.trim(),
        saleItems: [
          CreateSaleItemRequest(
            productId: dummyProduct.id,
            unitPrice: amount,
            quantity: 1,
            itemDiscount: 0,
            customizationNotes: 'Manual Historical Entry',
          ),
        ],
      );

      final success = await salesProvider.createSale(request);
      
      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Historical record added successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(salesProvider.errorMessage ?? 'Failed to add record')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_edu_rounded, color: AppTheme.primaryMaroon, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Manual Historical Entry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.charcoalGray,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // Date Selection
              const Text('Transaction Date', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryMaroon),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Customer Selection
              const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Consumer<SalesProvider>(
                builder: (context, provider, child) {
                  return DropdownButtonFormField<CustomerModel>(
                    value: _selectedCustomer,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      hintText: 'Choose a customer',
                    ),
                    items: provider.customers.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text('${c.name} (${c.phone})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCustomer = val),
                    validator: (val) => val == null ? 'Customer is required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Invoice Number (Manual Receipt No)
              PremiumTextField(
                controller: _invoiceController,
                label: 'Receipt Number (Optional)',
                hint: 'Leave blank to auto-generate',
                prefixIcon: Icons.confirmation_number_rounded,
              ),
              const SizedBox(height: 16),

              // Amount
              PremiumTextField(
                controller: _amountController,
                label: 'Total Amount (PKR)',
                prefixIcon: Icons.payments_rounded,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Amount is required';
                  if (double.tryParse(val) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Payment Method
              const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                items: _paymentMethods.map((m) {
                  return DropdownMenuItem(
                    value: m['value'],
                    child: Text(m['label']!),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _paymentMethod = val!),
              ),
              const SizedBox(height: 16),

              // Notes
              PremiumTextField(
                controller: _notesController,
                label: 'Notes',
                maxLines: 2,
                prefixIcon: Icons.note_rounded,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  PremiumButton(
                    text: 'Save Record',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading,
                    width: 150,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
