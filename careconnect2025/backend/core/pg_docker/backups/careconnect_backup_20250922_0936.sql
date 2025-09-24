--
-- PostgreSQL database dump
--

\restrict TQybt990hYGNFb21Y2qFpXzZLX0EFE9QImfJ1cZW298iSOAfWyRD8SRaBaSTR9w

-- Dumped from database version 15.14 (Debian 15.14-1.pgdg12+1)
-- Dumped by pg_dump version 15.14 (Debian 15.14-1.pgdg12+1)

-- Started on 2025-09-23 01:36:03 UTC

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
-- TOC entry 4013 (class 1262 OID 16384)
-- Name: careconnect; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE careconnect WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE careconnect OWNER TO postgres;

\unrestrict TQybt990hYGNFb21Y2qFpXzZLX0EFE9QImfJ1cZW298iSOAfWyRD8SRaBaSTR9w
\connect careconnect
\restrict TQybt990hYGNFb21Y2qFpXzZLX0EFE9QImfJ1cZW298iSOAfWyRD8SRaBaSTR9w

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
-- TOC entry 314 (class 1255 OID 24968)
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
    description character varying(255),
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
-- TOC entry 4014 (class 0 OID 0)
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
    first_name character varying(255),
    last_name character varying(255),
    dob character varying(255),
    email character varying(255) NOT NULL,
    phone character varying(255),
    address_line1 character varying(255),
    address_line2 character varying(255),
    city character varying(255),
    state character varying(255),
    zip character varying(255),
    caregiver_type character varying(255) NOT NULL,
    license_number character varying(255),
    issuing_state character varying(255),
    years_experience integer,
    gender character varying(255),
    line1 character varying(255),
    line2 character varying(255)
);


ALTER TABLE public.caregiver OWNER TO postgres;

--
-- TOC entry 4015 (class 0 OID 0)
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
-- TOC entry 4016 (class 0 OID 0)
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
    status character varying(255) DEFAULT 'ACTIVE'::character varying,
    link_type character varying(255) DEFAULT 'PERMANENT'::character varying,
    expires_at timestamp without time zone,
    notes character varying(255),
    CONSTRAINT caregiver_patient_link_link_type_check CHECK (((link_type)::text = ANY (ARRAY[('PERMANENT'::character varying)::text, ('TEMPORARY'::character varying)::text, ('EMERGENCY'::character varying)::text]))),
    CONSTRAINT caregiver_patient_link_status_check CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('SUSPENDED'::character varying)::text, ('REVOKED'::character varying)::text, ('EXPIRED'::character varying)::text])))
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
-- TOC entry 4017 (class 0 OID 0)
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
    conversation_id character varying(255) NOT NULL,
    patient_id bigint NOT NULL,
    user_id bigint NOT NULL,
    chat_type character varying(255) DEFAULT 'GENERAL_SUPPORT'::character varying NOT NULL,
    title character varying(255),
    ai_provider_used character varying(255),
    ai_model_used character varying(255),
    total_tokens_used integer DEFAULT 0,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chat_conversations_ai_provider_used_check CHECK (((ai_provider_used)::text = ANY (ARRAY[('OPENAI'::character varying)::text, ('DEEPSEEK'::character varying)::text]))),
    CONSTRAINT chat_conversations_chat_type_check CHECK (((chat_type)::text = ANY (ARRAY[('MEDICAL_CONSULTATION'::character varying)::text, ('GENERAL_SUPPORT'::character varying)::text, ('MEDICATION_INQUIRY'::character varying)::text, ('MOOD_PAIN_SUPPORT'::character varying)::text, ('EMERGENCY_GUIDANCE'::character varying)::text, ('LIFESTYLE_ADVICE'::character varying)::text])))
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
-- TOC entry 4018 (class 0 OID 0)
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
    message_type character varying(255) NOT NULL,
    content text NOT NULL,
    tokens_used integer,
    processing_time_ms bigint,
    temperature_used double precision,
    context_included text,
    ai_model_used character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chat_messages_message_type_check CHECK (((message_type)::text = ANY (ARRAY[('USER'::character varying)::text, ('ASSISTANT'::character varying)::text, ('SYSTEM'::character varying)::text])))
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
-- TOC entry 4019 (class 0 OID 0)
-- Dependencies: 269
-- Name: chat_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chat_messages_id_seq OWNED BY public.chat_messages.id;


--
-- TOC entry 276 (class 1259 OID 25245)
-- Name: clinical_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clinical_notes (
    id bigint NOT NULL,
    caregiver_id bigint,
    content text,
    created_at timestamp(6) without time zone,
    is_active boolean,
    note_type character varying(255),
    patient_id bigint NOT NULL,
    subject character varying(255),
    updated_at timestamp(6) without time zone
);


ALTER TABLE public.clinical_notes OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 25244)
-- Name: clinical_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.clinical_notes ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.clinical_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 278 (class 1259 OID 25253)
-- Name: comment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comment (
    id bigint NOT NULL,
    content character varying(255),
    created_at timestamp(6) without time zone,
    post_id bigint,
    user_id bigint,
    username character varying(255)
);


ALTER TABLE public.comment OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 25252)
-- Name: comment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.comment ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.comment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 280 (class 1259 OID 25261)
-- Name: connection_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.connection_requests (
    id bigint NOT NULL,
    message character varying(255),
    relationship_type character varying(255),
    requested_at timestamp(6) with time zone,
    responded_at timestamp(6) with time zone,
    status character varying(255) NOT NULL,
    token character varying(255),
    caregiver_id bigint,
    patient_id bigint
);


ALTER TABLE public.connection_requests OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 25260)
-- Name: connection_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.connection_requests ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.connection_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 264 (class 1259 OID 25078)
-- Name: device_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    fcm_token character varying(500) NOT NULL,
    device_type character varying(255) NOT NULL,
    device_id character varying(255) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone,
    last_used_at timestamp without time zone,
    CONSTRAINT device_tokens_device_type_check CHECK (((device_type)::text = ANY (ARRAY[('ANDROID'::character varying)::text, ('IOS'::character varying)::text, ('WEB'::character varying)::text])))
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
-- TOC entry 4020 (class 0 OID 0)
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
-- TOC entry 4021 (class 0 OID 0)
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
    first_name character varying(255),
    last_name character varying(255),
    email character varying(255) NOT NULL,
    phone character varying(255),
    address_line1 character varying(255),
    address_line2 character varying(255),
    city character varying(255),
    state character varying(255),
    zip character varying(255),
    line1 character varying(255),
    line2 character varying(255)
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
-- TOC entry 4022 (class 0 OID 0)
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
    status character varying(255) DEFAULT 'ACTIVE'::character varying,
    link_type character varying(255) DEFAULT 'PERMANENT'::character varying,
    expires_at timestamp without time zone,
    notes character varying(255),
    relationship character varying(255),
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    patient_id bigint,
    CONSTRAINT family_member_link_link_type_check CHECK (((link_type)::text = ANY (ARRAY[('PERMANENT'::character varying)::text, ('TEMPORARY'::character varying)::text, ('EMERGENCY'::character varying)::text]))),
    CONSTRAINT family_member_link_status_check CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('SUSPENDED'::character varying)::text, ('REVOKED'::character varying)::text, ('EXPIRED'::character varying)::text])))
);


ALTER TABLE public.family_member_link OWNER TO postgres;

--
-- TOC entry 4023 (class 0 OID 0)
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
-- TOC entry 4024 (class 0 OID 0)
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
-- TOC entry 282 (class 1259 OID 25290)
-- Name: friend_request; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.friend_request (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone,
    from_user_id bigint,
    status character varying(255),
    to_user_id bigint
);


ALTER TABLE public.friend_request OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 25289)
-- Name: friend_request_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.friend_request ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.friend_request_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 284 (class 1259 OID 25296)
-- Name: friendships; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.friendships (
    id bigint NOT NULL,
    status character varying(255) NOT NULL,
    user1_id bigint NOT NULL,
    user2_id bigint NOT NULL
);


ALTER TABLE public.friendships OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 25295)
-- Name: friendships_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.friendships ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.friendships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


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
-- TOC entry 4025 (class 0 OID 0)
-- Dependencies: 233
-- Name: meal_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.meal_entry_id_seq OWNED BY public.meal_entry.id;


--
-- TOC entry 286 (class 1259 OID 25302)
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    content text NOT NULL,
    is_read boolean NOT NULL,
    receiver_id bigint NOT NULL,
    sender_id bigint NOT NULL,
    "timestamp" timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- TOC entry 285 (class 1259 OID 25301)
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.messages ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


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
-- TOC entry 4026 (class 0 OID 0)
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
-- TOC entry 4027 (class 0 OID 0)
-- Dependencies: 253
-- Name: mood_pain_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mood_pain_log_id_seq OWNED BY public.mood_pain_log.id;


--
-- TOC entry 288 (class 1259 OID 25310)
-- Name: notification_setting; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_setting (
    id bigint NOT NULL,
    audio_call boolean NOT NULL,
    created_at timestamp(6) with time zone NOT NULL,
    emergency boolean NOT NULL,
    gamification boolean NOT NULL,
    significant_vitals boolean NOT NULL,
    sms boolean NOT NULL,
    updated_at timestamp(6) with time zone NOT NULL,
    user_id bigint NOT NULL,
    video_call boolean NOT NULL
);


ALTER TABLE public.notification_setting OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 25309)
-- Name: notification_setting_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.notification_setting ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.notification_setting_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 232 (class 1259 OID 24726)
-- Name: password_reset_token; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.password_reset_token (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token_hash character varying(64) NOT NULL,
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
-- TOC entry 4028 (class 0 OID 0)
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
    first_name character varying(255),
    last_name character varying(255),
    dob character varying(255),
    email character varying(255) NOT NULL,
    phone character varying(255),
    address_line1 character varying(255),
    address_line2 character varying(255),
    city character varying(255),
    state character varying(255),
    zip character varying(255),
    sex character varying(10),
    medical_notes text,
    relationship character varying(255),
    gender character varying(255),
    line1 character varying(255),
    line2 character varying(255),
    CONSTRAINT patient_sex_check CHECK (((sex)::text = ANY ((ARRAY['M'::character varying, 'F'::character varying, 'OTHER'::character varying])::text[])))
);


