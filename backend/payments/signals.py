from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.db import transaction
from django.utils import timezone
from decimal import Decimal
from .models import Payment
import logging

# Set up logger
logger = logging.getLogger(__name__)


# ============================================================================
# EXISTING SIGNALS (Your original code - preserved)
# ============================================================================

@receiver(post_save, sender=Payment)
def payment_post_save(sender, instance, created, **kwargs):
    """
    Signal handler for payment post-save operations
    """
    try:
        if created:
            # Log payment creation
            logger.info(
                f"New payment created: {instance.id} - "
                f"Amount: {instance.amount_paid}, "
                f"Payer: {instance.payer_type}, "
                f"Date: {instance.date}"
            )
            
            # Update related entity information if needed
            if instance.labor:
                # Update labor's last payment date
                instance.labor.last_payment_date = timezone.now()
                instance.labor.save(update_fields=['last_payment_date'])
                
            elif instance.vendor:
                # Update vendor's last payment date
                instance.vendor.last_payment_date = timezone.now()
                instance.vendor.save(update_fields=['last_payment_date'])
                
        else:
            # Log payment update
            logger.info(
                f"Payment updated: {instance.id} - "
                f"Amount: {instance.amount_paid}, "
                f"Status: {'Active' if instance.is_active else 'Inactive'}"
            )
            
    except Exception as e:
        logger.error(f"Error in payment post-save signal: {str(e)}")


@receiver(post_delete, sender=Payment)
def payment_post_delete(sender, instance, **kwargs):
    """
    Signal handler for payment post-delete operations
    """
    try:
        # Log payment deletion
        logger.info(
            f"Payment deleted: {instance.id} - "
            f"Amount: {instance.amount_paid}, "
            f"Payer: {instance.payer_type}, "
            f"Date: {instance.date}"
        )
        
    except Exception as e:
        logger.error(f"Error in payment post-delete signal: {str(e)}")


@receiver(post_save, sender=Payment)
def update_payment_statistics(sender, instance, **kwargs):
    """
    Signal handler to update payment statistics when payments change
    """
    try:
        # This could trigger cache invalidation or update summary tables
        # For now, just log the event
        if instance.is_final_payment:
            logger.info(
                f"Final payment marked: {instance.id} - "
                f"Amount: {instance.amount_paid}, "
                f"Month: {instance.payment_month}"
            )
            
    except Exception as e:
        logger.error(f"Error updating payment statistics: {str(e)}")


# ============================================================================
# NEW PAYABLE AUTO-REDUCTION SIGNALS
# ============================================================================

@receiver(post_save, sender=Payment)
def auto_reduce_payable_on_payment(sender, instance, created, **kwargs):
    """
    Automatically reduce vendor payable when payment is created.
    Only triggers for vendor payments that are active.
    """
    # Only process vendor payments
    if instance.payer_type != 'VENDOR' or not instance.vendor or not instance.is_active:
        return
    
    # Only process on creation or if payment wasn't previously processed
    if not created and hasattr(instance, '_payable_processed'):
        return
    
    try:
        from payables.models import Payable
        
        with transaction.atomic():
            # Find the most recent active payable for this vendor
            # Priority: linked payable > most recent pending payable
            payable = None
            
            if hasattr(instance, 'payable') and instance.payable:
                # Use explicitly linked payable
                payable = instance.payable
            else:
                # Auto-link to most recent pending payable for this vendor
                payable = Payable.objects.filter(
                    vendor=instance.vendor,
                    is_active=True,
                    is_fully_paid=False
                ).order_by('-date_borrowed').first()
            
            if not payable:
                logger.warning(
                    f"No pending payable found for vendor {instance.vendor.business_name} "
                    f"(Payment ID: {instance.id})"
                )
                return
            
            # Check if payment amount exceeds remaining balance
            if instance.amount_paid > payable.balance_remaining:
                logger.warning(
                    f"Payment amount ({instance.amount_paid}) exceeds "
                    f"payable balance ({payable.balance_remaining}) for vendor {instance.vendor.business_name}"
                )
                # Still process but log the overpayment
            
            # Add payment to payable
            old_balance = payable.balance_remaining
            payable.amount_paid += instance.amount_paid
            payable.save()
            
            # Link payment to payable if not already linked (and field exists)
            if hasattr(instance, 'payable') and not instance.payable:
                Payment.objects.filter(id=instance.id).update(payable=payable)
            
            # Mark as processed to avoid re-processing
            instance._payable_processed = True
            
            logger.info(
                f"✅ Auto-reduced payable for {instance.vendor.business_name}: "
                f"PKR {old_balance:,.2f} → PKR {payable.balance_remaining:,.2f} "
                f"(Payment: PKR {instance.amount_paid:,.2f})"
            )
            
    except Exception as e:
        logger.error(
            f"❌ Failed to auto-reduce payable for payment {instance.id}: {str(e)}"
        )


@receiver(post_delete, sender=Payment)
def reverse_payable_reduction_on_payment_deletion(sender, instance, **kwargs):
    """
    Reverse payable reduction when vendor payment is deleted.
    """
    # Only process vendor payments that were linked to a payable
    if instance.payer_type != 'VENDOR':
        return
    
    # Check if payable field exists and is linked
    if not hasattr(instance, 'payable') or not instance.payable:
        return
    
    try:
        payable = instance.payable
        
        with transaction.atomic():
            # Reverse the payment
            old_balance = payable.balance_remaining
            payable.amount_paid -= instance.amount_paid
            payable.save()
            
            logger.info(
                f"↩️ Reversed payable reduction for {instance.vendor.business_name}: "
                f"PKR {old_balance:,.2f} → PKR {payable.balance_remaining:,.2f} "
                f"(Reversed payment: PKR {instance.amount_paid:,.2f})"
            )
            
    except Exception as e:
        logger.error(
            f"❌ Failed to reverse payable reduction for payment {instance.id}: {str(e)}"
        )