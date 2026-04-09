import os
import django
import sys
from django.apps import apps

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
from django.conf import settings

print("Manually populating apps one by one...")
# We need to initialize settings first
from django.conf import settings
_ = settings.INSTALLED_APPS 

# Instead of django.setup(), we do what it does but with more prints
from django.utils.log import configure_logging
configure_logging(settings.LOGGING_CONFIG, settings.LOGGING)

print("Registry populate start")
# apps.populate(settings.INSTALLED_APPS)
# We'll do it manually
for app_config in settings.INSTALLED_APPS:
    print(f"Loading app: {app_config}...", flush=True)
    try:
        apps.populate([app_config])
    except Exception as e:
        print(f"Error loading {app_config}: {e}")
print("Registry populate end")
