package com.careconnect.model;

import java.time.OffsetDateTime;
import java.util.List;

public record UspsDigest(
        OffsetDateTime digestDate,
        List<MailPiece> mailpieces,
        List<PackageItem> packages
) {}
