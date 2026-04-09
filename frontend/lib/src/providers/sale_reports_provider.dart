import 'package:flutter/material.dart';
import '../models/sales/sale_report_model.dart';
import '../services/sale_reports_service.dart';

/// Provider for managing sale reports state and data
class SaleReportsProvider extends ChangeNotifier {
  final SaleReportsService _reportsService = SaleReportsService();

  // State variables
  SaleReportModel? _currentReport;
  SalesComparisonModel? _comparison;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String _selectedReportType = 'daily';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Available report types
  final List<String> _availableReportTypes = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  // Getters
  SaleReportModel? get currentReport => _currentReport;
  SalesComparisonModel? get comparison => _comparison;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get selectedReportType => _selectedReportType;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  List<String> get availableReportTypes => _availableReportTypes;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;
  bool get hasData => _currentReport != null;

  // Initialize provider
  Future<void> initialize() async {
    if (_isLoading) return;
    await loadReport('monthly');
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear success
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  // Set success
  void _setSuccess(String message) {
    _successMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  /// Load report for specified type
  Future<void> loadReport(String reportType, {DateTime? startDate, DateTime? endDate}) async {
    _setLoading(true);
    clearError();

    _selectedReportType = reportType.toLowerCase();
    _customStartDate = startDate;
    _customEndDate = endDate;

    try {
      // Fetch report data
      final reportResponse = await _reportsService.generateSalesReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );

      if (reportResponse.success && reportResponse.data != null) {
        _currentReport = reportResponse.data!;
        debugPrint('✅ [SaleReportsProvider] Report loaded: ${_currentReport!.formattedReportType}');
      } else {
        _setError(reportResponse.message ?? 'Failed to load report');
        return;
      }

      // Also fetch comparison data
      final comparisonResponse = await _reportsService.getSalesComparison(
        reportType: reportType,
      );

      if (comparisonResponse.success && comparisonResponse.data != null) {
        _comparison = comparisonResponse.data!;
        debugPrint('✅ [SaleReportsProvider] Comparison loaded');
      }

      _setSuccess('Report generated successfully');
    } catch (e) {
      debugPrint('❌ [SaleReportsProvider] Error loading report: $e');
      _setError('Failed to load report: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Set report type and reload
  Future<void> setReportType(String type) async {
    if (_selectedReportType == type.toLowerCase() && _currentReport != null) {
      return;
    }
    await loadReport(type);
  }

  /// Set custom date range
  Future<void> setCustomDateRange(DateTime start, DateTime end) async {
    _customStartDate = start;
    _customEndDate = end;
    await loadReport('custom', startDate: start, endDate: end);
  }

  /// Refresh current report
  Future<void> refreshReport() async {
    await loadReport(
      _selectedReportType,
      startDate: _customStartDate,
      endDate: _customEndDate,
    );
  }

  /// Export report as PDF
  Future<void> exportPdf() async {
    if (_currentReport == null) {
      _setError('No report data to export');
      return;
    }

    _setLoading(true);
    clearError();

    try {
      final fileName = await _reportsService.exportReportPdf(
        reportType: _selectedReportType,
        startDate: _customStartDate,
        endDate: _customEndDate,
      );

      if (fileName != null) {
        _setSuccess('Report exported successfully');
      } else {
        _setError('Failed to export report');
      }
    } catch (e) {
      _setError('Export failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Get formatted display for current period
  String get currentPeriodDisplay {
    if (_currentReport != null) {
      return _currentReport!.period.display;
    }
    return _getDefaultPeriodDisplay();
  }

  String _getDefaultPeriodDisplay() {
    final now = DateTime.now();
    switch (_selectedReportType) {
      case 'daily':
        return '${now.day}/${now.month}/${now.year}';
      case 'weekly':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return '${weekStart.day}/${weekStart.month} - ${now.day}/${now.month}/${now.year}';
      case 'monthly':
        return '${_getMonthName(now.month)} ${now.year}';
      case 'yearly':
        return '${now.year}';
      default:
        return 'Custom Period';
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  /// Get summary metrics for display
  Map<String, dynamic> getSummaryMetrics() {
    if (_currentReport == null) return {};

    final summary = _currentReport!.summary;
    return {
      'totalSales': summary.totalSales,
      'totalRevenue': summary.formattedRevenue,
      'totalProfit': summary.formattedProfit,
      'averageOrderValue': summary.formattedAOV,
      'profitMargin': summary.formattedMargin,
      'totalItems': summary.totalItemsSold,
    };
  }

  /// Get growth indicators
  Map<String, dynamic> getGrowthIndicators() {
    if (_comparison == null) return {};

    final growth = _comparison!.growth;
    return {
      'revenueGrowth': growth.formattedRevenueGrowth,
      'salesGrowth': growth.formattedSalesGrowth,
      'profitGrowth': growth.formattedProfitGrowth,
      'isRevenueUp': growth.isRevenueUp,
      'isSalesUp': growth.isSalesUp,
      'isProfitUp': growth.isProfitUp,
    };
  }

  /// Clear all data
  void clearData() {
    _currentReport = null;
    _comparison = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
