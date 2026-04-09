from rest_framework import serializers
from django.db.models import Q
from decimal import Decimal
from .models import Payable, PayablePayment


class PayableSerializer(serializers.ModelSerializer):
    """Complete serializer for Payable model"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    vendor_name = serializers.CharField(source='vendor.name', read_only=True)
    vendor_business_name = serializers.CharField(source='vendor.business_name', read_only=True)
    
    # Computed fields
    days_since_borrowed = serializers.IntegerField(read_only=True)
    days_until_due = serializers.IntegerField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    repayment_status = serializers.CharField(read_only=True)
    priority_color = serializers.CharField(read_only=True)
    status_color = serializers.CharField(read_only=True)
    
    # Payment-related fields
    payments_count = serializers.SerializerMethodField()
    latest_payment_date = serializers.SerializerMethodField()
    
    class Meta:
        model = Payable
        fields = (
            'id',
            'creditor_name',
            'creditor_phone',
            'creditor_email',
            'vendor',
            'vendor_name',
            'vendor_business_name',
            'amount_borrowed',
            'amount_paid',
            'balance_remaining',
            'reason_or_item',
            'date_borrowed',
            'expected_repayment_date',
            'is_fully_paid',
            'payment_percentage',
            'priority',
            'status',
            'notes',
            'days_since_borrowed',
            'days_until_due',
            'is_overdue',
            'repayment_status',
            'priority_color',
            'status_color',
            'payments_count',
            'latest_payment_date',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'created_by_id'
        )
        read_only_fields = (
            'id', 'balance_remaining', 'is_fully_paid', 'payment_percentage',
            'days_since_borrowed', 'days_until_due', 'is_overdue', 'repayment_status',
            'priority_color', 'status_color', 'payments_count', 'latest_payment_date',
            'created_at', 'updated_at', 'created_by', 'created_by_id',
            'vendor_name', 'vendor_business_name'
        )
    
    def get_payments_count(self, obj):
        """Get total payments count for payable"""
        return obj.payments.count()
    
    def get_latest_payment_date(self, obj):
        """Get latest payment date for payable"""
        latest_payment = obj.payments.order_by('-payment_date').first()
        return latest_payment.payment_date if latest_payment else None

    def validate_creditor_name(self, value):
        """Clean and validate creditor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Creditor name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Creditor name must be at least 2 characters long.")
        
        return name

    def validate_amount_borrowed(self, value):
        """Validate borrowed amount"""
        if value <= 0:
            raise serializers.ValidationError("Amount borrowed must be greater than zero.")
        return value

    def validate_amount_paid(self, value):
        """Validate paid amount"""
        if value < 0:
            raise serializers.ValidationError("Amount paid cannot be negative.")
        return value

    def validate_reason_or_item(self, value):
        """Clean and validate reason"""
        if not value or not value.strip():
            raise serializers.ValidationError("Reason or item description is required.")
        
        reason = value.strip()
        if len(reason) < 5:
            raise serializers.ValidationError("Reason must be at least 5 characters long.")
        
        return reason

    def validate(self, data):
        """Cross-field validation"""
        amount_borrowed = data.get('amount_borrowed')
        amount_paid = data.get('amount_paid', Decimal('0.00'))
        date_borrowed = data.get('date_borrowed')
        expected_repayment_date = data.get('expected_repayment_date')
        
        # Check if amount paid exceeds amount borrowed
        if amount_borrowed and amount_paid > amount_borrowed:
            raise serializers.ValidationError({
                'amount_paid': 'Amount paid cannot exceed amount borrowed.'
            })
        
        # Check date logic
        if date_borrowed and expected_repayment_date:
            if expected_repayment_date < date_borrowed:
                raise serializers.ValidationError({
                    'expected_repayment_date': 'Repayment date cannot be before borrowed date.'
                })
        
        return data


class PayableCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating payables"""
    
    class Meta:
        model = Payable
        fields = (
            'creditor_name',
            'creditor_phone',
            'creditor_email',
            'vendor',
            'amount_borrowed',
            'amount_paid',
            'reason_or_item',
            'date_borrowed',
            'expected_repayment_date',
            'priority',
            'notes'
        )

    def validate_creditor_name(self, value):
        """Clean and validate creditor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Creditor name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Creditor name must be at least 2 characters long.")
        
        return name

    def validate_amount_borrowed(self, value):
        """Validate borrowed amount"""
        if value <= 0:
            raise serializers.ValidationError("Amount borrowed must be greater than zero.")
        return value

    def validate_reason_or_item(self, value):
        """Clean and validate reason"""
        if not value or not value.strip():
            raise serializers.ValidationError("Reason or item description is required.")
        
        reason = value.strip()
        if len(reason) < 5:
            raise serializers.ValidationError("Reason must be at least 5 characters long.")
        
        return reason

    def validate(self, data):
        """Cross-field validation"""
        amount_borrowed = data.get('amount_borrowed')
        amount_paid = data.get('amount_paid', Decimal('0.00'))
        date_borrowed = data.get('date_borrowed')
        expected_repayment_date = data.get('expected_repayment_date')
        
        # Check that initial amount_paid doesn't exceed amount_borrowed
        if amount_borrowed and amount_paid:
            if amount_paid > amount_borrowed:
                raise serializers.ValidationError({
                    'amount_paid': f'Initial amount paid cannot exceed amount borrowed of {amount_borrowed}'
                })
        
        # Check date logic
        if date_borrowed and expected_repayment_date:
            if expected_repayment_date < date_borrowed:
                raise serializers.ValidationError({
                    'expected_repayment_date': 'Repayment date cannot be before borrowed date.'
                })
        
        return data

    def create(self, validated_data):
        """Create payable with the requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)


class PayableUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating payables"""
    
    class Meta:
        model = Payable
        fields = (
            'creditor_name',
            'creditor_phone',
            'creditor_email',
            'vendor',
            'amount_borrowed',
            'amount_paid',
            'reason_or_item',
            'date_borrowed',
            'expected_repayment_date',
            'priority',
            'notes'
        )

    def validate_creditor_name(self, value):
        """Clean and validate creditor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Creditor name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Creditor name must be at least 2 characters long.")
        
        return name

    def validate_amount_borrowed(self, value):
        """Validate borrowed amount"""
        if value <= 0:
            raise serializers.ValidationError("Amount borrowed must be greater than zero.")
        return value

    def validate_amount_paid(self, value):
        """Validate paid amount"""
        if value < 0:
            raise serializers.ValidationError("Amount paid cannot be negative.")
        return value

    def validate_reason_or_item(self, value):
        """Clean and validate reason"""
        if not value or not value.strip():
            raise serializers.ValidationError("Reason or item description is required.")
        
        reason = value.strip()
        if len(reason) < 5:
            raise serializers.ValidationError("Reason must be at least 5 characters long.")
        
        return reason

    def validate(self, data):
        """Cross-field validation"""
        amount_borrowed = data.get('amount_borrowed')
        amount_paid = data.get('amount_paid')
        date_borrowed = data.get('date_borrowed')
        expected_repayment_date = data.get('expected_repayment_date')
        
        # Check if there are payments and new amount is less than paid amount
        if self.instance and amount_borrowed:
            if amount_borrowed < self.instance.amount_paid:
                raise serializers.ValidationError({
                    'amount_borrowed': f'Cannot reduce borrowed amount below already paid amount of {self.instance.amount_paid}'
                })
        
        # Check that additional amount_paid doesn't exceed remaining balance
        if amount_paid and self.instance:
            current_paid = self.instance.amount_paid
            if current_paid + amount_paid > amount_borrowed:
                raise serializers.ValidationError({
                    'amount_paid': f'Additional payment of {amount_paid} would exceed remaining balance of {amount_borrowed - current_paid}'
                })
        
        # Check date logic
        if date_borrowed and expected_repayment_date:
            if expected_repayment_date < date_borrowed:
                raise serializers.ValidationError({
                    'expected_repayment_date': 'Repayment date cannot be before borrowed date.'
                })
        
        return data
    
    def update(self, instance, validated_data):
        """Handle incremental payment updates"""
        amount_paid = validated_data.get('amount_paid')
        
        if amount_paid is not None and amount_paid > 0:
            # amount_paid now represents the ADDITIONAL amount to pay
            # Add incremental payment
            instance.add_incremental_payment(amount_paid)
            # Remove amount_paid from validated_data to avoid double processing
            validated_data.pop('amount_paid')
        
        return super().update(instance, validated_data)


class PayableListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing payables"""
    
    created_by_email = serializers.CharField(source='created_by.email', read_only=True)
    vendor_name = serializers.CharField(source='vendor.name', read_only=True)
    days_until_due = serializers.IntegerField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    repayment_status = serializers.CharField(read_only=True)
    priority_color = serializers.CharField(read_only=True)
    status_color = serializers.CharField(read_only=True)
    
    class Meta:
        model = Payable
        fields = (
            'id',
            'creditor_name',
            'creditor_phone',
            'creditor_email',
            'vendor_name',
            'vendor',
            'amount_borrowed',
            'amount_paid',
            'balance_remaining',
            'payment_percentage',
            'reason_or_item',
            'notes',
            'expected_repayment_date',
            'days_until_due',
            'is_overdue',
            'priority',
            'status',
            'repayment_status',
            'priority_color',
            'status_color',
            'is_fully_paid',
            'created_at',
            'created_by_email'
        )


class PayableDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single payable view"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    vendor_name = serializers.CharField(source='vendor.name', read_only=True)
    vendor_business_name = serializers.CharField(source='vendor.business_name', read_only=True)
    vendor_phone = serializers.CharField(source='vendor.phone', read_only=True)
    
    # Computed fields
    days_since_borrowed = serializers.IntegerField(read_only=True)
    days_until_due = serializers.IntegerField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    repayment_status = serializers.CharField(read_only=True)
    priority_color = serializers.CharField(read_only=True)
    status_color = serializers.CharField(read_only=True)
    
    # Related payments
    payments = serializers.SerializerMethodField()
    payments_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Payable
        fields = (
            'id',
            'creditor_name',
            'creditor_phone',
            'creditor_email',
            'vendor',
            'vendor_name',
            'vendor_business_name',
            'vendor_phone',
            'amount_borrowed',
            'amount_paid',
            'balance_remaining',
            'reason_or_item',
            'date_borrowed',
            'expected_repayment_date',
            'is_fully_paid',
            'payment_percentage',
            'priority',
            'status',
            'notes',
            'days_since_borrowed',
            'days_until_due',
            'is_overdue',
            'repayment_status',
            'priority_color',
            'status_color',
            'payments',
            'payments_count',
            'is_active',
            'created_at',
            'updated_at',
            'created_by'
        )
    
    def get_payments(self, obj):
        """Get recent payments for this payable"""
        recent_payments = obj.payments.order_by('-payment_date')[:5]
        return PayablePaymentSerializer(recent_payments, many=True).data
    
    def get_payments_count(self, obj):
        """Get total payments count for payable"""
        return obj.payments.count()


class PayableStatsSerializer(serializers.Serializer):
    """Serializer for payable statistics"""
    
    total_payables = serializers.IntegerField()
    overdue_payables = serializers.IntegerField()
    urgent_payables = serializers.IntegerField()
    paid_payables = serializers.IntegerField()
    pending_payables = serializers.IntegerField()
    total_borrowed_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_paid_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_outstanding_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    overdue_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    priority_breakdown = serializers.ListField()
    status_breakdown = serializers.ListField()
    top_creditors = serializers.ListField()


class PayableSearchSerializer(serializers.Serializer):
    """Serializer for payable search parameters"""
    
    q = serializers.CharField(
        required=True,
        min_length=1,
        help_text="Search query for creditor name, reason, notes, phone, or email"
    )
    status = serializers.ChoiceField(
        choices=Payable.STATUS_CHOICES,
        required=False,
        help_text="Filter by status"
    )
    priority = serializers.ChoiceField(
        choices=Payable.PRIORITY_CHOICES,
        required=False,
        help_text="Filter by priority"
    )
    vendor_id = serializers.UUIDField(
        required=False,
        help_text="Filter by vendor ID"
    )


