import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
try:
    print("Setting up django...")
    django.setup()
    print("Setup complete")
except Exception as e:
    print(f"Error: {e}")
