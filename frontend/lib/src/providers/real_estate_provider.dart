import 'package:flutter/material.dart';
import '../models/real_estate/project_model.dart';
import '../models/real_estate/plot_model.dart';
import '../models/real_estate/dealer_model.dart';
import '../models/real_estate/real_estate_sale_model.dart';
import '../models/real_estate/installment_model.dart';
import '../models/real_estate/real_estate_finance_models.dart';
import '../services/real_estate_service.dart';

class RealEstateProvider with ChangeNotifier {
  final RealEstateService _service = RealEstateService();

  List<RealEstateProject> _projects = [];
  List<RealEstatePlot> _plots = [];
  List<RealEstateDealer> _dealers = [];
  List<RealEstateSale> _sales = [];
  List<RealEstateInstallment> _installments = [];
  List<RealEstateIncome> _incomes = [];
  List<RealEstateExpense> _expenses = [];
  FinancialSummary? _reportSummary;
  List<dynamic> _projectProfitReport = [];
  RealEstateDashboardData? _dashboardData;
  
  bool _isLoading = false;
  String? _errorMessage;

  List<RealEstateProject> get projects => _projects;
  List<RealEstatePlot> get plots => _plots;
  List<RealEstateDealer> get dealers => _dealers;
  List<RealEstateSale> get sales => _sales;
  List<RealEstateInstallment> get installments => _installments;
  List<RealEstateIncome> get incomes => _incomes;
  List<RealEstateExpense> get expenses => _expenses;
  FinancialSummary? get reportSummary => _reportSummary;
  List<dynamic> get projectProfitReport => _projectProfitReport;
  RealEstateDashboardData? get dashboardData => _dashboardData;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('REAL ESTATE: Fetching Dashboard Data...');
    final response = await _service.getDashboardData();
    if (response.success) {
      _dashboardData = response.data;
      debugPrint('REAL ESTATE: Dashboard Success. Projects count: ${_dashboardData?.projectSales.length}');
      debugPrint('REAL ESTATE: Project Sales Data: ${_dashboardData?.projectSales}');
    } else {
      _errorMessage = response.message;
      debugPrint('REAL ESTATE: Dashboard Error: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.getProjects();
    if (response.success) {
      _projects = response.data ?? [];
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> generatePlots(String projectId, {String size = '5 Marla', double price = 0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.generatePlots(projectId, size: size, price: price);
    if (response.success) {
      await fetchPlots(projectId: projectId);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchPlots({String? projectId, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.getPlots(projectId: projectId, status: status);
    if (response.success) {
      _plots = response.data ?? [];
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDealers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.getDealers();
    if (response.success) {
      _dealers = response.data ?? [];
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSales({String? projectId, String? customerId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.getSales(projectId: projectId, customerId: customerId);
    if (response.success) {
      _sales = response.data ?? [];
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchInstallments({String? saleId, String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.getInstallments(saleId: saleId, status: status);
    if (response.success) {
      _installments = response.data ?? [];
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addProject(RealEstateProject project) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.createProject(project);
    if (response.success) {
      _projects.insert(0, response.data!);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProject(String id, RealEstateProject project) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.updateProject(id, project);
    if (response.success) {
      final index = _projects.indexWhere((p) => p.id == id);
      if (index != -1) _projects[index] = response.data!;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProject(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.deleteProject(id);
    if (response.success) {
      _projects.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addPlot(RealEstatePlot plot) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.createPlot(plot);
    if (response.success) {
      _plots.insert(0, response.data!);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePlot(String id, RealEstatePlot plot) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.updatePlot(id, plot);
    if (response.success) {
      final index = _plots.indexWhere((p) => p.id == id);
      if (index != -1) _plots[index] = response.data!;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePlot(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.deletePlot(id);
    if (response.success) {
      _plots.removeWhere((p) => p.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addDealer(RealEstateDealer dealer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.createDealer(dealer);
    if (response.success) {
      _dealers.insert(0, response.data!);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDealer(String id, RealEstateDealer dealer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.updateDealer(id, dealer);
    if (response.success) {
      final index = _dealers.indexWhere((d) => d.id == id);
      if (index != -1) _dealers[index] = response.data!;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDealer(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.deleteDealer(id);
    if (response.success) {
      _dealers.removeWhere((d) => d.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addSale(RealEstateSale sale) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.createSale(sale);
    if (response.success) {
      _sales.insert(0, response.data!);
      // Also update plot status locally to SOLD
      final plotIndex = _plots.indexWhere((p) => p.id == sale.plotId);
      if (plotIndex != -1) {
        final p = _plots[plotIndex];
        _plots[plotIndex] = RealEstatePlot(
          id: p.id, projectId: p.projectId, projectName: p.projectName,
          plotNumber: p.plotNumber, plotSize: p.plotSize, totalPrice: p.totalPrice,
          status: 'SOLD', customerId: sale.customerId, customerName: sale.customerName,
          saleDate: DateTime.now().toIso8601String(), dealerId: sale.dealerId, dealerName: sale.dealerName
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSale(String id, RealEstateSale sale) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.updateSale(id, sale);
    if (response.success) {
      final index = _sales.indexWhere((s) => s.id == id);
      if (index != -1) _sales[index] = response.data!;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSale(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.deleteSale(id);
    if (response.success) {
      _sales.removeWhere((s) => s.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> payDownPayment(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.payDownPayment(id, data);
    if (response.success) {
      final index = _sales.indexWhere((s) => s.id == id);
      if (index != -1) _sales[index] = response.data!;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInstallment(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.updateInstallment(id, data);
    if (response.success) {
      final index = _installments.indexWhere((i) => i.id == id);
      if (index != -1) {
        _installments[index] = response.data!;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Incomes ---
  Future<void> fetchIncomes({String? projectId, String? type}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.getIncomes(projectId: projectId, type: type);
    if (response.success) {
      _incomes = response.data ?? [];
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addIncome(RealEstateIncome income) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.createIncome(income);
    if (response.success) {
      _incomes.insert(0, response.data!);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateIncome(String id, RealEstateIncome income) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.updateIncome(id, income);
    if (response.success) {
      final index = _incomes.indexWhere((i) => i.id == id);
      if (index != -1) _incomes[index] = response.data!;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteIncome(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.deleteIncome(id);
    if (response.success) {
      _incomes.removeWhere((i) => i.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Expenses ---
  Future<void> fetchExpenses({String? projectId, String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.getExpenses(projectId: projectId, category: category);
    if (response.success) {
      _expenses = response.data ?? [];
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addExpense(RealEstateExpense expense) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.createExpense(expense);
    if (response.success) {
      _expenses.insert(0, response.data!);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(String id, RealEstateExpense expense) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.updateExpense(id, expense);
    if (response.success) {
      final index = _expenses.indexWhere((e) => e.id == id);
      if (index != -1) _expenses[index] = response.data!;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.deleteExpense(id);
    if (response.success) {
      _expenses.removeWhere((e) => e.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Reports ---
  Future<void> fetchReportSummary({String period = 'daily', String? projectId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.getFinancialSummary(period: period, projectId: projectId);
    if (response.success) {
      _reportSummary = response.data;
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProjectProfitReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _service.getProjectProfitReport();
    if (response.success) {
      _projectProfitReport = response.data ?? [];
    } else {
      _errorMessage = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> exportReport({
    required bool isPdf,
    String reportType = 'commission',
    String? projectId,
    String? dealerId,
    String? customerId,
    String? saleId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final filePath = await _service.exportReport(
      isPdf: isPdf,
      reportType: reportType,
      projectId: projectId,
      dealerId: dealerId,
      customerId: customerId,
      saleId: saleId,
      startDate: startDate,
      endDate: endDate,
    );

    _isLoading = false;
    notifyListeners();
    return filePath;
  }

  Future<String?> exportExcel({String type = 'commission', String? projectId}) async {
    return exportReport(
      isPdf: false,
      reportType: type,
      projectId: projectId,
    );
  }
}
