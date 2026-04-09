from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('products', '0002_product_barcode_product_sku_and_more'),
    ]

    operations = [
        migrations.RunSQL(
            # Safely add column only if it doesn't already exist
            sql="""
                DO $$
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_name='products_product' AND column_name='reorder_point'
                    ) THEN
                        ALTER TABLE products_product ADD COLUMN reorder_point integer NOT NULL DEFAULT 10;
                    END IF;
                END $$;
            """,
            reverse_sql="""
                ALTER TABLE product DROP COLUMN IF EXISTS reorder_point;
            """,
        ),
    ]
