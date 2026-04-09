from rest_framework import permissions

class IsAdmin(permissions.BasePermission):
    """Allows access only to Admin users."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == 'ADMIN')

class IsManager(permissions.BasePermission):
    """Allows access to Admin and Manager users."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and 
                   (request.user.role == 'ADMIN' or request.user.role == 'MANAGER'))

class IsSalesAgent(permissions.BasePermission):
    """Allows access to Admin, Manager and Sales Agent users."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and 
                   (request.user.role == 'ADMIN' or request.user.role == 'MANAGER' or request.user.role == 'SALES_AGENT'))

class IsAccountant(permissions.BasePermission):
    """Allows access to Admin and Accountant users."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and 
                   (request.user.role == 'ADMIN' or request.user.role == 'ACCOUNTANT'))
