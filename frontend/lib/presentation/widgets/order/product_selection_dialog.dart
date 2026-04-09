import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_field.dart';
import '../globals/text_button.dart';

class ProductSelectionDialog extends StatefulWidget {
  final List<String>? excludeProductIds;
  final Function(ProductModel product, int quantity, String? customizationNotes) onProductSelected;

  const ProductSelectionDialog({super.key, this.excludeProductIds, required this.onProductSelected});

  @override
  State<ProductSelectionDialog> createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<ProductSelectionDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _customizationController = TextEditingController();

  String _searchQuery = '';
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  ProductModel? _selectedProduct;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    _loadProducts();

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    _customizationController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      await provider.loadProducts();
      _filterProducts();
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Error loading products: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterProducts() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    List<ProductModel> products = provider.products;

    if (widget.excludeProductIds != null) {
      products = products.where((product) => !widget.excludeProductIds!.contains(product.id)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      products = products
          .where(
            (product) =>
        product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.fabric.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.color.toLowerCase().contains(_searchQuery.toLowerCase()),
      )
          .toList();
    }

    setState(() {
      _filteredProducts = products;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  void _selectProduct(ProductModel product) {
    setState(() {
      _selectedProduct = product;
    });
  }

  void _addToOrder() {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedProduct == null) {
        _showErrorSnackbar(l10n.pleaseSelectProduct);
        return;
      }

      final quantity = int.tryParse(_quantityController.text) ?? 1;
      final customizationNotes = _customizationController.text.trim();

      widget.onProductSelected(_selectedProduct!, quantity, customizationNotes.isNotEmpty ? customizationNotes : null);

      _animationController.reverse().then((_) {
        Navigator.of(context).pop();
      });
    }
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
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
                  maxWidth: ResponsiveBreakpoints.responsive(context, tablet: 90.w, small: 85.w, medium: 75.w, large: 65.w, ultrawide: 55.w),
                  maxHeight: ResponsiveBreakpoints.responsive(context, tablet: 85.h, small: 80.h, medium: 75.h, large: 70.h, ultrawide: 65.h),
                ),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
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
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Icon(Icons.inventory_2_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.shouldShowCompactLayout ? l10n.selectProduct : l10n.selectProductForOrder,
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
                    l10n.chooseProductToAddToOrder,
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
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(context.cardPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchSection(),
                SizedBox(height: context.cardPadding),

                _buildProductListSection(),
                SizedBox(height: context.cardPadding),

                if (_selectedProduct != null) ...[_buildSelectedProductSection(), SizedBox(height: context.mainPadding)],

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
      ),
    );
  }

