from django.contrib.auth.models import AbstractUser
from django.db import models


class CustomUser(AbstractUser):
    """
    Custom User model with Google authentication support.
    İki tür kullanıcı: normal ve admin
    """
    google_id = models.CharField(max_length=100, unique=True, null=True, blank=True)
    profile_photo = models.URLField(max_length=500, blank=True, null=True)
    
    # Admin/Normal kullanıcı ayrımı (Django'nun is_staff'ından bağımsız)
    is_admin_user = models.BooleanField(default=False, verbose_name="Admin Kullanıcı")
    
    class Meta:
        verbose_name = "Kullanıcı"
        verbose_name_plural = "Kullanıcılar"
    
    def __str__(self):
        return f"{self.first_name} {self.last_name}" if self.first_name else self.username
