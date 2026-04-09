import os
import django
import importlib
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
from django.conf import settings

print("Testing app imports...")
for app in settings.INSTALLED_APPS:
    print(f"Importing {app}...")
    try:
        importlib.import_module(app)
        # Also try models if it's a child app
        if '.' not in app or app.startswith('django.'):
             try:
                 importlib.import_module(f"{app}.models")
             except ImportError:
                 pass
    except Exception as e:
        print(f"Error importing {app}: {e}")
print("Import test complete")
