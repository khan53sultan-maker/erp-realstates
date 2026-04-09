"""
Simplified Dashboard Analytics View - Daily Order Count Only
"""

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from django.db.models import Sum, Count
from datetime import timedelta
import logging

# Import models
from sales.models import Sales

# Set up logger
logger = logging.getLogger(__name__)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def dashboard_analytics(request):
    """
    Simplified Dashboard Analytics - Daily Order Count Only
    """
    try:
        logger.info("=== DASHBOARD ANALYTICS API CALLED ===")
        
        # Date ranges
        today = timezone.now().date()
        current_month_start = today.replace(day=1)
        
        logger.info(f"DEBUG: Date ranges - today: {today}, current_month_start: {current_month_start}")
        
        # =====================================================
        # SALES METRICS - SIMPLIFIED
        # =====================================================
        
        # Debug: Check total sales in database
        all_sales_count = Sales.objects.filter(is_active=True).count()
        logger.info(f"DEBUG: Total sales in database: {all_sales_count}")
        
        # Debug: Check sales this month
        this_month_sales = Sales.objects.filter(
            is_active=True,
            date_of_sale__gte=current_month_start
        )
        this_month_count = this_month_sales.count()
        logger.info(f"DEBUG: Sales this month: {this_month_count}")
        
        # Debug: Show some sample sales
        sample_sales = Sales.objects.filter(is_active=True)[:3]
        for sale in sample_sales:
            logger.info(f"DEBUG: Sample sale - ID: {sale.id}, date: {sale.date_of_sale}, total: {sale.grand_total}, active: {sale.is_active}")
        
        # Total sales (current month) - Including POS and Real Estate
        from real_estate.models import RealEstateSale
        
        pos_sales_result = Sales.objects.filter(
            is_active=True,
            date_of_sale__gte=current_month_start
        ).aggregate(total=Sum('grand_total'))
        
        re_sales_result = RealEstateSale.objects.filter(
            sale_date__gte=current_month_start
        ).aggregate(total=Sum('total_price'))
        
        total_sales = (pos_sales_result['total'] or 0) + (re_sales_result['total'] or 0)
        
        # Total orders (current month)
        pos_orders = Sales.objects.filter(
            is_active=True,
            date_of_sale__gte=current_month_start
        ).count()
        
        re_orders = RealEstateSale.objects.filter(
            sale_date__gte=current_month_start
        ).count()
        
        total_orders = pos_orders + re_orders
        
        logger.info(f"DEBUG: POS Sales: {pos_sales_result['total']}, RE Sales: {re_sales_result['total']}")
        logger.info(f"DEBUG: total_sales: {total_sales}, total_orders: {total_orders}")
        
        # Daily order count for the last 7 days (Optimized)
        start_date = today - timedelta(days=6)
        
        pos_daily = Sales.objects.filter(
            is_active=True,
            date_of_sale__date__gte=start_date
        ).values('date_of_sale__date').annotate(count=Count('id'))
        
        re_daily = RealEstateSale.objects.filter(
            sale_date__gte=start_date
        ).values('sale_date').annotate(count=Count('id'))
        
        pos_counts = {str(item['date_of_sale__date']): item['count'] for item in pos_daily}
        re_counts = {str(item['sale_date']): item['count'] for item in re_daily}
        
        daily_orders = []
        for i in range(7):
            date = today - timedelta(days=6-i)
            date_str = str(date)
            count = pos_counts.get(date_str, 0) + re_counts.get(date_str, 0)
            
            daily_orders.append({
                'date': date.isoformat(),
                'day_name': date.strftime('%a'),
                'order_count': count,
            })
        
        logger.info(f"DEBUG: daily_orders calculated: {len(daily_orders)} days")
        
        # =====================================================
        # ADDITIONAL METRICS
        # =====================================================
        
        # Customer metrics
        from customers.models import Customer
        total_customers = Customer.objects.filter(is_active=True).count()
        active_customers = Customer.objects.filter(is_active=True).count()
        
        # Latest customers (recent 5)
        latest_customers = Customer.objects.filter(is_active=True).order_by('-created_at')[:5]
        latest_customers_data = []
        for customer in latest_customers:
            latest_customers_data.append({
                'id': str(customer.id),
                'name': customer.name,
                'email': customer.email or '',
                'phone': customer.phone or '',
                'total_spent': float(customer.total_sales_amount),  # Calculate from customer's sales
                'total_orders': customer.total_sales_count,  # Get from customer's sales count
                'created_at': customer.created_at.isoformat(),
                'avatar': '',
            })
        
        # Vendor metrics  
        from vendors.models import Vendor
        total_vendors = Vendor.objects.filter(is_active=True).count()
        active_vendors = Vendor.objects.filter(is_active=True).count()
        
        # Product metrics
        from products.models import Product
        total_products = Product.objects.filter(is_active=True).count()
        low_stock_products = Product.objects.filter(is_active=True, quantity__lte=5).count()
        
        # Trending products (top 5 by sales)
        from sales.models import SaleItem
        trending_products = SaleItem.objects.filter(
            sale__is_active=True,
            sale__date_of_sale__gte=current_month_start
        ).values('product__name', 'product__id').annotate(
            total_quantity=Sum('quantity'),
            total_revenue=Sum('line_total')  # Fixed: use line_total instead of total_price
        ).order_by('-total_quantity')[:5]
        
        trending_products_data = []
        for product in trending_products:
            trending_products_data.append({
                'id': str(product['product__id']),
                'name': product['product__name'],
                'sales': int(product['total_quantity']),
                'revenue': float(product['total_revenue']),
                'stock': 0,  # Would need to get from Product model
                'category': '',
                'image': None,
            })
        
        # Expense metrics (simplified)
        from expenses.models import Expense
        total_expenses = Expense.objects.filter(
            is_active=True,
            date__gte=current_month_start
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        # Profit & Loss calculations
        net_profit = float(total_sales) - float(total_expenses)
        profit_margin = (net_profit / float(total_sales) * 100) if float(total_sales) > 0 else 0
        
        # Sales overview breakdown
        sales_overview = {
            'this_month': float(total_sales),
            'orders_count': total_orders,
            'average_order_value': float(total_sales) / total_orders if total_orders > 0 else 0,
            'daily_average': float(total_sales) / 30,  # Assuming 30 days
        }
        
        logger.info(f"DEBUG: Additional metrics - customers: {total_customers}, vendors: {total_vendors}, products: {total_products}, expenses: {total_expenses}")
        logger.info(f"DEBUG: Latest customers: {len(latest_customers_data)}, Trending products: {len(trending_products_data)}")
        
        # =====================================================
        # RESPONSE DATA - ENHANCED
        # =====================================================
        
        response_data = {
            # Sales metrics
            'total_sales': float(total_sales),
            'total_orders': total_orders,
            
            # Daily order analytics
            'daily_orders': daily_orders,
            
            # Customer metrics
            'total_customers': total_customers,
            'active_customers': active_customers,
            'latest_customers': latest_customers_data,
            
            # Vendor metrics
            'total_vendors': total_vendors,
            'active_vendors': active_vendors,
            
            # Product metrics
            'total_products': total_products,
            'low_stock_products': low_stock_products,
            'trending_products': trending_products_data,
            
            # Financial metrics
            'total_expenses': float(total_expenses),
            'total_revenue': float(total_sales),  # Alias for compatibility
            'net_profit': net_profit,
            'profit_margin': profit_margin,
            
            # Sales overview
            'sales_overview': sales_overview,
            
            # Basic info
            'current_month': current_month_start.isoformat(),
            'today': today.isoformat(),
        }
        
        logger.info("=== DASHBOARD ANALYTICS API SUCCESS ===")
        return Response({
            'success': True,
            'data': response_data
        })
        
    except Exception as e:
        logger.error(f"Dashboard analytics error: {e}")
        logger.error(f"Exception type: {type(e)}")
        import traceback
        logger.error(f"Traceback: {traceback.format_exc()}")
        
        return Response({
            'success': False,
            'message': 'Failed to get dashboard analytics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def business_metrics(request):
    """Get business metrics list"""
    try:
        from .models import BusinessMetrics
        from .serializers import BusinessMetricSerializer
        
        metrics = BusinessMetrics.objects.all().order_by('-start_date')[:20]
        serializer = BusinessMetricSerializer(metrics, many=True)
        
        return Response({
            'success': True,
            'data': {
                'metrics': serializer.data,
                'pagination': {
                    'page': 1,
                    'page_size': 20,
                    'total_count': BusinessMetrics.objects.count(),
                    'total_pages': 1,
                    'has_next': False,
                    'has_previous': False
                }
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get business metrics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def realtime_analytics(request):
    """Get real-time analytics data"""
    try:
        now = timezone.now()
        today = now.date()
        
        # Today's sales
        today_sales = Sales.objects.filter(
            is_active=True,
            date_of_sale=today
        ).aggregate(
            total=Sum('grand_total'),
            count=Count('id')
        )
        
        # Today's orders
        today_orders = Order.objects.filter(
            is_active=True,
            order_date=today
        ).count()
        
        # Active sessions (customers who made purchases in last hour)
        one_hour_ago = now - timedelta(hours=1)
        active_sessions = Sales.objects.filter(
            is_active=True,
            created_at__gte=one_hour_ago
        ).values('customer').distinct().count()
        
        realtime_data = {
            'current_time': now.isoformat(),
            'today_date': today.isoformat(),
            'today_sales': float(today_sales['total'] or Decimal('0.00')),
            'today_sales_count': today_sales['count'] or 0,
            'today_orders': today_orders,
            'active_sessions': active_sessions,
            'pending_orders': Order.objects.filter(
                is_active=True,
                status='PENDING'
            ).count(),
        }
        
        return Response({
            'success': True,
            'data': realtime_data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get real-time analytics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)