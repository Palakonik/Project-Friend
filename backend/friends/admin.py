from django.contrib import admin
from .models import FriendRequest, BlockedUser, Friendship


@admin.register(FriendRequest)
class FriendRequestAdmin(admin.ModelAdmin):
    list_display = ['sender', 'receiver', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['sender__username', 'sender__first_name', 'receiver__username', 'receiver__first_name']
    readonly_fields = ['created_at', 'updated_at']
    
    actions = ['approve_requests', 'reject_requests']
    
    def approve_requests(self, request, queryset):
        for obj in queryset.filter(status='pending'):
            obj.status = 'approved'
            obj.save()
            Friendship.objects.get_or_create(user1=obj.sender, user2=obj.receiver)
        self.message_user(request, f"{queryset.count()} istek onaylandı.")
    approve_requests.short_description = "Seçili istekleri onayla"
    
    def reject_requests(self, request, queryset):
        queryset.filter(status='pending').update(status='rejected')
        self.message_user(request, f"{queryset.count()} istek reddedildi.")
    reject_requests.short_description = "Seçili istekleri reddet"


@admin.register(BlockedUser)
class BlockedUserAdmin(admin.ModelAdmin):
    list_display = ['blocker', 'blocked', 'created_at']
    search_fields = ['blocker__username', 'blocked__username']
    readonly_fields = ['created_at']


@admin.register(Friendship)
class FriendshipAdmin(admin.ModelAdmin):
    list_display = ['user1', 'user2', 'created_at']
    search_fields = ['user1__username', 'user2__username']
    readonly_fields = ['created_at']
