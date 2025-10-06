--
-- PostgreSQL database dump
--

\restrict XRcnsXJHiw8qWtjdTBJyPG7mhFJYcNx63zetq2tgE4HqxhwKFhl9W2igowjzRKS

-- Dumped from database version 15.14 (Debian 15.14-1.pgdg12+1)
-- Dumped by pg_dump version 15.14 (Debian 15.14-1.pgdg12+1)

-- Started on 2025-10-06 17:08:45 UTC

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
-- TOC entry 3593 (class 1262 OID 16384)
-- Name: careconnect; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE careconnect WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE careconnect OWNER TO postgres;

\unrestrict XRcnsXJHiw8qWtjdTBJyPG7mhFJYcNx63zetq2tgE4HqxhwKFhl9W2igowjzRKS
\connect careconnect
\restrict XRcnsXJHiw8qWtjdTBJyPG7mhFJYcNx63zetq2tgE4HqxhwKFhl9W2igowjzRKS

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
-- TOC entry 2 (class 3079 OID 16385)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 3594 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 3 (class 3079 OID 16396)
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- TOC entry 3595 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


-- Completed on 2025-10-06 17:08:45 UTC

--
-- PostgreSQL database dump complete
--

\unrestrict XRcnsXJHiw8qWtjdTBJyPG7mhFJYcNx63zetq2tgE4HqxhwKFhl9W2igowjzRKS

