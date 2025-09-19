--
-- PostgreSQL database dump
--

\restrict Iz0rd6p4XFsL9cREIy6G7mCLoTo0wkEP2aizcn5aLw0OOSqjSeFbFHgVSQdDdDk

-- Dumped from database version 15.14 (Debian 15.14-1.pgdg12+1)
-- Dumped by pg_dump version 15.14 (Debian 15.14-1.pgdg12+1)

-- Started on 2025-09-18 15:59:48 UTC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS careconnect;
--
-- TOC entry 3857 (class 1262 OID 16384)
-- Name: careconnect; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE careconnect WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE careconnect OWNER TO postgres;

\unrestrict Iz0rd6p4XFsL9cREIy6G7mCLoTo0wkEP2aizcn5aLw0OOSqjSeFbFHgVSQdDdDk
\connect careconnect
\restrict Iz0rd6p4XFsL9cREIy6G7mCLoTo0wkEP2aizcn5aLw0OOSqjSeFbFHgVSQdDdDk

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 286 (class 1255 OID 24968)
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 246 (class 1259 OID 24879)
-- Name: achievement; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.achievement (
    id bigint NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    icon character varying(255)
);


ALTER TABLE public.achievement OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 24878)
-- Name: achievement_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.achievement_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.achievement_id_seq OWNER TO postgres;

--
-- TOC entry 3858 (class 0 OID 0)
-- Dependencies: 245
-- Name: achievement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.achievement_id_seq OWNED BY public.achievement.id;


--
-- TOC entry 218 (class 1259 OID 24603)
-- Name: caregiver; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.caregiver (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    dob date,
    email character varying(254) NOT NULL,
    phone character varying(32),
    address_line1 character varying(255),
    address_line2 character varying(255),
    city character varying(100),
    state character varying(50),
    zip character varying(20),
    caregiver_type character varying(20) NOT NULL,
    license_number character varying(100),
    issuing_state character varying(10),
    years_experience integer,
    gender character varying(20)
);


ALTER TABLE public.caregiver OWNER TO postgres;

--
-- TOC entry 3859 (class 0 OID 0)
-- Dependencies: 218
-- Name: COLUMN caregiver.gender; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.caregiver.gender IS 'Caregiver gender (MALE, FEMALE, OTHER, PREFER_NOT_TO_SAY)';


--
-- TOC entry 217 (class 1259 OID 24602)
-- Name: caregiver_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.caregiver_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.caregiver_id_seq OWNER TO postgres;

--
-- TOC entry 3860 (class 0 OID 0)
-- Dependencies: 217
-- Name: caregiver_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.caregiver_id_seq OWNED BY public.caregiver.id;


--
-- TOC entry 250 (class 1259 OID 24913)
-- Name: caregiver_patient_link; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.caregiver_patient_link (
    id bigint NOT NULL,
    caregiver_user_id bigint NOT NULL,
    patient_user_id bigint NOT NULL,
    created_by bigint NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'ACTIVE'::character varying,
    link_type character varying(20) DEFAULT 'PERMANENT'::character varying,
    expires_at timestamp without time zone,
    notes text,
    CONSTRAINT caregiver_patient_link_link_type_check CHECK (((link_type)::text = ANY ((ARRAY['PERMANENT'::character varying, 'TEMPORARY'::character varying, 'EMERGENCY'::character varying])::text[]))),
    CONSTRAINT caregiver_patient_link_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'SUSPENDED'::character varying, 'REVOKED'::character varying, 'EXPIRED'::character varying])::text[])))
);


ALTER TABLE public.caregiver_patient_link OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 24912)
-- Name: caregiver_patient_link_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.caregiver_patient_link_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.caregiver_patient_link_id_seq OWNER TO postgres;

--
-- TOC entry 3861 (class 0 OID 0)
-- Dependencies: 249
-- Name: caregiver_patient_link_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.caregiver_patient_link_id_seq OWNED BY public.caregiver_patient_link.id;


--
-- TOC entry 268 (class 1259 OID 25127)
-- Name: chat_conversations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_conversations (
    id bigint NOT NULL,
    conversation_id character varying(36) NOT NULL,
    patient_id bigint NOT NULL,
    user_id bigint NOT NULL,
    chat_type character varying(50) DEFAULT 'GENERAL_SUPPORT'::character varying NOT NULL,
    title character varying(200),
    ai_provider_used character varying(20),
    ai_model_used character varying(100),
    total_tokens_used integer DEFAULT 0,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chat_conversations_ai_provider_used_check CHECK (((ai_provider_used)::text = ANY ((ARRAY['OPENAI'::character varying, 'DEEPSEEK'::character varying])::text[]))),
    CONSTRAINT chat_conversations_chat_type_check CHECK (((chat_type)::text = ANY ((ARRAY['MEDICAL_CONSULTATION'::character varying, 'GENERAL_SUPPORT'::character varying, 'MEDICATION_INQUIRY'::character varying, 'MOOD_PAIN_SUPPORT'::character varying, 'EMERGENCY_GUIDANCE'::character varying, 'LIFESTYLE_ADVICE'::character varying])::text[])))
);


ALTER TABLE public.chat_conversations OWNER TO postgres;

--
-- TOC entry 267 (class 1259 OID 25126)
-- Name: chat_conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_conversations_id_seq OWNER TO postgres;

--
-- TOC entry 3862 (class 0 OID 0)
-- Dependencies: 267
-- Name: chat_conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_conversations_id_seq OWNED BY public.chat_conversations.id;


--
-- TOC entry 270 (class 1259 OID 25148)
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_messages (
    id bigint NOT NULL,
    conversation_id bigint NOT NULL,
    message_type character varying(20) NOT NULL,
    content text NOT NULL,
    tokens_used integer,
    processing_time_ms bigint,
    temperature_used numeric(3,2),
    context_included text,
    ai_model_used character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chat_messages_message_type_check CHECK (((message_type)::text = ANY ((ARRAY['USER'::character varying, 'ASSISTANT'::character varying, 'SYSTEM'::character varying])::text[])))
);


ALTER TABLE public.chat_messages OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 25147)
-- Name: chat_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chat_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_messages_id_seq OWNER TO postgres;

--
-- TOC entry 3863 (class 0 OID 0)
-- Dependencies: 269
-- Name: chat_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_messages_id_seq OWNED BY public.chat_messages.id;


--
-- TOC entry 264 (class 1259 OID 25078)
-- Name: device_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    fcm_token character varying(500) NOT NULL,
    device_type character varying(10) NOT NULL,
    device_id character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    last_used_at timestamp without time zone,
    CONSTRAINT device_tokens_device_type_check CHECK (((device_type)::text = ANY ((ARRAY['ANDROID'::character varying, 'IOS'::character varying, 'WEB'::character varying])::text[])))
);


ALTER TABLE public.device_tokens OWNER TO postgres;

--
-- TOC entry 263 (class 1259 OID 25077)
-- Name: device_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.device_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.device_tokens_id_seq OWNER TO postgres;

--
-- TOC entry 3864 (class 0 OID 0)
-- Dependencies: 263
-- Name: device_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.device_tokens_id_seq OWNED BY public.device_tokens.id;


--
-- TOC entry 230 (class 1259 OID 24712)
-- Name: email_verification_token; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_verification_token (
    id bigint NOT NULL,
    token character varying(255) NOT NULL,
    user_id bigint,
    expires_at timestamp without time zone NOT NULL
);


ALTER TABLE public.email_verification_token OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 24711)
-- Name: email_verification_token_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.email_verification_token_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.email_verification_token_id_seq OWNER TO postgres;

--
-- TOC entry 3865 (class 0 OID 0)
-- Dependencies: 229
-- Name: email_verification_token_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.email_verification_token_id_seq OWNED BY public.email_verification_token.id;


--
-- TOC entry 252 (class 1259 OID 24943)
-- Name: family_member; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.family_member (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    email character varying(254) NOT NULL,
    phone character varying(32),
    address_line1 character varying(255),
    address_line2 character varying(255),
    city character varying(100),
    state character varying(50),
    zip character varying(20)
);


ALTER TABLE public.family_member OWNER TO postgres;

--
-- TOC entry 251 (class 1259 OID 24942)
-- Name: family_member_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.family_member_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.family_member_id_seq OWNER TO postgres;

--
-- TOC entry 3866 (class 0 OID 0)
-- Dependencies: 251
-- Name: family_member_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.family_member_id_seq OWNED BY public.family_member.id;


--
-- TOC entry 244 (class 1259 OID 24836)
-- Name: family_member_link; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.family_member_link (
    id bigint NOT NULL,
    family_user_id bigint,
    patient_user_id bigint,
    granted_by bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'ACTIVE'::character varying,
    link_type character varying(20) DEFAULT 'PERMANENT'::character varying,
    expires_at timestamp without time zone,
    notes text,
    relationship character varying(100),
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    patient_id bigint,
    CONSTRAINT family_member_link_link_type_check CHECK (((link_type)::text = ANY ((ARRAY['PERMANENT'::character varying, 'TEMPORARY'::character varying, 'EMERGENCY'::character varying])::text[]))),
    CONSTRAINT family_member_link_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'SUSPENDED'::character varying, 'REVOKED'::character varying, 'EXPIRED'::character varying])::text[])))
);


ALTER TABLE public.family_member_link OWNER TO postgres;

