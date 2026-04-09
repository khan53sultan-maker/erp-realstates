import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../models/api_response.dart';
import '../../models/labor/labor_api_responses.dart';
import '../../models/labor/labor_model.dart';
import '../../utils/storage_service.dart';
import '../../utils/debug_helper.dart';
import '../api_client.dart';

class LaborServiceExtended {
  static final LaborServiceExtended _instance = LaborServiceExtended._internal();

  factory LaborServiceExtended() => _instance;

  LaborServiceExtended._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get labor statistics
  Future<ApiResponse<LaborStatisticsResponse>> getLaborStatistics() async {
    try {
      final response = await _apiClient.get(ApiConfig.laborStatistics);

      DebugHelper.printApiResponse('GET Labor Statistics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<LaborStatisticsResponse>.fromJson(
          response.data,
              (data) => LaborStatisticsResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborStatisticsResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get labor statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get labor statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborStatisticsResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get labor statistics error: ${e.toString()}');
      return ApiResponse<LaborStatisticsResponse>(
        success: false,
        message: 'An unexpected error occurred while getting labor statistics',
      );
    }
  }

  /// Get labors by city
  Future<ApiResponse<LaborsListResponse>> getLaborsByCity({
    required String city,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.laborsByCity(city),
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Labors by City', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<LaborsListResponse>.fromJson(
          response.data,
              (data) => LaborsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get labors by city',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get labors by city DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get labors by city error: ${e.toString()}');
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting labors by city',
      );
    }
  }

  /// Get labors by area
  Future<ApiResponse<LaborsListResponse>> getLaborsByArea({
    required String area,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.laborsByArea(area),
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Labors by Area', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<LaborsListResponse>.fromJson(
          response.data,
              (data) => LaborsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get labors by area',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get labors by area DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get labors by area error: ${e.toString()}');
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting labors by area',
      );
    }
  }

  /// Get labors by designation
  Future<ApiResponse<LaborsListResponse>> getLaborsByDesignation({
    required String designation,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.laborsByDesignation(designation),
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Labors by Designation', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<LaborsListResponse>.fromJson(
          response.data,
              (data) => LaborsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get labors by designation',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get labors by designation DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get labors by designation error: ${e.toString()}');
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting labors by designation',
      );
    }
  }

  /// Get new labors
  Future<ApiResponse<LaborsListResponse>> getNewLabors({
    int days = 30,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'days': days.toString(),
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.newLabors,
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET New Labors', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<LaborsListResponse>.fromJson(
          response.data,
              (data) => LaborsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get new labors',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get new labors DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get new labors error: ${e.toString()}');
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting new labors',
      );
    }
  }

  /// Get recent labors
  Future<ApiResponse<LaborsListResponse>> getRecentLabors({
    int days = 7,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'days': days.toString(),
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.recentLabors,
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Recent Labors', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<LaborsListResponse>.fromJson(
          response.data,
              (data) => LaborsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get recent labors',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get recent labors DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get recent labors error: ${e.toString()}');
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting recent labors',
      );
    }
  }

  /// Search labors
  Future<ApiResponse<LaborsListResponse>> searchLabors({
    required String query,
    String? city,
    String? area,
    String? designation,
    String? caste,
    String? gender,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'q': query,
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (area != null && area.isNotEmpty) {
        queryParams['area'] = area;
      }
      if (designation != null && designation.isNotEmpty) {
        queryParams['designation'] = designation;
      }
      if (caste != null && caste.isNotEmpty) {
        queryParams['caste'] = caste;
      }
      if (gender != null && gender.isNotEmpty) {
        queryParams['gender'] = gender;
      }

      final response = await _apiClient.get(
        ApiConfig.searchLabors,
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Search Labors', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<LaborsListResponse>.fromJson(
          response.data,
              (data) => LaborsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to search labors',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Search labors DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Search labors error: ${e.toString()}');
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: 'An unexpected error occurred while searching labors',
      );
    }
  }

  /// Get salary report
  Future<ApiResponse<LaborSalaryReportResponse>> getSalaryReport() async {
    try {
      final response = await _apiClient.get(ApiConfig.laborSalaryReport);

      DebugHelper.printApiResponse('GET Salary Report', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<LaborSalaryReportResponse>.fromJson(
          response.data,
              (data) => LaborSalaryReportResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborSalaryReportResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get salary report',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get salary report DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborSalaryReportResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get salary report error: ${e.toString()}');
      return ApiResponse<LaborSalaryReportResponse>(
        success: false,
        message: 'An unexpected error occurred while getting salary report',
      );
    }
  }

  /// Get demographics report
  Future<ApiResponse<LaborDemographicsReportResponse>> getDemographicsReport() async {
    try {
      final response = await _apiClient.get(ApiConfig.laborDemographicsReport);

      DebugHelper.printApiResponse('GET Demographics Report', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<LaborDemographicsReportResponse>.fromJson(
          response.data,
              (data) => LaborDemographicsReportResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborDemographicsReportResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get demographics report',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get demographics report DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborDemographicsReportResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get demographics report error: ${e.toString()}');
      return ApiResponse<LaborDemographicsReportResponse>(
        success: false,
        message: 'An unexpected error occurred while getting demographics report',
      );
    }
  }

  /// Bulk labor actions
  Future<ApiResponse<Map<String, dynamic>>> bulkLaborActions({
    required List<String> laborIds,
    required String action,
    double? salaryAmount,
    double? salaryPercentage,
  }) async {
    try {
      final request = LaborBulkActionRequest(
        laborIds: laborIds,
        action: action,
        salaryAmount: salaryAmount,
        salaryPercentage: salaryPercentage,
      );

      DebugHelper.printJson('Bulk Labor Actions Request', request.toJson());

      final response = await _apiClient.post(
        ApiConfig.bulkLaborActions,
        data: request.toJson(),
      );

      DebugHelper.printApiResponse('POST Bulk Labor Actions', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: response.data['message'] ?? 'Bulk action completed successfully',
          data: response.data['data'] as Map<String, dynamic>?,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to perform bulk action',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Bulk labor actions DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Bulk labor actions error: ${e.toString()}');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'An unexpected error occurred while performing bulk action',
      );
    }
  }

  /// Duplicate labor
  Future<ApiResponse<LaborModel>> duplicateLabor({
    required String id,
    required String newName,
    required String newPhone,
    required String newCnic,
    int? newAge,
  }) async {
    try {
      final requestData = {
        'name': newName,
        'phone_number': newPhone,
        'cnic': newCnic,
      };

      if (newAge != null) {
        requestData['age'] = newAge.toString();
      }

      DebugHelper.printJson('Duplicate Labor Request', requestData);

      final response = await _apiClient.post(
        ApiConfig.duplicateLabor(id),
        data: requestData,
      );

      DebugHelper.printApiResponse('POST Duplicate Labor', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<LaborModel>.fromJson(
          response.data,
              (data) => LaborModel.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to duplicate labor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Duplicate labor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborModel>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Duplicate labor error: ${e.toString()}');
      return ApiResponse<LaborModel>(
        success: false,
        message: 'An unexpected error occurred while duplicating labor',
      );
    }
  }

  /// Update labor contact information
  Future<ApiResponse<LaborModel>> updateLaborContact({
    required String id,
    String? phoneNumber,
    String? city,
    String? area,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (phoneNumber != null) requestData['phone_number'] = phoneNumber;
      if (city != null) requestData['city'] = city;
      if (area != null) requestData['area'] = area;

      DebugHelper.printJson('Update Labor Contact Request', requestData);

      final response = await _apiClient.put(
        ApiConfig.updateLaborContact(id),
        data: requestData,
      );

      DebugHelper.printApiResponse('PUT Update Labor Contact', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          // The contact update endpoint returns partial data, so we create a minimal response
          return ApiResponse<LaborModel>(
            success: true,
            message: responseData['message'] as String? ?? 'Labor contact updated successfully',
            data: null, // Contact endpoint doesn't return full labor data
          );
        } else {
          return ApiResponse<LaborModel>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to update labor contact',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<LaborModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update labor contact',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update labor contact DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborModel>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Update labor contact error: ${e.toString()}');
      return ApiResponse<LaborModel>(
        success: false,
        message: 'An unexpected error occurred while updating labor contact',
      );
    }
  }

  /// Update labor salary and designation
  Future<ApiResponse<LaborModel>> updateLaborSalary({
    required String id,
    double? salary,
    String? designation,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (salary != null) requestData['salary'] = salary;
      if (designation != null) requestData['designation'] = designation;

      DebugHelper.printJson('Update Labor Salary Request', requestData);

      final response = await _apiClient.put(
        ApiConfig.updateLaborSalary(id),
        data: requestData,
      );

      DebugHelper.printApiResponse('PUT Update Labor Salary', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          // The salary update endpoint returns partial data, so we create a minimal response
          return ApiResponse<LaborModel>(
            success: true,
            message: responseData['message'] as String? ?? 'Labor salary updated successfully',
            data: null, // Salary endpoint doesn't return full labor data
          );
        } else {
          return ApiResponse<LaborModel>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to update labor salary',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<LaborModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update labor salary',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update labor salary DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborModel>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Update labor salary error: ${e.toString()}');
      return ApiResponse<LaborModel>(
        success: false,
        message: 'An unexpected error occurred while updating labor salary',
      );
    }
  }

  /// Get labor payments (placeholder)
  Future<ApiResponse<LaborPaymentsResponse>> getLaborPayments({
    required String laborId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(
        ApiConfig.laborPayments(laborId),
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Labor Payments', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<LaborPaymentsResponse>.fromJson(
          response.data,
              (data) => LaborPaymentsResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborPaymentsResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get labor payments',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get labor payments DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborPaymentsResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get labor payments error: ${e.toString()}');
      return ApiResponse<LaborPaymentsResponse>(
        success: false,
        message: 'An unexpected error occurred while getting labor payments',
      );
    }
  }

  /// Get labors with advanced search parameters
  Future<ApiResponse<LaborsListResponse>> getLaborsAdvanced({
    String? search,
    String? city,
    String? area,
    String? designation,
    String? caste,
    String? gender,
    String? minSalary,
    String? maxSalary,
    String? minAge,
    String? maxAge,
    DateTime? joinedAfter,
    DateTime? joinedBefore,
    bool showInactive = false,
    String sortBy = 'name',
    String sortOrder = 'asc',
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'show_inactive': showInactive.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (area != null && area.isNotEmpty) {
        queryParams['area'] = area;
      }
      if (designation != null && designation.isNotEmpty) {
        queryParams['designation'] = designation;
      }
      if (caste != null && caste.isNotEmpty) {
        queryParams['caste'] = caste;
      }
      if (gender != null && gender.isNotEmpty) {
        queryParams['gender'] = gender;
      }
      if (minSalary != null && minSalary.isNotEmpty) {
        queryParams['min_salary'] = minSalary;
      }
      if (maxSalary != null && maxSalary.isNotEmpty) {
        queryParams['max_salary'] = maxSalary;
      }
      if (minAge != null && minAge.isNotEmpty) {
        queryParams['min_age'] = minAge;
      }
      if (maxAge != null && maxAge.isNotEmpty) {
        queryParams['max_age'] = maxAge;
      }
      if (joinedAfter != null) {
        queryParams['joined_after'] = joinedAfter.toIso8601String().split('T')[0];
      }
      if (joinedBefore != null) {
        queryParams['joined_before'] = joinedBefore.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(
        ApiConfig.labors,
        queryParameters: queryParams,
      );

      DebugHelper.printApiResponse('GET Labors Advanced', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<LaborsListResponse>.fromJson(
          response.data,
              (data) => LaborsListResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<LaborsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get labors',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get labors advanced DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: apiError.message,
        errors: apiError.errors,
      );
    } catch (e) {
      debugPrint('Get labors advanced error: ${e.toString()}');
      return ApiResponse<LaborsListResponse>(
        success: false,
        message: 'An unexpected error occurred while getting labors',
      );
    }
  }
}
