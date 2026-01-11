from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from django.db.models import Q
from django.conf import settings

from .models import CustomUser
from .serializers import (
    UserSerializer, UserSearchSerializer, GoogleAuthSerializer,
    FirebaseAuthSerializer, FirebaseRegisterSerializer
)

# Firebase Admin SDK - opsiyonel import
try:
    import firebase_admin
    from firebase_admin import auth as firebase_auth, credentials
    
    # Firebase Admin SDK'yı başlat (henüz başlatılmamışsa)
    if not firebase_admin._apps:
        # serviceAccountKey.json dosyasının yolu
        import os
        cred_path = os.path.join(settings.BASE_DIR, 'serviceAccountKey.json')
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            FIREBASE_ENABLED = True
        else:
            FIREBASE_ENABLED = False
            print("Warning: serviceAccountKey.json not found. Firebase authentication disabled.")
    else:
        FIREBASE_ENABLED = True
except ImportError:
    FIREBASE_ENABLED = False
    print("Warning: firebase-admin not installed. Firebase authentication disabled.")

# Google OAuth (geriye uyumluluk için)
try:
    from google.oauth2 import id_token
    from google.auth.transport import requests
    GOOGLE_AUTH_ENABLED = True
except ImportError:
    GOOGLE_AUTH_ENABLED = False


