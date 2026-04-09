import 'payout_history_model.dart';

class RealEstateSale {
  final String? id;
  final String plotId;
  final String? plotNumber;
  final String? plotSize;
  final String? projectName;
  final String? projectId;
  final String customerId;
  final String? customerName;
  final String? dealerId;
  final String? dealerName;
  final double totalPrice;
  final double downPayment;
  final double remainingBalance;
  final int installmentsCount;
  final double installmentAmount;
  final String? registrationNumber;
  final String? receiptNumber;
  final double receivedDownPayment;
  final double landownerCommissionReceived;
  final double landownerCommissionRemaining;
  final double currentDealerCommission;
  final double dealerCommissionRemaining;
  final String? saleDate;
  final double landownerCommission;
  final double dealerCommission;
  final String dealerCommissionType;
  final String commissionStatus;
  final double dealerPaidAmount;
  final double landownerPaidAmount;
  final double landownerTotalShare;
  final double landownerShareReceived;
  final double landownerShareRemaining;
  final double netCompanyIncome;
  final double totalReceived;
  final double currentBalance;
  final String? landownerPaymentRemarks;
  final double semiAnnualBalloonPayment;
  final String? blockName;
  final double cuttingPercentage;
  final bool isCommercial;
  final double allocationAmount;
  final double confirmationAmount;
  final double possessionAmount;
  final double processingAmount;
  final double lastPaymentAmount;
  final List<DealerPaymentRec> dealerPayments;
  final List<LandownerPaymentRec> landownerPayments;
  final List<LandownerCommissionRec> landownerCommissionHistory;

  RealEstateSale({
    this.id,
    required this.plotId,
    this.plotNumber,
    this.plotSize,
    this.projectName,
    this.projectId,
    required this.customerId,
    this.customerName,
    this.dealerId,
    this.dealerName,
    required this.totalPrice,
    this.registrationNumber,
    this.receiptNumber,
    required this.downPayment,
    this.receivedDownPayment = 0.0,
    required this.remainingBalance,
    this.installmentsCount = 0,
    this.installmentAmount = 0.0,
    this.saleDate,
    this.landownerCommission = 0.0,
    this.landownerCommissionReceived = 0.0,
    this.landownerCommissionRemaining = 0.0,
    this.dealerCommission = 0.0,
    this.currentDealerCommission = 0.0,
    this.dealerCommissionRemaining = 0.0,
    this.dealerCommissionType = 'PLOT_PRICE',
    this.commissionStatus = 'PENDING',
    this.dealerPaidAmount = 0.0,
    this.landownerPaidAmount = 0.0,
    this.landownerTotalShare = 0.0,
    this.landownerShareReceived = 0.0,
    this.landownerShareRemaining = 0.0,
    this.netCompanyIncome = 0.0,
    this.totalReceived = 0.0,
    this.currentBalance = 0.0,
    this.landownerPaymentRemarks,
    this.semiAnnualBalloonPayment = 0.0,
    this.blockName,
    this.cuttingPercentage = 0.0,
    this.isCommercial = false,
    this.allocationAmount = 0.0,
    this.confirmationAmount = 0.0,
    this.possessionAmount = 0.0,
    this.processingAmount = 0.0,
    this.lastPaymentAmount = 0.0,
    this.dealerPayments = const <DealerPaymentRec>[],
    this.landownerPayments = const <LandownerPaymentRec>[],
    this.landownerCommissionHistory = const <LandownerCommissionRec>[],
  });

