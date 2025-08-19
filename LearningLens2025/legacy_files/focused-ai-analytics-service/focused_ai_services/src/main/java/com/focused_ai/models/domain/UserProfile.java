package com.focused_ai.models.domain;

import lombok.Data;

@Data
public class UserProfile {
    private String id;
    private String emailAddress;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getEmailAddress() { return emailAddress; }
    public void setEmailAddress(String emailAddress) { this.emailAddress = emailAddress; }
}