  Widget _buildSearchSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.05),
            blurRadius: context.shadowBlur('light'),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.searchProducts, Icons.search),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.searchProducts,
            hint: context.shouldShowCompactLayout ? l10n.searchProductsShort : l10n.searchProductsByNameFabricOrColor,
            controller: _searchController,
            prefixIcon: Icons.search,
            onChanged: _onSearchChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildProductListSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.05),
            blurRadius: context.shadowBlur('light'),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.availableProducts, Icons.inventory_2),
          SizedBox(height: context.cardPadding),
          _isLoading
              ? Center(child: CircularProgressIndicator(color: AppTheme.primaryMaroon))
              : _filteredProducts.isEmpty
              ? Center(
            child: Container(
              padding: EdgeInsets.all(context.cardPadding * 2),
              child: Column(
                children: [
                  Icon(
                    _searchQuery.isEmpty ? Icons.inventory_2_outlined : Icons.search_off,
                    color: AppTheme.charcoalGray,
                    size: context.iconSize('large'),
                  ),
                  SizedBox(height: context.cardPadding),
                  Text(
                    _searchQuery.isEmpty ? l10n.noProductsAvailable : l10n.noProductsFound,
                    style: TextStyle(
                      fontSize: context.bodyFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    SizedBox(height: context.smallPadding),
                    Text(
                      l10n.tryAdjustingYourSearchTerms,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
              : SizedBox(
            height: ResponsiveBreakpoints.responsive(context, tablet: 40.h, small: 35.h, medium: 30.h, large: 25.h, ultrawide: 20.h),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                final isSelected = _selectedProduct?.id == product.id;

                return Container(
                  margin: EdgeInsets.only(bottom: context.smallPadding),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryMaroon.withOpacity(0.1) : AppTheme.pureWhite,
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryMaroon : AppTheme.lightGray.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () => _selectProduct(product),
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                    child: Padding(
                      padding: EdgeInsets.all(context.cardPadding),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryMaroon.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(context.borderRadius()),
                            ),
                            child: Icon(
                              Icons.inventory_2,
                              color: AppTheme.primaryMaroon,
                              size: context.iconSize('medium'),
                            ),
                          ),
                          SizedBox(width: context.cardPadding),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: TextStyle(
                                    fontSize: context.bodyFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: context.smallPadding / 2),
                                Text(
                                  '${product.fabric} • ${product.color}',
                                  style: TextStyle(
                                    fontSize: context.bodyFontSize,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: context.smallPadding / 2),
                                Row(
                                  children: [
                                    Text(
                                      'PKR ${product.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: context.bodyFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryMaroon,
                                      ),
                                    ),
                                    SizedBox(width: context.cardPadding),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.smallPadding,
                                        vertical: context.smallPadding / 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: product.quantity > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(context.borderRadius('small')),
                                      ),
                                      child: Text(
                                        product.quantity > 0 ? '${l10n.inStock} (${product.quantity})' : l10n.outOfStock,
                                        style: TextStyle(
                                          fontSize: context.bodyFontSize,
                                          color: product.quantity > 0 ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: EdgeInsets.all(context.smallPadding / 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryMaroon,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: AppTheme.pureWhite,
                                size: context.iconSize('medium'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedProductSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.05),
            blurRadius: context.shadowBlur('light'),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(l10n.selectedProductDetails, Icons.check_circle_outline),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _selectedProduct!.name.isNotEmpty ? _selectedProduct!.name[0].toUpperCase() : 'P',
                    style: TextStyle(
                      fontSize: context.headerFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedProduct!.name,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.smallPadding / 2),
                    Text(
                      '${_selectedProduct!.fabric} • ${_selectedProduct!.color}',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: context.smallPadding / 2),
                    Text(
                      '${l10n.available}: ${_selectedProduct!.quantity} ${l10n.units}',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w500,
                        color: _selectedProduct!.quantity > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          ResponsiveBreakpoints.responsive(
            context,
            tablet: _buildFormFieldsColumn(),
            small: _buildFormFieldsColumn(),
            medium: _buildFormFieldsRow(),
            large: _buildFormFieldsRow(),
            ultrawide: _buildFormFieldsRow(),
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.customizationNotesOptional,
            hint: context.shouldShowCompactLayout ? l10n.enterNotes : l10n.specialInstructionsOrCustomizationNotes,
            controller: _customizationController,
            prefixIcon: Icons.description_outlined,
            maxLines: 3,
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length > 500) {
                return l10n.notesMustBeLessThan500Characters;
              }
              return null;
            },
          ),
          SizedBox(height: context.cardPadding),
          Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryMaroon.withOpacity(0.1),
                  AppTheme.secondaryMaroon.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.primaryMaroon,
                      size: context.iconSize('medium'),
                    ),
                    SizedBox(width: context.smallPadding),
                    Text(
                      '${l10n.totalAmount}:',
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  'PKR ${(_selectedProduct!.price * (int.tryParse(_quantityController.text) ?? 1)).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: context.headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryMaroon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldsRow() {
    return Row(
      children: [
        Expanded(child: _buildQuantityField()),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildUnitPriceField()),
      ],
    );
  }

  Widget _buildFormFieldsColumn() {
    return Column(
      children: [
        _buildQuantityField(),
        SizedBox(height: context.cardPadding),
        _buildUnitPriceField(),
      ],
    );
  }

  Widget _buildQuantityField() {
    final l10n = AppLocalizations.of(context)!;

    return PremiumTextField(
      label: '${l10n.quantity} *',
      hint: l10n.enterQuantity,
      controller: _quantityController,
      keyboardType: TextInputType.number,
      prefixIcon: Icons.numbers,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return l10n.pleaseEnterQuantity;
        }
        final quantity = int.tryParse(value!);
        if (quantity == null) {
          return l10n.pleaseEnterValidNumber;
        }
        if (quantity <= 0) {
          return l10n.quantityMustBeGreaterThanZero;
        }
        if (_selectedProduct != null && quantity > _selectedProduct!.quantity) {
          return '${l10n.only} ${_selectedProduct!.quantity} ${l10n.unitsAvailable}';
        }
        return null;
      },
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildUnitPriceField() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.unitPrice,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: context.smallPadding),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            color: AppTheme.primaryMaroon.withOpacity(0.05),
            borderRadius: BorderRadius.circular(context.borderRadius()),
            border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.attach_money,
                color: AppTheme.primaryMaroon,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                'PKR ${_selectedProduct!.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryMaroon,
                ),
              ),
            ],
          ),
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
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumButton(
          text: l10n.addToOrder,
          onPressed: _selectedProduct != null ? _addToOrder : null,
          isLoading: _isLoading,
          height: context.buttonHeight,
          icon: Icons.add_rounded,
          backgroundColor: AppTheme.primaryMaroon,
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
          child: PremiumButton(
            text: l10n.addToOrder,
            onPressed: _selectedProduct != null ? _addToOrder : null,
            isLoading: _isLoading,
            height: context.buttonHeight / 1.5,
            icon: Icons.add_rounded,
            backgroundColor: AppTheme.primaryMaroon,
          ),
        ),
      ],
    );
  }
}
