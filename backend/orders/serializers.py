from rest_framework import serializers
from django.db.models import Q
from .models import Order
from customers.models import Customer
from decimal import Decimal


class OrderSerializer(serializers.ModelSerializer):
    """Complete serializer for Order model"""
    
    # Customer details
    customer_id = serializers.UUIDField(source='customer.id', read_only=True)
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    
    # Computed fields
    days_since_ordered = serializers.IntegerField(read_only=True)
    days_until_delivery = serializers.IntegerField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    payment_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    order_summary = serializers.JSONField(read_only=True)
    delivery_status = serializers.CharField(source='get_delivery_status', read_only=True)
    
    # Status display
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Order
        fields = (
            'id',
            'customer_id',
            'customer_name',
            'customer_phone',
            'customer_email',
            'advance_payment',
            'total_amount',
            'remaining_amount',
            'is_fully_paid',
            'date_ordered',
            'expected_delivery_date',
            'description',
            'status',
            'status_display',
            'days_since_ordered',
            'days_until_delivery',
            'is_overdue',
            'payment_percentage',
            'order_summary',
            'delivery_status',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'created_by_id'
        )
        read_only_fields = (
            'id', 'customer_id', 'customer_name', 'customer_phone', 'customer_email',
            'total_amount', 'remaining_amount', 'is_fully_paid', 'days_since_ordered',
            'days_until_delivery', 'is_overdue', 'payment_percentage', 'order_summary',
            'delivery_status', 'status_display', 'created_at', 'updated_at',
            'created_by', 'created_by_id'
        )

    def validate_advance_payment(self, value):
        """Validate advance payment"""
        if value < 0:
            raise serializers.ValidationError("Advance payment cannot be negative.")
        return value

    def validate_expected_delivery_date(self, value):
        """Validate expected delivery date"""
        if value and self.instance:
            if value < self.instance.date_ordered:
                raise serializers.ValidationError(
                    "Expected delivery date cannot be before order date."
                )
        return value

    def validate_description(self, value):
        """Clean description field"""
        if value:
            return value.strip()
        return value


class OrderCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating orders"""
    
    customer = serializers.UUIDField(write_only=True, help_text="Customer UUID")
    
    class Meta:
        model = Order
        fields = (
            'customer',
            'advance_payment',
            'date_ordered',
            'expected_delivery_date',
            'description',
            'status'
        )

    def validate_customer(self, value):
        """Validate customer exists and is active"""
        try:
            customer = Customer.objects.get(id=value, is_active=True)
            return customer
        except Customer.DoesNotExist:
            raise serializers.ValidationError("Invalid customer or customer is not active.")

    def validate_advance_payment(self, value):
        """Validate advance payment"""
        if value < 0:
            raise serializers.ValidationError("Advance payment cannot be negative.")
        return value

    def validate_expected_delivery_date(self, value):
        """Validate expected delivery date"""
        date_ordered = self.initial_data.get('date_ordered')
        if value and date_ordered:
            from datetime import datetime
            if isinstance(date_ordered, str):
                date_ordered = datetime.strptime(date_ordered, '%Y-%m-%d').date()
            if value < date_ordered:
                raise serializers.ValidationError(
                    "Expected delivery date cannot be before order date."
                )
        return value

    def validate_description(self, value):
        """Clean description field"""
        if value:
            return value.strip()
        return value

    def create(self, validated_data):
        """Create order with the requesting user as creator"""
        user = self.context['request'].user
        validated_data['created_by'] = user
        return super().create(validated_data)


class OrderUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating orders"""
    
    class Meta:
        model = Order
        fields = (
            'advance_payment',
            'expected_delivery_date',
            'description',
            'status'
        )

    def validate_advance_payment(self, value):
        """Validate advance payment doesn't exceed total amount"""
        if value < 0:
            raise serializers.ValidationError("Advance payment cannot be negative.")
        
        if self.instance and self.instance.total_amount > 0:
            if value > self.instance.total_amount:
                raise serializers.ValidationError(
                    f"Advance payment cannot exceed total amount of PKR {self.instance.total_amount}."
                )
        return value

    def validate_expected_delivery_date(self, value):
        """Validate expected delivery date"""
        if value and self.instance:
            if value < self.instance.date_ordered:
                raise serializers.ValidationError(
                    "Expected delivery date cannot be before order date."
                )
        return value

    def validate_status(self, value):
        """Validate status transitions"""
        if self.instance:
            current_status = self.instance.status
            
            # Prevent changing status of delivered or cancelled orders
            if current_status in ['DELIVERED', 'CANCELLED'] and value != current_status:
                raise serializers.ValidationError(
                    f"Cannot change status of {current_status.lower()} orders."
                )
            
            # Validate logical status progression
            valid_transitions = {
                'PENDING': ['CONFIRMED', 'CANCELLED'],
                'CONFIRMED': ['IN_PRODUCTION', 'CANCELLED'],
                'IN_PRODUCTION': ['READY', 'CANCELLED'],
                'READY': ['DELIVERED', 'CANCELLED'],
                'DELIVERED': [],  # Terminal state
                'CANCELLED': []   # Terminal state
            }
            
            if value != current_status and value not in valid_transitions.get(current_status, []):
                raise serializers.ValidationError(
                    f"Invalid status transition from {current_status} to {value}."
                )
        
        return value

    def validate_description(self, value):
        """Clean description field"""
        if value:
            return value.strip()
        return value


class OrderListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing orders"""
    
    customer_id = serializers.UUIDField(source='customer.id', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    days_since_ordered = serializers.IntegerField(read_only=True)
    days_until_delivery = serializers.IntegerField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    payment_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    order_summary = serializers.JSONField(read_only=True)
    delivery_status = serializers.CharField(source='get_delivery_status', read_only=True)
    order_items = serializers.SerializerMethodField()
    conversion_status = serializers.ReadOnlyField()
    converted_sales_amount = serializers.ReadOnlyField()
    conversion_date = serializers.ReadOnlyField()
    can_convert_to_sale = serializers.BooleanField(source='can_be_converted_to_sale', read_only=True)
    has_sales = serializers.BooleanField(source='has_been_converted_to_sale', read_only=True)
    related_sales = serializers.SerializerMethodField()
    created_by = serializers.StringRelatedField(read_only=True)
    
    def get_related_sales(self, obj):
        """Get sales created from this order"""
        sales = obj.get_related_sales()
        return [
            {
                'id': str(sale.id),
                'invoice_number': sale.invoice_number,
                'grand_total': float(sale.grand_total),
                'date_of_sale': sale.date_of_sale,
                'status': sale.status
            }
            for sale in sales
        ]

    def get_customer(self, obj):
        """Get customer details"""
        return {
            'id': str(obj.customer.id),
            'name': obj.customer.name,
            'phone': obj.customer.phone,
            'email': obj.customer.email,
            'status': obj.customer.status,
            'customer_type': obj.customer.customer_type
        }

    def get_order_items(self, obj):
        """Get order items summary"""
        items = obj.get_order_items()
        return [
            {
                'id': str(item.id),
                'product_name': item.product_name,
                'quantity': item.quantity,
                'unit_price': item.unit_price,
                'line_total': item.line_total,
                'has_customization': bool(item.customization_notes)
            }
            for item in items
        ]
    
    class Meta:
        model = Order
        fields = (
            'id',
            'customer',
            'customer_id',
            'customer_name',
            'customer_phone',
            'customer_email',
            'advance_payment',
            'total_amount',
            'remaining_amount',
            'is_fully_paid',
            'payment_percentage',
            'date_ordered',
            'expected_delivery_date',
            'description',
            'status',
            'status_display',
            'days_since_ordered',
            'days_until_delivery',
            'is_overdue',
            'order_summary',
            'delivery_status',
            'order_items',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'conversion_status', 'converted_sales_amount', 'conversion_date', 'can_convert_to_sale', 'has_sales', 'related_sales'
        )


class OrderDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single order view"""
    
    customer = serializers.SerializerMethodField()
    created_by = serializers.StringRelatedField(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    days_since_ordered = serializers.IntegerField(read_only=True)
    days_until_delivery = serializers.IntegerField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    payment_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    order_summary = serializers.JSONField(read_only=True)
    delivery_status = serializers.CharField(source='get_delivery_status', read_only=True)
    order_items = serializers.SerializerMethodField()
    customer_id = serializers.UUIDField(source='customer.id', read_only=True)
    conversion_status = serializers.ReadOnlyField()
    converted_sales_amount = serializers.ReadOnlyField()
    conversion_date = serializers.ReadOnlyField()
    can_convert_to_sale = serializers.BooleanField(source='can_be_converted_to_sale', read_only=True)
    has_sales = serializers.BooleanField(source='has_been_converted_to_sale', read_only=True)
    related_sales = serializers.SerializerMethodField()
    
    class Meta:
        model = Order
        fields = (
            'id',
            'customer',
            'customer_id',
            'customer_name',
            'customer_phone',
            'customer_email',
            'advance_payment',
            'total_amount',
            'remaining_amount',
            'is_fully_paid',
            'payment_percentage',
            'date_ordered',
            'expected_delivery_date',
            'description',
            'status',
            'status_display',
            'days_since_ordered',
            'days_until_delivery',
            'is_overdue',
            'order_summary',
            'delivery_status',
            'order_items',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'conversion_status', 'converted_sales_amount', 'conversion_date', 'can_convert_to_sale', 'has_sales', 'related_sales'
        )

    def get_related_sales(self, obj):
        """Get sales created from this order"""
        sales = obj.get_related_sales()
        return [
            {
                'id': str(sale.id),
                'invoice_number': sale.invoice_number,
                'grand_total': float(sale.grand_total),
                'date_of_sale': sale.date_of_sale,
                'status': sale.status
            }
            for sale in sales
        ]

    def get_customer(self, obj):
        """Get customer details"""
        return {
            'id': str(obj.customer.id),
            'name': obj.customer.name,
            'phone': obj.customer.phone,
            'email': obj.customer.email,
            'status': obj.customer.status,
            'customer_type': obj.customer.customer_type
        }

    def get_order_items(self, obj):
        """Get order items summary"""
        items = obj.get_order_items()
        return [
            {
                'id': str(item.id),
                'product_name': item.product_name,
                'quantity': item.quantity,
                'unit_price': item.unit_price,
                'line_total': item.line_total,
                'has_customization': bool(item.customization_notes)
            }
            for item in items
        ]


class OrderStatsSerializer(serializers.Serializer):
    """Serializer for order statistics"""
    
    total_orders = serializers.IntegerField()
    status_breakdown = serializers.DictField()
    financial_summary = serializers.DictField()
    payment_summary = serializers.DictField()
    delivery_summary = serializers.DictField()
    recent_activity = serializers.DictField()


class OrderPaymentSerializer(serializers.Serializer):
    """Serializer for adding payments to orders"""
    
    amount = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        min_value=Decimal('0.01'),
        help_text="Payment amount to add"
    )
    notes = serializers.CharField(
        max_length=500,
        required=False,
        help_text="Optional payment notes"
    )

    def validate_amount(self, value):
        """Validate payment amount"""
        if value <= 0:
            raise serializers.ValidationError("Payment amount must be positive.")
        return value


