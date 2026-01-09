from django.db import models
from django.conf import settings


class FriendRequest(models.Model):
    """
    Arkadaşlık isteği modeli.
    Admin onayına gönderilir, onaylandığında arkadaş olarak eklenir.
    """
    STATUS_CHOICES = [
        ('pending', 'Beklemede'),
        ('approved', 'Onaylandı'),
        ('rejected', 'Reddedildi'),
    ]
    
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='sent_requests',
        verbose_name="Gönderen"
    )
    receiver = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='received_requests',
        verbose_name="Alıcı"
    )
    note = models.TextField(blank=True, verbose_name="Not")
    status = models.CharField(
        max_length=10,
        choices=STATUS_CHOICES,
        default='pending',
        verbose_name="Durum"
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Oluşturulma Tarihi")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Güncellenme Tarihi")
    
    class Meta:
        verbose_name = "Arkadaşlık İsteği"
        verbose_name_plural = "Arkadaşlık İstekleri"
        unique_together = ['sender', 'receiver']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.sender} -> {self.receiver} ({self.get_status_display()})"


class BlockedUser(models.Model):
    """
    Engellenen kullanıcı modeli.
    Engellenen kişi tekrar arkadaşlık isteği gönderemez.
    """
    blocker = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='blocked_users',
        verbose_name="Engelleyen"
    )
    blocked = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='blocked_by',
        verbose_name="Engellenen"
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Engellenme Tarihi")
    
    class Meta:
        verbose_name = "Engellenmiş Kullanıcı"
        verbose_name_plural = "Engellenmiş Kullanıcılar"
        unique_together = ['blocker', 'blocked']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.blocker} engelledi: {self.blocked}"


class Friendship(models.Model):
    """
    Onaylanmış arkadaşlık ilişkisi.
    FriendRequest onaylandığında otomatik oluşturulur.
    """
    user1 = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='friendships_as_user1',
        verbose_name="Kullanıcı 1"
    )
    user2 = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='friendships_as_user2',
        verbose_name="Kullanıcı 2"
    )
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Arkadaşlık Tarihi")
    
    class Meta:
        verbose_name = "Arkadaşlık"
        verbose_name_plural = "Arkadaşlıklar"
        unique_together = ['user1', 'user2']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.user1} <-> {self.user2}"
