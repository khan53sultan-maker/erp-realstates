from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('products', '0002_product_barcode_product_sku_and_more'),
    ]

    operations = [
        migrations.RunSQL(
            # Forward: Add column only if it doesn't already exist
            sql="""
                DO $$
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_name='product' AND column_name='reorder_point'
                    ) THEN
                        ALTER TABLE product ADD COLUMN reorder_point integer NOT NULL DEFAULT 10;
                    END IF;
                END $$;

                DO $$
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM pg_indexes
                        WHERE tablename='product' AND indexname='product_reorder_idx'
                    ) THEN
                        CREATE INDEX product_reorder_idx ON product (reorder_point);
                    END IF;
                END $$;
            """,
            # Reverse: Remove column and index if exists
            reverse_sql="""
                DROP INDEX IF EXISTS product_reorder_idx;
                ALTER TABLE product DROP COLUMN IF EXISTS reorder_point;
            """,
        ),
    ]
