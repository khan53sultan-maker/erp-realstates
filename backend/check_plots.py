import os
import django
import sys

# Add the backend directory to sys.path
sys.path.append(r'd:\R_Technologies_Intership\pos-realstates-main\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from real_estate.models import Plot

plots = Plot.objects.all()
print(f"Total Plots in DB: {plots.count()}")
for p in plots:
    print(f"Plot: {p.plot_number}, Project: {p.project.name}, Size: {p.plot_size}, Price: {p.total_price}, Status: {p.status}")