ALTER TABLE public.patient OWNER TO postgres;

--
-- TOC entry 4029 (class 0 OID 0)
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
-- TOC entry 4030 (class 0 OID 0)
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
    allergy_type character varying(255),
    severity character varying(255),
    reaction text,
    notes text,
    diagnosed_date character varying(255),
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.patient_allergy OWNER TO postgres;

--
-- TOC entry 4031 (class 0 OID 0)
-- Dependencies: 258
-- Name: TABLE patient_allergy; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.patient_allergy IS 'Patient allergy information including allergens, reactions, and severity';


--
-- TOC entry 4032 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.patient_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.patient_id IS 'Reference to the patient who has this allergy';


--
-- TOC entry 4033 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.allergen; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.allergen IS 'Name of the allergen (e.g., Peanuts, Penicillin, Latex)';


--
-- TOC entry 4034 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.allergy_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.allergy_type IS 'Type of allergy (FOOD, MEDICATION, ENVIRONMENTAL, CONTACT, SEASONAL, OTHER)';


--
-- TOC entry 4035 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.severity; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.severity IS 'Severity level (MILD, MODERATE, SEVERE, LIFE_THREATENING)';


--
-- TOC entry 4036 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.reaction; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.reaction IS 'Description of allergic reaction symptoms';


--
-- TOC entry 4037 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.notes IS 'Additional notes from healthcare providers';


--
-- TOC entry 4038 (class 0 OID 0)
-- Dependencies: 258
-- Name: COLUMN patient_allergy.diagnosed_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_allergy.diagnosed_date IS 'When the allergy was first diagnosed';


--
-- TOC entry 4039 (class 0 OID 0)
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
    relationship_type character varying(255),
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
-- TOC entry 4040 (class 0 OID 0)
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
-- TOC entry 4041 (class 0 OID 0)
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
    dosage character varying(255),
    frequency character varying(255),
    route character varying(255),
    medication_type character varying(255),
    prescribed_by character varying(255),
    prescribed_date character varying(255),
    start_date character varying(255),
    end_date character varying(255),
    notes text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.patient_medication OWNER TO postgres;

--
-- TOC entry 4042 (class 0 OID 0)
-- Dependencies: 260
-- Name: TABLE patient_medication; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.patient_medication IS 'Patient medication information including prescriptions and supplements';


--
-- TOC entry 4043 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.patient_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.patient_id IS 'Reference to the patient taking this medication';


--
-- TOC entry 4044 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.medication_name; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.medication_name IS 'Name of the medication or supplement';


--
-- TOC entry 4045 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.dosage; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.dosage IS 'Dosage information (e.g., 10mg, 2 tablets)';


--
-- TOC entry 4046 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.frequency; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.frequency IS 'How often to take (e.g., twice daily, every 8 hours)';


--
-- TOC entry 4047 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.route; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.route IS 'Route of administration (oral, injection, topical, etc.)';


--
-- TOC entry 4048 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.medication_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.medication_type IS 'Type of medication (PRESCRIPTION, OVER_THE_COUNTER, SUPPLEMENT, HERBAL, EMERGENCY)';


--
-- TOC entry 4049 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.prescribed_by; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.prescribed_by IS 'Name of the prescribing healthcare provider';


--
-- TOC entry 4050 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.prescribed_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.prescribed_date IS 'Date when medication was prescribed';


--
-- TOC entry 4051 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.start_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.start_date IS 'Date when patient started taking the medication';


--
-- TOC entry 4052 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.end_date; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.end_date IS 'Date when medication should be stopped (null for ongoing)';


--
-- TOC entry 4053 (class 0 OID 0)
-- Dependencies: 260
-- Name: COLUMN patient_medication.notes; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.patient_medication.notes IS 'Additional instructions or notes about the medication';


--
-- TOC entry 4054 (class 0 OID 0)
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
    status character varying(255) NOT NULL,
    attempted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    stripe_invoice_id character varying(255),
    user_id bigint,
    CONSTRAINT payment_status_check CHECK (((status)::text = ANY (ARRAY[('SUCCEEDED'::character varying)::text, ('FAILED'::character varying)::text])))
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
-- TOC entry 4055 (class 0 OID 0)
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
-- TOC entry 4056 (class 0 OID 0)
-- Dependencies: 225
-- Name: payment_method_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_method_id_seq OWNED BY public.payment_method.id;


--
-- TOC entry 289 (class 1259 OID 25339)
-- Name: permission; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permission (
    id character varying(255) NOT NULL,
    description character varying(255),
    name character varying(255)
);


ALTER TABLE public.permission OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 24645)
-- Name: plan; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.plan (
    id bigint NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    price_cents integer NOT NULL,
    billing_period character varying(255) DEFAULT 'MONTH'::character varying,
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
-- TOC entry 4057 (class 0 OID 0)
-- Dependencies: 221
-- Name: plan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.plan_id_seq OWNED BY public.plan.id;


--
-- TOC entry 291 (class 1259 OID 25352)
-- Name: posts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.posts (
    id bigint NOT NULL,
    content character varying(255),
    created_at timestamp(6) without time zone,
    image_url character varying(255),
    user_id bigint
);


ALTER TABLE public.posts OWNER TO postgres;

--
-- TOC entry 290 (class 1259 OID 25351)
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.posts ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 292 (class 1259 OID 25359)
-- Name: reset_token; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reset_token (
    id bigint NOT NULL,
    token character varying(255)
);


ALTER TABLE public.reset_token OWNER TO postgres;

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
-- TOC entry 4058 (class 0 OID 0)
-- Dependencies: 223
-- Name: subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscription_id_seq OWNED BY public.subscription.id;


--
-- TOC entry 294 (class 1259 OID 25365)
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscriptions (
    id bigint NOT NULL,
    current_period_end timestamp(6) with time zone,
    price_id character varying(255),
    started_at timestamp(6) with time zone,
    status character varying(255),
    stripe_customer_id character varying(255),
    stripe_subscription_id character varying(255) NOT NULL,
    plan_id bigint,
    user_id bigint
);


ALTER TABLE public.subscriptions OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 25364)
-- Name: subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.subscriptions ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


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
-- TOC entry 4059 (class 0 OID 0)
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
    symptom_key character varying(255) NOT NULL,
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
-- TOC entry 4060 (class 0 OID 0)
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
    description character varying(255),
    date character varying(255) NOT NULL,
    time_of_day character varying(255) NOT NULL,
    iscompleted boolean DEFAULT false NOT NULL,
    task_type character varying(255) NOT NULL,
    frequency character varying(255),
    task_interval integer,
    do_count integer,
    days_of_week character varying(255) NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    is_completed boolean NOT NULL,
    CONSTRAINT tasks_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'COMPLETED'::character varying])::text[]))),
    CONSTRAINT tasks_task_type_check CHECK (((task_type)::text = ANY (ARRAY[('TASK'::character varying)::text, ('FREQUENCY'::character varying)::text, ('DAYOFWEEK'::character varying)::text])))
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
-- TOC entry 4061 (class 0 OID 0)
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
    description character varying(255),
    frequency character varying(255),
    task_interval integer,
    do_count integer,
    days_of_week jsonb,
    time_of_day character varying(255),
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
-- TOC entry 4062 (class 0 OID 0)
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
    progress integer,
    earned_at timestamp(6) without time zone
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
-- TOC entry 4063 (class 0 OID 0)
-- Dependencies: 247
-- Name: user_achievements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_achievements_id_seq OWNED BY public.user_achievements.id;


--
-- TOC entry 296 (class 1259 OID 25424)
-- Name: user_ai_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_ai_config (
    id bigint NOT NULL,
    conversation_history_limit integer,
    deepseek_model character varying(255),
    include_allergies_by_default boolean,
    include_medications_by_default boolean,
    include_mood_pain_by_default boolean,
    include_notes_by_default boolean,
    include_vitals_by_default boolean,
    is_active boolean,
    max_tokens integer,
    openai_model character varying(255),
    patient_id bigint,
    preferred_ai_provider character varying(255) NOT NULL,
    system_prompt character varying(255),
    temperature double precision,
    user_id bigint NOT NULL,
    CONSTRAINT user_ai_config_preferred_ai_provider_check CHECK (((preferred_ai_provider)::text = ANY ((ARRAY['DEFAULT'::character varying, 'OPENAI'::character varying, 'DEEPSEEK'::character varying])::text[])))
);


ALTER TABLE public.user_ai_config OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 25423)
-- Name: user_ai_config_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.user_ai_config ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_ai_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 298 (class 1259 OID 25433)
-- Name: user_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_files (
    id bigint NOT NULL,
    content_type character varying(255),
    description character varying(255),
    file_category character varying(255) NOT NULL,
    file_data oid NOT NULL,
    file_size bigint,
    filename character varying(255) NOT NULL,
    is_active boolean NOT NULL,
    original_filename character varying(255) NOT NULL,
    owner_id bigint NOT NULL,
    owner_type character varying(255) NOT NULL,
    patient_id bigint,
    s3_path character varying(255),
    storage_type character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone,
    uploaded_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT user_files_file_category_check CHECK (((file_category)::text = ANY ((ARRAY['PROFILE_IMAGE'::character varying, 'MEDICAL_RECORD'::character varying, 'CLINICAL_NOTE'::character varying, 'PRESCRIPTION'::character varying, 'LAB_RESULT'::character varying, 'INSURANCE_DOCUMENT'::character varying, 'CONSENT_FORM'::character varying, 'CARE_PLAN'::character varying, 'OTHER_DOCUMENT'::character varying])::text[]))),
    CONSTRAINT user_files_owner_type_check CHECK (((owner_type)::text = ANY ((ARRAY['PATIENT'::character varying, 'CAREGIVER'::character varying, 'FAMILY_MEMBER'::character varying, 'ADMIN'::character varying])::text[]))),
    CONSTRAINT user_files_storage_type_check CHECK (((storage_type)::text = ANY ((ARRAY['DATABASE'::character varying, 'S3'::character varying])::text[])))
);


