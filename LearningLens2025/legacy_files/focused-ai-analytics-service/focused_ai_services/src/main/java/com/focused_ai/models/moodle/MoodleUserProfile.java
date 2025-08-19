package com.focused_ai.models.moodle;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class MoodleUserProfile {
    private String id;
    private String username;

    public String getId() { return id; }
    public String getUsername() { return username; }

    public void setId(String id) { this.id = id; }
    public void setUsername(String username) { this.username = username; }
}