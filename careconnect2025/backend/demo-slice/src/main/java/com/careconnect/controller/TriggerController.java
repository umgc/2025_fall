package com.careconnect.controller;

import com.careconnect.dto.TextBody;
import com.careconnect.dto.TriggerProposalDTO;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/triggers")
public class TriggerController {

  @PostMapping("/propose")
  public ResponseEntity<?> propose(@RequestBody TextBody body) {
    if (body == null || body.text() == null || body.text().isBlank())
      return ResponseEntity.badRequest().body(Map.of("error","text required"));

    boolean match = body.text().toLowerCase().matches(".*(follow[- ]?up|appointment|schedule).*");
    String title = match ? "Follow-up from notes" : "Proposed item";

    TriggerProposalDTO proposal = new TriggerProposalDTO(
      "calendar_proposal", "AI-derived", title, true,
      Instant.now().toString(), body.text(), "patient" // demo-only
    );
    return ResponseEntity.ok(proposal);
  }
}
