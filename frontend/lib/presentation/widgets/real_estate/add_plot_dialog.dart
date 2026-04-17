import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/models/real_estate/plot_model.dart';
import '../../../src/providers/real_estate_provider.dart';

class AddPlotDialog extends StatefulWidget {
  final RealEstatePlot? plot;
  const AddPlotDialog({super.key, this.plot});

  @override
  State<AddPlotDialog> createState() => _AddPlotDialogState();
}

class _AddPlotDialogState extends State<AddPlotDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plotNumberController;
  late final TextEditingController _plotSizeController;
  late final TextEditingController _totalPriceController;
  String? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    _plotNumberController = TextEditingController(text: widget.plot?.plotNumber);
    _plotSizeController = TextEditingController(text: widget.plot?.plotSize);
    _totalPriceController = TextEditingController(text: widget.plot?.totalPrice.toString());
    _selectedProjectId = widget.plot?.projectId;
  }

  @override
  void dispose() {
    _plotNumberController.dispose();
    _plotSizeController.dispose();
    _totalPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final projects = context.watch<RealEstateProvider>().projects;

    return AlertDialog(
      title: Text(widget.plot == null ? l10n.addPlot : 'Edit Plot'),
      content: SizedBox(
        width: context.dialogWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedProjectId,
                  dropdownColor: AppTheme.pureWhite,
                  style: TextStyle(
                    fontSize: context.bodyFontSize, 
                    color: AppTheme.charcoalGray,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Select Project',
                    prefixIcon: Icon(Icons.business, size: context.iconSize('medium')),
                  ),
                  items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                  onChanged: (v) => setState(() => _selectedProjectId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                SizedBox(height: context.smallPadding),
                _buildField(l10n.plotNumber, _plotNumberController, icon: Icons.numbers, hint: 'e.g. A-123'),
                _buildField('Plot Size', _plotSizeController, icon: Icons.straighten, hint: 'e.g. 5 Marla'),
                _buildField('Total Price', _totalPriceController, icon: Icons.payments, isNumber: true, hint: '2500000'),
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
          onPressed: _savePlot,
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
        keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    );
  }

  void _savePlot() async {
    if (_formKey.currentState?.validate() == true && _selectedProjectId != null) {
      final plot = RealEstatePlot(
        id: widget.plot?.id,
        projectId: _selectedProjectId!,
        plotNumber: _plotNumberController.text,
        plotSize: _plotSizeController.text,
        totalPrice: double.tryParse(_totalPriceController.text) ?? 0,
        status: widget.plot?.status ?? 'AVAILABLE',
      );
      
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final provider = context.read<RealEstateProvider>();

      try {
        bool success;
        if (widget.plot == null) {
          success = await provider.addPlot(plot);
        } else {
          success = await provider.updatePlot(widget.plot!.id!, plot);
        }

        if (success) {
          navigator.pop();
          messenger.showSnackBar(
            SnackBar(content: Text(widget.plot == null ? 'Plot added successfully' : 'Plot updated successfully'), backgroundColor: Colors.green),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(content: Text(provider.errorMessage ?? 'Failed to save plot'), backgroundColor: Colors.red),
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
