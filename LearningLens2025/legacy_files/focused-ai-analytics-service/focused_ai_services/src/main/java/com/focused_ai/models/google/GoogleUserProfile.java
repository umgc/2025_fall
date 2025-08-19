package com.focused_ai.models.google;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class GoogleUserProfile {
    private String id;
    private String emailAddress;

    public String getId() { return id; }
    public String getEmailAddress() { return emailAddress; }

    public void setId(String id) { this.id = id; }
    public void setEmailAddress(String emailAddress) { this.emailAddress = emailAddress; }
}