from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model


class Command(BaseCommand):
    help = 'Creates a default admin user if none exists'

    def handle(self, *args, **kwargs):
        User = get_user_model()

        # Only create if no superuser exists
        if not User.objects.filter(is_superuser=True).exists():
            User.objects.create_superuser(
                email='admin@metabrass.com',
                password='Admin@1234',
                full_name='Admin User',
            )
            self.stdout.write(self.style.SUCCESS(
                '✅ Default admin user created!\n'
                '   Email: admin@metabrass.com\n'
                '   Password: Admin@1234\n'
                '   ⚠️  Please change password after first login!'
            ))
        else:
            self.stdout.write(self.style.WARNING(
                'Admin user already exists. Skipping creation.'
            ))
