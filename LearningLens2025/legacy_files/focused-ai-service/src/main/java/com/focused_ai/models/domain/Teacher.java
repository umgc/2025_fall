package com.focused_ai.models.domain;

import lombok.Data;

@Data
public class Teacher {
    private String userId;

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
}