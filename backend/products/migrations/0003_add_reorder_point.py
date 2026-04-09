from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('products', '0002_product_barcode_product_sku_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='product',
            name='reorder_point',
            field=models.PositiveIntegerField(
                default=10,
                help_text='Minimum quantity before reorder alert'
            ),
        ),
        migrations.AddIndex(
            model_name='product',
            index=models.Index(fields=['reorder_point'], name='product_reorder_idx'),
        ),
    ]


