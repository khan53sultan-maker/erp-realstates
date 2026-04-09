from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver, Signal
from django.core.cache import cache
from django.utils import timezone
from .models import Order
import logging

logger = logging.getLogger(__name__)

# Custom signals for bulk operations
order_bulk_updated = Signal()
order_bulk_created = Signal()
order_bulk_deleted = Signal()
order_status_changed = Signal()
order_payment_added = Signal()


@receiver(pre_save, sender=Order)
def order_pre_save(sender, instance, **kwargs):
    """Handle order pre-save operations"""
    if instance.pk:  # Existing order
        try:
            old_instance = Order.objects.get(pk=instance.pk)
            
            # Track status changes
            if old_instance.status != instance.status:
                instance._old_status = old_instance.status
            
            # Track payment changes
            if old_instance.advance_payment != instance.advance_payment:
                instance._old_advance_payment = old_instance.advance_payment
            
            # Track delivery date changes
            if old_instance.expected_delivery_date != instance.expected_delivery_date:
                instance._old_delivery_date = old_instance.expected_delivery_date
                
        except Order.DoesNotExist:
            pass


@receiver(post_save, sender=Order)
def order_post_save(sender, instance, created, **kwargs):
    """Handle order post-save operations"""
    # Prevent recursion by checking if we're already processing this instance
    if hasattr(instance, '_processing_signal'):
        return
    
    # Mark this instance as being processed
    instance._processing_signal = True
    
    try:
        # Clear related caches
        cache_keys_to_clear = [
            'order_statistics',
            f'orders_by_customer_{instance.customer_id}',
            f'orders_by_status_{instance.status}',
            'pending_orders',
            'overdue_orders',
            'recent_orders',
            'unpaid_orders',
        ]
        
        # Remove None values and clear caches
        for key in filter(None, cache_keys_to_clear):
            cache.delete(key)
        
        # Log order creation
        if created:
            logger.info(
                f"New order created: Order #{instance.id} for {instance.customer_name} "
                f"(Phone: {instance.customer_phone}) "
                f"Total: PKR {instance.total_amount}, Advance: PKR {instance.advance_payment} "
                f"Status: {instance.get_status_display()} by user {instance.created_by}"
            )
            
            # Log delivery date if set
            if instance.expected_delivery_date:
                logger.info(
                    f"Order delivery scheduled: Order #{instance.id} "
                    f"expected delivery on {instance.expected_delivery_date}"
                )
        
        # Log status changes
        elif hasattr(instance, '_old_status'):
            old_status = instance._old_status
            new_status = instance.status
            
            logger.info(
                f"Order status updated: Order #{instance.id} ({instance.customer_name}) "
                f"from {old_status} to {new_status}"
            )
            
            # Send custom signal for status change
            order_status_changed.send(
                sender=Order,
                order=instance,
                old_status=old_status,
                new_status=new_status
            )
            
            delattr(instance, '_old_status')
        
        # Log payment changes
        elif hasattr(instance, '_old_advance_payment'):
            old_payment = instance._old_advance_payment
            new_payment = instance.advance_payment
            payment_difference = new_payment - old_payment
            
            logger.info(
                f"Order payment updated: Order #{instance.id} ({instance.customer_name}) "
                f"payment from PKR {old_payment} to PKR {new_payment} "
                f"(difference: PKR {payment_difference:+.2f}) "
                f"Remaining: PKR {instance.remaining_amount}"
            )
            
            # Send custom signal for payment addition
            if payment_difference > 0:
                order_payment_added.send(
                    sender=Order,
                    order=instance,
                    payment_amount=payment_difference,
                    is_fully_paid=instance.is_fully_paid
                )
            
            delattr(instance, '_old_advance_payment')
        
        # Log delivery date changes
        elif hasattr(instance, '_old_delivery_date'):
            old_date = instance._old_delivery_date
            new_date = instance.expected_delivery_date
            
            if old_date and new_date:
                logger.info(
                    f"Order delivery date updated: Order #{instance.id} ({instance.customer_name}) "
                    f"from {old_date} to {new_date}"
                )
            elif new_date:
                logger.info(
                    f"Order delivery date set: Order #{instance.id} ({instance.customer_name}) "
                    f"delivery scheduled for {new_date}"
                )
            else:
                logger.info(
                    f"Order delivery date removed: Order #{instance.id} ({instance.customer_name})"
                )
            
            delattr(instance, '_old_delivery_date')
    
    finally:
        # Always remove the processing flag
        if hasattr(instance, '_processing_signal'):
            delattr(instance, '_processing_signal')


