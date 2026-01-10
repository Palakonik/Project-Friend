from rest_framework.authentication import SessionAuthentication


class CsrfExemptSessionAuthentication(SessionAuthentication):
    """
    Session authentication that doesn't enforce CSRF.
    Used for mobile apps that don't support CSRF tokens.
    """
    def enforce_csrf(self, request):
        # Don't enforce CSRF for mobile API requests
        return
