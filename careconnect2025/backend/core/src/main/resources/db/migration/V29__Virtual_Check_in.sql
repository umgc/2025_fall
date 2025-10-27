/* ---- VIRTUAL CHECK-IN: TABLES ---- */

-- Questions
CREATE TABLE IF NOT EXISTS questions (
  id BIGSERIAL PRIMARY KEY,
  prompt   TEXT        NOT NULL,
  type     VARCHAR(32) NOT NULL,  -- TEXT | YES_NO | TRUE_FALSE | NUMBER
  required BOOLEAN     NOT NULL DEFAULT FALSE,
  active   BOOLEAN     NOT NULL DEFAULT TRUE,
  ordinal  INT         NOT NULL DEFAULT 0,
  CONSTRAINT chk_questions_type
    CHECK (type IN ('TEXT','YES_NO','TRUE_FALSE','NUMBER'))
);

-- Check-ins
CREATE TABLE IF NOT EXISTS check_ins (
  id BIGSERIAL PRIMARY KEY,
  patient_id BIGINT NOT NULL REFERENCES patients(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  submitted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_checkins_patient_created
  ON check_ins(patient_id, created_at DESC);

-- Check-in → questions (snapshot of question metadata at time of check-in)
CREATE TABLE IF NOT EXISTS check_in_questions (
  check_in_id BIGINT NOT NULL REFERENCES check_ins(id) ON DELETE CASCADE,
  question_id BIGINT NOT NULL REFERENCES questions(id),
  required    BOOLEAN NOT NULL,
  ordinal     INT     NOT NULL,
  PRIMARY KEY (check_in_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_ciq_checkin ON check_in_questions(check_in_id);

-- Answers (one per question per check-in)
CREATE TABLE IF NOT EXISTS answers (
  id BIGSERIAL PRIMARY KEY,
  check_in_id BIGINT NOT NULL REFERENCES check_ins(id) ON DELETE CASCADE,
  question_id BIGINT NOT NULL REFERENCES questions(id),

  value_text    TEXT,
  value_boolean BOOLEAN,
  value_number  NUMERIC(12,2),

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT chk_answers_single_value CHECK (
    (CASE WHEN value_text    IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN value_boolean IS NOT NULL THEN 1 ELSE 0 END) +
    (CASE WHEN value_number  IS NOT NULL THEN 1 ELSE 0 END)
    = 1
  ),
  CONSTRAINT uq_answers_checkin_question UNIQUE (check_in_id, question_id),
  CONSTRAINT fk_answers_selected_question
    FOREIGN KEY (check_in_id, question_id)
    REFERENCES check_in_questions(check_in_id, question_id)
    ON DELETE CASCADE
);
