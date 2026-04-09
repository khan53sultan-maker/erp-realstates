import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/drop_down.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../../../l10n/app_localizations.dart';

class EditProductDialog extends StatefulWidget {
  final ProductModel product;

  const EditProductDialog({super.key, required this.product});

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _detailController;
  late TextEditingController _priceController;
  late TextEditingController _costPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _colorController;
  late TextEditingController _fabricController;

  late String? _selectedCategoryId;
  late List<String> _selectedPieces;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _detailController = TextEditingController(text: widget.product.detail);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _costPriceController = TextEditingController(text: widget.product.costPrice?.toString() ?? '');
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _colorController = TextEditingController(text: widget.product.color);
    _fabricController = TextEditingController(text: widget.product.fabric);

    _selectedCategoryId = widget.product.categoryId;
    _selectedPieces = List.from(widget.product.pieces);

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoriesAndSetSelected();
    });
  }

  Future<void> _loadCategoriesAndSetSelected() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);

    if (provider.categories.isEmpty) {
      await provider.loadCategories();
    }

    if (mounted) {
      _setSelectedCategory();
    }
  }

  void _setSelectedCategory() {
    final provider = Provider.of<ProductProvider>(context, listen: false);

    if (provider.categories.isEmpty) {
      print('🚨 No categories available');
      return;
    }

    print('🔍 Looking for category. Product categoryId: ${widget.product.categoryId}, categoryName: ${widget.product.categoryName}');
    print('📝 Available categories: ${provider.categories.map((c) => '${c.name} (${c.id})').join(', ')}');

    String? foundCategoryId;

    if (widget.product.categoryId != null && widget.product.categoryId!.isNotEmpty) {
      final categoryExists = provider.categories.any((cat) => cat.id == widget.product.categoryId && cat.isActive);

      if (categoryExists) {
        foundCategoryId = widget.product.categoryId;
        print('✅ Found category by ID: $foundCategoryId');
      }
    }

    if (foundCategoryId == null && widget.product.categoryName != null && widget.product.categoryName!.isNotEmpty) {
      try {
        final categoryByName = provider.categories.firstWhere(
              (cat) => cat.name.toLowerCase() == widget.product.categoryName!.toLowerCase() && cat.isActive,
        );
        foundCategoryId = categoryByName.id;
        print('✅ Found category by name: ${widget.product.categoryName} -> $foundCategoryId');
      } catch (e) {
        print('❌ Could not find category by name: ${widget.product.categoryName}');
      }
    }

    if (foundCategoryId == null && provider.categories.isNotEmpty) {
      final firstActiveCategory = provider.categories.firstWhere((cat) => cat.isActive, orElse: () => provider.categories.first);
      foundCategoryId = firstActiveCategory.id;
      print('⚠️ Using default category: ${firstActiveCategory.name} -> $foundCategoryId');
    }

    if (foundCategoryId != null && _selectedCategoryId != foundCategoryId) {
      setState(() {
        _selectedCategoryId = foundCategoryId;
      });
      print('🔄 Updated selected category to: $foundCategoryId');
    } else {
      print('ℹ️ Selected category unchanged: $_selectedCategoryId');
    }
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
    _fabricController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedPieces.isEmpty) {
        _showErrorSnackbar(l10n.pleaseSelectAtLeastOnePiece);
        return;
      }

      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      final success = await productProvider.updateProduct(
        id: widget.product.id,
        name: _nameController.text.trim(),
        detail: _detailController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        costPrice: _costPriceController.text.trim().isNotEmpty
            ? double.parse(_costPriceController.text.trim())
            : null,
        color: _colorController.text.trim(),
        fabric: _fabricController.text.trim(),
        pieces: _selectedPieces,
        quantity: int.parse(_quantityController.text.trim()),
        categoryId: _selectedCategoryId,
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(productProvider.errorMessage ?? l10n.failedToUpdateProduct);
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
              l10n.productUpdatedSuccessfully,
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
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 95.w, small: 90.w, medium: 80.w, large: 70.w, ultrawide: 60.w),
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
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [_buildHeader(), _buildFormContent()]),
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
        gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
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
                  context.shouldShowCompactLayout ? l10n.editProduct : l10n.editProductDetails,
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
                    l10n.updateProductInformation,
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
              widget.product.id,
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

  Widget _buildFormContent() {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.all(context.cardPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumTextField(
              label: l10n.productName,
              hint: context.shouldShowCompactLayout ? l10n.enterName : l10n.enterProductName,
              controller: _nameController,
              prefixIcon: Icons.label_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterProductName;
                }
                if (value!.length < 2) {
                  return l10n.productNameMustBeAtLeast2Characters;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.productDetail,
              hint: context.shouldShowCompactLayout ? l10n.enterDetails : l10n.enterProductDescriptionDetails,
              controller: _detailController,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterProductDetails;
                }
                if (value!.length < 5) {
                  return l10n.productDetailMustBeAtLeast5Characters;
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
                    hint: context.shouldShowCompactLayout ? l10n.enterPrice : l10n.enterPricePkr,
                    controller: _priceController,
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return l10n.pleaseEnterPrice;
                      }
                      final price = double.tryParse(value!);
                      if (price == null || price <= 0) {
                        return l10n.pleaseEnterValidPrice;
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: context.cardPadding),
                Expanded(
                  child: PremiumTextField(
                    label: l10n.costPrice,
                    hint: context.shouldShowCompactLayout ? l10n.enterCost : l10n.enterCostPricePkrOptional,
                    controller: _costPriceController,
                    prefixIcon: Icons.shopping_cart_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isNotEmpty ?? false) {
                        final costPrice = double.tryParse(value!);
                        if (costPrice == null || costPrice < 0) {
                          return l10n.pleaseEnterValidCostPrice;
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
            if (widget.product.costPrice == null) ...[
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
            ],
            SizedBox(height: context.cardPadding),

            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    label: l10n.quantity,
                    hint: context.shouldShowCompactLayout ? l10n.enterQty : l10n.enterQuantity,
                    controller: _quantityController,
                    prefixIcon: Icons.inventory_2_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return l10n.pleaseEnterQuantity;
                      }
                      final quantity = int.tryParse(value!);
                      if (quantity == null || quantity < 0) {
                        return l10n.pleaseEnterValidQuantity;
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

            Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.categories.isEmpty && provider.isLoading) {
                  return Container(
                    padding: EdgeInsets.all(context.cardPadding),
                    child: Row(
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryMaroon)),
                        SizedBox(width: context.smallPadding),
                        Text(
                          l10n.loadingCategories,
                          style: TextStyle(fontSize: context.bodyFontSize, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.categories.isEmpty && !provider.isLoading) {
                  return Container(
                    padding: EdgeInsets.all(context.cardPadding),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(context.borderRadius()),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_outlined, color: Colors.orange),
                        SizedBox(width: context.smallPadding),
                        Expanded(
                          child: Text(
                            l10n.noCategoriesAvailablePleaseAddCategoriesFirst,
                            style: TextStyle(fontSize: context.bodyFontSize, color: Colors.orange[700]),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                print('🎯 Rendering dropdown. Selected: $_selectedCategoryId');
                print('📋 Available categories: ${provider.categories.map((c) => '${c.name}(${c.id})').join(', ')}');

                final activeCategories = provider.categories.where((category) => category.isActive).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.product.categoryName != null) ...[
                      Container(
                        padding: EdgeInsets.all(context.smallPadding),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(context.borderRadius('small')),
                        ),
                        child: Text(
                          '${l10n.productCategory}: ${widget.product.categoryName} ${widget.product.categoryId != null ? '(ID: ${widget.product.categoryId})' : '(${l10n.noId})'}',
                          style: TextStyle(fontSize: context.captionFontSize, color: Colors.blue[700]),
                        ),
                      ),
                      SizedBox(height: context.smallPadding),
                    ],

                    PremiumDropdownField<String>(
                      label: l10n.category,
                      hint: context.shouldShowCompactLayout ? l10n.selectCategory : l10n.selectProductCategory,
                      prefixIcon: Icons.category_outlined,
                      items: activeCategories.map((category) => DropdownItem<String>(value: category.id, label: category.name)).toList(),
                      value: _selectedCategoryId,
                      onChanged: (categoryId) {
                        print('🔄 Category changed to: $categoryId');
                        setState(() {
                          _selectedCategoryId = categoryId;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return l10n.pleaseSelectCategory;
                        }
                        return null;
                      },
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.color,
              hint: context.shouldShowCompactLayout ? l10n.enterColor : l10n.enterColorName,
              controller: _colorController,
              prefixIcon: Icons.color_lens_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterColor;
                }
                if (value!.length < 2) {
                  return l10n.colorNameMustBeAtLeast2Characters;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

            PremiumTextField(
              label: l10n.fabric,
              hint: context.shouldShowCompactLayout ? l10n.enterFabric : l10n.enterFabricType,
              controller: _fabricController,
              prefixIcon: Icons.texture_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return l10n.pleaseEnterFabric;
                }
                if (value!.length < 2) {
                  return l10n.fabricNameMustBeAtLeast2Characters;
                }
                return null;
              },
            ),
            SizedBox(height: context.cardPadding),

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
                            selectedColor: Colors.blue,
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
              text: l10n.updateProduct,
              onPressed: provider.isLoading ? null : _handleUpdate,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.save_rounded,
              backgroundColor: Colors.blue,
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
                text: l10n.updateProduct,
                onPressed: provider.isLoading ? null : _handleUpdate,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.save_rounded,
                backgroundColor: Colors.blue,
              );
            },
          ),
        ),
      ],
    );
  }
}
