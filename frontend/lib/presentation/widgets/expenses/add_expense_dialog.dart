import 'package:flutter/material.dart';
import 'package:frontend/presentation/widgets/globals/custom_date_picker.dart';
import 'package:frontend/presentation/widgets/globals/drop_down.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/expenses/expenses_model.dart';
import '../../../src/providers/expenses_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../../../src/providers/real_estate_provider.dart';
import '../../../src/models/real_estate/real_estate_sale_model.dart';
import 'package:intl/intl.dart';

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _expenseController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedWithdrawalBy;
  String? _selectedCategory;
  RealEstateSale? _selectedSale;
  bool _isPersonal = false;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
    
    // Refresh sales in background for the dropdown
    context.read<RealEstateProvider>().fetchSales();

    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _expenseController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedWithdrawalBy == null || _selectedWithdrawalBy!.isEmpty) {
        _showErrorSnackbar(l10n.pleaseSelectWhoMadeWithdrawal);
        return;
      }

      final expensesProvider = Provider.of<ExpensesProvider>(context, listen: false);

      await expensesProvider.addExpense(
        expense: _expenseController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        withdrawalBy: _selectedWithdrawalBy!,
        date: _selectedDate,
        time: _selectedTime,
        category: _selectedCategory,
        saleId: _selectedSale?.id,
        isPersonal: _isPersonal,
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
              l10n.expenseAddedSuccessfully,
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
    if (_animationController.isCompleted) {
      _animationController.reverse().then((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showCustomNameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Custom Name'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _selectedWithdrawalBy = controller.text);
              }
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final l10n = AppLocalizations.of(context)!;

    await context.showSyncfusionDateTimePicker(
      initialDate: _selectedDate,
      initialTime: _selectedTime,
      title: l10n.selectExpenseDateTime,
      minDate: DateTime(2000),
      maxDate: DateTime.now().add(const Duration(days: 365)),
      onDateTimeSelected: (date, time) {
        setState(() {
          _selectedDate = date;
          _selectedTime = time;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: context.dialogWidth,
                constraints: BoxConstraints(
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 90.w, small: 85.w, medium: 75.w, large: 65.w, ultrawide: 55.w),
                  maxHeight: 90.h,
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
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [_buildHeader(), _buildFormContent(isCompact: true)]),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [_buildHeader(), _buildFormContent(isCompact: true)]),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [_buildHeader(), _buildFormContent(isCompact: false)]),
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
            child: Icon(Icons.receipt_long_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout ? l10n.addExpense : l10n.addNewExpense,
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
                    l10n.recordNewExpenseEntry,
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
            PremiumDropdownField<String>(
              label: 'Expense Category',
              hint: 'Select Category',
              value: _selectedCategory,
              prefixIcon: Icons.grid_view_rounded,
              items: [
                DropdownItem(value: 'LANDOWNER_PAYOUT', label: 'Landowner Payout'),
                DropdownItem(value: 'OFFICE_RENT', label: 'Office Rent'),
                DropdownItem(value: 'SALARY', label: 'Salary'),
                DropdownItem(value: 'MARKETING', label: 'Marketing'),
                DropdownItem(value: 'UTILITY', label: 'Utility'),
                DropdownItem(value: 'COMMISSION_PAID', label: 'Commission Paid'),
                DropdownItem(value: 'MISC', label: 'Misc Expenses'),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                  if (val == 'LANDOWNER_PAYOUT') {
                    _expenseController.text = 'Landowner Payout';
                    _isPersonal = false;
                  } else if (val != null) {
                    if (_expenseController.text.isEmpty || _expenseController.text == 'Landowner Payout') {
                       _expenseController.text = val.replaceAll('_', ' ').toLowerCase().split(' ').map((s) => s[0].toUpperCase() + s.substring(1)).join(' ');
                    }
                  }
                });
              },
            ),
            if (_selectedCategory == 'LANDOWNER_PAYOUT' || _selectedCategory == 'COMMISSION_PAID') ...[
              SizedBox(height: context.cardPadding),
              Consumer<RealEstateProvider>(
                builder: (context, reProvider, child) {
                  if (reProvider.sales.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('No plots/sales found.', style: TextStyle(color: Colors.red)),
                    );
                  }
                  return PremiumDropdownField<RealEstateSale>(
                    label: 'Select Plot / Sale',
                    hint: _selectedCategory == 'LANDOWNER_PAYOUT' ? 'Choose plot for payout' : 'Choose plot for commission',
                    value: _selectedSale,
                    prefixIcon: Icons.landscape_rounded,
                    items: reProvider.sales.map((sale) => DropdownItem<RealEstateSale>(
                      value: sale,
                      label: '${sale.plotNumber ?? "No #"} - ${sale.customerName ?? "Unknown"} (${sale.projectName ?? "No Project"})',
                    )).toList(),
                    onChanged: (sale) {
                      setState(() {
                        _selectedSale = sale;
                        if (sale != null) {
                          _descriptionController.text = _selectedCategory == 'LANDOWNER_PAYOUT'
                            ? 'Landowner payout for Plot ${sale.plotNumber} - ${sale.customerName}'
                            : 'Dealer commission for Plot ${sale.plotNumber} - ${sale.dealerName ?? sale.customerName}';
                        }
                      });
                    },
                    validator: (val) => val == null ? 'Please select a sale' : null,
                  );
                },
              ),
              if (_selectedSale != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Builder(
                    builder: (context) {
                      final amountTyped = double.tryParse(_amountController.text) ?? 0;
                      double liveRemaining;
                      String label;
                      
                      if (_selectedCategory == 'LANDOWNER_PAYOUT') {
                        liveRemaining = _selectedSale!.landownerShareRemaining - amountTyped;
                        label = 'Landowner Remaining';
                      } else {
                        liveRemaining = _selectedSale!.dealerCommissionRemaining - amountTyped;
                        label = 'Dealer Remaining';
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (liveRemaining < 0 ? Colors.red : Colors.orange).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: (liveRemaining < 0 ? Colors.red : Colors.orange).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(liveRemaining < 0 ? Icons.warning_amber_rounded : Icons.info_outline, 
                                 color: liveRemaining < 0 ? Colors.red : Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$label: Rs. ${NumberFormat.currency(symbol: '', decimalDigits: 0).format(liveRemaining)}',
                                style: TextStyle(fontWeight: FontWeight.bold, 
                                                 color: liveRemaining < 0 ? Colors.red : Colors.orange, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.expense,
              hint: isCompact ? l10n.enterExpense : l10n.enterExpenseTypeCategory,
              controller: _expenseController,
              prefixIcon: Icons.category_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterExpenseType;
                }
                if (value!.length < 2) {
                  return l10n.expenseMinLength;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.description,
              hint: isCompact ? l10n.enterDescription : l10n.enterExpenseDescription,
              controller: _descriptionController,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterDescription;
                }
                if (value!.length < 5) {
                  return l10n.descriptionMinLength;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.amount,
              hint: isCompact ? l10n.enterAmount : l10n.enterAmountPKR,
              controller: _amountController,
              prefixIcon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterAmount;
                }
                final amount = double.tryParse(value!);
                if (amount == null || amount <= 0) {
                  return l10n.pleaseEnterValidAmount;
                }
                if (_selectedSale != null) {
                  if (_selectedCategory == 'LANDOWNER_PAYOUT' && amount > _selectedSale!.landownerShareRemaining) {
                    return 'Exceeds Landowner remaining share (${NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0).format(_selectedSale!.landownerShareRemaining)})';
                  } else if (_selectedCategory == 'COMMISSION_PAID' && amount > _selectedSale!.dealerCommissionRemaining) {
                    return 'Exceeds Dealer remaining commission (${NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0).format(_selectedSale!.dealerCommissionRemaining)})';
                  }
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            Consumer<ExpensesProvider>(
              builder: (context, provider, child) {
                return Column(
                  children: [
                    PremiumDropdownField<String>(
                      label: l10n.withdrawalBy,
                      hint: l10n.selectWhoMadeWithdrawal,
                      value: provider.availablePersons.contains(_selectedWithdrawalBy) ? _selectedWithdrawalBy : null,
                      prefixIcon: Icons.person_outline,
                      items: [
                        ...provider.availablePersons.map((person) => DropdownItem<String>(value: person, label: person)),
                        if (_isPersonal) DropdownItem<String>(value: 'OTHER', label: 'Other / Personal'),
                      ],
                      onChanged: (person) {
                        if (person == 'OTHER') {
                          _showCustomNameDialog();
                        } else if (person != null) {
                          setState(() {
                            _selectedWithdrawalBy = person;
                          });
                        }
                      },
                      validator: (value) {
                        if (_selectedWithdrawalBy == null || _selectedWithdrawalBy!.isEmpty) {
                          return l10n.pleaseSelectWhoMadeWithdrawal;
                        }
                        return null;
                      },
                    ),
                    if (_isPersonal && _selectedWithdrawalBy != null && !provider.availablePersons.contains(_selectedWithdrawalBy))
                      Padding(
                        padding: EdgeInsets.only(top: context.smallPadding),
                        child: Row(
                          children: [
                            Icon(Icons.edit_note, size: 16, color: AppTheme.primaryMaroon),
                            SizedBox(width: 4),
                            Text(
                              'Withdrawal By: $_selectedWithdrawalBy',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryMaroon),
                            ),
                            IconButton(
                              icon: Icon(Icons.clear, size: 16),
                              onPressed: () => setState(() => _selectedWithdrawalBy = null),
                            )
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: context.cardPadding),

            // Personal Expense Toggle
            Container(
              decoration: BoxDecoration(
                color: _isPersonal ? Colors.purple.withOpacity(0.05) : Colors.transparent,
                borderRadius: BorderRadius.circular(context.borderRadius()),
                border: Border.all(color: _isPersonal ? Colors.purple.withOpacity(0.3) : Colors.grey.shade300),
              ),
              child: SwitchListTile(
                title: Text(
                  'Personal Expense',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: _isPersonal ? Colors.purple : AppTheme.charcoalGray,
                  ),
                ),
                subtitle: Text(
                  'Does not affect business Net Profit',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                secondary: Icon(
                  _isPersonal ? Icons.person_rounded : Icons.business_center_rounded,
                  color: _isPersonal ? Colors.purple : AppTheme.primaryMaroon,
                ),
                value: _isPersonal,
                activeColor: Colors.purple,
                onChanged: (value) {
                  setState(() {
                    _isPersonal = value;
                    // If switching to business, and current withdrawalBy is custom, reset it
                    final provider = context.read<ExpensesProvider>();
                    if (!_isPersonal && _selectedWithdrawalBy != null && !provider.availablePersons.contains(_selectedWithdrawalBy)) {
                      _selectedWithdrawalBy = null;
                    }
                  });
                },
              ),
            ),
            SizedBox(height: context.cardPadding),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _selectDateTime,
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                    child: Container(
                      padding: EdgeInsets.all(context.cardPadding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.primaryMaroon.withOpacity(0.1), AppTheme.secondaryMaroon.withOpacity(0.1)]),
                        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(context.borderRadius()),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.date_range_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
                              SizedBox(width: context.smallPadding),
                              Text(
                                l10n.selectDateTime,
                                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                              ),
                            ],
                          ),
                          SizedBox(height: context.smallPadding),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    l10n.date,
                                    style: TextStyle(
                                      fontSize: context.subtitleFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.charcoalGray.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: TextStyle(
                                      fontSize: context.bodyFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.charcoalGray,
                                    ),
                                  ),
                                ],
                              ),
                              Container(height: 40, width: 1, color: Colors.grey.shade300),
                              Column(
                                children: [
                                  Text(
                                    l10n.time,
                                    style: TextStyle(
                                      fontSize: context.subtitleFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.charcoalGray.withOpacity(0.7),
                                    ),
                                  ),
                                  Text(
                                    _selectedTime.format(context),
                                    style: TextStyle(
                                      fontSize: context.bodyFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.charcoalGray,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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
        Consumer<ExpensesProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.addExpense,
              onPressed: provider.isLoading ? null : _handleSubmit,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.add_rounded,
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
          child: Consumer<ExpensesProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.addExpense,
                onPressed: provider.isLoading ? null : _handleSubmit,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.add_rounded,
              );
            },
          ),
        ),
      ],
    );
  }
}
