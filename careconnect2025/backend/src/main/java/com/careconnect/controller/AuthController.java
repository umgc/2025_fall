package com.careconnect.controller;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/auth")
public class AuthController {

  @PostMapping("/register")
  public Map<String,Object> register(@RequestBody Map<String,String> body){
    // demo: pretend success
    return Map.of("ok", true, "email", body.getOrDefault("email","demo@x.com"));
  }

  @PostMapping("/login")
  public Map<String,Object> login(){
    // demo: HTTP Basic is used; return hint to try /auth/me
    return Map.of("ok", true, "hint", "Use Basic Auth (patient:pass) then GET /auth/me");
  }

  @GetMapping("/me")
  public Map<String,Object> me(Authentication auth){
    return Map.of("user", auth.getName(), "authorities", auth.getAuthorities());
  }
}