--
-- TOC entry 3867 (class 0 OID 0)
-- Dependencies: 244
-- Name: COLUMN family_member_link.patient_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.family_member_link.patient_id IS 'Denormalized patient ID for faster queries without joins';


--
-- TOC entry 243 (class 1259 OID 24835)
-- Name: family_member_link_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.family_member_link_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.family_member_link_id_seq OWNER TO postgres;

--
-- TOC entry 3868 (class 0 OID 0)
-- Dependencies: 243
-- Name: family_member_link_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.family_member_link_id_seq OWNED BY public.family_member_link.id;


--
-- TOC entry 214 (class 1259 OID 24576)
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


ALTER TABLE public.flyway_schema_history OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 24744)
-- Name: meal_entry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.meal_entry (
    id bigint NOT NULL,
    patient_user_id bigint NOT NULL,
    caregiver_user_id bigint,
    calories integer,
    taken_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT meal_entry_calories_check CHECK ((calories >= 0))
);


ALTER TABLE public.meal_entry OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 24743)
-- Name: meal_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.meal_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.meal_entry_id_seq OWNER TO postgres;

--
-- TOC entry 3869 (class 0 OID 0)
-- Dependencies: 233
-- Name: meal_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.meal_entry_id_seq OWNED BY public.meal_entry.id;


--
-- TOC entry 236 (class 1259 OID 24765)
-- Name: mood_entry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mood_entry (
    id bigint NOT NULL,
    patient_user_id bigint NOT NULL,
    mood_score integer,
    taken_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mood_entry_mood_score_check CHECK (((mood_score >= 1) AND (mood_score <= 5)))
);


ALTER TABLE public.mood_entry OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 24764)
-- Name: mood_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mood_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.mood_entry_id_seq OWNER TO postgres;

--
-- TOC entry 3870 (class 0 OID 0)
-- Dependencies: 235
-- Name: mood_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mood_entry_id_seq OWNED BY public.mood_entry.id;


--
-- TOC entry 254 (class 1259 OID 24982)
-- Name: mood_pain_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mood_pain_log (
    id bigint NOT NULL,
    patient_id bigint NOT NULL,
    mood_value integer NOT NULL,
    pain_value integer NOT NULL,
    note text,
    "timestamp" timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT chk_pain_value_0_10 CHECK (((pain_value >= 0) AND (pain_value <= 10))),
    CONSTRAINT mood_pain_log_mood_value_check CHECK (((mood_value >= 1) AND (mood_value <= 10))),
    CONSTRAINT mood_pain_log_pain_value_check CHECK (((pain_value >= 1) AND (pain_value <= 10)))
);


ALTER TABLE public.mood_pain_log OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 24981)
-- Name: mood_pain_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mood_pain_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.mood_pain_log_id_seq OWNER TO postgres;

--
-- TOC entry 3871 (class 0 OID 0)
-- Dependencies: 253
-- Name: mood_pain_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mood_pain_log_id_seq OWNED BY public.mood_pain_log.id;


--
-- TOC entry 232 (class 1259 OID 24726)
-- Name: password_reset_token; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.password_reset_token (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_hash character varying(255) NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    used boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.password_reset_token OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 24725)
-- Name: password_reset_token_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.password_reset_token_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.password_reset_token_id_seq OWNER TO postgres;

--
-- TOC entry 3872 (class 0 OID 0)
-- Dependencies: 231
-- Name: password_reset_token_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.password_reset_token_id_seq OWNED BY public.password_reset_token.id;


--
-- TOC entry 220 (class 1259 OID 24621)
-- Name: patient; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patient (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    dob date,
    email character varying(254) NOT NULL,
    phone character varying(32),
    address_line1 character varying(255),
    address_line2 character varying(255),
    city character varying(100),
    state character varying(50),
    zip character varying(20),
    sex character varying(10),
    medical_notes text,
    relationship character varying(50),
    gender character varying(20),
    CONSTRAINT patient_sex_check CHECK (((sex)::text = ANY ((ARRAY['M'::character varying, 'F'::character varying, 'OTHER'::character varying])::text[])))
);


ALTER TABLE public.patient OWNER TO postgres;

--
-- TOC entry 3873 (class 0 OID 0)
-- Dependencies: 220
-- Name: COLUMN patient.gender; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient.gender IS 'Patient gender (MALE, FEMALE, OTHER, PREFER_NOT_TO_SAY)';


--
-- TOC entry 266 (class 1259 OID 25101)
-- Name: patient_ai_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patient_ai_config (
    id bigint NOT NULL,
    patient_id bigint NOT NULL,
    ai_provider character varying(20) NOT NULL,
    openai_model character varying(100),
    deepseek_model character varying(100),
    max_tokens integer DEFAULT 1000 NOT NULL,
    temperature numeric(3,2) DEFAULT 0.7 NOT NULL,
    conversation_history_limit integer DEFAULT 20 NOT NULL,
    include_vitals_by_default boolean DEFAULT true NOT NULL,
    include_medications_by_default boolean DEFAULT true NOT NULL,
    include_notes_by_default boolean DEFAULT true NOT NULL,
    include_mood_pain_logs_by_default boolean DEFAULT true NOT NULL,
    include_allergies_by_default boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    system_prompt text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT patient_ai_config_ai_provider_check CHECK (((ai_provider)::text = ANY ((ARRAY['OPENAI'::character varying, 'DEEPSEEK'::character varying])::text[]))),
    CONSTRAINT patient_ai_config_conversation_history_limit_check CHECK (((conversation_history_limit >= 5) AND (conversation_history_limit <= 100))),
    CONSTRAINT patient_ai_config_max_tokens_check CHECK (((max_tokens >= 100) AND (max_tokens <= 8000))),
    CONSTRAINT patient_ai_config_temperature_check CHECK (((temperature >= 0.0) AND (temperature <= 2.0)))
);


ALTER TABLE public.patient_ai_config OWNER TO postgres;

--
-- TOC entry 265 (class 1259 OID 25100)
-- Name: patient_ai_config_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.patient_ai_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.patient_ai_config_id_seq OWNER TO postgres;

--
-- TOC entry 3874 (class 0 OID 0)
-- Dependencies: 265
-- Name: patient_ai_config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.patient_ai_config_id_seq OWNED BY public.patient_ai_config.id;


--
-- TOC entry 258 (class 1259 OID 25019)
-- Name: patient_allergy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patient_allergy (
    id bigint NOT NULL,
    patient_id bigint NOT NULL,
    allergen character varying(255) NOT NULL,
    allergy_type character varying(50),
    severity character varying(50),
    reaction text,
    notes text,
    diagnosed_date character varying(50),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.patient_allergy OWNER TO postgres;

--
-- TOC entry 3875 (class 0 OID 0)
-- Dependencies: 258
-- Name: TABLE patient_allergy; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.patient_allergy IS 'Patient allergy information including allergens, reactions, and severity';


--
-- TOC entry 3876 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.patient_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.patient_id IS 'Reference to the patient who has this allergy';


--
-- TOC entry 3877 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.allergen; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.allergen IS 'Name of the allergen (e.g., Peanuts, Penicillin, Latex)';


--
-- TOC entry 3878 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.allergy_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.allergy_type IS 'Type of allergy (FOOD, MEDICATION, ENVIRONMENTAL, CONTACT, SEASONAL, OTHER)';


--
-- TOC entry 3879 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.severity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.severity IS 'Severity level (MILD, MODERATE, SEVERE, LIFE_THREATENING)';


--
-- TOC entry 3880 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.reaction; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.reaction IS 'Description of allergic reaction symptoms';


--
-- TOC entry 3881 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.notes IS 'Additional notes from healthcare providers';


--
-- TOC entry 3882 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.diagnosed_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.diagnosed_date IS 'When the allergy was first diagnosed';


--
-- TOC entry 3883 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.is_active IS 'Whether the allergy is currently active (for soft deletes)';


--
-- TOC entry 257 (class 1259 OID 25018)
-- Name: patient_allergy_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.patient_allergy ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.patient_allergy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 262 (class 1259 OID 25058)
-- Name: patient_caregiver; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patient_caregiver (
    id bigint NOT NULL,
    patient_id bigint NOT NULL,
    caregiver_user_id bigint NOT NULL,
    relationship_type character varying(50),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.patient_caregiver OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 25057)
-- Name: patient_caregiver_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.patient_caregiver_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.patient_caregiver_id_seq OWNER TO postgres;

--
-- TOC entry 3884 (class 0 OID 0)
-- Dependencies: 261
-- Name: patient_caregiver_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.patient_caregiver_id_seq OWNED BY public.patient_caregiver.id;


--
-- TOC entry 219 (class 1259 OID 24620)
-- Name: patient_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.patient_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.patient_id_seq OWNER TO postgres;

--
-- TOC entry 3885 (class 0 OID 0)
-- Dependencies: 219
-- Name: patient_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.patient_id_seq OWNED BY public.patient.id;


--
-- TOC entry 260 (class 1259 OID 25038)
-- Name: patient_medication; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.patient_medication (
    id bigint NOT NULL,
    patient_id bigint NOT NULL,
    medication_name character varying(255) NOT NULL,
    dosage character varying(100),
    frequency character varying(100),
    route character varying(50),
    medication_type character varying(50),
    prescribed_by character varying(255),
    prescribed_date character varying(50),
    start_date character varying(50),
    end_date character varying(50),
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.patient_medication OWNER TO postgres;

--
-- TOC entry 3886 (class 0 OID 0)
-- Dependencies: 260
-- Name: TABLE patient_medication; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.patient_medication IS 'Patient medication information including prescriptions and supplements';


--
-- TOC entry 3887 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.patient_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.patient_id IS 'Reference to the patient taking this medication';


--
-- TOC entry 3888 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.medication_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.medication_name IS 'Name of the medication or supplement';


--
-- TOC entry 3889 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.dosage; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.dosage IS 'Dosage information (e.g., 10mg, 2 tablets)';


--
-- TOC entry 3890 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.frequency; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.frequency IS 'How often to take (e.g., twice daily, every 8 hours)';


--
-- TOC entry 3891 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.route; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.route IS 'Route of administration (oral, injection, topical, etc.)';


--
-- TOC entry 3892 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.medication_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.medication_type IS 'Type of medication (PRESCRIPTION, OVER_THE_COUNTER, SUPPLEMENT, HERBAL, EMERGENCY)';


--
-- TOC entry 3893 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.prescribed_by; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.prescribed_by IS 'Name of the prescribing healthcare provider';


--
-- TOC entry 3894 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.prescribed_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.prescribed_date IS 'Date when medication was prescribed';


--
-- TOC entry 3895 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.start_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.start_date IS 'Date when patient started taking the medication';


--
-- TOC entry 3896 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.end_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.end_date IS 'Date when medication should be stopped (null for ongoing)';


--
-- TOC entry 3897 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.notes IS 'Additional instructions or notes about the medication';


--
-- TOC entry 3898 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.is_active; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.is_active IS 'Whether the medication is currently active (for soft deletes)';


--
-- TOC entry 259 (class 1259 OID 25037)
-- Name: patient_medication_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.patient_medication ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.patient_medication_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 228 (class 1259 OID 24691)
-- Name: payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment (
    id bigint NOT NULL,
    subscription_id bigint NOT NULL,
    payment_method_id bigint,
    amount_cents integer NOT NULL,
    stripe_session_id character varying(255),
    stripe_payment_intent_id character varying(255),
    status character varying(20) NOT NULL,
    attempted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT payment_status_check CHECK (((status)::text = ANY ((ARRAY['SUCCEEDED'::character varying, 'FAILED'::character varying])::text[])))
);


ALTER TABLE public.payment OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 24690)
-- Name: payment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payment_id_seq OWNER TO postgres;

--
-- TOC entry 3899 (class 0 OID 0)
-- Dependencies: 227
-- Name: payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_id_seq OWNED BY public.payment.id;


--
-- TOC entry 226 (class 1259 OID 24677)
-- Name: payment_method; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment_method (
    id bigint NOT NULL,
    user_id bigint,
    provider character varying(20) NOT NULL,
    stripe_token character varying(255),
    last4 character(4),
    brand character varying(20),
    exp_month integer,
    exp_year integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT payment_method_provider_check CHECK (((provider)::text = ANY ((ARRAY['CARD'::character varying, 'PAYPAL'::character varying])::text[])))
);


ALTER TABLE public.payment_method OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 24676)
-- Name: payment_method_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_method_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payment_method_id_seq OWNER TO postgres;

