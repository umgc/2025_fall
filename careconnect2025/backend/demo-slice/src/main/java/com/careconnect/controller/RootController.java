package com.careconnect.controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;
@RestController
public class RootController {
  @GetMapping("/") public Map<String,Object> root() {
    return Map.of("status","ok","endpoints", new String[]{"/health","/notes","/triggers/propose"});
  }
}
