-- Add missing columns to users table to match the User model
SET @schema = DATABASE();

-- name
SET @cnt = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME='users' AND COLUMN_NAME='name');
SET @s = IF(@cnt=0, 'ALTER TABLE users ADD COLUMN name VARCHAR(100)', 'SELECT 1');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- verification_token
SET @cnt = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME='users' AND COLUMN_NAME='verification_token');
SET @s = IF(@cnt=0, 'ALTER TABLE users ADD COLUMN verification_token VARCHAR(255)', 'SELECT 1');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- stripe_customer_id
SET @cnt = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME='users' AND COLUMN_NAME='stripe_customer_id');
SET @s = IF(@cnt=0, 'ALTER TABLE users ADD COLUMN stripe_customer_id VARCHAR(255)', 'SELECT 1');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- last_login (allow NULL)
SET @cnt = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME='users' AND COLUMN_NAME='last_login');
SET @s = IF(@cnt=0, 'ALTER TABLE users ADD COLUMN last_login TIMESTAMP NULL', 'SELECT 1');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- profile_image_url
SET @cnt = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME='users' AND COLUMN_NAME='profile_image_url');
SET @s = IF(@cnt=0, 'ALTER TABLE users ADD COLUMN profile_image_url VARCHAR(255)', 'SELECT 1');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;