package com.careconnect.service;

import com.careconnect.dto.PresignedUrlResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedPutObjectRequest;

import java.time.Duration;
import java.util.UUID;

@Service
public class S3UploadService {

    private final S3Presigner s3Presigner;
    private final String bucketName;

    // This constructor injects the S3Presigner bean and the new bucket name from your properties
    public S3UploadService(S3Presigner s3Presigner, @Value("${aws.s3.ocr-upload-bucket}") String bucketName) {
        this.s3Presigner = s3Presigner;
        this.bucketName = bucketName;
    }

    public PresignedUrlResponse generatePresignedUrl(String contentType) {
        // Generate a unique filename (key) for the S3 object
        String key = "uploads/" + UUID.randomUUID().toString();

        PutObjectRequest objectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .contentType(contentType)
                .build();

        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .signatureDuration(Duration.ofMinutes(10)) // The URL will be valid for 10 minutes
                .putObjectRequest(objectRequest)
                .build();

        PresignedPutObjectRequest presignedRequest = s3Presigner.presignPutObject(presignRequest);
        String url = presignedRequest.url().toString();

        return new PresignedUrlResponse(url, key);
    }
}