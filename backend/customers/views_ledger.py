# backend/customers/views_ledger.py
"""
Customer Ledger API
Provides comprehensive transaction history for customers including:
- Sales
- Payments
- Receivables
- Returns
- Running balance calculation
"""

from django.db.models import Sum, Q, F
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from decimal import Decimal
from datetime import datetime, timedelta
from django.utils import timezone

from customers.models import Customer
from sales.models import Sales
from receivables.models import Receivable
from payments.models import Payment
from real_estate.models import RealEstateSale, Installment


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_ledger(request, customer_id):
    """
    Get comprehensive customer ledger with all transactions and running balance
    
    Query Parameters:
    - page: Page number (default: 1)
    - page_size: Items per page (default: 50, max: 100)
    - start_date: Filter from date (YYYY-MM-DD)
    - end_date: Filter to date (YYYY-MM-DD)
    - transaction_type: Filter by type (SALE, PAYMENT, RECEIVABLE, RETURN)
    
    Returns:
    - Chronological list of all customer transactions
    - Running balance after each transaction
    - Summary statistics
    - Pagination info
    """
    try:
        # Get customer (just to verify existence and activity)
        customer = Customer.objects.get(id=customer_id, is_active=True)
        
        # Pagination parameters
        page_size = min(int(request.GET.get('page_size', 50)), 100)
        page = int(request.GET.get('page', 1))
        
        # Date and type filtering
        start_date = request.GET.get('start_date')
        end_date = request.GET.get('end_date')
        transaction_type = request.GET.get('transaction_type', '').upper()
        
        # Use centralized utility for data
        from .ledger_utils import get_ledger_data
        ledger_entries, summary_base = get_ledger_data(customer_id, start_date, end_date, transaction_type)
        
        if ledger_entries is None:
            return Response({'success': False, 'message': 'Customer not found'}, status=status.HTTP_404_NOT_FOUND)

        # Build full summary for API
        total_sales = sum(e['amount'] for e in ledger_entries if e['type'] == 'SALE')
        total_re_sales = sum(e['amount'] for e in ledger_entries if e['type'] == 'RE SALE')
        total_payments = sum(e['amount'] for e in ledger_entries if e['type'] == 'PAYMENT')
        total_re_payments = sum(e['amount'] for e in ledger_entries if e['type'] == 'RE PAY')
        total_receivables = sum(e['amount'] for e in ledger_entries if e['type'] == 'REC.')
        total_receivable_payments = sum(e['amount'] for e in ledger_entries if e['type'] == 'REC. PAY')
        
        total_debit = total_sales + total_re_sales + total_receivables
        total_credit = total_payments + total_re_payments + total_receivable_payments
        outstanding_balance = total_debit - total_credit
        
        summary = {
            'customer_id': str(customer.id),
            'customer_name': customer.name,
            'customer_phone': customer.phone,
            'customer_email': customer.email or '',
            'total_transactions': len(ledger_entries),
            'total_sales': float(total_sales + total_re_sales),
            'total_sales_count': len([e for e in ledger_entries if e['type'] in ['SALE', 'RE SALE']]),
            'total_payments': float(total_payments + total_re_payments),
            'total_payments_count': len([e for e in ledger_entries if e['type'] in ['PAYMENT', 'RE PAY']]),
            'total_receivables': float(total_receivables),
            'total_receivables_count': len([e for e in ledger_entries if e['type'] == 'REC.']),
            'total_receivable_payments': float(total_receivable_payments),
            'total_debit': float(total_debit),
            'total_credit': float(total_credit),
            'outstanding_balance': float(outstanding_balance),
            'current_balance': float(summary_base['outstanding_balance']),
            'first_transaction_date': ledger_entries[0]['date'] if ledger_entries else None,
            'last_transaction_date': ledger_entries[-1]['date'] if ledger_entries else None,
        }
        
        # Pagination
        total_count = len(ledger_entries)
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        paginated_entries = ledger_entries[start_index:end_index]
        
        return Response({
            'success': True,
            'data': {
                'ledger_entries': paginated_entries,
                'summary': summary,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size if total_count > 0 else 0,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                }
            },
            'message': 'Customer ledger retrieved successfully'
        }, status=status.HTTP_200_OK)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist or is inactive.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except ValueError as e:
        return Response({
            'success': False,
            'message': 'Invalid parameters.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve customer ledger.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)