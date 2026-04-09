from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import RealEstateSale, Dealer
from decimal import Decimal

@receiver(post_save, sender=RealEstateSale)
def update_dealer_financials(sender, instance, created, **kwargs):
    """Update Dealer's total commission and paid amounts when a sale is created or updated"""
    if instance.dealer:
        dealer = instance.dealer
        
        # Calculate totals from all dealer's sales
        all_sales = RealEstateSale.objects.filter(dealer=dealer)
        
        total_earned = Decimal('0.00')
        total_paid = Decimal('0.00')
        sales_count = all_sales.count()
        
        for sale in all_sales:
            total_earned += sale.dealer_commission
            total_paid += sale.dealer_paid_amount
            
        dealer.total_commission_earned = total_earned
        dealer.paid_amount = total_paid
        dealer.total_sales_count = sales_count
        dealer.save()

@receiver(post_delete, sender=RealEstateSale)
def update_dealer_financials_on_delete(sender, instance, **kwargs):
    """Update Dealer's totals when a sale is deleted"""
    if instance.dealer:
        dealer = instance.dealer
        all_sales = RealEstateSale.objects.filter(dealer=dealer)
        
        total_earned = Decimal('0.00')
        total_paid = Decimal('0.00')
        sales_count = all_sales.count()
        
        for sale in all_sales:
            total_earned += sale.dealer_commission
            total_paid += sale.dealer_paid_amount
            
        dealer.total_commission_earned = total_earned
        dealer.paid_amount = total_paid
        dealer.total_sales_count = sales_count
        dealer.save()

@receiver(post_delete, sender=RealEstateSale)
def reset_plot_status_on_delete(sender, instance, **kwargs):
    """Revert plot to AVAILABLE status when a sale is deleted"""
    if instance.plot:
        plot = instance.plot
        plot.status = 'AVAILABLE'
        plot.customer = None
        plot.dealer = None
        plot.sale_date = None
        plot.save()
