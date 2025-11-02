CREATE TABLE IF NOT EXISTS email_credentials (
                                                 id BIGINT PRIMARY KEY AUTO_INCREMENT,
                                                 user_id VARCHAR(191) NOT NULL,
                                                 provider VARCHAR(20) NOT NULL,
                                                 access_token_enc LONGBLOB,
                                                 refresh_token_enc LONGBLOB,
                                                 expires_at TIMESTAMP NULL,
                                                 INDEX idx_email_cred (user_id, provider)
);

CREATE TABLE IF NOT EXISTS usps_digest_cache (
                                                 id BIGINT PRIMARY KEY AUTO_INCREMENT,
                                                 user_id VARCHAR(191) NOT NULL,
                                                 payload_json LONGTEXT NOT NULL,
                                                 digest_date TIMESTAMP NULL,
                                                 expires_at TIMESTAMP NOT NULL,
                                                 INDEX idx_usps_cache (user_id, expires_at)
);
