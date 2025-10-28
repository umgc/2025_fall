package com.careconnect.model;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "email_credentials")
public class EmailCredential {
    public enum Provider { GMAIL, OUTLOOK }

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false) private String userId;
    @Enumerated(EnumType.STRING) @Column(nullable = false)
    private Provider provider;

    @Lob private String accessTokenEnc;
    @Lob private String refreshTokenEnc;
    private Instant expiresAt;

    // getters/setters
    public Long getId() { return id; }
    public String getUserId() { return userId; }
    public void setUserId(String u) { userId = u; }
    public Provider getProvider() { return provider; }
    public void setProvider(Provider p) { provider = p; }
    public String getAccessTokenEnc() { return accessTokenEnc; }
    public void setAccessTokenEnc(String s) { accessTokenEnc = s; }
    public String getRefreshTokenEnc() { return refreshTokenEnc; }
    public void setRefreshTokenEnc(String s) { refreshTokenEnc = s; }
    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant t) { expiresAt = t; }
}
