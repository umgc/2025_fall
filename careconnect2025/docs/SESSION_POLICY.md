# Session Policy
Tokens: access ~15 minutes; refresh 7–14 days; rotate on refresh.
Storage: device secure storage (Flutter Secure Storage). Never log tokens.
Force re-auth: on role change or refresh failure. Logout revokes refresh token.
