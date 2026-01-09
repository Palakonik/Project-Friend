from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q
from django.conf import settings
from google.oauth2 import id_token
from google.auth.transport import requests

from .models import CustomUser
from .serializers import UserSerializer, UserSearchSerializer, GoogleAuthSerializer


class GoogleLoginView(APIView):
    """
    Google ile giriş yapma endpoint'i.
    Google ID token doğrulayıp kullanıcı oluşturur veya mevcut kullanıcıyı döndürür.
    """
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        serializer = GoogleAuthSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        token = serializer.validated_data['id_token']
        
        try:
            # Google ID token doğrulama
            idinfo = id_token.verify_oauth2_token(
                token, 
                requests.Request(), 
                settings.GOOGLE_CLIENT_ID
            )
            
            google_id = idinfo['sub']
            email = idinfo.get('email', '')
            first_name = idinfo.get('given_name', '')
            last_name = idinfo.get('family_name', '')
            profile_photo = idinfo.get('picture', '')
            
            # Kullanıcı var mı kontrol et, yoksa oluştur
            user, created = CustomUser.objects.get_or_create(
                google_id=google_id,
                defaults={
                    'username': email.split('@')[0] if email else f'user_{google_id[:8]}',
                    'email': email,
                    'first_name': first_name,
                    'last_name': last_name,
                    'profile_photo': profile_photo,
                }
            )
            
            # Mevcut kullanıcının bilgilerini güncelle
            if not created:
                user.profile_photo = profile_photo
                user.first_name = first_name
                user.last_name = last_name
                user.save()
            
            # Session oluştur
            from django.contrib.auth import login
            login(request, user)
            
            return Response({
                'user': UserSerializer(user).data,
                'is_new_user': created,
                'message': 'Giriş başarılı'
            }, status=status.HTTP_200_OK)
            
        except ValueError as e:
            return Response({
                'error': 'Geçersiz token',
                'detail': str(e)
            }, status=status.HTTP_401_UNAUTHORIZED)


class CurrentUserView(APIView):
    """Mevcut kullanıcı bilgilerini döndür"""
    
    def get(self, request):
        return Response(UserSerializer(request.user).data)


class UserSearchView(generics.ListAPIView):
    """
    Kullanıcı arama endpoint'i.
    Ad soyad ile arama yapılabilir.
    """
    serializer_class = UserSearchSerializer
    
    def get_queryset(self):
        query = self.request.query_params.get('q', '')
        if not query or len(query) < 2:
            return CustomUser.objects.none()
        
        # Kendisi hariç arama yap
        return CustomUser.objects.filter(
            Q(first_name__icontains=query) | 
            Q(last_name__icontains=query) |
            Q(username__icontains=query)
        ).exclude(id=self.request.user.id)[:20]


class LogoutView(APIView):
    """Çıkış yapma endpoint'i"""
    
    def post(self, request):
        from django.contrib.auth import logout
        logout(request)
        return Response({'message': 'Çıkış yapıldı'}, status=status.HTTP_200_OK)
