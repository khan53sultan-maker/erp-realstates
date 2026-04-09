import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from real_estate.models import RealEstateIncome, RealEstateExpense

print("--- Income Records ---")
for i in RealEstateIncome.objects.all():
    print(f"Type: {i.income_type}, Amount: {i.amount}, Project: {i.project.name if i.project else 'None'}")

print("\n--- Expense Records ---")
for e in RealEstateExpense.objects.all():
    print(f"Category: {e.category}, Amount: {e.amount}, Project: {e.project.name if e.project else 'None'}")
