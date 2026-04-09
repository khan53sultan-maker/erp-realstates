from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone


class UserManager(BaseUserManager):
    """Custom user manager for email-based authentication"""
    
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('agreed_to_terms', True)

        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    """Custom User model with email as username field"""
    
    # Roles
    ADMIN = 'ADMIN'
    MANAGER = 'MANAGER'
    SALES_AGENT = 'SALES_AGENT'
    ACCOUNTANT = 'ACCOUNTANT'
    
    ROLE_CHOICES = [
        (ADMIN, 'Admin'),
        (MANAGER, 'Manager'),
        (SALES_AGENT, 'Sales Agent'),
        (ACCOUNTANT, 'Accountant'),
    ]

    id = models.AutoField(primary_key=True)
    full_name = models.CharField(max_length=255)
    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default=ADMIN)
    agreed_to_terms = models.BooleanField(default=False)
    
    # Additional fields for Django admin and permissions
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(default=timezone.now)
    last_login = models.DateTimeField(null=True, blank=True)

    @property
    def is_admin(self):
        return self.role == self.ADMIN or self.is_superuser

    @property
    def is_manager(self):
        return self.role == self.MANAGER

    @property
    def is_sales_agent(self):
        return self.role == self.SALES_AGENT

    @property
    def is_accountant(self):
        return self.role == self.ACCOUNTANT
    
    @property
    def is_staff(self):
        """Allow superusers to access admin without is_staff field"""
        return self.is_superuser
    
    objects = UserManager()
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name']
    
    class Meta:
        db_table = 'user'
        verbose_name = 'User'
        verbose_name_plural = 'Users'
    
    def __str__(self):
        return self.email
    
    @property
    def get_full_name(self):
        return self.full_name
    
    @property
    def get_short_name(self):
        return self.full_name.split(' ')[0] if self.full_name else self.email
    