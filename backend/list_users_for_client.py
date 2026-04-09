import os
import django
import sys

# Add the backend directory to sys.path
sys.path.append(r'd:\R_Technologies_Intership\pos-realstates-main\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from posapi.models import User

print("--- User Accounts ---")
for user in User.objects.all():
    print(f"Email: {user.email}, Username: {user.username}, Is Admin: {user.is_superuser}")