ALTER TABLE public.user_files OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 25432)
-- Name: user_files_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.user_files ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.user_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 216 (class 1259 OID 24586)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying(255) NOT NULL,
    email_verified boolean DEFAULT false,
    password character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(255) NOT NULL,
    status character varying(255) DEFAULT 'ACTIVE'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    name character varying(255),
    verification_token character varying(255),
    stripe_customer_id character varying(255),
    last_login timestamp without time zone,
    profile_image_url character varying(255),
    last_login_date date,
    login_streak integer DEFAULT 0 NOT NULL,
    leaderboard_opt_in boolean DEFAULT true NOT NULL,
    CONSTRAINT users_role_check CHECK (((role)::text = ANY (ARRAY[('PATIENT'::character varying)::text, ('CAREGIVER'::character varying)::text, ('FAMILY_MEMBER'::character varying)::text, ('ADMIN'::character varying)::text]))),
    CONSTRAINT users_status_check CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('SUSPENDED'::character varying)::text])))
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
-- TOC entry 4064 (class 0 OID 0)
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
-- TOC entry 4065 (class 0 OID 0)
-- Dependencies: 256
-- Name: TABLE vital_sample; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.vital_sample IS 'Unified storage for all patient vital signs and health measurements';


--
-- TOC entry 4066 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.patient_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.patient_id IS 'Reference to the patient this vital sample belongs to';


--
-- TOC entry 4067 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample."timestamp"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample."timestamp" IS 'When this vital measurement was taken';


--
-- TOC entry 4068 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.heart_rate; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.heart_rate IS 'Heart rate in beats per minute (BPM)';


--
-- TOC entry 4069 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.spo2; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.spo2 IS 'Blood oxygen saturation percentage (SpO2)';


--
-- TOC entry 4070 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.systolic; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.systolic IS 'Systolic blood pressure in mmHg';


--
-- TOC entry 4071 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.diastolic; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.diastolic IS 'Diastolic blood pressure in mmHg';


--
-- TOC entry 4072 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.weight; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.weight IS 'Patient weight in kilograms';


--
-- TOC entry 4073 (class 0 OID 0)
-- Dependencies: 256
-- Name: COLUMN vital_sample.mood_value; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.vital_sample.mood_value IS 'Mood rating on scale 1-10 (1=very bad, 10=excellent)';


--
-- TOC entry 4074 (class 0 OID 0)
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
-- TOC entry 300 (class 1259 OID 25449)
-- Name: vitals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vitals (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone,
    is_abnormal boolean,
    notes character varying(255),
    patient_id bigint NOT NULL,
    recorded_at timestamp(6) without time zone NOT NULL,
    recorded_by bigint,
    unit character varying(255),
    value character varying(255) NOT NULL,
    vital_type character varying(255) NOT NULL
);


ALTER TABLE public.vitals OWNER TO postgres;

--
-- TOC entry 299 (class 1259 OID 25448)
-- Name: vitals_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.vitals ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.vitals_id_seq
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
    metric character varying(255) NOT NULL,
    metric_value double precision NOT NULL,
    recorded_at timestamp without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT wearable_metric_metric_check CHECK (((metric)::text = ANY (ARRAY[('HEART_RATE'::character varying)::text, ('SPO2'::character varying)::text, ('TEMPERATURE'::character varying)::text, ('BLOOD_PRESSURE_SYS'::character varying)::text, ('BLOOD_PRESSURE_DIA'::character varying)::text, ('WEIGHT'::character varying)::text, ('STEPS'::character varying)::text])))
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
-- TOC entry 4075 (class 0 OID 0)
-- Dependencies: 237
-- Name: wearable_metric_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.wearable_metric_id_seq OWNED BY public.wearable_metric.id;


--
-- TOC entry 302 (class 1259 OID 25458)
-- Name: xp_progress; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.xp_progress (
    id bigint NOT NULL,
    level integer NOT NULL,
    updated_at timestamp(6) without time zone,
    user_id bigint,
    xp integer NOT NULL
);


ALTER TABLE public.xp_progress OWNER TO postgres;

--
-- TOC entry 301 (class 1259 OID 25457)
-- Name: xp_progress_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.xp_progress ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.xp_progress_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 3467 (class 2604 OID 24882)
-- Name: achievement id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.achievement ALTER COLUMN id SET DEFAULT nextval('public.achievement_id_seq'::regclass);


--
-- TOC entry 3430 (class 2604 OID 24606)
-- Name: caregiver id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver ALTER COLUMN id SET DEFAULT nextval('public.caregiver_id_seq'::regclass);


--
-- TOC entry 3469 (class 2604 OID 24916)
-- Name: caregiver_patient_link id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver_patient_link ALTER COLUMN id SET DEFAULT nextval('public.caregiver_patient_link_id_seq'::regclass);


--
-- TOC entry 3503 (class 2604 OID 25130)
-- Name: chat_conversations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_conversations ALTER COLUMN id SET DEFAULT nextval('public.chat_conversations_id_seq'::regclass);


--
-- TOC entry 3509 (class 2604 OID 25151)
-- Name: chat_messages id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages ALTER COLUMN id SET DEFAULT nextval('public.chat_messages_id_seq'::regclass);


--
-- TOC entry 3488 (class 2604 OID 25081)
-- Name: device_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_tokens ALTER COLUMN id SET DEFAULT nextval('public.device_tokens_id_seq'::regclass);


--
-- TOC entry 3442 (class 2604 OID 24715)
-- Name: email_verification_token id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verification_token ALTER COLUMN id SET DEFAULT nextval('public.email_verification_token_id_seq'::regclass);


--
-- TOC entry 3474 (class 2604 OID 24946)
-- Name: family_member id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member ALTER COLUMN id SET DEFAULT nextval('public.family_member_id_seq'::regclass);


--
-- TOC entry 3462 (class 2604 OID 24839)
-- Name: family_member_link id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link ALTER COLUMN id SET DEFAULT nextval('public.family_member_link_id_seq'::regclass);


--
-- TOC entry 3446 (class 2604 OID 24747)
-- Name: meal_entry id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_entry ALTER COLUMN id SET DEFAULT nextval('public.meal_entry_id_seq'::regclass);


--
-- TOC entry 3449 (class 2604 OID 24768)
-- Name: mood_entry id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_entry ALTER COLUMN id SET DEFAULT nextval('public.mood_entry_id_seq'::regclass);


--
-- TOC entry 3475 (class 2604 OID 24985)
-- Name: mood_pain_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_pain_log ALTER COLUMN id SET DEFAULT nextval('public.mood_pain_log_id_seq'::regclass);


--
-- TOC entry 3443 (class 2604 OID 24729)
-- Name: password_reset_token id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_token ALTER COLUMN id SET DEFAULT nextval('public.password_reset_token_id_seq'::regclass);


--
-- TOC entry 3431 (class 2604 OID 24624)
-- Name: patient id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient ALTER COLUMN id SET DEFAULT nextval('public.patient_id_seq'::regclass);


--
-- TOC entry 3491 (class 2604 OID 25104)
-- Name: patient_ai_config id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_ai_config ALTER COLUMN id SET DEFAULT nextval('public.patient_ai_config_id_seq'::regclass);


--
-- TOC entry 3486 (class 2604 OID 25061)
-- Name: patient_caregiver id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_caregiver ALTER COLUMN id SET DEFAULT nextval('public.patient_caregiver_id_seq'::regclass);


--
-- TOC entry 3440 (class 2604 OID 24694)
-- Name: payment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment ALTER COLUMN id SET DEFAULT nextval('public.payment_id_seq'::regclass);


--
-- TOC entry 3438 (class 2604 OID 24680)
-- Name: payment_method id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_method ALTER COLUMN id SET DEFAULT nextval('public.payment_method_id_seq'::regclass);


--
-- TOC entry 3432 (class 2604 OID 24648)
-- Name: plan id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plan ALTER COLUMN id SET DEFAULT nextval('public.plan_id_seq'::regclass);


--
-- TOC entry 3435 (class 2604 OID 24660)
-- Name: subscription id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription ALTER COLUMN id SET DEFAULT nextval('public.subscription_id_seq'::regclass);


--
-- TOC entry 3455 (class 2604 OID 24800)
-- Name: summary_metrics id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.summary_metrics ALTER COLUMN id SET DEFAULT nextval('public.summary_metrics_id_seq'::regclass);


--
-- TOC entry 3458 (class 2604 OID 24817)
-- Name: symptom_entry id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symptom_entry ALTER COLUMN id SET DEFAULT nextval('public.symptom_entry_id_seq'::regclass);


--
-- TOC entry 3511 (class 2604 OID 25171)
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- TOC entry 3516 (class 2604 OID 25186)
-- Name: templates id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.templates ALTER COLUMN id SET DEFAULT nextval('public.templates_id_seq'::regclass);


--
-- TOC entry 3468 (class 2604 OID 24891)
-- Name: user_achievements id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievements ALTER COLUMN id SET DEFAULT nextval('public.user_achievements_id_seq'::regclass);


--
-- TOC entry 3423 (class 2604 OID 24589)
-- Name: users id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- TOC entry 3452 (class 2604 OID 24784)
-- Name: wearable_metric id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wearable_metric ALTER COLUMN id SET DEFAULT nextval('public.wearable_metric_id_seq'::regclass);


--
-- TOC entry 3951 (class 0 OID 24879)
-- Dependencies: 246
-- Data for Name: achievement; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.achievement (id, title, description, icon) FROM stdin;
1	First Login	Awarded for logging in for the first time.	login-icon.png
2	Made a Friend	Awarded for adding your first friend.	friend-icon.png
3	Added Family Member	Awarded for adding your first family member.	family-icon.png
4	First Post Created	Awarded for creating your first post.	post-icon.png
5	5-Day Streak	Awarded for logging in 5 days in a row.	streak-icon.png
\.


--
-- TOC entry 3923 (class 0 OID 24603)
-- Dependencies: 218
-- Data for Name: caregiver; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.caregiver (id, user_id, first_name, last_name, dob, email, phone, address_line1, address_line2, city, state, zip, caregiver_type, license_number, issuing_state, years_experience, gender, line1, line2) FROM stdin;
1	3	Sudarshan	Neupane	01/01/1990	sudnep@gmail.com	2405555555	\N	\N	Laurel	MD	20866	PROFESSIONAL	qwer223	md	5	MALE	123 false streey	apt 101
2	5	John	Doe	01/02/1990	test@gmail.com	3012324545	\N	\N	Laurel	MD	20707	PROFESSIONAL	qwerty	md	5	MALE	123 main st	
\.


