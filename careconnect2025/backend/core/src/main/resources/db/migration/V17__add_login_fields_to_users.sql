-- Add login tracking fields to users table
SET @schema = DATABASE();
-- last_login_date 
SET @cnt = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME='users' AND COLUMN_NAME='last_login_date');
SET @s = IF(@cnt=0, 'ALTER TABLE users ADD COLUMN last_login_date DATE', 'SELECT 1');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- login_streak
SET @cnt = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME='users' AND COLUMN_NAME='login_streak');
SET @s = IF(@cnt=0, 'ALTER TABLE users ADD COLUMN login_streak INTEGER NOT NULL DEFAULT 0', 'SELECT 1');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- leaderboard_opt_in
SET @cnt = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @schema AND TABLE_NAME='users' AND COLUMN_NAME='leaderboard_opt_in');
SET @s = IF(@cnt=0, 'ALTER TABLE users ADD COLUMN leaderboard_opt_in BOOLEAN NOT NULL DEFAULT TRUE', 'SELECT 1');
PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;