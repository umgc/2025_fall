package com.careconnect.controller;

import com.careconnect.controller.dto.NoteDTO;
import com.careconnect.controller.dto.TextBody;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/notes")
public class NotesController {

  // Simple in-memory store per user (demo scope)
  private final Map<String, List<NoteDTO>> notesByUser = new ConcurrentHashMap<>();

  @PostMapping
  public ResponseEntity<?> add(@RequestBody TextBody body, Authentication auth) {
    if (body == null || body.text() == null || body.text().isBlank())
      return ResponseEntity.badRequest().body(Map.of("error","text required"));

    final String user = auth.getName();
    final List<NoteDTO> list = notesByUser.computeIfAbsent(user, k -> new ArrayList<>());
    final String id = String.valueOf(list.size() + 1);

    NoteDTO note = new NoteDTO(id, user, body.text(), Instant.now().toString());
    list.add(note);
    return ResponseEntity.status(201).body(note);
  }

  @GetMapping
  public ResponseEntity<List<NoteDTO>> list(@RequestParam(value="q", required=false) String q,
                                            Authentication auth) {
    final String user = auth.getName();
    final List<NoteDTO> list = notesByUser.getOrDefault(user, List.of());
    if (q == null || q.isBlank()) return ResponseEntity.ok(list);

    final String needle = q.toLowerCase();
    List<NoteDTO> filtered = list.stream()
      .filter(n -> n.text().toLowerCase().contains(needle))
      .collect(Collectors.toList());
    return ResponseEntity.ok(filtered);
  }
}
