from rest_framework import serializers
from .models import FriendRequest, BlockedUser, Friendship
from users.serializers import UserSerializer, UserSearchSerializer


class FriendRequestSerializer(serializers.ModelSerializer):
    """Arkadaşlık isteği serializer"""
    sender = UserSearchSerializer(read_only=True)
    receiver = UserSearchSerializer(read_only=True)
    receiver_id = serializers.IntegerField(write_only=True)
    status_display = serializers.SerializerMethodField()
    
    class Meta:
        model = FriendRequest
        fields = ['id', 'sender', 'receiver', 'receiver_id', 'note', 
                  'status', 'status_display', 'created_at']
        read_only_fields = ['id', 'sender', 'status', 'created_at']
    
    def get_status_display(self, obj):
        return obj.get_status_display()


class FriendRequestCreateSerializer(serializers.ModelSerializer):
    """Arkadaşlık isteği oluşturma için"""
    receiver_id = serializers.IntegerField()
    
    class Meta:
        model = FriendRequest
        fields = ['receiver_id', 'note']


class FriendRequestAdminSerializer(serializers.ModelSerializer):
    """Admin panel için arkadaşlık isteği serializer"""
    sender = UserSearchSerializer(read_only=True)
    receiver = UserSearchSerializer(read_only=True)
    
    class Meta:
        model = FriendRequest
        fields = ['id', 'sender', 'receiver', 'note', 'status', 'created_at']
        read_only_fields = ['id', 'sender', 'receiver', 'note', 'created_at']


class BlockedUserSerializer(serializers.ModelSerializer):
    """Engellenen kullanıcı serializer"""
    blocked = UserSearchSerializer(read_only=True)
    blocked_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = BlockedUser
        fields = ['id', 'blocked', 'blocked_id', 'created_at']
        read_only_fields = ['id', 'blocked', 'created_at']


class FriendshipSerializer(serializers.ModelSerializer):
    """Arkadaşlık serializer"""
    friend = serializers.SerializerMethodField()
    
    class Meta:
        model = Friendship
        fields = ['id', 'friend', 'created_at']
    
    def get_friend(self, obj):
        request = self.context.get('request')
        if request and request.user:
            # Karşı tarafın bilgisini döndür
            if obj.user1 == request.user:
                return UserSearchSerializer(obj.user2).data
            return UserSearchSerializer(obj.user1).data
        return None
