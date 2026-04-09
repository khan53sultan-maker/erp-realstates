import os
import django
import sys
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
from django.conf import settings
from django.apps import apps

print("Note: This will try to populate each app one by one.")
print("This might fail for apps that depend on each other, but it helps find the hang.")

for app_path in settings.INSTALLED_APPS:
    print(f"DEBUG: Trying to populate {app_path}...", flush=True)
    # Reset apps registry as much as possible or just try to populate
    # Actually, apps.populate cannot be called multiple times easily with different lists
    # So we'll just try to import the AppConfig and run its ready() if possible
    # But django.setup() is the real test.
    pass

print("Actually, the best way is to try django.setup() with some apps removed.", flush=True)
