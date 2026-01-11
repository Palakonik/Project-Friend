"""
Django settings for core project.
Arkadaşlık Uygulaması Backend - Render & Local Uyumlu
"""
import os
from pathlib import Path
import dj_database_url  # Bu paket Render veritabanı için şart

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# --- ORTAM KONTROLÜ (ÇOK ÖNEMLİ) ---
# Render'da mıyız yoksa bilgisayarda mı? Bunu anlıyoruz.
IN_RENDER = os.environ.get('RENDER')

# SECURITY WARNING: keep the secret key used in production secret!
# Render'da gizli anahtarı ortam değişkeninden alır, yoksa yereldekini kullanır.
SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-yerel-icin-rastgele-bir-anahtar-yazabilirsin')

# SECURITY WARNING: don't run with debug turned on in production!
# Render'daysak False (Kapalı), Bilgisayardaysak True (Açık) olur.
DEBUG = False if IN_RENDER else True

ALLOWED_HOSTS = ['*'] # Şimdilik her yere izin verelim, sorun çıkmasın.


# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Third party apps
    'rest_framework',
    'corsheaders',
    # Local apps
    'users',
    'friends',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    "whitenoise.middleware.WhiteNoiseMiddleware",  # CSS dosyaları için şart
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'core.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'core.wsgi.application'


# --- VERİTABANI AYARLARI (KRİTİK BÖLÜM) ---

# Önce varsayılan olarak yerel ayarları çekmeyi dene
try:
    from database.config import DATABASES
except ImportError:
    # Eğer config dosyası yoksa boş bir şablon oluştur (Hata vermesin diye)
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }

# EĞER RENDER'DAYSAK VEYA DATABASE_URL VARSA, AYARLARI EZ VE RENDER'INKİNİ KULLAN
if 'DATABASE_URL' in os.environ:
    DATABASES['default'] = dj_database_url.config(
        conn_max_age=600,
        conn_health_checks=True,
        ssl_require=True,
    )


# Custom User Model
AUTH_USER_MODEL = 'users.CustomUser'

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    { 'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator', },
    { 'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator', },
    { 'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator', },
    { 'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator', },
]

# Internationalization
LANGUAGE_CODE = 'tr-tr'
TIME_ZONE = 'Europe/Istanbul'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

MEDIA_URL = 'media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# REST Framework settings
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'core.authentication.CsrfExemptSessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# CORS settings
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

# --- GÜVENLİK AYARLARI (HTTPS vs HTTP) ---
if IN_RENDER:
    # Render (Canlı) Ayarları - Güvenlik Sıkı
    CSRF_TRUSTED_ORIGINS = ['https://friend-app-backend.onrender.com'] # Kendi siten
    CSRF_COOKIE_SECURE = True
    SESSION_COOKIE_SECURE = True
    SECURE_SSL_REDIRECT = True
    CSRF_COOKIE_SAMESITE = 'None'
    SESSION_COOKIE_SAMESITE = 'None'
else:
    # Localhost Ayarları - Güvenlik Gevşek (Hata almamak için)
    CSRF_TRUSTED_ORIGINS = ['http://localhost:8000', 'http://127.0.0.1:8000', 'http://10.0.2.2:8000']
    CSRF_COOKIE_SECURE = False   # Localde False olmalı yoksa 403 alırsın
    SESSION_COOKIE_SECURE = False
    SECURE_SSL_REDIRECT = False
    CSRF_COOKIE_SAMESITE = 'Lax'
    SESSION_COOKIE_SAMESITE = 'Lax'

# Google OAuth settings
GOOGLE_CLIENT_ID = 'YOUR_GOOGLE_CLIENT_ID'