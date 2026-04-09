class RealEstatePlot {
  final String? id;
  final String projectId;
  final String? projectName;
  final String plotNumber;
  final String plotSize;
  final double totalPrice;
  final String status;
  final String? customerId;
  final String? customerName;
  final String? saleDate;
  final String? dealerId;
  final String? dealerName;
  final double? projectLandownerCommissionPercentage;

  RealEstatePlot({
    this.id,
    required this.projectId,
    this.projectName,
    required this.plotNumber,
    required this.plotSize,
    required this.totalPrice,
    this.status = 'AVAILABLE',
    this.customerId,
    this.customerName,
    this.saleDate,
    this.dealerId,
    this.dealerName,
    this.projectLandownerCommissionPercentage,
  });

  factory RealEstatePlot.fromJson(Map<String, dynamic> json) {
    return RealEstatePlot(
      id: json['id']?.toString(),
      projectId: json['project']?.toString() ?? '',
      projectName: json['project_name']?.toString(),
      plotNumber: json['plot_number']?.toString() ?? '',
      plotSize: json['plot_size']?.toString() ?? '',
      totalPrice: double.parse(json['total_price'].toString()),
      status: json['status'],
      customerId: json['customer'],
      customerName: json['customer_name'],
      saleDate: json['sale_date'],
      dealerId: json['dealer'],
      dealerName: json['dealer_name'],
      projectLandownerCommissionPercentage: json['project_landowner_commission_percentage'] != null 
          ? double.parse(json['project_landowner_commission_percentage'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'project': projectId,
      'plot_number': plotNumber,
      'plot_size': plotSize,
      'total_price': totalPrice,
      'status': status,
      'customer': customerId,
      'sale_date': saleDate,
      'dealer': dealerId,
    };
  }
}
