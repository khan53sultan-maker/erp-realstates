/// Sale Reports Models for Flutter Frontend
/// Contains models for sale reports data

class SaleReportModel {
  final String reportType;
  final ReportPeriod period;
  final ReportSummary summary;
  final List<PaymentBreakdown> paymentBreakdown;
  final List<StatusBreakdown> statusBreakdown;
  final List<TopProduct> topProducts;
  final List<TopCustomer> topCustomers;
  final List<TrendData> trendData;
  final List<SellerPerformance> sellerPerformance;
  final DateTime generatedAt;

  SaleReportModel({
    required this.reportType,
    required this.period,
    required this.summary,
    required this.paymentBreakdown,
    required this.statusBreakdown,
    required this.topProducts,
    required this.topCustomers,
    required this.trendData,
    required this.sellerPerformance,
    required this.generatedAt,
  });

  factory SaleReportModel.fromJson(Map<String, dynamic> json) {
    return SaleReportModel(
      reportType: json['report_type'] ?? 'daily',
      period: ReportPeriod.fromJson(json['period'] ?? {}),
      summary: ReportSummary.fromJson(json['summary'] ?? {}),
      paymentBreakdown: (json['payment_breakdown'] as List? ?? [])
          .map((e) => PaymentBreakdown.fromJson(e))
          .toList(),
      statusBreakdown: (json['status_breakdown'] as List? ?? [])
          .map((e) => StatusBreakdown.fromJson(e))
          .toList(),
      topProducts: (json['top_products'] as List? ?? [])
          .map((e) => TopProduct.fromJson(e))
          .toList(),
      topCustomers: (json['top_customers'] as List? ?? [])
          .map((e) => TopCustomer.fromJson(e))
          .toList(),
      trendData: (json['trend_data'] as List? ?? [])
          .map((e) => TrendData.fromJson(e))
          .toList(),
      sellerPerformance: (json['seller_performance'] as List? ?? [])
          .map((e) => SellerPerformance.fromJson(e))
          .toList(),
      generatedAt: json['generated_at'] != null 
          ? DateTime.parse(json['generated_at']) 
          : DateTime.now(),
    );
  }

  String get formattedReportType {
    switch (reportType.toLowerCase()) {
      case 'daily':
        return 'Daily Report';
      case 'weekly':
        return 'Weekly Report';
      case 'monthly':
        return 'Monthly Report';
      case 'yearly':
        return 'Yearly Report';
      default:
        return 'Sales Report';
    }
  }
}

class ReportPeriod {
  final String startDate;
  final String endDate;
  final String display;

  ReportPeriod({
    required this.startDate,
    required this.endDate,
    required this.display,
  });

  factory ReportPeriod.fromJson(Map<String, dynamic> json) {
    return ReportPeriod(
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      display: json['display'] ?? '',
    );
  }
}

class ReportSummary {
  final int totalSales;
  final double totalRevenue;
  final int totalItemsSold;
  final double totalProfit;
  final double totalDiscount;
  final double totalTax;
  final double averageOrderValue;
  final double profitMargin;

  ReportSummary({
    required this.totalSales,
    required this.totalRevenue,
    required this.totalItemsSold,
    required this.totalProfit,
    required this.totalDiscount,
    required this.totalTax,
    required this.averageOrderValue,
    required this.profitMargin,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalSales: json['total_sales'] ?? 0,
      totalRevenue: _parseDouble(json['total_revenue']),
      totalItemsSold: json['total_items_sold'] ?? 0,
      totalProfit: _parseDouble(json['total_profit']),
      totalDiscount: _parseDouble(json['total_discount']),
      totalTax: _parseDouble(json['total_tax']),
      averageOrderValue: _parseDouble(json['average_order_value']),
      profitMargin: _parseDouble(json['profit_margin']),
    );
  }

  String get formattedRevenue => 'PKR ${totalRevenue.toStringAsFixed(0)}';
  String get formattedProfit => 'PKR ${totalProfit.toStringAsFixed(0)}';
  String get formattedAOV => 'PKR ${averageOrderValue.toStringAsFixed(0)}';
  String get formattedMargin => '${profitMargin.toStringAsFixed(1)}%';
}

class PaymentBreakdown {
  final String method;
  final int count;
  final double total;

  PaymentBreakdown({
    required this.method,
    required this.count,
    required this.total,
  });

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) {
    return PaymentBreakdown(
      method: json['method'] ?? 'Unknown',
      count: json['count'] ?? 0,
      total: _parseDouble(json['total']),
    );
  }

  String get formattedTotal => 'PKR ${total.toStringAsFixed(0)}';
}

class StatusBreakdown {
  final String status;
  final int count;
  final double total;

  StatusBreakdown({
    required this.status,
    required this.count,
    required this.total,
  });

  factory StatusBreakdown.fromJson(Map<String, dynamic> json) {
    return StatusBreakdown(
      status: json['status'] ?? 'Unknown',
      count: json['count'] ?? 0,
      total: _parseDouble(json['total']),
    );
  }

