package com.careconnect.asl.core;

import com.careconnect.asl.model.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.InputStream;
import java.util.*;
import java.util.stream.Collectors;

public class AslTranslator {

  private final Map<String,String> dict;

  public AslTranslator() {
    this.dict = loadDictionary();
  }

  public AslResponse translate(AslRequest req){
    String text = Optional.ofNullable(req.getText()).orElse("").toLowerCase(Locale.ROOT);
    String[] tokens = text.replaceAll("[^a-z0-9\\s:]", " ").split("\\s+");

    List<AslFrame> frames = new ArrayList<>();
    for (String tk : tokens) {
      if (tk.isBlank()) continue;
      String key = tk;
      // normalize common time tokens like "3pm"
      key = key.replaceAll("(?i)pm$", "pm").replaceAll("(?i)am$", "am");
      if (dict.containsKey(key)) {
        String file = dict.get(key);
        frames.add(new AslFrame("sign", key.toUpperCase(Locale.ROOT),
          "asset://asl/phrases/" + file));
      }
    }
    boolean ok = !frames.isEmpty();
    String caption = frames.stream().map(AslFrame::getId).collect(Collectors.joining(" ")).toLowerCase(Locale.ROOT);
    if (ok) return new AslResponse(true, "video", frames, caption);
    return new AslResponse(false, "fingerspell", Collections.emptyList(), "");
  }

  private Map<String,String> loadDictionary() {
    try {
      ObjectMapper om = new ObjectMapper();
      InputStream in = getClass().getClassLoader().getResourceAsStream("asl-dictionary.json");
      if (in == null) return Map.of();
      @SuppressWarnings("unchecked")
      Map<String,String> m = om.readValue(in, Map.class);
      return m;
    } catch (Exception e) {
      return Map.of();
    }
  }
}
