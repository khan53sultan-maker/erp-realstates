import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone
from decimal import Decimal

class Project(models.Model):
    """Module A: Project Management"""
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('CLOSED', 'Closed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255, help_text="e.g., Umar Homes")
    location = models.CharField(max_length=255)
    landowner_name = models.CharField(max_length=255)
    total_plots = models.PositiveIntegerField()
    plot_sizes = models.CharField(max_length=255, help_text="e.g., 5 Marla, 10 Marla, 1 Kanal")
    
    landowner_commission_percentage = models.DecimalField(
        max_digits=5, decimal_places=2, default=Decimal('12.00'),
        help_text="Commission % from landowner"
    )
    down_payment_percentage = models.DecimalField(
        max_digits=5, decimal_places=2, default=Decimal('30.00'),
        help_text="Down payment % requirement"
    )
    payment_plan_details = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class Dealer(models.Model):
    """Module E: Dealer / Team Management profile"""
    TYPE_CHOICES = [
        ('TEAM_MEMBER', 'Team Member'),
        ('DEALER', 'Dealer'),
        ('SUB_AGENT', 'Sub-agent'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    phone = models.CharField(max_length=20, unique=True)
    dealer_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='DEALER')
    commission_percentage = models.DecimalField(
        max_digits=5, decimal_places=2, default=Decimal('5.00')
    )
    
    # Financial tracking (Can be updated via signals on sales)
    total_sales_count = models.PositiveIntegerField(default=0)
    total_commission_earned = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    paid_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    
    @property
    def pending_amount(self):
        return self.total_commission_earned - self.paid_amount

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

class Plot(models.Model):
    """Module B: Plot Management"""
    STATUS_CHOICES = [
        ('AVAILABLE', 'Available'),
        ('RESERVED', 'Reserved'),
        ('SOLD', 'Sold'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='plots')
    plot_number = models.CharField(max_length=50)
    plot_size = models.CharField(max_length=100) # e.g., "5 Marla"
    total_price = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='AVAILABLE')
    
    # These are populated when SOLD
    customer = models.ForeignKey(
        'customers.Customer', 
        on_delete=models.SET_NULL, 
        null=True, blank=True, 
        related_name='purchased_plots'
    )
    sale_date = models.DateField(null=True, blank=True)
    dealer = models.ForeignKey(
        Dealer, 
        on_delete=models.SET_NULL, 
        null=True, blank=True, 
        related_name='dealer_plots'
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('project', 'plot_number')
        ordering = ['plot_number']

    def __str__(self):
        return f"{self.project.name} - Plot {self.plot_number}"

class RealEstateSale(models.Model):
    """Module C: Sales Management / Booking"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    plot = models.OneToOneField(Plot, on_delete=models.CASCADE, related_name='sale_record')
    customer = models.ForeignKey('customers.Customer', on_delete=models.PROTECT, related_name='real_estate_purchases')
    dealer = models.ForeignKey(Dealer, on_delete=models.SET_NULL, null=True, blank=True, related_name='dealer_sales')
    
    total_price = models.DecimalField(max_digits=12, decimal_places=2)
    registration_number = models.CharField(max_length=50, blank=True, null=True, help_text="e.g., 1,001")
    receipt_number = models.CharField(max_length=100, blank=True, null=True, help_text="Manual receipt number for booking/down-payment")
    down_payment = models.DecimalField(max_digits=12, decimal_places=2, help_text="Required Down Payment (e.g. 30%)")
    received_down_payment = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'), help_text="Actual Down Payment Received at booking")
    remaining_balance = models.DecimalField(max_digits=12, decimal_places=2)
    
    # Milestone Breakdown (for Pakistani Real Estate Reports)
    block_name = models.CharField(max_length=100, blank=True, null=True, help_text="e.g., Sector A")
    cutting_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal('0.00'), help_text="e.g., 10%")
    is_commercial = models.BooleanField(default=False)
    
    allocation_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    confirmation_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    possession_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    processing_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    last_payment_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    
    installments_count = models.PositiveIntegerField(default=0)
    installment_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    
    sale_date = models.DateField(default=lambda: timezone.now().date())

    # Commission Configuration
    DEALER_COMMISSION_TYPE_CHOICES = [
        ('PLOT_PRICE', '% of Total Plot Price'),
        ('COMPANY_COMMISSION', '% of Company (Landowner) Commission'),
    ]
    dealer_commission_type = models.CharField(
        max_length=20,
        choices=DEALER_COMMISSION_TYPE_CHOICES,
        default='PLOT_PRICE',
        help_text="Basis for dealer commission calculation"
    )

    # Automated Commissions (Requirement D)
    landowner_commission = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'), help_text="Total Commission from Landowner")
    landowner_commission_received = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'), help_text="Commission actually received from Landowner")
    dealer_commission = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'), help_text="Total Commission for Dealer")
    
    # Dealer Payment Tracking
    COMMISSION_STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('PARTIAL', 'Partially Paid'),
        ('PAID', 'Paid'),
    ]
    commission_status = models.CharField(
        max_length=20,
        choices=COMMISSION_STATUS_CHOICES,
        default='PENDING'
    )
    dealer_paid_amount = models.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        default=Decimal('0.00'),
        help_text="Amount already paid to the dealer for this sale"
    )

    landowner_paid_amount = models.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        default=Decimal('0.00'),
        help_text="Amount already paid to the landowner for this sale"
    )

    landowner_payment_remarks = models.TextField(blank=True, null=True, help_text="Remarks for the last payment made to landowner")
    semi_annual_balloon_payment = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'), help_text="Amount to be paid every 6 months as a lump sum")

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    @property
    def landowner_total_share(self):
        """Total price minus company commission"""
        return self.total_price - self.landowner_commission

    @property
    def landowner_share_received(self):
        """Amount that belongs to landowner out of total customer payments"""
        if self.total_price <= 0:
            return Decimal('0.00')
        share = (self.total_received / self.total_price) * self.landowner_total_share
        return share.quantize(Decimal('1.'))

    @property
    def landowner_share_remaining(self):
        """Total Share - Paid Amount"""
        return self.landowner_total_share - self.landowner_paid_amount

    @property
    def total_received(self):
        """Actual Received Down Payment + All Paid Amounts from Installments"""
        p_amount = self.installments.aggregate(total=models.Sum('paid_amount'))['total'] or Decimal('0.00')
        return self.received_down_payment + p_amount

    @property
    def current_balance(self):
        """Total Price - All Received Payments"""
        return self.total_price - self.total_received

    @property
    def current_dealer_commission(self):
        if self.down_payment <= 0:
            return Decimal('0.00')
        earned = (self.received_down_payment / self.down_payment) * self.dealer_commission
        return earned.quantize(Decimal('1.'))

    @property
    def dealer_commission_remaining(self):
        return self.dealer_commission - self.dealer_paid_amount

    @property
    def landowner_commission_remaining(self):
        return self.landowner_commission - self.landowner_commission_received

    @property
    def net_company_income(self):
        return self.landowner_commission - self.dealer_commission

    def clean(self):
        from django.core.exceptions import ValidationError
        # Check if plot is already sold (only for new sales)
        if self._state.adding and self.plot.status == 'SOLD':
            raise ValidationError(f"Plot {self.plot.plot_number} is already sold.")
        super().clean()

    def save(self, *args, **kwargs):
        is_new = self._state.adding
        
        if is_new or self.landowner_commission == 0:
            landowner_percentage = self.plot.project.landowner_commission_percentage / Decimal('100.0')
            self.landowner_commission = self.total_price * landowner_percentage
            
        if self.dealer and (is_new or self.dealer_commission == 0):
            dealer_percentage = self.dealer.commission_percentage / Decimal('100.0')
            if self.dealer_commission_type == 'PLOT_PRICE':
                self.dealer_commission = self.total_price * dealer_percentage
            else:
                self.dealer_commission = self.landowner_commission * dealer_percentage
        
        if self.installments_count > 0 and (self.installment_amount == 0 or self.installment_amount is None):
            # 1. Total months and Balloon count
            total_count = self.installments_count
            balloon_count = total_count // 6
            non_balloon_count = total_count - balloon_count
            
            # 2. Total amount to be covered by balloons
            balloon_val = self.semi_annual_balloon_payment or Decimal('0.00')
            total_balloons_amount = Decimal(str(balloon_count)) * balloon_val
            
            # 3. Monthly amount for the OTHER months
            if non_balloon_count > 0:
                remaining_for_monthly = self.remaining_balance - total_balloons_amount
                self.installment_amount = remaining_for_monthly / Decimal(str(non_balloon_count))
            else:
                # If all months are balloon months (e.g. duration <= 6 and it's a 6th month only)
                self.installment_amount = Decimal('0.00')
            
        old_instance = None
        if not is_new:
            try:
                old_instance = RealEstateSale.objects.get(pk=self.pk)
            except RealEstateSale.DoesNotExist:
                pass

        if self.dealer_paid_amount >= self.dealer_commission and self.dealer_commission > 0:
            self.commission_status = 'PAID'
        elif self.dealer_paid_amount > 0:
            self.commission_status = 'PARTIAL'
        else:
            self.commission_status = 'PENDING'

        super().save(*args, **kwargs)

        # Update installments logic
        from .models import Installment
        from datetime import timedelta
        
        if not is_new:
            # Handle editing existing sale: Update pending installments
            all_insts = self.installments.all().order_by('due_date')
            pending_insts = [inst for inst in all_insts if inst.status == 'PENDING']
            
            if pending_insts:
                # 1. Calculate how many balloons are left among pending installments
                total_pending = len(pending_insts)
                balloon_count_pending = 0
                non_balloon_pending = 0
                
                for i, inst in enumerate(all_insts, start=1):
                    if inst.status == 'PENDING':
                        if i % 6 == 0:
                            balloon_count_pending += 1
                        else:
                            non_balloon_pending += 1
                
                # 2. Recalculate base monthly amount for remaining balance
                curr_bal = self.current_balance 
                balloon_val = (self.semi_annual_balloon_payment or Decimal('0.00'))
                total_balloons_val = Decimal(str(balloon_count_pending)) * balloon_val
                
                # Base installment for the rest of the duration (non-balloon months)
                if non_balloon_pending > 0:
                    new_base_monthly = (curr_bal - total_balloons_val) / Decimal(str(non_balloon_pending))
                else:
                    new_base_monthly = Decimal('0.00')
                
                # 3. Update pending installments
                for i, inst in enumerate(all_insts, start=1):
                    if inst.status == 'PENDING':
                        if i % 6 == 0:
                            amount_to_pay = balloon_val
                            remarks = "Semi-Annual Balloon Payment"
                        else:
                            amount_to_pay = new_base_monthly
                            # Clean up old balloon remarks if any
                            remarks = inst.payment_remarks or ""
                            if "Includes Semi-Annual" in remarks or "Semi-Annual Balloon" in remarks:
                                remarks = ""

                        # Update installment
                        Installment.objects.filter(pk=inst.pk).update(
                            amount=amount_to_pay,
                            payment_remarks=remarks if remarks else None
                        )

        from .models import RealEstateIncome, RealEstateExpense
        
        if is_new:
            if self.landowner_commission_received > 0:
                desc = f"Automated: Initial commission received for {self.plot.plot_number}"
                if self.landowner_payment_remarks:
                    desc += f" ({self.landowner_payment_remarks})"
                # Pass sale=self to ensure it's linked
                RealEstateIncome.objects.create(
                    sale=self,
                    project=self.plot.project,
                    income_type='COMMISSION_RECEIVED',
                    amount=self.landowner_commission_received,
                    date=timezone.now().date(),
                    description=desc
                )
            
            if self.dealer_paid_amount > 0:
                # Pass sale=self to ensure it's linked
                RealEstateExpense.objects.create(
                    sale=self,
                    project=self.plot.project,
                    category='COMMISSION_PAID',
                    amount=self.dealer_paid_amount,
                    date=timezone.now().date(),
                    description=f"Automated: Initial commission paid to {self.dealer.name if self.dealer else 'Dealer'} for {self.plot.plot_number}"
                )
        elif old_instance:
            income_diff = self.landowner_commission_received - old_instance.landowner_commission_received
            if income_diff > 0:
                # 1. Record in Commission History
                LandownerCommissionPayment.objects.create(
                    sale=self,
                    amount=income_diff,
                    date=timezone.now().date(),
                    remarks=self.landowner_payment_remarks or "Commission Received"
                )

                # 2. Record in Global Income
                desc = f"Automated: Commission received for {self.plot.plot_number} from Landowner"
                if self.landowner_payment_remarks:
                    desc += f" ({self.landowner_payment_remarks})"
                RealEstateIncome.objects.create(
                    sale=self, # Linked
                    project=self.plot.project,
                    income_type='COMMISSION_RECEIVED',
                    amount=income_diff,
                    date=timezone.now().date(),
                    description=desc
                )

            expense_diff = self.dealer_paid_amount - old_instance.dealer_paid_amount
            if expense_diff > 0:
                # 1. Record in Dealer History
                DealerPayment.objects.create(
                    sale=self,
                    amount=expense_diff,
                    date=timezone.now().date(),
                    remarks="Commission Payment"
                )
                
                # 2. Record in Global Expenses
                RealEstateExpense.objects.create(
                    project=self.plot.project,
                    category='COMMISSION_PAID',
                    amount=expense_diff,
                    date=timezone.now().date(),
                    description=f"Automated: Commission paid to {self.dealer.name if self.dealer else 'Dealer'} for {self.plot.plot_number}"
                )
            
            # Legacy/Data migration: If this is the FIRST time we see history but paid_amount is already set
            # and no history entries exist, create an initial bulk entry.
            if self.dealer_paid_amount > 0 and not self.dealer_payments.exists():
                 DealerPayment.objects.create(
                    sale=self,
                    amount=self.dealer_paid_amount,
                    date=self.sale_date or timezone.now().date(),
                    remarks="Initial/Bulk Payment Record"
                )

            landowner_share_diff = self.landowner_paid_amount - old_instance.landowner_paid_amount
            if landowner_share_diff > 0:
                # 1. Record in Landowner History
                LandownerPayment.objects.create(
                    sale=self,
                    amount=landowner_share_diff,
                    date=timezone.now().date(),
                    remarks=self.landowner_payment_remarks or "Plot Share Payout"
                )
                
                # 2. Record in Global Expenses
                desc = f"Automated: Share payout to Landowner for {self.plot.plot_number}"
                if self.landowner_payment_remarks:
                    desc += f" ({self.landowner_payment_remarks})"
                RealEstateExpense.objects.create(
                    project=self.plot.project,
                    category='LANDOWNER_PAYOUT',
                    amount=landowner_share_diff,
                    date=timezone.now().date(),
                    description=desc
                )
            
            if self.landowner_paid_amount > 0 and not self.landowner_payments.exists():
                LandownerPayment.objects.create(
                    sale=self,
                    amount=self.landowner_paid_amount,
                    date=self.sale_date or timezone.now().date(),
                    remarks="Initial/Bulk Payout Record"
                )
            
            # Initial history for commission received
            if self.landowner_commission_received > 0 and not self.landowner_commission_history.exists():
                LandownerCommissionPayment.objects.create(
                    sale=self,
                    amount=self.landowner_commission_received,
                    date=self.sale_date or timezone.now().date(),
                    remarks="Initial/Bulk Commission Record"
                )
        
        self.plot.status = 'SOLD'
        self.plot.customer = self.customer
        self.plot.dealer = self.dealer
        self.plot.sale_date = self.sale_date or timezone.now().date()
        self.plot.save()

        if is_new and self.installments_count > 0:
            from .models import Installment
            from datetime import timedelta
            start_date = self.sale_date or timezone.now().date()
            for i in range(1, self.installments_count + 1):
                due_date = start_date + timedelta(days=30 * i)
                is_balloon = (i % 6 == 0)
                remarks = None
                
                if is_balloon:
                    amount_to_pay = (self.semi_annual_balloon_payment or Decimal('0.00'))
                    remarks = f"Semi-Annual Balloon Payment"
                else:
                    amount_to_pay = Decimal(str(self.installment_amount))
                
                Installment.objects.get_or_create(
                    sale=self,
                    amount=amount_to_pay,
                    due_date=due_date,
                    defaults={
                        'status': 'PENDING',
                        'payment_remarks': remarks
                    }
                )

    def __str__(self):
        return f"Sale - {self.plot.project.name} - {self.plot.plot_number}"

class DealerPayment(models.Model):
    """History of payments made to a dealer for a specific sale"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sale = models.ForeignKey(RealEstateSale, on_delete=models.CASCADE, related_name='dealer_payments')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    date = models.DateField(default=lambda: timezone.now().date())
    remarks = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['date', 'created_at']

    def __str__(self):
        return f"Dealer Check - {self.amount} on {self.date}"

class LandownerPayment(models.Model):
    """History of plot share payments made to a landowner for a specific sale"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sale = models.ForeignKey(RealEstateSale, on_delete=models.CASCADE, related_name='landowner_payments')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    date = models.DateField(default=lambda: timezone.now().date())
    remarks = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['date', 'created_at']

    def __str__(self):
        return f"Landowner Check - {self.amount} on {self.date}"

class LandownerCommissionPayment(models.Model):
    """History of commission received FROM landowner for a specific sale"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sale = models.ForeignKey(RealEstateSale, on_delete=models.CASCADE, related_name='landowner_commission_history')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    date = models.DateField(default=lambda: timezone.now().date())
    remarks = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['date', 'created_at']

    def __str__(self):
        return f"Commission Recv - {self.amount} on {self.date}"

class RealEstateIncome(models.Model):
    """Module F: Income Section"""
    INCOME_TYPE_CHOICES = [
        ('COMMISSION_RECEIVED', 'Commission Received'),
        ('INSTALLMENT_PAYMENT', 'Installment Payment'),
        ('OTHER', 'Other Income'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    project = models.ForeignKey(Project, on_delete=models.SET_NULL, null=True, blank=True, related_name='incomes')
    income_type = models.CharField(max_length=50, choices=INCOME_TYPE_CHOICES)
    amount = models.DecimalField(max_digits=15, decimal_places=2)
    date = models.DateField(default=lambda: timezone.now().date())
    description = models.TextField(blank=True, null=True)
    sale = models.ForeignKey(RealEstateSale, on_delete=models.SET_NULL, null=True, blank=True, related_name='income_entries')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date', '-created_at']

    def __str__(self):
        return f"{self.get_income_type_display()} - {self.amount}"

    def save(self, *args, **kwargs):
        is_new = self._state.adding
        old_amount = 0
        if not is_new:
            try:
                old_instance = RealEstateIncome.objects.get(pk=self.pk)
                old_amount = old_instance.amount
            except RealEstateIncome.DoesNotExist:
                pass

        super().save(*args, **kwargs)

        # Update landowner commission received on sale if linked
        if self.sale and self.income_type == 'COMMISSION_RECEIVED':
            diff = self.amount - Decimal(str(old_amount))
            if diff != 0:
                self.sale.landowner_commission_received = (self.sale.landowner_commission_received or 0) + diff
                # Update only relevant field to avoid recursion
                RealEstateSale.objects.filter(pk=self.sale.pk).update(
                    landowner_commission_received=self.sale.landowner_commission_received
                )
                
                # Manually record in Landowner Commission History
                LandownerCommissionPayment.objects.create(
                    sale=self.sale,
                    amount=diff,
                    date=self.date,
                    remarks=f"Income Commission: {self.description or 'Unspecified'}"
                )

class RealEstateExpense(models.Model):
    """Module F: Expense Section"""
    EXPENSE_CATEGORY_CHOICES = [
        ('OFFICE_RENT', 'Office Rent'),
        ('SALARY', 'Salary'),
        ('MARKETING', 'Marketing'),
        ('UTILITY', 'Utility'),
        ('COMMISSION_PAID', 'Commission Paid'),
        ('LANDOWNER_PAYOUT', 'Landowner Payout'),
        ('MISC', 'Misc Expenses'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    project = models.ForeignKey(Project, on_delete=models.SET_NULL, null=True, blank=True, related_name='expenses')
    category = models.CharField(max_length=50, choices=EXPENSE_CATEGORY_CHOICES)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    date = models.DateField(default=lambda: timezone.now().date())
    description = models.TextField(blank=True, null=True)
    sale = models.ForeignKey(RealEstateSale, on_delete=models.SET_NULL, null=True, blank=True, related_name='payout_expenses')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date', '-created_at']

    def __str__(self):
        return f"{self.get_category_display()} - {self.amount}"

    def save(self, *args, **kwargs):
        is_new = self._state.adding
        old_amount = 0
        if not is_new:
            try:
                old_instance = RealEstateExpense.objects.get(pk=self.pk)
                old_amount = old_instance.amount
            except RealEstateExpense.DoesNotExist:
                pass

        super().save(*args, **kwargs)

        # Update landowner payout or dealer commission on sale if linked
        if self.sale and self.category in ['LANDOWNER_PAYOUT', 'COMMISSION_PAID']:
            diff = self.amount - Decimal(str(old_amount))
            if diff != 0:
                if self.category == 'LANDOWNER_PAYOUT':
                    self.sale.landowner_paid_amount = (self.sale.landowner_paid_amount or 0) + diff
                    RealEstateSale.objects.filter(pk=self.sale.pk).update(
                        landowner_paid_amount=self.sale.landowner_paid_amount
                    )
                    LandownerPayment.objects.create(
                        sale=self.sale, amount=diff, date=self.date,
                        remarks=f"Expense Payout: {self.description or 'Unspecified'}"
                    )
                elif self.category == 'COMMISSION_PAID':
                    self.sale.dealer_paid_amount = (self.sale.dealer_paid_amount or 0) + diff
                    RealEstateSale.objects.filter(pk=self.sale.pk).update(
                        dealer_paid_amount=self.sale.dealer_paid_amount
                    )
                    DealerPayment.objects.create(
                        sale=self.sale, amount=diff, date=self.date,
                        remarks=f"Expense Commission: {self.description or 'Unspecified'}"
                    )

class Installment(models.Model):
    """Installment tracking"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sale = models.ForeignKey(RealEstateSale, on_delete=models.CASCADE, related_name='installments')
    amount = models.DecimalField(max_digits=12, decimal_places=2) # Due amount
    paid_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00')) # Actual paid
    due_date = models.DateField()
    paid_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=[
        ('PENDING', 'Pending'), 
        ('PARTIAL', 'Partial'),
        ('PAID', 'Paid')
    ], default='PENDING')
    
    receipt_number = models.CharField(max_length=50, blank=True, null=True, help_text="Temporary field for manual receipt record")
    payment_remarks = models.CharField(max_length=255, blank=True, null=True, help_text="Temporary field for last payment's remarks")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def save(self, *args, **kwargs):
        is_new = self._state.adding
        old_paid_amount = Decimal('0.00')
        
        if not is_new:
            try:
                old_instance = Installment.objects.get(pk=self.pk)
                old_paid_amount = old_instance.paid_amount
            except Installment.DoesNotExist:
                pass
        
        super().save(*args, **kwargs)
        
        # Record income and payment history if paid_amount increased
        diff = Decimal(str(self.paid_amount)) - old_paid_amount
        if diff > 0:
            # 1. Create Detail Payment Record
            from .models import InstallmentPayment
            InstallmentPayment.objects.create(
                installment=self,
                amount=diff,
                payment_date=self.paid_date or timezone.now().date(),
                receipt_number=self.receipt_number,
                remarks=self.payment_remarks
            )

            # 2. Create Global Income Record
            desc = f"Installment payment for {self.sale.plot.plot_number} - {self.sale.customer.name}"
            if self.payment_remarks:
                desc += f" ({self.payment_remarks})"
            
            RealEstateIncome.objects.create(
                project=self.sale.plot.project,
                income_type='INSTALLMENT_PAYMENT',
                amount=diff,
                date=self.paid_date or timezone.now().date(),
                description=desc
            )
            
            # Reset remarks after saving so they don't stick around if updated again without remarks
            Installment.objects.filter(pk=self.pk).update(payment_remarks=None, receipt_number=None)

    def __str__(self):
        return f"Installment for {self.sale} - {self.amount}"

class InstallmentPayment(models.Model):
    """History of partial payments for an installment"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    installment = models.ForeignKey(Installment, on_delete=models.CASCADE, related_name='payment_history')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    payment_date = models.DateField(default=lambda: timezone.now().date())
    receipt_number = models.CharField(max_length=50, blank=True, null=True)
    remarks = models.CharField(max_length=255, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['payment_date', 'created_at']

    def __str__(self):
        return f"Payment of {self.amount} on {self.payment_date} for {self.installment}"