--
-- TOC entry 3900 (class 0 OID 0)
-- Dependencies: 225
-- Name: payment_method_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_method_id_seq OWNED BY public.payment_method.id;


--
-- TOC entry 222 (class 1259 OID 24645)
-- Name: plan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.plan (
    id bigint NOT NULL,
    code character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    price_cents integer NOT NULL,
    billing_period character varying(20) DEFAULT 'MONTH'::character varying,
    is_active boolean DEFAULT true,
    CONSTRAINT plan_chk_1 CHECK ((price_cents >= 0))
);


ALTER TABLE public.plan OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 24644)
-- Name: plan_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.plan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.plan_id_seq OWNER TO postgres;

--
-- TOC entry 3901 (class 0 OID 0)
-- Dependencies: 221
-- Name: plan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.plan_id_seq OWNED BY public.plan.id;


--
-- TOC entry 224 (class 1259 OID 24657)
-- Name: subscription; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscription (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    plan_id bigint NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying,
    started_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    current_period_end timestamp without time zone,
    CONSTRAINT subscription_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'SUSPENDED'::character varying, 'GRACE'::character varying, 'CANCELLED'::character varying])::text[])))
);


ALTER TABLE public.subscription OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 24656)
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.subscription_id_seq OWNER TO postgres;

--
-- TOC entry 3902 (class 0 OID 0)
-- Dependencies: 223
-- Name: subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscription_id_seq OWNED BY public.subscription.id;


--
-- TOC entry 240 (class 1259 OID 24797)
-- Name: summary_metrics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.summary_metrics (
    id bigint NOT NULL,
    patient_user_id bigint NOT NULL,
    period_start timestamp without time zone NOT NULL,
    period_end timestamp without time zone NOT NULL,
    adherence_rate double precision,
    avg_heart_rate double precision,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.summary_metrics OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 24796)
-- Name: summary_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.summary_metrics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.summary_metrics_id_seq OWNER TO postgres;

--
-- TOC entry 3903 (class 0 OID 0)
-- Dependencies: 239
-- Name: summary_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.summary_metrics_id_seq OWNED BY public.summary_metrics.id;


--
-- TOC entry 242 (class 1259 OID 24814)
-- Name: symptom_entry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.symptom_entry (
    id bigint NOT NULL,
    patient_user_id bigint NOT NULL,
    caregiver_user_id bigint,
    symptom_key character varying(60) NOT NULL,
    symptom_value character varying(255) NOT NULL,
    severity integer,
    taken_at timestamp without time zone NOT NULL,
    completed boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT symptom_entry_severity_check CHECK (((severity >= 1) AND (severity <= 5)))
);


ALTER TABLE public.symptom_entry OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 24813)
-- Name: symptom_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.symptom_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.symptom_entry_id_seq OWNER TO postgres;

--
-- TOC entry 3904 (class 0 OID 0)
-- Dependencies: 241
-- Name: symptom_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.symptom_entry_id_seq OWNED BY public.symptom_entry.id;


--
-- TOC entry 272 (class 1259 OID 25168)
-- Name: tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tasks (
    id bigint NOT NULL,
    patient_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    date timestamp without time zone NOT NULL,
    time_of_day time without time zone NOT NULL,
    iscompleted boolean DEFAULT false NOT NULL,
    task_type character varying(20) NOT NULL,
    frequency text,
    task_interval integer,
    do_count integer,
    days_of_week jsonb NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT tasks_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'COMPLETED'::character varying])::text[]))),
    CONSTRAINT tasks_task_type_check CHECK (((task_type)::text = ANY ((ARRAY['TASK'::character varying, 'FREQUENCY'::character varying, 'DAYOFWEEK'::character varying])::text[])))
);


ALTER TABLE public.tasks OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 25167)
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tasks_id_seq OWNER TO postgres;

--
-- TOC entry 3905 (class 0 OID 0)
-- Dependencies: 271
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- TOC entry 274 (class 1259 OID 25183)
-- Name: templates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.templates (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    frequency text,
    task_interval integer,
    do_count integer,
    days_of_week jsonb,
    time_of_day time without time zone,
    icon character varying(255) NOT NULL,
    notifications jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.templates OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 25182)
-- Name: templates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.templates_id_seq OWNER TO postgres;

--
-- TOC entry 3906 (class 0 OID 0)
-- Dependencies: 273
-- Name: templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.templates_id_seq OWNED BY public.templates.id;


--
-- TOC entry 248 (class 1259 OID 24888)
-- Name: user_achievements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_achievements (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    achievement_id bigint NOT NULL,
    date_earned timestamp without time zone,
    progress integer
);


ALTER TABLE public.user_achievements OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 24887)
-- Name: user_achievements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_achievements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_achievements_id_seq OWNER TO postgres;

--
-- TOC entry 3907 (class 0 OID 0)
-- Dependencies: 247
-- Name: user_achievements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_achievements_id_seq OWNED BY public.user_achievements.id;


--
-- TOC entry 216 (class 1259 OID 24586)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying(254) NOT NULL,
    email_verified boolean DEFAULT false,
    password character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    name character varying(100),
    verification_token character varying(255),
    stripe_customer_id character varying(255),
    last_login timestamp without time zone,
    profile_image_url character varying(255),
    last_login_date date,
    login_streak integer DEFAULT 0 NOT NULL,
    leaderboard_opt_in boolean DEFAULT true NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY ((ARRAY['PATIENT'::character varying, 'CAREGIVER'::character varying, 'FAMILY_MEMBER'::character varying, 'ADMIN'::character varying])::text[]))),
    CONSTRAINT users_status_check CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'SUSPENDED'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 24585)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO postgres;

--
-- TOC entry 3908 (class 0 OID 0)
-- Dependencies: 215
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- TOC entry 256 (class 1259 OID 25002)
-- Name: vital_sample; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vital_sample (
    id bigint NOT NULL,
    patient_id bigint NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    heart_rate double precision,
    spo2 double precision,
    systolic integer,
    diastolic integer,
    weight double precision,
    mood_value integer,
    pain_value integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT vital_sample_mood_value_check CHECK (((mood_value >= 1) AND (mood_value <= 10))),
    CONSTRAINT vital_sample_pain_value_check CHECK (((pain_value >= 1) AND (pain_value <= 10)))
);


ALTER TABLE public.vital_sample OWNER TO postgres;

