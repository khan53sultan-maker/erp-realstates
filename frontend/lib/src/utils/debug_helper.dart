import 'package:flutter/foundation.dart';
import 'dart:convert';

class DebugHelper {
  static const bool _isDebugMode = kDebugMode;

  /// Print API response data in formatted JSON
  static void printApiResponse(String endpoint, dynamic data) {
    if (!_isDebugMode) return;

    try {
      final formattedJson = const JsonEncoder.withIndent('  ').convert(data);
      debugPrint('🌐 API Response [$endpoint]:');
      debugPrint(formattedJson);
      debugPrint('─' * 80);
    } catch (e) {
      debugPrint('🌐 API Response [$endpoint]: $data');
      debugPrint('─' * 80);
    }
  }

  /// Print API request data in formatted JSON
  static void printApiRequest(String endpoint, dynamic data) {
    if (!_isDebugMode) return;

    try {
      final formattedJson = const JsonEncoder.withIndent('  ').convert(data);
      debugPrint('📤 API Request [$endpoint]:');
      debugPrint(formattedJson);
      debugPrint('─' * 80);
    } catch (e) {
      debugPrint('📤 API Request [$endpoint]: $data');
      debugPrint('─' * 80);
    }
  }

  /// Print JSON data with a custom label
  static void printJson(String label, dynamic data) {
    if (!_isDebugMode) return;

    try {
      final formattedJson = const JsonEncoder.withIndent('  ').convert(data);
      debugPrint('📄 $label:');
      debugPrint(formattedJson);
      debugPrint('─' * 80);
    } catch (e) {
      debugPrint('📄 $label: $data');
      debugPrint('─' * 80);
    }
  }

  /// Print error with context
  static void printError(String context, dynamic error) {
    if (!_isDebugMode) return;

    debugPrint('❌ Error in $context:');
    debugPrint('   $error');
    debugPrint('─' * 80);
  }

  /// Print warning with context
  static void printWarning(String context, String message) {
    if (!_isDebugMode) return;

    debugPrint('⚠️ Warning in $context:');
    debugPrint('   $message');
    debugPrint('─' * 80);
  }

  /// Print info message
  static void printInfo(String context, String message) {
    if (!_isDebugMode) return;

    debugPrint('ℹ️ Info in $context:');
    debugPrint('   $message');
    debugPrint('─' * 80);
  }

  /// Print success message
  static void printSuccess(String context, String message) {
    if (!_isDebugMode) return;

    debugPrint('✅ Success in $context:');
    debugPrint('   $message');
    debugPrint('─' * 80);
  }

  /// Print category model data for debugging
  static void printCategoryModel(String label, dynamic data) {
    if (!_isDebugMode) return;

    debugPrint('🏷️ $label:');
    if (data is Map<String, dynamic>) {
      debugPrint('   ID: ${data['id']}');
      debugPrint('   Name: ${data['name']}');
      debugPrint('   Description: ${data['description']}');
      debugPrint('   Is Active: ${data['is_active']}');
      debugPrint('   Created At: ${data['created_at']}');
      debugPrint('   Updated At: ${data['updated_at']}');
      debugPrint('   Created By: ${data['created_by']}');
    } else {
      debugPrint('   $data');
    }
    debugPrint('─' * 80);
  }

  /// Print product model data for debugging
  static void printProductModel(String label, dynamic data) {
    if (!_isDebugMode) return;

    debugPrint('📦 $label:');
    if (data is Map<String, dynamic>) {
      debugPrint('   ID: ${data['id']}');
      debugPrint('   Name: ${data['name']}');
      debugPrint('   Price: ${data['price']}');
      debugPrint('   Color: ${data['color']}');
      debugPrint('   Fabric: ${data['fabric']}');
      debugPrint('   Quantity: ${data['quantity']}');
      debugPrint('   Stock Status: ${data['stock_status']}');
      debugPrint('   Category: ${data['category_name'] ?? data['category_id']}');
      debugPrint('   Pieces: ${data['pieces']}');
      debugPrint('   Created At: ${data['created_at']}');
    } else {
      debugPrint('   $data');
    }
    debugPrint('─' * 80);
  }