@receiver(post_delete, sender=Order)
def order_post_delete(sender, instance, **kwargs):
    """Handle order deletion"""
    # Clear related caches
    cache_keys_to_clear = [
        'order_statistics',
        f'orders_by_customer_{instance.customer_id}',
        f'orders_by_status_{instance.status}',
        'pending_orders',
        'overdue_orders',
        'recent_orders',
        'unpaid_orders',
    ]
    
    # Remove None values and clear caches
    for key in filter(None, cache_keys_to_clear):
        cache.delete(key)
    
    # Log order deletion
    logger.info(
        f"Order deleted: Order #{instance.id} ({instance.customer_name}) "
        f"Total value: PKR {instance.total_amount}, Status: {instance.status}"
    )


@receiver(order_bulk_updated)
def handle_bulk_order_update(sender, orders, action, **kwargs):
    """Handle bulk order updates"""
    # Clear caches
    cache.delete('order_statistics')
    cache.delete('pending_orders')
    cache.delete('overdue_orders')
    cache.delete('recent_orders')
    cache.delete('unpaid_orders')
    
    # Clear status and customer specific caches
    for order in orders:
        cache.delete(f'orders_by_status_{order.status}')
        cache.delete(f'orders_by_customer_{order.customer_id}')
    
    # Log bulk update
    order_count = len(orders)
    logger.info(f"Bulk order update completed: {action} applied to {order_count} orders")
    
    # Specific logging for different actions
    if action == 'confirm':
        confirmed_orders = [f"#{o.id}" for o in orders[:5]]
        if order_count > 5:
            confirmed_orders.append(f"and {order_count - 5} more")
        
        logger.info(
            f"Orders confirmed: {order_count} orders confirmed: {', '.join(confirmed_orders)}"
        )
    
    elif action == 'start_production':
        logger.info(f"Production started: {order_count} orders moved to production")
    
    elif action == 'mark_ready':
        logger.info(f"Orders ready: {order_count} orders marked as ready for delivery")
    
    elif action == 'cancel':
        cancelled_orders = [f"#{o.id}" for o in orders[:5]]
        if order_count > 5:
            cancelled_orders.append(f"and {order_count - 5} more")
        
        logger.info(
            f"Orders cancelled: {order_count} orders cancelled: {', '.join(cancelled_orders)}"
        )


@receiver(order_bulk_created)
def handle_bulk_order_creation(sender, orders, **kwargs):
    """Handle bulk order creation"""
    # Clear caches
    cache.delete('order_statistics')
    cache.delete('recent_orders')
    
    # Log bulk creation
    order_count = len(orders)
    total_value = sum(order.total_amount for order in orders)
    
    logger.info(f"Bulk order creation completed: {order_count} orders created")
    logger.info(f"Total value of new orders: PKR {total_value}")
    
    # Customer breakdown
    customers = {}
    for order in orders:
        customer_name = order.customer_name
        customers[customer_name] = customers.get(customer_name, 0) + 1
    
    customer_summary = ', '.join([f'{name}: {count}' for name, count in list(customers.items())[:5]])
    if len(customers) > 5:
        customer_summary += f' and {len(customers) - 5} more customers'
    
    logger.info(f"Orders by customer: {customer_summary}")


