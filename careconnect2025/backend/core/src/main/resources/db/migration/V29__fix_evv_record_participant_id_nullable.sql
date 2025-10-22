-- Migrate existing EVV records from participant_id to patient_id
-- V28 already added the patient_id column and constraints
-- This migration only handles the data migration from evv_participant to patient

-- Update any existing records that have participant_id but no patient_id
-- This links EVV records to patients via the MA number
UPDATE evv_record 
SET patient_id = (
    SELECT p.id 
    FROM patient p 
    JOIN evv_participant ep ON p.ma_number = ep.ma_number 
    WHERE ep.id = evv_record.participant_id
)
WHERE patient_id IS NULL AND participant_id IS NOT NULL;