class OrderStatusUpdateSerializer(serializers.Serializer):
    """Serializer for updating order status"""
    
    status = serializers.ChoiceField(
        choices=Order.STATUS_CHOICES,
        help_text="New order status"
    )
    notes = serializers.CharField(
        max_length=1000,
        required=False,
        help_text="Optional status update notes"
    )


class OrderBulkActionSerializer(serializers.Serializer):
    """Serializer for bulk order actions"""
    
    order_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        help_text="List of order IDs to perform action on"
    )
    action = serializers.ChoiceField(
        choices=[
            ('confirm', 'Confirm Orders'),
            ('start_production', 'Start Production'),
            ('mark_ready', 'Mark as Ready'),
            ('cancel', 'Cancel Orders'),
            ('activate', 'Activate Orders'),
            ('deactivate', 'Deactivate Orders'),
        ],
        required=True,
        help_text="Action to perform on selected orders"
    )
    notes = serializers.CharField(
        max_length=1000,
        required=False,
        help_text="Optional notes for the bulk action"
    )

    def validate_order_ids(self, value):
        """Validate that all order IDs exist"""
        existing_ids = Order.objects.filter(id__in=value).values_list('id', flat=True)
        existing_ids = [str(id) for id in existing_ids]
        
        missing_ids = [str(id) for id in value if str(id) not in existing_ids]
        
        if missing_ids:
            raise serializers.ValidationError(
                f"Orders not found: {', '.join(missing_ids)}"
            )
        
        return value


class OrderSearchSerializer(serializers.Serializer):
    """Serializer for order search parameters"""
    
    q = serializers.CharField(
        required=True,
        min_length=1,
        help_text="Search query for customer name, phone, email, or order description"
    )
    status = serializers.ChoiceField(
        choices=Order.STATUS_CHOICES,
        required=False,
        help_text="Filter by order status"
    )
    payment_status = serializers.ChoiceField(
        choices=[('paid', 'Fully Paid'), ('unpaid', 'Unpaid'), ('partial', 'Partially Paid')],
        required=False,
        help_text="Filter by payment status"
    )
    delivery_status = serializers.ChoiceField(
        choices=[('overdue', 'Overdue'), ('due_today', 'Due Today'), ('upcoming', 'Upcoming')],
        required=False,
        help_text="Filter by delivery status"
    )
    date_from = serializers.DateField(
        required=False,
        help_text="Filter orders from this date"
    )
    date_to = serializers.DateField(
        required=False,
        help_text="Filter orders until this date"
    )


class OrderCustomerUpdateSerializer(serializers.Serializer):
    """Serializer for updating cached customer information in orders"""
    
    customer_name = serializers.CharField(max_length=200, required=False)
    customer_phone = serializers.CharField(max_length=20, required=False)
    customer_email = serializers.EmailField(required=False, allow_blank=True)

    def validate_customer_name(self, value):
        """Clean customer name"""
        if value:
            return value.strip()
        return value

    def validate_customer_phone(self, value):
        """Clean customer phone"""
        if value:
            return value.strip()
        return value

    def validate_customer_email(self, value):
        """Clean customer email"""
        if value:
            return value.strip().lower()
        return value
    