class PayablePaymentSerializer(serializers.ModelSerializer):
    """Serializer for payable payments"""
    
    created_by = serializers.StringRelatedField(read_only=True)
    payable_creditor = serializers.CharField(source='payable.creditor_name', read_only=True)
    
    class Meta:
        model = PayablePayment
        fields = (
            'id',
            'payable',
            'payable_creditor',
            'amount',
            'payment_date',
            'notes',
            'created_at',
            'created_by'
        )
        read_only_fields = ('id', 'created_at', 'created_by', 'payable_creditor')

    def validate_amount(self, value):
        """Validate payment amount"""
        if value <= 0:
            raise serializers.ValidationError("Payment amount must be greater than zero.")
        return value

    def validate(self, data):
        """Cross-field validation"""
        payable = data.get('payable')
        amount = data.get('amount')
        
        if payable and amount:
            if payable.is_fully_paid:
                raise serializers.ValidationError({
                    'payable': 'Cannot add payment to a fully paid payable.'
                })
            
            if amount > payable.balance_remaining:
                raise serializers.ValidationError({
                    'amount': f'Payment amount cannot exceed remaining balance of {payable.balance_remaining}'
                })
        
        return data

    def create(self, validated_data):
        """Create payment with the requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)


class PayablePaymentCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating payments without payable field"""
    
    class Meta:
        model = PayablePayment
        fields = (
            'amount',
            'payment_date',
            'notes'
        )

    def validate_amount(self, value):
        """Validate payment amount"""
        if value <= 0:
            raise serializers.ValidationError("Payment amount must be greater than zero.")
        return value


class PayableBulkActionSerializer(serializers.Serializer):
    """Serializer for bulk payable actions"""
    
    payable_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        help_text="List of payable IDs to perform action on"
    )
    action = serializers.ChoiceField(
        choices=[
            ('activate', 'Activate'),
            ('deactivate', 'Deactivate'),
            ('mark_urgent', 'Mark as Urgent'),
            ('mark_high', 'Mark as High Priority'),
            ('mark_medium', 'Mark as Medium Priority'),
            ('mark_low', 'Mark as Low Priority'),
            ('cancel', 'Cancel'),
        ],
        required=True,
        help_text="Action to perform on selected payables"
    )
    notes = serializers.CharField(
        required=False,
        help_text="Optional notes for the bulk action"
    )

    def validate_payable_ids(self, value):
        """Validate that all payable IDs exist"""
        existing_ids = Payable.objects.filter(id__in=value).values_list('id', flat=True)
        existing_ids = [str(id) for id in existing_ids]
        
        missing_ids = [str(id) for id in value if str(id) not in existing_ids]
        
        if missing_ids:
            raise serializers.ValidationError(
                f"Payables not found: {', '.join(missing_ids)}"
            )
        
        return value


class PayableContactUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating payable contact information"""
    
    class Meta:
        model = Payable
        fields = ('creditor_name', 'creditor_phone', 'creditor_email')

    def validate_creditor_name(self, value):
        """Clean and validate creditor name"""
        if not value or not value.strip():
            raise serializers.ValidationError("Creditor name is required.")
        
        name = value.strip()
        if len(name) < 2:
            raise serializers.ValidationError("Creditor name must be at least 2 characters long.")
        
        return name


class PayableScheduleSerializer(serializers.Serializer):
    """Serializer for payment schedule view"""
    
    id = serializers.UUIDField()
    creditor_name = serializers.CharField()
    amount_borrowed = serializers.DecimalField(max_digits=12, decimal_places=2)
    balance_remaining = serializers.DecimalField(max_digits=12, decimal_places=2)
    expected_repayment_date = serializers.DateField()
    priority = serializers.CharField()
    status = serializers.CharField()
    days_until_due = serializers.IntegerField()
    is_overdue = serializers.BooleanField()
    priority_color = serializers.CharField()
    status_color = serializers.CharField()


class CreditorSummarySerializer(serializers.Serializer):
    """Serializer for creditor-wise summary"""
    
    creditor_name = serializers.CharField()
    total_payables = serializers.IntegerField()
    total_borrowed_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_outstanding_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    overdue_count = serializers.IntegerField()
    overdue_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    contact_info = serializers.DictField()
    vendor_info = serializers.DictField(required=False)
    