  factory RealEstateSale.fromJson(Map<String, dynamic> json) {
    var dPayList = json['dealer_payments'] as List? ?? [];
    List<DealerPaymentRec> dPayments = dPayList.map((p) => DealerPaymentRec.fromJson(p as Map<String, dynamic>)).toList();

    var lPayList = json['landowner_payments'] as List? ?? [];
    List<LandownerPaymentRec> lPayments = lPayList.map((p) => LandownerPaymentRec.fromJson(p as Map<String, dynamic>)).toList();

    var lcHistList = json['landowner_commission_history'] as List? ?? [];
    List<LandownerCommissionRec> lcHistory = lcHistList.map((p) => LandownerCommissionRec.fromJson(p as Map<String, dynamic>)).toList();

    return RealEstateSale(
      id: json['id']?.toString(),
      plotId: json['plot']?.toString() ?? '',
      plotNumber: json['plot_number']?.toString(),
      plotSize: json['plot_size']?.toString(),
      projectName: json['project_name']?.toString(),
      projectId: json['project']?.toString(),
      customerId: json['customer']?.toString() ?? '',
      customerName: json['customer_name']?.toString(),
      dealerId: json['dealer']?.toString(),
      dealerName: json['dealer_name']?.toString(),
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      registrationNumber: json['registration_number'],
      receiptNumber: json['receipt_number'],
      downPayment: double.tryParse(json['down_payment']?.toString() ?? '0') ?? 0.0,
      receivedDownPayment: double.tryParse(json['received_down_payment']?.toString() ?? '0') ?? 0.0,
      remainingBalance: double.tryParse(json['remaining_balance']?.toString() ?? '0') ?? 0.0,
      installmentsCount: json['installments_count'] ?? 0,
      installmentAmount: double.tryParse(json['installment_amount']?.toString() ?? '0') ?? 0.0,
      saleDate: json['sale_date'],
      landownerCommission: double.tryParse(json['landowner_commission']?.toString() ?? '0') ?? 0.0,
      landownerCommissionReceived: double.tryParse(json['landowner_commission_received']?.toString() ?? '0') ?? 0.0,
      landownerCommissionRemaining: double.tryParse(json['landowner_commission_remaining']?.toString() ?? '0') ?? 0.0,
      dealerCommission: double.tryParse(json['dealer_commission']?.toString() ?? '0') ?? 0.0,
      currentDealerCommission: double.tryParse(json['current_dealer_commission']?.toString() ?? '0') ?? 0.0,
      dealerCommissionRemaining: double.tryParse(json['dealer_commission_remaining']?.toString() ?? '0') ?? 0.0,
      dealerCommissionType: json['dealer_commission_type'] ?? 'PLOT_PRICE',
      commissionStatus: json['commission_status'] ?? 'PENDING',
      dealerPaidAmount: double.tryParse(json['dealer_paid_amount']?.toString() ?? '0') ?? 0.0,
      landownerPaidAmount: double.tryParse(json['landowner_paid_amount']?.toString() ?? '0') ?? 0.0,
      landownerTotalShare: double.tryParse(json['landowner_total_share']?.toString() ?? '0') ?? 0.0,
      landownerShareReceived: double.tryParse(json['landowner_share_received']?.toString() ?? '0') ?? 0.0,
      landownerShareRemaining: double.tryParse(json['landowner_share_remaining']?.toString() ?? '0') ?? 0.0,
      netCompanyIncome: double.tryParse(json['net_company_income']?.toString() ?? '0') ?? 0.0,
      totalReceived: double.tryParse(json['total_received']?.toString() ?? '0') ?? 0.0,
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      landownerPaymentRemarks: json['landowner_payment_remarks'],
      semiAnnualBalloonPayment: double.tryParse(json['semi_annual_balloon_payment']?.toString() ?? '0') ?? 0.0,
      blockName: json['block_name'],
      cuttingPercentage: double.tryParse(json['cutting_percentage']?.toString() ?? '0') ?? 0.0,
      isCommercial: json['is_commercial'] ?? false,
      allocationAmount: double.tryParse(json['allocation_amount']?.toString() ?? '0') ?? 0.0,
      confirmationAmount: double.tryParse(json['confirmation_amount']?.toString() ?? '0') ?? 0.0,
      possessionAmount: double.tryParse(json['possession_amount']?.toString() ?? '0') ?? 0.0,
      processingAmount: double.tryParse(json['processing_amount']?.toString() ?? '0') ?? 0.0,
      lastPaymentAmount: double.tryParse(json['last_payment_amount']?.toString() ?? '0') ?? 0.0,
      dealerPayments: dPayments,
      landownerPayments: lPayments,
      landownerCommissionHistory: lcHistory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'plot': plotId,
      'customer': customerId,
      'dealer': dealerId,
      'total_price': totalPrice,
      'registration_number': registrationNumber,
      'receipt_number': receiptNumber,
      'down_payment': downPayment,
      'received_down_payment': receivedDownPayment,
      'remaining_balance': remainingBalance,
      'installments_count': installmentsCount,
      'installment_amount': installmentAmount,
      'dealer_commission_type': dealerCommissionType,
      'commission_status': commissionStatus,
      'dealer_paid_amount': dealerPaidAmount,
      'landowner_paid_amount': landownerPaidAmount,
      'landowner_commission_received': landownerCommissionReceived,
      'landowner_payment_remarks': landownerPaymentRemarks,
      'semi_annual_balloon_payment': semiAnnualBalloonPayment,
      'block_name': blockName,
      'cutting_percentage': cuttingPercentage,
      'is_commercial': isCommercial,
      'allocation_amount': allocationAmount,
      'confirmation_amount': confirmationAmount,
      'possession_amount': possessionAmount,
      'processing_amount': processingAmount,
      'last_payment_amount': lastPaymentAmount,
    };
  }
}
