from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from datetime import timedelta
from django.db.models import Sum
from django.utils import timezone
from .models import (
    Project, Plot, Dealer, RealEstateSale, Installment, 
    RealEstateIncome, RealEstateExpense, DownPaymentPayment
)
from django.http import HttpResponse
from .serializers import (
    ProjectSerializer, PlotSerializer, DealerSerializer, 
    RealEstateSaleSerializer, InstallmentSerializer,
    RealEstateIncomeSerializer, RealEstateExpenseSerializer
)
from posapi.permissions import IsAdmin, IsManager, IsSalesAgent, IsAccountant

class ProjectViewSet(viewsets.ModelViewSet):
    pagination_class = None
    permission_classes = [IsSalesAgent]
    queryset = Project.objects.all()
    serializer_class = ProjectSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status']
    search_fields = ['name', 'location', 'landowner_name']
    ordering_fields = ['created_at', 'name']

    @action(detail=True, methods=['post'])
    def generate_plots(self, request, pk=None):
        project = self.get_object()
        plot_size = request.data.get('plot_size', '5 Marla')
        total_price = request.data.get('total_price', 0)
        
        created_count = 0
        for i in range(1, project.total_plots + 1):
            plot_num = str(i)
            if not Plot.objects.filter(project=project, plot_number=plot_num).exists():
                Plot.objects.create(
                    project=project,
                    plot_number=plot_num,
                    plot_size=plot_size,
                    total_price=total_price,
                    status='AVAILABLE'
                )
                created_count += 1
        
        return Response({'message': f'Successfully generated {created_count} plots.'})

class DealerViewSet(viewsets.ModelViewSet):
    permission_classes = [IsSalesAgent]
    queryset = Dealer.objects.all()
    serializer_class = DealerSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'phone']
    ordering_fields = ['name', 'total_sales_count']

class PlotViewSet(viewsets.ModelViewSet):
    permission_classes = [IsSalesAgent]
    queryset = Plot.objects.all()
    serializer_class = PlotSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['project', 'status', 'plot_size']
    search_fields = ['plot_number', 'customer__name']
    ordering_fields = ['plot_number', 'total_price']

class RealEstateSaleViewSet(viewsets.ModelViewSet):
    pagination_class = None
    permission_classes = [IsSalesAgent]
    queryset = RealEstateSale.objects.all()
    serializer_class = RealEstateSaleSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['plot__project', 'customer', 'dealer']
    search_fields = ['plot__plot_number', 'customer__name']
    ordering_fields = ['sale_date', 'total_price']

    @action(detail=True, methods=['post'])
    def pay_down_payment(self, request, pk=None):
        sale = self.get_object()
        amount = request.data.get('amount')
        payment_date = request.data.get('payment_date', timezone.now().date())
        receipt_number = request.data.get('receipt_number')
        remarks = request.data.get('remarks')

        if not amount:
            return Response({'error': 'Amount is required'}, status=status.HTTP_400_BAD_REQUEST)

        # Create history entry which will trigger income and update received_down_payment
        DownPaymentPayment.objects.create(
            sale=sale,
            amount=amount,
            payment_date=payment_date,
            receipt_number=receipt_number,
            remarks=remarks
        )

        # Refresh sale from DB
        sale.refresh_from_db()
        return Response(RealEstateSaleSerializer(sale).data)

class InstallmentViewSet(viewsets.ModelViewSet):
    pagination_class = None
    permission_classes = [IsSalesAgent]
    queryset = Installment.objects.all()
    serializer_class = InstallmentSerializer
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['sale', 'status']
    ordering_fields = ['due_date']

class RealEstateIncomeViewSet(viewsets.ModelViewSet):
    pagination_class = None
    permission_classes = [IsAccountant]
    queryset = RealEstateIncome.objects.all()
    serializer_class = RealEstateIncomeSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['project', 'income_type', 'date']
    search_fields = ['description']
    ordering_fields = ['date', 'amount']

class RealEstateExpenseViewSet(viewsets.ModelViewSet):
    pagination_class = None
    permission_classes = [IsAccountant]
    queryset = RealEstateExpense.objects.all()
    serializer_class = RealEstateExpenseSerializer
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['project', 'category', 'date']
    search_fields = ['description']
    ordering_fields = ['date', 'amount']

