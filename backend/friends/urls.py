from django.urls import path
from .views import (
    SendFriendRequestView, MyFriendsView,
    PendingRequestsView, ApproveRequestView, RejectRequestView,
    BlockUserView, UnblockUserView, BlockedUsersListView
)

urlpatterns = [
    # Arkadaşlık
    path('send-request/', SendFriendRequestView.as_view(), name='send-friend-request'),
    path('my-friends/', MyFriendsView.as_view(), name='my-friends'),
    
    # Admin endpoints
    path('admin/pending/', PendingRequestsView.as_view(), name='pending-requests'),
    path('admin/approve/<int:pk>/', ApproveRequestView.as_view(), name='approve-request'),
    path('admin/reject/<int:pk>/', RejectRequestView.as_view(), name='reject-request'),
    
    # Engelleme
    path('block/', BlockUserView.as_view(), name='block-user'),
    path('unblock/<int:pk>/', UnblockUserView.as_view(), name='unblock-user'),
    path('blocked/', BlockedUsersListView.as_view(), name='blocked-users'),
]