@receiver(order_bulk_deleted)
def handle_bulk_order_deletion(sender, order_ids, **kwargs):
    """Handle bulk order deletion"""
    # Clear all order-related caches
    cache_keys_to_clear = [
        'order_statistics',
        'pending_orders',
        'overdue_orders',
        'recent_orders',
        'unpaid_orders',
    ]
    
    for key in cache_keys_to_clear:
        cache.delete(key)
    
    # Log bulk deletion
    order_count = len(order_ids)
    logger.info(f"Bulk order deletion completed: {order_count} orders deleted")


@receiver(order_status_changed)
def handle_order_status_change(sender, order, old_status, new_status, **kwargs):
    """Handle order status changes with business logic"""
    
    # Log status-specific actions
    if new_status == 'CONFIRMED':
        logger.info(
            f"Order confirmed: Order #{order.id} confirmed for {order.customer_name}. "
            f"Expected delivery: {order.expected_delivery_date or 'Not set'}"
        )
    
    elif new_status == 'IN_PRODUCTION':
        logger.info(
            f"Production started: Order #{order.id} for {order.customer_name} "
            f"has entered production phase"
        )
    
    elif new_status == 'READY':
        logger.info(
            f"Order ready: Order #{order.id} for {order.customer_name} "
            f"is ready for delivery"
        )
        
        # Check if delivery is overdue
        if order.is_overdue:
            logger.warning(
                f"Delivery overdue: Order #{order.id} was due on {order.expected_delivery_date} "
                f"but is just now ready (overdue by {abs(order.days_until_delivery)} days)"
            )
    
    elif new_status == 'DELIVERED':
        logger.info(
            f"Order delivered: Order #{order.id} for {order.customer_name} "
            f"has been successfully delivered"
        )
        
        # Check payment status
        if not order.is_fully_paid:
            logger.warning(
                f"Delivery with pending payment: Order #{order.id} delivered but "
                f"PKR {order.remaining_amount} payment is still pending"
            )
    
    elif new_status == 'CANCELLED':
        logger.info(
            f"Order cancelled: Order #{order.id} for {order.customer_name} "
            f"has been cancelled (was {old_status})"
        )
        
        # Log refund information if advance payment was made
        if order.advance_payment > 0:
            logger.info(
                f"Refund required: Order #{order.id} cancellation requires "
                f"refund of PKR {order.advance_payment} advance payment"
            )


@receiver(order_payment_added)
def handle_order_payment_addition(sender, order, payment_amount, is_fully_paid, **kwargs):
    """Handle payment additions to orders"""
    
    logger.info(
        f"Payment received: PKR {payment_amount} added to Order #{order.id} "
        f"({order.customer_name}). Total paid: PKR {order.advance_payment}"
    )
    
    if is_fully_paid:
        logger.info(
            f"Order fully paid: Order #{order.id} for {order.customer_name} "
            f"is now fully paid (PKR {order.total_amount})"
        )
    else:
        logger.info(
            f"Partial payment: Order #{order.id} still has PKR {order.remaining_amount} "
            f"remaining ({order.payment_percentage:.1f}% paid)"
        )


# Signal to update customer's last order date
@receiver(post_save, sender=Order)
def update_customer_last_order_date(sender, instance, created, **kwargs):
    """Update customer's last order date when order is created"""
    # Prevent recursion by checking if we're already processing this instance
    if hasattr(instance, '_processing_customer_update'):
        return
    
    # Mark this instance as being processed for customer update
    instance._processing_customer_update = True
    
    try:
        if created and instance.customer:
            try:
                customer = instance.customer
                customer.update_last_order_date(instance.date_ordered)
                logger.info(
                    f"Customer activity updated: {customer.name} last order date "
                    f"updated to {instance.date_ordered}"
                )
            except Exception as e:
                logger.error(
                    f"Failed to update customer last order date for "
                    f"customer {instance.customer_id}: {str(e)}"
                )
    finally:
        # Always remove the processing flag
        if hasattr(instance, '_processing_customer_update'):
            delattr(instance, '_processing_customer_update')


