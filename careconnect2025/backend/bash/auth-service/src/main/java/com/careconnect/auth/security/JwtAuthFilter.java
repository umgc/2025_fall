package com.careconnect.auth.security;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import java.io.IOException;
import java.util.*;

@Component
public class JwtAuthFilter extends GenericFilter {

  private final JwtUtil jwt;
  public JwtAuthFilter() {
    // DEMO SECRET ONLY: set from env in real usage
    this.jwt = new JwtUtil(Optional.ofNullable(System.getenv("JWT_SECRET"))
      .orElse("demo-secret-should-be-32+chars-demo-secret-123"));
  }

  @Override
  public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
      throws IOException, ServletException {
    HttpServletRequest r = (HttpServletRequest) req;
    String h = r.getHeader("Authorization");
    if (h != null && h.startsWith("Bearer ")) {
      String token = h.substring(7);
      try {
        var claims = jwt.parse(token).getPayload();
        String sub = claims.getSubject();
        @SuppressWarnings("unchecked")
        List<String> roles = (List<String>) claims.get("roles");
        var auth = new UsernamePasswordAuthenticationToken(
          sub, null, roles.stream().map(SimpleGrantedAuthority::new).toList());
        SecurityContextHolder.getContext().setAuthentication(auth);
      } catch (Exception ignored) { /* invalid token -> proceed unauthenticated */ }
    }
    chain.doFilter(req, res);
  }
}
