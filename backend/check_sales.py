import os
import django
import sys

# Add the backend directory to sys.path
sys.path.append(r'd:\R_Technologies_Intership\pos-realstates-main\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from real_estate.models import RealEstateSale

sales = RealEstateSale.objects.all()
for s in sales:
    print(f"Sale ID: {s.id}, Project: {s.plot.project.name}, Price: {s.total_price}, DP: {s.down_payment}, Remaining: {s.remaining_balance}")
