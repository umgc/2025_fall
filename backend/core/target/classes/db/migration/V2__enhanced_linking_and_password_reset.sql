-- V2: Consolidated migration for password reset, enhanced linking, and cleanup
-- This migration includes:
-- 1. Password reset token functionality
-- 2. Enhanced family member and caregiver-patient linking
-- 3. Removal of direct caregiver-patient relationship

-- =====================================================
-- 1. PASSWORD RESET TOKEN TABLE
-- =====================================================
-- Add password_reset_token table for secure password reset functionality
CREATE TABLE IF NOT EXISTS password_reset_token
(
    id
    BIGSERIAL
    PRIMARY
    KEY,
    user_id
    BIGINT
    NOT
    NULL,
    token_hash
    CHAR
(
    64
) NOT NULL, -- SHA-256 of random string
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY
(
    user_id
) REFERENCES users
(
    id
) ON DELETE CASCADE
    );

CREATE INDEX IF NOT EXISTS idx_password_reset_token ON password_reset_token(token_hash);

-- =====================================================
-- 2. ENHANCED FAMILY MEMBER LINKING
-- =====================================================
-- Add enhanced family member link functionality
-- Add missing columns to the existing family_member_link table if they don't exist

DO
$$
BEGIN
    -- Add status column if it doesn't exist
    IF
NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = current_schema() 
        AND table_name = 'family_member_link' 
        AND column_name = 'status'
    ) THEN
ALTER TABLE family_member_link
    ADD COLUMN status VARCHAR(20) DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'SUSPENDED', 'REVOKED', 'EXPIRED'));
END IF;

    -- Add link_type column if it doesn't exist
    IF
NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = current_schema() 
        AND table_name = 'family_member_link' 
        AND column_name = 'link_type'
    ) THEN
ALTER TABLE family_member_link
    ADD COLUMN link_type VARCHAR(20) DEFAULT 'PERMANENT'
        CHECK (link_type IN ('PERMANENT', 'TEMPORARY', 'EMERGENCY'));
END IF;

    -- Add expires_at column if it doesn't exist
    IF
NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = current_schema() 
        AND table_name = 'family_member_link' 
        AND column_name = 'expires_at'
    ) THEN
ALTER TABLE family_member_link
    ADD COLUMN expires_at TIMESTAMP NULL;
END IF;

    -- Add notes column if it doesn't exist
    IF
NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = current_schema() 
        AND table_name = 'family_member_link' 
        AND column_name = 'notes'
    ) THEN
ALTER TABLE family_member_link
    ADD COLUMN notes TEXT;
END IF;

    -- Add relationship column if it doesn't exist
    IF
NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = current_schema() 
        AND table_name = 'family_member_link' 
        AND column_name = 'relationship'
    ) THEN
ALTER TABLE family_member_link
    ADD COLUMN relationship VARCHAR(100);
END IF;

    -- Add updated_at column if it doesn't exist
    IF
NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = current_schema() 
        AND table_name = 'family_member_link' 
        AND column_name = 'updated_at'
    ) THEN
ALTER TABLE family_member_link
    ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
END IF;
END $$;

-- =====================================================
-- 3. CAREGIVER-PATIENT LINKING TABLE
-- =====================================================
-- Create the caregiver_patient_link table if it doesn't exist
CREATE TABLE IF NOT EXISTS caregiver_patient_link
(
    id
    BIGSERIAL
    PRIMARY
    KEY,
    caregiver_user_id
    BIGINT
    NOT
    NULL,
    patient_user_id
    BIGINT
    NOT
    NULL,
    created_by
    BIGINT
    NOT
    NULL,
    created_at
    TIMESTAMP
    DEFAULT
    CURRENT_TIMESTAMP,
    updated_at
    TIMESTAMP
    DEFAULT
    CURRENT_TIMESTAMP,
    status
    VARCHAR
(
    20
) DEFAULT 'ACTIVE' CHECK
(
    status
    IN
(
    'ACTIVE',
    'SUSPENDED',
    'REVOKED',
    'EXPIRED'
)),
    link_type VARCHAR
(
    20
) DEFAULT 'PERMANENT' CHECK
(
    link_type
    IN
(
    'PERMANENT',
    'TEMPORARY',
    'EMERGENCY'
)),
    expires_at TIMESTAMP NULL,
    notes TEXT,
    FOREIGN KEY
(
    caregiver_user_id
) REFERENCES users
(
    id
) ON DELETE CASCADE,
    FOREIGN KEY
(
    patient_user_id
) REFERENCES users
(
    id
)
  ON DELETE CASCADE,
    FOREIGN KEY
(
    created_by
) REFERENCES users
(
    id
)
  ON DELETE CASCADE
    );