  /// Print pagination info
  static void printPaginationInfo(String context, dynamic paginationData) {
    if (!_isDebugMode) return;

    debugPrint('📄 Pagination [$context]:');
    if (paginationData is Map<String, dynamic>) {
      debugPrint('   Current Page: ${paginationData['current_page']}');
      debugPrint('   Total Pages: ${paginationData['total_pages']}');
      debugPrint('   Total Count: ${paginationData['total_count']}');
      debugPrint('   Page Size: ${paginationData['page_size']}');
      debugPrint('   Has Next: ${paginationData['has_next']}');
      debugPrint('   Has Previous: ${paginationData['has_previous']}');
    } else {
      debugPrint('   $paginationData');
    }
    debugPrint('─' * 80);
  }

  /// Print cache operation
  static void printCacheOperation(String operation, String key, {dynamic data}) {
    if (!_isDebugMode) return;

    debugPrint('💾 Cache $operation [$key]:');
    if (data != null) {
      if (data is List) {
        debugPrint('   Items count: ${data.length}');
      } else if (data is Map) {
        debugPrint('   Data keys: ${data.keys.join(', ')}');
      } else {
        debugPrint('   Data: $data');
      }
    }
    debugPrint('─' * 80);
  }

  /// Print network status
  static void printNetworkStatus(String status, {String? details}) {
    if (!_isDebugMode) return;

    debugPrint('🌐 Network Status: $status');
    if (details != null) {
      debugPrint('   Details: $details');
    }
    debugPrint('─' * 80);
  }

  /// Print provider state change
  static void printProviderState(String provider, String state, {dynamic data}) {
    if (!_isDebugMode) return;

    debugPrint('🔄 Provider [$provider] State: $state');
    if (data != null) {
      debugPrint('   Data: $data');
    }
    debugPrint('─' * 80);
  }

  /// Print performance timing
  static void printPerformance(String operation, Duration duration) {
    if (!_isDebugMode) return;

    debugPrint('⏱️ Performance [$operation]: ${duration.inMilliseconds}ms');
    debugPrint('─' * 80);
  }

  /// Print authentication status
  static void printAuthStatus(String status, {String? userEmail}) {
    if (!_isDebugMode) return;

    debugPrint('🔐 Auth Status: $status');
    if (userEmail != null) {
      debugPrint('   User: $userEmail');
    }
    debugPrint('─' * 80);
  }

  /// Print validation errors
  static void printValidationErrors(String context, Map<String, dynamic> errors) {
    if (!_isDebugMode) return;

    debugPrint('❌ Validation Errors [$context]:');
    errors.forEach((key, value) {
      if (value is List) {
        debugPrint('   $key: ${value.join(', ')}');
      } else {
        debugPrint('   $key: $value');
      }
    });
    debugPrint('─' * 80);
  }

  /// Print database operation
  static void printDatabaseOperation(String operation, String table, {dynamic data}) {
    if (!_isDebugMode) return;

    debugPrint('🗄️ DB $operation [$table]:');
    if (data != null) {
      if (data is List) {
        debugPrint('   Records: ${data.length}');
      } else {
        debugPrint('   Data: $data');
      }
    }
    debugPrint('─' * 80);
  }

  /// Print app lifecycle event
  static void printLifecycleEvent(String event, {String? details}) {
    if (!_isDebugMode) return;

    debugPrint('🔄 Lifecycle Event: $event');
    if (details != null) {
      debugPrint('   Details: $details');
    }
    debugPrint('─' * 80);
  }

  /// Print memory usage (approximate)
  static void printMemoryUsage(String context) {
    if (!_isDebugMode) return;

    // Note: Actual memory usage tracking would require platform-specific implementation
    debugPrint('🧠 Memory Check [$context]: Tracking not implemented');
    debugPrint('─' * 80);
  }

  /// Print feature flag status
  static void printFeatureFlag(String flag, bool isEnabled) {
    if (!_isDebugMode) return;

    debugPrint('🚩 Feature Flag [$flag]: ${isEnabled ? 'ENABLED' : 'DISABLED'}');
    debugPrint('─' * 80);
  }
}
