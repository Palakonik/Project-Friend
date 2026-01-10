from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    """
    Custom User model with Firebase authentication support.
    İki tür kullanıcı: normal ve admin
    """
    # Firebase UID - Firebase Authentication entegrasyonu için
    firebase_uid = models.CharField(max_length=128, unique=True, null=True, blank=True)
    
    # Eski Google ID - geriye uyumluluk için
    google_id = models.CharField(max_length=100, unique=True, null=True, blank=True)
    
    # Profil fotoğrafı
    profile_photo = models.URLField(max_length=500, blank=True, null=True)
    profile_photo_file = models.ImageField(upload_to='profile_photos/', blank=True, null=True)
    
    # E-posta doğrulama durumu
    is_email_verified = models.BooleanField(default=False, verbose_name="E-posta Doğrulandı")
    
    # Admin/Normal kullanıcı ayrımı (Django'nun is_staff'ından bağımsız)
    is_admin_user = models.BooleanField(default=False, verbose_name="Admin Kullanıcı")
    
    class Meta:
        verbose_name = "Kullanıcı"
        verbose_name_plural = "Kullanıcılar"
    
    def __str__(self):
        return f"{self.first_name} {self.last_name}" if self.first_name else self.username
    
    def get_profile_photo_url(self):
        """Profil fotoğrafı URL'sini döndür (dosya veya URL)"""
        if self.profile_photo_file:
            return self.profile_photo_file.url
        return self.profile_photo
