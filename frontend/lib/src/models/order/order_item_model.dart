class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String customizationNotes;
  final double lineTotal;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Product details
  final String? productColor;
  final String? productFabric;
  final int? currentStock;

  // Sales tracking
  final int? remainingToSell;
  final bool? hasBeenSold;

  // Computed fields
  final double totalValue;
  final Map<String, dynamic> productDisplayInfo;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.customizationNotes,
    required this.lineTotal,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.productColor,
    this.productFabric,
    this.currentStock,
    this.remainingToSell,
    this.hasBeenSold,
    required this.totalValue,
    required this.productDisplayInfo,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: _parseDouble(json['unit_price']),
      customizationNotes:
          json['customization_notes']?.toString() ??
          json['notes']?.toString() ??
          json['description']?.toString() ??
          json['comment']?.toString() ??
          json['remarks']?.toString() ??
          '', 
      lineTotal: _parseDouble(json['line_total']),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']?.toString() ?? '') : null,
      productColor: json['product_color']?.toString(),
      productFabric: json['product_fabric']?.toString(),
      currentStock: json['current_stock'] as int?,
      remainingToSell: json['remaining_to_sell'] as int?,
      hasBeenSold: json['has_been_sold'] as bool?,
      totalValue: _parseDouble(json['total_value'] ?? json['line_total']),
      productDisplayInfo: json['product_display_info'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'customization_notes': customizationNotes,
      'notes': customizationNotes, // Alternative field name for compatibility
      'description': customizationNotes, // Alternative field name for compatibility
      'comment': customizationNotes, // Alternative field name for compatibility
      'remarks': customizationNotes, // Alternative field name for compatibility
      'line_total': lineTotal,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'product_color': productColor,
      'product_fabric': productFabric,
      'current_stock': currentStock,
      'remaining_to_sell': remainingToSell,
      'has_been_sold': hasBeenSold,
      'total_value': totalValue,
      'product_display_info': productDisplayInfo,
    };
  }

  // Helper method to parse double from string or number
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Copy with method for updates
  OrderItemModel copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    String? customizationNotes,
    double? lineTotal,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? productColor,
    String? productFabric,
    int? currentStock,
    int? remainingToSell,
    bool? hasBeenSold,
    double? totalValue,
    Map<String, dynamic>? productDisplayInfo,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      customizationNotes: customizationNotes ?? this.customizationNotes,
      lineTotal: lineTotal ?? this.lineTotal,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productColor: productColor ?? this.productColor,
      productFabric: productFabric ?? this.productFabric,
      currentStock: currentStock ?? this.currentStock,
      remainingToSell: remainingToSell ?? this.remainingToSell,
      hasBeenSold: hasBeenSold ?? this.hasBeenSold,
      totalValue: totalValue ?? this.totalValue,
      productDisplayInfo: productDisplayInfo ?? this.productDisplayInfo,
    );
  }

  // Helper getters
  String get formattedUnitPrice => 'PKR ${unitPrice.toStringAsFixed(0)}';
  String get formattedLineTotal => 'PKR ${lineTotal.toStringAsFixed(0)}';
  String get formattedTotalValue => 'PKR ${totalValue.toStringAsFixed(0)}';

  bool get hasCustomization => customizationNotes.isNotEmpty;
  bool get isOutOfStock => currentStock != null && currentStock! <= 0;
  bool get isLowStock => currentStock != null && currentStock! <= 5;

  @override
  String toString() {
    return 'OrderItemModel(id: $id, productName: $productName, quantity: $quantity, lineTotal: $lineTotal)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
