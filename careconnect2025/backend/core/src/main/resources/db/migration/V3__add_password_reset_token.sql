-- CREATE TABLE password_reset_token (
--     id BIGSERIAL PRIMARY KEY,
--     user_id BIGINT NOT NULL,
--     token_hash VARCHAR(255) NOT NULL UNIQUE,
--     expires_at TIMESTAMP NOT NULL,
--     used BOOLEAN DEFAULT FALSE,
--     created_at TIMESTAMP DEFAULT NOW(),
--     CONSTRAINT fk_password_reset_token_user
--       FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
-- );
-- 
CREATE INDEX IF NOT EXISTS idx_password_reset_token_hash ON password_reset_token(token_hash);
CREATE INDEX IF NOT EXISTS idx_password_reset_token_expires ON password_reset_token(expires_at);

-- Drop Spring Session tables if they exist (PostgreSQL)
DROP TABLE IF EXISTS spring_session_attributes;
DROP TABLE IF EXISTS spring_session;
