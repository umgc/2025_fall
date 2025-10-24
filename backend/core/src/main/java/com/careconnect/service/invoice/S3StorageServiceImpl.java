package com.careconnect.service.invoice;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.ObjectCannedACL;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

@Service
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "careconnect.aws.enabled", havingValue = "true", matchIfMissing = true)
public class S3StorageServiceImpl implements S3StorageService {

    private final S3Client s3Client;

    @Value("${aws.s3.bucket-name}")
    private String bucket;

    @Override
    public void upload(byte[] data, String key) {
        upload(data, key, null);
    }

    @Override
    public void upload(byte[] data, String key, String contentType) {
        PutObjectRequest.Builder put = PutObjectRequest.builder()
                .bucket(bucket)
                .key(key)
                .acl(ObjectCannedACL.BUCKET_OWNER_FULL_CONTROL);

        if (contentType != null && !contentType.isBlank()) {
            put.contentType(contentType);
        }

        s3Client.putObject(put.build(), RequestBody.fromBytes(data));
        log.info("Uploaded to s3://{}/{}", bucket, key);
    }
}
