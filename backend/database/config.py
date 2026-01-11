"""
PostgreSQL Veritabanı Yapılandırması
Arkadaşlık Uygulaması Backend

Bu dosyayı düzenleyerek veritabanı ayarlarınızı yapılandırabilirsiniz.
"""

import os

# Ortam değişkenlerinden veya varsayılan değerlerden al
DB_NAME = os.environ.get('DB_NAME', 'friendapp')
DB_USER = os.environ.get('DB_USER', 'postgres')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'mete0202')  # Kendi şifrenizi girin!
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_PORT = os.environ.get('DB_PORT', '5432')

# Django DATABASES ayarı
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': DB_NAME,
        'USER': DB_USER,
        'PASSWORD': DB_PASSWORD,
        'HOST': DB_HOST,
        'PORT': DB_PORT,
        'OPTIONS': {
            'connect_timeout': 10,
        },
    }
}

# SQLite fallback (development için)
DATABASES_SQLITE = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': 'db.sqlite3',
    }
}
