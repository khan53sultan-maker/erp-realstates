import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/payable/payable_model.dart';
import '../../../src/providers/payables_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../globals/custom_date_picker.dart';
import '../../../l10n/app_localizations.dart';

class EditPayableDialog extends StatefulWidget {
  final Payable payable;

  const EditPayableDialog({super.key, required this.payable});

  @override
  State<EditPayableDialog> createState() => _EditPayableDialogState();
}

class _EditPayableDialogState extends State<EditPayableDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _creditorNameController;
  late TextEditingController _creditorPhoneController;
  late TextEditingController _creditorEmailController;
  late TextEditingController _amountBorrowedController;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;
  late TextEditingController _amountPaidController;

  late DateTime _dateBorrowed;
  late DateTime _expectedRepaymentDate;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _creditorNameController = TextEditingController(text: widget.payable.creditorName);
    _creditorPhoneController = TextEditingController(text: widget.payable.creditorPhone ?? '');
    _creditorEmailController = TextEditingController(text: widget.payable.creditorEmail ?? '');
    _amountBorrowedController = TextEditingController(text: widget.payable.amountBorrowed.toString());
    _reasonController = TextEditingController(text: widget.payable.reasonOrItem);
    _notesController = TextEditingController(text: widget.payable.notes ?? '');
    _amountPaidController = TextEditingController(text: widget.payable.amountPaid.toString());
    _dateBorrowed = widget.payable.dateBorrowed;
    _expectedRepaymentDate = widget.payable.expectedRepaymentDate;

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _creditorNameController.dispose();
    _creditorPhoneController.dispose();
    _creditorEmailController.dispose();
    _amountBorrowedController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      final amountBorrowed = double.parse(_amountBorrowedController.text.trim());
      final amountPaid = double.tryParse(_amountPaidController.text.trim()) ?? 0.0;

      if (amountPaid > amountBorrowed) {
        _showErrorSnackbar(l10n.amountPaidCannotExceedAmountBorrowed);
        return;
      }

      if (_expectedRepaymentDate.isBefore(_dateBorrowed)) {
        _showErrorSnackbar(l10n.expectedRepaymentDateCannotBeBeforeDateBorrowed);
        return;
      }

      final payablesProvider = Provider.of<PayablesProvider>(context, listen: false);

      final additionalAmount = double.tryParse(_amountPaidController.text.trim()) ?? 0.0;

      await payablesProvider.updatePayable(
        id: widget.payable.id,
        creditorName: _creditorNameController.text.trim(),
        creditorPhone: _creditorPhoneController.text.trim(),
        creditorEmail: _creditorEmailController.text.trim(),
        amountBorrowed: amountBorrowed,
        amountPaid: additionalAmount,
        reasonOrItem: _reasonController.text.trim(),
        dateBorrowed: _dateBorrowed,
        expectedRepaymentDate: _expectedRepaymentDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        _showSuccessSnackbar();
        Navigator.of(context).pop();
      }
    }
  }

  void _showSuccessSnackbar() {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.payableUpdatedSuccessfully,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              message,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  Future<void> _selectDateBorrowed() async {
    final l10n = AppLocalizations.of(context)!;

    await context.showSyncfusionDateTimePicker(
      initialDate: _dateBorrowed,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
      onDateTimeSelected: (date, time) {
        if (date != _dateBorrowed) {
          setState(() {
            _dateBorrowed = date;
            if (_expectedRepaymentDate.isBefore(_dateBorrowed.add(const Duration(days: 1)))) {
              _expectedRepaymentDate = _dateBorrowed.add(const Duration(days: 30));
            }
          });
        }
      },
      title: l10n.selectBorrowedDate,
      minDate: DateTime.now().subtract(const Duration(days: 365)),
      maxDate: DateTime.now(),
      showTimeInline: false,
    );
  }

  Future<void> _selectExpectedRepaymentDate() async {
    final l10n = AppLocalizations.of(context)!;

    await context.showSyncfusionDateTimePicker(
      initialDate: _expectedRepaymentDate,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
      onDateTimeSelected: (date, time) {
        if (date != _expectedRepaymentDate) {
          setState(() {
            _expectedRepaymentDate = date;
          });
        }
      },
      title: l10n.selectExpectedRepaymentDate,
      minDate: _dateBorrowed.add(const Duration(days: 1)),
      maxDate: DateTime.now().add(const Duration(days: 365)),
      showTimeInline: false,
    );
  }

  double get balanceRemaining {
    final amountBorrowed = double.tryParse(_amountBorrowedController.text) ?? 0;
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
    return amountBorrowed - amountPaid;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 95.w, small: 85.w, medium: 75.w, large: 65.w, ultrawide: 55.w),
                  maxHeight: 85.h,
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
                  ],
                ),
                child: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: _buildTabletLayout(),
                  small: _buildMobileLayout(),
                  medium: _buildDesktopLayout(),
                  large: _buildDesktopLayout(),
                  ultrawide: _buildDesktopLayout(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(child: SingleChildScrollView(child: _buildFormContent(isCompact: true))),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(child: SingleChildScrollView(child: _buildFormContent(isCompact: true))),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Flexible(child: SingleChildScrollView(child: _buildFormContent(isCompact: false))),
      ],
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Icon(Icons.edit_outlined, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout ? l10n.editPayable : l10n.editPayableDetails,
                  style: TextStyle(
                    fontSize: context.headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!context.isTablet) ...[
                  SizedBox(height: context.smallPadding / 2),
                  Text(
                    l10n.updatePayableInformation,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.pureWhite.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Text(
              widget.payable.id,
              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
            ),
          ),
          SizedBox(width: context.smallPadding),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleCancel,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding),
                child: Icon(Icons.close_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent({required bool isCompact}) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumTextField(
              label: l10n.creditorName,
              hint: isCompact ? l10n.enterName : l10n.enterCreditorFullName,
              controller: _creditorNameController,
              prefixIcon: Icons.business_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) return l10n.pleaseEnterCreditorName;
                if (value!.length < 2) return l10n.nameMustBeAtLeast2Characters;
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: l10n.phone,
              hint: isCompact ? l10n.enterPhone : l10n.enterPhoneNumberWithFormat,
              controller: _creditorPhoneController,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) return l10n.pleaseEnterPhoneNumber;
                if (value!.length < 10) return l10n.pleaseEnterAValidPhoneNumber;
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: l10n.emailOptional,
              hint: isCompact ? l10n.enterEmail : l10n.enterCreditorEmail,
              controller: _creditorEmailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: context.cardPadding),
            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: l10n.amountBorrowedPKR,
                    hint: l10n.enterAmount,
                    controller: _amountBorrowedController,
                    prefixIcon: Icons.trending_down_rounded,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return l10n.pleaseEnterAmount;
                      final amount = double.tryParse(value!);
                      if (amount == null || amount <= 0) return l10n.pleaseEnterValidAmount;
                      return null;
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumTextField(
                    label: l10n.additionalAmountToPayPKR,
                    hint: l10n.enterAdditionalAmount,
                    controller: _amountPaidController,
                    prefixIcon: Icons.trending_up_rounded,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {}),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final additionalAmount = double.tryParse(value);
                        if (additionalAmount == null || additionalAmount < 0) return l10n.enterValidAmount;
                        final currentPaid = widget.payable.amountPaid;
                        final amountBorrowed = double.tryParse(_amountBorrowedController.text) ?? 0;
                        if (currentPaid + additionalAmount > amountBorrowed) return l10n.totalPaymentCannotExceedAmountBorrowed;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (_amountBorrowedController.text.isNotEmpty || _amountPaidController.text.isNotEmpty) ...[
              SizedBox(height: context.cardPadding),
              Container(
                padding: EdgeInsets.all(context.cardPadding),
                decoration: BoxDecoration(
                  color: balanceRemaining >= 0 ? Colors.orange.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  border: Border.all(color: balanceRemaining >= 0 ? Colors.orange.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calculate_rounded, color: balanceRemaining >= 0 ? Colors.orange : Colors.red, size: context.iconSize('medium')),
                        SizedBox(width: context.smallPadding),
                        Text(
                          l10n.paymentSummary,
                          style: TextStyle(
                            fontSize: context.bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: balanceRemaining >= 0 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.smallPadding),
                    Text(
                      '${l10n.currentPaid}: PKR ${widget.payable.amountPaid.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: context.bodyFontSize - 2, color: Colors.grey[600]),
                    ),
                    Text(
                      '${l10n.additionalPayment}: PKR ${(double.tryParse(_amountPaidController.text) ?? 0.0).toStringAsFixed(0)}',
                      style: TextStyle(fontSize: context.bodyFontSize - 2, color: Colors.grey[600]),
                    ),
                    Text(
                      '${l10n.totalAfterUpdate}: PKR ${(widget.payable.amountPaid + (double.tryParse(_amountPaidController.text) ?? 0.0)).toStringAsFixed(0)}',
                      style: TextStyle(fontSize: context.bodyFontSize - 2, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                    ),
                    Text(
                      '${l10n.balanceRemaining}: PKR ${balanceRemaining.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: balanceRemaining >= 0 ? Colors.orange : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: l10n.reasonItem,
              hint: isCompact ? l10n.reasonForBorrowing : l10n.enterReasonForBorrowingOrItemDescription,
              controller: _reasonController,
              prefixIcon: Icons.assignment_outlined,
              maxLines: ResponsiveBreakpoints.responsive(context, tablet: 2, small: 3, medium: 4, large: 5, ultrawide: 6),
              validator: (value) {
                if (value?.isEmpty ?? true) return l10n.pleaseEnterReasonOrItem;
                if (value!.length < 5) return l10n.pleaseProvideMoreDetails;
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),
            PremiumTextField(
              label: l10n.notesOptional,
              hint: isCompact ? l10n.additionalNotes : l10n.enterAdditionalNotesOrTerms,
              controller: _notesController,
              prefixIcon: Icons.note_outlined,
              maxLines: ResponsiveBreakpoints.responsive(context, tablet: 3, small: 3, medium: 4, large: 4, ultrawide: 4),
            ),
            SizedBox(height: context.cardPadding),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDateBorrowed,
                    child: PremiumTextField(
                      label: l10n.dateBorrowed,
                      hint: l10n.selectDate,
                      controller: TextEditingController(text: '${_dateBorrowed.day}/${_dateBorrowed.month}/${_dateBorrowed.year}'),
                      prefixIcon: Icons.calendar_today,
                      enabled: false,
                    ),
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectExpectedRepaymentDate,
                    child: PremiumTextField(
                      label: l10n.expectedRepaymentDate,
                      hint: l10n.selectDate,
                      controller: TextEditingController(
                        text: '${_expectedRepaymentDate.day}/${_expectedRepaymentDate.month}/${_expectedRepaymentDate.year}',
                      ),
                      prefixIcon: Icons.event_available,
                      enabled: false,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.mainPadding),
            ResponsiveBreakpoints.responsive(
              context,
              tablet: _buildCompactButtons(),
              small: _buildCompactButtons(),
              medium: _buildDesktopButtons(),
              large: _buildDesktopButtons(),
              ultrawide: _buildDesktopButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<PayablesProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.updatePayable,
              onPressed: provider.isLoading ? null : _handleUpdate,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.save_rounded,
              backgroundColor: AppTheme.primaryMaroon,
            );
          },
        ),
        SizedBox(height: context.cardPadding),
        PremiumButton(
          text: l10n.cancel,
          onPressed: _handleCancel,
          isOutlined: true,
          height: context.buttonHeight,
          backgroundColor: Colors.grey[600],
          textColor: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildDesktopButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: PremiumButton(
            text: l10n.cancel,
            onPressed: _handleCancel,
            isOutlined: true,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: Colors.grey[600],
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: Consumer<PayablesProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.updatePayable,
                onPressed: provider.isLoading ? null : _handleUpdate,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.save_rounded,
                backgroundColor: AppTheme.primaryMaroon,
              );
            },
          ),
        ),
      ],
    );
  }
}
