import os
import django
import sys

# Add the backend directory to sys.path
sys.path.append(r'd:\R_Technologies_Intership\pos-realstates-main\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from real_estate.models import Project, Plot, RealEstateSale, RealEstateIncome, RealEstateExpense

print(f"Total Projects: {Project.objects.count()}")
for p in Project.objects.all():
    plots_count = Plot.objects.filter(project=p).count()
    sales_count = RealEstateSale.objects.filter(plot__project=p).count()
    print(f"Project: {p.name}, Plots: {plots_count}, Sales: {sales_count}")

print(f"Total Sales: {RealEstateSale.objects.count()}")
print(f"Total Incomes: {RealEstateIncome.objects.count()}")
print(f"Total Expenses: {RealEstateExpense.objects.count()}")

from django.utils import timezone
today = timezone.now().date()
today_sales = RealEstateSale.objects.filter(sale_date=today).count()
print(f"Today's Sales Count: {today_sales}")
