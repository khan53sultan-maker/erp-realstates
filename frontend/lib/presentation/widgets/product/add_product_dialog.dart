import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/drop_down.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _colorController = TextEditingController();
  final _typeController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _skuController = TextEditingController();

  String? _selectedCategoryId;
  List<String> _selectedPieces = [];

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _detailController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _quantityController.dispose();
    _colorController.dispose();
    _typeController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (_colorController.text.trim().isEmpty) {
        _showErrorSnackbar('${l10n.pleaseEnter} ${l10n.color}');
        return;
      }
      if (_typeController.text.trim().isEmpty) {
        _showErrorSnackbar('${l10n.pleaseEnter} ${l10n.type}');
        return;
      }
      if (_selectedCategoryId == null) {
        _showErrorSnackbar('${l10n.pleaseSelect} ${l10n.category}');
        return;
      }
      if (_selectedPieces.isEmpty) {
        _showErrorSnackbar(l10n.pleaseSelectAtLeastOnePiece);
        return;
      }

      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      final success = await productProvider.addProduct(
        name: _nameController.text.trim(),
        detail: _detailController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        costPrice: _costPriceController.text.trim().isNotEmpty
            ? double.parse(_costPriceController.text.trim())
            : null,
        color: _colorController.text.trim(),
        fabric: _typeController.text.trim(),
        pieces: _selectedPieces,
        quantity: int.parse(_quantityController.text.trim()),
        categoryId: _selectedCategoryId!,
        barcode: _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null,
        sku: _skuController.text.trim().isNotEmpty ? _skuController.text.trim() : null,
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(productProvider.errorMessage ?? '${l10n.failedToAdd} ${l10n.product}');
        }
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
              '${l10n.product} ${l10n.addedSuccessfully}!',
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
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
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
          backgroundColor: Colors.black.withOpacity(0.5 * (_fadeAnimation.value.clamp(0.0, 1.0))),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value.clamp(0.1, 2.0),
              child: Container(
                width: context.dialogWidth ?? 600,
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
            child: Icon(Icons.inventory_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout
                      ? '${l10n.add} ${l10n.product}'
                      : '${l10n.add} ${l10n.newProduct}',
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
                    l10n.createNewProductEntry,
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
            PremiumTextField(
              label: '${l10n.product} ${l10n.name}',
              hint: isCompact ? '${l10n.enterEmail} ${l10n.name}' : '${l10n.enterEmail} ${l10n.product} ${l10n.name}',
              controller: _nameController,
              prefixIcon: Icons.label_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '${l10n.pleaseEnter} ${l10n.product} ${l10n.name}';
                }
                if (value!.length < 2) {
                  return '${l10n.product} ${l10n.name} ${l10n.mustBeAtLeast} 2 ${l10n.characters}';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: '${l10n.product} ${l10n.detail}',
              hint: isCompact ? '${l10n.enterEmail} ${l10n.details}' : '${l10n.enterEmail} ${l10n.product} ${l10n.description}',
              controller: _detailController,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '${l10n.pleaseEnter} ${l10n.product} ${l10n.details}';
                }
                if (value!.length < 5) {
                  return '${l10n.product} ${l10n.detail} ${l10n.mustBeAtLeast} 5 ${l10n.characters}';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: l10n.price,
                    hint: isCompact ? '${l10n.enterEmail} ${l10n.price}' : '${l10n.enterEmail} ${l10n.price} (PKR)',
                    controller: _priceController,
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return '${l10n.pleaseEnter} ${l10n.price}';
                      }
                      final price = double.tryParse(value!);
                      if (price == null || price <= 0) {
                        return '${l10n.pleaseEnterValid} ${l10n.price}';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumTextField(
                    label: l10n.costPrice,
                    hint: isCompact ? '${l10n.enterEmail} ${l10n.cost}' : '${l10n.enterEmail} ${l10n.costPrice} (PKR) - ${l10n.optional}',
                    controller: _costPriceController,
                    prefixIcon: Icons.shopping_cart_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isNotEmpty ?? false) {
                        final costPrice = double.tryParse(value!);
                        if (costPrice == null || costPrice < 0) {
                          return '${l10n.pleaseEnterValid} ${l10n.costPrice}';
                        }
                        final price = double.tryParse(_priceController.text);
                        if (price != null && costPrice > price) {
                          return l10n.costPriceCannotExceedSellingPrice;
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: context.smallPadding / 2),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 3),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: context.iconSize('small'), color: Colors.blue[700]),
                  SizedBox(width: context.smallPadding / 2),
                  Flexible(
                    child: Text(
                      l10n.costPriceInfo,
                      style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.cardPadding),

            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: l10n.quantity,
                    hint: isCompact ? '${l10n.enterEmail} ${l10n.qty}' : '${l10n.enterEmail} ${l10n.quantity}',
                    controller: _quantityController,
                    prefixIcon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return '${l10n.pleaseEnter} ${l10n.quantity}';
                      }
                      final quantity = int.tryParse(value!);
                      if (quantity == null || quantity < 0) {
                        return '${l10n.pleaseEnterValid} ${l10n.quantity}';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(child: Container()),
              ],
            ),
            SizedBox(height: context.cardPadding),

            // Category Selection
            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                return PremiumDropdownField<String>(
                  label: l10n.category,
                  hint: isCompact ? '${l10n.select} ${l10n.category}' : '${l10n.select} ${l10n.product} ${l10n.category}',
                  prefixIcon: Icons.category_outlined,
                  items: provider.categories
                      .where((category) => category.isActive)
                      .map((category) => DropdownItem<String>(value: category.id, label: category.name))
                      .toList(),
                  value: _selectedCategoryId,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return '${l10n.pleaseSelect} ${l10n.category}';
                    }
                    return null;
                  },
                );
              },
            ),
            SizedBox(height: context.cardPadding),

            // Color Input Field
            PremiumTextField(
              label: l10n.color,
              hint: isCompact ? '${l10n.enterEmail} ${l10n.color}' : '${l10n.enterEmail} ${l10n.colorName}',
              controller: _colorController,
              prefixIcon: Icons.color_lens_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '${l10n.pleaseEnter} ${l10n.color}';
                }
                if (value!.length < 2) {
                  return '${l10n.colorName} ${l10n.mustBeAtLeast} 2 ${l10n.characters}';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            // Type Input Field
            PremiumTextField(
              label: l10n.type,
              hint: isCompact ? '${l10n.enterEmail} ${l10n.type}' : '${l10n.enterEmail} ${l10n.product} ${l10n.type}',
              controller: _typeController,
              prefixIcon: Icons.category_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return '${l10n.pleaseEnter} ${l10n.type}';
                }
                if (value!.length < 2) {
                  return '${l10n.type} ${l10n.mustBeAtLeast} 2 ${l10n.characters}';
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            // Barcode and SKU Fields
            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: 'Barcode',
                    hint: 'Enter barcode (optional)',
                    controller: _barcodeController,
                    prefixIcon: Icons.qr_code_2_outlined,
                    validator: (value) {
                      // Barcode is optional, no validation required
                      return null;
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumTextField(
                    label: 'SKU',
                    hint: 'Enter SKU (optional)',
                    controller: _skuController,
                    prefixIcon: Icons.tag_outlined,
                    validator: (value) {
                      // SKU is optional, no validation required
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: context.cardPadding),

            // Pieces Selection
            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pieces,
                      style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                    ),
                    SizedBox(height: context.smallPadding),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(context.cardPadding),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(context.borderRadius()),
                      ),
                      child: Wrap(
                        spacing: context.smallPadding,
                        runSpacing: context.smallPadding,
                        children: provider.availablePieces.map((piece) {
                          final isSelected = _selectedPieces.contains(piece);
                          return FilterChip(
                            label: Text(
                              piece,
                              style: TextStyle(
                                fontSize: context.captionFontSize,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? AppTheme.pureWhite : AppTheme.charcoalGray,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedPieces.add(piece);
                                } else {
                                  _selectedPieces.remove(piece);
                                }
                              });
                            },
                            selectedColor: AppTheme.primaryMaroon,
                            checkmarkColor: AppTheme.pureWhite,
                            backgroundColor: AppTheme.lightGray,
                          );
                        }).toList(),
                      ),
                    ),
                    if (_selectedPieces.isEmpty) ...[
                      SizedBox(height: context.smallPadding / 2),
                      Text(
                        l10n.pleaseSelectAtLeastOnePiece,
                        style: TextStyle(fontSize: context.captionFontSize, color: Colors.red),
                      ),
                    ],
                  ],
                );
              },
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
        Consumer<ProductProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: '${l10n.add} ${l10n.product}',
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
          child: Consumer<ProductProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: '${l10n.add} ${l10n.product}',
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
