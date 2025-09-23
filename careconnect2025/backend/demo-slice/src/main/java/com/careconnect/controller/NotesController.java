package com.careconnect.controller;

import com.careconnect.dto.NoteDTO;
import com.careconnect.dto.TextBody;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/notes")
public class NotesController {
  private final Map<String, List<NoteDTO>> notesByUser = new ConcurrentHashMap<>();

  @PostMapping
  public ResponseEntity<?> add(@RequestBody TextBody body) {
    if (body == null || body.text() == null || body.text().isBlank())
      return ResponseEntity.badRequest().body(Map.of("error","text required"));

    final String user = "patient"; // demo-only (no auth in this slice)
    final List<NoteDTO> list = notesByUser.computeIfAbsent(user, k -> new ArrayList<>());
    final String id = String.valueOf(list.size() + 1);

    NoteDTO note = new NoteDTO(id, user, body.text(), Instant.now().toString());
    list.add(note);
    return ResponseEntity.status(201).body(note);
  }

  @GetMapping
  public ResponseEntity<List<NoteDTO>> list(@RequestParam(value="q", required=false) String q) {
    final String user = "patient"; // demo-only
    final List<NoteDTO> list = notesByUser.getOrDefault(user, List.of());
    if (q == null || q.isBlank()) return ResponseEntity.ok(list);

    final String needle = q.toLowerCase();
    List<NoteDTO> filtered = list.stream()
      .filter(n -> n.text().toLowerCase().contains(needle))
      .collect(Collectors.toList());
    return ResponseEntity.ok(filtered);
  }
}