-- =====================================================
-- 4. FAMILY MEMBER TABLE
-- =====================================================
-- Add family member table if it doesn't exist
CREATE TABLE IF NOT EXISTS family_member
(
    id
    BIGSERIAL
    PRIMARY
    KEY,
    user_id
    BIGINT
    NOT
    NULL
    UNIQUE,
    first_name
    VARCHAR
(
    100
),
    last_name VARCHAR
(
    100
),
    email VARCHAR
(
    254
) NOT NULL UNIQUE,
    phone VARCHAR
(
    32
),
    address_line1 VARCHAR
(
    255
),
    address_line2 VARCHAR
(
    255
),
    city VARCHAR
(
    100
),
    state VARCHAR
(
    50
),
    zip VARCHAR
(
    20
),
    FOREIGN KEY
(
    user_id
) REFERENCES users
(
    id
) ON DELETE CASCADE
    );

-- =====================================================
-- 5. CREATE INDEXES FOR PERFORMANCE
-- =====================================================
-- For caregiver_patient_link table
CREATE INDEX IF NOT EXISTS idx_caregiver_patient_link_caregiver ON caregiver_patient_link(caregiver_user_id);
CREATE INDEX IF NOT EXISTS idx_caregiver_patient_link_patient ON caregiver_patient_link(patient_user_id);
CREATE INDEX IF NOT EXISTS idx_caregiver_patient_link_status ON caregiver_patient_link(status);
CREATE INDEX IF NOT EXISTS idx_caregiver_patient_link_expires ON caregiver_patient_link(expires_at);

-- For family_member_link table
CREATE INDEX IF NOT EXISTS idx_family_member_link_family ON family_member_link(family_user_id);
CREATE INDEX IF NOT EXISTS idx_family_member_link_patient ON family_member_link(patient_user_id);
CREATE INDEX IF NOT EXISTS idx_family_member_link_status ON family_member_link(status);
CREATE INDEX IF NOT EXISTS idx_family_member_link_expires ON family_member_link(expires_at);

-- =====================================================
-- 6. REMOVE DIRECT CAREGIVER-PATIENT RELATIONSHIP
-- =====================================================
-- Remove the direct caregiver_id column from patient table since we now use linking tables

DO
$$
DECLARE
constraint_name TEXT;
BEGIN
    -- Find and drop foreign key constraint for caregiver_id if it exists
SELECT tc.constraint_name
INTO constraint_name
FROM information_schema.table_constraints tc
         JOIN information_schema.key_column_usage kcu
              ON tc.constraint_name = kcu.constraint_name
                  AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = current_schema()
  AND tc.table_name = 'patient'
  AND kcu.column_name = 'caregiver_id' LIMIT 1;

IF
constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE patient DROP CONSTRAINT ' || constraint_name;
END IF;

    -- Drop the caregiver_id column if it exists
    IF
EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = current_schema()
        AND table_name = 'patient'
        AND column_name = 'caregiver_id'
    ) THEN
ALTER TABLE patient DROP COLUMN caregiver_id;
END IF;
END $$;

-- =====================================================
-- 7. CREATE TRIGGERS FOR AUTOMATIC TIMESTAMP UPDATES
-- =====================================================
-- PostgreSQL doesn't support ON UPDATE CURRENT_TIMESTAMP, so we need triggers

-- Create trigger function for updating timestamps
CREATE
OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at
= CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$
language 'plpgsql';

-- Create triggers for tables that need automatic updated_at updates
DO
$$
BEGIN
    -- For family_member_link table
    IF
NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_schema = current_schema() 
        AND trigger_name = 'update_family_member_link_updated_at'
    ) THEN
CREATE TRIGGER update_family_member_link_updated_at
    BEFORE UPDATE
    ON family_member_link
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
END IF;

    -- For caregiver_patient_link table
    IF
NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_schema = current_schema() 
        AND trigger_name = 'update_caregiver_patient_link_updated_at'
    ) THEN
CREATE TRIGGER update_caregiver_patient_link_updated_at
    BEFORE UPDATE
    ON caregiver_patient_link
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
END IF;
END $$;
