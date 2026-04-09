import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class EnhancedAddVendorDialog extends StatefulWidget {
  const EnhancedAddVendorDialog({super.key});

  @override
  State<EnhancedAddVendorDialog> createState() => _EnhancedAddVendorDialogState();
}

class _EnhancedAddVendorDialogState extends State<EnhancedAddVendorDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _cnicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Validation errors
  Map<String, String> _validationErrors = {};

  // Options
  final List<String> _commonCities = [
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Faisalabad',
    'Multan',
    'Peshawar',
    'Quetta',
  ];
  final List<String> _commonAreas = [
    'Gulshan',
    'Clifton',
    'DHA',
    'Johar Town',
    'Model Town',
    'F-7',
    'Blue Area',
    'Saddar',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _businessNameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final provider = Provider.of<VendorProvider>(context, listen: false);

    _validationErrors = provider.validateVendorData(
      name: _nameController.text,
      businessName: _businessNameController.text,
      cnic: _cnicController.text.trim().isEmpty ? null : _cnicController.text,
      phone: _phoneController.text,
      city: _cityController.text,
      area: _areaController.text,
    );

    setState(() {});
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Additional validation using provider
      _validateForm();

      if (_validationErrors.isNotEmpty) {
        _showValidationErrors();
        return;
      }

      final provider = Provider.of<VendorProvider>(context, listen: false);

      final success = await provider.addVendor(
        name: _nameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        cnic: _cnicController.text.trim().isEmpty
            ? null
            : _cnicController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(provider.errorMessage ?? 'Failed to add vendor');
        }
      }
    }
  }

  void _showValidationErrors() {
    final l10n = AppLocalizations.of(context)!;
    final errorMessages = _validationErrors.values.join('\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                '${l10n.pleaseFixErrors}:\n$errorMessages',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
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
              '${l10n.vendor} ${l10n.success}!',
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.pureWhite,
              ),
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
            Icon(Icons.error_outline, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
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
                  maxWidth: ResponsiveBreakpoints.responsive(
                    context,
                    tablet: 90.w,
                    small: 85.w,
                    medium: 75.w,
                    large: 65.w,
                    ultrawide: 55.w,
                  ),
                  maxHeight: 90.h,
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: context.shadowBlur('heavy'),
                      offset: Offset(0, context.cardPadding),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(child: _buildFormContent()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Icon(Icons.store_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout
                      ? '${l10n.add} ${l10n.vendor}'
                      : '${l10n.add} ${l10n.newCustomer} ${l10n.vendor}',
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
                    '${l10n.createOrder} ${l10n.vendor} ${l10n.profile}',
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

  Widget _buildFormContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(context.cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information Section
              _buildBasicInfoSection(),
              SizedBox(height: context.cardPadding),

              // Contact Information Section
              _buildContactInfoSection(),
              SizedBox(height: context.cardPadding),

              // Location Information Section
              _buildLocationInfoSection(),
              SizedBox(height: context.mainPadding),

              // Action Buttons
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
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.basicInformation, Icons.info_outline),
        SizedBox(height: context.cardPadding),

        // Vendor Name
        PremiumTextField(
          label: '${l10n.vendor} ${l10n.name} *',
          hint: context.shouldShowCompactLayout
              ? l10n.enterVendorName
              : '${l10n.enterVendorName} ${l10n.fullName}',
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return '${l10n.pleaseEnter} ${l10n.vendor} ${l10n.name}';
            }
            if (value!.length < 2) {
              return '${l10n.name} ${l10n.mustBeAtLeast} 2 ${l10n.characters}';
            }
            if (value.length > 100) {
              return '${l10n.name} ${l10n.mustBeLessThan} 100 ${l10n.characters}';
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),

        // Business Name
        PremiumTextField(
          label: '${l10n.businessName} *',
          hint: context.shouldShowCompactLayout
              ? l10n.enterBusinessName
              : l10n.enterBusinessName,
          controller: _businessNameController,
          prefixIcon: Icons.business_outlined,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return '${l10n.pleaseEnter} ${l10n.businessName}';
            }
            if (value!.length < 2) {
              return '${l10n.businessName} ${l10n.mustBeAtLeast} 2 ${l10n.characters}';
            }
            if (value.length > 200) {
              return '${l10n.businessName} ${l10n.mustBeLessThan} 200 ${l10n.characters}';
            }
            return null;
          },
        ),
        SizedBox(height: context.cardPadding),

        // CNIC
        PremiumTextField(
          label: l10n.cnic,
          hint: context.shouldShowCompactLayout
              ? '${l10n.enterCnicNumber} (${l10n.optional})'
              : '${l10n.enterCnicNumber} (${l10n.cnicFormat}) - ${l10n.optional}',
          controller: _cnicController,
          prefixIcon: Icons.credit_card,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(value)) {
                return '${l10n.pleaseEnterValid} ${l10n.cnic} (${l10n.cnicFormat})';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
        SizedBox(width: context.smallPadding),
        Text(
          title,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.charcoalGray,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSelectChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.borderRadius('small')),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
        decoration: BoxDecoration(
          color: AppTheme.accentGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: context.captionFontSize,
            fontWeight: FontWeight.w500,
            color: AppTheme.accentGold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<VendorProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: '${l10n.add} ${l10n.vendor}',
              onPressed: provider.isLoading ? null : _handleSubmit,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.add_rounded,
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
          flex: 2,
          child: Consumer<VendorProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: '${l10n.add} ${l10n.vendor}',
                onPressed: provider.isLoading ? null : _handleSubmit,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.add_rounded,
                backgroundColor: AppTheme.primaryMaroon,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.contactInformation, Icons.contact_phone_outlined),
        SizedBox(height: context.cardPadding),

        // Phone Number
        PremiumTextField(
          label: '${l10n.phone} *',
          hint: context.shouldShowCompactLayout
              ? l10n.enterPhoneWithCode
              : '${l10n.enterPhoneWithCode} (${l10n.phoneFormat})',
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return '${l10n.pleaseEnter} ${l10n.phone}';
            }
            if (value!.length < 10) {
              return '${l10n.pleaseEnterValid} ${l10n.phone}';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(l10n.locationInformation, Icons.location_on_outlined),
        SizedBox(height: context.cardPadding),

        // City and Area Row/Column
        ResponsiveBreakpoints.responsive(
          context,
          tablet: _buildCityAreaColumn(),
          small: _buildCityAreaColumn(),
          medium: _buildCityAreaRow(),
          large: _buildCityAreaRow(),
          ultrawide: _buildCityAreaRow(),
        ),
      ],
    );
  }

  Widget _buildCityAreaRow() {
    return Row(
      children: [
        Expanded(child: _buildCityField()),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildAreaField()),
      ],
    );
  }

  Widget _buildCityAreaColumn() {
    return Column(
      children: [
        _buildCityField(),
        SizedBox(height: context.cardPadding),
        _buildAreaField(),
      ],
    );
  }

  Widget _buildCityField() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumTextField(
          label: '${l10n.city} *',
          hint: l10n.enterCity,
          controller: _cityController,
          prefixIcon: Icons.location_city_outlined,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return '${l10n.pleaseEnter} ${l10n.city}';
            }
            return null;
          },
        ),
        SizedBox(height: context.smallPadding),
        Wrap(
          spacing: context.smallPadding / 2,
          runSpacing: context.smallPadding / 4,
          children: _commonCities
              .take(4)
              .map(
                (city) => _buildQuickSelectChip(
              label: city,
              onTap: () => setState(() => _cityController.text = city),
            ),
          )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAreaField() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumTextField(
          label: '${l10n.area} *',
          hint: l10n.enterArea,
          controller: _areaController,
          prefixIcon: Icons.map_outlined,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return '${l10n.pleaseEnter} ${l10n.area}';
            }
            return null;
          },
        ),
        SizedBox(height: context.smallPadding),
        Wrap(
          spacing: context.smallPadding / 2,
          runSpacing: context.smallPadding / 4,
          children: _commonAreas
              .take(4)
              .map(
                (area) => _buildQuickSelectChip(
              label: area,
              onTap: () => setState(() => _areaController.text = area),
            ),
          )
              .toList(),
        ),
      ],
    );
  }
}
