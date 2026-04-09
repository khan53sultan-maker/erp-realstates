
import os
import django
import sys
from decimal import Decimal
from datetime import datetime
from io import BytesIO

# Set up Django environment
sys.path.append(r'd:\R_Technologies_Intership\pos-realstates-main\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from real_estate.models import RealEstateSale, Project
from real_estate.reports import generate_commission_report_excel

def generate_demo():
    # If there are no real sales, we'll use a mock queryset concept
    sales = RealEstateSale.objects.all()
    project = Project.objects.first()
    
    if not sales.exists():
        print("No real sales found, generating mock sales for demo...")
        from unittest.mock import MagicMock
        from django.db.models.query import QuerySet
        
        # Create a mock project
        mock_project = MagicMock(spec=Project)
        mock_project.name = "Iconic Estate Demo Project"
        
        # Create a mock sale
        mock_sale = MagicMock()
        mock_sale.sale_date = datetime.now()
        mock_sale.customer.name = "John Doe (Mock)"
        mock_sale.registration_number = "1,001"
        mock_sale.plot.plot_number = "A-123"
        mock_sale.plot.plot_size = "5 Marla"
        mock_sale.total_price = Decimal("3500000")
        mock_sale.total_received = Decimal("1050000")
        mock_sale.current_balance = Decimal("2450000")
        mock_sale.landowner_commission = Decimal("1050000")
        mock_sale.landowner_commission_received = Decimal("500000")
        mock_sale.landowner_commission_remaining = Decimal("550000")
        mock_sale.dealer.name = "Alpha Dealer"
        mock_sale.down_payment = Decimal("1050000")
        mock_sale.received_down_payment = Decimal("1050000")
        mock_sale.dealer_commission = Decimal("105000")
        mock_sale.current_dealer_commission = Decimal("105000")
        mock_sale.dealer_paid_amount = Decimal("50000")
        mock_sale.dealer_commission_remaining = Decimal("55000")
        mock_sale.commission_status = "PARTIAL"
        
        # We need a list that handles aggregate
        # Since reports.py uses .aggregate, MagicMock should intercept it
        mock_sales = MagicMock()
        mock_sales.__iter__.return_value = [mock_sale]
        mock_sales.aggregate.return_value = {'total': Decimal("3500000")}
        
        output_buffer = generate_commission_report_excel(mock_sales, mock_project)
    else:
        output_buffer = generate_commission_report_excel(sales, project)
    
    artifact_path = r'C:\Users\mirfa\.gemini\antigravity\brain\3b3ced40-a7db-4a10-a814-50df640918ff\commission_report_demo_v3.xlsx'
    
    with open(artifact_path, 'wb') as f:
        f.write(output_buffer.read())
    
    print(f"Generated demo report at: {artifact_path}")

if __name__ == "__main__":
    generate_demo()
