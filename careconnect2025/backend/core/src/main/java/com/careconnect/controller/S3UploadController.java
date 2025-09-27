package com.careconnect.controller;

import com.careconnect.dto.PresignedUrlResponse;
import com.careconnect.service.S3UploadService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/files")
@CrossOrigin(origins = "*") // Allows requests from your web app for easy development
public class S3UploadController {

    private final S3UploadService s3UploadService;

    public S3UploadController(S3UploadService s3UploadService) {
        this.s3UploadService = s3UploadService;
    }

    @GetMapping("/generate-upload-url")
    public ResponseEntity<PresignedUrlResponse> generateUploadUrl(@RequestParam String contentType) {
        try {
            PresignedUrlResponse response = s3UploadService.generatePresignedUrl(contentType);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            // In a real app, you would add proper logging here
            System.err.println("Error generating presigned URL: " + e.getMessage());
            return ResponseEntity.internalServerError().build();
        }
    }
}