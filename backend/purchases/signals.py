from django.db.models.signals import post_save
from django.dispatch import receiver

from purchases.models import Purchase, PurchaseItem
from payables.models import Payable


# ===============================
# STOCK UPDATE ON PURCHASE ITEM
# ===============================
@receiver(post_save, sender=PurchaseItem)
def increase_stock_on_purchase_item(sender, instance, created, **kwargs):
    """
    Increase product stock when a purchase item is created.
    """
    if not created:
        return

    product = instance.product

    # ✅ FIX: Changed 'stock' to 'quantity' (common naming convention).
    # If your Product model uses a different name (e.g. 'inventory'), change it here.
    if hasattr(product, 'quantity'):
        product.quantity += instance.quantity
        product.save()
    elif hasattr(product, 'stock'):
        product.stock += instance.quantity
        product.save()
    else:
        # Fallback log if neither exists (prevents 500 error crash)
        print(f"⚠️ Error updating stock: Product model has no 'quantity' or 'stock' field.")


# ====================================
# PAYABLE CREATION ON PURCHASE POSTED
# ====================================
@receiver(post_save, sender=Purchase)
def create_or_update_payable_on_purchase(sender, instance, created, **kwargs):
    """
    Create or update payable when a purchase is POSTED.
    Draft purchases are ignored.
    Only create payable if total > 0 (Payable model requires amount_borrowed >= 0.01)
    """

    # Ignore drafts or zero-total purchases
    if instance.status != "posted" or instance.total <= 0:
        return

    # Ensure Payable has all required fields.
    # Added 'vendor' and 'balance' logic usually required for payables.
    payable, payable_created = Payable.objects.get_or_create(
        purchase=instance,
        defaults={
            "vendor": instance.vendor,  # Associate with the vendor
            "creditor_name": instance.vendor.name if instance.vendor else "Unknown Vendor",
            "amount_borrowed": instance.total,
            "amount_paid": 0,
            "reason_or_item": f"Purchase {instance.invoice_number or 'N/A'}",
            "date_borrowed": instance.purchase_date,
            "expected_repayment_date": instance.purchase_date,  # You may want to adjust this
        }
    )

    # Sync amount if purchase total changes
    if not payable_created and payable.amount_borrowed != instance.total:
        payable.amount_borrowed = instance.total
        payable.save()