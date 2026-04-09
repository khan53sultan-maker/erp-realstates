from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
from .models import Purchase
from .serializers import PurchaseSerializer

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def purchase_list(request):
    """
    List all purchases or create a new purchase
    """
    if request.method == 'GET':
        try:
            purchases = Purchase.objects.all().order_by('-created_at')
            serializer = PurchaseSerializer(purchases, many=True)
            
            return Response({
                'success': True,
                'data': serializer.data
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to fetch purchases.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    elif request.method == 'POST':
        try:
            with transaction.atomic():
                serializer = PurchaseSerializer(data=request.data)
                if serializer.is_valid():
                    purchase = serializer.save()
                    return Response({
                        'success': True,
                        'message': 'Purchase created successfully.',
                        'data': serializer.data
                    }, status=status.HTTP_201_CREATED)
                
                return Response({
                    'success': False,
                    'message': 'Failed to create purchase.',
                    'errors': serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'An error occurred while creating purchase.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def purchase_detail(request, pk):
    """
    Retrieve a specific purchase
    """
    try:
        purchase = Purchase.objects.get(pk=pk)
        serializer = PurchaseSerializer(purchase)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Purchase.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Purchase not found.',
            'errors': {'detail': 'Purchase with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'An error occurred while fetching purchase details.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
