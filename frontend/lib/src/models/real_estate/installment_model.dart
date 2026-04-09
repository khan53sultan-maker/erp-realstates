class InstallmentPayment {
  final String? id;
  final String installmentId;
  final double amount;
  final String paymentDate;
  final String? receiptNumber;
  final String? remarks;

  InstallmentPayment({
    this.id,
    required this.installmentId,
    required this.amount,
    required this.paymentDate,
    this.receiptNumber,
    this.remarks,
  });

  factory InstallmentPayment.fromJson(Map<String, dynamic> json) {
    return InstallmentPayment(
      id: json['id'],
      installmentId: json['installment'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentDate: json['payment_date'] ?? '',
      receiptNumber: json['receipt_number'],
      remarks: json['remarks'],
    );
  }
}

class RealEstateInstallment {
  final String? id;
  final String saleId;
  final double amount;
  final double paidAmount;
  final String dueDate;
  final String? paidDate;
  final String status;
  final String? receiptNumber;
  final String? paymentRemarks;
  final List<InstallmentPayment> paymentHistory;

  RealEstateInstallment({
    this.id,
    required this.saleId,
    required this.amount,
    this.paidAmount = 0.0,
    required this.dueDate,
    this.paidDate,
    this.status = 'PENDING',
    this.receiptNumber,
    this.paymentRemarks,
    this.paymentHistory = const [],
  });

  factory RealEstateInstallment.fromJson(Map<String, dynamic> json) {
    var historyList = json['payment_history'] as List? ?? [];
    List<InstallmentPayment> history = historyList.map((e) => InstallmentPayment.fromJson(e)).toList();

    return RealEstateInstallment(
      id: json['id'],
      saleId: json['sale'],
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      dueDate: json['due_date'],
      paidDate: json['paid_date'],
      status: json['status'],
      receiptNumber: json['receipt_number'],
      paymentRemarks: json['payment_remarks'],
      paymentHistory: history,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sale': saleId,
      'amount': amount,
      'paid_amount': paidAmount,
      'due_date': dueDate,
      'paid_date': paidDate,
      'status': status,
      if (paymentRemarks != null) 'payment_remarks': paymentRemarks,
    };
  }
}
