import 'package:flutter/material.dart';

class Expense {
  final String id;
  final String expense;
  final String description;
  final double amount;
  final String withdrawalBy;
  final DateTime date;
  final TimeOfDay time;
  final String? category;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByEmail;
  final String? saleId;

  final bool isPersonal;

  Expense({
    required this.id,
    required this.expense,
    required this.description,
    required this.amount,
    required this.withdrawalBy,
    required this.date,
    required this.time,
    this.category,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.createdByEmail,
    this.saleId,
    this.isPersonal = false,
  });

  // Formatted date for display
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Formatted time for display
  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Relative date (e.g., "Today", "Yesterday", "2 days ago")
  String get relativeDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(recordDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  // Combined date and time for sorting
  DateTime get dateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // Formatted amount for display
  String get formattedAmount {
    return 'PKR ${amount.toStringAsFixed(2)}';
  }

  // Get color for person
  Color get personColor {
    if (isPersonal) return Colors.purple;
    switch (withdrawalBy) {
      case 'Mr. Shahzain Baloch':
        return Colors.blue;
      case 'Mr Huzaifa':
        return Colors.green;
      default:
        return Colors.teal;
    }
  }

  // Withdrawal initials for display
  String get withdrawalInitials {
    final nameParts = withdrawalBy.trim().split(' ');
    if (nameParts.isEmpty || withdrawalBy.isEmpty) return '??';
    
    String initials = '';
    for (final part in nameParts) {
      if (part.startsWith(RegExp(r'(Mr\.?|Mrs\.?|Ms\.?|Sheikh)'))) {
        continue;
      }
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
      }
    }
    return initials.isNotEmpty ? initials : withdrawalBy.substring(0, min(2, withdrawalBy.length)).toUpperCase();
  }

  int min(int a, int b) => a < b ? a : b;

  // Expense summary for display
  String get expenseSummary {
    final summary = expense.length > 50 ? '${expense.substring(0, 47)}...' : expense;
    final personalLabel = isPersonal ? ' [Personal]' : '';
    return '$summary$personalLabel - ${formattedAmount}';
  }

  // Age in days since creation
  int get expenseAgeDays {
    return DateTime.now().difference(date).inDays;
  }

  // Copy method for updates
  Expense copyWith({
    String? id,
    String? expense,
    String? description,
    double? amount,
    String? withdrawalBy,
    DateTime? date,
    TimeOfDay? time,
    String? category,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdByEmail,
    String? saleId,
    bool? isPersonal,
  }) {
    return Expense(
      id: id ?? this.id,
      expense: expense ?? this.expense,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      withdrawalBy: withdrawalBy ?? this.withdrawalBy,
      date: date ?? this.date,
      time: time ?? this.time,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      saleId: saleId ?? this.saleId,
      isPersonal: isPersonal ?? this.isPersonal,
    );
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense': expense,
      'description': description,
      'amount': amount,
      'withdrawal_by': withdrawalBy,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'category': category,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by_email': createdByEmail,
      'sale': saleId,
      'is_personal': isPersonal,
    };
  }

  // Create from JSON API response
  factory Expense.fromJson(Map<String, dynamic> json) {
    // Parse time string (HH:MM or HH:MM:SS format)
    TimeOfDay parseTime(String timeStr) {
      try {
        if (timeStr.isEmpty) return TimeOfDay(hour: 0, minute: 0);
        final parts = timeStr.split(':');
        if (parts.length < 2 || parts.length > 3) return TimeOfDay(hour: 0, minute: 0);
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        return TimeOfDay(hour: 0, minute: 0);
      }
    }

    // Handle null values safely
    String safeString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    // Extract numeric amount from formatted amount string (e.g., "PKR 1,600.00" -> 1600.0)
    double extractAmountFromFormatted(String formattedAmount) {
      try {
        // Remove "PKR " prefix and commas, then parse
        final cleanAmount = formattedAmount.replaceAll('PKR ', '').replaceAll(',', '');
        return double.tryParse(cleanAmount) ?? 0.0;
      } catch (e) {
        return 0.0;
      }
    }

    DateTime safeDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          // Try parsing YYYY-MM-DD
          try {
            final parts = value.split('-');
            if (parts.length == 3) {
              return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
            }
          } catch (_) {}
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Expense(
      id: safeString(json['id']),
      expense: safeString(json['expense'] ?? json['expense_summary'] ?? ''),
      description: safeString(json['description'] ?? ''),
      amount: safeDouble(json['amount']) != 0.0 
          ? safeDouble(json['amount']) 
          : extractAmountFromFormatted(safeString(json['formatted_amount'] ?? '')),
      withdrawalBy: safeString(json['withdrawal_by'] ?? ''),
      date: safeDateTime(json['date']),
      time: parseTime(safeString(json['time'] ?? '00:00')),
      category: json['category'] != null ? safeString(json['category']) : null,
      notes: json['notes'] != null ? safeString(json['notes']) : null,
      createdAt: safeDateTime(json['created_at']),
      updatedAt: safeDateTime(json['updated_at'] ?? json['created_at']),
      createdByEmail: json['created_by_name'] != null ? safeString(json['created_by_name']) : null,
      saleId: json['sale'] != null ? safeString(json['sale']) : null,
      isPersonal: json['is_personal'] == true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Expense(id: $id, expense: $expense, amount: $amount, withdrawalBy: $withdrawalBy)';
  }
}

// Helper class for withdrawal authorities
class ExpenseAuthorities {
  static const List<String> authorities = [
    'Mr. Shahzain Baloch',
    'Mr Huzaifa'
  ];

  static String getDisplayName(String authority) {
    return authority;
  }

  static String getInitials(String authority) {
    final nameParts = authority.split(' ');
    String initials = '';
    for (final part in nameParts) {
      if (part.startsWith(RegExp(r'(Mr\.?|Mrs\.?|Ms\.?|Sheikh)'))) {
        continue;
      }
      if (part.isNotEmpty) {
        initials += part[0].toUpperCase();
      }
    }
    return initials.isNotEmpty ? initials : authority.substring(0, 2).toUpperCase();
  }
}
