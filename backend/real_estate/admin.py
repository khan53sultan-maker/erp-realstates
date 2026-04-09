from django.contrib import admin
from .models import (
    Project, Plot, Dealer, RealEstateSale, Installment,
    InstallmentPayment, DealerPayment, LandownerPayment,
    LandownerCommissionPayment, RealEstateIncome, RealEstateExpense
)


@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ['name', 'location', 'landowner_name', 'total_plots', 'status', 'created_at']
    list_filter = ['status']
    search_fields = ['name', 'location', 'landowner_name']


@admin.register(Plot)
class PlotAdmin(admin.ModelAdmin):
    list_display = ['plot_number', 'project', 'plot_size', 'total_price', 'status', 'customer']
    list_filter = ['status', 'project']
    search_fields = ['plot_number', 'customer__name']


@admin.register(Dealer)
class DealerAdmin(admin.ModelAdmin):
    list_display = ['name', 'phone', 'dealer_type', 'commission_percentage', 'total_sales_count', 'total_commission_earned', 'paid_amount']
    list_filter = ['dealer_type']
    search_fields = ['name', 'phone']


@admin.register(RealEstateSale)
class RealEstateSaleAdmin(admin.ModelAdmin):
    list_display = ['plot', 'customer', 'dealer', 'total_price', 'sale_date', 'commission_status']
    list_filter = ['commission_status', 'sale_date']
    search_fields = ['plot__plot_number', 'customer__name', 'dealer__name']


@admin.register(Installment)
class InstallmentAdmin(admin.ModelAdmin):
    list_display = ['sale', 'amount', 'paid_amount', 'due_date', 'status']
    list_filter = ['status']
    search_fields = ['sale__plot__plot_number', 'sale__customer__name']


@admin.register(InstallmentPayment)
class InstallmentPaymentAdmin(admin.ModelAdmin):
    list_display = ['installment', 'amount', 'payment_date', 'receipt_number']
    search_fields = ['installment__sale__customer__name']


@admin.register(DealerPayment)
class DealerPaymentAdmin(admin.ModelAdmin):
    list_display = ['sale', 'amount', 'date', 'remarks']
    search_fields = ['sale__dealer__name']


@admin.register(LandownerPayment)
class LandownerPaymentAdmin(admin.ModelAdmin):
    list_display = ['sale', 'amount', 'date', 'remarks']
    search_fields = ['sale__plot__project__landowner_name']


@admin.register(LandownerCommissionPayment)
class LandownerCommissionPaymentAdmin(admin.ModelAdmin):
    list_display = ['sale', 'amount', 'date', 'remarks']
    search_fields = ['sale__plot__project__landowner_name']


@admin.register(RealEstateIncome)
class RealEstateIncomeAdmin(admin.ModelAdmin):
    list_display = ['income_type', 'amount', 'date', 'project', 'description']
    list_filter = ['income_type', 'project']
    search_fields = ['description']


@admin.register(RealEstateExpense)
class RealEstateExpenseAdmin(admin.ModelAdmin):
    list_display = ['category', 'amount', 'date', 'project', 'description']
    list_filter = ['category', 'project']
    search_fields = ['description']
