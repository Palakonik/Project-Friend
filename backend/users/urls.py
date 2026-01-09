from django.urls import path
from .views import GoogleLoginView, CurrentUserView, UserSearchView, LogoutView

urlpatterns = [
    path('google-login/', GoogleLoginView.as_view(), name='google-login'),
    path('me/', CurrentUserView.as_view(), name='current-user'),
    path('search/', UserSearchView.as_view(), name='user-search'),
    path('logout/', LogoutView.as_view(), name='logout'),
]
