package com.careconnect.model;

import lombok.*;
import java.time.OffsetDateTime;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class MailPiece {
    private String id;
    private String sender;
    private String subject;
    private String thumbnailUrl;        // data: URL or https link
    private OffsetDateTime receivedAt;  // when the digest says it’s from
    private ActionLinks actionLinks;
}