--
-- TOC entry 3955 (class 0 OID 24913)
-- Dependencies: 250
-- Data for Name: caregiver_patient_link; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.caregiver_patient_link (id, caregiver_user_id, patient_user_id, created_by, created_at, updated_at, status, link_type, expires_at, notes) FROM stdin;
1	3	4	3	2025-09-19 00:43:33.173221	2025-09-19 00:43:33.173221	ACTIVE	PERMANENT	\N	Patient registered by caregiver
\.


--
-- TOC entry 3973 (class 0 OID 25127)
-- Dependencies: 268
-- Data for Name: chat_conversations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_conversations (id, conversation_id, patient_id, user_id, chat_type, title, ai_provider_used, ai_model_used, total_tokens_used, is_active, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3975 (class 0 OID 25148)
-- Dependencies: 270
-- Data for Name: chat_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_messages (id, conversation_id, message_type, content, tokens_used, processing_time_ms, temperature_used, context_included, ai_model_used, created_at) FROM stdin;
\.


--
-- TOC entry 3981 (class 0 OID 25245)
-- Dependencies: 276
-- Data for Name: clinical_notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clinical_notes (id, caregiver_id, content, created_at, is_active, note_type, patient_id, subject, updated_at) FROM stdin;
\.


--
-- TOC entry 3983 (class 0 OID 25253)
-- Dependencies: 278
-- Data for Name: comment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comment (id, content, created_at, post_id, user_id, username) FROM stdin;
\.


--
-- TOC entry 3985 (class 0 OID 25261)
-- Dependencies: 280
-- Data for Name: connection_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.connection_requests (id, message, relationship_type, requested_at, responded_at, status, token, caregiver_id, patient_id) FROM stdin;
\.


--
-- TOC entry 3969 (class 0 OID 25078)
-- Dependencies: 264
-- Data for Name: device_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.device_tokens (id, user_id, fcm_token, device_type, device_id, is_active, created_at, updated_at, last_used_at) FROM stdin;
\.


--
-- TOC entry 3935 (class 0 OID 24712)
-- Dependencies: 230
-- Data for Name: email_verification_token; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.email_verification_token (id, token, user_id, expires_at) FROM stdin;
\.


--
-- TOC entry 3957 (class 0 OID 24943)
-- Dependencies: 252
-- Data for Name: family_member; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.family_member (id, user_id, first_name, last_name, email, phone, address_line1, address_line2, city, state, zip, line1, line2) FROM stdin;
\.


--
-- TOC entry 3949 (class 0 OID 24836)
-- Dependencies: 244
-- Data for Name: family_member_link; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.family_member_link (id, family_user_id, patient_user_id, granted_by, created_at, status, link_type, expires_at, notes, relationship, updated_at, patient_id) FROM stdin;
\.


--
-- TOC entry 3919 (class 0 OID 24576)
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
-- TOC entry 3987 (class 0 OID 25290)
-- Dependencies: 282
-- Data for Name: friend_request; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.friend_request (id, created_at, from_user_id, status, to_user_id) FROM stdin;
\.


--
-- TOC entry 3989 (class 0 OID 25296)
-- Dependencies: 284
-- Data for Name: friendships; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.friendships (id, status, user1_id, user2_id) FROM stdin;
\.


--
-- TOC entry 3939 (class 0 OID 24744)
-- Dependencies: 234
-- Data for Name: meal_entry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.meal_entry (id, patient_user_id, caregiver_user_id, calories, taken_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3991 (class 0 OID 25302)
-- Dependencies: 286
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, content, is_read, receiver_id, sender_id, "timestamp") FROM stdin;
\.


--
-- TOC entry 3941 (class 0 OID 24765)
-- Dependencies: 236
-- Data for Name: mood_entry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mood_entry (id, patient_user_id, mood_score, taken_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3959 (class 0 OID 24982)
-- Dependencies: 254
-- Data for Name: mood_pain_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mood_pain_log (id, patient_id, mood_value, pain_value, note, "timestamp", created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3993 (class 0 OID 25310)
-- Dependencies: 288
-- Data for Name: notification_setting; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification_setting (id, audio_call, created_at, emergency, gamification, significant_vitals, sms, updated_at, user_id, video_call) FROM stdin;
1	t	2025-09-19 00:15:35.563965+00	t	t	t	t	2025-09-19 00:15:35.563965+00	3	t
\.


--
-- TOC entry 3937 (class 0 OID 24726)
-- Dependencies: 232
-- Data for Name: password_reset_token; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.password_reset_token (id, user_id, token_hash, expires_at, used, created_at) FROM stdin;
\.


--
-- TOC entry 3925 (class 0 OID 24621)
-- Dependencies: 220
-- Data for Name: patient; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient (id, user_id, first_name, last_name, dob, email, phone, address_line1, address_line2, city, state, zip, sex, medical_notes, relationship, gender, line1, line2) FROM stdin;
1	4	john	doe	01/25/1990	jd@gmail.com	2405695653	\N	\N	laurel	md	20747	\N	\N	spouse	MALE	123 main st	\N
\.


--
-- TOC entry 3971 (class 0 OID 25101)
-- Dependencies: 266
-- Data for Name: patient_ai_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_ai_config (id, patient_id, ai_provider, openai_model, deepseek_model, max_tokens, temperature, conversation_history_limit, include_vitals_by_default, include_medications_by_default, include_notes_by_default, include_mood_pain_logs_by_default, include_allergies_by_default, is_active, system_prompt, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3963 (class 0 OID 25019)
-- Dependencies: 258
-- Data for Name: patient_allergy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_allergy (id, patient_id, allergen, allergy_type, severity, reaction, notes, diagnosed_date, is_active, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3967 (class 0 OID 25058)
-- Dependencies: 262
-- Data for Name: patient_caregiver; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_caregiver (id, patient_id, caregiver_user_id, relationship_type, created_at) FROM stdin;
\.


--
-- TOC entry 3965 (class 0 OID 25038)
-- Dependencies: 260
-- Data for Name: patient_medication; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.patient_medication (id, patient_id, medication_name, dosage, frequency, route, medication_type, prescribed_by, prescribed_date, start_date, end_date, notes, is_active, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3933 (class 0 OID 24691)
-- Dependencies: 228
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment (id, subscription_id, payment_method_id, amount_cents, stripe_session_id, stripe_payment_intent_id, status, attempted_at, stripe_invoice_id, user_id) FROM stdin;
\.


--
-- TOC entry 3931 (class 0 OID 24677)
-- Dependencies: 226
-- Data for Name: payment_method; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payment_method (id, user_id, provider, stripe_token, last4, brand, exp_month, exp_year, created_at) FROM stdin;
\.


--
-- TOC entry 3994 (class 0 OID 25339)
-- Dependencies: 289
-- Data for Name: permission; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.permission (id, description, name) FROM stdin;
\.


--
-- TOC entry 3927 (class 0 OID 24645)
-- Dependencies: 222
-- Data for Name: plan; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.plan (id, code, name, price_cents, billing_period, is_active) FROM stdin;
3	price_1RmqWxELoozGI1YxQql5rsvN	Premium Plan	3000	MONTH	t
4	plan_SbkhH3AATKabKy	Standard Plan	2000	MONTH	t
5	plan_SbkhIoC5wy5iwB	Premium Plan	3000	MONTH	t
\.


--
-- TOC entry 3996 (class 0 OID 25352)
-- Dependencies: 291
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.posts (id, content, created_at, image_url, user_id) FROM stdin;
\.


--
-- TOC entry 3997 (class 0 OID 25359)
-- Dependencies: 292
-- Data for Name: reset_token; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reset_token (id, token) FROM stdin;
\.


--
-- TOC entry 3929 (class 0 OID 24657)
-- Dependencies: 224
-- Data for Name: subscription; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subscription (id, user_id, plan_id, status, started_at, current_period_end) FROM stdin;
\.


--
-- TOC entry 3999 (class 0 OID 25365)
-- Dependencies: 294
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subscriptions (id, current_period_end, price_id, started_at, status, stripe_customer_id, stripe_subscription_id, plan_id, user_id) FROM stdin;
\.


--
-- TOC entry 3945 (class 0 OID 24797)
-- Dependencies: 240
-- Data for Name: summary_metrics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.summary_metrics (id, patient_user_id, period_start, period_end, adherence_rate, avg_heart_rate, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3947 (class 0 OID 24814)
-- Dependencies: 242
-- Data for Name: symptom_entry; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.symptom_entry (id, patient_user_id, caregiver_user_id, symptom_key, symptom_value, severity, taken_at, completed, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 3977 (class 0 OID 25168)
-- Dependencies: 272
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.tasks (id, patient_id, name, description, date, time_of_day, iscompleted, task_type, frequency, task_interval, do_count, days_of_week, status, created_at, updated_at, is_completed) FROM stdin;
\.


--
-- TOC entry 3979 (class 0 OID 25183)
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
-- TOC entry 3953 (class 0 OID 24888)
-- Dependencies: 248
-- Data for Name: user_achievements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_achievements (id, user_id, achievement_id, date_earned, progress, earned_at) FROM stdin;
1	3	1	\N	\N	2025-09-19 00:15:18.036668
\.


--
-- TOC entry 4001 (class 0 OID 25424)
-- Dependencies: 296
-- Data for Name: user_ai_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_ai_config (id, conversation_history_limit, deepseek_model, include_allergies_by_default, include_medications_by_default, include_mood_pain_by_default, include_notes_by_default, include_vitals_by_default, is_active, max_tokens, openai_model, patient_id, preferred_ai_provider, system_prompt, temperature, user_id) FROM stdin;
\.


--
-- TOC entry 4003 (class 0 OID 25433)
-- Dependencies: 298
-- Data for Name: user_files; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_files (id, content_type, description, file_category, file_data, file_size, filename, is_active, original_filename, owner_id, owner_type, patient_id, s3_path, storage_type, updated_at, uploaded_at) FROM stdin;
\.


--
-- TOC entry 3921 (class 0 OID 24586)
-- Dependencies: 216
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, email_verified, password, password_hash, role, status, created_at, updated_at, name, verification_token, stripe_customer_id, last_login, profile_image_url, last_login_date, login_streak, leaderboard_opt_in) FROM stdin;
1	test@caregiver	t	1234	$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.	CAREGIVER	ACTIVE	2025-09-18 11:59:00.792608	2025-09-18 11:59:00.792608	Test Caregiver	\N	\N	\N	\N	\N	0	t
2	test@patient	t	1234	$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.	PATIENT	ACTIVE	2025-09-18 11:59:00.792608	2025-09-18 11:59:00.792608	Test Patient	\N	\N	\N	\N	\N	0	t
4	jd@gmail.com	f	$2a$10$Zka25BwS2LgXkMe/9Kn4G.2x5VLo5GqzJ2EGsX3jaQ0uNVvYjTMZC	$2a$10$Zka25BwS2LgXkMe/9Kn4G.2x5VLo5GqzJ2EGsX3jaQ0uNVvYjTMZC	PATIENT	ACTIVE	2025-09-19 00:43:33.104	2025-09-18 20:43:32.985572	\N	cb64ec8e-d2a2-4016-bd3d-86a057b70787	\N	\N	\N	\N	0	t
5	test@gmail.com	f	$2a$10$wFGEeC8KRHjWouauprRq5OJlYDH8W.dBmIqm9WNTfQ10tZtjFJIMe	$2a$10$wFGEeC8KRHjWouauprRq5OJlYDH8W.dBmIqm9WNTfQ10tZtjFJIMe	CAREGIVER	ACTIVE	\N	2025-09-19 13:07:36.441575	\N	\N	cus_mock_1758301656444	\N	\N	\N	0	t
3	sudnep@gmail.com	f	$2a$10$NLnuyTpzVP7bADz/QlHv9eZIz8MLeHbcrCzmwFW/raxYAu7CoPZy.	$2a$10$NLnuyTpzVP7bADz/QlHv9eZIz8MLeHbcrCzmwFW/raxYAu7CoPZy.	CAREGIVER	ACTIVE	\N	2025-09-18 20:10:00.988748	\N	\N	cus_mock_1758240600993	\N	\N	2025-09-22	1	t
\.


--
-- TOC entry 3961 (class 0 OID 25002)
-- Dependencies: 256
-- Data for Name: vital_sample; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vital_sample (id, patient_id, "timestamp", heart_rate, spo2, systolic, diastolic, weight, mood_value, pain_value, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 4005 (class 0 OID 25449)
-- Dependencies: 300
-- Data for Name: vitals; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vitals (id, created_at, is_abnormal, notes, patient_id, recorded_at, recorded_by, unit, value, vital_type) FROM stdin;
\.


--
-- TOC entry 3943 (class 0 OID 24781)
-- Dependencies: 238
-- Data for Name: wearable_metric; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.wearable_metric (id, patient_user_id, metric, metric_value, recorded_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 4007 (class 0 OID 25458)
-- Dependencies: 302
-- Data for Name: xp_progress; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.xp_progress (id, level, updated_at, user_id, xp) FROM stdin;
1	2	2025-09-19 00:15:18.024547	3	50
\.


--
-- TOC entry 4076 (class 0 OID 0)
-- Dependencies: 245
-- Name: achievement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.achievement_id_seq', 5, true);


--
-- TOC entry 4077 (class 0 OID 0)
-- Dependencies: 217
-- Name: caregiver_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.caregiver_id_seq', 2, true);


--
-- TOC entry 4078 (class 0 OID 0)
-- Dependencies: 249
-- Name: caregiver_patient_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.caregiver_patient_link_id_seq', 1, true);


--
-- TOC entry 4079 (class 0 OID 0)
-- Dependencies: 267
-- Name: chat_conversations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_conversations_id_seq', 1, false);


--
-- TOC entry 4080 (class 0 OID 0)
-- Dependencies: 269
-- Name: chat_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.chat_messages_id_seq', 1, false);


--
-- TOC entry 4081 (class 0 OID 0)
-- Dependencies: 275
-- Name: clinical_notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clinical_notes_id_seq', 1, false);


--
-- TOC entry 4082 (class 0 OID 0)
-- Dependencies: 277
-- Name: comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comment_id_seq', 1, false);


--
-- TOC entry 4083 (class 0 OID 0)
-- Dependencies: 279
-- Name: connection_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.connection_requests_id_seq', 1, false);


--
-- TOC entry 4084 (class 0 OID 0)
-- Dependencies: 263
-- Name: device_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.device_tokens_id_seq', 1, false);


--
-- TOC entry 4085 (class 0 OID 0)
-- Dependencies: 229
-- Name: email_verification_token_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.email_verification_token_id_seq', 1, false);


--
-- TOC entry 4086 (class 0 OID 0)
-- Dependencies: 251
-- Name: family_member_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.family_member_id_seq', 1, false);


--
-- TOC entry 4087 (class 0 OID 0)
-- Dependencies: 243
-- Name: family_member_link_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.family_member_link_id_seq', 1, false);


--
-- TOC entry 4088 (class 0 OID 0)
-- Dependencies: 281
-- Name: friend_request_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.friend_request_id_seq', 1, false);


--
-- TOC entry 4089 (class 0 OID 0)
-- Dependencies: 283
-- Name: friendships_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.friendships_id_seq', 1, false);


--
-- TOC entry 4090 (class 0 OID 0)
-- Dependencies: 233
-- Name: meal_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.meal_entry_id_seq', 1, false);


--
-- TOC entry 4091 (class 0 OID 0)
-- Dependencies: 285
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.messages_id_seq', 1, false);


--
-- TOC entry 4092 (class 0 OID 0)
-- Dependencies: 235
-- Name: mood_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mood_entry_id_seq', 1, false);


--
-- TOC entry 4093 (class 0 OID 0)
-- Dependencies: 253
-- Name: mood_pain_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mood_pain_log_id_seq', 1, false);


--
-- TOC entry 4094 (class 0 OID 0)
-- Dependencies: 287
-- Name: notification_setting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.notification_setting_id_seq', 1, true);


--
-- TOC entry 4095 (class 0 OID 0)
-- Dependencies: 231
-- Name: password_reset_token_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.password_reset_token_id_seq', 1, false);


--
-- TOC entry 4096 (class 0 OID 0)
-- Dependencies: 265
-- Name: patient_ai_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_ai_config_id_seq', 1, false);


--
-- TOC entry 4097 (class 0 OID 0)
-- Dependencies: 257
-- Name: patient_allergy_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_allergy_id_seq', 1, false);


--
-- TOC entry 4098 (class 0 OID 0)
-- Dependencies: 261
-- Name: patient_caregiver_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_caregiver_id_seq', 1, false);


--
-- TOC entry 4099 (class 0 OID 0)
-- Dependencies: 219
-- Name: patient_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_id_seq', 1, true);


--
-- TOC entry 4100 (class 0 OID 0)
-- Dependencies: 259
-- Name: patient_medication_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.patient_medication_id_seq', 1, false);


--
-- TOC entry 4101 (class 0 OID 0)
-- Dependencies: 227
-- Name: payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_id_seq', 1, false);


--
-- TOC entry 4102 (class 0 OID 0)
-- Dependencies: 225
-- Name: payment_method_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payment_method_id_seq', 1, false);


--
-- TOC entry 4103 (class 0 OID 0)
-- Dependencies: 221
-- Name: plan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.plan_id_seq', 6, true);


--
-- TOC entry 4104 (class 0 OID 0)
-- Dependencies: 290
-- Name: posts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.posts_id_seq', 1, false);


--
-- TOC entry 4105 (class 0 OID 0)
-- Dependencies: 223
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subscription_id_seq', 1, false);


--
-- TOC entry 4106 (class 0 OID 0)
-- Dependencies: 293
-- Name: subscriptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subscriptions_id_seq', 1, false);


--
-- TOC entry 4107 (class 0 OID 0)
-- Dependencies: 239
-- Name: summary_metrics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.summary_metrics_id_seq', 1, false);


--
-- TOC entry 4108 (class 0 OID 0)
-- Dependencies: 241
-- Name: symptom_entry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.symptom_entry_id_seq', 1, false);


--
-- TOC entry 4109 (class 0 OID 0)
-- Dependencies: 271
-- Name: tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.tasks_id_seq', 1, false);


--
-- TOC entry 4110 (class 0 OID 0)
-- Dependencies: 273
-- Name: templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.templates_id_seq', 5, true);


--
-- TOC entry 4111 (class 0 OID 0)
-- Dependencies: 247
-- Name: user_achievements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_achievements_id_seq', 1, true);


--
-- TOC entry 4112 (class 0 OID 0)
-- Dependencies: 295
-- Name: user_ai_config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_ai_config_id_seq', 1, false);


--
-- TOC entry 4113 (class 0 OID 0)
-- Dependencies: 297
-- Name: user_files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_files_id_seq', 1, false);


--
-- TOC entry 4114 (class 0 OID 0)
-- Dependencies: 215
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 5, true);


--
-- TOC entry 4115 (class 0 OID 0)
-- Dependencies: 255
-- Name: vital_sample_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vital_sample_id_seq', 1, false);


--
-- TOC entry 4116 (class 0 OID 0)
-- Dependencies: 299
-- Name: vitals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vitals_id_seq', 1, false);


--
-- TOC entry 4117 (class 0 OID 0)
-- Dependencies: 237
-- Name: wearable_metric_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.wearable_metric_id_seq', 1, false);


--
-- TOC entry 4118 (class 0 OID 0)
-- Dependencies: 301
-- Name: xp_progress_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.xp_progress_id_seq', 1, true);


--
-- TOC entry 3624 (class 2606 OID 24886)
-- Name: achievement achievement_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.achievement
    ADD CONSTRAINT achievement_pkey PRIMARY KEY (id);


--
-- TOC entry 3561 (class 2606 OID 25211)
-- Name: caregiver caregiver_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver
    ADD CONSTRAINT caregiver_email_key UNIQUE (email);


--
-- TOC entry 3628 (class 2606 OID 24926)
-- Name: caregiver_patient_link caregiver_patient_link_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver_patient_link
    ADD CONSTRAINT caregiver_patient_link_pkey PRIMARY KEY (id);


--
-- TOC entry 3563 (class 2606 OID 24610)
-- Name: caregiver caregiver_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver
    ADD CONSTRAINT caregiver_pkey PRIMARY KEY (id);


--
-- TOC entry 3565 (class 2606 OID 24612)
-- Name: caregiver caregiver_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver
    ADD CONSTRAINT caregiver_user_id_key UNIQUE (user_id);


--
-- TOC entry 3674 (class 2606 OID 25233)
-- Name: chat_conversations chat_conversations_conversation_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_conversations
    ADD CONSTRAINT chat_conversations_conversation_id_key UNIQUE (conversation_id);


--
-- TOC entry 3676 (class 2606 OID 25139)
-- Name: chat_conversations chat_conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_conversations
    ADD CONSTRAINT chat_conversations_pkey PRIMARY KEY (id);


--
-- TOC entry 3683 (class 2606 OID 25157)
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);


--
-- TOC entry 3691 (class 2606 OID 25251)
-- Name: clinical_notes clinical_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clinical_notes
    ADD CONSTRAINT clinical_notes_pkey PRIMARY KEY (id);


--
-- TOC entry 3693 (class 2606 OID 25259)
-- Name: comment comment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comment
    ADD CONSTRAINT comment_pkey PRIMARY KEY (id);


--
-- TOC entry 3695 (class 2606 OID 25267)
-- Name: connection_requests connection_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.connection_requests
    ADD CONSTRAINT connection_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 3663 (class 2606 OID 25088)
-- Name: device_tokens device_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_tokens
    ADD CONSTRAINT device_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 3665 (class 2606 OID 25090)
-- Name: device_tokens device_tokens_user_id_device_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_tokens
    ADD CONSTRAINT device_tokens_user_id_device_id_key UNIQUE (user_id, device_id);


--
-- TOC entry 3583 (class 2606 OID 24717)
-- Name: email_verification_token email_verification_token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verification_token
    ADD CONSTRAINT email_verification_token_pkey PRIMARY KEY (id);


--
-- TOC entry 3585 (class 2606 OID 24719)
-- Name: email_verification_token email_verification_token_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verification_token
    ADD CONSTRAINT email_verification_token_token_key UNIQUE (token);


--
-- TOC entry 3634 (class 2606 OID 25270)
-- Name: family_member family_member_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member
    ADD CONSTRAINT family_member_email_key UNIQUE (email);


--
-- TOC entry 3613 (class 2606 OID 24842)
-- Name: family_member_link family_member_link_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT family_member_link_pkey PRIMARY KEY (id);


--
-- TOC entry 3636 (class 2606 OID 24950)
-- Name: family_member family_member_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member
    ADD CONSTRAINT family_member_pkey PRIMARY KEY (id);


--
-- TOC entry 3638 (class 2606 OID 24952)
-- Name: family_member family_member_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member
    ADD CONSTRAINT family_member_user_id_key UNIQUE (user_id);


--
-- TOC entry 3554 (class 2606 OID 24583)
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- TOC entry 3697 (class 2606 OID 25294)
-- Name: friend_request friend_request_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friend_request
    ADD CONSTRAINT friend_request_pkey PRIMARY KEY (id);


--
-- TOC entry 3699 (class 2606 OID 25300)
-- Name: friendships friendships_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendships
    ADD CONSTRAINT friendships_pkey PRIMARY KEY (id);


--
-- TOC entry 3595 (class 2606 OID 24752)
-- Name: meal_entry meal_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_entry
    ADD CONSTRAINT meal_entry_pkey PRIMARY KEY (id);


--
-- TOC entry 3701 (class 2606 OID 25308)
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- TOC entry 3598 (class 2606 OID 24773)
-- Name: mood_entry mood_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_entry
    ADD CONSTRAINT mood_entry_pkey PRIMARY KEY (id);


--
-- TOC entry 3642 (class 2606 OID 24993)
-- Name: mood_pain_log mood_pain_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_pain_log
    ADD CONSTRAINT mood_pain_log_pkey PRIMARY KEY (id);


--
-- TOC entry 3703 (class 2606 OID 25314)
-- Name: notification_setting notification_setting_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_setting
    ADD CONSTRAINT notification_setting_pkey PRIMARY KEY (id);


--
-- TOC entry 3590 (class 2606 OID 24733)
-- Name: password_reset_token password_reset_token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_token
    ADD CONSTRAINT password_reset_token_pkey PRIMARY KEY (id);


--
-- TOC entry 3592 (class 2606 OID 25316)
-- Name: password_reset_token password_reset_token_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_token
    ADD CONSTRAINT password_reset_token_token_hash_key UNIQUE (token_hash);


--
-- TOC entry 3672 (class 2606 OID 25123)
-- Name: patient_ai_config patient_ai_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_ai_config
    ADD CONSTRAINT patient_ai_config_pkey PRIMARY KEY (id);


--
-- TOC entry 3651 (class 2606 OID 25028)
-- Name: patient_allergy patient_allergy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_allergy
    ADD CONSTRAINT patient_allergy_pkey PRIMARY KEY (id);


--
-- TOC entry 3659 (class 2606 OID 25064)
-- Name: patient_caregiver patient_caregiver_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_caregiver
    ADD CONSTRAINT patient_caregiver_pkey PRIMARY KEY (id);


--
-- TOC entry 3567 (class 2606 OID 25336)
-- Name: patient patient_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_email_key UNIQUE (email);


--
-- TOC entry 3657 (class 2606 OID 25047)
-- Name: patient_medication patient_medication_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_medication
    ADD CONSTRAINT patient_medication_pkey PRIMARY KEY (id);


--
-- TOC entry 3569 (class 2606 OID 24629)
-- Name: patient patient_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_pkey PRIMARY KEY (id);


--
-- TOC entry 3571 (class 2606 OID 24631)
-- Name: patient patient_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_user_id_key UNIQUE (user_id);


--
-- TOC entry 3579 (class 2606 OID 24684)
-- Name: payment_method payment_method_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_method
    ADD CONSTRAINT payment_method_pkey PRIMARY KEY (id);


--
-- TOC entry 3581 (class 2606 OID 24700)
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (id);


--
-- TOC entry 3707 (class 2606 OID 25345)
-- Name: permission permission_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permission
    ADD CONSTRAINT permission_pkey PRIMARY KEY (id);


--
-- TOC entry 3573 (class 2606 OID 25348)
-- Name: plan plan_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plan
    ADD CONSTRAINT plan_code_key UNIQUE (code);


--
-- TOC entry 3575 (class 2606 OID 24653)
-- Name: plan plan_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plan
    ADD CONSTRAINT plan_pkey PRIMARY KEY (id);


--
-- TOC entry 3709 (class 2606 OID 25358)
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- TOC entry 3711 (class 2606 OID 25363)
-- Name: reset_token reset_token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reset_token
    ADD CONSTRAINT reset_token_pkey PRIMARY KEY (id);


--
-- TOC entry 3577 (class 2606 OID 24665)
-- Name: subscription subscription_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_pkey PRIMARY KEY (id);


--
-- TOC entry 3713 (class 2606 OID 25371)
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- TOC entry 3604 (class 2606 OID 24806)
-- Name: summary_metrics summary_metrics_patient_user_id_period_start_period_end_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.summary_metrics
    ADD CONSTRAINT summary_metrics_patient_user_id_period_start_period_end_key UNIQUE (patient_user_id, period_start, period_end);


--
-- TOC entry 3606 (class 2606 OID 24804)
-- Name: summary_metrics summary_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.summary_metrics
    ADD CONSTRAINT summary_metrics_pkey PRIMARY KEY (id);


--
-- TOC entry 3611 (class 2606 OID 24823)
-- Name: symptom_entry symptom_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symptom_entry
    ADD CONSTRAINT symptom_entry_pkey PRIMARY KEY (id);


--
-- TOC entry 3687 (class 2606 OID 25181)
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- TOC entry 3689 (class 2606 OID 25192)
-- Name: templates templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.templates
    ADD CONSTRAINT templates_pkey PRIMARY KEY (id);


--
-- TOC entry 3620 (class 2606 OID 24980)
-- Name: family_member_link uk_family_member_link_patient_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT uk_family_member_link_patient_unique UNIQUE (family_user_id, patient_id);


--
-- TOC entry 4119 (class 0 OID 0)
-- Dependencies: 3620
-- Name: CONSTRAINT uk_family_member_link_patient_unique ON family_member_link; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT uk_family_member_link_patient_unique ON public.family_member_link IS 'Prevents duplicate family member-patient links using patient_id';


--
-- TOC entry 3622 (class 2606 OID 24978)
-- Name: family_member_link uk_family_member_link_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT uk_family_member_link_unique UNIQUE (family_user_id, patient_user_id);


--
-- TOC entry 4120 (class 0 OID 0)
-- Dependencies: 3622
-- Name: CONSTRAINT uk_family_member_link_unique ON family_member_link; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON CONSTRAINT uk_family_member_link_unique ON public.family_member_link IS 'Prevents duplicate family member-patient links';


--
-- TOC entry 3661 (class 2606 OID 25066)
-- Name: patient_caregiver uk_patient_caregiver; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_caregiver
    ADD CONSTRAINT uk_patient_caregiver UNIQUE (patient_id, caregiver_user_id);


--
-- TOC entry 3715 (class 2606 OID 25466)
-- Name: subscriptions ukhrjab6j3njsjx6ua50ob6byeu; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT ukhrjab6j3njsjx6ua50ob6byeu UNIQUE (stripe_subscription_id);


--
-- TOC entry 3705 (class 2606 OID 25464)
-- Name: notification_setting ukprsli08qedapfuoqx92jd8o7x; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_setting
    ADD CONSTRAINT ukprsli08qedapfuoqx92jd8o7x UNIQUE (user_id);


--
-- TOC entry 3608 (class 2606 OID 25468)
-- Name: summary_metrics uq_patient_window; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.summary_metrics
    ADD CONSTRAINT uq_patient_window UNIQUE (patient_user_id, period_start, period_end);


--
-- TOC entry 3626 (class 2606 OID 24893)
-- Name: user_achievements user_achievements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_pkey PRIMARY KEY (id);


--
-- TOC entry 3717 (class 2606 OID 25431)
-- Name: user_ai_config user_ai_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_ai_config
    ADD CONSTRAINT user_ai_config_pkey PRIMARY KEY (id);


--
-- TOC entry 3719 (class 2606 OID 25442)
-- Name: user_files user_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_files
    ADD CONSTRAINT user_files_pkey PRIMARY KEY (id);


--
-- TOC entry 3557 (class 2606 OID 25444)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3559 (class 2606 OID 24599)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3646 (class 2606 OID 25010)
-- Name: vital_sample vital_sample_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vital_sample
    ADD CONSTRAINT vital_sample_pkey PRIMARY KEY (id);


--
-- TOC entry 3721 (class 2606 OID 25455)
-- Name: vitals vitals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vitals
    ADD CONSTRAINT vitals_pkey PRIMARY KEY (id);


--
-- TOC entry 3601 (class 2606 OID 24789)
-- Name: wearable_metric wearable_metric_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wearable_metric
    ADD CONSTRAINT wearable_metric_pkey PRIMARY KEY (id);


--
-- TOC entry 3723 (class 2606 OID 25462)
-- Name: xp_progress xp_progress_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.xp_progress
    ADD CONSTRAINT xp_progress_pkey PRIMARY KEY (id);


--
-- TOC entry 3555 (class 1259 OID 24584)
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- TOC entry 3629 (class 1259 OID 24960)
-- Name: idx_caregiver_patient_link_caregiver; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_caregiver_patient_link_caregiver ON public.caregiver_patient_link USING btree (caregiver_user_id);


--
-- TOC entry 3630 (class 1259 OID 24963)
-- Name: idx_caregiver_patient_link_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_caregiver_patient_link_expires ON public.caregiver_patient_link USING btree (expires_at);


--
-- TOC entry 3631 (class 1259 OID 24961)
-- Name: idx_caregiver_patient_link_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_caregiver_patient_link_patient ON public.caregiver_patient_link USING btree (patient_user_id);


--
-- TOC entry 3632 (class 1259 OID 25225)
-- Name: idx_caregiver_patient_link_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_caregiver_patient_link_status ON public.caregiver_patient_link USING btree (status);


--
-- TOC entry 3677 (class 1259 OID 25234)
-- Name: idx_chat_conversations_conversation_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_conversations_conversation_id ON public.chat_conversations USING btree (conversation_id);


--
-- TOC entry 3678 (class 1259 OID 25145)
-- Name: idx_chat_conversations_patient_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_conversations_patient_active ON public.chat_conversations USING btree (patient_id, is_active);


--
-- TOC entry 3679 (class 1259 OID 25143)
-- Name: idx_chat_conversations_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_conversations_patient_id ON public.chat_conversations USING btree (patient_id);


--
-- TOC entry 3680 (class 1259 OID 25146)
-- Name: idx_chat_conversations_updated_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_conversations_updated_at ON public.chat_conversations USING btree (updated_at DESC);


--
-- TOC entry 3681 (class 1259 OID 25144)
-- Name: idx_chat_conversations_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_conversations_user_id ON public.chat_conversations USING btree (user_id);


--
-- TOC entry 3684 (class 1259 OID 25163)
-- Name: idx_chat_messages_conversation_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_messages_conversation_id ON public.chat_messages USING btree (conversation_id);


--
-- TOC entry 3685 (class 1259 OID 25164)
-- Name: idx_chat_messages_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_messages_created_at ON public.chat_messages USING btree (conversation_id, created_at);


--
-- TOC entry 3666 (class 1259 OID 25098)
-- Name: idx_device_tokens_device_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_tokens_device_id ON public.device_tokens USING btree (device_id);


--
-- TOC entry 3667 (class 1259 OID 25097)
-- Name: idx_device_tokens_fcm_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_tokens_fcm_token ON public.device_tokens USING btree (fcm_token);


--
-- TOC entry 3668 (class 1259 OID 25096)
-- Name: idx_device_tokens_user_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_tokens_user_active ON public.device_tokens USING btree (user_id, is_active);


--
-- TOC entry 3614 (class 1259 OID 24967)
-- Name: idx_family_member_link_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_family_member_link_expires ON public.family_member_link USING btree (expires_at);


--
-- TOC entry 3615 (class 1259 OID 24964)
-- Name: idx_family_member_link_family; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_family_member_link_family ON public.family_member_link USING btree (family_user_id);


--
-- TOC entry 3616 (class 1259 OID 24965)
-- Name: idx_family_member_link_patient; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_family_member_link_patient ON public.family_member_link USING btree (patient_user_id);


--
-- TOC entry 3617 (class 1259 OID 24971)
-- Name: idx_family_member_link_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_family_member_link_patient_id ON public.family_member_link USING btree (patient_id);


--
-- TOC entry 3618 (class 1259 OID 25287)
-- Name: idx_family_member_link_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_family_member_link_status ON public.family_member_link USING btree (status);


--
-- TOC entry 3593 (class 1259 OID 24763)
-- Name: idx_meal_patient_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_meal_patient_time ON public.meal_entry USING btree (patient_user_id, taken_at);


--
-- TOC entry 3639 (class 1259 OID 24999)
-- Name: idx_mood_pain_patient_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mood_pain_patient_timestamp ON public.mood_pain_log USING btree (patient_id, "timestamp");


--
-- TOC entry 3640 (class 1259 OID 25000)
-- Name: idx_mood_pain_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mood_pain_timestamp ON public.mood_pain_log USING btree ("timestamp");


--
-- TOC entry 3596 (class 1259 OID 24779)
-- Name: idx_mood_patient_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mood_patient_time ON public.mood_entry USING btree (patient_user_id, taken_at);


--
-- TOC entry 3586 (class 1259 OID 25318)
-- Name: idx_password_reset_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_password_reset_token ON public.password_reset_token USING btree (token_hash);


--
-- TOC entry 3587 (class 1259 OID 24742)
-- Name: idx_password_reset_token_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_password_reset_token_expires ON public.password_reset_token USING btree (expires_at);


--
-- TOC entry 3588 (class 1259 OID 25317)
-- Name: idx_password_reset_token_hash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_password_reset_token_hash ON public.password_reset_token USING btree (token_hash);


--
-- TOC entry 3669 (class 1259 OID 25125)
-- Name: idx_patient_ai_config_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_ai_config_active ON public.patient_ai_config USING btree (patient_id, is_active);


--
-- TOC entry 3670 (class 1259 OID 25124)
-- Name: idx_patient_ai_config_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_ai_config_patient_id ON public.patient_ai_config USING btree (patient_id);


--
-- TOC entry 3647 (class 1259 OID 25035)
-- Name: idx_patient_allergy_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_allergy_active ON public.patient_allergy USING btree (patient_id, is_active);


--
-- TOC entry 3648 (class 1259 OID 25036)
-- Name: idx_patient_allergy_allergen; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_allergy_allergen ON public.patient_allergy USING btree (allergen);


--
-- TOC entry 3649 (class 1259 OID 25034)
-- Name: idx_patient_allergy_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_allergy_patient_id ON public.patient_allergy USING btree (patient_id);


--
-- TOC entry 3652 (class 1259 OID 25054)
-- Name: idx_patient_medication_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_medication_active ON public.patient_medication USING btree (patient_id, is_active);


--
-- TOC entry 3653 (class 1259 OID 25056)
-- Name: idx_patient_medication_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_medication_name ON public.patient_medication USING btree (medication_name);


--
-- TOC entry 3654 (class 1259 OID 25053)
-- Name: idx_patient_medication_patient_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_medication_patient_id ON public.patient_medication USING btree (patient_id);


--
-- TOC entry 3655 (class 1259 OID 25337)
-- Name: idx_patient_medication_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_patient_medication_type ON public.patient_medication USING btree (medication_type);


--
-- TOC entry 3602 (class 1259 OID 24812)
-- Name: idx_summary_patient_end; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_summary_patient_end ON public.summary_metrics USING btree (patient_user_id, period_end);


--
-- TOC entry 3609 (class 1259 OID 24834)
-- Name: idx_symptom_patient_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_symptom_patient_time ON public.symptom_entry USING btree (patient_user_id, taken_at);


--
-- TOC entry 3643 (class 1259 OID 25016)
-- Name: idx_vital_sample_patient_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vital_sample_patient_timestamp ON public.vital_sample USING btree (patient_id, "timestamp");


--
-- TOC entry 3644 (class 1259 OID 25017)
-- Name: idx_vital_sample_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vital_sample_timestamp ON public.vital_sample USING btree ("timestamp");


--
-- TOC entry 3599 (class 1259 OID 24795)
-- Name: idx_wearable_patient_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_wearable_patient_time ON public.wearable_metric USING btree (patient_user_id, recorded_at);


--
-- TOC entry 3774 (class 2620 OID 24970)
-- Name: caregiver_patient_link update_caregiver_patient_link_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_caregiver_patient_link_updated_at BEFORE UPDATE ON public.caregiver_patient_link FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3776 (class 2620 OID 25166)
-- Name: chat_conversations update_chat_conversations_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_chat_conversations_updated_at BEFORE UPDATE ON public.chat_conversations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3773 (class 2620 OID 24969)
-- Name: family_member_link update_family_member_link_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_family_member_link_updated_at BEFORE UPDATE ON public.family_member_link FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3775 (class 2620 OID 25165)
-- Name: patient_ai_config update_patient_ai_config_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_patient_ai_config_updated_at BEFORE UPDATE ON public.patient_ai_config FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 3754 (class 2606 OID 24927)
-- Name: caregiver_patient_link caregiver_patient_link_caregiver_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver_patient_link
    ADD CONSTRAINT caregiver_patient_link_caregiver_user_id_fkey FOREIGN KEY (caregiver_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3755 (class 2606 OID 24937)
-- Name: caregiver_patient_link caregiver_patient_link_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver_patient_link
    ADD CONSTRAINT caregiver_patient_link_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3756 (class 2606 OID 24932)
-- Name: caregiver_patient_link caregiver_patient_link_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver_patient_link
    ADD CONSTRAINT caregiver_patient_link_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3724 (class 2606 OID 24615)
-- Name: caregiver caregiver_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.caregiver
    ADD CONSTRAINT caregiver_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3765 (class 2606 OID 25158)
-- Name: chat_messages chat_messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.chat_conversations(id) ON DELETE CASCADE;


--
-- TOC entry 3764 (class 2606 OID 25091)
-- Name: device_tokens device_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_tokens
    ADD CONSTRAINT device_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3748 (class 2606 OID 24843)
-- Name: family_member_link family_member_link_family_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT family_member_link_family_user_id_fkey FOREIGN KEY (family_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3749 (class 2606 OID 24853)
-- Name: family_member_link family_member_link_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT family_member_link_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 3750 (class 2606 OID 24848)
-- Name: family_member_link family_member_link_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT family_member_link_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3757 (class 2606 OID 24955)
-- Name: family_member family_member_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member
    ADD CONSTRAINT family_member_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3769 (class 2606 OID 25484)
-- Name: friendships fk3ii24jylf37bx29q6navneqa7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendships
    ADD CONSTRAINT fk3ii24jylf37bx29q6navneqa7 FOREIGN KEY (user2_id) REFERENCES public.users(id);


--
-- TOC entry 3744 (class 2606 OID 25534)
-- Name: symptom_entry fk3sgbeu1b3pqgbtbjvkilasm3f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symptom_entry
    ADD CONSTRAINT fk3sgbeu1b3pqgbtbjvkilasm3f FOREIGN KEY (patient_user_id) REFERENCES public.patient(id);


--
-- TOC entry 3742 (class 2606 OID 25524)
-- Name: summary_metrics fk4mdpik2u8qvume4ib5y4svphn; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.summary_metrics
    ADD CONSTRAINT fk4mdpik2u8qvume4ib5y4svphn FOREIGN KEY (patient_user_id) REFERENCES public.patient(id);


--
-- TOC entry 3739 (class 2606 OID 25499)
-- Name: mood_entry fk6bl0h62g8saq0xgtdo2d7a7ln; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_entry
    ADD CONSTRAINT fk6bl0h62g8saq0xgtdo2d7a7ln FOREIGN KEY (patient_user_id) REFERENCES public.patient(id);


--
-- TOC entry 3745 (class 2606 OID 25529)
-- Name: symptom_entry fk6daqkvqkps7ne36o5oljny8q7; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symptom_entry
    ADD CONSTRAINT fk6daqkvqkps7ne36o5oljny8q7 FOREIGN KEY (caregiver_user_id) REFERENCES public.caregiver(id);


--
-- TOC entry 3762 (class 2606 OID 25072)
-- Name: patient_caregiver fk_caregiver; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_caregiver
    ADD CONSTRAINT fk_caregiver FOREIGN KEY (caregiver_user_id) REFERENCES public.users(id);


--
-- TOC entry 3733 (class 2606 OID 24720)
-- Name: email_verification_token fk_email_verification_token_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_verification_token
    ADD CONSTRAINT fk_email_verification_token_user FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3751 (class 2606 OID 24972)
-- Name: family_member_link fk_family_member_link_patient_id; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.family_member_link
    ADD CONSTRAINT fk_family_member_link_patient_id FOREIGN KEY (patient_id) REFERENCES public.patient(id);


--
-- TOC entry 3734 (class 2606 OID 24736)
-- Name: password_reset_token fk_password_reset_token_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.password_reset_token
    ADD CONSTRAINT fk_password_reset_token_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3763 (class 2606 OID 25067)
-- Name: patient_caregiver fk_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_caregiver
    ADD CONSTRAINT fk_patient FOREIGN KEY (patient_id) REFERENCES public.patient(id);


--
-- TOC entry 3760 (class 2606 OID 25029)
-- Name: patient_allergy fk_patient_allergy_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_allergy
    ADD CONSTRAINT fk_patient_allergy_patient FOREIGN KEY (patient_id) REFERENCES public.patient(id) ON DELETE CASCADE;


--
-- TOC entry 3761 (class 2606 OID 25048)
-- Name: patient_medication fk_patient_medication_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient_medication
    ADD CONSTRAINT fk_patient_medication_patient FOREIGN KEY (patient_id) REFERENCES public.patient(id) ON DELETE CASCADE;


--
-- TOC entry 3759 (class 2606 OID 25011)
-- Name: vital_sample fk_vital_sample_patient; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vital_sample
    ADD CONSTRAINT fk_vital_sample_patient FOREIGN KEY (patient_id) REFERENCES public.patient(id) ON DELETE CASCADE;


--
-- TOC entry 3767 (class 2606 OID 25474)
-- Name: connection_requests fkaf2yxd70f6vhf1qql0llwgpxo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.connection_requests
    ADD CONSTRAINT fkaf2yxd70f6vhf1qql0llwgpxo FOREIGN KEY (patient_id) REFERENCES public.users(id);


--
-- TOC entry 3770 (class 2606 OID 25479)
-- Name: friendships fkbni8hh12wpbcinmrrm7icj9pa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.friendships
    ADD CONSTRAINT fkbni8hh12wpbcinmrrm7icj9pa FOREIGN KEY (user1_id) REFERENCES public.users(id);


--
-- TOC entry 3771 (class 2606 OID 25514)
-- Name: subscriptions fkbw0tb1ps02vxlfvh4yunmoxtm; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fkbw0tb1ps02vxlfvh4yunmoxtm FOREIGN KEY (plan_id) REFERENCES public.plan(id);


--
-- TOC entry 3766 (class 2606 OID 25539)
-- Name: tasks fkebwdar82f70rnnwqiiehk1v8d; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT fkebwdar82f70rnnwqiiehk1v8d FOREIGN KEY (patient_id) REFERENCES public.patient(id);


--
-- TOC entry 3729 (class 2606 OID 25504)
-- Name: payment fkf33gbc1d0uh0qb5v2lhjhrnda; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT fkf33gbc1d0uh0qb5v2lhjhrnda FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id);


--
-- TOC entry 3768 (class 2606 OID 25469)
-- Name: connection_requests fkhaq6er0489u8s6k9q2iteq05y; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.connection_requests
    ADD CONSTRAINT fkhaq6er0489u8s6k9q2iteq05y FOREIGN KEY (caregiver_id) REFERENCES public.users(id);


--
-- TOC entry 3772 (class 2606 OID 25519)
-- Name: subscriptions fkhro52ohfqfbay9774bev0qinr; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT fkhro52ohfqfbay9774bev0qinr FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3735 (class 2606 OID 25494)
-- Name: meal_entry fkkwsei10fwpo2sk9pijuh1845q; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_entry
    ADD CONSTRAINT fkkwsei10fwpo2sk9pijuh1845q FOREIGN KEY (patient_user_id) REFERENCES public.patient(id);


--
-- TOC entry 3730 (class 2606 OID 25509)
-- Name: payment fkmi2669nkjesvp7cd257fptl6f; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT fkmi2669nkjesvp7cd257fptl6f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3736 (class 2606 OID 25489)
-- Name: meal_entry fktfrqoho4yikyyv9dd3uceuef0; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_entry
    ADD CONSTRAINT fktfrqoho4yikyyv9dd3uceuef0 FOREIGN KEY (caregiver_user_id) REFERENCES public.caregiver(id);


--
-- TOC entry 3737 (class 2606 OID 24758)
-- Name: meal_entry meal_entry_caregiver_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_entry
    ADD CONSTRAINT meal_entry_caregiver_user_id_fkey FOREIGN KEY (caregiver_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 3738 (class 2606 OID 24753)
-- Name: meal_entry meal_entry_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.meal_entry
    ADD CONSTRAINT meal_entry_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3740 (class 2606 OID 24774)
-- Name: mood_entry mood_entry_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_entry
    ADD CONSTRAINT mood_entry_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3758 (class 2606 OID 24994)
-- Name: mood_pain_log mood_pain_log_patient_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mood_pain_log
    ADD CONSTRAINT mood_pain_log_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES public.patient(id) ON DELETE CASCADE;


--
-- TOC entry 3725 (class 2606 OID 24634)
-- Name: patient patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3728 (class 2606 OID 24685)
-- Name: payment_method payment_method_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment_method
    ADD CONSTRAINT payment_method_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3731 (class 2606 OID 24706)
-- Name: payment payment_payment_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_payment_method_id_fkey FOREIGN KEY (payment_method_id) REFERENCES public.payment_method(id) ON DELETE SET NULL;


--
-- TOC entry 3732 (class 2606 OID 24701)
-- Name: payment payment_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscription(id) ON DELETE CASCADE;


--
-- TOC entry 3726 (class 2606 OID 24671)
-- Name: subscription subscription_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.plan(id);


--
-- TOC entry 3727 (class 2606 OID 24666)
-- Name: subscription subscription_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription
    ADD CONSTRAINT subscription_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3743 (class 2606 OID 24807)
-- Name: summary_metrics summary_metrics_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.summary_metrics
    ADD CONSTRAINT summary_metrics_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3746 (class 2606 OID 24829)
-- Name: symptom_entry symptom_entry_caregiver_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symptom_entry
    ADD CONSTRAINT symptom_entry_caregiver_user_id_fkey FOREIGN KEY (caregiver_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 3747 (class 2606 OID 24824)
-- Name: symptom_entry symptom_entry_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.symptom_entry
    ADD CONSTRAINT symptom_entry_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 3752 (class 2606 OID 24899)
-- Name: user_achievements user_achievements_achievement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_achievement_id_fkey FOREIGN KEY (achievement_id) REFERENCES public.achievement(id);


--
-- TOC entry 3753 (class 2606 OID 24894)
-- Name: user_achievements user_achievements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_achievements
    ADD CONSTRAINT user_achievements_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 3741 (class 2606 OID 24790)
-- Name: wearable_metric wearable_metric_patient_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.wearable_metric
    ADD CONSTRAINT wearable_metric_patient_user_id_fkey FOREIGN KEY (patient_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


-- Completed on 2025-09-23 01:36:04 UTC

--
-- PostgreSQL database dump complete
--

\unrestrict TQybt990hYGNFb21Y2qFpXzZLX0EFE9QImfJ1cZW298iSOAfWyRD8SRaBaSTR9w

