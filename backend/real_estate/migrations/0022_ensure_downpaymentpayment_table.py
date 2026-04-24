"""
Fix migration: Ensure real_estate_downpaymentpayment table exists on Railway.
On Railway, migration 0020 was marked as applied but the table was never
actually created due to a migration state mismatch. This migration uses
CREATE TABLE IF NOT EXISTS to safely create it if missing.
"""
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('real_estate', '0021_realestatesale_remarks'),
    ]

    operations = [
        migrations.RunSQL(
            sql="""
                CREATE TABLE IF NOT EXISTS "real_estate_downpaymentpayment" (
                    "id" uuid NOT NULL PRIMARY KEY,
                    "amount" numeric(12, 2) NOT NULL,
                    "payment_date" date NOT NULL,
                    "receipt_number" varchar(50) NULL,
                    "remarks" varchar(255) NULL,
                    "created_at" timestamp with time zone NOT NULL,
                    "sale_id" uuid NOT NULL
                        REFERENCES "real_estate_realestatesale" ("id")
                        DEFERRABLE INITIALLY DEFERRED
                );
                CREATE INDEX IF NOT EXISTS "real_estate_downpaymentpayment_sale_id_idx"
                    ON "real_estate_downpaymentpayment" ("sale_id");
            """,
            reverse_sql="DROP TABLE IF EXISTS real_estate_downpaymentpayment;",
        ),
    ]
