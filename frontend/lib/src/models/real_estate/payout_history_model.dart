
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
      id: json['id']?.toString(),
      saleId: json['sale']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['date']?.toString() ?? '',
      remarks: json['remarks']?.toString(),
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
      id: json['id']?.toString(),
      saleId: json['sale']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['date']?.toString() ?? '',
      remarks: json['remarks']?.toString(),
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
      id: json['id']?.toString(),
      saleId: json['sale']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['date']?.toString() ?? '',
      remarks: json['remarks']?.toString(),
    );
  }
}

class DownPaymentRec {
  final String? id;
  final String saleId;
  final double amount;
  final String date;
  final String? receiptNumber;
  final String? remarks;

  DownPaymentRec({
    this.id,
    required this.saleId,
    required this.amount,
    required this.date,
    this.receiptNumber,
    this.remarks,
  });

  factory DownPaymentRec.fromJson(Map<String, dynamic> json) {
    return DownPaymentRec(
      id: json['id']?.toString(),
      saleId: json['sale']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['payment_date']?.toString() ?? '',
      receiptNumber: json['receipt_number']?.toString(),
      remarks: json['remarks']?.toString(),
    );
  }
}
