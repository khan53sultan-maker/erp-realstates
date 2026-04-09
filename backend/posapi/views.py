from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.auth import login, logout
from django.utils import timezone
from django.db import transaction
from .models import User
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserSerializer,
    ChangePasswordSerializer
)


@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    """
    Register a new user
    """
    serializer = UserRegistrationSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                user = serializer.save()
                
                # Create authentication token
                token, created = Token.objects.get_or_create(user=user)
                
                return Response({
                    'success': True,
                    'message': 'User registered successfully.',
                    'data': {
                        'user': UserSerializer(user).data,
                        'token': token.key
                    }
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Registration failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Registration failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    """
    Login user with email and password
    """
    serializer = UserLoginSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            user = serializer.validated_data['user']
            
            # Update last login
            user.last_login = timezone.now()
            user.save(update_fields=['last_login'])
            
            # Get or create token
            token, created = Token.objects.get_or_create(user=user)
            
            # Login user (for session-based auth if needed)
            login(request, user)
            
            return Response({
                'success': True,
                'message': 'Login successful.',
                'data': {
                    'user': UserSerializer(user).data,
                    'token': token.key
                }
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Login failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Login failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_user(request):
    """
    Logout user and delete token
    """
    try:
        # Delete the user's token
        token = Token.objects.get(user=request.user)
        token.delete()
        
        # Logout user from session
        logout(request)
        
        return Response({
            'success': True,
            'message': 'Logout successful.'
        }, status=status.HTTP_200_OK)
        
    except Token.DoesNotExist:
        # Token doesn't exist, but still logout the session
        logout(request)
        return Response({
            'success': True,
            'message': 'Logout successful.'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Logout failed.',
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    """
    Get current user profile
    """
    serializer = UserSerializer(request.user)
    
    return Response({
        'success': True,
        'data': serializer.data
    }, status=status.HTTP_200_OK)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_user_profile(request):
    """
    Update user profile
    """
    serializer = UserSerializer(
        request.user,
        data=request.data,
        partial=request.method == 'PATCH'
    )
    
    if serializer.is_valid():
        serializer.save()
        
        return Response({
            'success': True,
            'message': 'Profile updated successfully.',
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    
    return Response({
        'success': False,
        'message': 'Profile update failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password(request):
    """
    Change user password
    """
    serializer = ChangePasswordSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            user = request.user
            user.set_password(serializer.validated_data['new_password'])
            user.save()
            
            # Delete old token and create new one for security
            try:
                old_token = Token.objects.get(user=user)
                old_token.delete()
            except Token.DoesNotExist:
                pass
            
            token = Token.objects.create(user=user)
            
            return Response({
                'success': True,
                'message': 'Password changed successfully.',
                'data': {
                    'token': token.key
                }
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Password change failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Password change failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


# Class-based views alternative (more DRF standard)
class UserRegistrationAPIView(generics.CreateAPIView):
    """Class-based view for user registration"""
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        token, created = Token.objects.get_or_create(user=user)
        
        return Response({
            'success': True,
            'message': 'User registered successfully.',
            'data': {
                'user': UserSerializer(user).data,
                'token': token.key
            }
        }, status=status.HTTP_201_CREATED)


class UserProfileAPIView(generics.RetrieveUpdateAPIView):
    """Class-based view for user profile"""
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        return self.request.user
    