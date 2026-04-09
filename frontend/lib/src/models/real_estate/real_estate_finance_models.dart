class RealEstateIncome {
  final String? id;
  final String? projectId;
  final String? projectName;
  final String incomeType; // COMMISSION_RECEIVED, OTHER
  final double amount;
  final String date;
  final String? description;
  final String? saleId;

  RealEstateIncome({
    this.id,
    this.projectId,
    this.projectName,
    required this.incomeType,
    required this.amount,
    required this.date,
    this.description,
    this.saleId,
  });

  factory RealEstateIncome.fromJson(Map<String, dynamic> json) {
    return RealEstateIncome(
      id: json['id']?.toString(),
      projectId: json['project']?.toString(),
      projectName: json['project_name'],
      incomeType: json['income_type'],
      amount: double.parse(json['amount'].toString()),
      date: json['date'],
      description: json['description'],
      saleId: json['sale']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'project': projectId,
      'income_type': incomeType,
      'amount': amount,
      'date': date,
      'description': description,
      'sale': saleId,
    };
  }
}

class RealEstateExpense {
  final String? id;
  final String? projectId;
  final String? projectName;
  final String category; // OFFICE_RENT, SALARY, MARKETING, UTILITY, MISC
  final double amount;
  final String date;
  final String? description;
  final String? saleId;

  RealEstateExpense({
    this.id,
    this.projectId,
    this.projectName,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.saleId,
  });

  factory RealEstateExpense.fromJson(Map<String, dynamic> json) {
    return RealEstateExpense(
      id: json['id']?.toString(),
      projectId: json['project']?.toString(),
      projectName: json['project_name'],
      category: json['category'],
      amount: double.parse(json['amount'].toString()),
      date: json['date'],
      description: json['description'],
      saleId: json['sale']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'project': projectId,
      'category': category,
      'amount': amount,
      'date': date,
      'description': description,
      'sale': saleId,
    };
  }
}

class FinancialSummary {
  final String period;
  final String? startDate;
  final double totalIncome;
  final double totalExpense;
  final double netProfit;
  final List<dynamic> incomeBreakdown;
  final List<dynamic> expenseBreakdown;

  FinancialSummary({
    required this.period,
    this.startDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfit,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      period: json['period'],
      startDate: json['start_date']?.toString(),
      totalIncome: double.parse(json['total_income'].toString()),
      totalExpense: double.parse(json['total_expense'].toString()),
      netProfit: double.parse(json['net_profit'].toString()),
      incomeBreakdown: json['income_breakdown'] ?? [],
      expenseBreakdown: json['expense_breakdown'] ?? [],
    );
  }
}

class RealEstateDashboardData {
  final List<dynamic> projectSales;
  final double totalSalesAllTime; // Added this
  final double totalCommissionReceived;
  final double totalCommissionPaid;
  final double netProfit;
  final double totalReceivables;
  final double pendingCommissions;
  final int availablePlots;
  final Map<String, dynamic> today;
  final Map<String, dynamic> charts;

  RealEstateDashboardData({
    required this.projectSales,
    required this.totalSalesAllTime,
    required this.totalCommissionReceived,
    required this.totalCommissionPaid,
    required this.netProfit,
    required this.totalReceivables,
    required this.pendingCommissions,
    required this.availablePlots,
    required this.today,
    required this.charts,
  });

  factory RealEstateDashboardData.fromJson(Map<String, dynamic> json) {
    return RealEstateDashboardData(
      projectSales: json['project_sales'] ?? [],
      totalSalesAllTime: double.parse((json['total_sales_all_time'] ?? 0).toString()),
      totalCommissionReceived: double.parse((json['total_commission_received'] ?? 0).toString()),
      totalCommissionPaid: double.parse((json['total_commission_paid'] ?? 0).toString()),
      netProfit: double.parse((json['net_profit'] ?? 0).toString()),
      totalReceivables: double.parse((json['total_receivables'] ?? 0).toString()),
      pendingCommissions: double.parse((json['pending_commissions'] ?? 0).toString()),
      availablePlots: json['available_plots'] ?? 0,
      today: json['today'] ?? {},
      charts: json['charts'] ?? {},
    );
  }
}
