package com.focused_ai.models.google;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class GoogleCourse {
    private String id;
    private String name;

    // Getters
    public String getId() { return id; }
    public String getName() { return name; }

    // Setters
    public void setId(String id) { this.id = id; }
    public void setName(String name) { this.name = name; }
}