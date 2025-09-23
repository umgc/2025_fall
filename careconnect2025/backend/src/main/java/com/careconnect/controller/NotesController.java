package com.careconnect.controller;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/notes")
public class NotesController {

  @GetMapping
  @PreAuthorize("hasAnyRole('PATIENT','CAREGIVER','ADMIN')")
  public List<Map<String,Object>> list(){
    return List.of(Map.of("id",1,"text","Example note (protected)"));
  }
}
