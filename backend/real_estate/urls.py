from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ProjectViewSet, PlotViewSet, DealerViewSet, 
    RealEstateSaleViewSet, InstallmentViewSet,
    RealEstateIncomeViewSet, RealEstateExpenseViewSet,
    FinancialReportViewSet
)

router = DefaultRouter()
router.register(r'projects', ProjectViewSet)
router.register(r'plots', PlotViewSet)
router.register(r'dealers', DealerViewSet)
router.register(r'sales', RealEstateSaleViewSet)
router.register(r'installments', InstallmentViewSet)
router.register(r'incomes', RealEstateIncomeViewSet)
router.register(r'expenses', RealEstateExpenseViewSet)
router.register(r'reports', FinancialReportViewSet, basename='financial-reports')

urlpatterns = [
    path('', include(router.urls)),
]
