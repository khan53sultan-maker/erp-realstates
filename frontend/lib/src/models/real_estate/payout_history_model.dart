
class DealerPaymentRec {
  final String? id;
  final String saleId;
  final double amount;
  final String date;
  final String? remarks;

  DealerPaymentRec({
    this.id,
    required this.saleId,
    required this.amount,
    required this.date,
    this.remarks,
  });

  factory DealerPaymentRec.fromJson(Map<String, dynamic> json) {
    return DealerPaymentRec(
      id: json['id'],
      saleId: json['sale'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['date'] ?? '',
      remarks: json['remarks'],
    );
  }
}

class LandownerPaymentRec {
  final String? id;
  final String saleId;
  final double amount;
  final String date;
  final String? remarks;

  LandownerPaymentRec({
    this.id,
    required this.saleId,
    required this.amount,
    required this.date,
    this.remarks,
  });

  factory LandownerPaymentRec.fromJson(Map<String, dynamic> json) {
    return LandownerPaymentRec(
      id: json['id'],
      saleId: json['sale'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['date'] ?? '',
      remarks: json['remarks'],
    );
  }
}

class LandownerCommissionRec {
  final String? id;
  final String saleId;
  final double amount;
  final String date;
  final String? remarks;

  LandownerCommissionRec({
    this.id,
    required this.saleId,
    required this.amount,
    required this.date,
    this.remarks,
  });

  factory LandownerCommissionRec.fromJson(Map<String, dynamic> json) {
    return LandownerCommissionRec(
      id: json['id'],
      saleId: json['sale'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['date'] ?? '',
      remarks: json['remarks'],
    );
  }
}
