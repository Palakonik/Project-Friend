from django.urls import path
from .views import (
    GoogleLoginView, CurrentUserView, UserSearchView, LogoutView,
    FirebaseLoginView, FirebaseRegisterView
)

urlpatterns = [
    # Firebase Authentication (yeni)
    path('firebase-login/', FirebaseLoginView.as_view(), name='firebase-login'),
    path('firebase-register/', FirebaseRegisterView.as_view(), name='firebase-register'),
    
    # Google Authentication (geriye uyumluluk)
    path('google-login/', GoogleLoginView.as_view(), name='google-login'),
    
    # User operations
    path('me/', CurrentUserView.as_view(), name='current-user'),
    path('search/', UserSearchView.as_view(), name='user-search'),
    path('logout/', LogoutView.as_view(), name='logout'),
]