class FirebaseLoginView(APIView):
    """
    Firebase token ile giriş yapma endpoint'i.
    Firebase ID token doğrulayıp kullanıcı oluşturur veya mevcut kullanıcıyı döndürür.
    """
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        if not FIREBASE_ENABLED:
            return Response({
                'error': 'Firebase authentication disabled',
                'detail': 'Firebase Admin SDK not configured'
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        
        serializer = FirebaseAuthSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        token = serializer.validated_data['firebase_token']
        
        try:
            # Firebase ID token doğrulama
            decoded_token = firebase_auth.verify_id_token(token)
            
            uid = decoded_token['uid']
            email = decoded_token.get('email', '')
            name = decoded_token.get('name', '')
            picture = decoded_token.get('picture', '')
            email_verified = decoded_token.get('email_verified', False)
            
            # İsmi parçala
            name_parts = name.split(' ', 1) if name else ['', '']
            first_name = name_parts[0]
            last_name = name_parts[1] if len(name_parts) > 1 else ''
            
            # Kullanıcı var mı kontrol et (firebase_uid veya email ile)
            user = CustomUser.objects.filter(
                Q(firebase_uid=uid) | Q(email=email)
            ).first()
            
            if user:
                # Mevcut kullanıcıyı güncelle
                user.firebase_uid = uid
                user.is_email_verified = email_verified
                if picture:
                    user.profile_photo = picture
                if first_name and not user.first_name:
                    user.first_name = first_name
                if last_name and not user.last_name:
                    user.last_name = last_name
                user.save()
                created = False
            else:
                # Yeni kullanıcı oluştur
                username = email.split('@')[0] if email else f'user_{uid[:8]}'
                # Username benzersiz olmalı
                base_username = username
                counter = 1
                while CustomUser.objects.filter(username=username).exists():
                    username = f"{base_username}{counter}"
                    counter += 1
                
                user = CustomUser.objects.create(
                    firebase_uid=uid,
                    username=username,
                    email=email,
                    first_name=first_name,
                    last_name=last_name,
                    profile_photo=picture,
                    is_email_verified=email_verified,
                )
                created = True
            
            # Session oluştur
            from django.contrib.auth import login
            login(request, user)
            
            return Response({
                'user': UserSerializer(user).data,
                'is_new_user': created,
                'message': 'Giriş başarılı'
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': 'Geçersiz token',
                'detail': str(e)
            }, status=status.HTTP_401_UNAUTHORIZED)


class FirebaseRegisterView(APIView):
    """
    Firebase ile kayıt endpoint'i.
    Profil fotoğrafı yükleme destekler.
    """
    permission_classes = [permissions.AllowAny]
    parser_classes = [MultiPartParser, FormParser]
    
    def post(self, request):
        if not FIREBASE_ENABLED:
            return Response({
                'error': 'Firebase authentication disabled',
                'detail': 'Firebase Admin SDK not configured'
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        
        firebase_token = request.data.get('firebase_token')
        first_name = request.data.get('first_name', '')
        last_name = request.data.get('last_name', '')
        profile_photo = request.FILES.get('profile_photo')
        
        if not firebase_token:
            return Response({
                'error': 'firebase_token gerekli'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Firebase ID token doğrulama
            decoded_token = firebase_auth.verify_id_token(firebase_token)
            
            uid = decoded_token['uid']
            email = decoded_token.get('email', '')
            
            # Kullanıcı var mı kontrol et
            user = CustomUser.objects.filter(firebase_uid=uid).first()
            
            if user:
                # Mevcut kullanıcıyı güncelle
                user.first_name = first_name
                user.last_name = last_name
                if profile_photo:
                    user.profile_photo_file = profile_photo
                user.save()
                created = False
            else:
                # Yeni kullanıcı oluştur
                username = email.split('@')[0] if email else f'user_{uid[:8]}'
                base_username = username
                counter = 1
                while CustomUser.objects.filter(username=username).exists():
                    username = f"{base_username}{counter}"
                    counter += 1
                
                user = CustomUser.objects.create(
                    firebase_uid=uid,
                    username=username,
                    email=email,
                    first_name=first_name,
                    last_name=last_name,
                )
                if profile_photo:
                    user.profile_photo_file = profile_photo
                    user.save()
                created = True
            
            # Session oluştur
            from django.contrib.auth import login
            login(request, user)
            
            return Response({
                'user': UserSerializer(user).data,
                'is_new_user': created,
                'message': 'Kayıt başarılı'
            }, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'error': 'Kayıt hatası',
                'detail': str(e)
            }, status=status.HTTP_400_BAD_REQUEST)


class GoogleLoginView(APIView):
    """
    Google ile giriş yapma endpoint'i (geriye uyumluluk).
    Google ID token doğrulayıp kullanıcı oluşturur veya mevcut kullanıcıyı döndürür.
    """
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        if not GOOGLE_AUTH_ENABLED:
            return Response({
                'error': 'Google authentication disabled',
            }, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        
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


class IsAdminUser(permissions.BasePermission):
    """Admin kullanıcı kontrolü"""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.is_admin_user


class AllUsersView(APIView):
    """Tüm kullanıcıları listele (sadece admin görebilir)"""
    permission_classes = [IsAdminUser]
    
    def get(self, request):
        users = CustomUser.objects.all().order_by('-date_joined')
        data = []
        for user in users:
            data.append({
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name,
                'last_name': user.last_name,
                'full_name': f"{user.first_name} {user.last_name}".strip(),
                'profile_photo': user.profile_photo if user.profile_photo else None,
                'is_admin_user': user.is_admin_user,
                'date_joined': user.date_joined.isoformat(),
            })
        return Response(data)


class ToggleAdminView(APIView):
    """Kullanıcıya admin yetkisi ver/kaldır (sadece admin yapabilir)"""
    permission_classes = [IsAdminUser]
    
    def post(self, request, user_id):
        try:
            target_user = CustomUser.objects.get(id=user_id)
        except CustomUser.DoesNotExist:
            return Response(
                {'error': 'Kullanıcı bulunamadı'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Kendini değiştiremez
        if target_user == request.user:
            return Response(
                {'error': 'Kendi admin yetkinizi değiştiremezsiniz'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Admin durumunu tersine çevir
        target_user.is_admin_user = not target_user.is_admin_user
        target_user.save()
        
        action = 'verildi' if target_user.is_admin_user else 'kaldırıldı'
        
        return Response({
            'message': f'{target_user.first_name} {target_user.last_name} için admin yetkisi {action}',
            'user_id': target_user.id,
            'is_admin_user': target_user.is_admin_user,
        })

