package com.careconnect.model;

import lombok.*;
import java.time.OffsetDateTime;
import java.util.List;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class UspsDigest {
    private OffsetDateTime digestDate;
    private List<MailPiece> mailPieces;
    private List<PackageItem> packages;
}
