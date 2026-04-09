import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../src/models/real_estate/project_model.dart';
import '../../../src/providers/real_estate_provider.dart';

class AddProjectDialog extends StatefulWidget {
  final RealEstateProject? project;
  const AddProjectDialog({super.key, this.project});

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _landownerController;
  late final TextEditingController _totalPlotsController;
  late final TextEditingController _plotSizesController;
  late final TextEditingController _commissionController;
  late final TextEditingController _downPaymentController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name);
    _locationController = TextEditingController(text: widget.project?.location);
    _landownerController = TextEditingController(text: widget.project?.landownerName);
    _totalPlotsController = TextEditingController(text: widget.project?.totalPlots.toString());
    _plotSizesController = TextEditingController(text: widget.project?.plotSizes);
    _commissionController = TextEditingController(text: widget.project?.landownerCommissionPercentage.toString() ?? '12.0');
    _downPaymentController = TextEditingController(text: widget.project?.downPaymentPercentage.toString() ?? '30.0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _landownerController.dispose();
    _totalPlotsController.dispose();
    _plotSizesController.dispose();
    _commissionController.dispose();
    _downPaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(widget.project == null ? l10n.addProject : 'Edit Project'),
      content: SizedBox(
        width: context.dialogWidth,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(l10n.name, _nameController, icon: Icons.business, hint: 'e.g. Blue World City'),
                _buildField(l10n.location, _locationController, icon: Icons.location_on, hint: 'e.g. Islamabad'),
                _buildField(l10n.landowner, _landownerController, icon: Icons.person, hint: 'Name of the owner'),
                Row(
                  children: [
                    Expanded(child: _buildField(l10n.totalPlots, _totalPlotsController, icon: Icons.pie_chart, isNumber: true, hint: '500')),
                    SizedBox(width: context.smallPadding),
                    Expanded(child: _buildField('Plot Sizes', _plotSizesController, icon: Icons.straighten, hint: '5 Marla, 10 Marla')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildField(l10n.commission + ' %', _commissionController, isNumber: true, hint: '10.0')),
                    SizedBox(width: context.smallPadding),
                    Expanded(child: _buildField(l10n.downPayment + ' %', _downPaymentController, isNumber: true, hint: '25.0')),
                  ],
                ),
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
          onPressed: _saveProject,
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

  void _saveProject() async {
    if (_formKey.currentState?.validate() == true) {
      final project = RealEstateProject(
        id: widget.project?.id,
        name: _nameController.text,
        location: _locationController.text,
        landownerName: _landownerController.text,
        totalPlots: int.tryParse(_totalPlotsController.text) ?? 0,
        plotSizes: _plotSizesController.text,
        landownerCommissionPercentage: double.tryParse(_commissionController.text) ?? 12.0,
        downPaymentPercentage: double.tryParse(_downPaymentController.text) ?? 30.0,
        status: widget.project?.status ?? 'ACTIVE',
      );
      
      bool success;
      if (widget.project == null) {
        success = await context.read<RealEstateProvider>().addProject(project);
      } else {
        success = await context.read<RealEstateProvider>().updateProject(widget.project!.id!, project);
      }

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.project == null ? 'Project added successfully' : 'Project updated successfully'), backgroundColor: Colors.green),
        );
      }
    }
  }
}
