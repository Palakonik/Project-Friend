from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Q

from .models import FriendRequest, BlockedUser, Friendship
from .serializers import (
    FriendRequestSerializer, FriendRequestCreateSerializer,
    FriendRequestAdminSerializer, BlockedUserSerializer, FriendshipSerializer
)
from users.models import CustomUser


class IsAdminUser(permissions.BasePermission):
    """Admin kullanıcı kontrolü"""
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.is_admin_user


# ============== Arkadaşlık İsteği Views ==============

class SendFriendRequestView(APIView):
    """Arkadaşlık isteği gönderme"""
    
    def post(self, request):
        receiver_id = request.data.get('receiver_id')
        note = request.data.get('note', '')
        
        # Alıcı kontrol
        try:
            receiver = CustomUser.objects.get(id=receiver_id)
        except CustomUser.DoesNotExist:
            return Response(
                {'error': 'Kullanıcı bulunamadı'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Kendine istek gönderemez
        if receiver == request.user:
            return Response(
                {'error': 'Kendinize arkadaşlık isteği gönderemezsiniz'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Engelleme kontrolü
        if BlockedUser.objects.filter(
            Q(blocker=request.user, blocked=receiver) |
            Q(blocker=receiver, blocked=request.user)
        ).exists():
            return Response(
                {'error': 'Bu kullanıcıyla işlem yapılamaz'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Zaten arkadaş mı kontrolü
        if Friendship.objects.filter(
            Q(user1=request.user, user2=receiver) |
            Q(user1=receiver, user2=request.user)
        ).exists():
            return Response(
                {'error': 'Bu kullanıcı zaten arkadaşınız'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Mevcut bekleyen istek kontrolü
        existing = FriendRequest.objects.filter(
            sender=request.user, 
            receiver=receiver,
            status='pending'
        ).first()
        
        if existing:
            return Response(
                {'error': 'Bu kullanıcıya zaten bekleyen bir isteğiniz var'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # İstek oluştur
        friend_request = FriendRequest.objects.create(
            sender=request.user,
            receiver=receiver,
            note=note
        )
        
        return Response({
            'message': 'Arkadaşlık isteği gönderildi. Admin onayına sunuldu.',
            'request': FriendRequestSerializer(friend_request).data
        }, status=status.HTTP_201_CREATED)


class MyFriendsView(generics.ListAPIView):
    """Onaylanmış arkadaş listesi"""
    serializer_class = FriendshipSerializer
    
    def get_queryset(self):
        return Friendship.objects.filter(
            Q(user1=self.request.user) | Q(user2=self.request.user)
        )


# ============== Admin Views ==============

class PendingRequestsView(generics.ListAPIView):
    """Admin için bekleyen arkadaşlık istekleri"""
    serializer_class = FriendRequestAdminSerializer
    permission_classes = [IsAdminUser]
    
    def get_queryset(self):
        return FriendRequest.objects.filter(status='pending')


class ApproveRequestView(APIView):
    """Arkadaşlık isteğini onayla"""
    permission_classes = [IsAdminUser]
    
    def post(self, request, pk):
        try:
            friend_request = FriendRequest.objects.get(id=pk, status='pending')
        except FriendRequest.DoesNotExist:
            return Response(
                {'error': 'İstek bulunamadı'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # İsteği onayla
        friend_request.status = 'approved'
        friend_request.save()
        
        # Arkadaşlık oluştur
        Friendship.objects.get_or_create(
            user1=friend_request.sender,
            user2=friend_request.receiver
        )
        
        return Response({
            'message': 'Arkadaşlık isteği onaylandı',
            'request': FriendRequestAdminSerializer(friend_request).data
        })


class RejectRequestView(APIView):
    """Arkadaşlık isteğini reddet"""
    permission_classes = [IsAdminUser]
    
    def post(self, request, pk):
        try:
            friend_request = FriendRequest.objects.get(id=pk, status='pending')
        except FriendRequest.DoesNotExist:
            return Response(
                {'error': 'İstek bulunamadı'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        friend_request.status = 'rejected'
        friend_request.save()
        
        return Response({
            'message': 'Arkadaşlık isteği reddedildi',
            'request': FriendRequestAdminSerializer(friend_request).data
        })


# ============== Engelleme Views ==============

class BlockUserView(APIView):
    """Kullanıcı engelle"""
    
    def post(self, request):
        blocked_id = request.data.get('user_id')
        
        try:
            blocked_user = CustomUser.objects.get(id=blocked_id)
        except CustomUser.DoesNotExist:
            return Response(
                {'error': 'Kullanıcı bulunamadı'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        if blocked_user == request.user:
            return Response(
                {'error': 'Kendinizi engelleyemezsiniz'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Arkadaşlık varsa sil
        Friendship.objects.filter(
            Q(user1=request.user, user2=blocked_user) |
            Q(user1=blocked_user, user2=request.user)
        ).delete()
        
        # Engelle
        blocked, created = BlockedUser.objects.get_or_create(
            blocker=request.user,
            blocked=blocked_user
        )
        
        if not created:
            return Response(
                {'error': 'Bu kullanıcı zaten engellenmiş'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        return Response({
            'message': 'Kullanıcı engellendi',
            'blocked_user': BlockedUserSerializer(blocked).data
        }, status=status.HTTP_201_CREATED)


class UnblockUserView(APIView):
    """Engeli kaldır"""
    
    def post(self, request, pk):
        try:
            blocked = BlockedUser.objects.get(id=pk, blocker=request.user)
        except BlockedUser.DoesNotExist:
            return Response(
                {'error': 'Engelleme bulunamadı'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        blocked.delete()
        return Response({'message': 'Engel kaldırıldı'})


class BlockedUsersListView(generics.ListAPIView):
    """Engellenmiş kullanıcılar listesi"""
    serializer_class = BlockedUserSerializer
    
    def get_queryset(self):
        return BlockedUser.objects.filter(blocker=self.request.user)