--
-- TOC entry 3909 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE vital_sample; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.vital_sample IS 'Unified storage for all patient vital signs and health measurements';


--
-- TOC entry 3910 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.patient_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.patient_id IS 'Reference to the patient this vital sample belongs to';


--
-- TOC entry 3911 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample."timestamp"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample."timestamp" IS 'When this vital measurement was taken';


--
-- TOC entry 3912 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.heart_rate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.heart_rate IS 'Heart rate in beats per minute (BPM)';


--
-- TOC entry 3913 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.spo2; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.spo2 IS 'Blood oxygen saturation percentage (SpO2)';


--
-- TOC entry 3914 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.systolic; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.systolic IS 'Systolic blood pressure in mmHg';


--
-- TOC entry 3915 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.diastolic; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.diastolic IS 'Diastolic blood pressure in mmHg';


--
-- TOC entry 3916 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.weight; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.weight IS 'Patient weight in kilograms';


--
-- TOC entry 3917 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.mood_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.mood_value IS 'Mood rating on scale 1-10 (1=very bad, 10=excellent)';


--
-- TOC entry 3918 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.pain_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.pain_value IS 'Pain level on scale 1-10 (1=no pain, 10=severe pain)';


--
-- TOC entry 255 (class 1259 OID 25001)
-- Name: vital_sample_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.vital_sample ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.vital_sample_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 238 (class 1259 OID 24781)
-- Name: wearable_metric; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.wearable_metric (
    id bigint NOT NULL,
    patient_user_id bigint NOT NULL,
    metric character varying(20) NOT NULL,
    metric_value double precision NOT NULL,
    recorded_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT wearable_metric_metric_check CHECK (((metric)::text = ANY ((ARRAY['HEART_RATE'::character varying, 'SPO2'::character varying, 'TEMPERATURE'::character varying, 'BLOOD_PRESSURE_SYS'::character varying, 'BLOOD_PRESSURE_DIA'::character varying, 'WEIGHT'::character varying, 'STEPS'::character varying])::text[])))
);


ALTER TABLE public.wearable_metric OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 24780)
-- Name: wearable_metric_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.wearable_metric_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.wearable_metric_id_seq OWNER TO postgres;

--
-- TOC entry 3919 (class 0 OID 0)
-- Dependencies: 237
-- Name: wearable_metric_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.wearable_metric_id_seq OWNED BY public.wearable_metric.id;


--
-- TOC entry 3394 (class 2604 OID 24882)
-- Name: achievement id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.achievement ALTER COLUMN id SET DEFAULT nextval('public.achievement_id_seq'::regclass);


--
-- TOC entry 3357 (class 2604 OID 24606)
-- Name: caregiver id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver ALTER COLUMN id SET DEFAULT nextval('public.caregiver_id_seq'::regclass);


--
-- TOC entry 3396 (class 2604 OID 24916)
-- Name: caregiver_patient_link id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver_patient_link ALTER COLUMN id SET DEFAULT nextval('public.caregiver_patient_link_id_seq'::regclass);


--
-- TOC entry 3430 (class 2604 OID 25130)
-- Name: chat_conversations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_conversations ALTER COLUMN id SET DEFAULT nextval('public.chat_conversations_id_seq'::regclass);


--
-- TOC entry 3436 (class 2604 OID 25151)
-- Name: chat_messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages ALTER COLUMN id SET DEFAULT nextval('public.chat_messages_id_seq'::regclass);


--
-- TOC entry 3415 (class 2604 OID 25081)
-- Name: device_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_tokens ALTER COLUMN id SET DEFAULT nextval('public.device_tokens_id_seq'::regclass);


--
-- TOC entry 3369 (class 2604 OID 24715)
-- Name: email_verification_token id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verification_token ALTER COLUMN id SET DEFAULT nextval('public.email_verification_token_id_seq'::regclass);


--
-- TOC entry 3401 (class 2604 OID 24946)
-- Name: family_member id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member ALTER COLUMN id SET DEFAULT nextval('public.family_member_id_seq'::regclass);


--
-- TOC entry 3389 (class 2604 OID 24839)
-- Name: family_member_link id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link ALTER COLUMN id SET DEFAULT nextval('public.family_member_link_id_seq'::regclass);


--
-- TOC entry 3373 (class 2604 OID 24747)
-- Name: meal_entry id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_entry ALTER COLUMN id SET DEFAULT nextval('public.meal_entry_id_seq'::regclass);


--
-- TOC entry 3376 (class 2604 OID 24768)
-- Name: mood_entry id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_entry ALTER COLUMN id SET DEFAULT nextval('public.mood_entry_id_seq'::regclass);


--
-- TOC entry 3402 (class 2604 OID 24985)
-- Name: mood_pain_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_pain_log ALTER COLUMN id SET DEFAULT nextval('public.mood_pain_log_id_seq'::regclass);


--
-- TOC entry 3370 (class 2604 OID 24729)
-- Name: password_reset_token id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_token ALTER COLUMN id SET DEFAULT nextval('public.password_reset_token_id_seq'::regclass);


--
-- TOC entry 3358 (class 2604 OID 24624)
-- Name: patient id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient ALTER COLUMN id SET DEFAULT nextval('public.patient_id_seq'::regclass);


--
-- TOC entry 3418 (class 2604 OID 25104)
-- Name: patient_ai_config id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_ai_config ALTER COLUMN id SET DEFAULT nextval('public.patient_ai_config_id_seq'::regclass);


--
-- TOC entry 3413 (class 2604 OID 25061)
-- Name: patient_caregiver id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_caregiver ALTER COLUMN id SET DEFAULT nextval('public.patient_caregiver_id_seq'::regclass);


--
-- TOC entry 3367 (class 2604 OID 24694)
-- Name: payment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment ALTER COLUMN id SET DEFAULT nextval('public.payment_id_seq'::regclass);


--
-- TOC entry 3365 (class 2604 OID 24680)
-- Name: payment_method id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_method ALTER COLUMN id SET DEFAULT nextval('public.payment_method_id_seq'::regclass);


--
-- TOC entry 3359 (class 2604 OID 24648)
-- Name: plan id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plan ALTER COLUMN id SET DEFAULT nextval('public.plan_id_seq'::regclass);


--
-- TOC entry 3362 (class 2604 OID 24660)
-- Name: subscription id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription ALTER COLUMN id SET DEFAULT nextval('public.subscription_id_seq'::regclass);


--
-- TOC entry 3382 (class 2604 OID 24800)
-- Name: summary_metrics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.summary_metrics ALTER COLUMN id SET DEFAULT nextval('public.summary_metrics_id_seq'::regclass);


--
-- TOC entry 3385 (class 2604 OID 24817)
-- Name: symptom_entry id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symptom_entry ALTER COLUMN id SET DEFAULT nextval('public.symptom_entry_id_seq'::regclass);


--
-- TOC entry 3438 (class 2604 OID 25171)
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- TOC entry 3443 (class 2604 OID 25186)
-- Name: templates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.templates ALTER COLUMN id SET DEFAULT nextval('public.templates_id_seq'::regclass);


--
-- TOC entry 3395 (class 2604 OID 24891)
-- Name: user_achievements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievements ALTER COLUMN id SET DEFAULT nextval('public.user_achievements_id_seq'::regclass);


--
-- TOC entry 3350 (class 2604 OID 24589)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 3379 (class 2604 OID 24784)
-- Name: wearable_metric id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wearable_metric ALTER COLUMN id SET DEFAULT nextval('public.wearable_metric_id_seq'::regclass);


--
-- TOC entry 3823 (class 0 OID 24879)
-- Dependencies: 246
-- Data for Name: achievement; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.achievement (id, title, description, icon) FROM stdin;
\.


--
-- TOC entry 3795 (class 0 OID 24603)
-- Dependencies: 218
-- Data for Name: caregiver; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.caregiver (id, user_id, first_name, last_name, dob, email, phone, address_line1, address_line2, city, state, zip, caregiver_type, license_number, issuing_state, years_experience, gender) FROM stdin;
\.


--
-- TOC entry 3827 (class 0 OID 24913)
-- Dependencies: 250
-- Data for Name: caregiver_patient_link; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.caregiver_patient_link (id, caregiver_user_id, patient_user_id, created_by, created_at, updated_at, status, link_type, expires_at, notes) FROM stdin;
\.


