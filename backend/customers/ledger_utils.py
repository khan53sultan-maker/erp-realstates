# backend/customers/ledger_utils.py
from django.db.models import Sum, Q, F
from decimal import Decimal
from datetime import datetime
from django.utils import timezone

from customers.models import Customer
from sales.models import Sales
from receivables.models import Receivable
from payments.models import Payment
from real_estate.models import RealEstateSale, Installment

def get_ledger_data(customer_id, start_date=None, end_date=None, transaction_type=None):
    """
    Core logic to get customer ledger which can be reused by API and Reporting
    """
    try:
        customer = Customer.objects.get(id=customer_id, is_active=True)
    except (Customer.DoesNotExist, ValidationError, ValueError, TypeError):
        return [], None
        
    ledger_entries = []
    
    # 1. Sales
    sales_query = Sales.objects.filter(customer=customer, is_active=True)
    if start_date: sales_query = sales_query.filter(date_of_sale__gte=start_date)
    if end_date: sales_query = sales_query.filter(date_of_sale__lte=end_date)
    
    for sale in sales_query.order_by('date_of_sale', 'created_at'):
        ledger_entries.append({
            'id': str(sale.id),
            'type': 'SALE',
            'transaction_type': 'DEBIT',
            'amount': float(sale.grand_total),
            'date': sale.date_of_sale.strftime('%Y-%m-%d'),
            'time': sale.created_at.strftime('%H:%M:%S'),
            'description': f'Sale Invoice #{sale.invoice_number}',
            'reference_number': sale.invoice_number,
            'source_module': 'SALES',
        })
        
    # 2. Payments
    payments_query = Payment.objects.filter(sale__customer=customer, is_active=True)
    if start_date: payments_query = payments_query.filter(date__gte=start_date)
    if end_date: payments_query = payments_query.filter(date__lte=end_date)
    
    for payment in payments_query.order_by('date', 'time'):
        ledger_entries.append({
            'id': str(payment.id),
            'type': 'PAYMENT',
            'transaction_type': 'CREDIT',
            'amount': float(payment.amount_paid),
            'date': payment.date.strftime('%Y-%m-%d'),
            'time': payment.time.strftime('%H:%M:%S'),
            'description': f'Payment received - {payment.payment_method}',
            'reference_number': f'PAY-{str(payment.id)[:8].upper()}',
            'source_module': 'PAYMENTS',
        })
        
    # 3. Receivables
    receivables_query = Receivable.objects.filter(
        Q(debtor_phone=customer.phone) | Q(debtor_name__icontains=customer.name),
        is_active=True
    )
    if start_date: receivables_query = receivables_query.filter(date_lent__gte=start_date)
    if end_date: receivables_query = receivables_query.filter(date_lent__lte=end_date)
    
    for receivable in receivables_query.order_by('date_lent'):
        ledger_entries.append({
            'id': str(receivable.id),
            'type': 'REC.',
            'transaction_type': 'DEBIT',
            'amount': float(receivable.amount_given),
            'date': receivable.date_lent.strftime('%Y-%m-%d'),
            'time': receivable.created_at.strftime('%H:%M:%S'),
            'description': f'Amount lent: {receivable.reason_or_item}',
            'reference_number': f'REC-{str(receivable.id)[:8].upper()}',
            'source_module': 'RECEIVABLES',
        })
        
        if receivable.amount_returned > 0:
            return_date = receivable.updated_at.date() if hasattr(receivable.updated_at, 'date') else receivable.date_lent
            ledger_entries.append({
                'id': f"{receivable.id}_return",
                'type': 'REC. PAY',
                'transaction_type': 'CREDIT',
                'amount': float(receivable.amount_returned),
                'date': return_date.strftime('%Y-%m-%d'),
                'time': receivable.updated_at.strftime('%H:%M:%S'),
                'description': f'Payment received for: {receivable.reason_or_item}',
                'reference_number': f'REC-{str(receivable.id)[:8].upper()}-RETURN',
                'source_module': 'RECEIVABLES',
            })
            
    # 4. Real Estate
    re_sales_query = RealEstateSale.objects.filter(customer=customer)
    if start_date: re_sales_query = re_sales_query.filter(sale_date__gte=start_date)
    if end_date: re_sales_query = re_sales_query.filter(sale_date__lte=end_date)
    
    for re_sale in re_sales_query.order_by('sale_date', 'created_at'):
        ledger_entries.append({
            'id': str(re_sale.id),
            'type': 'RE SALE',
            'transaction_type': 'DEBIT',
            'amount': float(re_sale.total_price),
            'date': re_sale.sale_date.strftime('%Y-%m-%d'),
            'time': re_sale.created_at.strftime('%H:%M:%S'),
            'description': f'Plot Sale: {re_sale.plot.project.name} - {re_sale.plot.plot_number}',
            'reference_number': f'RE-{str(re_sale.id)[:8].upper()}',
            'source_module': 'REAL_ESTATE',
        })
        
        ledger_entries.append({
            'id': f"{re_sale.id}_downpayment",
            'type': 'RE PAY',
            'transaction_type': 'CREDIT',
            'amount': float(re_sale.down_payment),
            'date': re_sale.sale_date.strftime('%Y-%m-%d'),
            'time': re_sale.created_at.strftime('%H:%M:%S'),
            'description': f'Down Payment: {re_sale.plot.project.name} - {re_sale.plot.plot_number}',
            'reference_number': f'RE-DP-{str(re_sale.id)[:8].upper()}',
            'source_module': 'REAL_ESTATE',
        })
        
        for inst in re_sale.installments.filter(status='PAID'):
            pay_date = inst.paid_date or inst.due_date
            ledger_entries.append({
                'id': str(inst.id),
                'type': 'RE PAY',
                'transaction_type': 'CREDIT',
                'amount': float(inst.amount),
                'date': pay_date.strftime('%Y-%m-%d'),
                'time': inst.updated_at.strftime('%H:%M:%S'),
                'description': f'Installment Paid: {re_sale.plot.project.name} - {re_sale.plot.plot_number}',
                'reference_number': f'RE-INST-{str(inst.id)[:8].upper()}',
                'source_module': 'REAL_ESTATE',
            })
            
    # Sort and calculate balance
    ledger_entries.sort(key=lambda x: (x['date'], x['time']))
    
    running_balance = Decimal('0.00')
    for entry in ledger_entries:
        if entry['transaction_type'] == 'DEBIT':
            running_balance += Decimal(str(entry['amount']))
            entry['debit'] = float(entry['amount'])
            entry['credit'] = 0.0
        else:
            running_balance -= Decimal(str(entry['amount']))
            entry['debit'] = 0.0
            entry['credit'] = float(entry['amount'])
        entry['balance'] = float(running_balance)
        
    if transaction_type:
        ledger_entries = [e for e in ledger_entries if e['type'] == transaction_type]
        
    summary = {
        'customer_name': customer.name,
        'customer_phone': customer.phone,
        'outstanding_balance': float(running_balance),
    }
    
    return ledger_entries, summary