  String get formattedTotal => 'PKR ${total.toStringAsFixed(0)}';
}

class TopProduct {
  final String name;
  final int quantity;
  final double revenue;

  TopProduct({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      name: json['name'] ?? 'Unknown',
      quantity: json['quantity'] ?? 0,
      revenue: _parseDouble(json['revenue']),
    );
  }

  String get formattedRevenue => 'PKR ${revenue.toStringAsFixed(0)}';
}

class TopCustomer {
  final String name;
  final int orders;
  final double revenue;

  TopCustomer({
    required this.name,
    required this.orders,
    required this.revenue,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    return TopCustomer(
      name: json['name'] ?? 'Walk-in',
      orders: json['orders'] ?? 0,
      revenue: _parseDouble(json['revenue']),
    );
  }

  String get formattedRevenue => 'PKR ${revenue.toStringAsFixed(0)}';
}

class TrendData {
  final dynamic date; // Can be date string or hour int
  final int salesCount;
  final double revenue;

  TrendData({
    required this.date,
    required this.salesCount,
    required this.revenue,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      date: json['date'] ?? json['hour'],
      salesCount: json['sales_count'] ?? 0,
      revenue: _parseDouble(json['revenue']),
    );
  }

  String get formattedRevenue => 'PKR ${revenue.toStringAsFixed(0)}';
}

class SellerPerformance {
  final String name;
  final int sales;
  final double revenue;
  final double profit;

  SellerPerformance({
    required this.name,
    required this.sales,
    required this.revenue,
    required this.profit,
  });

  factory SellerPerformance.fromJson(Map<String, dynamic> json) {
    return SellerPerformance(
      name: json['name'] ?? 'System',
      sales: json['sales'] ?? 0,
      revenue: _parseDouble(json['revenue']),
      profit: _parseDouble(json['profit']),
    );
  }

  String get formattedRevenue => 'PKR ${revenue.toStringAsFixed(0)}';
  String get formattedProfit => 'PKR ${profit.toStringAsFixed(0)}';
}

class SalesComparisonModel {
  final String reportType;
  final ComparisonPeriod currentPeriod;
  final ComparisonPeriod previousPeriod;
  final GrowthData growth;

  SalesComparisonModel({
    required this.reportType,
    required this.currentPeriod,
    required this.previousPeriod,
    required this.growth,
  });

  factory SalesComparisonModel.fromJson(Map<String, dynamic> json) {
    return SalesComparisonModel(
      reportType: json['report_type'] ?? 'daily',
      currentPeriod: ComparisonPeriod.fromJson(json['current_period'] ?? {}),
      previousPeriod: ComparisonPeriod.fromJson(json['previous_period'] ?? {}),
      growth: GrowthData.fromJson(json['growth'] ?? {}),
    );
  }
}

class ComparisonPeriod {
  final String startDate;
  final String endDate;
  final int totalSales;
  final double totalRevenue;
  final double totalProfit;

  ComparisonPeriod({
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.totalRevenue,
    required this.totalProfit,
  });

  factory ComparisonPeriod.fromJson(Map<String, dynamic> json) {
    return ComparisonPeriod(
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      totalSales: json['total_sales'] ?? 0,
      totalRevenue: _parseDouble(json['total_revenue']),
      totalProfit: _parseDouble(json['total_profit']),
    );
  }

  String get formattedRevenue => 'PKR ${totalRevenue.toStringAsFixed(0)}';
  String get formattedProfit => 'PKR ${totalProfit.toStringAsFixed(0)}';
}

class GrowthData {
  final double revenueGrowth;
  final double salesGrowth;
  final double profitGrowth;
  final String revenueTrend;
  final String salesTrend;
  final String profitTrend;

  GrowthData({
    required this.revenueGrowth,
    required this.salesGrowth,
    required this.profitGrowth,
    required this.revenueTrend,
    required this.salesTrend,
    required this.profitTrend,
  });

  factory GrowthData.fromJson(Map<String, dynamic> json) {
    return GrowthData(
      revenueGrowth: _parseDouble(json['revenue_growth']),
      salesGrowth: _parseDouble(json['sales_growth']),
      profitGrowth: _parseDouble(json['profit_growth']),
      revenueTrend: json['revenue_trend'] ?? 'stable',
      salesTrend: json['sales_trend'] ?? 'stable',
      profitTrend: json['profit_trend'] ?? 'stable',
    );
  }

  String get formattedRevenueGrowth => '${revenueGrowth >= 0 ? '+' : ''}${revenueGrowth.toStringAsFixed(1)}%';
  String get formattedSalesGrowth => '${salesGrowth >= 0 ? '+' : ''}${salesGrowth.toStringAsFixed(1)}%';
  String get formattedProfitGrowth => '${profitGrowth >= 0 ? '+' : ''}${profitGrowth.toStringAsFixed(1)}%';

  bool get isRevenueUp => revenueTrend == 'up';
  bool get isSalesUp => salesTrend == 'up';
  bool get isProfitUp => profitTrend == 'up';
}

// Helper function for parsing doubles
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }
  return 0.0;
}
