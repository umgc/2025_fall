package com.careconnect.model;

import lombok.*;
import java.time.OffsetDateTime;

@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class PackageItem {
    private String trackingNumber;
    private OffsetDateTime expectedDeliveryDate;  // null if unknown
    private ActionLinks actionLinks;
}
