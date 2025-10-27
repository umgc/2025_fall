/* ---- VIRTUAL CHECK-IN: SEED QUESTIONS ---- */
INSERT INTO questions (prompt, type, required, ordinal) VALUES
('Did you take all of your prescribed medications today?', 'YES_NO', TRUE, 1),
('Have you missed any doses in the past 24 hours?', 'YES_NO', TRUE, 2),
('I feel comfortable managing my medications without help.', 'TRUE_FALSE', FALSE, 3),
('On a scale of 0–10, how would you rate your current level of pain?', 'NUMBER', TRUE, 4),
('On a scale of 0–10, how would you rate your overall mood today?', 'NUMBER', TRUE, 5),
('Did you sleep well last night?', 'YES_NO', FALSE, 6),
('Have you eaten at least two meals today?', 'YES_NO', FALSE, 7),
('I have experienced dizziness or lightheadedness today.', 'TRUE_FALSE', FALSE, 8),
('Have you had any difficulty breathing or chest discomfort?', 'YES_NO', TRUE, 9),
('Do you currently feel safe and comfortable at home?', 'YES_NO', TRUE, 10),
('Please describe any new symptoms or concerns you’ve noticed.', 'TEXT', FALSE, 11),
('Is there anything specific you’d like to talk to your caregiver about?', 'TEXT', FALSE, 12),
('How are you feeling emotionally today?', 'TEXT', FALSE, 13),
('How much energy do you feel you have right now (0 = none, 10 = full of energy)?', 'NUMBER', FALSE, 14),
('Have you experienced any side effects from your medication today?', 'YES_NO', TRUE, 15)
ON CONFLICT DO NOTHING;
