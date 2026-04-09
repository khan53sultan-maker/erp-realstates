import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/invoice_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../widgets/globals/text_field.dart';
import '../../widgets/globals/drop_down.dart';
import '../../widgets/globals/text_button.dart';
import '../../widgets/globals/custom_date_picker.dart';

class EditInvoiceDialog extends StatefulWidget {
  final InvoiceModel invoice;

  const EditInvoiceDialog({super.key, required this.invoice});

  @override
  State<EditInvoiceDialog> createState() => _EditInvoiceDialogState();
}

class _EditInvoiceDialogState extends State<EditInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _termsController;

  DateTime? _selectedDueDate;
  String? _selectedStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.invoice.notes ?? '');
    _termsController = TextEditingController(text: widget.invoice.termsConditions ?? '');
    _selectedDueDate = widget.invoice.dueDate;
    _selectedStatus = widget.invoice.status;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    // Set default terms if empty (using standardTermsAndConditionsApply as seen in CreateDialog)
    if (_termsController.text.isEmpty) {
      _termsController.text = l10n.standardTermsAndConditionsApply;
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
        width: 500,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Row(
                  children: [
                    Icon(Icons.edit, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.editInvoiceWithNumber(widget.invoice.invoiceNumber),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 24),

              // --- Status Dropdown ---
              PremiumDropdownField<String>(
                label: l10n.statusRequired,
                hint: l10n.selectInvoiceStatus,
                value: _selectedStatus,
                items: [
                  DropdownItem(value: 'DRAFT', label: l10n.draft),
                  DropdownItem(value: 'ISSUED', label: l10n.issued),
                  DropdownItem(value: 'SENT', label: l10n.sent),
                  DropdownItem(value: 'VIEWED', label: l10n.viewed),
                  DropdownItem(value: 'PAID', label: l10n.paid),
                  DropdownItem(value: 'OVERDUE', label: l10n.overdue),
                  DropdownItem(value: 'CANCELLED', label: l10n.cancelled),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseSelectStatus;
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // --- Due Date Picker ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.dueDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  _selectedDueDate != null
                      ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                      : l10n.notSpecified,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedDueDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _selectedDueDate = null;
                          });
                        },
                        tooltip: l10n.clearDueDate,
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () {
                        // ✅ Use Syncfusion Date Picker
                        context.showSyncfusionDateTimePicker(
                          initialDate: _selectedDueDate ?? DateTime.now(),
                          initialTime: TimeOfDay.now(),
                          showTimeInline: false,
                          onDateTimeSelected: (date, time) {
                            setState(() {
                              _selectedDueDate = date;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- Notes ---
              PremiumTextField(
                label: l10n.notes,
                hint: l10n.additionalInvoiceNotes,
                controller: _notesController,
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // --- Terms ---
              PremiumTextField(
                label: l10n.termsAndConditions,
                hint: l10n.invoiceTermsAndConditions,
                controller: _termsController,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // --- Actions ---
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PremiumButton(
                    text: l10n.cancel,
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    isOutlined: true,
                    width: 100,
                  ),
                  const SizedBox(width: 12),
                  PremiumButton(
                    text: l10n.updateInvoice,
                    onPressed: _isLoading ? null : _updateInvoice,
                    isLoading: _isLoading,
                    backgroundColor: Theme.of(context).primaryColor,
                    width: 120,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Future<void> _updateInvoice() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔍 [EditInvoiceDialog] Updating invoice: ${widget.invoice.id}');
      debugPrint('🔍 [EditInvoiceDialog] Status: $_selectedStatus');
      debugPrint('🔍 [EditInvoiceDialog] Due date: $_selectedDueDate');
      debugPrint('🔍 [EditInvoiceDialog] Notes: ${_notesController.text}');
      
      final invoiceProvider = context.read<InvoiceProvider>();
      final success = await invoiceProvider.updateInvoice(
        id: widget.invoice.id,
        status: _selectedStatus,
        dueDate: _selectedDueDate,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      debugPrint('🔍 [EditInvoiceDialog] Update invoice success: $success');

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invoiceUpdatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToUpdateInvoice ?? "Failed to update invoice"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [EditInvoiceDialog] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToUpdateInvoice ?? "Failed to update invoice"}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