--
-- TOC entry 3845 (class 0 OID 25127)
-- Dependencies: 268
-- Data for Name: chat_conversations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_conversations (id, conversation_id, patient_id, user_id, chat_type, title, ai_provider_used, ai_model_used, total_tokens_used, is_active, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3847 (class 0 OID 25148)
-- Dependencies: 270
-- Data for Name: chat_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_messages (id, conversation_id, message_type, content, tokens_used, processing_time_ms, temperature_used, context_included, ai_model_used, created_at) FROM stdin;
\.


--
-- TOC entry 3841 (class 0 OID 25078)
-- Dependencies: 264
-- Data for Name: device_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_tokens (id, user_id, fcm_token, device_type, device_id, is_active, created_at, updated_at, last_used_at) FROM stdin;
\.


--
-- TOC entry 3807 (class 0 OID 24712)
-- Dependencies: 230
-- Data for Name: email_verification_token; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.email_verification_token (id, token, user_id, expires_at) FROM stdin;
\.


--
-- TOC entry 3829 (class 0 OID 24943)
-- Dependencies: 252
-- Data for Name: family_member; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.family_member (id, user_id, first_name, last_name, email, phone, address_line1, address_line2, city, state, zip) FROM stdin;
\.


--
-- TOC entry 3821 (class 0 OID 24836)
-- Dependencies: 244
-- Data for Name: family_member_link; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.family_member_link (id, family_user_id, patient_user_id, granted_by, created_at, status, link_type, expires_at, notes, relationship, updated_at, patient_id) FROM stdin;
\.


--
-- TOC entry 3791 (class 0 OID 24576)
-- Dependencies: 214
-- Data for Name: flyway_schema_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success) FROM stdin;
1	1	init	SQL	V1__init.sql	654406129	postgres	2025-09-18 11:58:59.366896	239	t
2	2	enhanced linking and password reset	SQL	V2__enhanced_linking_and_password_reset.sql	-604185791	postgres	2025-09-18 11:58:59.687321	126	t
3	3	add password reset token	SQL	V3__add_password_reset_token.sql	-1296730147	postgres	2025-09-18 11:58:59.852931	18	t
4	4	add patient id to family member link	SQL	V4__add_patient_id_to_family_member_link.sql	-1256747693	postgres	2025-09-18 11:58:59.902271	33	t
5	6	add mood pain log table	SQL	V6__add_mood_pain_log_table.sql	-430000562	postgres	2025-09-18 11:58:59.960245	32	t
6	7	add vital sample table	SQL	V7__add_vital_sample_table.sql	701166194	postgres	2025-09-18 11:59:00.023091	44	t
7	8	add gender and allergies	SQL	V8__add_gender_and_allergies.sql	513819958	postgres	2025-09-18 11:59:00.102999	53	t
8	9	add patient medication table	SQL	V9__add_patient_medication_table.sql	1421547110	postgres	2025-09-18 11:59:00.181406	38	t
9	10	add subscription plans	SQL	V10__add_subscription_plans.sql	511743334	postgres	2025-09-18 11:59:00.244408	16	t
10	11	add vital sample table	SQL	V11__add_vital_sample_table.sql	954450307	postgres	2025-09-18 11:59:00.283662	26	t
11	12	add gender and allergies	SQL	V12__add_gender_and_allergies.sql	1577589063	postgres	2025-09-18 11:59:00.334705	28	t
12	13	add patient medication table	SQL	V13__add_patient_medication_table.sql	1627976371	postgres	2025-09-18 11:59:00.385629	57	t
13	14	add device tokens table	SQL	V14__add_device_tokens_table.sql	615121205	postgres	2025-09-18 11:59:00.46713	38	t
14	21	update pain scale to 0 10	SQL	V21__update_pain_scale_to_0_10.sql	-1873014646	postgres	2025-09-18 11:59:00.528339	9	t
15	22	create ai chat tables	SQL	V22__create_ai_chat_tables.sql	1555289750	postgres	2025-09-18 11:59:00.56162	92	t
16	23	add tasks and templates	SQL	V23__add_tasks_and_templates.sql	-610230285	postgres	2025-09-18 11:59:00.674868	23	t
17	24	load preset task templates	SQL	V24__load_preset_task_templates.sql	-2038353341	postgres	2025-09-18 11:59:00.720783	17	t
18	25	add login fields to users	SQL	V25__add_login_fields_to_users.sql	2014023339	postgres	2025-09-18 11:59:00.761341	6	t
19	26	insert test users	SQL	V26__insert_test_users.sql	-1037694184	postgres	2025-09-18 11:59:00.786393	7	t
\.


