package com.careconnect.asl.api;

import com.careconnect.asl.core.AslTranslator;
import com.careconnect.asl.model.AslRequest;
import com.careconnect.asl.model.AslResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/v1/asl")
public class AslController {
  private final AslTranslator translator;
  public AslController(AslTranslator translator){ this.translator = translator; }

  @PostMapping("/translate")
  public ResponseEntity<AslResponse> translate(@RequestBody AslRequest req){
    return ResponseEntity.ok(translator.translate(req));
  }

  @GetMapping("/health")
  public Map<String,String> health(){ return Map.of("status","UP"); }
}
