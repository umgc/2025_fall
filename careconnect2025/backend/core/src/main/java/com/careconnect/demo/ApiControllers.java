package com.careconnect.demo;

import com.careconnect.demo.dto.*;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@RestController
public class ApiControllers {

  private final Map<String, List<Note>> notesByUser = new ConcurrentHashMap<>();

  @GetMapping("/health")
  public Map<String,String> health() { return Map.of("status","ok"); }

  @GetMapping("/auth/me")
  public UserInfo me(Authentication auth) {
    String[] roles = auth.getAuthorities().stream()
      .map(a -> a.getAuthority().replace("ROLE_",""))
      .toArray(String[]::new);
    return new UserInfo(auth.getName(), roles);
  }

  @PostMapping("/notes")
  public ResponseEntity<?> addNote(@RequestBody TextBody body, Authentication auth) {
    if (body == null || body.text() == null || body.text().isBlank())
      return ResponseEntity.badRequest().body(Map.of("error","text required"));
    var user = auth.getName();
    var list = notesByUser.computeIfAbsent(user, k -> new ArrayList<>());
    var id = String.valueOf(list.size() + 1);
    var note = new Note(id, user, body.text(), Instant.now().toString());
    list.add(note);
    return ResponseEntity.status(201).body(note);
  }

  @GetMapping("/notes")
  public List<Note> listNotes(@RequestParam(value="q", required=false) String q, Authentication auth) {
    var user = auth.getName();
    var list = notesByUser.getOrDefault(user, List.of());
    if (q == null || q.isBlank()) return list;
    var needle = q.toLowerCase();
    return list.stream().filter(n -> n.text().toLowerCase().contains(needle)).collect(Collectors.toList());
  }

  @PostMapping("/triggers/propose")
  public ResponseEntity<?> propose(@RequestBody TextBody body, Authentication auth) {
    if (body == null || body.text() == null || body.text().isBlank())
      return ResponseEntity.badRequest().body(Map.of("error","text required"));
    boolean match = body.text().toLowerCase().matches(".*(follow[- ]?up|appointment|schedule).*");
    String title = match ? "Follow-up from notes" : "Proposed item";
    var p = new TriggerProposal("calendar_proposal","AI-derived", title, true,
      Instant.now().toString(), body.text(), auth.getName());
    return ResponseEntity.ok(p);
  }

  @PostMapping("/pii/sanitize")
  public ResponseEntity<?> sanitize(@RequestBody TextBody body) {
    if (body == null || body.text() == null)
      return ResponseEntity.badRequest().body(Map.of("error","text required"));
    String s = body.text();
    String sanitized = s
      .replaceAll("(?i)[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", "[email]")
      .replaceAll("(?:\\+?1[-.\\s]?)?\\(?\\d{3}\\)?[-.\\s]?\\d{3}[-.\\s]?\\d{4}\\b", "[phone]")
      .replaceAll("\\b\\d{3}-\\d{2}-\\d{4}\\b", "[ssn]");
    return ResponseEntity.ok(Map.of("original", s, "sanitized", sanitized));
  }
}
