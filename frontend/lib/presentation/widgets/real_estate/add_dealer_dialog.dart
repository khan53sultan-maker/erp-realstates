import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/models/real_estate/dealer_model.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/providers/auth_provider.dart';

class AddDealerDialog extends StatefulWidget {
  final RealEstateDealer? dealer;
  const AddDealerDialog({super.key, this.dealer});

  @override
  State<AddDealerDialog> createState() => _AddDealerDialogState();
}

class _AddDealerDialogState extends State<AddDealerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _commissionController;
  late String _type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dealer?.name);
    _phoneController = TextEditingController(text: widget.dealer?.phone);
    _commissionController = TextEditingController(text: widget.dealer?.commissionPercentage.toString() ?? '2.0');
    _type = widget.dealer?.type ?? 'DEALER';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.dealer == null ? l10n.addDealer : 'Edit Dealer/Agent'),
      content: SizedBox(
        width: context.dialogWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(l10n.name, _nameController, icon: Icons.person, hint: 'Full Name'),
                _buildField(l10n.phone, _phoneController, icon: Icons.phone, hint: '03xx-xxxxxxx'),
                DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor: AppTheme.pureWhite,
                  style: TextStyle(
                    fontSize: context.bodyFontSize, 
                    color: AppTheme.charcoalGray,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.category, size: context.iconSize('medium')),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DEALER', child: Text('Dealer')),
                    DropdownMenuItem(value: 'SUB_AGENT', child: Text('Sub Agent')),
                    DropdownMenuItem(value: 'TEAM_MEMBER', child: Text('Team Member')),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
                SizedBox(height: context.smallPadding),
                if (context.read<AuthProvider>().currentUser?.role != 'MANAGER')
                  _buildField(l10n.commission + ' %', _commissionController, icon: Icons.percent, isNumber: true, hint: '2.0'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _saveDealer,
          child: Text(l10n.save),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, {IconData? icon, bool isNumber = false, String? hint}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallPadding / 1.5),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          fontSize: context.bodyFontSize, 
          color: AppTheme.charcoalGray,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, size: context.iconSize('medium')) : null,
        ),
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.phone,
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    );
  }

  void _saveDealer() async {
    if (_formKey.currentState?.validate() == true) {
      final dealer = RealEstateDealer(
        id: widget.dealer?.id,
        name: _nameController.text,
        phone: _phoneController.text,
        commissionPercentage: double.tryParse(_commissionController.text) ?? 2.0,
        type: _type,
      );
      
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final provider = context.read<RealEstateProvider>();

      try {
        bool success;
        if (widget.dealer == null) {
          success = await provider.addDealer(dealer);
        } else {
          success = await provider.updateDealer(widget.dealer!.id!, dealer);
        }

        if (success) {
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(content: Text(widget.dealer == null ? 'Dealer added successfully' : 'Dealer updated successfully'), backgroundColor: Colors.green),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text(provider.errorMessage ?? 'Failed to save dealer'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
