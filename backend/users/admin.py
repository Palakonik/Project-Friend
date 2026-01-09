from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser


@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    list_display = ['username', 'email', 'first_name', 'last_name', 'is_admin_user', 'is_active']
    list_filter = ['is_admin_user', 'is_active', 'is_staff']
    search_fields = ['username', 'email', 'first_name', 'last_name']
    
    fieldsets = UserAdmin.fieldsets + (
        ('Özel Alanlar', {'fields': ('google_id', 'profile_photo', 'is_admin_user')}),
    )
    
    add_fieldsets = UserAdmin.add_fieldsets + (
        ('Özel Alanlar', {'fields': ('google_id', 'profile_photo', 'is_admin_user')}),
    )