from django.db.models.functions import TruncMonth
from django.db.models import Sum, Count, F

class FinancialReportViewSet(viewsets.ViewSet):
    permission_classes = [IsAccountant]
    """Module F: Reporting logic"""
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        period = request.query_params.get('period', 'all_time')
        project_id = request.query_params.get('project_id')
        
        today = timezone.now().date()
        if period == 'daily':
            start_date = today
        elif period == 'weekly':
            start_date = today - timedelta(days=7)
        elif period == 'monthly':
            start_date = today.replace(day=1)
        elif period == 'yearly':
            start_date = today.replace(month=1, day=1)
        elif period == 'all_time':
            start_date = None
        else:
            start_date = today

        income_qs = RealEstateIncome.objects.all()
        expense_qs = RealEstateExpense.objects.all()
        
        if start_date:
            income_qs = income_qs.filter(date__gte=start_date)
            expense_qs = expense_qs.filter(date__gte=start_date)
        
        if project_id and project_id != 'null' and project_id != '':
            income_qs = income_qs.filter(project_id=project_id)
            expense_qs = expense_qs.filter(project_id=project_id)

        total_income = income_qs.aggregate(total=Sum('amount'))['total'] or 0
        total_expense = expense_qs.aggregate(total=Sum('amount'))['total'] or 0
        
        income_breakdown = list(income_qs.values('income_type').annotate(total=Sum('amount')))
        expense_breakdown = list(expense_qs.values('category').annotate(total=Sum('amount')))

        return Response({
            'period': period,
            'start_date': start_date,
            'total_income': total_income,
            'total_expense': total_expense,
            'net_profit': total_income - total_expense,
            'income_breakdown': income_breakdown,
            'expense_breakdown': expense_breakdown
        })

    @action(detail=False, methods=['get'])
    def export_pdf(self, request):
        """Export Real Estate reports as PDF"""
        from .reports import (
            generate_commission_report_pdf, generate_sales_report_pdf,
            generate_dealer_commission_report_pdf, generate_client_payment_report_pdf,
            generate_profit_loss_report_pdf, generate_cash_flow_report_pdf,
            generate_landowner_payout_report_pdf, generate_customer_ledger_pdf,
            generate_payment_plan_pdf
        )
        from django.http import HttpResponse
        
        report_type = request.query_params.get('type', 'commission').lower()
        project_id = request.query_params.get('project_id')
        customer_id = request.query_params.get('customer_id')
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        
        # Clean up parameters
        if not project_id or project_id == 'null': project_id = None
        if not customer_id or customer_id == 'null': customer_id = None
        if not start_date or start_date == 'null': start_date = None
        if not end_date or end_date == 'null': end_date = None
        
        sales = RealEstateSale.objects.all().order_by('-sale_date')
        project = None
        if project_id:
            project = Project.objects.filter(id=project_id).first()
            sales = sales.filter(plot__project=project)
        if customer_id:
            sales = sales.filter(customer_id=customer_id)
        if start_date:
            sales = sales.filter(sale_date__gte=start_date)
        if end_date:
            sales = sales.filter(sale_date__lte=end_date)
            
        if report_type == 'commission':
            buffer = generate_commission_report_pdf(sales, project, start_date, end_date)
            name_part = project.name.lower().replace(' ', '_') if project else 'commission'
            filename = f"{name_part}_report_{timezone.now().strftime('%Y%m%d')}.pdf"
        elif report_type == 'payment_plan':
            # NEW: Support PDF for payment plan
            sale_id = request.query_params.get('sale_id')
            if not sale_id and customer_id:
                sale = RealEstateSale.objects.filter(customer_id=customer_id).order_by('-sale_date').first()
                sale_id = sale.id if sale else None
            
            if sale_id:
                sale = RealEstateSale.objects.get(id=sale_id)
                installments = sale.installments.all().order_by('due_date')
                buffer = generate_payment_plan_pdf(sale, installments)
                filename = f"payment_plan_{sale.customer.name.replace(' ', '_')}.pdf"
            else:
                return HttpResponse("sale_id or customer_id is required for payment plan", status=400)
        elif report_type == 'landowner_payout':
            buffer = generate_landowner_payout_report_pdf(sales, project, start_date, end_date)
            filename = f"landowner_payout_report_{timezone.now().strftime('%Y%m%d')}.pdf"
        elif report_type == 'dealer_commission':
            dealer_id = request.query_params.get('dealer_id')
            dealer = Dealer.objects.filter(id=dealer_id).first() if dealer_id else None
            if dealer:
                sales = sales.filter(dealer=dealer)
            buffer = generate_dealer_commission_report_pdf(sales, dealer, start_date, end_date)
            filename = f"dealer_commission_report_{timezone.now().strftime('%Y%m%d')}.pdf"
        elif report_type == 'client_payment':
            if customer_id:
                # Use detailed ledger logic for a single customer
                from customers.ledger_utils import get_ledger_data
                ledger_entries, summary = get_ledger_data(customer_id, start_date, end_date)
                if ledger_entries:
                    buffer = generate_customer_ledger_pdf(ledger_entries, summary, start_date, end_date)
                    filename = f"ledger_{summary['customer_name'].replace(' ', '_')}.pdf"
                else:
                    # Fallback to summary if no ledger data
                    buffer = generate_client_payment_report_pdf(sales, start_date, end_date)
                    filename = f"client_payment_report_{timezone.now().strftime('%Y%m%d')}.pdf"
            else:
                buffer = generate_client_payment_report_pdf(sales, start_date, end_date)
                filename = f"client_payment_report_{timezone.now().strftime('%Y%m%d')}.pdf"
        elif report_type == 'profit_loss':
            incomes = RealEstateIncome.objects.all()
            expenses = RealEstateExpense.objects.all()
            if project_id:
                incomes = incomes.filter(project_id=project_id)
                expenses = expenses.filter(project_id=project_id)
            if start_date:
                incomes = incomes.filter(date__gte=start_date)
                expenses = expenses.filter(date__gte=start_date)
            if end_date:
                incomes = incomes.filter(date__lte=end_date)
                expenses = expenses.filter(date__lte=end_date)
            buffer = generate_profit_loss_report_pdf(incomes, expenses, start_date, end_date)
            filename = f"profit_loss_report_{timezone.now().strftime('%Y%m%d')}.pdf"
        elif report_type == 'cash_flow':
            incomes = RealEstateIncome.objects.all()
            expenses = RealEstateExpense.objects.all()
            if project_id:
                incomes = incomes.filter(project_id=project_id)
                expenses = expenses.filter(project_id=project_id)
            if start_date:
                incomes = incomes.filter(date__gte=start_date)
                expenses = expenses.filter(date__gte=start_date)
            if end_date:
                incomes = incomes.filter(date__lte=end_date)
                expenses = expenses.filter(date__lte=end_date)
                
            transactions = []
            for i in incomes:
                transactions.append({'date': i.date, 'type': 'Income', 'category': i.income_type, 'description': i.description or '', 'amount': i.amount})
            for e in expenses:
                transactions.append({'date': e.date, 'type': 'Expense', 'category': e.category, 'description': e.description or '', 'amount': e.amount})
            transactions.sort(key=lambda x: x['date'] if x['date'] else timezone.now().date())
            
            buffer = generate_cash_flow_report_pdf(transactions, start_date, end_date)
            filename = f"cash_flow_report_{timezone.now().strftime('%Y%m%d')}.pdf"
        elif report_type == 'plots':
            from .serializers import PlotSerializer
            plots_qs = Plot.objects.all().order_by('plot_number')
            if project_id:
                plots_qs = plots_qs.filter(project_id=project_id)
            # For PDF, we'd need a separate generator, for now fallback to sales
            buffer = generate_sales_report_pdf(sales, start_date, end_date)
            filename = f"plots_list_{timezone.now().strftime('%Y%m%d')}.pdf"
        else: # sales
            buffer = generate_sales_report_pdf(sales, start_date, end_date)
            filename = f"sales_report_{timezone.now().strftime('%Y%m%d')}.pdf"
            
        response = HttpResponse(buffer, content_type='application/pdf')
        response['Content-Disposition'] = f'attachment; filename="{filename}"'
        return response

    @action(detail=False, methods=['get'])
    def export_excel(self, request):
        """Export Real Estate reports as Excel"""
        try:
            import pandas as pd
            from django.http import HttpResponse
            from io import BytesIO
            from .reports import (
                generate_commission_report_excel, generate_payment_plan_excel,
                generate_executive_statement_excel, generate_cash_flow_report_excel,
                generate_profit_loss_report_excel, generate_sales_report_excel,
                generate_dealer_commission_report_excel, generate_client_payment_report_excel,
                generate_plots_report_excel, generate_landowner_payout_report_excel
            )
            
            report_type = request.query_params.get('type', 'commission').lower()
            project_id = request.query_params.get('project_id')
            customer_id = request.query_params.get('customer_id')
            sale_id = request.query_params.get('sale_id')
            start_date = request.query_params.get('start_date')
            end_date = request.query_params.get('end_date')

            # Clean up parameters (especially 'null' strings from frontend)
            if not project_id or project_id == 'null': project_id = None
            if not customer_id or customer_id == 'null': customer_id = None
            if not sale_id or sale_id == 'null': sale_id = None
            if not start_date or start_date == 'null': start_date = None
            if not end_date or end_date == 'null': end_date = None

            # Fetch Base Data for sales-based reports
            sales = RealEstateSale.objects.all().select_related('plot', 'customer', 'plot__project', 'dealer')
            if project_id:
                sales = sales.filter(plot__project_id=project_id)
            if start_date:
                sales = sales.filter(sale_date__gte=start_date)
            if end_date:
                sales = sales.filter(sale_date__lte=end_date)

            output = None
            filename = f"{report_type}_report_{timezone.now().strftime('%Y%m%d')}.xlsx"

            if report_type == 'commission':
                output = generate_commission_report_excel(sales, start_date=start_date, end_date=end_date)
            
            elif report_type in ['payment_plan', 'executive_statement']:
                if not sale_id:
                    if customer_id:
                        sale = RealEstateSale.objects.filter(customer_id=customer_id).order_by('-sale_date').first()
                        if not sale:
                            return HttpResponse("No sales found for this customer", status=404)
                        sale_id = sale.id
                    else:
                        return HttpResponse("sale_id or customer_id is required for this report", status=400)
                try:
                    sale = RealEstateSale.objects.get(id=sale_id)
                    installments = sale.installments.all().order_by('due_date')
                    if report_type == 'executive_statement':
                        output = generate_executive_statement_excel(sale, installments)
                    else:
                        output = generate_payment_plan_excel(sale, installments)
                except RealEstateSale.DoesNotExist:
                    return HttpResponse("Sale not found", status=404)
            
            elif report_type == 'plots':
                plots_qs = Plot.objects.all().select_related('project', 'customer', 'dealer').order_by('plot_number')
                if project_id: plots_qs = plots_qs.filter(project_id=project_id)
                output = generate_plots_report_excel(plots_qs)
            
            elif report_type == 'sales':
                output = generate_sales_report_excel(sales, start_date, end_date)
            
            elif report_type == 'dealer_commission':
                dealer_id = request.query_params.get('dealer_id')
                if dealer_id and dealer_id != 'null':
                    sales = sales.filter(dealer_id=dealer_id)
                    dealer_obj = Dealer.objects.filter(id=dealer_id).first()
                else:
                    dealer_obj = None
                output = generate_dealer_commission_report_excel(sales, dealer=dealer_obj)
            
            elif report_type == 'client_payment':
                if customer_id:
                    from customers.ledger_utils import get_ledger_data
                    ledger_entries, summary = get_ledger_data(customer_id, start_date, end_date)
                    if ledger_entries:
                        output = generate_client_payment_report_excel(ledger_entries=ledger_entries, summary=summary)
                    else:
                        if customer_id: sales = sales.filter(customer_id=customer_id)
                        output = generate_client_payment_report_excel(sales=sales)
                else:
                    output = generate_client_payment_report_excel(sales=sales)
            
            elif report_type == 'landowner_payout':
                output = generate_landowner_payout_report_excel(sales, start_date=start_date, end_date=end_date)

            elif report_type == 'cash_flow':
                incomes = RealEstateIncome.objects.all()
                expenses = RealEstateExpense.objects.all()
                if project_id:
                    incomes = incomes.filter(project_id=project_id)
                    expenses = expenses.filter(project_id=project_id)
                if start_date:
                    incomes = incomes.filter(date__gte=start_date)
                    expenses = expenses.filter(date__gte=start_date)
                if end_date:
                    incomes = incomes.filter(date__lte=end_date)
                    expenses = expenses.filter(date__lte=end_date)
                
                transactions = []
                for i in incomes:
                    d = i.date.date() if hasattr(i.date, 'date') else i.date
                    transactions.append({'date': d, 'type': 'Income', 'category': i.get_income_type_display(), 'description': i.description or '', 'amount': i.amount})
                for e in expenses:
                    d = e.date.date() if hasattr(e.date, 'date') else e.date
                    transactions.append({'date': d, 'type': 'Expense', 'category': e.get_category_display(), 'description': e.description or '', 'amount': e.amount})
                
                # Sort by date, ensuring we compare date objects
                today = timezone.now().date()
                transactions.sort(key=lambda x: x['date'] if x['date'] else today)
                
                output = generate_cash_flow_report_excel(transactions, start_date, end_date)
                
            elif report_type == 'profit_loss':
                incomes = RealEstateIncome.objects.all()
                expenses = RealEstateExpense.objects.all()
                if project_id:
                    incomes = incomes.filter(project_id=project_id)
                    expenses = expenses.filter(project_id=project_id)
                if start_date:
                    incomes = incomes.filter(date__gte=start_date)
                    expenses = expenses.filter(date__gte=start_date)
                if end_date:
                    incomes = incomes.filter(date__lte=end_date)
                    expenses = expenses.filter(date__lte=end_date)
                    
                output = generate_profit_loss_report_excel(incomes, expenses, start_date, end_date)

            if output:
                response = HttpResponse(output, content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
                response['Content-Disposition'] = f'attachment; filename="{filename}"'
                return response
            else:
                return HttpResponse(f"No output generated for report type '{report_type}'. It may be unsupported or returned no data.", status=400)

        except Exception as e:
            import traceback
            error_trace = traceback.format_exc()
            print(error_trace)
            return HttpResponse(f"Excel Export Error: {str(e)}\n\n{error_trace}", status=500)


    @action(detail=False, methods=['get'])
    def project_profit(self, request):
        """Project-wise profit report"""
        projects = Project.objects.all()
        report = []
        
        for project in projects:
            income = RealEstateIncome.objects.filter(project=project).aggregate(total=Sum('amount'))['total'] or 0
            expense = RealEstateExpense.objects.filter(project=project).aggregate(total=Sum('amount'))['total'] or 0
            
            report.append({
                'project_id': project.id,
                'project_name': project.name,
                'total_income': income,
                'total_expense': expense,
                'profit': income - expense
            })
            
        return Response(report)

    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """Module G: Real Estate Dashboard Stats"""
        today = timezone.now().date()
        
        from django.db.models import Sum, Count, Q, F, Value
        from django.db.models.functions import Coalesce, TruncMonth
        from django.db.models import DecimalField, FloatField
        
        # 1. Total Sales (Project-wise)
        project_sales = []
        sales_stats = RealEstateSale.objects.values(
            'plot__project__id', 
            'plot__project__name'
        ).annotate(
            total_sales=Coalesce(Sum('total_price'), Value(0), output_field=FloatField()),
            sales_count=Count('id')
        )
        
        for stat in sales_stats:
            if stat['plot__project__id']:
                project_sales.append({
                    'id': str(stat['plot__project__id']),
                    'name': stat['plot__project__name'],
                    'total_sales': stat['total_sales'],
                    'sales_count': stat['sales_count']
                })
        
        # Ensure even projects with 0 sales are listed if they exist
        existing_ids = [s['id'] for s in project_sales]
        for p in Project.objects.exclude(id__in=existing_ids):
            project_sales.append({
                'id': str(p.id),
                'name': p.name,
                'total_sales': 0.0,
                'sales_count': 0
            })

        # 2. Commissions
        total_comm_received = RealEstateIncome.objects.filter(
            income_type='COMMISSION_RECEIVED'
        ).aggregate(total=Coalesce(Sum('amount'), Value(0), output_field=DecimalField()))['total']
        
        total_comm_paid = RealEstateSale.objects.aggregate(
            total=Coalesce(Sum('dealer_paid_amount'), Value(0), output_field=DecimalField())
        )['total']
        
        pending_comm = RealEstateSale.objects.exclude(
            commission_status='PAID'
        ).aggregate(
            total=Coalesce(Sum(F('dealer_commission') - F('dealer_paid_amount')), Value(0), output_field=DecimalField())
        )['total']

        # 3. Net Profit (Overall)
        grand_total_income = RealEstateIncome.objects.aggregate(total=Coalesce(Sum('amount'), Value(0), output_field=DecimalField()))['total']
        grand_total_expense = RealEstateExpense.objects.aggregate(total=Coalesce(Sum('amount'), Value(0), output_field=DecimalField()))['total']
        net_profit = grand_total_income - grand_total_expense
        
        # 3.1 Total Receivables (Remaining Balances from Sales)
        total_receivables = RealEstateSale.objects.aggregate(total=Coalesce(Sum('remaining_balance'), Value(0), output_field=DecimalField()))['total']

        # 4. Plots
        available_plots = Plot.objects.filter(status='AVAILABLE').count()

        # 5. Overall & Today's Stats
        total_sales_all_time = RealEstateSale.objects.aggregate(total=Coalesce(Sum('total_price'), Value(0), output_field=DecimalField()))['total']
        today_sales = RealEstateSale.objects.filter(sale_date=today).aggregate(total=Coalesce(Sum('total_price'), Value(0), output_field=DecimalField()))['total']
        today_income = RealEstateIncome.objects.filter(date=today).aggregate(total=Coalesce(Sum('amount'), Value(0), output_field=DecimalField()))['total']
        today_expense = RealEstateExpense.objects.filter(date=today).aggregate(total=Coalesce(Sum('amount'), Value(0), output_field=DecimalField()))['total']

        # 6. Charts Data
        # Monthly Sales
        monthly_sales = RealEstateSale.objects.annotate(
            month=TruncMonth('sale_date')
        ).values('month').annotate(
            total=Coalesce(Sum('total_price'), Value(0), output_field=FloatField())
        ).order_by('month')

        # Monthly Income vs Expense
        monthly_income = RealEstateIncome.objects.annotate(
            month=TruncMonth('date')
        ).values('month').annotate(
            total=Coalesce(Sum('amount'), Value(0), output_field=FloatField())
        ).order_by('month')

        monthly_expense = RealEstateExpense.objects.annotate(
            month=TruncMonth('date')
        ).values('month').annotate(
            total=Coalesce(Sum('amount'), Value(0), output_field=FloatField())
        ).order_by('month')

        # Dealer Performance
        dealer_performance = Dealer.objects.annotate(
            s_val=Coalesce(Sum('dealer_sales__total_price'), Value(0), output_field=FloatField()),
            c_val=Coalesce(Sum('dealer_sales__dealer_commission'), Value(0), output_field=FloatField())
        ).values('id', 'name', 's_val', 'c_val').order_by('-s_val')[:5]
        
        # Clean up dealer performance keys for frontend
        performance_data = []
        for dp in dealer_performance:
            performance_data.append({
                'id': str(dp['id']),
                'name': dp['name'],
                'sales_val': dp['s_val'],
                'comm_val': dp['c_val']
            })

        return Response({
            'project_sales': project_sales,
            'total_sales_all_time': float(total_sales_all_time),
            'total_commission_received': float(total_comm_received),
            'total_commission_paid': float(total_comm_paid),
            'net_profit': float(net_profit),
            'total_receivables': float(total_receivables),
            'pending_commissions': float(pending_comm),
            'available_plots': available_plots,
            'today': {
                'sales': float(today_sales),
                'income': float(today_income),
                'expense': float(today_expense)
            },
            'charts': {
                'monthly_sales': list(monthly_sales),
                'monthly_income': list(monthly_income),
                'monthly_expense': list(monthly_expense),
                'dealer_performance': performance_data
            }
        })
