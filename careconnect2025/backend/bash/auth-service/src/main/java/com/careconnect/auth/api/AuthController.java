package com.careconnect.auth.api;

import com.careconnect.auth.core.AuthService;
import com.careconnect.auth.model.AuthDtos.*;
import com.careconnect.auth.security.JwtUtil;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController @RequestMapping("/auth")
public class AuthController {
  private final AuthService auth;
  private final JwtUtil jwt = new JwtUtil(Optional.ofNullable(System.getenv("JWT_SECRET"))
    .orElse("demo-secret-should-be-32+chars-demo-secret-123"));

  public AuthController(AuthService auth){ this.auth = auth; }

  @GetMapping("/health") public Map<String,String> health(){ return Map.of("status","UP"); }

  @PostMapping("/register")
  public ResponseEntity<?> register(@RequestBody Register r){
    auth.register(r.email, r.password, List.of("patient")); // default role
    return ResponseEntity.status(HttpStatus.CREATED).build();
  }

  @PostMapping("/login")
  public ResponseEntity<Tokens> login(@RequestBody Login l){
    if (!auth.verify(l.email, l.password)) return ResponseEntity.status(401).build();
    var roles = auth.roles(l.email);
    String access = jwt.createAccessToken(l.email, roles, 15*60); // 15m
    String refreshId = auth.newRefresh(l.email);                 // 7d cookie
    ResponseCookie cookie = ResponseCookie.from("refreshId", refreshId)
      .httpOnly(true).secure(false).path("/auth").maxAge(Duration.ofDays(7)).sameSite("Lax").build();
    return ResponseEntity.ok().header(HttpHeaders.SET_COOKIE, cookie.toString())
      .body(tokens(access, refreshId));
  }

  @PostMapping("/refresh")
  public ResponseEntity<Tokens> refresh(@CookieValue(value="refreshId", required=false) String cookieId,
                                        @RequestHeader(value="X-Refresh-Id", required=false) String headerId){
    String id = cookieId != null ? cookieId : headerId;
    if (id == null) return ResponseEntity.status(401).build();
    var email = auth.emailForRefresh(id).orElse(null);
    if (email == null) return ResponseEntity.status(401).build();
    var roles = auth.roles(email);
    String access = jwt.createAccessToken(email, roles, 15*60);
    String newId = auth.rotateRefresh(id);
    ResponseCookie cookie = ResponseCookie.from("refreshId", newId)
      .httpOnly(true).secure(false).path("/auth").maxAge(Duration.ofDays(7)).sameSite("Lax").build();
    return ResponseEntity.ok().header(HttpHeaders.SET_COOKIE, cookie.toString())
      .body(tokens(access, newId));
  }

  @PostMapping("/logout")
  public ResponseEntity<?> logout(@CookieValue(value="refreshId", required=false) String cookieId,
                                  @RequestHeader(value="X-Refresh-Id", required=false) String headerId){
    String id = cookieId != null ? cookieId : headerId;
    if (id != null) auth.revokeRefresh(id);
    ResponseCookie cookie = ResponseCookie.from("refreshId","").path("/auth").maxAge(0).build();
    return ResponseEntity.ok().header(HttpHeaders.SET_COOKIE, cookie.toString()).build();
  }

  private Tokens tokens(String access, String refresh){ var t = new Tokens(); t.accessToken=access; t.refreshToken=refresh; return t; }
}
