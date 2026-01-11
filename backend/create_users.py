"""
Test kullanıcıları ve admin hesabı oluşturma scripti
"""
import os
import sys
import django

# Django ayarlarını yükle
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from users.models import CustomUser

# Admin hesabı oluştur
admin, created = CustomUser.objects.get_or_create(
    email='admin@friendapp.com',
    defaults={
        'username': 'admin',
        'first_name': 'Admin',
        'last_name': 'User',
        'is_staff': True,
        'is_superuser': True,
        'is_admin_user': True,
    }
)
if created:
    admin.set_password('admin123')
    admin.save()
    print('Admin hesabı oluşturuldu!')
else:
    admin.is_admin_user = True
    admin.is_staff = True
    admin.is_superuser = True
    admin.save()
    print('Admin hesabı güncellendi!')

# 5 test kullanıcısı oluştur
test_users = [
    {'email': 'ali@test.com', 'first_name': 'Ali', 'last_name': 'Yılmaz', 'username': 'ali'},
    {'email': 'ayse@test.com', 'first_name': 'Ayşe', 'last_name': 'Demir', 'username': 'ayse'},
    {'email': 'mehmet@test.com', 'first_name': 'Mehmet', 'last_name': 'Kaya', 'username': 'mehmet'},
    {'email': 'fatma@test.com', 'first_name': 'Fatma', 'last_name': 'Çelik', 'username': 'fatma'},
    {'email': 'ahmet@test.com', 'first_name': 'Ahmet', 'last_name': 'Öztürk', 'username': 'ahmet'},
]

print('\nTest Kullanıcıları:')
for u in test_users:
    user, created = CustomUser.objects.get_or_create(
        email=u['email'],
        defaults={
            'username': u['username'],
            'first_name': u['first_name'],
            'last_name': u['last_name'],
        }
    )
    if created:
        user.set_password('test123')
        user.save()
    print(f"  ID:{user.id} - {user.first_name} {user.last_name} ({user.email})")

print('\n' + '='*50)
print('Tüm kullanıcılar hazır!')
print('='*50)
