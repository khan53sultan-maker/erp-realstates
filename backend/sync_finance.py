import os
import django
from decimal import Decimal

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from real_estate.models import RealEstateSale, RealEstateIncome, RealEstateExpense
from django.utils import timezone

def force_sync_finance():
    sales = RealEstateSale.objects.all()
    print(f"Force syncing {sales.count()} sales into Finance Breakdown...")
    
    income_created = 0
    expense_created = 0
    
    for sale in sales:
        # 1. Sync Income (Commission Received)
        # We use a unique description to strictly avoid duplicates
        desc_income = f"Auto-Sync: Commission for Plot {sale.plot.plot_number} ({sale.id})"
        if sale.landowner_commission_received > 0:
            income, created = RealEstateIncome.objects.get_or_create(
                description=desc_income,
                defaults={
                    'project': sale.plot.project,
                    'income_type': 'COMMISSION_RECEIVED',
                    'amount': sale.landowner_commission_received,
                    'date': sale.sale_date or timezone.now().date()
                }
            )
            if created: income_created += 1

        # 2. Sync Expense (Commission Paid)
        desc_expense = f"Auto-Sync: Dealer Payment for Plot {sale.plot.plot_number} ({sale.id})"
        if sale.dealer_paid_amount > 0:
            expense, created = RealEstateExpense.objects.get_or_create(
                description=desc_expense,
                defaults={
                    'project': sale.plot.project,
                    'category': 'COMMISSION_PAID',
                    'amount': sale.dealer_paid_amount,
                    'date': sale.sale_date or timezone.now().date()
                }
            )
            if created: expense_created += 1
            
    print(f"Completed! Added {income_created} Income and {expense_created} Expense records.")

if __name__ == "__main__":
    force_sync_finance()