--
-- TOC entry 3811 (class 0 OID 24744)
-- Dependencies: 234
-- Data for Name: meal_entry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.meal_entry (id, patient_user_id, caregiver_user_id, calories, taken_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3813 (class 0 OID 24765)
-- Dependencies: 236
-- Data for Name: mood_entry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mood_entry (id, patient_user_id, mood_score, taken_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3831 (class 0 OID 24982)
-- Dependencies: 254
-- Data for Name: mood_pain_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mood_pain_log (id, patient_id, mood_value, pain_value, note, "timestamp", created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3809 (class 0 OID 24726)
-- Dependencies: 232
-- Data for Name: password_reset_token; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.password_reset_token (id, user_id, token_hash, expires_at, used, created_at) FROM stdin;
\.


--
-- TOC entry 3797 (class 0 OID 24621)
-- Dependencies: 220
-- Data for Name: patient; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient (id, user_id, first_name, last_name, dob, email, phone, address_line1, address_line2, city, state, zip, sex, medical_notes, relationship, gender) FROM stdin;
\.


--
-- TOC entry 3843 (class 0 OID 25101)
-- Dependencies: 266
-- Data for Name: patient_ai_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_ai_config (id, patient_id, ai_provider, openai_model, deepseek_model, max_tokens, temperature, conversation_history_limit, include_vitals_by_default, include_medications_by_default, include_notes_by_default, include_mood_pain_logs_by_default, include_allergies_by_default, is_active, system_prompt, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3835 (class 0 OID 25019)
-- Dependencies: 258
-- Data for Name: patient_allergy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_allergy (id, patient_id, allergen, allergy_type, severity, reaction, notes, diagnosed_date, is_active, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3839 (class 0 OID 25058)
-- Dependencies: 262
-- Data for Name: patient_caregiver; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_caregiver (id, patient_id, caregiver_user_id, relationship_type, created_at) FROM stdin;
\.


--
-- TOC entry 3837 (class 0 OID 25038)
-- Dependencies: 260
-- Data for Name: patient_medication; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_medication (id, patient_id, medication_name, dosage, frequency, route, medication_type, prescribed_by, prescribed_date, start_date, end_date, notes, is_active, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3805 (class 0 OID 24691)
-- Dependencies: 228
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment (id, subscription_id, payment_method_id, amount_cents, stripe_session_id, stripe_payment_intent_id, status, attempted_at) FROM stdin;
\.


--
-- TOC entry 3803 (class 0 OID 24677)
-- Dependencies: 226
-- Data for Name: payment_method; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment_method (id, user_id, provider, stripe_token, last4, brand, exp_month, exp_year, created_at) FROM stdin;
\.


--
-- TOC entry 3799 (class 0 OID 24645)
-- Dependencies: 222
-- Data for Name: plan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.plan (id, code, name, price_cents, billing_period, is_active) FROM stdin;
3	price_1RmqWxELoozGI1YxQql5rsvN	Premium Plan	3000	MONTH	t
4	plan_SbkhH3AATKabKy	Standard Plan	2000	MONTH	t
5	plan_SbkhIoC5wy5iwB	Premium Plan	3000	MONTH	t
\.


--
-- TOC entry 3801 (class 0 OID 24657)
-- Dependencies: 224
-- Data for Name: subscription; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subscription (id, user_id, plan_id, status, started_at, current_period_end) FROM stdin;
\.


--
-- TOC entry 3817 (class 0 OID 24797)
-- Dependencies: 240
-- Data for Name: summary_metrics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.summary_metrics (id, patient_user_id, period_start, period_end, adherence_rate, avg_heart_rate, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3819 (class 0 OID 24814)
-- Dependencies: 242
-- Data for Name: symptom_entry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.symptom_entry (id, patient_user_id, caregiver_user_id, symptom_key, symptom_value, severity, taken_at, completed, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3849 (class 0 OID 25168)
-- Dependencies: 272
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tasks (id, patient_id, name, description, date, time_of_day, iscompleted, task_type, frequency, task_interval, do_count, days_of_week, status, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3851 (class 0 OID 25183)
-- Dependencies: 274
-- Data for Name: templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.templates (id, name, description, frequency, task_interval, do_count, days_of_week, time_of_day, icon, notifications, created_at, updated_at) FROM stdin;
1	Medication	Medication schedules and dosages.	DAILY	-1	-1	\N	08:00:00	58329	\N	2025-09-18 11:59:00.731296	2025-09-18 11:59:00.731296
2	Meals	Meal plans and nutritional information.	DAILY	-1	-1	\N	08:00:00	57946	\N	2025-09-18 11:59:00.731296	2025-09-18 11:59:00.731296
3	Daily Walk	Managing daily walk schedules and tracking.	DAILY	-1	-1	\N	10:00:00	57825	\N	2025-09-18 11:59:00.731296	2025-09-18 11:59:00.731296
4	Sleep	Manage sleep schedules	DAILY	-1	-1	\N	20:30:00	57563	\N	2025-09-18 11:59:00.731296	2025-09-18 11:59:00.731296
5	Bathing	Manage bathing schedules and assistance.	DAILY	-1	-1	\N	08:00:00	57551	\N	2025-09-18 11:59:00.731296	2025-09-18 11:59:00.731296
\.


--
-- TOC entry 3825 (class 0 OID 24888)
-- Dependencies: 248
-- Data for Name: user_achievements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_achievements (id, user_id, achievement_id, date_earned, progress) FROM stdin;
\.


--
-- TOC entry 3793 (class 0 OID 24586)
-- Dependencies: 216
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, email_verified, password, password_hash, role, status, created_at, updated_at, name, verification_token, stripe_customer_id, last_login, profile_image_url, last_login_date, login_streak, leaderboard_opt_in) FROM stdin;
1	test@caregiver	t	1234	$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.	CAREGIVER	ACTIVE	2025-09-18 11:59:00.792608	2025-09-18 11:59:00.792608	Test Caregiver	\N	\N	\N	\N	\N	0	t
2	test@patient	t	1234	$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.	PATIENT	ACTIVE	2025-09-18 11:59:00.792608	2025-09-18 11:59:00.792608	Test Patient	\N	\N	\N	\N	\N	0	t
\.


--
-- TOC entry 3833 (class 0 OID 25002)
-- Dependencies: 256
-- Data for Name: vital_sample; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vital_sample (id, patient_id, "timestamp", heart_rate, spo2, systolic, diastolic, weight, mood_value, pain_value, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3815 (class 0 OID 24781)
-- Dependencies: 238
-- Data for Name: wearable_metric; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wearable_metric (id, patient_user_id, metric, metric_value, recorded_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3920 (class 0 OID 0)
-- Dependencies: 245
-- Name: achievement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.achievement_id_seq', 1, false);


--
-- TOC entry 3921 (class 0 OID 0)
-- Dependencies: 217
-- Name: caregiver_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.caregiver_id_seq', 1, false);


--
-- TOC entry 3922 (class 0 OID 0)
-- Dependencies: 249
-- Name: caregiver_patient_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.caregiver_patient_link_id_seq', 1, false);


--
-- TOC entry 3923 (class 0 OID 0)
-- Dependencies: 267
-- Name: chat_conversations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_conversations_id_seq', 1, false);


--
-- TOC entry 3924 (class 0 OID 0)
-- Dependencies: 269
-- Name: chat_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_messages_id_seq', 1, false);


--
-- TOC entry 3925 (class 0 OID 0)
-- Dependencies: 263
-- Name: device_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.device_tokens_id_seq', 1, false);


--
-- TOC entry 3926 (class 0 OID 0)
-- Dependencies: 229
-- Name: email_verification_token_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.email_verification_token_id_seq', 1, false);


--
-- TOC entry 3927 (class 0 OID 0)
-- Dependencies: 251
-- Name: family_member_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.family_member_id_seq', 1, false);


--
-- TOC entry 3928 (class 0 OID 0)
-- Dependencies: 243
-- Name: family_member_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.family_member_link_id_seq', 1, false);


--
-- TOC entry 3929 (class 0 OID 0)
-- Dependencies: 233
-- Name: meal_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.meal_entry_id_seq', 1, false);


--
-- TOC entry 3930 (class 0 OID 0)
-- Dependencies: 235
-- Name: mood_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mood_entry_id_seq', 1, false);


--
-- TOC entry 3931 (class 0 OID 0)
-- Dependencies: 253
-- Name: mood_pain_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mood_pain_log_id_seq', 1, false);


--
-- TOC entry 3932 (class 0 OID 0)
-- Dependencies: 231
-- Name: password_reset_token_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.password_reset_token_id_seq', 1, false);


--
-- TOC entry 3933 (class 0 OID 0)
-- Dependencies: 265
-- Name: patient_ai_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_ai_config_id_seq', 1, false);


--
-- TOC entry 3934 (class 0 OID 0)
-- Dependencies: 257
-- Name: patient_allergy_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_allergy_id_seq', 1, false);


--
-- TOC entry 3935 (class 0 OID 0)
-- Dependencies: 261
-- Name: patient_caregiver_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_caregiver_id_seq', 1, false);


--
-- TOC entry 3936 (class 0 OID 0)
-- Dependencies: 219
-- Name: patient_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_id_seq', 1, false);


--
-- TOC entry 3937 (class 0 OID 0)
-- Dependencies: 259
-- Name: patient_medication_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_medication_id_seq', 1, false);


--
-- TOC entry 3938 (class 0 OID 0)
-- Dependencies: 227
-- Name: payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_id_seq', 1, false);


--
-- TOC entry 3939 (class 0 OID 0)
-- Dependencies: 225
-- Name: payment_method_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_method_id_seq', 1, false);


--
-- TOC entry 3940 (class 0 OID 0)
-- Dependencies: 221
-- Name: plan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.plan_id_seq', 6, true);


--
-- TOC entry 3941 (class 0 OID 0)
-- Dependencies: 223
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subscription_id_seq', 1, false);


--
-- TOC entry 3942 (class 0 OID 0)
-- Dependencies: 239
-- Name: summary_metrics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.summary_metrics_id_seq', 1, false);


--
-- TOC entry 3943 (class 0 OID 0)
-- Dependencies: 241
-- Name: symptom_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.symptom_entry_id_seq', 1, false);


--
-- TOC entry 3944 (class 0 OID 0)
-- Dependencies: 271
-- Name: tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tasks_id_seq', 1, false);


--
-- TOC entry 3945 (class 0 OID 0)
-- Dependencies: 273
-- Name: templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.templates_id_seq', 5, true);


--
-- TOC entry 3946 (class 0 OID 0)
-- Dependencies: 247
-- Name: user_achievements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_achievements_id_seq', 1, false);


--
-- TOC entry 3947 (class 0 OID 0)
-- Dependencies: 215
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- TOC entry 3948 (class 0 OID 0)
-- Dependencies: 255
-- Name: vital_sample_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vital_sample_id_seq', 1, false);


--
-- TOC entry 3949 (class 0 OID 0)
-- Dependencies: 237
-- Name: wearable_metric_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wearable_metric_id_seq', 1, false);


--
-- TOC entry 3545 (class 2606 OID 24886)
-- Name: achievement achievement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.achievement
    ADD CONSTRAINT achievement_pkey PRIMARY KEY (id);


--
-- TOC entry 3484 (class 2606 OID 24614)
-- Name: caregiver caregiver_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver
    ADD CONSTRAINT caregiver_email_key UNIQUE (email);


--
-- TOC entry 3549 (class 2606 OID 24926)
-- Name: caregiver_patient_link caregiver_patient_link_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver_patient_link
    ADD CONSTRAINT caregiver_patient_link_pkey PRIMARY KEY (id);


--
-- TOC entry 3486 (class 2606 OID 24610)
-- Name: caregiver caregiver_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver
    ADD CONSTRAINT caregiver_pkey PRIMARY KEY (id);


--
-- TOC entry 3488 (class 2606 OID 24612)
-- Name: caregiver caregiver_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver
    ADD CONSTRAINT caregiver_user_id_key UNIQUE (user_id);


--
-- TOC entry 3595 (class 2606 OID 25141)
-- Name: chat_conversations chat_conversations_conversation_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_conversations
    ADD CONSTRAINT chat_conversations_conversation_id_key UNIQUE (conversation_id);


--
-- TOC entry 3597 (class 2606 OID 25139)
-- Name: chat_conversations chat_conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_conversations
    ADD CONSTRAINT chat_conversations_pkey PRIMARY KEY (id);


--
-- TOC entry 3604 (class 2606 OID 25157)
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);


--
-- TOC entry 3584 (class 2606 OID 25088)
-- Name: device_tokens device_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_tokens
    ADD CONSTRAINT device_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 3586 (class 2606 OID 25090)
-- Name: device_tokens device_tokens_user_id_device_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_tokens
    ADD CONSTRAINT device_tokens_user_id_device_id_key UNIQUE (user_id, device_id);


--
-- TOC entry 3506 (class 2606 OID 24717)
-- Name: email_verification_token email_verification_token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verification_token
    ADD CONSTRAINT email_verification_token_pkey PRIMARY KEY (id);


--
-- TOC entry 3508 (class 2606 OID 24719)
-- Name: email_verification_token email_verification_token_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verification_token
    ADD CONSTRAINT email_verification_token_token_key UNIQUE (token);


--
-- TOC entry 3555 (class 2606 OID 24954)
-- Name: family_member family_member_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member
    ADD CONSTRAINT family_member_email_key UNIQUE (email);


--
-- TOC entry 3534 (class 2606 OID 24842)
-- Name: family_member_link family_member_link_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT family_member_link_pkey PRIMARY KEY (id);


--
-- TOC entry 3557 (class 2606 OID 24950)
-- Name: family_member family_member_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member
    ADD CONSTRAINT family_member_pkey PRIMARY KEY (id);


--
-- TOC entry 3559 (class 2606 OID 24952)
-- Name: family_member family_member_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member
    ADD CONSTRAINT family_member_user_id_key UNIQUE (user_id);


--
-- TOC entry 3477 (class 2606 OID 24583)
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- TOC entry 3518 (class 2606 OID 24752)
-- Name: meal_entry meal_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_entry
    ADD CONSTRAINT meal_entry_pkey PRIMARY KEY (id);


--
-- TOC entry 3521 (class 2606 OID 24773)
-- Name: mood_entry mood_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_entry
    ADD CONSTRAINT mood_entry_pkey PRIMARY KEY (id);


--
-- TOC entry 3563 (class 2606 OID 24993)
-- Name: mood_pain_log mood_pain_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_pain_log
    ADD CONSTRAINT mood_pain_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3513 (class 2606 OID 24733)
-- Name: password_reset_token password_reset_token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_token
    ADD CONSTRAINT password_reset_token_pkey PRIMARY KEY (id);


--
-- TOC entry 3515 (class 2606 OID 24735)
-- Name: password_reset_token password_reset_token_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_token
    ADD CONSTRAINT password_reset_token_token_hash_key UNIQUE (token_hash);


--
-- TOC entry 3593 (class 2606 OID 25123)
-- Name: patient_ai_config patient_ai_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_ai_config
    ADD CONSTRAINT patient_ai_config_pkey PRIMARY KEY (id);


--
-- TOC entry 3572 (class 2606 OID 25028)
-- Name: patient_allergy patient_allergy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_allergy
    ADD CONSTRAINT patient_allergy_pkey PRIMARY KEY (id);


--
-- TOC entry 3580 (class 2606 OID 25064)
-- Name: patient_caregiver patient_caregiver_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_caregiver
    ADD CONSTRAINT patient_caregiver_pkey PRIMARY KEY (id);


--
-- TOC entry 3490 (class 2606 OID 24633)
-- Name: patient patient_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_email_key UNIQUE (email);


--
-- TOC entry 3578 (class 2606 OID 25047)
-- Name: patient_medication patient_medication_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_medication
    ADD CONSTRAINT patient_medication_pkey PRIMARY KEY (id);


--
-- TOC entry 3492 (class 2606 OID 24629)
-- Name: patient patient_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_pkey PRIMARY KEY (id);


--
-- TOC entry 3494 (class 2606 OID 24631)
-- Name: patient patient_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_user_id_key UNIQUE (user_id);


--
-- TOC entry 3502 (class 2606 OID 24684)
-- Name: payment_method payment_method_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_method
    ADD CONSTRAINT payment_method_pkey PRIMARY KEY (id);


--
-- TOC entry 3504 (class 2606 OID 24700)
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (id);


--
-- TOC entry 3496 (class 2606 OID 24655)
-- Name: plan plan_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plan
    ADD CONSTRAINT plan_code_key UNIQUE (code);


--
-- TOC entry 3498 (class 2606 OID 24653)
-- Name: plan plan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plan
    ADD CONSTRAINT plan_pkey PRIMARY KEY (id);


--
-- TOC entry 3500 (class 2606 OID 24665)
-- Name: subscription subscription_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_pkey PRIMARY KEY (id);


--
-- TOC entry 3527 (class 2606 OID 24806)
-- Name: summary_metrics summary_metrics_patient_user_id_period_start_period_end_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.summary_metrics
    ADD CONSTRAINT summary_metrics_patient_user_id_period_start_period_end_key UNIQUE (patient_user_id, period_start, period_end);


--
-- TOC entry 3529 (class 2606 OID 24804)
-- Name: summary_metrics summary_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.summary_metrics
    ADD CONSTRAINT summary_metrics_pkey PRIMARY KEY (id);


--
-- TOC entry 3532 (class 2606 OID 24823)
-- Name: symptom_entry symptom_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symptom_entry
    ADD CONSTRAINT symptom_entry_pkey PRIMARY KEY (id);


--
-- TOC entry 3608 (class 2606 OID 25181)
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- TOC entry 3610 (class 2606 OID 25192)
-- Name: templates templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.templates
    ADD CONSTRAINT templates_pkey PRIMARY KEY (id);


--
-- TOC entry 3541 (class 2606 OID 24980)
-- Name: family_member_link uk_family_member_link_patient_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT uk_family_member_link_patient_unique UNIQUE (family_user_id, patient_id);


--
-- TOC entry 3950 (class 0 OID 0)
-- Dependencies: 3541
-- Name: CONSTRAINT uk_family_member_link_patient_unique ON family_member_link; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT uk_family_member_link_patient_unique ON public.family_member_link IS 'Prevents duplicate family member-patient links using patient_id';


--
-- TOC entry 3543 (class 2606 OID 24978)
-- Name: family_member_link uk_family_member_link_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT uk_family_member_link_unique UNIQUE (family_user_id, patient_user_id);


--
-- TOC entry 3951 (class 0 OID 0)
-- Dependencies: 3543
-- Name: CONSTRAINT uk_family_member_link_unique ON family_member_link; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT uk_family_member_link_unique ON public.family_member_link IS 'Prevents duplicate family member-patient links';


--
-- TOC entry 3582 (class 2606 OID 25066)
-- Name: patient_caregiver uk_patient_caregiver; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_caregiver
    ADD CONSTRAINT uk_patient_caregiver UNIQUE (patient_id, caregiver_user_id);


--
-- TOC entry 3547 (class 2606 OID 24893)
-- Name: user_achievements user_achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_pkey PRIMARY KEY (id);


--
-- TOC entry 3480 (class 2606 OID 24601)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3482 (class 2606 OID 24599)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3567 (class 2606 OID 25010)
-- Name: vital_sample vital_sample_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vital_sample
    ADD CONSTRAINT vital_sample_pkey PRIMARY KEY (id);


--
-- TOC entry 3524 (class 2606 OID 24789)
-- Name: wearable_metric wearable_metric_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wearable_metric
    ADD CONSTRAINT wearable_metric_pkey PRIMARY KEY (id);


--
-- TOC entry 3478 (class 1259 OID 24584)
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- TOC entry 3550 (class 1259 OID 24960)
-- Name: idx_caregiver_patient_link_caregiver; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_caregiver_patient_link_caregiver ON public.caregiver_patient_link USING btree (caregiver_user_id);


--
-- TOC entry 3551 (class 1259 OID 24963)
-- Name: idx_caregiver_patient_link_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_caregiver_patient_link_expires ON public.caregiver_patient_link USING btree (expires_at);


--
-- TOC entry 3552 (class 1259 OID 24961)
-- Name: idx_caregiver_patient_link_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_caregiver_patient_link_patient ON public.caregiver_patient_link USING btree (patient_user_id);


--
-- TOC entry 3553 (class 1259 OID 24962)
-- Name: idx_caregiver_patient_link_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_caregiver_patient_link_status ON public.caregiver_patient_link USING btree (status);


--
-- TOC entry 3598 (class 1259 OID 25142)
-- Name: idx_chat_conversations_conversation_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_conversations_conversation_id ON public.chat_conversations USING btree (conversation_id);


--
-- TOC entry 3599 (class 1259 OID 25145)
-- Name: idx_chat_conversations_patient_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_conversations_patient_active ON public.chat_conversations USING btree (patient_id, is_active);


--
-- TOC entry 3600 (class 1259 OID 25143)
-- Name: idx_chat_conversations_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_conversations_patient_id ON public.chat_conversations USING btree (patient_id);


--
-- TOC entry 3601 (class 1259 OID 25146)
-- Name: idx_chat_conversations_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_conversations_updated_at ON public.chat_conversations USING btree (updated_at DESC);


--
-- TOC entry 3602 (class 1259 OID 25144)
-- Name: idx_chat_conversations_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_conversations_user_id ON public.chat_conversations USING btree (user_id);


--
-- TOC entry 3605 (class 1259 OID 25163)
-- Name: idx_chat_messages_conversation_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_messages_conversation_id ON public.chat_messages USING btree (conversation_id);


--
-- TOC entry 3606 (class 1259 OID 25164)
-- Name: idx_chat_messages_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_messages_created_at ON public.chat_messages USING btree (conversation_id, created_at);


--
-- TOC entry 3587 (class 1259 OID 25098)
-- Name: idx_device_tokens_device_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_tokens_device_id ON public.device_tokens USING btree (device_id);


--
-- TOC entry 3588 (class 1259 OID 25097)
-- Name: idx_device_tokens_fcm_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_tokens_fcm_token ON public.device_tokens USING btree (fcm_token);


--
-- TOC entry 3589 (class 1259 OID 25096)
-- Name: idx_device_tokens_user_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_tokens_user_active ON public.device_tokens USING btree (user_id, is_active);


--
-- TOC entry 3535 (class 1259 OID 24967)
-- Name: idx_family_member_link_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_family_member_link_expires ON public.family_member_link USING btree (expires_at);


--
-- TOC entry 3536 (class 1259 OID 24964)
-- Name: idx_family_member_link_family; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_family_member_link_family ON public.family_member_link USING btree (family_user_id);


--
-- TOC entry 3537 (class 1259 OID 24965)
-- Name: idx_family_member_link_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_family_member_link_patient ON public.family_member_link USING btree (patient_user_id);


--
-- TOC entry 3538 (class 1259 OID 24971)
-- Name: idx_family_member_link_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_family_member_link_patient_id ON public.family_member_link USING btree (patient_id);


--
-- TOC entry 3539 (class 1259 OID 24966)
-- Name: idx_family_member_link_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_family_member_link_status ON public.family_member_link USING btree (status);


--
-- TOC entry 3516 (class 1259 OID 24763)
-- Name: idx_meal_patient_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meal_patient_time ON public.meal_entry USING btree (patient_user_id, taken_at);


--
-- TOC entry 3560 (class 1259 OID 24999)
-- Name: idx_mood_pain_patient_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mood_pain_patient_timestamp ON public.mood_pain_log USING btree (patient_id, "timestamp");


--
-- TOC entry 3561 (class 1259 OID 25000)
-- Name: idx_mood_pain_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mood_pain_timestamp ON public.mood_pain_log USING btree ("timestamp");


--
-- TOC entry 3519 (class 1259 OID 24779)
-- Name: idx_mood_patient_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mood_patient_time ON public.mood_entry USING btree (patient_user_id, taken_at);


--
-- TOC entry 3509 (class 1259 OID 24904)
-- Name: idx_password_reset_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_password_reset_token ON public.password_reset_token USING btree (token_hash);


--
-- TOC entry 3510 (class 1259 OID 24742)
-- Name: idx_password_reset_token_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_password_reset_token_expires ON public.password_reset_token USING btree (expires_at);


--
-- TOC entry 3511 (class 1259 OID 24741)
-- Name: idx_password_reset_token_hash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_password_reset_token_hash ON public.password_reset_token USING btree (token_hash);


--
-- TOC entry 3590 (class 1259 OID 25125)
-- Name: idx_patient_ai_config_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_ai_config_active ON public.patient_ai_config USING btree (patient_id, is_active);


--
-- TOC entry 3591 (class 1259 OID 25124)
-- Name: idx_patient_ai_config_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_ai_config_patient_id ON public.patient_ai_config USING btree (patient_id);


--
-- TOC entry 3568 (class 1259 OID 25035)
-- Name: idx_patient_allergy_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_allergy_active ON public.patient_allergy USING btree (patient_id, is_active);


--
-- TOC entry 3569 (class 1259 OID 25036)
-- Name: idx_patient_allergy_allergen; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_allergy_allergen ON public.patient_allergy USING btree (allergen);


--
-- TOC entry 3570 (class 1259 OID 25034)
-- Name: idx_patient_allergy_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_allergy_patient_id ON public.patient_allergy USING btree (patient_id);


--
-- TOC entry 3573 (class 1259 OID 25054)
-- Name: idx_patient_medication_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_medication_active ON public.patient_medication USING btree (patient_id, is_active);


--
-- TOC entry 3574 (class 1259 OID 25056)
-- Name: idx_patient_medication_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_medication_name ON public.patient_medication USING btree (medication_name);


--
-- TOC entry 3575 (class 1259 OID 25053)
-- Name: idx_patient_medication_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_medication_patient_id ON public.patient_medication USING btree (patient_id);


--
-- TOC entry 3576 (class 1259 OID 25055)
-- Name: idx_patient_medication_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_medication_type ON public.patient_medication USING btree (medication_type);


--
-- TOC entry 3525 (class 1259 OID 24812)
-- Name: idx_summary_patient_end; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_summary_patient_end ON public.summary_metrics USING btree (patient_user_id, period_end);


--
-- TOC entry 3530 (class 1259 OID 24834)
-- Name: idx_symptom_patient_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_symptom_patient_time ON public.symptom_entry USING btree (patient_user_id, taken_at);


--
-- TOC entry 3564 (class 1259 OID 25016)
-- Name: idx_vital_sample_patient_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vital_sample_patient_timestamp ON public.vital_sample USING btree (patient_id, "timestamp");


--
-- TOC entry 3565 (class 1259 OID 25017)
-- Name: idx_vital_sample_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vital_sample_timestamp ON public.vital_sample USING btree ("timestamp");


--
-- TOC entry 3522 (class 1259 OID 24795)
-- Name: idx_wearable_patient_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wearable_patient_time ON public.wearable_metric USING btree (patient_user_id, recorded_at);


--
-- TOC entry 3646 (class 2620 OID 24970)
-- Name: caregiver_patient_link update_caregiver_patient_link_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_caregiver_patient_link_updated_at BEFORE UPDATE ON public.caregiver_patient_link FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3648 (class 2620 OID 25166)
-- Name: chat_conversations update_chat_conversations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_chat_conversations_updated_at BEFORE UPDATE ON public.chat_conversations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3645 (class 2620 OID 24969)
-- Name: family_member_link update_family_member_link_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_family_member_link_updated_at BEFORE UPDATE ON public.family_member_link FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3647 (class 2620 OID 25165)
-- Name: patient_ai_config update_patient_ai_config_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_patient_ai_config_updated_at BEFORE UPDATE ON public.patient_ai_config FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3633 (class 2606 OID 24927)
-- Name: caregiver_patient_link caregiver_patient_link_caregiver_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver_patient_link
    ADD CONSTRAINT caregiver_patient_link_caregiver_user_id_fkey FOREIGN KEY (caregiver_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3634 (class 2606 OID 24937)
-- Name: caregiver_patient_link caregiver_patient_link_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver_patient_link
    ADD CONSTRAINT caregiver_patient_link_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3635 (class 2606 OID 24932)
-- Name: caregiver_patient_link caregiver_patient_link_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver_patient_link
    ADD CONSTRAINT caregiver_patient_link_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3611 (class 2606 OID 24615)
-- Name: caregiver caregiver_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver
    ADD CONSTRAINT caregiver_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3644 (class 2606 OID 25158)
-- Name: chat_messages chat_messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.chat_conversations(id) ON DELETE CASCADE;


--
-- TOC entry 3643 (class 2606 OID 25091)
-- Name: device_tokens device_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_tokens
    ADD CONSTRAINT device_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3627 (class 2606 OID 24843)
-- Name: family_member_link family_member_link_family_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT family_member_link_family_user_id_fkey FOREIGN KEY (family_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3628 (class 2606 OID 24853)
-- Name: family_member_link family_member_link_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT family_member_link_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 3629 (class 2606 OID 24848)
-- Name: family_member_link family_member_link_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT family_member_link_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3636 (class 2606 OID 24955)
-- Name: family_member family_member_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member
    ADD CONSTRAINT family_member_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3641 (class 2606 OID 25072)
-- Name: patient_caregiver fk_caregiver; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_caregiver
    ADD CONSTRAINT fk_caregiver FOREIGN KEY (caregiver_user_id) REFERENCES public.users(id);


--
-- TOC entry 3618 (class 2606 OID 24720)
-- Name: email_verification_token fk_email_verification_token_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verification_token
    ADD CONSTRAINT fk_email_verification_token_user FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3630 (class 2606 OID 24972)
-- Name: family_member_link fk_family_member_link_patient_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT fk_family_member_link_patient_id FOREIGN KEY (patient_id) REFERENCES public.patient(id);


--
-- TOC entry 3619 (class 2606 OID 24736)
-- Name: password_reset_token fk_password_reset_token_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_token
    ADD CONSTRAINT fk_password_reset_token_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3642 (class 2606 OID 25067)
-- Name: patient_caregiver fk_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_caregiver
    ADD CONSTRAINT fk_patient FOREIGN KEY (patient_id) REFERENCES public.patient(id);


--
-- TOC entry 3639 (class 2606 OID 25029)
-- Name: patient_allergy fk_patient_allergy_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_allergy
    ADD CONSTRAINT fk_patient_allergy_patient FOREIGN KEY (patient_id) REFERENCES public.patient(id) ON DELETE CASCADE;


--
-- TOC entry 3640 (class 2606 OID 25048)
-- Name: patient_medication fk_patient_medication_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_medication
    ADD CONSTRAINT fk_patient_medication_patient FOREIGN KEY (patient_id) REFERENCES public.patient(id) ON DELETE CASCADE;


--
-- TOC entry 3638 (class 2606 OID 25011)
-- Name: vital_sample fk_vital_sample_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vital_sample
    ADD CONSTRAINT fk_vital_sample_patient FOREIGN KEY (patient_id) REFERENCES public.patient(id) ON DELETE CASCADE;


--
-- TOC entry 3620 (class 2606 OID 24758)
-- Name: meal_entry meal_entry_caregiver_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_entry
    ADD CONSTRAINT meal_entry_caregiver_user_id_fkey FOREIGN KEY (caregiver_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 3621 (class 2606 OID 24753)
-- Name: meal_entry meal_entry_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_entry
    ADD CONSTRAINT meal_entry_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3622 (class 2606 OID 24774)
-- Name: mood_entry mood_entry_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_entry
    ADD CONSTRAINT mood_entry_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3637 (class 2606 OID 24994)
-- Name: mood_pain_log mood_pain_log_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_pain_log
    ADD CONSTRAINT mood_pain_log_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patient(id) ON DELETE CASCADE;


--
-- TOC entry 3612 (class 2606 OID 24634)
-- Name: patient patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3615 (class 2606 OID 24685)
-- Name: payment_method payment_method_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_method
    ADD CONSTRAINT payment_method_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3616 (class 2606 OID 24706)
-- Name: payment payment_payment_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_payment_method_id_fkey FOREIGN KEY (payment_method_id) REFERENCES public.payment_method(id) ON DELETE SET NULL;


--
-- TOC entry 3617 (class 2606 OID 24701)
-- Name: payment payment_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscription(id) ON DELETE CASCADE;


--
-- TOC entry 3613 (class 2606 OID 24671)
-- Name: subscription subscription_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.plan(id);


--
-- TOC entry 3614 (class 2606 OID 24666)
-- Name: subscription subscription_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3624 (class 2606 OID 24807)
-- Name: summary_metrics summary_metrics_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.summary_metrics
    ADD CONSTRAINT summary_metrics_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3625 (class 2606 OID 24829)
-- Name: symptom_entry symptom_entry_caregiver_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symptom_entry
    ADD CONSTRAINT symptom_entry_caregiver_user_id_fkey FOREIGN KEY (caregiver_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 3626 (class 2606 OID 24824)
-- Name: symptom_entry symptom_entry_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symptom_entry
    ADD CONSTRAINT symptom_entry_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3631 (class 2606 OID 24899)
-- Name: user_achievements user_achievements_achievement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_achievement_id_fkey FOREIGN KEY (achievement_id) REFERENCES public.achievement(id);


--
-- TOC entry 3632 (class 2606 OID 24894)
-- Name: user_achievements user_achievements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3623 (class 2606 OID 24790)
-- Name: wearable_metric wearable_metric_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wearable_metric
    ADD CONSTRAINT wearable_metric_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


-- Completed on 2025-09-18 15:59:48 UTC

--
-- PostgreSQL database dump complete
--

\unrestrict Iz0rd6p4XFsL9cREIy6G7mCLoTo0wkEP2aizcn5aLw0OOSqjSeFbFHgVSQdDdDk

