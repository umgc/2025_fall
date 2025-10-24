package com.careconnect.auth.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import java.security.Key;
import java.time.Instant;
import java.util.*;

public class JwtUtil {
  private final Key key;
  public JwtUtil(String secret){ this.key = Keys.hmacShaKeyFor(secret.getBytes()); }

  public String createAccessToken(String subject, List<String> roles, long ttlSeconds){
    Instant now = Instant.now();
    return Jwts.builder()
      .subject(subject)
      .issuedAt(Date.from(now))
      .expiration(Date.from(now.plusSeconds(ttlSeconds)))
      .claim("roles", roles)
      .signWith(key, Jwts.SIG.HS256).compact();
  }

  public Jws<Claims> parse(String token){
    return Jwts.parser().verifyWith(key).build().parseSignedClaims(token);
  }
}
