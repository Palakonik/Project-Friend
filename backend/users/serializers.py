from rest_framework import serializers
from .models import CustomUser


class UserSerializer(serializers.ModelSerializer):
    """Kullanıcı serializer - liste ve detay için"""
    full_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 
                  'full_name', 'profile_photo', 'is_admin_user']
        read_only_fields = ['id', 'is_admin_user']
    
    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}".strip() or obj.username


class UserSearchSerializer(serializers.ModelSerializer):
    """Kullanıcı arama sonuçları için basit serializer"""
    full_name = serializers.SerializerMethodField()
    
    class Meta:
        model = CustomUser
        fields = ['id', 'first_name', 'last_name', 'full_name', 'profile_photo']
    
    def get_full_name(self, obj):
        return f"{obj.first_name} {obj.last_name}".strip() or obj.username


class GoogleAuthSerializer(serializers.Serializer):
    """Google ID Token doğrulama için"""
    id_token = serializers.CharField(required=True)
