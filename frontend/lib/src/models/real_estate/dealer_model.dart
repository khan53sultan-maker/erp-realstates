class RealEstateDealer {
  final String? id;
  final String name;
  final String phone;
  final String type; // 'TEAM_MEMBER', 'DEALER', 'SUB_AGENT'
  final double commissionPercentage;
  final int totalSalesCount;
  final double totalCommissionEarned;
  final double paidAmount;
  final double pendingAmount;

  RealEstateDealer({
    this.id,
    required this.name,
    required this.phone,
    this.type = 'DEALER',
    this.commissionPercentage = 5.0,
    this.totalSalesCount = 0,
    this.totalCommissionEarned = 0.0,
    this.paidAmount = 0.0,
    this.pendingAmount = 0.0,
  });

  factory RealEstateDealer.fromJson(Map<String, dynamic> json) {
    return RealEstateDealer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      type: json['dealer_type'] ?? 'DEALER',
      commissionPercentage: double.parse(json['commission_percentage'].toString()),
      totalSalesCount: json['total_sales_count'] ?? 0,
      totalCommissionEarned: double.parse((json['total_commission_earned'] ?? 0).toString()),
      paidAmount: double.parse((json['paid_amount'] ?? 0).toString()),
      pendingAmount: double.parse((json['pending_amount'] ?? 0).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'dealer_type': type,
      'commission_percentage': commissionPercentage,
      'paid_amount': paidAmount,
    };
  }
}
