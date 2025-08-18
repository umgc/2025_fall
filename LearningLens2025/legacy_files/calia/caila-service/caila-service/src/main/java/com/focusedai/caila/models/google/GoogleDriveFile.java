package com.focusedai.caila.models.google;

import lombok.Data;
import lombok.Builder;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GoogleDriveFile {
    private String id;
    private String name;
    private String mimeType;
    private String webViewLink;
    private String webContentLink;
    private LocalDateTime createdTime;
    private LocalDateTime modifiedTime;
}