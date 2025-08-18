package com.focused_ai.models.moodle;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class MoodleCourse {
    private long id;
    private String fullname;

    public Long getId() { return id; }
    public String getFullname() { return fullname; }

    public void setId(Long id) { this.id = id; }
    public void setFullname(String fullname) { this.fullname = fullname; }
}