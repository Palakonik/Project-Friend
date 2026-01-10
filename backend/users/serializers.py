from rest_framework import serializers
from .models import CustomUser


class UserSerializer(serializers.ModelSerializer):
    """Kullanıcı serializer - liste ve detay için"""
    full_name = serializers.SerializerMethodField()
    profile_photo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 
                  'full_name', 'profile_photo', 'profile_photo_url', 
                  'is_admin_user', 'is_email_verified']
        read_only_fields = ['id', 'is_admin_user']
    
    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}".strip() or obj.username
    
    def get_profile_photo_url(self, obj):
        return obj.get_profile_photo_url()


class UserSearchSerializer(serializers.ModelSerializer):
    """Kullanıcı arama sonuçları için basit serializer"""
    full_name = serializers.SerializerMethodField()
    profile_photo_url = serializers.SerializerMethodField()
    
    class Meta:
        model = CustomUser
        fields = ['id', 'first_name', 'last_name', 'full_name', 'profile_photo', 'profile_photo_url']
    
    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}".strip() or obj.username
    
    def get_profile_photo_url(self, obj):
        return obj.get_profile_photo_url()


class GoogleAuthSerializer(serializers.Serializer):
    """Google ID Token doğrulama için (geriye uyumluluk)"""
    id_token = serializers.CharField(required=True)


class FirebaseAuthSerializer(serializers.Serializer):
    """Firebase Token doğrulama için"""
    firebase_token = serializers.CharField(required=True)


class FirebaseRegisterSerializer(serializers.Serializer):
    """Firebase ile kayıt için"""
    firebase_token = serializers.CharField(required=True)
    first_name = serializers.CharField(required=True, max_length=150)
    last_name = serializers.CharField(required=True, max_length=150)
    profile_photo = serializers.ImageField(required=False, allow_null=True)
