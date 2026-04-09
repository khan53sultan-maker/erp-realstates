class RealEstateProject {
  final String? id;
  final String name;
  final String location;
  final String landownerName;
  final int totalPlots;
  final String plotSizes;
  final double landownerCommissionPercentage;
  final double downPaymentPercentage;
  final String? paymentPlanDetails;
  final String status;
  final int? plotsCount;
  final int? availablePlots;

  RealEstateProject({
    this.id,
    required this.name,
    required this.location,
    required this.landownerName,
    required this.totalPlots,
    required this.plotSizes,
    this.landownerCommissionPercentage = 12.0,
    this.downPaymentPercentage = 30.0,
    this.paymentPlanDetails,
    this.status = 'ACTIVE',
    this.plotsCount,
    this.availablePlots,
  });

  factory RealEstateProject.fromJson(Map<String, dynamic> json) {
    return RealEstateProject(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      landownerName: json['landowner_name'],
      totalPlots: json['total_plots'],
      plotSizes: json['plot_sizes'],
      landownerCommissionPercentage: double.parse(json['landowner_commission_percentage'].toString()),
      downPaymentPercentage: double.parse(json['down_payment_percentage'].toString()),
      paymentPlanDetails: json['payment_plan_details'],
      status: json['status'],
      plotsCount: json['plots_count'],
      availablePlots: json['available_plots'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'location': location,
      'landowner_name': landownerName,
      'total_plots': totalPlots,
      'plot_sizes': plotSizes,
      'landowner_commission_percentage': landownerCommissionPercentage,
      'down_payment_percentage': downPaymentPercentage,
      'payment_plan_details': paymentPlanDetails,
      'status': status,
    };
  }
}
