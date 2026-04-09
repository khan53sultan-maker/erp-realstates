from rest_framework import serializers
from .models import Purchase, PurchaseItem
from products.models import Product

class PurchaseItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = PurchaseItem
        fields = ['product', 'quantity', 'unit_cost', 'total_cost']

class PurchaseSerializer(serializers.ModelSerializer):
    items = PurchaseItemSerializer(many=True)
    # ✅ FIX: Send the vendor name directly from the backend
    vendor_name = serializers.ReadOnlyField(source='vendor.name')

    class Meta:
        model = Purchase
        fields = [
            'id',
            'vendor',
            'vendor_name', # ✅ Added here
            'invoice_number',
            'purchase_date',
            'subtotal',
            'tax',
            'total',
            'status',
            'items',
        ]
        read_only_fields = ['subtotal', 'total', 'vendor_name']

    def create(self, validated_data):
        items_data = validated_data.pop('items')

        # Initialize total=0 to satisfy DB constraint
        purchase = Purchase.objects.create(total=0, subtotal=0, **validated_data)

        subtotal = 0
        for item in items_data:
            product = item['product']
            quantity = item['quantity']
            unit_cost = item['unit_cost']
            total_cost = quantity * unit_cost

            PurchaseItem.objects.create(
                purchase=purchase,
                product=product,
                quantity=quantity,
                unit_cost=unit_cost,
                total_cost=total_cost
            )
            subtotal += total_cost

        purchase.subtotal = subtotal
        purchase.total = subtotal + purchase.tax
        purchase.save()

        return purchase