# Signal for overdue order notifications
# @receiver(post_save, sender=Order)  # TEMPORARILY DISABLED - CAUSING RECURSION
def check_overdue_orders(sender, instance, **kwargs):
    """Check and log overdue order warnings"""
    if instance.is_overdue and instance.status not in ['DELIVERED', 'CANCELLED']:
        days_overdue = abs(instance.days_until_delivery)
        logger.warning(
            f"Overdue order alert: Order #{instance.id} for {instance.customer_name} "
            f"is {days_overdue} days overdue (due: {instance.expected_delivery_date}, "
            f"status: {instance.get_status_display()})"
        )


# Signal for payment validation
@receiver(pre_save, sender=Order)
def validate_payment_logic(sender, instance, **kwargs):
    """Validate payment-related business logic"""
    if instance.advance_payment > instance.total_amount and instance.total_amount > 0:
        logger.warning(
            f"Payment exceeds total: Order #{instance.id} advance payment "
            f"(PKR {instance.advance_payment}) exceeds total amount "
            f"(PKR {instance.total_amount})"
        )


# Signal for delivery date validation
@receiver(pre_save, sender=Order)
def validate_delivery_date(sender, instance, **kwargs):
    """Validate delivery date logic"""
    if instance.expected_delivery_date and instance.date_ordered:
        if instance.expected_delivery_date < instance.date_ordered:
            logger.warning(
                f"Invalid delivery date: Order #{instance.id} delivery date "
                f"({instance.expected_delivery_date}) is before order date "
                f"({instance.date_ordered})"
            )


# Signal for order completion tracking
@receiver(order_status_changed)
def track_order_completion_time(sender, order, old_status, new_status, **kwargs):
    """Track order completion metrics"""
    if new_status == 'DELIVERED':
        days_to_complete = order.days_since_ordered
        logger.info(
            f"Order completion: Order #{order.id} completed in {days_to_complete} days "
            f"(ordered: {order.date_ordered}, delivered: {timezone.now().date()})"
        )
        
        # Check if delivered on time
        if order.expected_delivery_date:
            if timezone.now().date() <= order.expected_delivery_date:
                logger.info(
                    f"On-time delivery: Order #{order.id} delivered on or before "
                    f"expected date ({order.expected_delivery_date})"
                )
            else:
                days_late = (timezone.now().date() - order.expected_delivery_date).days
                logger.warning(
                    f"Late delivery: Order #{order.id} delivered {days_late} days "
                    f"after expected date ({order.expected_delivery_date})"
                )


# Signal for automatic status progression validation
@receiver(pre_save, sender=Order)
def validate_status_progression(sender, instance, **kwargs):
    """Validate logical status progression"""
    if instance.pk:
        try:
            old_instance = Order.objects.get(pk=instance.pk)
            if old_instance.status != instance.status:
                # Define valid status transitions
                valid_transitions = {
                    'PENDING': ['CONFIRMED', 'CANCELLED'],
                    'CONFIRMED': ['IN_PRODUCTION', 'CANCELLED'],
                    'IN_PRODUCTION': ['READY', 'CANCELLED'],
                    'READY': ['DELIVERED', 'CANCELLED'],
                    'DELIVERED': [],  # Terminal state
                    'CANCELLED': []   # Terminal state
                }
                
                valid_next_statuses = valid_transitions.get(old_instance.status, [])
                
                if instance.status not in valid_next_statuses and instance.status != old_instance.status:
                    logger.warning(
                        f"Invalid status transition: Order #{instance.id} cannot go "
                        f"from {old_instance.status} to {instance.status}. "
                        f"Valid transitions: {valid_next_statuses}"
                    )
        except Order.DoesNotExist:
            pass
        