import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/sales/sale_report_model.dart';
import '../utils/debug_helper.dart';
import 'api_client.dart';

/// Service for fetching sale reports from the backend API
class SaleReportsService {
  static final SaleReportsService _instance = SaleReportsService._internal();

  factory SaleReportsService() => _instance;

  SaleReportsService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Generate sales report with specified type and optional date range
  Future<ApiResponse<SaleReportModel>> generateSalesReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': reportType.toLowerCase(),
      };

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      debugPrint('📊 [SaleReportsService] Fetching $reportType report...');

      final response = await _apiClient.get(
        '${ApiConfig.sales}reports/',
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Sales Report', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          try {
            final report = SaleReportModel.fromJson(responseData['data']);

            debugPrint('✅ [SaleReportsService] Report fetched successfully');

            return ApiResponse<SaleReportModel>(
              success: true,
              message: responseData['message'] ?? 'Report generated successfully',
              data: report,
            );
          } catch (e) {
            debugPrint('❌ [SaleReportsService] Error parsing report: $e');
            return ApiResponse<SaleReportModel>(
              success: false,
              message: 'Error parsing report data: ${e.toString()}',
              errors: {'parsing_error': e.toString()},
            );
          }
        } else {
          return ApiResponse<SaleReportModel>(
            success: false,
            message: responseData['message'] ?? 'Failed to generate report',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<SaleReportModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to generate report',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [SaleReportsService] DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SaleReportModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('❌ [SaleReportsService] Error: ${e.toString()}');
      return ApiResponse<SaleReportModel>(
        success: false,
        message: 'An unexpected error occurred while generating report',
      );
    }
  }

  /// Get sales comparison between current and previous period
  Future<ApiResponse<SalesComparisonModel>> getSalesComparison({
    required String reportType,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': reportType.toLowerCase(),
      };

      debugPrint('📊 [SaleReportsService] Fetching $reportType comparison...');

      final response = await _apiClient.get(
        '${ApiConfig.sales}reports/comparison/',
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Sales Comparison', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          try {
            final comparison = SalesComparisonModel.fromJson(responseData['data']);

            debugPrint('✅ [SaleReportsService] Comparison fetched successfully');

            return ApiResponse<SalesComparisonModel>(
              success: true,
              message: responseData['message'] ?? 'Comparison generated successfully',
              data: comparison,
            );
          } catch (e) {
            debugPrint('❌ [SaleReportsService] Error parsing comparison: $e');
            return ApiResponse<SalesComparisonModel>(
              success: false,
              message: 'Error parsing comparison data: ${e.toString()}',
              errors: {'parsing_error': e.toString()},
            );
          }
        } else {
          return ApiResponse<SalesComparisonModel>(
            success: false,
            message: responseData['message'] ?? 'Failed to get comparison',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<SalesComparisonModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get comparison',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('❌ [SaleReportsService] DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SalesComparisonModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('❌ [SaleReportsService] Error: ${e.toString()}');
      return ApiResponse<SalesComparisonModel>(
        success: false,
        message: 'An unexpected error occurred while getting comparison',
      );
    }
  }

  /// Export sales report as PDF
  Future<String?> exportReportPdf({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': reportType.toLowerCase(),
      };

      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      debugPrint('📤 [SaleReportsService] Exporting $reportType report as PDF...');

      final response = await _apiClient.get(
        '${ApiConfig.sales}reports/export-pdf/',
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // Save PDF file
        final bytes = response.data as List<int>;
        final fileName = 'sales_report_${reportType}_${DateTime.now().millisecondsSinceEpoch}.pdf';

        debugPrint('✅ [SaleReportsService] PDF generated: ${bytes.length} bytes');
        
        // Save to Downloads folder and open (Desktop only)
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          debugPrint('❌ [SaleReportsService] Could not get downloads directory');
          return null;
        }
        
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        debugPrint('✅ [SaleReportsService] PDF saved to: $filePath');
        
        // Open the PDF file
        await OpenFile.open(filePath);
        
        return fileName;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [SaleReportsService] Error exporting PDF: ${e.toString()}');
      return null;
    }
  }
}
