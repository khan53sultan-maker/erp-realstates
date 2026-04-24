from rest_framework import serializers
from .models import (
    Project, Plot, Dealer, RealEstateSale, Installment, 
    InstallmentPayment, RealEstateIncome, RealEstateExpense,
    DealerPayment, LandownerPayment, LandownerCommissionPayment,
    DownPaymentPayment
)
from customers.models import Customer

class ProjectSerializer(serializers.ModelSerializer):
    plots_count = serializers.IntegerField(source='plots.count', read_only=True)
    available_plots = serializers.SerializerMethodField()

    class Meta:
        model = Project
        fields = '__all__'

    def get_available_plots(self, obj):
        return obj.plots.filter(status='AVAILABLE').count()

class DealerSerializer(serializers.ModelSerializer):
    pending_amount = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = Dealer
        fields = '__all__'

class PlotSerializer(serializers.ModelSerializer):
    project_name = serializers.CharField(source='project.name', read_only=True)
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    dealer_name = serializers.CharField(source='dealer.name', read_only=True)
    project_landowner_commission_percentage = serializers.DecimalField(
        source='project.landowner_commission_percentage', 
        max_digits=5, 
        decimal_places=2, 
        read_only=True
    )

    class Meta:
        model = Plot
        fields = '__all__'

class InstallmentPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = InstallmentPayment
        fields = '__all__'

class DealerPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = DealerPayment
        fields = '__all__'

class LandownerPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = LandownerPayment
        fields = '__all__'

class LandownerCommissionPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = LandownerCommissionPayment
        fields = '__all__'

class DownPaymentPaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = DownPaymentPayment
        fields = '__all__'

class InstallmentSerializer(serializers.ModelSerializer):
    payment_history = InstallmentPaymentSerializer(many=True, read_only=True)

    class Meta:
        model = Installment
        fields = [
            'id', 'sale', 'amount', 'paid_amount', 'due_date', 
            'paid_date', 'status', 'receipt_number', 'payment_remarks', 'payment_history',
            'created_at', 'updated_at'
        ]

class RealEstateSaleSerializer(serializers.ModelSerializer):
    installments = InstallmentSerializer(many=True, read_only=True)
    dealer_payments = DealerPaymentSerializer(many=True, read_only=True)
    landowner_payments = LandownerPaymentSerializer(many=True, read_only=True)
    landowner_commission_history = LandownerCommissionPaymentSerializer(many=True, read_only=True)
    down_payment_history = DownPaymentPaymentSerializer(many=True, read_only=True)
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    plot_number = serializers.CharField(source='plot.plot_number', read_only=True)
    plot_size = serializers.CharField(source='plot.plot_size', read_only=True)
    project_name = serializers.CharField(source='plot.project.name', read_only=True)
    dealer_name = serializers.CharField(source='dealer.name', read_only=True)
    net_company_income = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    total_received = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    current_balance = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    project = serializers.ReadOnlyField(source='plot.project_id')

    landowner_total_share = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    landowner_share_received = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    landowner_share_remaining = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = RealEstateSale
        fields = [
            'id', 'plot', 'customer', 'dealer', 'total_price', 'registration_number', 'receipt_number',
            'down_payment', 'received_down_payment', 'remaining_balance', 
            'installments_count', 'installment_amount', 'sale_date', 
            'landowner_commission', 'landowner_commission_received', 'landowner_commission_remaining',
            'dealer_commission', 'current_dealer_commission', 'dealer_commission_remaining',
            'dealer_commission_type', 'commission_status', 'dealer_paid_amount',
            'landowner_paid_amount', 'landowner_payment_remarks', 'remarks', 'semi_annual_balloon_payment', 
            'landowner_total_share', 'landowner_share_received', 'landowner_share_remaining',
            'block_name', 'cutting_percentage', 'is_commercial',
            'allocation_amount', 'confirmation_amount', 'possession_amount', 'processing_amount', 'last_payment_amount',
            'net_company_income', 'installments', 'dealer_payments', 'landowner_payments',
            'landowner_commission_history', 'down_payment_history',
            'customer_name', 'plot_number', 'plot_size', 'project_name', 'project', 'dealer_name', 
            'total_received', 'current_balance', 'created_at', 'updated_at'
        ]

class RealEstateIncomeSerializer(serializers.ModelSerializer):
    project_name = serializers.CharField(source='project.name', read_only=True)

    class Meta:
        model = RealEstateIncome
        fields = '__all__'

class RealEstateExpenseSerializer(serializers.ModelSerializer):
    project_name = serializers.CharField(source='project.name', read_only=True)

    class Meta:
        model = RealEstateExpense
        fields = '__all__'
