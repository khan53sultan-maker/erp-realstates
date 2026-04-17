import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/real_estate/project_model.dart';
import '../models/real_estate/plot_model.dart';
import '../models/real_estate/dealer_model.dart';
import '../models/real_estate/real_estate_sale_model.dart';
import '../models/real_estate/installment_model.dart';
import '../models/real_estate/real_estate_finance_models.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'api_client.dart';

class RealEstateService {
  static final RealEstateService _instance = RealEstateService._internal();
  factory RealEstateService() => _instance;
  RealEstateService._internal();

  final ApiClient _apiClient = ApiClient();
  
  List<dynamic> _parseListData(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      return data['results'] ?? data['data'] ?? [];
    }
    return [];
  }

  // --- Projects ---
  Future<ApiResponse<List<RealEstateProject>>> getProjects() async {
    try {
      final response = await _apiClient.get(ApiConfig.realEstateProjects, queryParameters: {'page_size': 10000});
      if (response.statusCode == 200) {
        final data = _parseListData(response.data);
        final projects = data.map((json) => RealEstateProject.fromJson(json)).toList();
        return ApiResponse<List<RealEstateProject>>(
          success: true,
          message: 'Projects retrieved successfully',
          data: projects,
        );
      }
      return ApiResponse<List<RealEstateProject>>(success: false, message: 'Failed to retrieve projects');
    } catch (e) {
      return ApiResponse<List<RealEstateProject>>(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<void>> generatePlots(String projectId, {String size = '5 Marla', double price = 0}) async {
    try {
      final response = await _apiClient.post('${ApiConfig.realEstateProjects}$projectId/generate_plots/', data: {
        'plot_size': size,
        'total_price': price,
      });
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: response.data['message']);
      }
      return ApiResponse(success: false, message: 'Failed to generate plots');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateProject>> createProject(RealEstateProject project) async {
    try {
      final response = await _apiClient.post(ApiConfig.realEstateProjects, data: project.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<RealEstateProject>(
          success: true,
          message: 'Project created successfully',
          data: RealEstateProject.fromJson(response.data),
        );
      }
      return ApiResponse<RealEstateProject>(success: false, message: 'Failed to create project');
    } catch (e) {
      return ApiResponse<RealEstateProject>(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateProject>> updateProject(String id, RealEstateProject project) async {
    try {
      final response = await _apiClient.put('${ApiConfig.realEstateProjects}$id/', data: project.toJson());
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Project updated', data: RealEstateProject.fromJson(response.data));
      }
      return ApiResponse(success: false, message: 'Failed to update project');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<void>> deleteProject(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.realEstateProjects}$id/');
      if (response.statusCode == 204) {
        return ApiResponse(success: true, message: 'Project deleted');
      }
      return ApiResponse(success: false, message: 'Failed to delete project');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // --- Plots ---
  Future<ApiResponse<List<RealEstatePlot>>> getPlots({String? projectId, String? status}) async {
    try {
      final queryParams = <String, dynamic>{'page_size': 10000};
      if (projectId != null) queryParams['project'] = projectId;
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.get(ApiConfig.realEstatePlots, queryParameters: queryParams);
      if (response.statusCode == 200) {
        final data = _parseListData(response.data);
        final plots = data.map((json) => RealEstatePlot.fromJson(json)).toList();
        return ApiResponse<List<RealEstatePlot>>(
          success: true,
          message: 'Plots retrieved successfully',
          data: plots,
        );
      }
      return ApiResponse<List<RealEstatePlot>>(success: false, message: 'Failed to retrieve plots');
    } catch (e) {
      return ApiResponse<List<RealEstatePlot>>(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstatePlot>> createPlot(RealEstatePlot plot) async {
    try {
      final response = await _apiClient.post(ApiConfig.realEstatePlots, data: plot.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<RealEstatePlot>(
          success: true,
          message: 'Plot created successfully',
          data: RealEstatePlot.fromJson(response.data),
        );
      }
      return ApiResponse<RealEstatePlot>(success: false, message: 'Failed to create plot');
    } catch (e) {
      return ApiResponse<RealEstatePlot>(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstatePlot>> updatePlot(String id, RealEstatePlot plot) async {
    try {
      final response = await _apiClient.put('${ApiConfig.realEstatePlots}$id/', data: plot.toJson());
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Plot updated', data: RealEstatePlot.fromJson(response.data));
      }
      return ApiResponse(success: false, message: 'Failed to update plot');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<void>> deletePlot(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.realEstatePlots}$id/');
      if (response.statusCode == 204) {
        return ApiResponse(success: true, message: 'Plot deleted');
      }
      return ApiResponse(success: false, message: 'Failed to delete plot');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // --- Dealers ---
  Future<ApiResponse<List<RealEstateDealer>>> getDealers() async {
    try {
      final response = await _apiClient.get(ApiConfig.realEstateDealers, queryParameters: {'page_size': 10000});
      if (response.statusCode == 200) {
        final data = _parseListData(response.data);
        final dealers = data.map((json) => RealEstateDealer.fromJson(json)).toList();
        return ApiResponse<List<RealEstateDealer>>(
          success: true,
          message: 'Dealers retrieved successfully',
          data: dealers,
        );
      }
      return ApiResponse<List<RealEstateDealer>>(success: false, message: 'Failed to retrieve dealers');
    } catch (e) {
      return ApiResponse<List<RealEstateDealer>>(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateDealer>> createDealer(RealEstateDealer dealer) async {
    try {
      final response = await _apiClient.post(ApiConfig.realEstateDealers, data: dealer.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<RealEstateDealer>(
          success: true,
          message: 'Dealer created successfully',
          data: RealEstateDealer.fromJson(response.data),
        );
      }
      return ApiResponse<RealEstateDealer>(success: false, message: 'Failed to create dealer');
    } catch (e) {
      return ApiResponse<RealEstateDealer>(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateDealer>> updateDealer(String id, RealEstateDealer dealer) async {
    try {
      final response = await _apiClient.put('${ApiConfig.realEstateDealers}$id/', data: dealer.toJson());
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Dealer updated', data: RealEstateDealer.fromJson(response.data));
      }
      return ApiResponse(success: false, message: 'Failed to update dealer');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<void>> deleteDealer(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.realEstateDealers}$id/');
      if (response.statusCode == 204) {
        return ApiResponse(success: true, message: 'Dealer deleted');
      }
      return ApiResponse(success: false, message: 'Failed to delete dealer');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // --- Sales ---
  Future<ApiResponse<List<RealEstateSale>>> getSales({String? projectId, String? customerId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (projectId != null) queryParams['plot__project'] = projectId;
      if (customerId != null) queryParams['customer'] = customerId;

      final response = await _apiClient.get(ApiConfig.realEstateSales, queryParameters: queryParams);
      if (response.statusCode == 200) {
        final data = _parseListData(response.data);
        final sales = data.map((json) => RealEstateSale.fromJson(json)).toList();
        return ApiResponse<List<RealEstateSale>>(
          success: true,
          message: 'Sales retrieved successfully',
          data: sales,
        );
      }
      return ApiResponse<List<RealEstateSale>>(success: false, message: 'Failed to retrieve sales');
    } catch (e) {
      return ApiResponse<List<RealEstateSale>>(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateSale>> createSale(RealEstateSale sale) async {
    try {
      final response = await _apiClient.post(ApiConfig.realEstateSales, data: sale.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<RealEstateSale>(
          success: true,
          message: 'Sale created successfully',
          data: RealEstateSale.fromJson(response.data),
        );
      }
      return ApiResponse<RealEstateSale>(success: false, message: 'Failed to create sale');
    } catch (e) {
      return ApiResponse<RealEstateSale>(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateSale>> updateSale(String id, RealEstateSale sale) async {
    try {
      final response = await _apiClient.put('${ApiConfig.realEstateSales}$id/', data: sale.toJson());
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Sale updated', data: RealEstateSale.fromJson(response.data));
      }
      return ApiResponse(success: false, message: 'Failed to update sale');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<void>> deleteSale(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.realEstateSales}$id/');
      if (response.statusCode == 204) {
        return ApiResponse(success: true, message: 'Sale deleted');
      }
      return ApiResponse(success: false, message: 'Failed to delete sale');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // --- Installments ---
  Future<ApiResponse<List<RealEstateInstallment>>> getInstallments({String? saleId, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (saleId != null) queryParams['sale'] = saleId;
      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.get(ApiConfig.realEstateInstallments, queryParameters: queryParams);
      if (response.statusCode == 200) {
        final data = _parseListData(response.data);
        final installments = data.map((json) => RealEstateInstallment.fromJson(json)).toList();
        return ApiResponse<List<RealEstateInstallment>>(
          success: true,
          message: 'Installments retrieved successfully',
          data: installments,
        );
      }
      return ApiResponse<List<RealEstateInstallment>>(success: false, message: 'Failed to retrieve installments');
    } catch (e) {
      return ApiResponse<List<RealEstateInstallment>>(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateInstallment>> updateInstallment(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.patch('${ApiConfig.realEstateInstallments}$id/', data: data);
      if (response.statusCode == 200) {
        return ApiResponse<RealEstateInstallment>(
          success: true,
          message: 'Installment updated successfully',
          data: RealEstateInstallment.fromJson(response.data),
        );
      }
      return ApiResponse<RealEstateInstallment>(success: false, message: 'Failed to update installment');
    } catch (e) {
      return ApiResponse<RealEstateInstallment>(success: false, message: e.toString());
    }
  }

  // --- Incomes ---
  Future<ApiResponse<List<RealEstateIncome>>> getIncomes({String? projectId, String? type}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (projectId != null) queryParams['project'] = projectId;
      if (type != null) queryParams['income_type'] = type;

      final response = await _apiClient.get(ApiConfig.realEstateIncomes, queryParameters: queryParams);
      if (response.statusCode == 200) {
        final data = _parseListData(response.data);
        final incomes = data.map((json) => RealEstateIncome.fromJson(json)).toList();
        return ApiResponse(success: true, message: 'Incomes retrieved', data: incomes);
      }
      return ApiResponse(success: false, message: 'Failed to retrieve incomes');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateIncome>> createIncome(RealEstateIncome income) async {
    try {
      final response = await _apiClient.post(ApiConfig.realEstateIncomes, data: income.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Income recorded', data: RealEstateIncome.fromJson(response.data));
      }
      return ApiResponse(success: false, message: 'Failed to record income');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateIncome>> updateIncome(String id, RealEstateIncome income) async {
    try {
      final response = await _apiClient.put('${ApiConfig.realEstateIncomes}$id/', data: income.toJson());
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Income updated', data: RealEstateIncome.fromJson(response.data));
      }
      return ApiResponse(success: false, message: 'Failed to update income');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<void>> deleteIncome(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.realEstateIncomes}$id/');
      if (response.statusCode == 204) {
        return ApiResponse(success: true, message: 'Income deleted');
      }
      return ApiResponse(success: false, message: 'Failed to delete income');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // --- Expenses ---
  Future<ApiResponse<List<RealEstateExpense>>> getExpenses({String? projectId, String? category}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (projectId != null) queryParams['project'] = projectId;
      if (category != null) queryParams['category'] = category;

      final response = await _apiClient.get(ApiConfig.realEstateExpenses, queryParameters: queryParams);
      if (response.statusCode == 200) {
        final data = _parseListData(response.data);
        final expenses = data.map((json) => RealEstateExpense.fromJson(json)).toList();
        return ApiResponse(success: true, message: 'Expenses retrieved', data: expenses);
      }
      return ApiResponse(success: false, message: 'Failed to retrieve expenses');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateExpense>> createExpense(RealEstateExpense expense) async {
    try {
      final response = await _apiClient.post(ApiConfig.realEstateExpenses, data: expense.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Expense recorded', data: RealEstateExpense.fromJson(response.data));
      }
      return ApiResponse(success: false, message: 'Failed to record expense');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateExpense>> updateExpense(String id, RealEstateExpense expense) async {
    try {
      final response = await _apiClient.put('${ApiConfig.realEstateExpenses}$id/', data: expense.toJson());
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Expense updated', data: RealEstateExpense.fromJson(response.data));
      }
      return ApiResponse(success: false, message: 'Failed to update expense');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<void>> deleteExpense(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.realEstateExpenses}$id/');
      if (response.statusCode == 204) {
        return ApiResponse(success: true, message: 'Expense deleted');
      }
      return ApiResponse(success: false, message: 'Failed to delete expense');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // --- Reports ---
  Future<ApiResponse<FinancialSummary>> getFinancialSummary({String period = 'daily', String? projectId}) async {
    try {
      final queryParams = <String, dynamic>{'period': period};
      if (projectId != null) queryParams['project_id'] = projectId;

      final response = await _apiClient.get(ApiConfig.realEstateReportsSummary, queryParameters: queryParams);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Summary retrieved', data: FinancialSummary.fromJson(response.data));
      }
      return ApiResponse(success: false, message: 'Failed to retrieve summary');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<List<dynamic>>> getProjectProfitReport() async {
    try {
      final response = await _apiClient.get(ApiConfig.realEstateProjectProfitReport);
      if (response.statusCode == 200) {
        return ApiResponse(success: true, message: 'Report retrieved', data: response.data);
      }
      return ApiResponse(success: false, message: 'Failed to retrieve report');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  Future<ApiResponse<RealEstateDashboardData>> getDashboardData() async {
    try {
      final response = await _apiClient.get(ApiConfig.realEstateDashboard);
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Dashboard data retrieved',
          data: RealEstateDashboardData.fromJson(response.data),
        );
      }
      return ApiResponse(success: false, message: 'Failed to retrieve dashboard data');
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // --- New Export Reports ---
  Future<String?> exportReport({
    required bool isPdf,
    required String reportType, // 'commission', 'sales', 'dealer_commission', 'client_payment', 'profit_loss', 'cash_flow'
    String? projectId,
    String? dealerId,
    String? customerId,
    String? saleId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': reportType,
      };
      if (projectId != null) queryParams['project_id'] = projectId;
      if (dealerId != null) queryParams['dealer_id'] = dealerId;
      if (customerId != null) queryParams['customer_id'] = customerId;
      if (saleId != null) queryParams['sale_id'] = saleId;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String().split('T')[0];

      final endpoint = isPdf ? 'reports/export_pdf/' : 'reports/export_excel/';
      
      final response = await _apiClient.get(
        '${ApiConfig.realEstate}$endpoint',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final List<int> bytes = response.data;
        final extension = isPdf ? 'pdf' : 'xlsx';
        final fileName = 'real_estate_report_${DateTime.now().millisecondsSinceEpoch}.$extension';

        // Use the same logic as SaleReportsService
        final directory = await _getExportDirectory();
        if (directory == null) return null;

        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // Import open_file might be needed or use the existing one
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Error exporting report: $e');
      return null;
    }
  }

  Future<Directory?> _getExportDirectory() async {
    if (kIsWeb) return null;
    try {
      // Trying to get Downloads directory
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // For desktop, getDownloadsDirectory is usually available via path_provider
        // and we have it in SaleReportsService.
        // I'll assume we have path_provider imported.
        // Wait, I need to check imports in real_estate_service.dart.
        return await getDownloadsDirectory();
      } else {
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      return null;
    }
  }
}

// Helper imports that might be needed in real_estate_service.dart
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
