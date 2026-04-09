import os
import django
from decimal import Decimal

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from real_estate.models import RealEstateIncome, RealEstateExpense

with open('db_inspect_output.txt', 'w') as f:
    f.write("--- Income Records ---\n")
    incomes = RealEstateIncome.objects.all()
    f.write(f"Total Income Records: {incomes.count()}\n")
    for i in incomes:
        f.write(f"Type: '{i.income_type}', Amount: {i.amount}, Project: {i.project.name if i.project else 'None'}\n")

    f.write("\n--- Expense Records ---\n")
    expenses = RealEstateExpense.objects.all()
    f.write(f"Total Expense Records: {expenses.count()}\n")
    for e in expenses:
        f.write(f"Category: '{e.category}', Amount: {e.amount}, Project: {e.project.name if e.project else 'None'}\n")
