package com.careconnect.auth.api;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/me")
public class DemoProtectedController {

  @GetMapping
  public Map<String,String> me(){ return Map.of("ok","you are authenticated"); }

  @GetMapping("/admin")
  @PreAuthorize("hasAuthority('global_admin')")
  public Map<String,String> admin(){ return Map.of("ok","admin area"); }
}
