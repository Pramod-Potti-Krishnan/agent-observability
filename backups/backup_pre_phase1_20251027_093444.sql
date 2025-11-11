--
-- PostgreSQL database dump
--

-- Dumped from database version 15.13
-- Dumped by pg_dump version 15.13

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
-- Name: timescaledb; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;


--
-- Name: EXTENSION timescaledb; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION timescaledb IS 'Enables scalable inserts and complex queries for time-series data (Community Edition)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _compressed_hypertable_6; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_6 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_6 OWNER TO postgres;

--
-- Name: _compressed_hypertable_7; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_7 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_7 OWNER TO postgres;

--
-- Name: _compressed_hypertable_8; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_8 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_8 OWNER TO postgres;

--
-- Name: traces; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.traces (
    id bigint NOT NULL,
    trace_id character varying(64) NOT NULL,
    workspace_id uuid NOT NULL,
    agent_id character varying(128) NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    latency_ms integer NOT NULL,
    input text,
    output text,
    error text,
    status character varying(20) DEFAULT 'success'::character varying,
    model character varying(64),
    model_provider character varying(32),
    tokens_input integer,
    tokens_output integer,
    tokens_total integer,
    cost_usd numeric(10,6),
    metadata jsonb,
    tags character varying(64)[],
    user_id character varying(128)
);


ALTER TABLE public.traces OWNER TO postgres;

--
-- Name: _direct_view_2; Type: VIEW; Schema: _timescaledb_internal; Owner: postgres
--

CREATE VIEW _timescaledb_internal._direct_view_2 AS
 SELECT public.time_bucket('01:00:00'::interval, traces."timestamp") AS hour,
    traces.workspace_id,
    traces.agent_id,
    traces.model,
    count(*) AS request_count,
    avg(traces.latency_ms) AS avg_latency_ms,
    percentile_cont((0.50)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p50_latency_ms,
    percentile_cont((0.95)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p95_latency_ms,
    percentile_cont((0.99)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p99_latency_ms,
    max(traces.latency_ms) AS max_latency_ms,
    sum(traces.tokens_input) AS total_tokens_input,
    sum(traces.tokens_output) AS total_tokens_output,
    sum(traces.cost_usd) AS total_cost_usd,
    count(*) FILTER (WHERE ((traces.status)::text = 'success'::text)) AS success_count,
    count(*) FILTER (WHERE ((traces.status)::text = 'error'::text)) AS error_count,
    count(*) FILTER (WHERE ((traces.status)::text = 'timeout'::text)) AS timeout_count
   FROM public.traces
  GROUP BY (public.time_bucket('01:00:00'::interval, traces."timestamp")), traces.workspace_id, traces.agent_id, traces.model;


ALTER TABLE _timescaledb_internal._direct_view_2 OWNER TO postgres;

--
-- Name: _direct_view_3; Type: VIEW; Schema: _timescaledb_internal; Owner: postgres
--

CREATE VIEW _timescaledb_internal._direct_view_3 AS
 SELECT public.time_bucket('1 day'::interval, traces."timestamp") AS day,
    traces.workspace_id,
    traces.agent_id,
    traces.model,
    count(*) AS request_count,
    avg(traces.latency_ms) AS avg_latency_ms,
    percentile_cont((0.50)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p50_latency_ms,
    percentile_cont((0.95)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p95_latency_ms,
    percentile_cont((0.99)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p99_latency_ms,
    sum(traces.tokens_input) AS total_tokens_input,
    sum(traces.tokens_output) AS total_tokens_output,
    sum(traces.cost_usd) AS total_cost_usd,
    count(*) FILTER (WHERE ((traces.status)::text = 'success'::text)) AS success_count,
    count(*) FILTER (WHERE ((traces.status)::text = 'error'::text)) AS error_count
   FROM public.traces
  GROUP BY (public.time_bucket('1 day'::interval, traces."timestamp")), traces.workspace_id, traces.agent_id, traces.model;


ALTER TABLE _timescaledb_internal._direct_view_3 OWNER TO postgres;

--
-- Name: _hyper_1_1_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_1_chunk (
    CONSTRAINT constraint_1 CHECK ((("timestamp" >= '2025-10-18 00:00:00+00'::timestamp with time zone) AND ("timestamp" < '2025-10-19 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.traces);


ALTER TABLE _timescaledb_internal._hyper_1_1_chunk OWNER TO postgres;

--
-- Name: _hyper_1_2_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_2_chunk (
    CONSTRAINT constraint_2 CHECK ((("timestamp" >= '2025-10-15 00:00:00+00'::timestamp with time zone) AND ("timestamp" < '2025-10-16 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.traces);


ALTER TABLE _timescaledb_internal._hyper_1_2_chunk OWNER TO postgres;

--
-- Name: _hyper_1_3_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_3_chunk (
    CONSTRAINT constraint_3 CHECK ((("timestamp" >= '2025-10-19 00:00:00+00'::timestamp with time zone) AND ("timestamp" < '2025-10-20 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.traces);


ALTER TABLE _timescaledb_internal._hyper_1_3_chunk OWNER TO postgres;

--
-- Name: _hyper_1_4_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_4_chunk (
    CONSTRAINT constraint_4 CHECK ((("timestamp" >= '2025-10-17 00:00:00+00'::timestamp with time zone) AND ("timestamp" < '2025-10-18 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.traces);


ALTER TABLE _timescaledb_internal._hyper_1_4_chunk OWNER TO postgres;

--
-- Name: _hyper_1_5_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_5_chunk (
    CONSTRAINT constraint_5 CHECK ((("timestamp" >= '2025-10-22 00:00:00+00'::timestamp with time zone) AND ("timestamp" < '2025-10-23 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.traces);


ALTER TABLE _timescaledb_internal._hyper_1_5_chunk OWNER TO postgres;

--
-- Name: _hyper_1_6_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_6_chunk (
    CONSTRAINT constraint_6 CHECK ((("timestamp" >= '2025-10-20 00:00:00+00'::timestamp with time zone) AND ("timestamp" < '2025-10-21 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.traces);


ALTER TABLE _timescaledb_internal._hyper_1_6_chunk OWNER TO postgres;

--
-- Name: _hyper_1_7_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_7_chunk (
    CONSTRAINT constraint_7 CHECK ((("timestamp" >= '2025-10-16 00:00:00+00'::timestamp with time zone) AND ("timestamp" < '2025-10-17 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.traces);


ALTER TABLE _timescaledb_internal._hyper_1_7_chunk OWNER TO postgres;

--
-- Name: _hyper_1_8_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_1_8_chunk (
    CONSTRAINT constraint_8 CHECK ((("timestamp" >= '2025-10-21 00:00:00+00'::timestamp with time zone) AND ("timestamp" < '2025-10-22 00:00:00+00'::timestamp with time zone)))
)
INHERITS (public.traces);


ALTER TABLE _timescaledb_internal._hyper_1_8_chunk OWNER TO postgres;

--
-- Name: _materialized_hypertable_2; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._materialized_hypertable_2 (
    hour timestamp with time zone NOT NULL,
    workspace_id uuid,
    agent_id character varying(128),
    model character varying(64),
    request_count bigint,
    avg_latency_ms numeric,
    p50_latency_ms double precision,
    p95_latency_ms double precision,
    p99_latency_ms double precision,
    max_latency_ms integer,
    total_tokens_input bigint,
    total_tokens_output bigint,
    total_cost_usd numeric,
    success_count bigint,
    error_count bigint,
    timeout_count bigint
);


ALTER TABLE _timescaledb_internal._materialized_hypertable_2 OWNER TO postgres;

--
-- Name: _hyper_2_9_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_2_9_chunk (
    CONSTRAINT constraint_9 CHECK (((hour >= '2025-10-19 00:00:00+00'::timestamp with time zone) AND (hour < '2025-10-29 00:00:00+00'::timestamp with time zone)))
)
INHERITS (_timescaledb_internal._materialized_hypertable_2);


ALTER TABLE _timescaledb_internal._hyper_2_9_chunk OWNER TO postgres;

--
-- Name: _materialized_hypertable_3; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._materialized_hypertable_3 (
    day timestamp with time zone NOT NULL,
    workspace_id uuid,
    agent_id character varying(128),
    model character varying(64),
    request_count bigint,
    avg_latency_ms numeric,
    p50_latency_ms double precision,
    p95_latency_ms double precision,
    p99_latency_ms double precision,
    total_tokens_input bigint,
    total_tokens_output bigint,
    total_cost_usd numeric,
    success_count bigint,
    error_count bigint
);


ALTER TABLE _timescaledb_internal._materialized_hypertable_3 OWNER TO postgres;

--
-- Name: _hyper_3_11_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_3_11_chunk (
    CONSTRAINT constraint_10 CHECK (((day >= '2025-10-19 00:00:00+00'::timestamp with time zone) AND (day < '2025-10-29 00:00:00+00'::timestamp with time zone)))
)
INHERITS (_timescaledb_internal._materialized_hypertable_3);


ALTER TABLE _timescaledb_internal._hyper_3_11_chunk OWNER TO postgres;

--
-- Name: _hyper_3_12_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal._hyper_3_12_chunk (
    CONSTRAINT constraint_11 CHECK (((day >= '2025-10-09 00:00:00+00'::timestamp with time zone) AND (day < '2025-10-19 00:00:00+00'::timestamp with time zone)))
)
INHERITS (_timescaledb_internal._materialized_hypertable_3);


ALTER TABLE _timescaledb_internal._hyper_3_12_chunk OWNER TO postgres;

--
-- Name: _partial_view_2; Type: VIEW; Schema: _timescaledb_internal; Owner: postgres
--

CREATE VIEW _timescaledb_internal._partial_view_2 AS
 SELECT public.time_bucket('01:00:00'::interval, traces."timestamp") AS hour,
    traces.workspace_id,
    traces.agent_id,
    traces.model,
    count(*) AS request_count,
    avg(traces.latency_ms) AS avg_latency_ms,
    percentile_cont((0.50)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p50_latency_ms,
    percentile_cont((0.95)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p95_latency_ms,
    percentile_cont((0.99)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p99_latency_ms,
    max(traces.latency_ms) AS max_latency_ms,
    sum(traces.tokens_input) AS total_tokens_input,
    sum(traces.tokens_output) AS total_tokens_output,
    sum(traces.cost_usd) AS total_cost_usd,
    count(*) FILTER (WHERE ((traces.status)::text = 'success'::text)) AS success_count,
    count(*) FILTER (WHERE ((traces.status)::text = 'error'::text)) AS error_count,
    count(*) FILTER (WHERE ((traces.status)::text = 'timeout'::text)) AS timeout_count
   FROM public.traces
  GROUP BY (public.time_bucket('01:00:00'::interval, traces."timestamp")), traces.workspace_id, traces.agent_id, traces.model;


ALTER TABLE _timescaledb_internal._partial_view_2 OWNER TO postgres;

--
-- Name: _partial_view_3; Type: VIEW; Schema: _timescaledb_internal; Owner: postgres
--

CREATE VIEW _timescaledb_internal._partial_view_3 AS
 SELECT public.time_bucket('1 day'::interval, traces."timestamp") AS day,
    traces.workspace_id,
    traces.agent_id,
    traces.model,
    count(*) AS request_count,
    avg(traces.latency_ms) AS avg_latency_ms,
    percentile_cont((0.50)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p50_latency_ms,
    percentile_cont((0.95)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p95_latency_ms,
    percentile_cont((0.99)::double precision) WITHIN GROUP (ORDER BY ((traces.latency_ms)::double precision)) AS p99_latency_ms,
    sum(traces.tokens_input) AS total_tokens_input,
    sum(traces.tokens_output) AS total_tokens_output,
    sum(traces.cost_usd) AS total_cost_usd,
    count(*) FILTER (WHERE ((traces.status)::text = 'success'::text)) AS success_count,
    count(*) FILTER (WHERE ((traces.status)::text = 'error'::text)) AS error_count
   FROM public.traces
  GROUP BY (public.time_bucket('1 day'::interval, traces."timestamp")), traces.workspace_id, traces.agent_id, traces.model;


ALTER TABLE _timescaledb_internal._partial_view_3 OWNER TO postgres;

--
-- Name: compress_hyper_6_10_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal.compress_hyper_6_10_chunk (
    _ts_meta_count integer,
    workspace_id uuid,
    agent_id character varying(128),
    id _timescaledb_internal.compressed_data,
    _ts_meta_min_2 character varying(64),
    _ts_meta_max_2 character varying(64),
    trace_id _timescaledb_internal.compressed_data,
    _ts_meta_min_1 timestamp with time zone,
    _ts_meta_max_1 timestamp with time zone,
    "timestamp" _timescaledb_internal.compressed_data,
    latency_ms _timescaledb_internal.compressed_data,
    input _timescaledb_internal.compressed_data,
    output _timescaledb_internal.compressed_data,
    error _timescaledb_internal.compressed_data,
    _ts_meta_min_4 character varying(20),
    _ts_meta_max_4 character varying(20),
    status _timescaledb_internal.compressed_data,
    _ts_meta_min_3 character varying(64),
    _ts_meta_max_3 character varying(64),
    model _timescaledb_internal.compressed_data,
    model_provider _timescaledb_internal.compressed_data,
    tokens_input _timescaledb_internal.compressed_data,
    tokens_output _timescaledb_internal.compressed_data,
    tokens_total _timescaledb_internal.compressed_data,
    cost_usd _timescaledb_internal.compressed_data,
    metadata _timescaledb_internal.compressed_data,
    _ts_meta_min_5 character varying(64)[],
    _ts_meta_max_5 character varying(64)[],
    tags _timescaledb_internal.compressed_data,
    _ts_meta_v2_bloom1_user_id _timescaledb_internal.bloom1,
    user_id _timescaledb_internal.compressed_data
)
WITH (toast_tuple_target='128');
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_count SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN workspace_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN agent_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_min_2 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_min_2 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_max_2 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_max_2 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN trace_id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN trace_id SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_min_1 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_max_1 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN "timestamp" SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN latency_ms SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN input SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN input SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN output SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN output SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN error SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN error SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_min_4 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_min_4 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_max_4 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_max_4 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN status SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN status SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_min_3 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_min_3 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_max_3 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_max_3 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN model SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN model SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN model_provider SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN model_provider SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN tokens_input SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN tokens_output SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN tokens_total SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN cost_usd SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN cost_usd SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN metadata SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN metadata SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_min_5 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_min_5 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_max_5 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_max_5 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN tags SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN tags SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_v2_bloom1_user_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN _ts_meta_v2_bloom1_user_id SET STORAGE EXTERNAL;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN user_id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_10_chunk ALTER COLUMN user_id SET STORAGE EXTENDED;


ALTER TABLE _timescaledb_internal.compress_hyper_6_10_chunk OWNER TO postgres;

--
-- Name: compress_hyper_6_13_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal.compress_hyper_6_13_chunk (
    _ts_meta_count integer,
    workspace_id uuid,
    agent_id character varying(128),
    id _timescaledb_internal.compressed_data,
    _ts_meta_min_2 character varying(64),
    _ts_meta_max_2 character varying(64),
    trace_id _timescaledb_internal.compressed_data,
    _ts_meta_min_1 timestamp with time zone,
    _ts_meta_max_1 timestamp with time zone,
    "timestamp" _timescaledb_internal.compressed_data,
    latency_ms _timescaledb_internal.compressed_data,
    input _timescaledb_internal.compressed_data,
    output _timescaledb_internal.compressed_data,
    error _timescaledb_internal.compressed_data,
    _ts_meta_min_4 character varying(20),
    _ts_meta_max_4 character varying(20),
    status _timescaledb_internal.compressed_data,
    _ts_meta_min_3 character varying(64),
    _ts_meta_max_3 character varying(64),
    model _timescaledb_internal.compressed_data,
    model_provider _timescaledb_internal.compressed_data,
    tokens_input _timescaledb_internal.compressed_data,
    tokens_output _timescaledb_internal.compressed_data,
    tokens_total _timescaledb_internal.compressed_data,
    cost_usd _timescaledb_internal.compressed_data,
    metadata _timescaledb_internal.compressed_data,
    _ts_meta_min_5 character varying(64)[],
    _ts_meta_max_5 character varying(64)[],
    tags _timescaledb_internal.compressed_data,
    _ts_meta_v2_bloom1_user_id _timescaledb_internal.bloom1,
    user_id _timescaledb_internal.compressed_data
)
WITH (toast_tuple_target='128');
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_count SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN workspace_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN agent_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_min_2 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_min_2 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_max_2 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_max_2 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN trace_id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN trace_id SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_min_1 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_max_1 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN "timestamp" SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN latency_ms SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN input SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN input SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN output SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN output SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN error SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN error SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_min_4 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_min_4 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_max_4 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_max_4 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN status SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN status SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_min_3 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_min_3 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_max_3 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_max_3 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN model SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN model SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN model_provider SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN model_provider SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN tokens_input SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN tokens_output SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN tokens_total SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN cost_usd SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN cost_usd SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN metadata SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN metadata SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_min_5 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_min_5 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_max_5 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_max_5 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN tags SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN tags SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_v2_bloom1_user_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN _ts_meta_v2_bloom1_user_id SET STORAGE EXTERNAL;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN user_id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_13_chunk ALTER COLUMN user_id SET STORAGE EXTENDED;


ALTER TABLE _timescaledb_internal.compress_hyper_6_13_chunk OWNER TO postgres;

--
-- Name: compress_hyper_6_14_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal.compress_hyper_6_14_chunk (
    _ts_meta_count integer,
    workspace_id uuid,
    agent_id character varying(128),
    id _timescaledb_internal.compressed_data,
    _ts_meta_min_2 character varying(64),
    _ts_meta_max_2 character varying(64),
    trace_id _timescaledb_internal.compressed_data,
    _ts_meta_min_1 timestamp with time zone,
    _ts_meta_max_1 timestamp with time zone,
    "timestamp" _timescaledb_internal.compressed_data,
    latency_ms _timescaledb_internal.compressed_data,
    input _timescaledb_internal.compressed_data,
    output _timescaledb_internal.compressed_data,
    error _timescaledb_internal.compressed_data,
    _ts_meta_min_4 character varying(20),
    _ts_meta_max_4 character varying(20),
    status _timescaledb_internal.compressed_data,
    _ts_meta_min_3 character varying(64),
    _ts_meta_max_3 character varying(64),
    model _timescaledb_internal.compressed_data,
    model_provider _timescaledb_internal.compressed_data,
    tokens_input _timescaledb_internal.compressed_data,
    tokens_output _timescaledb_internal.compressed_data,
    tokens_total _timescaledb_internal.compressed_data,
    cost_usd _timescaledb_internal.compressed_data,
    metadata _timescaledb_internal.compressed_data,
    _ts_meta_min_5 character varying(64)[],
    _ts_meta_max_5 character varying(64)[],
    tags _timescaledb_internal.compressed_data,
    _ts_meta_v2_bloom1_user_id _timescaledb_internal.bloom1,
    user_id _timescaledb_internal.compressed_data
)
WITH (toast_tuple_target='128');
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_count SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN workspace_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN agent_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_min_2 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_min_2 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_max_2 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_max_2 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN trace_id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN trace_id SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_min_1 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_max_1 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN "timestamp" SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN latency_ms SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN input SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN input SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN output SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN output SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN error SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN error SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_min_4 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_min_4 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_max_4 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_max_4 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN status SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN status SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_min_3 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_min_3 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_max_3 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_max_3 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN model SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN model SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN model_provider SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN model_provider SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN tokens_input SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN tokens_output SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN tokens_total SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN cost_usd SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN cost_usd SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN metadata SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN metadata SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_min_5 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_min_5 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_max_5 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_max_5 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN tags SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN tags SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_v2_bloom1_user_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN _ts_meta_v2_bloom1_user_id SET STORAGE EXTERNAL;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN user_id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_14_chunk ALTER COLUMN user_id SET STORAGE EXTENDED;


ALTER TABLE _timescaledb_internal.compress_hyper_6_14_chunk OWNER TO postgres;

--
-- Name: compress_hyper_6_15_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal.compress_hyper_6_15_chunk (
    _ts_meta_count integer,
    workspace_id uuid,
    agent_id character varying(128),
    id _timescaledb_internal.compressed_data,
    _ts_meta_min_2 character varying(64),
    _ts_meta_max_2 character varying(64),
    trace_id _timescaledb_internal.compressed_data,
    _ts_meta_min_1 timestamp with time zone,
    _ts_meta_max_1 timestamp with time zone,
    "timestamp" _timescaledb_internal.compressed_data,
    latency_ms _timescaledb_internal.compressed_data,
    input _timescaledb_internal.compressed_data,
    output _timescaledb_internal.compressed_data,
    error _timescaledb_internal.compressed_data,
    _ts_meta_min_4 character varying(20),
    _ts_meta_max_4 character varying(20),
    status _timescaledb_internal.compressed_data,
    _ts_meta_min_3 character varying(64),
    _ts_meta_max_3 character varying(64),
    model _timescaledb_internal.compressed_data,
    model_provider _timescaledb_internal.compressed_data,
    tokens_input _timescaledb_internal.compressed_data,
    tokens_output _timescaledb_internal.compressed_data,
    tokens_total _timescaledb_internal.compressed_data,
    cost_usd _timescaledb_internal.compressed_data,
    metadata _timescaledb_internal.compressed_data,
    _ts_meta_min_5 character varying(64)[],
    _ts_meta_max_5 character varying(64)[],
    tags _timescaledb_internal.compressed_data,
    _ts_meta_v2_bloom1_user_id _timescaledb_internal.bloom1,
    user_id _timescaledb_internal.compressed_data
)
WITH (toast_tuple_target='128');
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_count SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN workspace_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN agent_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_min_2 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_min_2 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_max_2 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_max_2 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN trace_id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN trace_id SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_min_1 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_max_1 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN "timestamp" SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN latency_ms SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN input SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN input SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN output SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN output SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN error SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN error SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_min_4 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_min_4 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_max_4 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_max_4 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN status SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN status SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_min_3 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_min_3 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_max_3 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_max_3 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN model SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN model SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN model_provider SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN model_provider SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN tokens_input SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN tokens_output SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN tokens_total SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN cost_usd SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN cost_usd SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN metadata SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN metadata SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_min_5 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_min_5 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_max_5 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_max_5 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN tags SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN tags SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_v2_bloom1_user_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN _ts_meta_v2_bloom1_user_id SET STORAGE EXTERNAL;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN user_id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_15_chunk ALTER COLUMN user_id SET STORAGE EXTENDED;


ALTER TABLE _timescaledb_internal.compress_hyper_6_15_chunk OWNER TO postgres;

--
-- Name: compress_hyper_6_16_chunk; Type: TABLE; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TABLE _timescaledb_internal.compress_hyper_6_16_chunk (
    _ts_meta_count integer,
    workspace_id uuid,
    agent_id character varying(128),
    id _timescaledb_internal.compressed_data,
    _ts_meta_min_2 character varying(64),
    _ts_meta_max_2 character varying(64),
    trace_id _timescaledb_internal.compressed_data,
    _ts_meta_min_1 timestamp with time zone,
    _ts_meta_max_1 timestamp with time zone,
    "timestamp" _timescaledb_internal.compressed_data,
    latency_ms _timescaledb_internal.compressed_data,
    input _timescaledb_internal.compressed_data,
    output _timescaledb_internal.compressed_data,
    error _timescaledb_internal.compressed_data,
    _ts_meta_min_4 character varying(20),
    _ts_meta_max_4 character varying(20),
    status _timescaledb_internal.compressed_data,
    _ts_meta_min_3 character varying(64),
    _ts_meta_max_3 character varying(64),
    model _timescaledb_internal.compressed_data,
    model_provider _timescaledb_internal.compressed_data,
    tokens_input _timescaledb_internal.compressed_data,
    tokens_output _timescaledb_internal.compressed_data,
    tokens_total _timescaledb_internal.compressed_data,
    cost_usd _timescaledb_internal.compressed_data,
    metadata _timescaledb_internal.compressed_data,
    _ts_meta_min_5 character varying(64)[],
    _ts_meta_max_5 character varying(64)[],
    tags _timescaledb_internal.compressed_data,
    _ts_meta_v2_bloom1_user_id _timescaledb_internal.bloom1,
    user_id _timescaledb_internal.compressed_data
)
WITH (toast_tuple_target='128');
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_count SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN workspace_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN agent_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_min_2 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_min_2 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_max_2 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_max_2 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN trace_id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN trace_id SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_min_1 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_max_1 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN "timestamp" SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN latency_ms SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN input SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN input SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN output SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN output SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN error SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN error SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_min_4 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_min_4 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_max_4 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_max_4 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN status SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN status SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_min_3 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_min_3 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_max_3 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_max_3 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN model SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN model SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN model_provider SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN model_provider SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN tokens_input SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN tokens_output SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN tokens_total SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN cost_usd SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN cost_usd SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN metadata SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN metadata SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_min_5 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_min_5 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_max_5 SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_max_5 SET STORAGE PLAIN;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN tags SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN tags SET STORAGE EXTENDED;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_v2_bloom1_user_id SET STATISTICS 1000;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN _ts_meta_v2_bloom1_user_id SET STORAGE EXTERNAL;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN user_id SET STATISTICS 0;
ALTER TABLE ONLY _timescaledb_internal.compress_hyper_6_16_chunk ALTER COLUMN user_id SET STORAGE EXTENDED;


ALTER TABLE _timescaledb_internal.compress_hyper_6_16_chunk OWNER TO postgres;

--
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events (
    id bigint NOT NULL,
    event_id character varying(64) NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    workspace_id uuid NOT NULL,
    agent_id character varying(128),
    event_type character varying(32) NOT NULL,
    severity character varying(16) NOT NULL,
    title character varying(256) NOT NULL,
    description text,
    metadata jsonb,
    acknowledged boolean DEFAULT false,
    acknowledged_at timestamp with time zone,
    acknowledged_by character varying(128)
);


ALTER TABLE public.events OWNER TO postgres;

--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.events_id_seq OWNER TO postgres;

--
-- Name: events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.events_id_seq OWNED BY public.events.id;


--
-- Name: performance_metrics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.performance_metrics (
    "timestamp" timestamp with time zone NOT NULL,
    workspace_id uuid NOT NULL,
    agent_id character varying(128) NOT NULL,
    metric_name character varying(64) NOT NULL,
    value double precision NOT NULL,
    unit character varying(32),
    metadata jsonb
);


ALTER TABLE public.performance_metrics OWNER TO postgres;

--
-- Name: traces_daily; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.traces_daily AS
 SELECT _materialized_hypertable_3.day,
    _materialized_hypertable_3.workspace_id,
    _materialized_hypertable_3.agent_id,
    _materialized_hypertable_3.model,
    _materialized_hypertable_3.request_count,
    _materialized_hypertable_3.avg_latency_ms,
    _materialized_hypertable_3.p50_latency_ms,
    _materialized_hypertable_3.p95_latency_ms,
    _materialized_hypertable_3.p99_latency_ms,
    _materialized_hypertable_3.total_tokens_input,
    _materialized_hypertable_3.total_tokens_output,
    _materialized_hypertable_3.total_cost_usd,
    _materialized_hypertable_3.success_count,
    _materialized_hypertable_3.error_count
   FROM _timescaledb_internal._materialized_hypertable_3;


ALTER TABLE public.traces_daily OWNER TO postgres;

--
-- Name: traces_hourly; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.traces_hourly AS
 SELECT _materialized_hypertable_2.hour,
    _materialized_hypertable_2.workspace_id,
    _materialized_hypertable_2.agent_id,
    _materialized_hypertable_2.model,
    _materialized_hypertable_2.request_count,
    _materialized_hypertable_2.avg_latency_ms,
    _materialized_hypertable_2.p50_latency_ms,
    _materialized_hypertable_2.p95_latency_ms,
    _materialized_hypertable_2.p99_latency_ms,
    _materialized_hypertable_2.max_latency_ms,
    _materialized_hypertable_2.total_tokens_input,
    _materialized_hypertable_2.total_tokens_output,
    _materialized_hypertable_2.total_cost_usd,
    _materialized_hypertable_2.success_count,
    _materialized_hypertable_2.error_count,
    _materialized_hypertable_2.timeout_count
   FROM _timescaledb_internal._materialized_hypertable_2;


ALTER TABLE public.traces_hourly OWNER TO postgres;

--
-- Name: traces_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.traces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.traces_id_seq OWNER TO postgres;

--
-- Name: traces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.traces_id_seq OWNED BY public.traces.id;


--
-- Name: _hyper_1_1_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_1_chunk ALTER COLUMN id SET DEFAULT nextval('public.traces_id_seq'::regclass);


--
-- Name: _hyper_1_1_chunk timestamp; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_1_chunk ALTER COLUMN "timestamp" SET DEFAULT now();


--
-- Name: _hyper_1_1_chunk status; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_1_chunk ALTER COLUMN status SET DEFAULT 'success'::character varying;


--
-- Name: _hyper_1_2_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk ALTER COLUMN id SET DEFAULT nextval('public.traces_id_seq'::regclass);


--
-- Name: _hyper_1_2_chunk timestamp; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk ALTER COLUMN "timestamp" SET DEFAULT now();


--
-- Name: _hyper_1_2_chunk status; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk ALTER COLUMN status SET DEFAULT 'success'::character varying;


--
-- Name: _hyper_1_3_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_3_chunk ALTER COLUMN id SET DEFAULT nextval('public.traces_id_seq'::regclass);


--
-- Name: _hyper_1_3_chunk timestamp; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_3_chunk ALTER COLUMN "timestamp" SET DEFAULT now();


--
-- Name: _hyper_1_3_chunk status; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_3_chunk ALTER COLUMN status SET DEFAULT 'success'::character varying;


--
-- Name: _hyper_1_4_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_4_chunk ALTER COLUMN id SET DEFAULT nextval('public.traces_id_seq'::regclass);


--
-- Name: _hyper_1_4_chunk timestamp; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_4_chunk ALTER COLUMN "timestamp" SET DEFAULT now();


--
-- Name: _hyper_1_4_chunk status; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_4_chunk ALTER COLUMN status SET DEFAULT 'success'::character varying;


--
-- Name: _hyper_1_5_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_5_chunk ALTER COLUMN id SET DEFAULT nextval('public.traces_id_seq'::regclass);


--
-- Name: _hyper_1_5_chunk timestamp; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_5_chunk ALTER COLUMN "timestamp" SET DEFAULT now();


--
-- Name: _hyper_1_5_chunk status; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_5_chunk ALTER COLUMN status SET DEFAULT 'success'::character varying;


--
-- Name: _hyper_1_6_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_6_chunk ALTER COLUMN id SET DEFAULT nextval('public.traces_id_seq'::regclass);


--
-- Name: _hyper_1_6_chunk timestamp; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_6_chunk ALTER COLUMN "timestamp" SET DEFAULT now();


--
-- Name: _hyper_1_6_chunk status; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_6_chunk ALTER COLUMN status SET DEFAULT 'success'::character varying;


--
-- Name: _hyper_1_7_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_7_chunk ALTER COLUMN id SET DEFAULT nextval('public.traces_id_seq'::regclass);


--
-- Name: _hyper_1_7_chunk timestamp; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_7_chunk ALTER COLUMN "timestamp" SET DEFAULT now();


--
-- Name: _hyper_1_7_chunk status; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_7_chunk ALTER COLUMN status SET DEFAULT 'success'::character varying;


--
-- Name: _hyper_1_8_chunk id; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk ALTER COLUMN id SET DEFAULT nextval('public.traces_id_seq'::regclass);


--
-- Name: _hyper_1_8_chunk timestamp; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk ALTER COLUMN "timestamp" SET DEFAULT now();


--
-- Name: _hyper_1_8_chunk status; Type: DEFAULT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk ALTER COLUMN status SET DEFAULT 'success'::character varying;


--
-- Name: events id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events ALTER COLUMN id SET DEFAULT nextval('public.events_id_seq'::regclass);


--
-- Name: traces id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traces ALTER COLUMN id SET DEFAULT nextval('public.traces_id_seq'::regclass);


--
-- Data for Name: hypertable; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.hypertable (id, schema_name, table_name, associated_schema_name, associated_table_prefix, num_dimensions, chunk_sizing_func_schema, chunk_sizing_func_name, chunk_target_size, compression_state, compressed_hypertable_id, status) FROM stdin;
2	_timescaledb_internal	_materialized_hypertable_2	_timescaledb_internal	_hyper_2	1	_timescaledb_functions	calculate_chunk_interval	0	0	\N	0
3	_timescaledb_internal	_materialized_hypertable_3	_timescaledb_internal	_hyper_3	1	_timescaledb_functions	calculate_chunk_interval	0	0	\N	0
6	_timescaledb_internal	_compressed_hypertable_6	_timescaledb_internal	_hyper_6	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
1	public	traces	_timescaledb_internal	_hyper_1	1	_timescaledb_functions	calculate_chunk_interval	0	1	6	0
7	_timescaledb_internal	_compressed_hypertable_7	_timescaledb_internal	_hyper_7	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
4	public	performance_metrics	_timescaledb_internal	_hyper_4	1	_timescaledb_functions	calculate_chunk_interval	0	1	7	0
8	_timescaledb_internal	_compressed_hypertable_8	_timescaledb_internal	_hyper_8	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
5	public	events	_timescaledb_internal	_hyper_5	1	_timescaledb_functions	calculate_chunk_interval	0	1	8	0
\.


--
-- Data for Name: chunk; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.chunk (id, hypertable_id, schema_name, table_name, compressed_chunk_id, dropped, status, osm_chunk, creation_time) FROM stdin;
5	1	_timescaledb_internal	_hyper_1_5_chunk	\N	f	0	f	2025-10-22 19:31:25.380906+00
6	1	_timescaledb_internal	_hyper_1_6_chunk	\N	f	0	f	2025-10-22 19:31:25.412675+00
8	1	_timescaledb_internal	_hyper_1_8_chunk	\N	f	0	f	2025-10-22 19:31:25.481193+00
9	2	_timescaledb_internal	_hyper_2_9_chunk	\N	f	0	f	2025-10-22 20:41:06.092834+00
10	6	_timescaledb_internal	compress_hyper_6_10_chunk	\N	f	0	f	2025-10-23 03:14:09.368314+00
2	1	_timescaledb_internal	_hyper_1_2_chunk	10	f	1	f	2025-10-22 19:31:25.285468+00
11	3	_timescaledb_internal	_hyper_3_11_chunk	\N	f	0	f	2025-10-23 16:28:42.262099+00
12	3	_timescaledb_internal	_hyper_3_12_chunk	\N	f	0	f	2025-10-23 16:28:42.317733+00
13	6	_timescaledb_internal	compress_hyper_6_13_chunk	\N	f	0	f	2025-10-24 04:35:25.535615+00
7	1	_timescaledb_internal	_hyper_1_7_chunk	13	f	1	f	2025-10-22 19:31:25.449707+00
14	6	_timescaledb_internal	compress_hyper_6_14_chunk	\N	f	0	f	2025-10-25 05:33:26.03472+00
4	1	_timescaledb_internal	_hyper_1_4_chunk	14	f	1	f	2025-10-22 19:31:25.351551+00
15	6	_timescaledb_internal	compress_hyper_6_15_chunk	\N	f	0	f	2025-10-26 05:47:09.226641+00
1	1	_timescaledb_internal	_hyper_1_1_chunk	15	f	1	f	2025-10-22 19:31:25.214839+00
16	6	_timescaledb_internal	compress_hyper_6_16_chunk	\N	f	0	f	2025-10-27 06:13:17.748203+00
3	1	_timescaledb_internal	_hyper_1_3_chunk	16	f	1	f	2025-10-22 19:31:25.320905+00
\.


--
-- Data for Name: chunk_column_stats; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.chunk_column_stats (id, hypertable_id, chunk_id, column_name, range_start, range_end, valid) FROM stdin;
\.


--
-- Data for Name: dimension; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.dimension (id, hypertable_id, column_name, column_type, aligned, num_slices, partitioning_func_schema, partitioning_func, interval_length, compress_interval_length, integer_now_func_schema, integer_now_func) FROM stdin;
1	1	timestamp	timestamp with time zone	t	\N	\N	\N	86400000000	\N	\N	\N
2	2	hour	timestamp with time zone	t	\N	\N	\N	864000000000	\N	\N	\N
3	3	day	timestamp with time zone	t	\N	\N	\N	864000000000	\N	\N	\N
4	4	timestamp	timestamp with time zone	t	\N	\N	\N	86400000000	\N	\N	\N
5	5	timestamp	timestamp with time zone	t	\N	\N	\N	86400000000	\N	\N	\N
\.


--
-- Data for Name: dimension_slice; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.dimension_slice (id, dimension_id, range_start, range_end) FROM stdin;
1	1	1760745600000000	1760832000000000
2	1	1760486400000000	1760572800000000
3	1	1760832000000000	1760918400000000
4	1	1760659200000000	1760745600000000
5	1	1761091200000000	1761177600000000
6	1	1760918400000000	1761004800000000
7	1	1760572800000000	1760659200000000
8	1	1761004800000000	1761091200000000
9	2	1760832000000000	1761696000000000
10	3	1760832000000000	1761696000000000
11	3	1759968000000000	1760832000000000
\.


--
-- Data for Name: chunk_constraint; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.chunk_constraint (chunk_id, dimension_slice_id, constraint_name, hypertable_constraint_name) FROM stdin;
1	1	constraint_1	\N
1	\N	1_1_traces_pkey	traces_pkey
2	2	constraint_2	\N
2	\N	2_2_traces_pkey	traces_pkey
3	3	constraint_3	\N
3	\N	3_3_traces_pkey	traces_pkey
4	4	constraint_4	\N
4	\N	4_4_traces_pkey	traces_pkey
5	5	constraint_5	\N
5	\N	5_5_traces_pkey	traces_pkey
6	6	constraint_6	\N
6	\N	6_6_traces_pkey	traces_pkey
7	7	constraint_7	\N
7	\N	7_7_traces_pkey	traces_pkey
8	8	constraint_8	\N
8	\N	8_8_traces_pkey	traces_pkey
9	9	constraint_9	\N
11	10	constraint_10	\N
12	11	constraint_11	\N
\.


--
-- Data for Name: compression_chunk_size; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.compression_chunk_size (chunk_id, compressed_chunk_id, uncompressed_heap_size, uncompressed_toast_size, uncompressed_index_size, compressed_heap_size, compressed_toast_size, compressed_index_size, numrows_pre_compression, numrows_post_compression, numrows_frozen_immediately) FROM stdin;
2	10	73728	8192	294912	16384	65536	16384	56	4	4
7	13	278528	8192	622592	16384	73728	16384	297	4	4
4	14	221184	8192	540672	16384	73728	16384	228	4	4
1	15	270336	8192	614400	16384	73728	16384	289	4	4
3	16	262144	8192	573440	16384	73728	16384	274	4	4
\.


--
-- Data for Name: compression_settings; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.compression_settings (relid, compress_relid, segmentby, orderby, orderby_desc, orderby_nullsfirst, index) FROM stdin;
public.traces	\N	{workspace_id,agent_id}	\N	\N	\N	\N
public.performance_metrics	\N	{workspace_id,agent_id}	\N	\N	\N	\N
public.events	\N	{workspace_id,event_type}	\N	\N	\N	\N
_timescaledb_internal._hyper_1_2_chunk	_timescaledb_internal.compress_hyper_6_10_chunk	{workspace_id,agent_id}	{timestamp,trace_id,model,status,tags}	{t,f,f,f,f}	{t,f,f,f,f}	[{"type": "bloom", "column": "user_id", "source": "default"}, {"type": "minmax", "column": "timestamp", "source": "orderby"}, {"type": "minmax", "column": "trace_id", "source": "orderby"}, {"type": "minmax", "column": "model", "source": "orderby"}, {"type": "minmax", "column": "status", "source": "orderby"}, {"type": "minmax", "column": "tags", "source": "orderby"}]
_timescaledb_internal._hyper_1_7_chunk	_timescaledb_internal.compress_hyper_6_13_chunk	{workspace_id,agent_id}	{timestamp,trace_id,model,status,tags}	{t,f,f,f,f}	{t,f,f,f,f}	[{"type": "bloom", "column": "user_id", "source": "default"}, {"type": "minmax", "column": "timestamp", "source": "orderby"}, {"type": "minmax", "column": "trace_id", "source": "orderby"}, {"type": "minmax", "column": "model", "source": "orderby"}, {"type": "minmax", "column": "status", "source": "orderby"}, {"type": "minmax", "column": "tags", "source": "orderby"}]
_timescaledb_internal._hyper_1_4_chunk	_timescaledb_internal.compress_hyper_6_14_chunk	{workspace_id,agent_id}	{timestamp,trace_id,model,status,tags}	{t,f,f,f,f}	{t,f,f,f,f}	[{"type": "bloom", "column": "user_id", "source": "default"}, {"type": "minmax", "column": "timestamp", "source": "orderby"}, {"type": "minmax", "column": "trace_id", "source": "orderby"}, {"type": "minmax", "column": "model", "source": "orderby"}, {"type": "minmax", "column": "status", "source": "orderby"}, {"type": "minmax", "column": "tags", "source": "orderby"}]
_timescaledb_internal._hyper_1_1_chunk	_timescaledb_internal.compress_hyper_6_15_chunk	{workspace_id,agent_id}	{timestamp,trace_id,model,status,tags}	{t,f,f,f,f}	{t,f,f,f,f}	[{"type": "bloom", "column": "user_id", "source": "default"}, {"type": "minmax", "column": "timestamp", "source": "orderby"}, {"type": "minmax", "column": "trace_id", "source": "orderby"}, {"type": "minmax", "column": "model", "source": "orderby"}, {"type": "minmax", "column": "status", "source": "orderby"}, {"type": "minmax", "column": "tags", "source": "orderby"}]
_timescaledb_internal._hyper_1_3_chunk	_timescaledb_internal.compress_hyper_6_16_chunk	{workspace_id,agent_id}	{timestamp,trace_id,model,status,tags}	{t,f,f,f,f}	{t,f,f,f,f}	[{"type": "bloom", "column": "user_id", "source": "default"}, {"type": "minmax", "column": "timestamp", "source": "orderby"}, {"type": "minmax", "column": "trace_id", "source": "orderby"}, {"type": "minmax", "column": "model", "source": "orderby"}, {"type": "minmax", "column": "status", "source": "orderby"}, {"type": "minmax", "column": "tags", "source": "orderby"}]
\.


--
-- Data for Name: continuous_agg; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_agg (mat_hypertable_id, raw_hypertable_id, parent_mat_hypertable_id, user_view_schema, user_view_name, partial_view_schema, partial_view_name, direct_view_schema, direct_view_name, materialized_only, finalized) FROM stdin;
2	1	\N	public	traces_hourly	_timescaledb_internal	_partial_view_2	_timescaledb_internal	_direct_view_2	t	t
3	1	\N	public	traces_daily	_timescaledb_internal	_partial_view_3	_timescaledb_internal	_direct_view_3	t	t
\.


--
-- Data for Name: continuous_agg_migrate_plan; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_agg_migrate_plan (mat_hypertable_id, start_ts, end_ts, user_view_definition) FROM stdin;
\.


--
-- Data for Name: continuous_agg_migrate_plan_step; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_agg_migrate_plan_step (mat_hypertable_id, step_id, status, start_ts, end_ts, type, config) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_bucket_function; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_bucket_function (mat_hypertable_id, bucket_func, bucket_width, bucket_origin, bucket_offset, bucket_timezone, bucket_fixed_width) FROM stdin;
2	public.time_bucket(interval,timestamp with time zone)	01:00:00	\N	\N	\N	t
3	public.time_bucket(interval,timestamp with time zone)	1 day	\N	\N	\N	t
\.


--
-- Data for Name: continuous_aggs_hypertable_invalidation_log; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_hypertable_invalidation_log (hypertable_id, lowest_modified_value, greatest_modified_value) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_invalidation_threshold; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_invalidation_threshold (hypertable_id, watermark) FROM stdin;
1	1761570000000000
\.


--
-- Data for Name: continuous_aggs_materialization_invalidation_log; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_materialization_invalidation_log (materialization_id, lowest_modified_value, greatest_modified_value) FROM stdin;
2	1761307200000000	1761310799999999
2	1761516000000000	1761519599999999
2	1761328800000000	1761332399999999
2	1761166800000000	1761170399999999
2	1761350400000000	1761353999999999
2	-9223372036854775808	1761163199999999
2	1761177600000000	1761181199999999
2	1761537600000000	1761541199999999
2	1761562800000000	1761566399999999
2	1761570000000000	9223372036854775807
2	1761217200000000	1761220799999999
2	1761224400000000	1761227999999999
3	-9223372036854775808	1760659199999999
2	1761235200000000	1761238799999999
2	1761274800000000	1761278399999999
2	1761476400000000	1761479999999999
2	1761487200000000	1761490799999999
3	1761350400000000	9223372036854775807
2	1761498000000000	1761501599999999
\.


--
-- Data for Name: continuous_aggs_materialization_ranges; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_materialization_ranges (materialization_id, lowest_modified_value, greatest_modified_value) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_watermark; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.continuous_aggs_watermark (mat_hypertable_id, watermark) FROM stdin;
2	1761159600000000
3	1761177600000000
\.


--
-- Data for Name: metadata; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.metadata (key, value, include_in_telemetry) FROM stdin;
install_timestamp	2025-10-22 15:14:08.852404+00	t
timescaledb_version	2.22.1	f
exported_uuid	ff545e19-f0a8-4198-904a-b593bc899b12	t
\.


--
-- Data for Name: tablespace; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: postgres
--

COPY _timescaledb_catalog.tablespace (id, hypertable_id, tablespace_name) FROM stdin;
\.


--
-- Data for Name: bgw_job; Type: TABLE DATA; Schema: _timescaledb_config; Owner: postgres
--

COPY _timescaledb_config.bgw_job (id, application_name, schedule_interval, max_runtime, max_retries, retry_period, proc_schema, proc_name, owner, scheduled, fixed_schedule, initial_start, hypertable_id, config, check_schema, check_name, timezone) FROM stdin;
1000	Retention Policy [1000]	1 day	00:05:00	-1	00:05:00	_timescaledb_functions	policy_retention	postgres	t	f	\N	1	{"drop_after": "30 days", "hypertable_id": 1}	_timescaledb_functions	policy_retention_check	\N
1001	Refresh Continuous Aggregate Policy [1001]	01:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_refresh_continuous_aggregate	postgres	t	f	\N	2	{"end_offset": "01:00:00", "start_offset": "03:00:00", "mat_hypertable_id": 2}	_timescaledb_functions	policy_refresh_continuous_aggregate_check	\N
1002	Refresh Continuous Aggregate Policy [1002]	1 day	00:00:00	-1	1 day	_timescaledb_functions	policy_refresh_continuous_aggregate	postgres	t	f	\N	3	{"end_offset": "1 day", "start_offset": "7 days", "mat_hypertable_id": 3}	_timescaledb_functions	policy_refresh_continuous_aggregate_check	\N
1003	Retention Policy [1003]	1 day	00:05:00	-1	00:05:00	_timescaledb_functions	policy_retention	postgres	t	f	\N	4	{"drop_after": "90 days", "hypertable_id": 4}	_timescaledb_functions	policy_retention_check	\N
1004	Retention Policy [1004]	1 day	00:05:00	-1	00:05:00	_timescaledb_functions	policy_retention	postgres	t	f	\N	5	{"drop_after": "30 days", "hypertable_id": 5}	_timescaledb_functions	policy_retention_check	\N
1005	Columnstore Policy [1005]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	postgres	t	f	\N	1	{"hypertable_id": 1, "compress_after": "7 days"}	_timescaledb_functions	policy_compression_check	\N
1006	Columnstore Policy [1006]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	postgres	t	f	\N	4	{"hypertable_id": 4, "compress_after": "7 days"}	_timescaledb_functions	policy_compression_check	\N
1007	Columnstore Policy [1007]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	postgres	t	f	\N	5	{"hypertable_id": 5, "compress_after": "7 days"}	_timescaledb_functions	policy_compression_check	\N
\.


--
-- Data for Name: _compressed_hypertable_6; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._compressed_hypertable_6  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_7; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._compressed_hypertable_7  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_8; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._compressed_hypertable_8  FROM stdin;
\.


--
-- Data for Name: _hyper_1_1_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_1_1_chunk (id, trace_id, workspace_id, agent_id, "timestamp", latency_ms, input, output, error, status, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, tags, user_id) FROM stdin;
\.


--
-- Data for Name: _hyper_1_2_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_1_2_chunk (id, trace_id, workspace_id, agent_id, "timestamp", latency_ms, input, output, error, status, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, tags, user_id) FROM stdin;
\.


--
-- Data for Name: _hyper_1_3_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_1_3_chunk (id, trace_id, workspace_id, agent_id, "timestamp", latency_ms, input, output, error, status, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, tags, user_id) FROM stdin;
\.


--
-- Data for Name: _hyper_1_4_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_1_4_chunk (id, trace_id, workspace_id, agent_id, "timestamp", latency_ms, input, output, error, status, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, tags, user_id) FROM stdin;
\.


--
-- Data for Name: _hyper_1_5_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_1_5_chunk (id, trace_id, workspace_id, agent_id, "timestamp", latency_ms, input, output, error, status, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, tags, user_id) FROM stdin;
1596	trace-596-1761129680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 10:41:20.663+00	3024	Sample prompt for testing iteration 596	\N	Sample error message: API_ERROR	error	gemini-pro	google	422	126	765	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
6	trace-6-1761132685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 11:31:25.171576+00	1608	Sample prompt for testing iteration 6	Sample response from AI model for iteration 6	\N	success	claude-3-opus	anthropic	253	46	378	0.056485	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
16	trace-16-1761093085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 00:31:25.171576+00	3434	Sample prompt for testing iteration 16	\N	Request timeout after 3434ms	timeout	gemini-pro	google	353	131	625	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
23	trace-23-1761121885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 08:31:25.171576+00	1011	Sample prompt for testing iteration 23	Sample response from AI model for iteration 23	\N	success	mixtral-8x7b	mistral	172	135	176	0.003662	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
33	trace-33-1761096685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 01:31:25.171576+00	1449	Sample prompt for testing iteration 33	Sample response from AI model for iteration 33	\N	success	claude-3-opus	anthropic	365	90	444	0.062869	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
36	trace-36-1761150685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 16:31:25.171576+00	1892	Sample prompt for testing iteration 36	\N	Request timeout after 1892ms	timeout	gemini-pro	google	231	138	202	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
42	trace-42-1761103885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 03:31:25.171576+00	1607	Sample prompt for testing iteration 42	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	408	129	231	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
65	trace-65-1761096685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 01:31:25.171576+00	1502	Sample prompt for testing iteration 65	Sample response from AI model for iteration 65	\N	success	mixtral-8x7b	mistral	240	154	541	0.009329	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
68	trace-68-1761111085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 05:31:25.171576+00	967	Sample prompt for testing iteration 68	\N	Sample error message: API_ERROR	error	gemini-pro	google	176	141	259	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
69	trace-69-1761114685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 06:31:25.171576+00	1191	Sample prompt for testing iteration 69	Sample response from AI model for iteration 69	\N	success	gpt-4-turbo	openai	72	128	205	0.042576	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
89	trace-89-1761143485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 14:31:25.171576+00	197	Sample prompt for testing iteration 89	Sample response from AI model for iteration 89	\N	success	gemini-pro	google	522	165	286	0.018993	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
91	trace-91-1761111085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 05:31:25.171576+00	1772	Sample prompt for testing iteration 91	Sample response from AI model for iteration 91	\N	success	claude-3-opus	anthropic	62	184	402	0.020949	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
117	trace-117-1761129085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 10:31:25.171576+00	1046	Sample prompt for testing iteration 117	\N	Request timeout after 1046ms	timeout	gpt-4-turbo	openai	193	75	457	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
147	trace-147-1761121885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 08:31:25.171576+00	1145	Sample prompt for testing iteration 147	\N	Request timeout after 1145ms	timeout	mixtral-8x7b	mistral	437	157	341	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
150	trace-150-1761111085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 05:31:25.171576+00	1878	Sample prompt for testing iteration 150	\N	Request timeout after 1878ms	timeout	mixtral-8x7b	mistral	263	135	711	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
155	trace-155-1761154285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 17:31:25.171576+00	1479	Sample prompt for testing iteration 155	Sample response from AI model for iteration 155	\N	success	gemini-pro	google	477	162	227	0.023552	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
157	trace-157-1761100285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 02:31:25.171576+00	491	Sample prompt for testing iteration 157	Sample response from AI model for iteration 157	\N	success	gemini-pro	google	160	123	447	0.007552	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
161	trace-161-1761103885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 03:31:25.171576+00	1653	Sample prompt for testing iteration 161	Sample response from AI model for iteration 161	\N	success	gemini-pro	google	280	190	249	0.018224	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
172	trace-172-1761118285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 07:31:25.171576+00	1812	Sample prompt for testing iteration 172	Sample response from AI model for iteration 172	\N	success	claude-3-opus	anthropic	491	60	506	0.048813	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
174	trace-174-1761132685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 11:31:25.171576+00	386	Sample prompt for testing iteration 174	\N	Sample error message: API_ERROR	error	gemini-pro	google	396	208	590	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
184	trace-184-1761154285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 17:31:25.171576+00	1332	Sample prompt for testing iteration 184	\N	Request timeout after 1332ms	timeout	gpt-4-turbo	openai	499	110	264	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
186	trace-186-1761143485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 14:31:25.171576+00	660	Sample prompt for testing iteration 186	Sample response from AI model for iteration 186	\N	success	gemini-pro	google	525	99	243	0.013172	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
187	trace-187-1761143485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 14:31:25.171576+00	554	Sample prompt for testing iteration 187	Sample response from AI model for iteration 187	\N	success	claude-3-opus	anthropic	145	65	603	0.044028	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
200	trace-200-1761121885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 08:31:25.171576+00	1653	Sample prompt for testing iteration 200	Sample response from AI model for iteration 200	\N	success	gemini-pro	google	256	140	512	0.020986	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
204	trace-204-1761111085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 05:31:25.171576+00	1529	Sample prompt for testing iteration 204	Sample response from AI model for iteration 204	\N	success	mixtral-8x7b	mistral	267	135	450	0.007694	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
208	trace-208-1761161485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 19:31:25.171576+00	146	Sample prompt for testing iteration 208	Sample response from AI model for iteration 208	\N	success	gemini-pro	google	275	121	340	0.005328	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
219	trace-219-1761157885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 18:31:25.171576+00	766	Sample prompt for testing iteration 219	Sample response from AI model for iteration 219	\N	success	gpt-4-turbo	openai	264	95	305	0.029137	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
225	trace-225-1761107485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 04:31:25.171576+00	1787	Sample prompt for testing iteration 225	Sample response from AI model for iteration 225	\N	success	gemini-pro	google	498	77	689	0.021820	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
226	trace-226-1761125485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 09:31:25.171576+00	1140	Sample prompt for testing iteration 226	Sample response from AI model for iteration 226	\N	success	claude-3-opus	anthropic	419	87	230	0.035083	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
232	trace-232-1761157885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 18:31:25.171576+00	295	Sample prompt for testing iteration 232	Sample response from AI model for iteration 232	\N	success	gemini-pro	google	486	67	464	0.008310	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
242	trace-242-1761132685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 11:31:25.171576+00	1415	Sample prompt for testing iteration 242	Sample response from AI model for iteration 242	\N	success	claude-3-opus	anthropic	283	157	518	0.049668	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
256	trace-256-1761136285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 12:31:25.171576+00	1757	Sample prompt for testing iteration 256	Sample response from AI model for iteration 256	\N	success	gpt-4-turbo	openai	54	190	480	0.041176	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
267	trace-267-1761132685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 11:31:25.171576+00	1137	Sample prompt for testing iteration 267	\N	Request timeout after 1137ms	timeout	mixtral-8x7b	mistral	270	106	639	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
274	trace-274-1761143485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 14:31:25.171576+00	392	Sample prompt for testing iteration 274	Sample response from AI model for iteration 274	\N	success	claude-3-opus	anthropic	301	91	316	0.066152	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
291	trace-291-1761139885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 13:31:25.171576+00	1181	Sample prompt for testing iteration 291	Sample response from AI model for iteration 291	\N	success	mixtral-8x7b	mistral	524	75	730	0.006322	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
304	trace-304-1761161485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 19:31:25.171576+00	872	Sample prompt for testing iteration 304	Sample response from AI model for iteration 304	\N	success	mixtral-8x7b	mistral	82	147	658	0.008274	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
331	trace-331-1761157885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 18:31:25.171576+00	1421	Sample prompt for testing iteration 331	\N	Sample error message: API_ERROR	error	gemini-pro	google	128	133	248	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
332	trace-332-1761139885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 13:31:25.171576+00	1038	Sample prompt for testing iteration 332	Sample response from AI model for iteration 332	\N	success	gemini-pro	google	194	43	639	0.011860	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
351	trace-351-1761118285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 07:31:25.171576+00	1039	Sample prompt for testing iteration 351	\N	Sample error message: API_ERROR	error	gemini-pro	google	471	141	425	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
354	trace-354-1761100285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 02:31:25.171576+00	664	Sample prompt for testing iteration 354	Sample response from AI model for iteration 354	\N	success	gpt-4-turbo	openai	504	148	226	0.054693	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
359	trace-359-1761125485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 09:31:25.171576+00	2686	Sample prompt for testing iteration 359	Sample response from AI model for iteration 359	\N	success	gpt-4-turbo	openai	327	133	349	0.050717	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
379	trace-379-1761125485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 09:31:25.171576+00	2584	Sample prompt for testing iteration 379	\N	Request timeout after 2584ms	timeout	mixtral-8x7b	mistral	182	138	589	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
385	trace-385-1761161485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 19:31:25.171576+00	102	Sample prompt for testing iteration 385	Sample response from AI model for iteration 385	\N	success	gemini-pro	google	404	207	673	0.017802	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
399	trace-399-1761093085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 00:31:25.171576+00	1823	Sample prompt for testing iteration 399	Sample response from AI model for iteration 399	\N	success	gpt-4-turbo	openai	193	98	556	0.032918	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
403	trace-403-1761157885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 18:31:25.171576+00	502	Sample prompt for testing iteration 403	Sample response from AI model for iteration 403	\N	success	claude-3-opus	anthropic	324	77	652	0.070389	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
441	trace-441-1761143485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 14:31:25.171576+00	1975	Sample prompt for testing iteration 441	Sample response from AI model for iteration 441	\N	success	mixtral-8x7b	mistral	442	95	762	0.005770	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
447	trace-447-1761118285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 07:31:25.171576+00	2031	Sample prompt for testing iteration 447	\N	Request timeout after 2031ms	timeout	gpt-4-turbo	openai	180	182	78	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
451	trace-451-1761139885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 13:31:25.171576+00	184	Sample prompt for testing iteration 451	Sample response from AI model for iteration 451	\N	success	mixtral-8x7b	mistral	192	139	289	0.008766	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
453	trace-453-1761121885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 08:31:25.171576+00	154	Sample prompt for testing iteration 453	Sample response from AI model for iteration 453	\N	success	claude-3-opus	anthropic	451	138	226	0.050892	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
469	trace-469-1761136285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 12:31:25.171576+00	1859	Sample prompt for testing iteration 469	Sample response from AI model for iteration 469	\N	success	gpt-4-turbo	openai	154	185	93	0.057938	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
482	trace-482-1761107485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 04:31:25.171576+00	1626	Sample prompt for testing iteration 482	Sample response from AI model for iteration 482	\N	success	gpt-4-turbo	openai	58	58	354	0.022543	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
496	trace-496-1761139885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 13:31:25.171576+00	1277	Sample prompt for testing iteration 496	Sample response from AI model for iteration 496	\N	success	mixtral-8x7b	mistral	53	101	278	0.005635	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
498	trace-498-1761132685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 11:31:25.171576+00	860	Sample prompt for testing iteration 498	Sample response from AI model for iteration 498	\N	success	gemini-pro	google	452	214	378	0.019228	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
516	trace-516-1761143485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 14:31:25.171576+00	614	Sample prompt for testing iteration 516	\N	Request timeout after 614ms	timeout	mixtral-8x7b	mistral	545	54	591	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
518	trace-518-1761100285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 02:31:25.171576+00	356	Sample prompt for testing iteration 518	\N	Request timeout after 356ms	timeout	gpt-4-turbo	openai	303	217	702	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
525	trace-525-1761157885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 18:31:25.171576+00	721	Sample prompt for testing iteration 525	Sample response from AI model for iteration 525	\N	success	mixtral-8x7b	mistral	484	209	309	0.006864	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
529	trace-529-1761132685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 11:31:25.171576+00	1628	Sample prompt for testing iteration 529	\N	Request timeout after 1628ms	timeout	gpt-4-turbo	openai	54	192	151	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
544	trace-544-1761125485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 09:31:25.171576+00	2065	Sample prompt for testing iteration 544	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	425	46	661	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
546	trace-546-1761103885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 03:31:25.171576+00	121	Sample prompt for testing iteration 546	Sample response from AI model for iteration 546	\N	success	gemini-pro	google	433	41	545	0.023148	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
553	trace-553-1761096685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 01:31:25.171576+00	1424	Sample prompt for testing iteration 553	\N	Request timeout after 1424ms	timeout	gpt-4-turbo	openai	421	166	184	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
561	trace-561-1761147085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 15:31:25.171576+00	1149	Sample prompt for testing iteration 561	Sample response from AI model for iteration 561	\N	success	gpt-4-turbo	openai	250	46	90	0.037576	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
564	trace-564-1761154285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 17:31:25.171576+00	1806	Sample prompt for testing iteration 564	Sample response from AI model for iteration 564	\N	success	gpt-4-turbo	openai	391	24	644	0.025444	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
570	trace-570-1761139885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 13:31:25.171576+00	255	Sample prompt for testing iteration 570	Sample response from AI model for iteration 570	\N	success	mixtral-8x7b	mistral	522	167	619	0.005051	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
575	trace-575-1761107485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 04:31:25.171576+00	737	Sample prompt for testing iteration 575	Sample response from AI model for iteration 575	\N	success	mixtral-8x7b	mistral	424	172	210	0.005019	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
586	trace-586-1761093085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 00:31:25.171576+00	940	Sample prompt for testing iteration 586	Sample response from AI model for iteration 586	\N	success	gemini-pro	google	376	31	706	0.018277	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
588	trace-588-1761096685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 01:31:25.171576+00	490	Sample prompt for testing iteration 588	Sample response from AI model for iteration 588	\N	success	gpt-4-turbo	openai	291	217	574	0.057120	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
591	trace-591-1761118285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 07:31:25.171576+00	839	Sample prompt for testing iteration 591	Sample response from AI model for iteration 591	\N	success	mixtral-8x7b	mistral	386	89	405	0.007894	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
596	trace-596-1761132685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 11:31:25.171576+00	4701	Sample prompt for testing iteration 596	Sample response from AI model for iteration 596	\N	success	gpt-4-turbo	openai	231	68	514	0.024152	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
612	trace-612-1761129085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 10:31:25.171576+00	1731	Sample prompt for testing iteration 612	Sample response from AI model for iteration 612	\N	success	gpt-4-turbo	openai	424	168	470	0.040845	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
614	trace-614-1761125485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 09:31:25.171576+00	1586	Sample prompt for testing iteration 614	Sample response from AI model for iteration 614	\N	success	gemini-pro	google	174	25	517	0.013407	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
626	trace-626-1761129085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 10:31:25.171576+00	800	Sample prompt for testing iteration 626	Sample response from AI model for iteration 626	\N	success	gemini-pro	google	203	167	337	0.009713	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
629	trace-629-1761161485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 19:31:25.171576+00	148	Sample prompt for testing iteration 629	Sample response from AI model for iteration 629	\N	success	claude-3-opus	anthropic	232	103	274	0.060060	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
631	trace-631-1761139885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 13:31:25.171576+00	601	Sample prompt for testing iteration 631	Sample response from AI model for iteration 631	\N	success	gpt-4-turbo	openai	144	180	310	0.016547	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
634	trace-634-1761125485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 09:31:25.171576+00	947	Sample prompt for testing iteration 634	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	244	25	448	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
647	trace-647-1761132685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 11:31:25.171576+00	1382	Sample prompt for testing iteration 647	Sample response from AI model for iteration 647	\N	success	gemini-pro	google	130	167	92	0.005868	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
650	trace-650-1761154285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 17:31:25.171576+00	234	Sample prompt for testing iteration 650	Sample response from AI model for iteration 650	\N	success	mixtral-8x7b	mistral	279	113	746	0.012812	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
652	trace-652-1761125485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 09:31:25.171576+00	4367	Sample prompt for testing iteration 652	Sample response from AI model for iteration 652	\N	success	gemini-pro	google	184	38	413	0.005518	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
657	trace-657-1761129085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 10:31:25.171576+00	1356	Sample prompt for testing iteration 657	Sample response from AI model for iteration 657	\N	success	gpt-4-turbo	openai	446	206	655	0.015871	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
661	trace-661-1761139885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 13:31:25.171576+00	1098	Sample prompt for testing iteration 661	Sample response from AI model for iteration 661	\N	success	gemini-pro	google	168	70	449	0.018007	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
681	trace-681-1761161485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 19:31:25.171576+00	1756	Sample prompt for testing iteration 681	\N	Request timeout after 1756ms	timeout	mixtral-8x7b	mistral	107	142	204	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
706	trace-706-1761157885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 18:31:25.171576+00	1279	Sample prompt for testing iteration 706	Sample response from AI model for iteration 706	\N	success	claude-3-opus	anthropic	533	180	367	0.059874	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
707	trace-707-1761107485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 04:31:25.171576+00	252	Sample prompt for testing iteration 707	Sample response from AI model for iteration 707	\N	success	gpt-4-turbo	openai	368	82	531	0.032215	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
716	trace-716-1761111085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 05:31:25.171576+00	1309	Sample prompt for testing iteration 716	Sample response from AI model for iteration 716	\N	success	gpt-4-turbo	openai	403	200	424	0.048571	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
722	trace-722-1761157885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 18:31:25.171576+00	1387	Sample prompt for testing iteration 722	Sample response from AI model for iteration 722	\N	success	gemini-pro	google	147	46	391	0.022040	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
723	trace-723-1761136285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 12:31:25.171576+00	1662	Sample prompt for testing iteration 723	\N	Request timeout after 1662ms	timeout	gpt-4-turbo	openai	279	85	362	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
725	trace-725-1761100285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 02:31:25.171576+00	1370	Sample prompt for testing iteration 725	\N	Request timeout after 1370ms	timeout	gemini-pro	google	105	127	707	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
736	trace-736-1761096685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 01:31:25.171576+00	1270	Sample prompt for testing iteration 736	\N	Request timeout after 1270ms	timeout	mixtral-8x7b	mistral	460	189	98	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
738	trace-738-1761125485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 09:31:25.171576+00	554	Sample prompt for testing iteration 738	Sample response from AI model for iteration 738	\N	success	gpt-4-turbo	openai	406	190	419	0.014827	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
740	trace-740-1761107485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 04:31:25.171576+00	1162	Sample prompt for testing iteration 740	Sample response from AI model for iteration 740	\N	success	gemini-pro	google	483	181	164	0.013018	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
744	trace-744-1761139885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 13:31:25.171576+00	1600	Sample prompt for testing iteration 744	\N	Sample error message: API_ERROR	error	gemini-pro	google	395	57	532	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
753	trace-753-1761107485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 04:31:25.171576+00	1557	Sample prompt for testing iteration 753	Sample response from AI model for iteration 753	\N	success	gpt-4-turbo	openai	453	149	708	0.023380	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
754	trace-754-1761114685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 06:31:25.171576+00	1858	Sample prompt for testing iteration 754	Sample response from AI model for iteration 754	\N	success	mixtral-8x7b	mistral	57	39	140	0.010433	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
762	trace-762-1761154285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 17:31:25.171576+00	137	Sample prompt for testing iteration 762	Sample response from AI model for iteration 762	\N	success	claude-3-opus	anthropic	294	28	545	0.033348	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
768	trace-768-1761154285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 17:31:25.171576+00	1384	Sample prompt for testing iteration 768	Sample response from AI model for iteration 768	\N	success	claude-3-opus	anthropic	413	72	687	0.055173	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
793	trace-793-1761154285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 17:31:25.171576+00	1317	Sample prompt for testing iteration 793	Sample response from AI model for iteration 793	\N	success	gemini-pro	google	494	33	471	0.018906	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
804	trace-804-1761096685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 01:31:25.171576+00	443	Sample prompt for testing iteration 804	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	392	166	120	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
805	trace-805-1761132685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 11:31:25.171576+00	145	Sample prompt for testing iteration 805	\N	Sample error message: API_ERROR	error	gemini-pro	google	464	155	424	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
811	trace-811-1761136285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 12:31:25.171576+00	2097	Sample prompt for testing iteration 811	Sample response from AI model for iteration 811	\N	success	gemini-pro	google	479	127	218	0.009663	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
814	trace-814-1761093085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 00:31:25.171576+00	2039	Sample prompt for testing iteration 814	Sample response from AI model for iteration 814	\N	success	gpt-4-turbo	openai	463	78	306	0.019406	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
815	trace-815-1761121885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 08:31:25.171576+00	1829	Sample prompt for testing iteration 815	Sample response from AI model for iteration 815	\N	success	mixtral-8x7b	mistral	454	190	542	0.005354	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
836	trace-836-1761154285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 17:31:25.171576+00	1207	Sample prompt for testing iteration 836	Sample response from AI model for iteration 836	\N	success	gemini-pro	google	363	44	213	0.018333	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
845	trace-845-1761100285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 02:31:25.171576+00	514	Sample prompt for testing iteration 845	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	60	143	700	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
853	trace-853-1761103885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 03:31:25.171576+00	1632	Sample prompt for testing iteration 853	Sample response from AI model for iteration 853	\N	success	mixtral-8x7b	mistral	295	134	132	0.009608	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
860	trace-860-1761129085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 10:31:25.171576+00	1000	Sample prompt for testing iteration 860	Sample response from AI model for iteration 860	\N	success	mixtral-8x7b	mistral	238	53	697	0.003238	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
863	trace-863-1761103885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 03:31:25.171576+00	1974	Sample prompt for testing iteration 863	Sample response from AI model for iteration 863	\N	success	mixtral-8x7b	mistral	526	175	483	0.007620	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
866	trace-866-1761118285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 07:31:25.171576+00	821	Sample prompt for testing iteration 866	Sample response from AI model for iteration 866	\N	success	claude-3-opus	anthropic	93	103	297	0.055426	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
873	trace-873-1761114685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 06:31:25.171576+00	619	Sample prompt for testing iteration 873	Sample response from AI model for iteration 873	\N	success	mixtral-8x7b	mistral	462	110	382	0.008724	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
895	trace-895-1761157885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 18:31:25.171576+00	1366	Sample prompt for testing iteration 895	Sample response from AI model for iteration 895	\N	success	claude-3-opus	anthropic	537	154	547	0.056475	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
899	trace-899-1761139885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 13:31:25.171576+00	1435	Sample prompt for testing iteration 899	Sample response from AI model for iteration 899	\N	success	gemini-pro	google	368	194	359	0.021367	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
900	trace-900-1761125485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 09:31:25.171576+00	4298	Sample prompt for testing iteration 900	\N	Request timeout after 4298ms	timeout	claude-3-opus	anthropic	284	34	706	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
920	trace-920-1761103885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 03:31:25.171576+00	1163	Sample prompt for testing iteration 920	Sample response from AI model for iteration 920	\N	success	gpt-4-turbo	openai	439	128	482	0.041517	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
922	trace-922-1761161485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 19:31:25.171576+00	1490	Sample prompt for testing iteration 922	Sample response from AI model for iteration 922	\N	success	mixtral-8x7b	mistral	464	126	681	0.004195	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
929	trace-929-1761161485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 19:31:25.171576+00	1086	Sample prompt for testing iteration 929	Sample response from AI model for iteration 929	\N	success	gemini-pro	google	134	182	363	0.014291	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
934	trace-934-1761100285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 02:31:25.171576+00	962	Sample prompt for testing iteration 934	Sample response from AI model for iteration 934	\N	success	gpt-4-turbo	openai	318	28	143	0.016175	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
936	trace-936-1761125485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 09:31:25.171576+00	1366	Sample prompt for testing iteration 936	Sample response from AI model for iteration 936	\N	success	gpt-4-turbo	openai	429	73	575	0.054414	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
940	trace-940-1761125485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 09:31:25.171576+00	2552	Sample prompt for testing iteration 940	Sample response from AI model for iteration 940	\N	success	mixtral-8x7b	mistral	455	78	394	0.008258	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
960	trace-960-1761107485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 04:31:25.171576+00	2334	Sample prompt for testing iteration 960	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	369	80	344	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
961	trace-961-1761150685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 16:31:25.171576+00	153	Sample prompt for testing iteration 961	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	458	142	579	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
966	trace-966-1761147085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 15:31:25.171576+00	418	Sample prompt for testing iteration 966	\N	Request timeout after 418ms	timeout	claude-3-opus	anthropic	255	51	291	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
969	trace-969-1761136285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 12:31:25.171576+00	409	Sample prompt for testing iteration 969	Sample response from AI model for iteration 969	\N	success	claude-3-opus	anthropic	290	180	156	0.029423	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
976	trace-976-1761093085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 00:31:25.171576+00	742	Sample prompt for testing iteration 976	Sample response from AI model for iteration 976	\N	success	gpt-4-turbo	openai	225	161	652	0.037191	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
978	trace-978-1761154285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 17:31:25.171576+00	591	Sample prompt for testing iteration 978	Sample response from AI model for iteration 978	\N	success	claude-3-opus	anthropic	238	157	245	0.018182	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
994	trace-994-1761103885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 03:31:25.171576+00	3338	Sample prompt for testing iteration 994	\N	Request timeout after 3338ms	timeout	gemini-pro	google	505	150	633	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
998	trace-998-1761154285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 17:31:25.171576+00	1452	Sample prompt for testing iteration 998	Sample response from AI model for iteration 998	\N	success	mixtral-8x7b	mistral	199	139	593	0.007801	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1000	trace-1000-1761093085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 00:31:25.171576+00	3790	Sample prompt for testing iteration 1000	\N	Request timeout after 3790ms	timeout	gemini-pro	google	160	68	326	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1001	trace-1-1761136880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 12:41:20.663+00	3247	Sample prompt for testing iteration 1	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	184	114	600	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1028	trace-28-1761158480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 18:41:20.663+00	1894	Sample prompt for testing iteration 28	Sample response from AI model for iteration 28	\N	success	gpt-4-turbo	openai	542	116	710	0.049106	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1032	trace-32-1761147680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 15:41:20.663+00	1230	Sample prompt for testing iteration 32	Sample response from AI model for iteration 32	\N	success	mixtral-8x7b	mistral	272	43	139	0.003225	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1045	trace-45-1761129680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 10:41:20.663+00	1207	Sample prompt for testing iteration 45	Sample response from AI model for iteration 45	\N	success	claude-3-opus	anthropic	182	121	353	0.069353	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1058	trace-58-1761151280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 16:41:20.663+00	1586	Sample prompt for testing iteration 58	Sample response from AI model for iteration 58	\N	success	gpt-4-turbo	openai	151	203	752	0.019980	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1061	trace-61-1761122480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 08:41:20.663+00	177	Sample prompt for testing iteration 61	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	321	133	594	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1074	trace-74-1761144080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 14:41:20.663+00	1026	Sample prompt for testing iteration 74	Sample response from AI model for iteration 74	\N	success	mixtral-8x7b	mistral	413	117	496	0.011429	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1084	trace-84-1761144080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 14:41:20.663+00	387	Sample prompt for testing iteration 84	\N	Request timeout after 387ms	timeout	gemini-pro	google	74	36	456	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1090	trace-90-1761111680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 05:41:20.663+00	1052	Sample prompt for testing iteration 90	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	319	115	176	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1106	trace-106-1761133280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 11:41:20.663+00	3405	Sample prompt for testing iteration 106	Sample response from AI model for iteration 106	\N	success	gemini-pro	google	310	201	244	0.005377	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1110	trace-110-1761147680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 15:41:20.663+00	537	Sample prompt for testing iteration 110	Sample response from AI model for iteration 110	\N	success	claude-3-opus	anthropic	85	126	527	0.037862	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1112	trace-112-1761151280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 16:41:20.663+00	1532	Sample prompt for testing iteration 112	Sample response from AI model for iteration 112	\N	success	mixtral-8x7b	mistral	357	77	734	0.004029	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1122	trace-122-1761151280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 16:41:20.663+00	141	Sample prompt for testing iteration 122	Sample response from AI model for iteration 122	\N	success	gemini-pro	google	151	207	470	0.008196	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1132	trace-132-1761115280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 06:41:20.663+00	751	Sample prompt for testing iteration 132	Sample response from AI model for iteration 132	\N	success	gpt-4-turbo	openai	133	26	100	0.029841	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1147	trace-147-1761126080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 09:41:20.663+00	1973	Sample prompt for testing iteration 147	Sample response from AI model for iteration 147	\N	success	gemini-pro	google	173	109	400	0.009946	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1153	trace-153-1761104480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 03:41:20.663+00	1170	Sample prompt for testing iteration 153	Sample response from AI model for iteration 153	\N	success	claude-3-opus	anthropic	297	104	108	0.017888	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1156	trace-156-1761144080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 14:41:20.663+00	1298	Sample prompt for testing iteration 156	Sample response from AI model for iteration 156	\N	success	gemini-pro	google	88	124	184	0.010452	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1165	trace-165-1761115280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 06:41:20.663+00	1433	Sample prompt for testing iteration 165	Sample response from AI model for iteration 165	\N	success	claude-3-opus	anthropic	181	65	400	0.055543	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1168	trace-168-1761144080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 14:41:20.663+00	4668	Sample prompt for testing iteration 168	Sample response from AI model for iteration 168	\N	success	claude-3-opus	anthropic	313	130	406	0.023363	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1177	trace-177-1761140480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 13:41:20.663+00	2394	Sample prompt for testing iteration 177	Sample response from AI model for iteration 177	\N	success	claude-3-opus	anthropic	269	80	712	0.071377	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1189	trace-189-1761097280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 01:41:20.663+00	809	Sample prompt for testing iteration 189	Sample response from AI model for iteration 189	\N	success	gemini-pro	google	359	123	606	0.010819	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1191	trace-191-1761129680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 10:41:20.663+00	700	Sample prompt for testing iteration 191	Sample response from AI model for iteration 191	\N	success	claude-3-opus	anthropic	124	184	254	0.033116	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1219	trace-219-1761093680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 00:41:20.663+00	1241	Sample prompt for testing iteration 219	Sample response from AI model for iteration 219	\N	success	claude-3-opus	anthropic	199	191	196	0.038859	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1232	trace-232-1761140480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 13:41:20.663+00	121	Sample prompt for testing iteration 232	Sample response from AI model for iteration 232	\N	success	claude-3-opus	anthropic	341	52	720	0.064248	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1242	trace-242-1761115280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 06:41:20.663+00	565	Sample prompt for testing iteration 242	\N	Request timeout after 565ms	timeout	claude-3-opus	anthropic	456	92	366	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1248	trace-248-1761111680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 05:41:20.663+00	1183	Sample prompt for testing iteration 248	\N	Request timeout after 1183ms	timeout	gpt-4-turbo	openai	503	43	767	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1254	trace-254-1761111680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 05:41:20.663+00	2092	Sample prompt for testing iteration 254	Sample response from AI model for iteration 254	\N	success	gemini-pro	google	76	92	760	0.023080	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1258	trace-258-1761100880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 02:41:20.663+00	1315	Sample prompt for testing iteration 258	Sample response from AI model for iteration 258	\N	success	gemini-pro	google	150	92	478	0.015910	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1266	trace-266-1761108080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 04:41:20.663+00	539	Sample prompt for testing iteration 266	Sample response from AI model for iteration 266	\N	success	gpt-4-turbo	openai	119	59	730	0.018053	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1273	trace-273-1761093680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 00:41:20.663+00	756	Sample prompt for testing iteration 273	Sample response from AI model for iteration 273	\N	success	gpt-4-turbo	openai	80	187	220	0.027075	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1275	trace-275-1761093680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 00:41:20.663+00	588	Sample prompt for testing iteration 275	Sample response from AI model for iteration 275	\N	success	gpt-4-turbo	openai	268	174	623	0.042648	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1280	trace-280-1761133280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 11:41:20.663+00	3625	Sample prompt for testing iteration 280	Sample response from AI model for iteration 280	\N	success	mixtral-8x7b	mistral	87	108	319	0.003530	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1288	trace-288-1761093680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 00:41:20.663+00	1112	Sample prompt for testing iteration 288	Sample response from AI model for iteration 288	\N	success	claude-3-opus	anthropic	542	169	426	0.057892	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1292	trace-292-1761122480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 08:41:20.663+00	1582	Sample prompt for testing iteration 292	Sample response from AI model for iteration 292	\N	success	gpt-4-turbo	openai	94	180	671	0.038214	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1293	trace-293-1761108080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 04:41:20.663+00	584	Sample prompt for testing iteration 293	\N	Request timeout after 584ms	timeout	gemini-pro	google	317	141	603	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1297	trace-297-1761162080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 19:41:20.663+00	535	Sample prompt for testing iteration 297	Sample response from AI model for iteration 297	\N	success	gpt-4-turbo	openai	172	125	294	0.057313	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1303	trace-303-1761108080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 04:41:20.663+00	1222	Sample prompt for testing iteration 303	Sample response from AI model for iteration 303	\N	success	claude-3-opus	anthropic	484	146	559	0.072821	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1308	trace-308-1761162080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 19:41:20.663+00	1360	Sample prompt for testing iteration 308	Sample response from AI model for iteration 308	\N	success	gemini-pro	google	348	138	148	0.021168	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1327	trace-327-1761158480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 18:41:20.663+00	1668	Sample prompt for testing iteration 327	\N	Request timeout after 1668ms	timeout	gemini-pro	google	269	61	102	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1328	trace-328-1761097280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 01:41:20.663+00	390	Sample prompt for testing iteration 328	Sample response from AI model for iteration 328	\N	success	gpt-4-turbo	openai	374	106	630	0.014129	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1351	trace-351-1761136880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 12:41:20.663+00	2000	Sample prompt for testing iteration 351	Sample response from AI model for iteration 351	\N	success	gemini-pro	google	430	161	442	0.024121	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1355	trace-355-1761151280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 16:41:20.663+00	1068	Sample prompt for testing iteration 355	Sample response from AI model for iteration 355	\N	success	gpt-4-turbo	openai	285	84	388	0.024027	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1358	trace-358-1761144080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 14:41:20.663+00	617	Sample prompt for testing iteration 358	\N	Sample error message: API_ERROR	error	gemini-pro	google	98	56	534	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1362	trace-362-1761162080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 19:41:20.663+00	815	Sample prompt for testing iteration 362	Sample response from AI model for iteration 362	\N	success	gemini-pro	google	104	43	412	0.024350	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1363	trace-363-1761136880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 12:41:20.663+00	2077	Sample prompt for testing iteration 363	Sample response from AI model for iteration 363	\N	success	gemini-pro	google	272	124	142	0.010921	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1386	trace-386-1761126080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 09:41:20.663+00	431	Sample prompt for testing iteration 386	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	212	129	349	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1403	trace-403-1761158480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 18:41:20.663+00	486	Sample prompt for testing iteration 403	\N	Sample error message: API_ERROR	error	gemini-pro	google	133	208	70	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1427	trace-427-1761118880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 07:41:20.663+00	1852	Sample prompt for testing iteration 427	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	402	130	738	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1431	trace-431-1761147680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 15:41:20.663+00	4855	Sample prompt for testing iteration 431	\N	Request timeout after 4855ms	timeout	mixtral-8x7b	mistral	161	215	72	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1448	trace-448-1761093680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 00:41:20.663+00	4919	Sample prompt for testing iteration 448	Sample response from AI model for iteration 448	\N	success	gpt-4-turbo	openai	51	186	166	0.018185	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1456	trace-456-1761100880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 02:41:20.663+00	735	Sample prompt for testing iteration 456	Sample response from AI model for iteration 456	\N	success	mixtral-8x7b	mistral	530	179	674	0.005523	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1472	trace-472-1761100880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 02:41:20.663+00	969	Sample prompt for testing iteration 472	Sample response from AI model for iteration 472	\N	success	mixtral-8x7b	mistral	367	112	452	0.007415	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1473	trace-473-1761136880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 12:41:20.663+00	1743	Sample prompt for testing iteration 473	Sample response from AI model for iteration 473	\N	success	mixtral-8x7b	mistral	474	180	152	0.004838	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1475	trace-475-1761147680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 15:41:20.663+00	1719	Sample prompt for testing iteration 475	Sample response from AI model for iteration 475	\N	success	claude-3-opus	anthropic	378	113	401	0.053477	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1480	trace-480-1761122480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 08:41:20.663+00	1885	Sample prompt for testing iteration 480	Sample response from AI model for iteration 480	\N	success	gemini-pro	google	291	136	769	0.010269	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1494	trace-494-1761108080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 04:41:20.663+00	1265	Sample prompt for testing iteration 494	Sample response from AI model for iteration 494	\N	success	mixtral-8x7b	mistral	150	179	683	0.012088	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1495	trace-495-1761097280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 01:41:20.663+00	705	Sample prompt for testing iteration 495	Sample response from AI model for iteration 495	\N	success	gpt-4-turbo	openai	194	219	618	0.050238	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1528	trace-528-1761144080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 14:41:20.663+00	3872	Sample prompt for testing iteration 528	Sample response from AI model for iteration 528	\N	success	gemini-pro	google	304	125	630	0.011749	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1533	trace-533-1761151280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 16:41:20.663+00	1878	Sample prompt for testing iteration 533	\N	Sample error message: API_ERROR	error	gemini-pro	google	541	80	535	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1537	trace-537-1761147680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 15:41:20.663+00	1468	Sample prompt for testing iteration 537	Sample response from AI model for iteration 537	\N	success	gemini-pro	google	201	197	127	0.015951	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1540	trace-540-1761111680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 05:41:20.663+00	4938	Sample prompt for testing iteration 540	\N	Request timeout after 4938ms	timeout	mixtral-8x7b	mistral	392	131	372	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1572	trace-572-1761111680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 05:41:20.663+00	1686	Sample prompt for testing iteration 572	\N	Request timeout after 1686ms	timeout	mixtral-8x7b	mistral	176	167	237	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1585	trace-585-1761111680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 05:41:20.663+00	188	Sample prompt for testing iteration 585	Sample response from AI model for iteration 585	\N	success	mixtral-8x7b	mistral	221	54	363	0.003135	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1591	trace-591-1761097280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 01:41:20.663+00	532	Sample prompt for testing iteration 591	Sample response from AI model for iteration 591	\N	success	claude-3-opus	anthropic	403	140	701	0.026889	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1609	trace-609-1761108080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 04:41:20.663+00	924	Sample prompt for testing iteration 609	Sample response from AI model for iteration 609	\N	success	gemini-pro	google	469	201	222	0.024564	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1610	trace-610-1761115280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 06:41:20.663+00	1394	Sample prompt for testing iteration 610	Sample response from AI model for iteration 610	\N	success	mixtral-8x7b	mistral	207	60	265	0.012539	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1611	trace-611-1761136880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 12:41:20.663+00	4804	Sample prompt for testing iteration 611	\N	Request timeout after 4804ms	timeout	gpt-4-turbo	openai	450	55	627	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1612	trace-612-1761097280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 01:41:20.663+00	1563	Sample prompt for testing iteration 612	Sample response from AI model for iteration 612	\N	success	mixtral-8x7b	mistral	182	114	288	0.009691	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1622	trace-622-1761147680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 15:41:20.663+00	1342	Sample prompt for testing iteration 622	Sample response from AI model for iteration 622	\N	success	gpt-4-turbo	openai	534	134	653	0.058315	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1633	trace-633-1761136880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 12:41:20.663+00	1398	Sample prompt for testing iteration 633	Sample response from AI model for iteration 633	\N	success	mixtral-8x7b	mistral	299	143	483	0.012517	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1662	trace-662-1761162080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 19:41:20.663+00	100	Sample prompt for testing iteration 662	\N	Request timeout after 100ms	timeout	gemini-pro	google	342	140	693	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1666	trace-666-1761126080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 09:41:20.663+00	1708	Sample prompt for testing iteration 666	Sample response from AI model for iteration 666	\N	success	gemini-pro	google	326	153	82	0.020378	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1678	trace-678-1761154880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 17:41:20.663+00	417	Sample prompt for testing iteration 678	\N	Sample error message: API_ERROR	error	gemini-pro	google	428	186	539	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1679	trace-679-1761162080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 19:41:20.663+00	2048	Sample prompt for testing iteration 679	Sample response from AI model for iteration 679	\N	success	gemini-pro	google	245	183	271	0.013370	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1681	trace-681-1761111680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 05:41:20.663+00	1987	Sample prompt for testing iteration 681	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	113	210	210	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1693	trace-693-1761104480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 03:41:20.663+00	1992	Sample prompt for testing iteration 693	Sample response from AI model for iteration 693	\N	success	gemini-pro	google	143	42	148	0.019552	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1694	trace-694-1761162080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 19:41:20.663+00	1108	Sample prompt for testing iteration 694	Sample response from AI model for iteration 694	\N	success	claude-3-opus	anthropic	538	64	496	0.025370	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1707	trace-707-1761104480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 03:41:20.663+00	4335	Sample prompt for testing iteration 707	Sample response from AI model for iteration 707	\N	success	gpt-4-turbo	openai	329	72	301	0.026415	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1709	trace-709-1761111680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 05:41:20.663+00	835	Sample prompt for testing iteration 709	Sample response from AI model for iteration 709	\N	success	claude-3-opus	anthropic	512	80	278	0.044993	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1710	trace-710-1761100880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 02:41:20.663+00	1203	Sample prompt for testing iteration 710	\N	Request timeout after 1203ms	timeout	gemini-pro	google	535	177	175	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1712	trace-712-1761133280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 11:41:20.663+00	1844	Sample prompt for testing iteration 712	\N	Sample error message: API_ERROR	error	gemini-pro	google	361	67	693	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1714	trace-714-1761162080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 19:41:20.663+00	2084	Sample prompt for testing iteration 714	Sample response from AI model for iteration 714	\N	success	mixtral-8x7b	mistral	266	45	469	0.009817	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1721	trace-721-1761136880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 12:41:20.663+00	1651	Sample prompt for testing iteration 721	Sample response from AI model for iteration 721	\N	success	claude-3-opus	anthropic	409	177	395	0.052416	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1725	trace-725-1761129680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 10:41:20.663+00	407	Sample prompt for testing iteration 725	Sample response from AI model for iteration 725	\N	success	claude-3-opus	anthropic	396	130	699	0.031816	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1727	trace-727-1761097280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 01:41:20.663+00	311	Sample prompt for testing iteration 727	Sample response from AI model for iteration 727	\N	success	mixtral-8x7b	mistral	349	78	81	0.003259	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1730	trace-730-1761104480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 03:41:20.663+00	1665	Sample prompt for testing iteration 730	Sample response from AI model for iteration 730	\N	success	gemini-pro	google	363	202	721	0.015561	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1735	trace-735-1761118880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 07:41:20.663+00	899	Sample prompt for testing iteration 735	Sample response from AI model for iteration 735	\N	success	mixtral-8x7b	mistral	76	68	448	0.006075	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1742	trace-742-1761129680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 10:41:20.663+00	576	Sample prompt for testing iteration 742	Sample response from AI model for iteration 742	\N	success	mixtral-8x7b	mistral	169	23	230	0.008823	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1743	trace-743-1761158480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 18:41:20.663+00	574	Sample prompt for testing iteration 743	Sample response from AI model for iteration 743	\N	success	claude-3-opus	anthropic	400	216	583	0.058559	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1746	trace-746-1761118880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 07:41:20.663+00	1211	Sample prompt for testing iteration 746	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	178	208	670	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1769	trace-769-1761115280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 06:41:20.663+00	1481	Sample prompt for testing iteration 769	Sample response from AI model for iteration 769	\N	success	gpt-4-turbo	openai	72	136	227	0.026410	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1771	trace-771-1761093680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 00:41:20.663+00	1050	Sample prompt for testing iteration 771	Sample response from AI model for iteration 771	\N	success	mixtral-8x7b	mistral	387	86	496	0.011091	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1778	trace-778-1761162080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 19:41:20.663+00	676	Sample prompt for testing iteration 778	Sample response from AI model for iteration 778	\N	success	gpt-4-turbo	openai	114	134	194	0.045006	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1779	trace-779-1761133280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 11:41:20.663+00	1971	Sample prompt for testing iteration 779	Sample response from AI model for iteration 779	\N	success	gpt-4-turbo	openai	130	141	288	0.037846	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1782	trace-782-1761136880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 12:41:20.663+00	248	Sample prompt for testing iteration 782	Sample response from AI model for iteration 782	\N	success	mixtral-8x7b	mistral	139	70	608	0.009793	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1783	trace-783-1761151280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 16:41:20.663+00	821	Sample prompt for testing iteration 783	Sample response from AI model for iteration 783	\N	success	mixtral-8x7b	mistral	510	211	219	0.003272	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1789	trace-789-1761147680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 15:41:20.663+00	1284	Sample prompt for testing iteration 789	Sample response from AI model for iteration 789	\N	success	gpt-4-turbo	openai	275	101	326	0.016872	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1802	trace-802-1761162080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 19:41:20.663+00	1642	Sample prompt for testing iteration 802	Sample response from AI model for iteration 802	\N	success	gpt-4-turbo	openai	451	148	215	0.011631	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1817	trace-817-1761129680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 10:41:20.663+00	147	Sample prompt for testing iteration 817	Sample response from AI model for iteration 817	\N	success	gemini-pro	google	398	42	339	0.006840	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1824	trace-824-1761104480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 03:41:20.663+00	1906	Sample prompt for testing iteration 824	\N	Request timeout after 1906ms	timeout	mixtral-8x7b	mistral	91	52	208	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1830	trace-830-1761118880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 07:41:20.663+00	1406	Sample prompt for testing iteration 830	\N	Request timeout after 1406ms	timeout	gemini-pro	google	103	105	336	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1848	trace-848-1761158480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 18:41:20.663+00	523	Sample prompt for testing iteration 848	Sample response from AI model for iteration 848	\N	success	claude-3-opus	anthropic	350	135	351	0.072016	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1849	trace-849-1761144080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 14:41:20.663+00	1228	Sample prompt for testing iteration 849	Sample response from AI model for iteration 849	\N	success	claude-3-opus	anthropic	210	134	230	0.050877	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1853	trace-853-1761136880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 12:41:20.663+00	902	Sample prompt for testing iteration 853	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	479	36	355	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1866	trace-866-1761154880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 17:41:20.663+00	387	Sample prompt for testing iteration 866	Sample response from AI model for iteration 866	\N	success	gpt-4-turbo	openai	181	138	536	0.055146	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1884	trace-884-1761147680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 15:41:20.663+00	1583	Sample prompt for testing iteration 884	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	58	53	532	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1895	trace-895-1761126080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 09:41:20.663+00	906	Sample prompt for testing iteration 895	Sample response from AI model for iteration 895	\N	success	gemini-pro	google	369	35	462	0.024465	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1903	trace-903-1761144080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 14:41:20.663+00	873	Sample prompt for testing iteration 903	Sample response from AI model for iteration 903	\N	success	gemini-pro	google	428	190	671	0.016774	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1916	trace-916-1761144080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 14:41:20.663+00	901	Sample prompt for testing iteration 916	Sample response from AI model for iteration 916	\N	success	claude-3-opus	anthropic	247	187	637	0.051127	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1933	trace-933-1761136880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 12:41:20.663+00	1661	Sample prompt for testing iteration 933	Sample response from AI model for iteration 933	\N	success	gemini-pro	google	75	73	434	0.023143	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1934	trace-934-1761133280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-22 11:41:20.663+00	1180	Sample prompt for testing iteration 934	\N	Request timeout after 1180ms	timeout	mixtral-8x7b	mistral	133	68	722	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1938	trace-938-1761100880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 02:41:20.663+00	1434	Sample prompt for testing iteration 938	Sample response from AI model for iteration 938	\N	success	mixtral-8x7b	mistral	178	64	349	0.003347	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1943	trace-943-1761111680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 05:41:20.663+00	237	Sample prompt for testing iteration 943	Sample response from AI model for iteration 943	\N	success	gpt-4-turbo	openai	52	137	712	0.020501	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1951	trace-951-1761162080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 19:41:20.663+00	211	Sample prompt for testing iteration 951	Sample response from AI model for iteration 951	\N	success	claude-3-opus	anthropic	372	31	568	0.017908	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1958	trace-958-1761097280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 01:41:20.663+00	1639	Sample prompt for testing iteration 958	\N	Request timeout after 1639ms	timeout	gemini-pro	google	90	199	346	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1965	trace-965-1761158480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 18:41:20.663+00	461	Sample prompt for testing iteration 965	Sample response from AI model for iteration 965	\N	success	mixtral-8x7b	mistral	264	193	109	0.011276	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1967	trace-967-1761097280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 01:41:20.663+00	397	Sample prompt for testing iteration 967	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	237	51	119	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1968	trace-968-1761140480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 13:41:20.663+00	283	Sample prompt for testing iteration 968	Sample response from AI model for iteration 968	\N	success	gpt-4-turbo	openai	366	71	489	0.013498	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1970	trace-970-1761097280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-22 01:41:20.663+00	1581	Sample prompt for testing iteration 970	\N	Request timeout after 1581ms	timeout	gpt-4-turbo	openai	538	131	640	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1979	trace-979-1761147680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 15:41:20.663+00	3509	Sample prompt for testing iteration 979	Sample response from AI model for iteration 979	\N	success	gpt-4-turbo	openai	446	110	114	0.016678	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1993	trace-993-1761158480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-22 18:41:20.663+00	711	Sample prompt for testing iteration 993	\N	Sample error message: API_ERROR	error	gemini-pro	google	208	53	406	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1999	trace-999-1761151280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-22 16:41:20.663+00	1158	Sample prompt for testing iteration 999	Sample response from AI model for iteration 999	\N	success	gemini-pro	google	521	218	149	0.021562	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
\.


--
-- Data for Name: _hyper_1_6_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_1_6_chunk (id, trace_id, workspace_id, agent_id, "timestamp", latency_ms, input, output, error, status, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, tags, user_id) FROM stdin;
7	trace-7-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 06:31:25.171576+00	1756	Sample prompt for testing iteration 7	Sample response from AI model for iteration 7	\N	success	claude-3-opus	anthropic	154	178	167	0.038149	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
12	trace-12-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 13:31:25.171576+00	397	Sample prompt for testing iteration 12	\N	Request timeout after 397ms	timeout	mixtral-8x7b	mistral	155	199	642	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
14	trace-14-1760938285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 05:31:25.171576+00	753	Sample prompt for testing iteration 14	Sample response from AI model for iteration 14	\N	success	gpt-4-turbo	openai	286	172	727	0.057635	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
40	trace-40-1760974285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 15:31:25.171576+00	1048	Sample prompt for testing iteration 40	Sample response from AI model for iteration 40	\N	success	mixtral-8x7b	mistral	512	91	165	0.006881	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
43	trace-43-1760988685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 19:31:25.171576+00	1619	Sample prompt for testing iteration 43	Sample response from AI model for iteration 43	\N	success	gemini-pro	google	337	79	675	0.024895	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
45	trace-45-1760952685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 09:31:25.171576+00	1008	Sample prompt for testing iteration 45	Sample response from AI model for iteration 45	\N	success	mixtral-8x7b	mistral	180	161	215	0.005628	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
49	trace-49-1760974285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 15:31:25.171576+00	626	Sample prompt for testing iteration 49	Sample response from AI model for iteration 49	\N	success	gpt-4-turbo	openai	369	28	765	0.035978	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
63	trace-63-1761003085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 23:31:25.171576+00	963	Sample prompt for testing iteration 63	Sample response from AI model for iteration 63	\N	success	mixtral-8x7b	mistral	445	85	199	0.007410	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
70	trace-70-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 06:31:25.171576+00	1358	Sample prompt for testing iteration 70	Sample response from AI model for iteration 70	\N	success	mixtral-8x7b	mistral	517	124	504	0.006824	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
75	trace-75-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 13:31:25.171576+00	4769	Sample prompt for testing iteration 75	Sample response from AI model for iteration 75	\N	success	gemini-pro	google	353	90	477	0.020675	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
76	trace-76-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 06:31:25.171576+00	756	Sample prompt for testing iteration 76	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	258	110	494	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
79	trace-79-1760977885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 16:31:25.171576+00	2025	Sample prompt for testing iteration 79	Sample response from AI model for iteration 79	\N	success	gpt-4-turbo	openai	212	43	597	0.058149	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
100	trace-100-1760988685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 19:31:25.171576+00	1284	Sample prompt for testing iteration 100	Sample response from AI model for iteration 100	\N	success	claude-3-opus	anthropic	298	142	586	0.027623	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
102	trace-102-1760974285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 15:31:25.171576+00	1212	Sample prompt for testing iteration 102	Sample response from AI model for iteration 102	\N	success	gpt-4-turbo	openai	332	212	268	0.056130	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
113	trace-113-1760945485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 07:31:25.171576+00	507	Sample prompt for testing iteration 113	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	410	126	669	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
121	trace-121-1760945485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 07:31:25.171576+00	1539	Sample prompt for testing iteration 121	\N	Request timeout after 1539ms	timeout	gpt-4-turbo	openai	531	198	551	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
131	trace-131-1760985085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 18:31:25.171576+00	297	Sample prompt for testing iteration 131	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	381	20	466	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
136	trace-136-1760923885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 01:31:25.171576+00	874	Sample prompt for testing iteration 136	Sample response from AI model for iteration 136	\N	success	mixtral-8x7b	mistral	505	33	410	0.009281	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
138	trace-138-1760927485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 02:31:25.171576+00	556	Sample prompt for testing iteration 138	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	134	195	134	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
141	trace-141-1760938285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 05:31:25.171576+00	1192	Sample prompt for testing iteration 141	Sample response from AI model for iteration 141	\N	success	claude-3-opus	anthropic	547	189	441	0.071887	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
142	trace-142-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 13:31:25.171576+00	472	Sample prompt for testing iteration 142	Sample response from AI model for iteration 142	\N	success	gpt-4-turbo	openai	165	200	195	0.028191	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
148	trace-148-1760963485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 12:31:25.171576+00	1403	Sample prompt for testing iteration 148	Sample response from AI model for iteration 148	\N	success	claude-3-opus	anthropic	69	135	259	0.061164	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
151	trace-151-1760995885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 21:31:25.171576+00	1601	Sample prompt for testing iteration 151	Sample response from AI model for iteration 151	\N	success	gpt-4-turbo	openai	499	96	704	0.039461	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
163	trace-163-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 06:31:25.171576+00	1422	Sample prompt for testing iteration 163	Sample response from AI model for iteration 163	\N	success	gemini-pro	google	331	128	754	0.009164	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
170	trace-170-1760995885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 21:31:25.171576+00	1853	Sample prompt for testing iteration 170	Sample response from AI model for iteration 170	\N	success	gemini-pro	google	456	156	192	0.024817	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
171	trace-171-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 13:31:25.171576+00	738	Sample prompt for testing iteration 171	Sample response from AI model for iteration 171	\N	success	mixtral-8x7b	mistral	411	75	224	0.008671	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
183	trace-183-1760985085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 18:31:25.171576+00	352	Sample prompt for testing iteration 183	Sample response from AI model for iteration 183	\N	success	gemini-pro	google	180	154	151	0.017100	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
192	trace-192-1760995885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 21:31:25.171576+00	1476	Sample prompt for testing iteration 192	Sample response from AI model for iteration 192	\N	success	claude-3-opus	anthropic	531	197	754	0.069346	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
194	trace-194-1760988685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 19:31:25.171576+00	1433	Sample prompt for testing iteration 194	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	251	51	478	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
197	trace-197-1760959885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 11:31:25.171576+00	1107	Sample prompt for testing iteration 197	Sample response from AI model for iteration 197	\N	success	mixtral-8x7b	mistral	290	178	530	0.009672	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
210	trace-210-1760974285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 15:31:25.171576+00	542	Sample prompt for testing iteration 210	\N	Request timeout after 542ms	timeout	gpt-4-turbo	openai	510	175	724	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
231	trace-231-1760974285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 15:31:25.171576+00	205	Sample prompt for testing iteration 231	\N	Request timeout after 205ms	timeout	mixtral-8x7b	mistral	156	165	738	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
234	trace-234-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 06:31:25.171576+00	2943	Sample prompt for testing iteration 234	Sample response from AI model for iteration 234	\N	success	mixtral-8x7b	mistral	489	142	541	0.003047	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
239	trace-239-1760938285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 05:31:25.171576+00	1429	Sample prompt for testing iteration 239	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	425	107	345	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
240	trace-240-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 13:31:25.171576+00	638	Sample prompt for testing iteration 240	Sample response from AI model for iteration 240	\N	success	claude-3-opus	anthropic	433	208	122	0.065900	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
246	trace-246-1760995885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 21:31:25.171576+00	1479	Sample prompt for testing iteration 246	\N	Request timeout after 1479ms	timeout	gemini-pro	google	120	44	385	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
248	trace-248-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 13:31:25.171576+00	1251	Sample prompt for testing iteration 248	Sample response from AI model for iteration 248	\N	success	gpt-4-turbo	openai	365	62	221	0.015721	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
268	trace-268-1760995885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 21:31:25.171576+00	3880	Sample prompt for testing iteration 268	Sample response from AI model for iteration 268	\N	success	mixtral-8x7b	mistral	248	126	621	0.008289	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
269	trace-269-1760988685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 19:31:25.171576+00	315	Sample prompt for testing iteration 269	Sample response from AI model for iteration 269	\N	success	gemini-pro	google	83	115	522	0.012939	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
270	trace-270-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 13:31:25.171576+00	1478	Sample prompt for testing iteration 270	Sample response from AI model for iteration 270	\N	success	claude-3-opus	anthropic	422	107	715	0.021141	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
272	trace-272-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 06:31:25.171576+00	293	Sample prompt for testing iteration 272	Sample response from AI model for iteration 272	\N	success	gemini-pro	google	199	137	360	0.005021	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
273	trace-273-1760970685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 14:31:25.171576+00	295	Sample prompt for testing iteration 273	Sample response from AI model for iteration 273	\N	success	gemini-pro	google	77	112	176	0.017789	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
276	trace-276-1760938285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 05:31:25.171576+00	597	Sample prompt for testing iteration 276	Sample response from AI model for iteration 276	\N	success	gpt-4-turbo	openai	531	44	467	0.056093	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
277	trace-277-1760934685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 04:31:25.171576+00	1680	Sample prompt for testing iteration 277	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	88	45	139	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
279	trace-279-1760995885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 21:31:25.171576+00	112	Sample prompt for testing iteration 279	Sample response from AI model for iteration 279	\N	success	mixtral-8x7b	mistral	483	77	297	0.011920	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
280	trace-280-1761003085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 23:31:25.171576+00	890	Sample prompt for testing iteration 280	Sample response from AI model for iteration 280	\N	success	gpt-4-turbo	openai	406	102	400	0.040444	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
283	trace-283-1760985085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 18:31:25.171576+00	1776	Sample prompt for testing iteration 283	\N	Request timeout after 1776ms	timeout	claude-3-opus	anthropic	266	91	251	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
285	trace-285-1760927485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 02:31:25.171576+00	1420	Sample prompt for testing iteration 285	Sample response from AI model for iteration 285	\N	success	mixtral-8x7b	mistral	393	54	191	0.011673	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
292	trace-292-1760992285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 20:31:25.171576+00	1826	Sample prompt for testing iteration 292	Sample response from AI model for iteration 292	\N	success	gpt-4-turbo	openai	309	180	275	0.036254	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
293	trace-293-1760920285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 00:31:25.171576+00	4773	Sample prompt for testing iteration 293	Sample response from AI model for iteration 293	\N	success	mixtral-8x7b	mistral	258	218	261	0.010573	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
297	trace-297-1760931085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 03:31:25.171576+00	840	Sample prompt for testing iteration 297	Sample response from AI model for iteration 297	\N	success	gemini-pro	google	494	167	234	0.019135	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
298	trace-298-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 06:31:25.171576+00	1474	Sample prompt for testing iteration 298	Sample response from AI model for iteration 298	\N	success	gpt-4-turbo	openai	369	177	290	0.057569	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
302	trace-302-1760970685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 14:31:25.171576+00	1462	Sample prompt for testing iteration 302	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	151	218	577	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
308	trace-308-1760920285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 00:31:25.171576+00	1571	Sample prompt for testing iteration 308	Sample response from AI model for iteration 308	\N	success	gpt-4-turbo	openai	521	63	358	0.040589	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
309	trace-309-1760963485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 12:31:25.171576+00	1050	Sample prompt for testing iteration 309	Sample response from AI model for iteration 309	\N	success	gemini-pro	google	156	213	580	0.011167	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
311	trace-311-1760938285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 05:31:25.171576+00	654	Sample prompt for testing iteration 311	Sample response from AI model for iteration 311	\N	success	gpt-4-turbo	openai	329	178	547	0.019168	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
312	trace-312-1760931085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 03:31:25.171576+00	679	Sample prompt for testing iteration 312	\N	Request timeout after 679ms	timeout	gpt-4-turbo	openai	495	203	469	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
315	trace-315-1760931085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 03:31:25.171576+00	1077	Sample prompt for testing iteration 315	Sample response from AI model for iteration 315	\N	success	mixtral-8x7b	mistral	271	74	706	0.003524	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
321	trace-321-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 06:31:25.171576+00	279	Sample prompt for testing iteration 321	Sample response from AI model for iteration 321	\N	success	gemini-pro	google	234	61	272	0.018222	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
327	trace-327-1760934685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 04:31:25.171576+00	3595	Sample prompt for testing iteration 327	Sample response from AI model for iteration 327	\N	success	mixtral-8x7b	mistral	497	118	554	0.004472	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
330	trace-330-1760959885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 11:31:25.171576+00	2858	Sample prompt for testing iteration 330	Sample response from AI model for iteration 330	\N	success	gemini-pro	google	332	94	765	0.015041	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
341	trace-341-1760920285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 00:31:25.171576+00	1851	Sample prompt for testing iteration 341	Sample response from AI model for iteration 341	\N	success	claude-3-opus	anthropic	286	131	278	0.063763	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
344	trace-344-1760952685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 09:31:25.171576+00	1268	Sample prompt for testing iteration 344	Sample response from AI model for iteration 344	\N	success	gpt-4-turbo	openai	444	124	259	0.021741	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
356	trace-356-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 13:31:25.171576+00	1380	Sample prompt for testing iteration 356	Sample response from AI model for iteration 356	\N	success	gemini-pro	google	304	91	272	0.014246	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
357	trace-357-1760949085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 08:31:25.171576+00	4125	Sample prompt for testing iteration 357	Sample response from AI model for iteration 357	\N	success	claude-3-opus	anthropic	380	54	408	0.044360	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
365	trace-365-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 13:31:25.171576+00	1234	Sample prompt for testing iteration 365	Sample response from AI model for iteration 365	\N	success	claude-3-opus	anthropic	115	158	198	0.031215	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
368	trace-368-1760977885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 16:31:25.171576+00	1479	Sample prompt for testing iteration 368	\N	Request timeout after 1479ms	timeout	mixtral-8x7b	mistral	154	169	480	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
377	trace-377-1760974285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 15:31:25.171576+00	1318	Sample prompt for testing iteration 377	\N	Request timeout after 1318ms	timeout	mixtral-8x7b	mistral	498	47	386	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
386	trace-386-1760959885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 11:31:25.171576+00	2299	Sample prompt for testing iteration 386	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	124	190	517	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
387	trace-387-1760988685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 19:31:25.171576+00	1298	Sample prompt for testing iteration 387	\N	Request timeout after 1298ms	timeout	gemini-pro	google	483	173	404	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
389	trace-389-1761003085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 23:31:25.171576+00	3695	Sample prompt for testing iteration 389	Sample response from AI model for iteration 389	\N	success	mixtral-8x7b	mistral	101	176	446	0.010544	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
422	trace-422-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 13:31:25.171576+00	4531	Sample prompt for testing iteration 422	\N	Request timeout after 4531ms	timeout	claude-3-opus	anthropic	166	126	377	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
428	trace-428-1761003085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 23:31:25.171576+00	903	Sample prompt for testing iteration 428	Sample response from AI model for iteration 428	\N	success	gpt-4-turbo	openai	311	157	432	0.020977	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
432	trace-432-1760963485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 12:31:25.171576+00	1619	Sample prompt for testing iteration 432	Sample response from AI model for iteration 432	\N	success	mixtral-8x7b	mistral	506	198	428	0.004846	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
433	trace-433-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 13:31:25.171576+00	605	Sample prompt for testing iteration 433	Sample response from AI model for iteration 433	\N	success	gemini-pro	google	268	135	326	0.013654	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
436	trace-436-1760995885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 21:31:25.171576+00	712	Sample prompt for testing iteration 436	Sample response from AI model for iteration 436	\N	success	gemini-pro	google	467	38	630	0.015169	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
443	trace-443-1760963485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 12:31:25.171576+00	1155	Sample prompt for testing iteration 443	Sample response from AI model for iteration 443	\N	success	gpt-4-turbo	openai	210	141	711	0.011498	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
449	trace-449-1761003085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 23:31:25.171576+00	890	Sample prompt for testing iteration 449	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	430	78	467	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
458	trace-458-1760920285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 00:31:25.171576+00	1203	Sample prompt for testing iteration 458	Sample response from AI model for iteration 458	\N	success	gemini-pro	google	345	146	506	0.006444	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
459	trace-459-1760988685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 19:31:25.171576+00	1681	Sample prompt for testing iteration 459	\N	Request timeout after 1681ms	timeout	gemini-pro	google	357	157	643	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
460	trace-460-1760977885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 16:31:25.171576+00	1863	Sample prompt for testing iteration 460	Sample response from AI model for iteration 460	\N	success	mixtral-8x7b	mistral	201	190	164	0.003575	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
461	trace-461-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 13:31:25.171576+00	101	Sample prompt for testing iteration 461	Sample response from AI model for iteration 461	\N	success	gpt-4-turbo	openai	273	145	762	0.031260	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
465	trace-465-1760992285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 20:31:25.171576+00	1898	Sample prompt for testing iteration 465	\N	Sample error message: API_ERROR	error	gemini-pro	google	167	31	93	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
475	trace-475-1760999485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 22:31:25.171576+00	802	Sample prompt for testing iteration 475	Sample response from AI model for iteration 475	\N	success	claude-3-opus	anthropic	82	20	170	0.060193	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
479	trace-479-1760963485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 12:31:25.171576+00	1571	Sample prompt for testing iteration 479	\N	Request timeout after 1571ms	timeout	mixtral-8x7b	mistral	261	78	235	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
488	trace-488-1760992285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 20:31:25.171576+00	890	Sample prompt for testing iteration 488	Sample response from AI model for iteration 488	\N	success	claude-3-opus	anthropic	513	204	94	0.018075	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
490	trace-490-1760920285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 00:31:25.171576+00	1433	Sample prompt for testing iteration 490	\N	Sample error message: API_ERROR	error	gemini-pro	google	185	123	598	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
503	trace-503-1760981485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 17:31:25.171576+00	672	Sample prompt for testing iteration 503	\N	Request timeout after 672ms	timeout	mixtral-8x7b	mistral	481	133	681	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
508	trace-508-1760927485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 02:31:25.171576+00	424	Sample prompt for testing iteration 508	Sample response from AI model for iteration 508	\N	success	claude-3-opus	anthropic	66	164	494	0.071155	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
512	trace-512-1760927485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 02:31:25.171576+00	294	Sample prompt for testing iteration 512	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	363	103	339	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
522	trace-522-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 13:31:25.171576+00	1637	Sample prompt for testing iteration 522	Sample response from AI model for iteration 522	\N	success	gpt-4-turbo	openai	191	108	393	0.040220	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
527	trace-527-1760963485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 12:31:25.171576+00	988	Sample prompt for testing iteration 527	Sample response from AI model for iteration 527	\N	success	mixtral-8x7b	mistral	153	106	369	0.005087	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
536	trace-536-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 13:31:25.171576+00	1301	Sample prompt for testing iteration 536	Sample response from AI model for iteration 536	\N	success	mixtral-8x7b	mistral	209	155	686	0.005922	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
540	trace-540-1760985085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 18:31:25.171576+00	569	Sample prompt for testing iteration 540	Sample response from AI model for iteration 540	\N	success	claude-3-opus	anthropic	273	69	374	0.024393	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
552	trace-552-1760995885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 21:31:25.171576+00	746	Sample prompt for testing iteration 552	Sample response from AI model for iteration 552	\N	success	mixtral-8x7b	mistral	367	183	196	0.003513	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
554	trace-554-1760959885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 11:31:25.171576+00	490	Sample prompt for testing iteration 554	Sample response from AI model for iteration 554	\N	success	gpt-4-turbo	openai	123	183	488	0.046625	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
560	trace-560-1760920285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 00:31:25.171576+00	2042	Sample prompt for testing iteration 560	\N	Request timeout after 2042ms	timeout	claude-3-opus	anthropic	99	46	635	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
568	trace-568-1760927485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 02:31:25.171576+00	1298	Sample prompt for testing iteration 568	Sample response from AI model for iteration 568	\N	success	mixtral-8x7b	mistral	208	77	662	0.006031	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
572	trace-572-1760988685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 19:31:25.171576+00	1226	Sample prompt for testing iteration 572	Sample response from AI model for iteration 572	\N	success	claude-3-opus	anthropic	484	42	314	0.063308	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
574	trace-574-1760977885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 16:31:25.171576+00	543	Sample prompt for testing iteration 574	\N	Request timeout after 543ms	timeout	mixtral-8x7b	mistral	82	90	705	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
578	trace-578-1761003085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 23:31:25.171576+00	1440	Sample prompt for testing iteration 578	Sample response from AI model for iteration 578	\N	success	gpt-4-turbo	openai	93	195	219	0.043030	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
584	trace-584-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 06:31:25.171576+00	222	Sample prompt for testing iteration 584	\N	Request timeout after 222ms	timeout	gemini-pro	google	135	120	653	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
593	trace-593-1760934685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 04:31:25.171576+00	3894	Sample prompt for testing iteration 593	Sample response from AI model for iteration 593	\N	success	claude-3-opus	anthropic	336	161	134	0.021057	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
595	trace-595-1760934685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 04:31:25.171576+00	631	Sample prompt for testing iteration 595	Sample response from AI model for iteration 595	\N	success	claude-3-opus	anthropic	115	37	256	0.033867	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
608	trace-608-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 06:31:25.171576+00	916	Sample prompt for testing iteration 608	\N	Sample error message: API_ERROR	error	gemini-pro	google	243	216	726	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
627	trace-627-1760977885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 16:31:25.171576+00	1955	Sample prompt for testing iteration 627	Sample response from AI model for iteration 627	\N	success	claude-3-opus	anthropic	497	78	377	0.054927	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
644	trace-644-1760934685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 04:31:25.171576+00	1652	Sample prompt for testing iteration 644	Sample response from AI model for iteration 644	\N	success	mixtral-8x7b	mistral	345	75	237	0.009564	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
656	trace-656-1760988685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 19:31:25.171576+00	348	Sample prompt for testing iteration 656	Sample response from AI model for iteration 656	\N	success	gpt-4-turbo	openai	130	74	140	0.050070	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
659	trace-659-1760992285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 20:31:25.171576+00	1627	Sample prompt for testing iteration 659	Sample response from AI model for iteration 659	\N	success	gpt-4-turbo	openai	231	70	211	0.032009	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
666	trace-666-1760959885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 11:31:25.171576+00	805	Sample prompt for testing iteration 666	\N	Sample error message: API_ERROR	error	gemini-pro	google	409	186	384	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
674	trace-674-1760988685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 19:31:25.171576+00	836	Sample prompt for testing iteration 674	Sample response from AI model for iteration 674	\N	success	claude-3-opus	anthropic	418	113	376	0.052856	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
676	trace-676-1760988685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 19:31:25.171576+00	2053	Sample prompt for testing iteration 676	Sample response from AI model for iteration 676	\N	success	claude-3-opus	anthropic	151	216	152	0.068041	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
684	trace-684-1760981485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 17:31:25.171576+00	815	Sample prompt for testing iteration 684	\N	Request timeout after 815ms	timeout	mixtral-8x7b	mistral	119	89	505	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
686	trace-686-1760931085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 03:31:25.171576+00	487	Sample prompt for testing iteration 686	Sample response from AI model for iteration 686	\N	success	mixtral-8x7b	mistral	425	169	129	0.011520	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
709	trace-709-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 13:31:25.171576+00	206	Sample prompt for testing iteration 709	Sample response from AI model for iteration 709	\N	success	claude-3-opus	anthropic	237	96	755	0.067940	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
710	trace-710-1760956285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 10:31:25.171576+00	1066	Sample prompt for testing iteration 710	\N	Request timeout after 1066ms	timeout	gpt-4-turbo	openai	190	104	317	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
720	trace-720-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 06:31:25.171576+00	714	Sample prompt for testing iteration 720	Sample response from AI model for iteration 720	\N	success	claude-3-opus	anthropic	175	213	689	0.025315	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
730	trace-730-1760931085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 03:31:25.171576+00	437	Sample prompt for testing iteration 730	Sample response from AI model for iteration 730	\N	success	gemini-pro	google	170	93	261	0.010063	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
732	trace-732-1760999485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 22:31:25.171576+00	1291	Sample prompt for testing iteration 732	\N	Request timeout after 1291ms	timeout	gpt-4-turbo	openai	346	88	316	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
737	trace-737-1760992285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 20:31:25.171576+00	1040	Sample prompt for testing iteration 737	Sample response from AI model for iteration 737	\N	success	gemini-pro	google	376	151	129	0.007038	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
760	trace-760-1760967085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 13:31:25.171576+00	1861	Sample prompt for testing iteration 760	Sample response from AI model for iteration 760	\N	success	gpt-4-turbo	openai	166	193	586	0.012910	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
764	trace-764-1760952685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 09:31:25.171576+00	303	Sample prompt for testing iteration 764	\N	Request timeout after 303ms	timeout	gemini-pro	google	235	39	538	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
767	trace-767-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 06:31:25.171576+00	131	Sample prompt for testing iteration 767	Sample response from AI model for iteration 767	\N	success	claude-3-opus	anthropic	67	28	605	0.073713	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
770	trace-770-1760970685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 14:31:25.171576+00	641	Sample prompt for testing iteration 770	Sample response from AI model for iteration 770	\N	success	gemini-pro	google	437	168	676	0.011496	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
773	trace-773-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 06:31:25.171576+00	640	Sample prompt for testing iteration 773	Sample response from AI model for iteration 773	\N	success	mixtral-8x7b	mistral	383	51	495	0.008939	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
783	trace-783-1760956285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 10:31:25.171576+00	1849	Sample prompt for testing iteration 783	Sample response from AI model for iteration 783	\N	success	gemini-pro	google	236	73	337	0.005061	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
784	trace-784-1760931085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 03:31:25.171576+00	1277	Sample prompt for testing iteration 784	Sample response from AI model for iteration 784	\N	success	mixtral-8x7b	mistral	178	44	255	0.005882	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
802	trace-802-1760977885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 16:31:25.171576+00	1844	Sample prompt for testing iteration 802	Sample response from AI model for iteration 802	\N	success	claude-3-opus	anthropic	249	25	200	0.053520	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
810	trace-810-1760974285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 15:31:25.171576+00	1532	Sample prompt for testing iteration 810	Sample response from AI model for iteration 810	\N	success	gemini-pro	google	251	80	369	0.012759	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
816	trace-816-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 06:31:25.171576+00	1245	Sample prompt for testing iteration 816	Sample response from AI model for iteration 816	\N	success	claude-3-opus	anthropic	290	195	313	0.048059	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
818	trace-818-1761003085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 23:31:25.171576+00	1931	Sample prompt for testing iteration 818	Sample response from AI model for iteration 818	\N	success	mixtral-8x7b	mistral	287	146	627	0.005187	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
822	trace-822-1760927485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 02:31:25.171576+00	114	Sample prompt for testing iteration 822	Sample response from AI model for iteration 822	\N	success	gemini-pro	google	521	168	357	0.011503	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
828	trace-828-1760945485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 07:31:25.171576+00	1307	Sample prompt for testing iteration 828	Sample response from AI model for iteration 828	\N	success	gemini-pro	google	62	143	498	0.016578	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
841	trace-841-1760927485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 02:31:25.171576+00	2458	Sample prompt for testing iteration 841	Sample response from AI model for iteration 841	\N	success	claude-3-opus	anthropic	483	218	457	0.021405	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
850	trace-850-1760981485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 17:31:25.171576+00	625	Sample prompt for testing iteration 850	Sample response from AI model for iteration 850	\N	success	gpt-4-turbo	openai	515	107	722	0.018689	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
862	trace-862-1760941885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 06:31:25.171576+00	224	Sample prompt for testing iteration 862	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	96	124	336	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
872	trace-872-1760920285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 00:31:25.171576+00	1730	Sample prompt for testing iteration 872	Sample response from AI model for iteration 872	\N	success	claude-3-opus	anthropic	532	129	425	0.064109	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
874	trace-874-1760938285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 05:31:25.171576+00	304	Sample prompt for testing iteration 874	\N	Sample error message: API_ERROR	error	gemini-pro	google	80	47	515	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
883	trace-883-1760963485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 12:31:25.171576+00	972	Sample prompt for testing iteration 883	Sample response from AI model for iteration 883	\N	success	gpt-4-turbo	openai	303	120	564	0.016793	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
898	trace-898-1760923885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 01:31:25.171576+00	1241	Sample prompt for testing iteration 898	Sample response from AI model for iteration 898	\N	success	claude-3-opus	anthropic	294	133	330	0.033236	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
913	trace-913-1760920285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 00:31:25.171576+00	460	Sample prompt for testing iteration 913	Sample response from AI model for iteration 913	\N	success	gemini-pro	google	124	37	683	0.023751	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
915	trace-915-1760959885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 11:31:25.171576+00	1403	Sample prompt for testing iteration 915	Sample response from AI model for iteration 915	\N	success	gemini-pro	google	51	186	323	0.024382	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
919	trace-919-1760981485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 17:31:25.171576+00	758	Sample prompt for testing iteration 919	\N	Request timeout after 758ms	timeout	gemini-pro	google	179	94	680	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
923	trace-923-1760934685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 04:31:25.171576+00	1366	Sample prompt for testing iteration 923	Sample response from AI model for iteration 923	\N	success	mixtral-8x7b	mistral	267	63	271	0.011676	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
926	trace-926-1760970685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 14:31:25.171576+00	1056	Sample prompt for testing iteration 926	Sample response from AI model for iteration 926	\N	success	claude-3-opus	anthropic	144	186	121	0.058610	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
932	trace-932-1760920285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 00:31:25.171576+00	1583	Sample prompt for testing iteration 932	Sample response from AI model for iteration 932	\N	success	claude-3-opus	anthropic	418	52	321	0.021996	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
933	trace-933-1760959885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 11:31:25.171576+00	1995	Sample prompt for testing iteration 933	\N	Sample error message: API_ERROR	error	gemini-pro	google	450	172	285	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
937	trace-937-1760931085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 03:31:25.171576+00	1721	Sample prompt for testing iteration 937	\N	Request timeout after 1721ms	timeout	gpt-4-turbo	openai	503	89	748	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
939	trace-939-1760956285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 10:31:25.171576+00	616	Sample prompt for testing iteration 939	Sample response from AI model for iteration 939	\N	success	gpt-4-turbo	openai	357	165	450	0.048800	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
949	trace-949-1760981485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 17:31:25.171576+00	236	Sample prompt for testing iteration 949	Sample response from AI model for iteration 949	\N	success	gemini-pro	google	182	136	423	0.015217	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
953	trace-953-1760963485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 12:31:25.171576+00	1088	Sample prompt for testing iteration 953	Sample response from AI model for iteration 953	\N	success	gpt-4-turbo	openai	241	106	757	0.056003	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
956	trace-956-1760923885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 01:31:25.171576+00	760	Sample prompt for testing iteration 956	Sample response from AI model for iteration 956	\N	success	gpt-4-turbo	openai	543	145	518	0.029452	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
982	trace-982-1760923885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 01:31:25.171576+00	1250	Sample prompt for testing iteration 982	Sample response from AI model for iteration 982	\N	success	claude-3-opus	anthropic	425	53	352	0.054754	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
988	trace-988-1760927485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 02:31:25.171576+00	1148	Sample prompt for testing iteration 988	Sample response from AI model for iteration 988	\N	success	gpt-4-turbo	openai	527	192	248	0.029439	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
991	trace-991-1760999485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 22:31:25.171576+00	4989	Sample prompt for testing iteration 991	\N	Request timeout after 4989ms	timeout	claude-3-opus	anthropic	76	126	231	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
992	trace-992-1760959885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 11:31:25.171576+00	1576	Sample prompt for testing iteration 992	Sample response from AI model for iteration 992	\N	success	gemini-pro	google	191	178	377	0.006176	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1010	trace-10-1760967680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 13:41:20.663+00	193	Sample prompt for testing iteration 10	\N	Sample error message: API_ERROR	error	gemini-pro	google	549	160	112	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1020	trace-20-1760920880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 00:41:20.663+00	1956	Sample prompt for testing iteration 20	Sample response from AI model for iteration 20	\N	success	gpt-4-turbo	openai	500	100	765	0.018872	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1021	trace-21-1760978480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 16:41:20.663+00	1390	Sample prompt for testing iteration 21	Sample response from AI model for iteration 21	\N	success	mixtral-8x7b	mistral	166	33	391	0.009008	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1024	trace-24-1760956880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 10:41:20.663+00	2060	Sample prompt for testing iteration 24	\N	Request timeout after 2060ms	timeout	claude-3-opus	anthropic	469	64	619	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1031	trace-31-1760946080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 07:41:20.663+00	1826	Sample prompt for testing iteration 31	Sample response from AI model for iteration 31	\N	success	mixtral-8x7b	mistral	247	98	554	0.010292	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1036	trace-36-1760967680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 13:41:20.663+00	3452	Sample prompt for testing iteration 36	\N	Sample error message: API_ERROR	error	gemini-pro	google	295	60	267	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1048	trace-48-1760982080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 17:41:20.663+00	1653	Sample prompt for testing iteration 48	Sample response from AI model for iteration 48	\N	success	mixtral-8x7b	mistral	453	98	578	0.007740	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1049	trace-49-1760978480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 16:41:20.663+00	479	Sample prompt for testing iteration 49	Sample response from AI model for iteration 49	\N	success	mixtral-8x7b	mistral	155	61	444	0.012026	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1053	trace-53-1761003680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 23:41:20.663+00	1993	Sample prompt for testing iteration 53	Sample response from AI model for iteration 53	\N	success	gemini-pro	google	94	145	251	0.011870	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1055	trace-55-1760931680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 03:41:20.663+00	800	Sample prompt for testing iteration 55	Sample response from AI model for iteration 55	\N	success	mixtral-8x7b	mistral	420	156	81	0.012863	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1056	trace-56-1760931680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 03:41:20.663+00	741	Sample prompt for testing iteration 56	Sample response from AI model for iteration 56	\N	success	claude-3-opus	anthropic	240	66	608	0.025000	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1075	trace-75-1760992880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 20:41:20.663+00	1145	Sample prompt for testing iteration 75	Sample response from AI model for iteration 75	\N	success	gemini-pro	google	96	25	156	0.020293	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1079	trace-79-1760960480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 11:41:20.663+00	593	Sample prompt for testing iteration 79	Sample response from AI model for iteration 79	\N	success	mixtral-8x7b	mistral	177	128	453	0.007635	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1085	trace-85-1760960480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 11:41:20.663+00	311	Sample prompt for testing iteration 85	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	124	195	746	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1091	trace-91-1760967680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 13:41:20.663+00	1382	Sample prompt for testing iteration 91	Sample response from AI model for iteration 91	\N	success	gpt-4-turbo	openai	498	76	270	0.024959	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1092	trace-92-1760924480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 01:41:20.663+00	1289	Sample prompt for testing iteration 92	\N	Request timeout after 1289ms	timeout	claude-3-opus	anthropic	395	84	539	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1103	trace-103-1760989280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 19:41:20.663+00	1782	Sample prompt for testing iteration 103	Sample response from AI model for iteration 103	\N	success	mixtral-8x7b	mistral	389	186	140	0.005998	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1107	trace-107-1760960480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 11:41:20.663+00	936	Sample prompt for testing iteration 107	\N	Request timeout after 936ms	timeout	claude-3-opus	anthropic	50	143	683	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1109	trace-109-1760967680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 13:41:20.663+00	1093	Sample prompt for testing iteration 109	Sample response from AI model for iteration 109	\N	success	mixtral-8x7b	mistral	393	157	627	0.010332	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1120	trace-120-1760938880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 05:41:20.663+00	1742	Sample prompt for testing iteration 120	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	372	162	224	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1125	trace-125-1761003680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 23:41:20.663+00	2045	Sample prompt for testing iteration 125	Sample response from AI model for iteration 125	\N	success	claude-3-opus	anthropic	196	65	119	0.020842	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1128	trace-128-1761003680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 23:41:20.663+00	1969	Sample prompt for testing iteration 128	Sample response from AI model for iteration 128	\N	success	gemini-pro	google	99	163	652	0.011144	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1130	trace-130-1760978480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 16:41:20.663+00	251	Sample prompt for testing iteration 130	Sample response from AI model for iteration 130	\N	success	gemini-pro	google	449	49	411	0.020055	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1135	trace-135-1760992880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 20:41:20.663+00	295	Sample prompt for testing iteration 135	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	205	73	766	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1157	trace-157-1760938880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 05:41:20.663+00	2023	Sample prompt for testing iteration 157	\N	Sample error message: API_ERROR	error	gemini-pro	google	57	111	176	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1180	trace-180-1760931680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 03:41:20.663+00	205	Sample prompt for testing iteration 180	Sample response from AI model for iteration 180	\N	success	gpt-4-turbo	openai	485	218	241	0.051783	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1197	trace-197-1760960480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 11:41:20.663+00	382	Sample prompt for testing iteration 197	Sample response from AI model for iteration 197	\N	success	gpt-4-turbo	openai	280	171	683	0.056943	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1200	trace-200-1760938880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 05:41:20.663+00	1751	Sample prompt for testing iteration 200	Sample response from AI model for iteration 200	\N	success	gemini-pro	google	294	213	569	0.024402	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1204	trace-204-1760974880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 15:41:20.663+00	767	Sample prompt for testing iteration 204	\N	Sample error message: API_ERROR	error	gemini-pro	google	82	166	661	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1213	trace-213-1760964080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 12:41:20.663+00	1366	Sample prompt for testing iteration 213	Sample response from AI model for iteration 213	\N	success	claude-3-opus	anthropic	142	164	156	0.039950	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1215	trace-215-1760931680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 03:41:20.663+00	1821	Sample prompt for testing iteration 215	Sample response from AI model for iteration 215	\N	success	claude-3-opus	anthropic	453	63	80	0.025537	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1222	trace-222-1760989280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 19:41:20.663+00	1594	Sample prompt for testing iteration 222	Sample response from AI model for iteration 222	\N	success	claude-3-opus	anthropic	54	202	130	0.070797	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1225	trace-225-1760967680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 13:41:20.663+00	4447	Sample prompt for testing iteration 225	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	97	186	548	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1236	trace-236-1760982080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 17:41:20.663+00	1519	Sample prompt for testing iteration 236	Sample response from AI model for iteration 236	\N	success	gemini-pro	google	71	41	702	0.020564	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1245	trace-245-1760967680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 13:41:20.663+00	749	Sample prompt for testing iteration 245	Sample response from AI model for iteration 245	\N	success	gpt-4-turbo	openai	484	212	505	0.039730	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1246	trace-246-1760971280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 14:41:20.663+00	1349	Sample prompt for testing iteration 246	Sample response from AI model for iteration 246	\N	success	mixtral-8x7b	mistral	378	131	438	0.009190	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1257	trace-257-1760942480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 06:41:20.663+00	1362	Sample prompt for testing iteration 257	Sample response from AI model for iteration 257	\N	success	mixtral-8x7b	mistral	502	131	320	0.004773	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1272	trace-272-1761000080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 22:41:20.663+00	1826	Sample prompt for testing iteration 272	Sample response from AI model for iteration 272	\N	success	mixtral-8x7b	mistral	87	48	338	0.003545	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1287	trace-287-1760985680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 18:41:20.663+00	156	Sample prompt for testing iteration 287	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	232	200	385	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1291	trace-291-1761000080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 22:41:20.663+00	445	Sample prompt for testing iteration 291	Sample response from AI model for iteration 291	\N	success	gpt-4-turbo	openai	481	73	118	0.058096	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1295	trace-295-1760920880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 00:41:20.663+00	726	Sample prompt for testing iteration 295	Sample response from AI model for iteration 295	\N	success	claude-3-opus	anthropic	206	126	634	0.039014	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1315	trace-315-1760935280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 04:41:20.663+00	1270	Sample prompt for testing iteration 315	Sample response from AI model for iteration 315	\N	success	gpt-4-turbo	openai	67	133	513	0.054431	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1316	trace-316-1760942480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 06:41:20.663+00	1736	Sample prompt for testing iteration 316	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	445	78	192	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1325	trace-325-1760992880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 20:41:20.663+00	1897	Sample prompt for testing iteration 325	Sample response from AI model for iteration 325	\N	success	mixtral-8x7b	mistral	153	37	259	0.005094	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1330	trace-330-1761003680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 23:41:20.663+00	1345	Sample prompt for testing iteration 330	Sample response from AI model for iteration 330	\N	success	mixtral-8x7b	mistral	378	154	93	0.010753	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1335	trace-335-1760938880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 05:41:20.663+00	2768	Sample prompt for testing iteration 335	Sample response from AI model for iteration 335	\N	success	gpt-4-turbo	openai	183	168	576	0.016322	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1341	trace-341-1760964080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 12:41:20.663+00	127	Sample prompt for testing iteration 341	Sample response from AI model for iteration 341	\N	success	claude-3-opus	anthropic	320	87	339	0.021212	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1342	trace-342-1760978480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 16:41:20.663+00	3705	Sample prompt for testing iteration 342	Sample response from AI model for iteration 342	\N	success	claude-3-opus	anthropic	202	26	768	0.058391	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1346	trace-346-1760942480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 06:41:20.663+00	1310	Sample prompt for testing iteration 346	Sample response from AI model for iteration 346	\N	success	gpt-4-turbo	openai	197	121	746	0.021820	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1357	trace-357-1760953280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 09:41:20.663+00	2093	Sample prompt for testing iteration 357	Sample response from AI model for iteration 357	\N	success	claude-3-opus	anthropic	155	200	463	0.020572	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1360	trace-360-1760996480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 21:41:20.663+00	1336	Sample prompt for testing iteration 360	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	79	136	505	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1365	trace-365-1760978480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 16:41:20.663+00	1024	Sample prompt for testing iteration 365	Sample response from AI model for iteration 365	\N	success	gemini-pro	google	65	123	402	0.023139	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1367	trace-367-1760931680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 03:41:20.663+00	1734	Sample prompt for testing iteration 367	Sample response from AI model for iteration 367	\N	success	claude-3-opus	anthropic	382	139	295	0.027760	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1368	trace-368-1760974880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 15:41:20.663+00	1250	Sample prompt for testing iteration 368	Sample response from AI model for iteration 368	\N	success	claude-3-opus	anthropic	369	161	679	0.067504	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1383	trace-383-1760956880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 10:41:20.663+00	1145	Sample prompt for testing iteration 383	Sample response from AI model for iteration 383	\N	success	gpt-4-turbo	openai	185	57	264	0.023332	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1384	trace-384-1760978480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 16:41:20.663+00	990	Sample prompt for testing iteration 384	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	162	133	364	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1391	trace-391-1760978480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 16:41:20.663+00	906	Sample prompt for testing iteration 391	\N	Request timeout after 906ms	timeout	mixtral-8x7b	mistral	542	192	335	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1398	trace-398-1760996480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 21:41:20.663+00	1106	Sample prompt for testing iteration 398	\N	Request timeout after 1106ms	timeout	gpt-4-turbo	openai	132	105	242	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1408	trace-408-1760949680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 08:41:20.663+00	335	Sample prompt for testing iteration 408	Sample response from AI model for iteration 408	\N	success	gemini-pro	google	289	104	568	0.024435	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1412	trace-412-1760985680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 18:41:20.663+00	1776	Sample prompt for testing iteration 412	\N	Request timeout after 1776ms	timeout	gpt-4-turbo	openai	498	32	745	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1413	trace-413-1760992880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 20:41:20.663+00	858	Sample prompt for testing iteration 413	Sample response from AI model for iteration 413	\N	success	gpt-4-turbo	openai	223	162	734	0.031976	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1422	trace-422-1760985680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 18:41:20.663+00	718	Sample prompt for testing iteration 422	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	240	91	534	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1424	trace-424-1760978480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 16:41:20.663+00	879	Sample prompt for testing iteration 424	Sample response from AI model for iteration 424	\N	success	gpt-4-turbo	openai	445	54	379	0.054411	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1442	trace-442-1761000080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 22:41:20.663+00	247	Sample prompt for testing iteration 442	Sample response from AI model for iteration 442	\N	success	claude-3-opus	anthropic	520	171	399	0.056831	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1445	trace-445-1761000080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 22:41:20.663+00	1040	Sample prompt for testing iteration 445	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	125	146	536	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1447	trace-447-1760971280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 14:41:20.663+00	1044	Sample prompt for testing iteration 447	\N	Request timeout after 1044ms	timeout	gemini-pro	google	200	185	325	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1454	trace-454-1760953280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 09:41:20.663+00	1265	Sample prompt for testing iteration 454	\N	Sample error message: API_ERROR	error	gemini-pro	google	530	105	261	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1469	trace-469-1760949680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 08:41:20.663+00	953	Sample prompt for testing iteration 469	Sample response from AI model for iteration 469	\N	success	gemini-pro	google	545	85	435	0.015053	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1479	trace-479-1760978480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 16:41:20.663+00	4872	Sample prompt for testing iteration 479	Sample response from AI model for iteration 479	\N	success	gpt-4-turbo	openai	251	166	714	0.026978	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1487	trace-487-1760920880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 00:41:20.663+00	1710	Sample prompt for testing iteration 487	Sample response from AI model for iteration 487	\N	success	mixtral-8x7b	mistral	393	96	461	0.007347	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1497	trace-497-1760953280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 09:41:20.663+00	2071	Sample prompt for testing iteration 497	Sample response from AI model for iteration 497	\N	success	gemini-pro	google	140	219	469	0.011848	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1499	trace-499-1760935280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 04:41:20.663+00	1271	Sample prompt for testing iteration 499	Sample response from AI model for iteration 499	\N	success	mixtral-8x7b	mistral	492	63	315	0.006659	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1506	trace-506-1760949680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 08:41:20.663+00	1458	Sample prompt for testing iteration 506	Sample response from AI model for iteration 506	\N	success	claude-3-opus	anthropic	462	65	212	0.044573	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1510	trace-510-1760946080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 07:41:20.663+00	937	Sample prompt for testing iteration 510	Sample response from AI model for iteration 510	\N	success	gpt-4-turbo	openai	181	125	613	0.017785	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1513	trace-513-1760928080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 02:41:20.663+00	1532	Sample prompt for testing iteration 513	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	189	91	455	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1520	trace-520-1760920880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 00:41:20.663+00	1566	Sample prompt for testing iteration 520	Sample response from AI model for iteration 520	\N	success	gemini-pro	google	143	101	95	0.023953	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1536	trace-536-1760992880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 20:41:20.663+00	612	Sample prompt for testing iteration 536	Sample response from AI model for iteration 536	\N	success	gpt-4-turbo	openai	404	169	370	0.012485	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1548	trace-548-1760960480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 11:41:20.663+00	244	Sample prompt for testing iteration 548	Sample response from AI model for iteration 548	\N	success	gemini-pro	google	85	135	743	0.018439	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1552	trace-552-1760924480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 01:41:20.663+00	369	Sample prompt for testing iteration 552	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	302	109	416	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1554	trace-554-1760982080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 17:41:20.663+00	585	Sample prompt for testing iteration 554	\N	Request timeout after 585ms	timeout	gemini-pro	google	337	108	398	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1557	trace-557-1760971280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 14:41:20.663+00	1115	Sample prompt for testing iteration 557	\N	Request timeout after 1115ms	timeout	claude-3-opus	anthropic	324	161	85	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1561	trace-561-1760938880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 05:41:20.663+00	822	Sample prompt for testing iteration 561	Sample response from AI model for iteration 561	\N	success	gemini-pro	google	269	169	606	0.020724	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1563	trace-563-1760989280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 19:41:20.663+00	937	Sample prompt for testing iteration 563	Sample response from AI model for iteration 563	\N	success	claude-3-opus	anthropic	488	20	699	0.023178	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1564	trace-564-1760960480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 11:41:20.663+00	130	Sample prompt for testing iteration 564	\N	Request timeout after 130ms	timeout	gpt-4-turbo	openai	159	60	134	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1566	trace-566-1760996480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 21:41:20.663+00	1867	Sample prompt for testing iteration 566	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	159	126	140	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1581	trace-581-1760960480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 11:41:20.663+00	1085	Sample prompt for testing iteration 581	Sample response from AI model for iteration 581	\N	success	gemini-pro	google	404	92	661	0.024818	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1584	trace-584-1760924480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 01:41:20.663+00	1552	Sample prompt for testing iteration 584	\N	Sample error message: API_ERROR	error	gemini-pro	google	344	146	433	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1597	trace-597-1760974880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 15:41:20.663+00	1254	Sample prompt for testing iteration 597	Sample response from AI model for iteration 597	\N	success	claude-3-opus	anthropic	476	174	99	0.071712	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1603	trace-603-1760964080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 12:41:20.663+00	2063	Sample prompt for testing iteration 603	Sample response from AI model for iteration 603	\N	success	gemini-pro	google	373	84	366	0.010545	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1607	trace-607-1760964080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 12:41:20.663+00	753	Sample prompt for testing iteration 607	Sample response from AI model for iteration 607	\N	success	mixtral-8x7b	mistral	270	124	360	0.003256	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1608	trace-608-1760964080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 12:41:20.663+00	703	Sample prompt for testing iteration 608	Sample response from AI model for iteration 608	\N	success	mixtral-8x7b	mistral	275	65	177	0.012423	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1615	trace-615-1760924480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 01:41:20.663+00	300	Sample prompt for testing iteration 615	Sample response from AI model for iteration 615	\N	success	mixtral-8x7b	mistral	529	116	529	0.008145	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1627	trace-627-1760935280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 04:41:20.663+00	248	Sample prompt for testing iteration 627	Sample response from AI model for iteration 627	\N	success	gemini-pro	google	113	46	587	0.022424	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1634	trace-634-1760953280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 09:41:20.663+00	1008	Sample prompt for testing iteration 634	Sample response from AI model for iteration 634	\N	success	claude-3-opus	anthropic	126	33	359	0.015676	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1637	trace-637-1760938880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 05:41:20.663+00	821	Sample prompt for testing iteration 637	Sample response from AI model for iteration 637	\N	success	mixtral-8x7b	mistral	95	170	549	0.012523	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1647	trace-647-1761003680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 23:41:20.663+00	1499	Sample prompt for testing iteration 647	Sample response from AI model for iteration 647	\N	success	gemini-pro	google	239	185	339	0.012590	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1650	trace-650-1760996480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 21:41:20.663+00	1393	Sample prompt for testing iteration 650	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	89	37	243	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1656	trace-656-1760935280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 04:41:20.663+00	359	Sample prompt for testing iteration 656	Sample response from AI model for iteration 656	\N	success	gemini-pro	google	445	146	264	0.014037	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1657	trace-657-1760956880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 10:41:20.663+00	1412	Sample prompt for testing iteration 657	Sample response from AI model for iteration 657	\N	success	gpt-4-turbo	openai	358	171	617	0.039809	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1659	trace-659-1761003680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 23:41:20.663+00	1631	Sample prompt for testing iteration 659	Sample response from AI model for iteration 659	\N	success	claude-3-opus	anthropic	394	59	126	0.070148	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1668	trace-668-1760967680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 13:41:20.663+00	456	Sample prompt for testing iteration 668	Sample response from AI model for iteration 668	\N	success	gpt-4-turbo	openai	274	158	608	0.025285	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1673	trace-673-1760938880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 05:41:20.663+00	915	Sample prompt for testing iteration 673	Sample response from AI model for iteration 673	\N	success	claude-3-opus	anthropic	94	132	598	0.065957	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1675	trace-675-1760992880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 20:41:20.663+00	938	Sample prompt for testing iteration 675	Sample response from AI model for iteration 675	\N	success	gemini-pro	google	509	216	600	0.019514	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1688	trace-688-1760982080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 17:41:20.663+00	1322	Sample prompt for testing iteration 688	\N	Request timeout after 1322ms	timeout	gpt-4-turbo	openai	119	140	139	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1701	trace-701-1760920880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 00:41:20.663+00	1037	Sample prompt for testing iteration 701	Sample response from AI model for iteration 701	\N	success	mixtral-8x7b	mistral	357	182	504	0.005828	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1705	trace-705-1761003680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 23:41:20.663+00	1390	Sample prompt for testing iteration 705	Sample response from AI model for iteration 705	\N	success	gpt-4-turbo	openai	292	143	79	0.011910	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1706	trace-706-1760989280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 19:41:20.663+00	926	Sample prompt for testing iteration 706	\N	Sample error message: API_ERROR	error	gemini-pro	google	228	28	572	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1711	trace-711-1760989280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 19:41:20.663+00	1043	Sample prompt for testing iteration 711	Sample response from AI model for iteration 711	\N	success	claude-3-opus	anthropic	284	103	490	0.059039	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1713	trace-713-1760953280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 09:41:20.663+00	1724	Sample prompt for testing iteration 713	Sample response from AI model for iteration 713	\N	success	claude-3-opus	anthropic	547	191	638	0.024596	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1718	trace-718-1760992880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 20:41:20.663+00	728	Sample prompt for testing iteration 718	Sample response from AI model for iteration 718	\N	success	claude-3-opus	anthropic	335	35	518	0.024093	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1723	trace-723-1760974880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 15:41:20.663+00	346	Sample prompt for testing iteration 723	Sample response from AI model for iteration 723	\N	success	claude-3-opus	anthropic	51	41	431	0.051887	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1740	trace-740-1760942480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 06:41:20.663+00	1810	Sample prompt for testing iteration 740	Sample response from AI model for iteration 740	\N	success	mixtral-8x7b	mistral	456	123	444	0.009306	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1768	trace-768-1760956880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 10:41:20.663+00	1107	Sample prompt for testing iteration 768	Sample response from AI model for iteration 768	\N	success	gemini-pro	google	319	43	294	0.013930	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1772	trace-772-1760956880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 10:41:20.663+00	1689	Sample prompt for testing iteration 772	Sample response from AI model for iteration 772	\N	success	mixtral-8x7b	mistral	352	203	224	0.007533	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1777	trace-777-1760946080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 07:41:20.663+00	1265	Sample prompt for testing iteration 777	Sample response from AI model for iteration 777	\N	success	claude-3-opus	anthropic	117	184	279	0.039881	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1787	trace-787-1760938880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 05:41:20.663+00	909	Sample prompt for testing iteration 787	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	542	154	539	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1808	trace-808-1760935280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 04:41:20.663+00	1826	Sample prompt for testing iteration 808	Sample response from AI model for iteration 808	\N	success	gpt-4-turbo	openai	271	191	466	0.054224	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1812	trace-812-1760960480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 11:41:20.663+00	712	Sample prompt for testing iteration 812	\N	Sample error message: API_ERROR	error	gemini-pro	google	530	209	497	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1813	trace-813-1760931680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 03:41:20.663+00	1000	Sample prompt for testing iteration 813	Sample response from AI model for iteration 813	\N	success	mixtral-8x7b	mistral	221	204	623	0.008138	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1814	trace-814-1760992880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 20:41:20.663+00	1904	Sample prompt for testing iteration 814	Sample response from AI model for iteration 814	\N	success	gemini-pro	google	539	25	285	0.019244	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1819	trace-819-1760989280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 19:41:20.663+00	1356	Sample prompt for testing iteration 819	Sample response from AI model for iteration 819	\N	success	claude-3-opus	anthropic	302	62	359	0.051644	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1834	trace-834-1760938880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 05:41:20.663+00	225	Sample prompt for testing iteration 834	\N	Request timeout after 225ms	timeout	claude-3-opus	anthropic	532	52	520	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1861	trace-861-1760974880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 15:41:20.663+00	1881	Sample prompt for testing iteration 861	Sample response from AI model for iteration 861	\N	success	gemini-pro	google	119	208	707	0.011105	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1868	trace-868-1760949680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 08:41:20.663+00	1533	Sample prompt for testing iteration 868	Sample response from AI model for iteration 868	\N	success	mixtral-8x7b	mistral	411	80	72	0.011546	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1878	trace-878-1760985680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 18:41:20.663+00	822	Sample prompt for testing iteration 878	Sample response from AI model for iteration 878	\N	success	mixtral-8x7b	mistral	405	144	213	0.005432	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1883	trace-883-1760931680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 03:41:20.663+00	358	Sample prompt for testing iteration 883	\N	Request timeout after 358ms	timeout	mixtral-8x7b	mistral	117	120	459	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1889	trace-889-1760935280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 04:41:20.663+00	838	Sample prompt for testing iteration 889	Sample response from AI model for iteration 889	\N	success	gemini-pro	google	178	89	474	0.011691	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1908	trace-908-1760924480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 01:41:20.663+00	171	Sample prompt for testing iteration 908	Sample response from AI model for iteration 908	\N	success	claude-3-opus	anthropic	262	26	715	0.021483	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1909	trace-909-1760956880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 10:41:20.663+00	740	Sample prompt for testing iteration 909	\N	Request timeout after 740ms	timeout	gpt-4-turbo	openai	530	197	516	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1913	trace-913-1760992880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 20:41:20.663+00	1517	Sample prompt for testing iteration 913	Sample response from AI model for iteration 913	\N	success	gemini-pro	google	229	204	724	0.024926	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1918	trace-918-1760953280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 09:41:20.663+00	918	Sample prompt for testing iteration 918	\N	Request timeout after 918ms	timeout	gpt-4-turbo	openai	434	167	633	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1920	trace-920-1760964080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 12:41:20.663+00	604	Sample prompt for testing iteration 920	\N	Sample error message: API_ERROR	error	gemini-pro	google	379	209	642	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1921	trace-921-1760967680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 13:41:20.663+00	4709	Sample prompt for testing iteration 921	Sample response from AI model for iteration 921	\N	success	gpt-4-turbo	openai	495	88	463	0.026825	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1926	trace-926-1760971280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 14:41:20.663+00	1691	Sample prompt for testing iteration 926	Sample response from AI model for iteration 926	\N	success	claude-3-opus	anthropic	322	94	289	0.015740	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1930	trace-930-1761000080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 22:41:20.663+00	1315	Sample prompt for testing iteration 930	Sample response from AI model for iteration 930	\N	success	claude-3-opus	anthropic	271	200	540	0.018688	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1940	trace-940-1760953280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 09:41:20.663+00	1539	Sample prompt for testing iteration 940	Sample response from AI model for iteration 940	\N	success	claude-3-opus	anthropic	199	69	390	0.028162	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1953	trace-953-1760964080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 12:41:20.663+00	904	Sample prompt for testing iteration 953	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	459	82	711	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1954	trace-954-1761003680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 23:41:20.663+00	3071	Sample prompt for testing iteration 954	Sample response from AI model for iteration 954	\N	success	mixtral-8x7b	mistral	227	219	638	0.010746	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1956	trace-956-1760928080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 02:41:20.663+00	793	Sample prompt for testing iteration 956	Sample response from AI model for iteration 956	\N	success	mixtral-8x7b	mistral	83	186	574	0.008993	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1959	trace-959-1760931680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-20 03:41:20.663+00	2082	Sample prompt for testing iteration 959	\N	Request timeout after 2082ms	timeout	gemini-pro	google	445	98	479	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1960	trace-960-1760996480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 21:41:20.663+00	3851	Sample prompt for testing iteration 960	Sample response from AI model for iteration 960	\N	success	mixtral-8x7b	mistral	359	87	462	0.010548	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1972	trace-972-1760935280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 04:41:20.663+00	1229	Sample prompt for testing iteration 972	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	245	68	347	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1973	trace-973-1760938880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 05:41:20.663+00	2958	Sample prompt for testing iteration 973	\N	Request timeout after 2958ms	timeout	gemini-pro	google	149	216	621	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1975	trace-975-1760942480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 06:41:20.663+00	1838	Sample prompt for testing iteration 975	Sample response from AI model for iteration 975	\N	success	gemini-pro	google	183	126	684	0.010869	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1976	trace-976-1760989280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-20 19:41:20.663+00	664	Sample prompt for testing iteration 976	\N	Request timeout after 664ms	timeout	gemini-pro	google	288	46	430	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1978	trace-978-1760967680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 13:41:20.663+00	1920	Sample prompt for testing iteration 978	Sample response from AI model for iteration 978	\N	success	gpt-4-turbo	openai	354	82	103	0.011010	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1986	trace-986-1760938880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-20 05:41:20.663+00	1204	Sample prompt for testing iteration 986	Sample response from AI model for iteration 986	\N	success	claude-3-opus	anthropic	339	102	181	0.047442	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1998	trace-998-1760992880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-20 20:41:20.663+00	1843	Sample prompt for testing iteration 998	Sample response from AI model for iteration 998	\N	success	mixtral-8x7b	mistral	251	29	160	0.010932	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
\.


--
-- Data for Name: _hyper_1_7_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_1_7_chunk (id, trace_id, workspace_id, agent_id, "timestamp", latency_ms, input, output, error, status, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, tags, user_id) FROM stdin;
\.


--
-- Data for Name: _hyper_1_8_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_1_8_chunk (id, trace_id, workspace_id, agent_id, "timestamp", latency_ms, input, output, error, status, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, tags, user_id) FROM stdin;
9	trace-9-1761039085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 09:31:25.171576+00	181	Sample prompt for testing iteration 9	Sample response from AI model for iteration 9	\N	success	mixtral-8x7b	mistral	264	121	84	0.011642	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
13	trace-13-1761046285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 11:31:25.171576+00	934	Sample prompt for testing iteration 13	Sample response from AI model for iteration 13	\N	success	gpt-4-turbo	openai	148	218	308	0.053444	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
15	trace-15-1761053485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 13:31:25.171576+00	1477	Sample prompt for testing iteration 15	Sample response from AI model for iteration 15	\N	success	claude-3-opus	anthropic	414	184	509	0.050836	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
21	trace-21-1761060685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 15:31:25.171576+00	1397	Sample prompt for testing iteration 21	Sample response from AI model for iteration 21	\N	success	gemini-pro	google	216	201	502	0.006227	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
22	trace-22-1761089485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 23:31:25.171576+00	193	Sample prompt for testing iteration 22	Sample response from AI model for iteration 22	\N	success	claude-3-opus	anthropic	427	112	340	0.024574	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
26	trace-26-1761089485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 23:31:25.171576+00	729	Sample prompt for testing iteration 26	Sample response from AI model for iteration 26	\N	success	claude-3-opus	anthropic	178	178	174	0.032547	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
27	trace-27-1761039085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 09:31:25.171576+00	1167	Sample prompt for testing iteration 27	Sample response from AI model for iteration 27	\N	success	gpt-4-turbo	openai	539	159	528	0.055828	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
28	trace-28-1761017485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 03:31:25.171576+00	999	Sample prompt for testing iteration 28	\N	Request timeout after 999ms	timeout	claude-3-opus	anthropic	307	158	231	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
34	trace-34-1761013885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 02:31:25.171576+00	1934	Sample prompt for testing iteration 34	Sample response from AI model for iteration 34	\N	success	gemini-pro	google	188	85	108	0.020534	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
38	trace-38-1761010285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 01:31:25.171576+00	430	Sample prompt for testing iteration 38	\N	Request timeout after 430ms	timeout	gemini-pro	google	492	201	737	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
47	trace-47-1761035485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 08:31:25.171576+00	582	Sample prompt for testing iteration 47	Sample response from AI model for iteration 47	\N	success	gpt-4-turbo	openai	83	131	130	0.052263	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
56	trace-56-1761071485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 18:31:25.171576+00	514	Sample prompt for testing iteration 56	Sample response from AI model for iteration 56	\N	success	gpt-4-turbo	openai	498	112	708	0.016866	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
60	trace-60-1761057085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 14:31:25.171576+00	750	Sample prompt for testing iteration 60	Sample response from AI model for iteration 60	\N	success	claude-3-opus	anthropic	106	196	75	0.069736	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
88	trace-88-1761042685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 10:31:25.171576+00	469	Sample prompt for testing iteration 88	Sample response from AI model for iteration 88	\N	success	gemini-pro	google	123	211	621	0.022464	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
90	trace-90-1761035485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 08:31:25.171576+00	610	Sample prompt for testing iteration 90	Sample response from AI model for iteration 90	\N	success	gpt-4-turbo	openai	169	154	313	0.012675	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
93	trace-93-1761049885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 12:31:25.171576+00	688	Sample prompt for testing iteration 93	Sample response from AI model for iteration 93	\N	success	mixtral-8x7b	mistral	139	197	93	0.008977	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
95	trace-95-1761089485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 23:31:25.171576+00	678	Sample prompt for testing iteration 95	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	360	163	442	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
96	trace-96-1761085885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 22:31:25.171576+00	1645	Sample prompt for testing iteration 96	\N	Sample error message: API_ERROR	error	gemini-pro	google	270	42	269	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
99	trace-99-1761046285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 11:31:25.171576+00	1885	Sample prompt for testing iteration 99	Sample response from AI model for iteration 99	\N	success	gpt-4-turbo	openai	134	71	247	0.056251	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
106	trace-106-1761057085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 14:31:25.171576+00	1994	Sample prompt for testing iteration 106	Sample response from AI model for iteration 106	\N	success	mixtral-8x7b	mistral	473	134	564	0.007051	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
107	trace-107-1761024685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 05:31:25.171576+00	1805	Sample prompt for testing iteration 107	Sample response from AI model for iteration 107	\N	success	gpt-4-turbo	openai	146	141	466	0.030788	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
110	trace-110-1761071485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 18:31:25.171576+00	1082	Sample prompt for testing iteration 110	Sample response from AI model for iteration 110	\N	success	claude-3-opus	anthropic	95	162	636	0.039828	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
111	trace-111-1761024685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 05:31:25.171576+00	1412	Sample prompt for testing iteration 111	\N	Sample error message: API_ERROR	error	gemini-pro	google	139	171	666	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
116	trace-116-1761021085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 04:31:25.171576+00	341	Sample prompt for testing iteration 116	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	387	175	530	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
118	trace-118-1761028285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 06:31:25.171576+00	805	Sample prompt for testing iteration 118	Sample response from AI model for iteration 118	\N	success	gpt-4-turbo	openai	520	161	203	0.037975	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
122	trace-122-1761053485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 13:31:25.171576+00	290	Sample prompt for testing iteration 122	Sample response from AI model for iteration 122	\N	success	mixtral-8x7b	mistral	532	154	606	0.003758	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
125	trace-125-1761057085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 14:31:25.171576+00	1021	Sample prompt for testing iteration 125	Sample response from AI model for iteration 125	\N	success	mixtral-8x7b	mistral	367	89	449	0.003676	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
129	trace-129-1761028285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 06:31:25.171576+00	901	Sample prompt for testing iteration 129	Sample response from AI model for iteration 129	\N	success	gemini-pro	google	211	23	83	0.016001	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
132	trace-132-1761010285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 01:31:25.171576+00	274	Sample prompt for testing iteration 132	Sample response from AI model for iteration 132	\N	success	claude-3-opus	anthropic	548	90	706	0.047067	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
134	trace-134-1761039085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 09:31:25.171576+00	1587	Sample prompt for testing iteration 134	Sample response from AI model for iteration 134	\N	success	gemini-pro	google	124	159	648	0.017322	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
145	trace-145-1761046285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 11:31:25.171576+00	494	Sample prompt for testing iteration 145	Sample response from AI model for iteration 145	\N	success	mixtral-8x7b	mistral	414	78	382	0.009794	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
154	trace-154-1761078685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 20:31:25.171576+00	4373	Sample prompt for testing iteration 154	Sample response from AI model for iteration 154	\N	success	mixtral-8x7b	mistral	467	98	524	0.005675	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
162	trace-162-1761031885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 07:31:25.171576+00	3288	Sample prompt for testing iteration 162	Sample response from AI model for iteration 162	\N	success	gpt-4-turbo	openai	262	126	693	0.052838	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
164	trace-164-1761082285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 21:31:25.171576+00	1113	Sample prompt for testing iteration 164	Sample response from AI model for iteration 164	\N	success	claude-3-opus	anthropic	545	164	585	0.047042	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
166	trace-166-1761021085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 04:31:25.171576+00	439	Sample prompt for testing iteration 166	\N	Request timeout after 439ms	timeout	claude-3-opus	anthropic	129	77	521	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
176	trace-176-1761013885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 02:31:25.171576+00	1265	Sample prompt for testing iteration 176	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	319	170	349	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
177	trace-177-1761053485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 13:31:25.171576+00	750	Sample prompt for testing iteration 177	Sample response from AI model for iteration 177	\N	success	gemini-pro	google	183	68	168	0.024991	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
178	trace-178-1761064285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 16:31:25.171576+00	2055	Sample prompt for testing iteration 178	\N	Request timeout after 2055ms	timeout	claude-3-opus	anthropic	351	95	493	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
188	trace-188-1761035485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 08:31:25.171576+00	309	Sample prompt for testing iteration 188	Sample response from AI model for iteration 188	\N	success	mixtral-8x7b	mistral	213	187	518	0.008041	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
193	trace-193-1761053485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 13:31:25.171576+00	1690	Sample prompt for testing iteration 193	Sample response from AI model for iteration 193	\N	success	mixtral-8x7b	mistral	459	206	642	0.011738	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
199	trace-199-1761064285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 16:31:25.171576+00	344	Sample prompt for testing iteration 199	Sample response from AI model for iteration 199	\N	success	claude-3-opus	anthropic	277	94	401	0.065776	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
216	trace-216-1761085885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 22:31:25.171576+00	3352	Sample prompt for testing iteration 216	Sample response from AI model for iteration 216	\N	success	gpt-4-turbo	openai	298	103	81	0.021315	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
220	trace-220-1761049885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 12:31:25.171576+00	747	Sample prompt for testing iteration 220	\N	Request timeout after 747ms	timeout	gpt-4-turbo	openai	117	57	290	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
227	trace-227-1761071485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 18:31:25.171576+00	1229	Sample prompt for testing iteration 227	Sample response from AI model for iteration 227	\N	success	mixtral-8x7b	mistral	53	171	682	0.003793	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
230	trace-230-1761071485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 18:31:25.171576+00	1815	Sample prompt for testing iteration 230	\N	Request timeout after 1815ms	timeout	gpt-4-turbo	openai	220	185	543	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
245	trace-245-1761082285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 21:31:25.171576+00	785	Sample prompt for testing iteration 245	Sample response from AI model for iteration 245	\N	success	mixtral-8x7b	mistral	224	133	749	0.008136	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
247	trace-247-1761021085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 04:31:25.171576+00	3755	Sample prompt for testing iteration 247	\N	Request timeout after 3755ms	timeout	mixtral-8x7b	mistral	391	158	351	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
253	trace-253-1761013885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 02:31:25.171576+00	4362	Sample prompt for testing iteration 253	Sample response from AI model for iteration 253	\N	success	mixtral-8x7b	mistral	112	197	135	0.004883	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
257	trace-257-1761057085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 14:31:25.171576+00	214	Sample prompt for testing iteration 257	Sample response from AI model for iteration 257	\N	success	gpt-4-turbo	openai	534	23	673	0.014391	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
264	trace-264-1761064285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 16:31:25.171576+00	1450	Sample prompt for testing iteration 264	Sample response from AI model for iteration 264	\N	success	claude-3-opus	anthropic	533	108	218	0.043254	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
275	trace-275-1761060685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 15:31:25.171576+00	1372	Sample prompt for testing iteration 275	\N	Request timeout after 1372ms	timeout	claude-3-opus	anthropic	76	203	410	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
295	trace-295-1761024685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 05:31:25.171576+00	1201	Sample prompt for testing iteration 295	Sample response from AI model for iteration 295	\N	success	gemini-pro	google	287	139	356	0.020043	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
303	trace-303-1761039085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 09:31:25.171576+00	491	Sample prompt for testing iteration 303	\N	Request timeout after 491ms	timeout	gpt-4-turbo	openai	75	105	766	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
305	trace-305-1761053485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 13:31:25.171576+00	1155	Sample prompt for testing iteration 305	Sample response from AI model for iteration 305	\N	success	gpt-4-turbo	openai	287	189	306	0.024571	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
316	trace-316-1761031885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 07:31:25.171576+00	223	Sample prompt for testing iteration 316	Sample response from AI model for iteration 316	\N	success	gemini-pro	google	439	87	316	0.023104	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
320	trace-320-1761028285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 06:31:25.171576+00	3471	Sample prompt for testing iteration 320	Sample response from AI model for iteration 320	\N	success	claude-3-opus	anthropic	124	196	248	0.019834	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
323	trace-323-1761053485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 13:31:25.171576+00	1943	Sample prompt for testing iteration 323	\N	Request timeout after 1943ms	timeout	mixtral-8x7b	mistral	297	129	583	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
338	trace-338-1761010285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 01:31:25.171576+00	1502	Sample prompt for testing iteration 338	\N	Request timeout after 1502ms	timeout	mixtral-8x7b	mistral	218	138	573	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
339	trace-339-1761013885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 02:31:25.171576+00	1839	Sample prompt for testing iteration 339	Sample response from AI model for iteration 339	\N	success	mixtral-8x7b	mistral	307	214	707	0.009259	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
340	trace-340-1761060685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 15:31:25.171576+00	1036	Sample prompt for testing iteration 340	\N	Request timeout after 1036ms	timeout	gpt-4-turbo	openai	549	27	602	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
348	trace-348-1761028285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 06:31:25.171576+00	1495	Sample prompt for testing iteration 348	Sample response from AI model for iteration 348	\N	success	mixtral-8x7b	mistral	537	133	248	0.004586	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
349	trace-349-1761024685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 05:31:25.171576+00	1018	Sample prompt for testing iteration 349	Sample response from AI model for iteration 349	\N	success	mixtral-8x7b	mistral	202	133	686	0.004292	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
353	trace-353-1761031885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 07:31:25.171576+00	4721	Sample prompt for testing iteration 353	Sample response from AI model for iteration 353	\N	success	mixtral-8x7b	mistral	359	150	306	0.007193	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
363	trace-363-1761049885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 12:31:25.171576+00	1443	Sample prompt for testing iteration 363	Sample response from AI model for iteration 363	\N	success	gemini-pro	google	279	183	752	0.015605	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
367	trace-367-1761060685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 15:31:25.171576+00	222	Sample prompt for testing iteration 367	Sample response from AI model for iteration 367	\N	success	gemini-pro	google	301	160	264	0.005190	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
369	trace-369-1761006685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 00:31:25.171576+00	1230	Sample prompt for testing iteration 369	\N	Sample error message: API_ERROR	error	gemini-pro	google	87	36	716	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
370	trace-370-1761049885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 12:31:25.171576+00	1573	Sample prompt for testing iteration 370	Sample response from AI model for iteration 370	\N	success	gpt-4-turbo	openai	199	79	602	0.052952	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
372	trace-372-1761021085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 04:31:25.171576+00	1281	Sample prompt for testing iteration 372	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	62	186	393	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
376	trace-376-1761057085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 14:31:25.171576+00	3591	Sample prompt for testing iteration 376	Sample response from AI model for iteration 376	\N	success	gemini-pro	google	180	167	76	0.011552	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
380	trace-380-1761071485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 18:31:25.171576+00	1968	Sample prompt for testing iteration 380	Sample response from AI model for iteration 380	\N	success	claude-3-opus	anthropic	384	107	140	0.065620	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
388	trace-388-1761024685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 05:31:25.171576+00	106	Sample prompt for testing iteration 388	Sample response from AI model for iteration 388	\N	success	claude-3-opus	anthropic	429	194	660	0.064628	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
393	trace-393-1761042685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 10:31:25.171576+00	2375	Sample prompt for testing iteration 393	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	349	156	679	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
412	trace-412-1761053485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 13:31:25.171576+00	1336	Sample prompt for testing iteration 412	Sample response from AI model for iteration 412	\N	success	gemini-pro	google	184	186	611	0.013094	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
413	trace-413-1761085885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 22:31:25.171576+00	1006	Sample prompt for testing iteration 413	Sample response from AI model for iteration 413	\N	success	gpt-4-turbo	openai	290	30	693	0.041680	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
419	trace-419-1761057085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 14:31:25.171576+00	1768	Sample prompt for testing iteration 419	Sample response from AI model for iteration 419	\N	success	mixtral-8x7b	mistral	409	81	693	0.010188	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
423	trace-423-1761010285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 01:31:25.171576+00	736	Sample prompt for testing iteration 423	\N	Sample error message: API_ERROR	error	gemini-pro	google	262	56	686	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
439	trace-439-1761057085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 14:31:25.171576+00	942	Sample prompt for testing iteration 439	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	261	63	328	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
440	trace-440-1761010285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 01:31:25.171576+00	1881	Sample prompt for testing iteration 440	\N	Request timeout after 1881ms	timeout	claude-3-opus	anthropic	221	171	742	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
445	trace-445-1761035485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 08:31:25.171576+00	1928	Sample prompt for testing iteration 445	Sample response from AI model for iteration 445	\N	success	claude-3-opus	anthropic	80	84	98	0.065611	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
446	trace-446-1761071485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 18:31:25.171576+00	442	Sample prompt for testing iteration 446	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	510	157	739	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
462	trace-462-1761017485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 03:31:25.171576+00	1355	Sample prompt for testing iteration 462	Sample response from AI model for iteration 462	\N	success	gemini-pro	google	444	59	89	0.019617	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
473	trace-473-1761031885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 07:31:25.171576+00	1796	Sample prompt for testing iteration 473	Sample response from AI model for iteration 473	\N	success	claude-3-opus	anthropic	529	114	635	0.038781	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
480	trace-480-1761053485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 13:31:25.171576+00	515	Sample prompt for testing iteration 480	Sample response from AI model for iteration 480	\N	success	mixtral-8x7b	mistral	448	102	261	0.006621	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
493	trace-493-1761064285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 16:31:25.171576+00	546	Sample prompt for testing iteration 493	Sample response from AI model for iteration 493	\N	success	claude-3-opus	anthropic	472	157	660	0.069980	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
497	trace-497-1761013885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 02:31:25.171576+00	403	Sample prompt for testing iteration 497	Sample response from AI model for iteration 497	\N	success	gemini-pro	google	129	65	247	0.024281	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
501	trace-501-1761082285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 21:31:25.171576+00	1070	Sample prompt for testing iteration 501	Sample response from AI model for iteration 501	\N	success	claude-3-opus	anthropic	173	75	102	0.032800	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
513	trace-513-1761060685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 15:31:25.171576+00	1676	Sample prompt for testing iteration 513	Sample response from AI model for iteration 513	\N	success	mixtral-8x7b	mistral	308	47	83	0.007332	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
514	trace-514-1761075085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 19:31:25.171576+00	873	Sample prompt for testing iteration 514	\N	Sample error message: API_ERROR	error	gemini-pro	google	445	109	307	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
517	trace-517-1761067885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 17:31:25.171576+00	1772	Sample prompt for testing iteration 517	\N	Request timeout after 1772ms	timeout	mixtral-8x7b	mistral	516	182	761	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
520	trace-520-1761042685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 10:31:25.171576+00	536	Sample prompt for testing iteration 520	\N	Request timeout after 536ms	timeout	claude-3-opus	anthropic	314	104	237	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
521	trace-521-1761046285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 11:31:25.171576+00	3141	Sample prompt for testing iteration 521	Sample response from AI model for iteration 521	\N	success	gemini-pro	google	114	192	714	0.016658	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
523	trace-523-1761024685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 05:31:25.171576+00	2079	Sample prompt for testing iteration 523	Sample response from AI model for iteration 523	\N	success	gpt-4-turbo	openai	285	75	597	0.014983	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
528	trace-528-1761078685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 20:31:25.171576+00	567	Sample prompt for testing iteration 528	Sample response from AI model for iteration 528	\N	success	claude-3-opus	anthropic	457	92	98	0.073564	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
530	trace-530-1761057085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 14:31:25.171576+00	4339	Sample prompt for testing iteration 530	Sample response from AI model for iteration 530	\N	success	gemini-pro	google	382	22	521	0.024482	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
537	trace-537-1761064285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 16:31:25.171576+00	1326	Sample prompt for testing iteration 537	Sample response from AI model for iteration 537	\N	success	gemini-pro	google	224	181	723	0.005344	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
538	trace-538-1761042685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 10:31:25.171576+00	553	Sample prompt for testing iteration 538	Sample response from AI model for iteration 538	\N	success	gpt-4-turbo	openai	92	120	316	0.018683	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
539	trace-539-1761013885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 02:31:25.171576+00	1281	Sample prompt for testing iteration 539	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	259	45	74	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
541	trace-541-1761039085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 09:31:25.171576+00	589	Sample prompt for testing iteration 541	Sample response from AI model for iteration 541	\N	success	gpt-4-turbo	openai	83	152	552	0.030976	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
547	trace-547-1761078685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 20:31:25.171576+00	1991	Sample prompt for testing iteration 547	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	345	146	344	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
548	trace-548-1761024685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 05:31:25.171576+00	1089	Sample prompt for testing iteration 548	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	161	90	510	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
557	trace-557-1761089485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 23:31:25.171576+00	1150	Sample prompt for testing iteration 557	Sample response from AI model for iteration 557	\N	success	claude-3-opus	anthropic	451	87	321	0.034003	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
558	trace-558-1761017485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 03:31:25.171576+00	1084	Sample prompt for testing iteration 558	Sample response from AI model for iteration 558	\N	success	gemini-pro	google	315	182	498	0.015303	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
563	trace-563-1761042685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 10:31:25.171576+00	887	Sample prompt for testing iteration 563	Sample response from AI model for iteration 563	\N	success	claude-3-opus	anthropic	195	125	615	0.063741	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
597	trace-597-1761028285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 06:31:25.171576+00	743	Sample prompt for testing iteration 597	Sample response from AI model for iteration 597	\N	success	gemini-pro	google	94	165	370	0.009702	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
598	trace-598-1761075085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 19:31:25.171576+00	2292	Sample prompt for testing iteration 598	Sample response from AI model for iteration 598	\N	success	mixtral-8x7b	mistral	291	25	428	0.005785	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
607	trace-607-1761071485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 18:31:25.171576+00	1518	Sample prompt for testing iteration 607	\N	Request timeout after 1518ms	timeout	gpt-4-turbo	openai	143	127	292	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
611	trace-611-1761082285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 21:31:25.171576+00	1500	Sample prompt for testing iteration 611	Sample response from AI model for iteration 611	\N	success	gemini-pro	google	75	36	489	0.014148	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
615	trace-615-1761075085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 19:31:25.171576+00	872	Sample prompt for testing iteration 615	Sample response from AI model for iteration 615	\N	success	gpt-4-turbo	openai	158	138	598	0.050023	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
617	trace-617-1761046285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 11:31:25.171576+00	1042	Sample prompt for testing iteration 617	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	275	130	264	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
625	trace-625-1761067885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 17:31:25.171576+00	1574	Sample prompt for testing iteration 625	Sample response from AI model for iteration 625	\N	success	mixtral-8x7b	mistral	127	66	707	0.008324	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
628	trace-628-1761085885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 22:31:25.171576+00	452	Sample prompt for testing iteration 628	Sample response from AI model for iteration 628	\N	success	gpt-4-turbo	openai	99	146	484	0.051990	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
635	trace-635-1761089485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 23:31:25.171576+00	1038	Sample prompt for testing iteration 635	\N	Request timeout after 1038ms	timeout	mixtral-8x7b	mistral	527	166	152	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
645	trace-645-1761071485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 18:31:25.171576+00	1319	Sample prompt for testing iteration 645	\N	Sample error message: API_ERROR	error	gemini-pro	google	485	160	182	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
658	trace-658-1761006685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 00:31:25.171576+00	332	Sample prompt for testing iteration 658	\N	Request timeout after 332ms	timeout	mixtral-8x7b	mistral	113	169	724	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
662	trace-662-1761075085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 19:31:25.171576+00	3796	Sample prompt for testing iteration 662	\N	Request timeout after 3796ms	timeout	gemini-pro	google	80	77	751	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
670	trace-670-1761006685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 00:31:25.171576+00	676	Sample prompt for testing iteration 670	Sample response from AI model for iteration 670	\N	success	claude-3-opus	anthropic	455	162	249	0.030508	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
671	trace-671-1761082285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 21:31:25.171576+00	3105	Sample prompt for testing iteration 671	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	130	105	742	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
672	trace-672-1761075085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 19:31:25.171576+00	961	Sample prompt for testing iteration 672	Sample response from AI model for iteration 672	\N	success	claude-3-opus	anthropic	464	63	649	0.052048	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
685	trace-685-1761085885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 22:31:25.171576+00	1379	Sample prompt for testing iteration 685	Sample response from AI model for iteration 685	\N	success	mixtral-8x7b	mistral	145	160	93	0.007299	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
692	trace-692-1761057085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 14:31:25.171576+00	1889	Sample prompt for testing iteration 692	Sample response from AI model for iteration 692	\N	success	mixtral-8x7b	mistral	248	87	677	0.003634	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
694	trace-694-1761039085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 09:31:25.171576+00	663	Sample prompt for testing iteration 694	Sample response from AI model for iteration 694	\N	success	mixtral-8x7b	mistral	505	25	484	0.008054	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
695	trace-695-1761039085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 09:31:25.171576+00	1101	Sample prompt for testing iteration 695	Sample response from AI model for iteration 695	\N	success	gemini-pro	google	157	118	635	0.005889	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
697	trace-697-1761049885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 12:31:25.171576+00	1413	Sample prompt for testing iteration 697	Sample response from AI model for iteration 697	\N	success	mixtral-8x7b	mistral	89	23	268	0.007568	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
699	trace-699-1761082285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 21:31:25.171576+00	1762	Sample prompt for testing iteration 699	Sample response from AI model for iteration 699	\N	success	mixtral-8x7b	mistral	328	94	243	0.008814	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
711	trace-711-1761057085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 14:31:25.171576+00	705	Sample prompt for testing iteration 711	Sample response from AI model for iteration 711	\N	success	gemini-pro	google	329	150	330	0.020377	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
713	trace-713-1761039085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 09:31:25.171576+00	1019	Sample prompt for testing iteration 713	\N	Request timeout after 1019ms	timeout	claude-3-opus	anthropic	238	156	620	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
715	trace-715-1761053485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 13:31:25.171576+00	1824	Sample prompt for testing iteration 715	Sample response from AI model for iteration 715	\N	success	gpt-4-turbo	openai	448	199	697	0.049997	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
717	trace-717-1761046285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 11:31:25.171576+00	1327	Sample prompt for testing iteration 717	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	337	118	205	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
718	trace-718-1761031885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 07:31:25.171576+00	1453	Sample prompt for testing iteration 718	Sample response from AI model for iteration 718	\N	success	gpt-4-turbo	openai	79	95	307	0.031233	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
729	trace-729-1761082285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 21:31:25.171576+00	441	Sample prompt for testing iteration 729	\N	Request timeout after 441ms	timeout	mixtral-8x7b	mistral	515	207	411	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
734	trace-734-1761024685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 05:31:25.171576+00	2855	Sample prompt for testing iteration 734	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	453	23	422	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
739	trace-739-1761053485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 13:31:25.171576+00	979	Sample prompt for testing iteration 739	Sample response from AI model for iteration 739	\N	success	claude-3-opus	anthropic	288	117	347	0.019237	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
747	trace-747-1761031885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 07:31:25.171576+00	1838	Sample prompt for testing iteration 747	Sample response from AI model for iteration 747	\N	success	gpt-4-turbo	openai	199	156	644	0.034409	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
749	trace-749-1761075085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 19:31:25.171576+00	585	Sample prompt for testing iteration 749	Sample response from AI model for iteration 749	\N	success	claude-3-opus	anthropic	255	184	463	0.033479	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
750	trace-750-1761024685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 05:31:25.171576+00	281	Sample prompt for testing iteration 750	Sample response from AI model for iteration 750	\N	success	mixtral-8x7b	mistral	270	155	580	0.012917	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
758	trace-758-1761028285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 06:31:25.171576+00	817	Sample prompt for testing iteration 758	Sample response from AI model for iteration 758	\N	success	gpt-4-turbo	openai	518	102	290	0.051638	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
761	trace-761-1761082285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 21:31:25.171576+00	1462	Sample prompt for testing iteration 761	Sample response from AI model for iteration 761	\N	success	claude-3-opus	anthropic	99	106	271	0.024664	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
771	trace-771-1761078685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 20:31:25.171576+00	604	Sample prompt for testing iteration 771	Sample response from AI model for iteration 771	\N	success	gpt-4-turbo	openai	96	121	649	0.023773	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
772	trace-772-1761017485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 03:31:25.171576+00	285	Sample prompt for testing iteration 772	Sample response from AI model for iteration 772	\N	success	gemini-pro	google	269	151	697	0.024991	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
780	trace-780-1761075085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 19:31:25.171576+00	1253	Sample prompt for testing iteration 780	Sample response from AI model for iteration 780	\N	success	gemini-pro	google	218	170	423	0.015102	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
788	trace-788-1761078685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 20:31:25.171576+00	3834	Sample prompt for testing iteration 788	Sample response from AI model for iteration 788	\N	success	claude-3-opus	anthropic	478	157	280	0.029115	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
789	trace-789-1761042685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 10:31:25.171576+00	1624	Sample prompt for testing iteration 789	Sample response from AI model for iteration 789	\N	success	gpt-4-turbo	openai	162	56	548	0.014802	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
794	trace-794-1761021085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 04:31:25.171576+00	1092	Sample prompt for testing iteration 794	Sample response from AI model for iteration 794	\N	success	claude-3-opus	anthropic	162	181	217	0.040894	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
800	trace-800-1761071485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 18:31:25.171576+00	398	Sample prompt for testing iteration 800	Sample response from AI model for iteration 800	\N	success	claude-3-opus	anthropic	55	130	642	0.046057	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
813	trace-813-1761089485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 23:31:25.171576+00	371	Sample prompt for testing iteration 813	Sample response from AI model for iteration 813	\N	success	gemini-pro	google	369	36	659	0.008587	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
824	trace-824-1761085885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 22:31:25.171576+00	1606	Sample prompt for testing iteration 824	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	396	22	559	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
833	trace-833-1761057085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 14:31:25.171576+00	1276	Sample prompt for testing iteration 833	\N	Request timeout after 1276ms	timeout	mixtral-8x7b	mistral	547	181	185	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
852	trace-852-1761085885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 22:31:25.171576+00	1526	Sample prompt for testing iteration 852	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	529	158	568	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
877	trace-877-1761078685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 20:31:25.171576+00	650	Sample prompt for testing iteration 877	Sample response from AI model for iteration 877	\N	success	gemini-pro	google	284	165	408	0.006396	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
882	trace-882-1761024685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 05:31:25.171576+00	2038	Sample prompt for testing iteration 882	Sample response from AI model for iteration 882	\N	success	gemini-pro	google	71	113	484	0.022282	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
891	trace-891-1761042685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 10:31:25.171576+00	187	Sample prompt for testing iteration 891	\N	Request timeout after 187ms	timeout	gpt-4-turbo	openai	202	147	426	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
892	trace-892-1761082285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 21:31:25.171576+00	665	Sample prompt for testing iteration 892	Sample response from AI model for iteration 892	\N	success	gemini-pro	google	524	49	253	0.018974	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
894	trace-894-1761085885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 22:31:25.171576+00	1559	Sample prompt for testing iteration 894	Sample response from AI model for iteration 894	\N	success	mixtral-8x7b	mistral	274	47	359	0.007494	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
901	trace-901-1761042685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 10:31:25.171576+00	363	Sample prompt for testing iteration 901	Sample response from AI model for iteration 901	\N	success	gemini-pro	google	392	148	531	0.011951	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
910	trace-910-1761078685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 20:31:25.171576+00	662	Sample prompt for testing iteration 910	Sample response from AI model for iteration 910	\N	success	claude-3-opus	anthropic	347	47	448	0.040444	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
911	trace-911-1761013885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 02:31:25.171576+00	1476	Sample prompt for testing iteration 911	\N	Sample error message: API_ERROR	error	gemini-pro	google	130	29	677	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
917	trace-917-1761060685.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 15:31:25.171576+00	221	Sample prompt for testing iteration 917	\N	Sample error message: API_ERROR	error	gemini-pro	google	325	28	538	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
924	trace-924-1761035485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 08:31:25.171576+00	1836	Sample prompt for testing iteration 924	Sample response from AI model for iteration 924	\N	success	claude-3-opus	anthropic	289	188	502	0.039093	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
938	trace-938-1761039085.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 09:31:25.171576+00	328	Sample prompt for testing iteration 938	Sample response from AI model for iteration 938	\N	success	claude-3-opus	anthropic	144	23	148	0.018024	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
959	trace-959-1761031885.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 07:31:25.171576+00	217	Sample prompt for testing iteration 959	Sample response from AI model for iteration 959	\N	success	gemini-pro	google	410	215	133	0.009403	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
964	trace-964-1761046285.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 11:31:25.171576+00	2075	Sample prompt for testing iteration 964	Sample response from AI model for iteration 964	\N	success	claude-3-opus	anthropic	352	213	159	0.040248	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
987	trace-987-1761035485.171576	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 08:31:25.171576+00	740	Sample prompt for testing iteration 987	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	252	51	108	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1003	trace-3-1761046880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 11:41:20.663+00	1801	Sample prompt for testing iteration 3	\N	Request timeout after 1801ms	timeout	gpt-4-turbo	openai	307	31	658	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1022	trace-22-1761054080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 13:41:20.663+00	1690	Sample prompt for testing iteration 22	\N	Sample error message: API_ERROR	error	gemini-pro	google	400	108	222	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1041	trace-41-1761050480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 12:41:20.663+00	2481	Sample prompt for testing iteration 41	Sample response from AI model for iteration 41	\N	success	claude-3-opus	anthropic	543	154	344	0.035765	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1043	trace-43-1761036080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 08:41:20.663+00	1087	Sample prompt for testing iteration 43	Sample response from AI model for iteration 43	\N	success	gpt-4-turbo	openai	339	209	331	0.014626	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1054	trace-54-1761079280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 20:41:20.663+00	109	Sample prompt for testing iteration 54	Sample response from AI model for iteration 54	\N	success	gpt-4-turbo	openai	223	142	559	0.044718	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1059	trace-59-1761082880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 21:41:20.663+00	1731	Sample prompt for testing iteration 59	Sample response from AI model for iteration 59	\N	success	mixtral-8x7b	mistral	311	181	587	0.010954	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1063	trace-63-1761018080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 03:41:20.663+00	2018	Sample prompt for testing iteration 63	Sample response from AI model for iteration 63	\N	success	claude-3-opus	anthropic	331	101	696	0.062461	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1064	trace-64-1761082880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 21:41:20.663+00	1029	Sample prompt for testing iteration 64	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	504	181	603	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1066	trace-66-1761072080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 18:41:20.663+00	571	Sample prompt for testing iteration 66	Sample response from AI model for iteration 66	\N	success	gemini-pro	google	276	216	584	0.009029	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1068	trace-68-1761014480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 02:41:20.663+00	1592	Sample prompt for testing iteration 68	Sample response from AI model for iteration 68	\N	success	claude-3-opus	anthropic	436	167	247	0.063398	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1069	trace-69-1761028880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 06:41:20.663+00	1782	Sample prompt for testing iteration 69	Sample response from AI model for iteration 69	\N	success	claude-3-opus	anthropic	269	106	585	0.065621	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1070	trace-70-1761046880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 11:41:20.663+00	781	Sample prompt for testing iteration 70	\N	Request timeout after 781ms	timeout	mixtral-8x7b	mistral	170	183	715	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1072	trace-72-1761061280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 15:41:20.663+00	1845	Sample prompt for testing iteration 72	Sample response from AI model for iteration 72	\N	success	mixtral-8x7b	mistral	437	149	261	0.012133	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1078	trace-78-1761018080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 03:41:20.663+00	1122	Sample prompt for testing iteration 78	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	238	60	152	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1086	trace-86-1761050480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 12:41:20.663+00	1246	Sample prompt for testing iteration 86	Sample response from AI model for iteration 86	\N	success	claude-3-opus	anthropic	416	130	287	0.043658	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1108	trace-108-1761014480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 02:41:20.663+00	173	Sample prompt for testing iteration 108	Sample response from AI model for iteration 108	\N	success	gemini-pro	google	514	162	644	0.015307	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1118	trace-118-1761050480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 12:41:20.663+00	1081	Sample prompt for testing iteration 118	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	539	159	669	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1121	trace-121-1761043280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 10:41:20.663+00	1447	Sample prompt for testing iteration 121	Sample response from AI model for iteration 121	\N	success	gpt-4-turbo	openai	185	97	599	0.027617	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1133	trace-133-1761068480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 17:41:20.663+00	1698	Sample prompt for testing iteration 133	Sample response from AI model for iteration 133	\N	success	gpt-4-turbo	openai	341	217	260	0.022622	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1134	trace-134-1761050480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 12:41:20.663+00	516	Sample prompt for testing iteration 134	Sample response from AI model for iteration 134	\N	success	mixtral-8x7b	mistral	460	86	471	0.012015	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1148	trace-148-1761090080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 23:41:20.663+00	485	Sample prompt for testing iteration 148	\N	Sample error message: API_ERROR	error	gemini-pro	google	339	65	273	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1150	trace-150-1761068480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 17:41:20.663+00	358	Sample prompt for testing iteration 150	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	309	26	296	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1159	trace-159-1761086480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 22:41:20.663+00	995	Sample prompt for testing iteration 159	Sample response from AI model for iteration 159	\N	success	gpt-4-turbo	openai	549	217	80	0.013711	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1162	trace-162-1761075680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 19:41:20.663+00	2047	Sample prompt for testing iteration 162	Sample response from AI model for iteration 162	\N	success	claude-3-opus	anthropic	252	185	291	0.033997	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1175	trace-175-1761064880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 16:41:20.663+00	1690	Sample prompt for testing iteration 175	Sample response from AI model for iteration 175	\N	success	mixtral-8x7b	mistral	490	126	382	0.012570	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1184	trace-184-1761039680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 09:41:20.663+00	3774	Sample prompt for testing iteration 184	Sample response from AI model for iteration 184	\N	success	claude-3-opus	anthropic	202	105	124	0.066601	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1193	trace-193-1761010880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 01:41:20.663+00	4657	Sample prompt for testing iteration 193	Sample response from AI model for iteration 193	\N	success	gpt-4-turbo	openai	434	196	455	0.024920	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1196	trace-196-1761032480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 07:41:20.663+00	787	Sample prompt for testing iteration 196	Sample response from AI model for iteration 196	\N	success	gpt-4-turbo	openai	85	104	157	0.022602	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1202	trace-202-1761007280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 00:41:20.663+00	1586	Sample prompt for testing iteration 202	Sample response from AI model for iteration 202	\N	success	claude-3-opus	anthropic	171	124	179	0.058240	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1203	trace-203-1761032480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 07:41:20.663+00	1623	Sample prompt for testing iteration 203	\N	Sample error message: API_ERROR	error	gemini-pro	google	261	23	707	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1205	trace-205-1761032480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 07:41:20.663+00	1701	Sample prompt for testing iteration 205	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	391	124	354	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1212	trace-212-1761090080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 23:41:20.663+00	1267	Sample prompt for testing iteration 212	Sample response from AI model for iteration 212	\N	success	mixtral-8x7b	mistral	243	111	350	0.012983	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1218	trace-218-1761057680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 14:41:20.663+00	254	Sample prompt for testing iteration 218	Sample response from AI model for iteration 218	\N	success	gemini-pro	google	438	215	559	0.006611	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1221	trace-221-1761086480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 22:41:20.663+00	1102	Sample prompt for testing iteration 221	Sample response from AI model for iteration 221	\N	success	gpt-4-turbo	openai	423	95	149	0.026761	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1234	trace-234-1761018080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 03:41:20.663+00	974	Sample prompt for testing iteration 234	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	81	149	553	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1243	trace-243-1761061280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 15:41:20.663+00	1145	Sample prompt for testing iteration 243	Sample response from AI model for iteration 243	\N	success	gpt-4-turbo	openai	397	88	437	0.031626	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1247	trace-247-1761079280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 20:41:20.663+00	432	Sample prompt for testing iteration 247	\N	Sample error message: API_ERROR	error	gemini-pro	google	541	210	88	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1256	trace-256-1761068480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 17:41:20.663+00	239	Sample prompt for testing iteration 256	Sample response from AI model for iteration 256	\N	success	gpt-4-turbo	openai	404	210	445	0.013672	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1259	trace-259-1761025280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 05:41:20.663+00	1249	Sample prompt for testing iteration 259	Sample response from AI model for iteration 259	\N	success	gpt-4-turbo	openai	159	158	82	0.018954	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1260	trace-260-1761086480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 22:41:20.663+00	928	Sample prompt for testing iteration 260	Sample response from AI model for iteration 260	\N	success	gemini-pro	google	524	201	746	0.005693	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1262	trace-262-1761014480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 02:41:20.663+00	1363	Sample prompt for testing iteration 262	Sample response from AI model for iteration 262	\N	success	mixtral-8x7b	mistral	414	102	162	0.009570	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1264	trace-264-1761014480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 02:41:20.663+00	3664	Sample prompt for testing iteration 264	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	397	39	436	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1269	trace-269-1761072080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 18:41:20.663+00	153	Sample prompt for testing iteration 269	\N	Request timeout after 153ms	timeout	gpt-4-turbo	openai	393	38	512	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1274	trace-274-1761025280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 05:41:20.663+00	529	Sample prompt for testing iteration 274	Sample response from AI model for iteration 274	\N	success	claude-3-opus	anthropic	194	113	141	0.066851	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1305	trace-305-1761061280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 15:41:20.663+00	1474	Sample prompt for testing iteration 305	Sample response from AI model for iteration 305	\N	success	gpt-4-turbo	openai	256	135	569	0.050662	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1319	trace-319-1761021680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 04:41:20.663+00	1877	Sample prompt for testing iteration 319	Sample response from AI model for iteration 319	\N	success	mixtral-8x7b	mistral	170	216	266	0.011146	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1321	trace-321-1761025280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 05:41:20.663+00	727	Sample prompt for testing iteration 321	Sample response from AI model for iteration 321	\N	success	mixtral-8x7b	mistral	276	196	248	0.007273	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1322	trace-322-1761032480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 07:41:20.663+00	1247	Sample prompt for testing iteration 322	Sample response from AI model for iteration 322	\N	success	mixtral-8x7b	mistral	518	161	75	0.004704	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1323	trace-323-1761021680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 04:41:20.663+00	4546	Sample prompt for testing iteration 323	Sample response from AI model for iteration 323	\N	success	claude-3-opus	anthropic	286	40	204	0.038783	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1332	trace-332-1761057680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 14:41:20.663+00	1319	Sample prompt for testing iteration 332	\N	Request timeout after 1319ms	timeout	claude-3-opus	anthropic	513	26	337	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1338	trace-338-1761010880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 01:41:20.663+00	1458	Sample prompt for testing iteration 338	Sample response from AI model for iteration 338	\N	success	mixtral-8x7b	mistral	418	67	552	0.009420	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1359	trace-359-1761036080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 08:41:20.663+00	1249	Sample prompt for testing iteration 359	Sample response from AI model for iteration 359	\N	success	mixtral-8x7b	mistral	324	75	553	0.007109	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1369	trace-369-1761057680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 14:41:20.663+00	1945	Sample prompt for testing iteration 369	Sample response from AI model for iteration 369	\N	success	claude-3-opus	anthropic	366	110	409	0.040072	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1375	trace-375-1761090080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 23:41:20.663+00	1853	Sample prompt for testing iteration 375	Sample response from AI model for iteration 375	\N	success	gpt-4-turbo	openai	534	134	372	0.048737	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1382	trace-382-1761061280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 15:41:20.663+00	1041	Sample prompt for testing iteration 382	Sample response from AI model for iteration 382	\N	success	gemini-pro	google	97	205	749	0.024903	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1392	trace-392-1761050480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 12:41:20.663+00	570	Sample prompt for testing iteration 392	Sample response from AI model for iteration 392	\N	success	mixtral-8x7b	mistral	337	134	500	0.006504	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1419	trace-419-1761054080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 13:41:20.663+00	241	Sample prompt for testing iteration 419	Sample response from AI model for iteration 419	\N	success	gpt-4-turbo	openai	320	99	149	0.048408	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1420	trace-420-1761064880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 16:41:20.663+00	3375	Sample prompt for testing iteration 420	\N	Sample error message: API_ERROR	error	gemini-pro	google	156	188	331	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1430	trace-430-1761050480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 12:41:20.663+00	272	Sample prompt for testing iteration 430	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	295	144	547	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1443	trace-443-1761068480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 17:41:20.663+00	3698	Sample prompt for testing iteration 443	\N	Request timeout after 3698ms	timeout	claude-3-opus	anthropic	350	132	551	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1459	trace-459-1761057680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 14:41:20.663+00	2079	Sample prompt for testing iteration 459	Sample response from AI model for iteration 459	\N	success	mixtral-8x7b	mistral	282	98	195	0.007235	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1460	trace-460-1761075680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 19:41:20.663+00	777	Sample prompt for testing iteration 460	\N	Request timeout after 777ms	timeout	mixtral-8x7b	mistral	492	71	408	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1464	trace-464-1761010880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 01:41:20.663+00	798	Sample prompt for testing iteration 464	Sample response from AI model for iteration 464	\N	success	mixtral-8x7b	mistral	375	215	94	0.006553	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1466	trace-466-1761075680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 19:41:20.663+00	303	Sample prompt for testing iteration 466	Sample response from AI model for iteration 466	\N	success	claude-3-opus	anthropic	260	151	725	0.055661	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1470	trace-470-1761057680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 14:41:20.663+00	130	Sample prompt for testing iteration 470	\N	Request timeout after 130ms	timeout	mixtral-8x7b	mistral	419	172	149	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1478	trace-478-1761061280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 15:41:20.663+00	3411	Sample prompt for testing iteration 478	Sample response from AI model for iteration 478	\N	success	gemini-pro	google	367	121	151	0.011693	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1484	trace-484-1761086480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 22:41:20.663+00	1181	Sample prompt for testing iteration 484	Sample response from AI model for iteration 484	\N	success	gemini-pro	google	511	118	486	0.013277	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1485	trace-485-1761068480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 17:41:20.663+00	579	Sample prompt for testing iteration 485	Sample response from AI model for iteration 485	\N	success	claude-3-opus	anthropic	374	153	104	0.045244	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1493	trace-493-1761043280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 10:41:20.663+00	1378	Sample prompt for testing iteration 493	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	336	118	132	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1496	trace-496-1761061280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 15:41:20.663+00	1403	Sample prompt for testing iteration 496	Sample response from AI model for iteration 496	\N	success	mixtral-8x7b	mistral	185	212	411	0.007044	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1504	trace-504-1761046880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 11:41:20.663+00	2041	Sample prompt for testing iteration 504	Sample response from AI model for iteration 504	\N	success	claude-3-opus	anthropic	393	102	525	0.033776	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1512	trace-512-1761061280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 15:41:20.663+00	217	Sample prompt for testing iteration 512	Sample response from AI model for iteration 512	\N	success	gpt-4-turbo	openai	416	174	454	0.026235	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1517	trace-517-1761082880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 21:41:20.663+00	178	Sample prompt for testing iteration 517	Sample response from AI model for iteration 517	\N	success	gemini-pro	google	155	165	358	0.009841	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1526	trace-526-1761007280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 00:41:20.663+00	2552	Sample prompt for testing iteration 526	Sample response from AI model for iteration 526	\N	success	gemini-pro	google	520	41	234	0.010871	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1529	trace-529-1761079280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 20:41:20.663+00	259	Sample prompt for testing iteration 529	Sample response from AI model for iteration 529	\N	success	gpt-4-turbo	openai	76	109	604	0.025743	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1532	trace-532-1761032480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 07:41:20.663+00	617	Sample prompt for testing iteration 532	Sample response from AI model for iteration 532	\N	success	claude-3-opus	anthropic	544	50	137	0.027706	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1535	trace-535-1761068480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 17:41:20.663+00	4481	Sample prompt for testing iteration 535	Sample response from AI model for iteration 535	\N	success	claude-3-opus	anthropic	271	154	303	0.054216	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1542	trace-542-1761025280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 05:41:20.663+00	1351	Sample prompt for testing iteration 542	Sample response from AI model for iteration 542	\N	success	gemini-pro	google	278	76	303	0.009460	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1545	trace-545-1761068480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 17:41:20.663+00	411	Sample prompt for testing iteration 545	Sample response from AI model for iteration 545	\N	success	mixtral-8x7b	mistral	277	210	195	0.004412	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1556	trace-556-1761025280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 05:41:20.663+00	4931	Sample prompt for testing iteration 556	\N	Request timeout after 4931ms	timeout	gpt-4-turbo	openai	207	119	152	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1559	trace-559-1761090080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 23:41:20.663+00	260	Sample prompt for testing iteration 559	\N	Request timeout after 260ms	timeout	gemini-pro	google	336	47	320	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1569	trace-569-1761018080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 03:41:20.663+00	1809	Sample prompt for testing iteration 569	Sample response from AI model for iteration 569	\N	success	gemini-pro	google	263	200	124	0.009141	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1577	trace-577-1761032480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 07:41:20.663+00	1368	Sample prompt for testing iteration 577	Sample response from AI model for iteration 577	\N	success	mixtral-8x7b	mistral	216	49	509	0.003347	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1578	trace-578-1761010880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 01:41:20.663+00	616	Sample prompt for testing iteration 578	Sample response from AI model for iteration 578	\N	success	claude-3-opus	anthropic	339	76	746	0.040072	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1579	trace-579-1761028880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 06:41:20.663+00	1013	Sample prompt for testing iteration 579	Sample response from AI model for iteration 579	\N	success	mixtral-8x7b	mistral	55	168	683	0.006186	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1583	trace-583-1761025280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 05:41:20.663+00	2016	Sample prompt for testing iteration 583	Sample response from AI model for iteration 583	\N	success	gpt-4-turbo	openai	512	133	218	0.022118	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1589	trace-589-1761014480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 02:41:20.663+00	1324	Sample prompt for testing iteration 589	Sample response from AI model for iteration 589	\N	success	mixtral-8x7b	mistral	519	40	473	0.005987	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1592	trace-592-1761054080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 13:41:20.663+00	587	Sample prompt for testing iteration 592	Sample response from AI model for iteration 592	\N	success	gemini-pro	google	131	214	424	0.016249	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1593	trace-593-1761018080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 03:41:20.663+00	902	Sample prompt for testing iteration 593	Sample response from AI model for iteration 593	\N	success	gpt-4-turbo	openai	181	90	332	0.012055	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1599	trace-599-1761057680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 14:41:20.663+00	1462	Sample prompt for testing iteration 599	Sample response from AI model for iteration 599	\N	success	gpt-4-turbo	openai	496	163	595	0.017870	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1630	trace-630-1761010880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 01:41:20.663+00	2090	Sample prompt for testing iteration 630	Sample response from AI model for iteration 630	\N	success	mixtral-8x7b	mistral	278	36	526	0.006206	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1636	trace-636-1761082880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 21:41:20.663+00	1566	Sample prompt for testing iteration 636	Sample response from AI model for iteration 636	\N	success	gemini-pro	google	84	184	494	0.008043	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1638	trace-638-1761014480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 02:41:20.663+00	1652	Sample prompt for testing iteration 638	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	305	155	531	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1664	trace-664-1761021680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 04:41:20.663+00	1186	Sample prompt for testing iteration 664	Sample response from AI model for iteration 664	\N	success	gpt-4-turbo	openai	403	145	440	0.034777	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1671	trace-671-1761014480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 02:41:20.663+00	177	Sample prompt for testing iteration 671	Sample response from AI model for iteration 671	\N	success	mixtral-8x7b	mistral	508	215	241	0.009739	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1674	trace-674-1761039680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 09:41:20.663+00	1881	Sample prompt for testing iteration 674	\N	Request timeout after 1881ms	timeout	mixtral-8x7b	mistral	149	219	712	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1676	trace-676-1761064880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 16:41:20.663+00	281	Sample prompt for testing iteration 676	Sample response from AI model for iteration 676	\N	success	gemini-pro	google	143	60	88	0.006497	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1682	trace-682-1761057680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 14:41:20.663+00	1292	Sample prompt for testing iteration 682	Sample response from AI model for iteration 682	\N	success	gpt-4-turbo	openai	89	183	107	0.013400	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1691	trace-691-1761086480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 22:41:20.663+00	1537	Sample prompt for testing iteration 691	Sample response from AI model for iteration 691	\N	success	claude-3-opus	anthropic	177	109	188	0.073140	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1700	trace-700-1761075680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 19:41:20.663+00	549	Sample prompt for testing iteration 700	Sample response from AI model for iteration 700	\N	success	gemini-pro	google	120	162	237	0.022232	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1719	trace-719-1761046880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 11:41:20.663+00	135	Sample prompt for testing iteration 719	Sample response from AI model for iteration 719	\N	success	gpt-4-turbo	openai	124	150	482	0.044868	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1729	trace-729-1761010880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 01:41:20.663+00	298	Sample prompt for testing iteration 729	Sample response from AI model for iteration 729	\N	success	claude-3-opus	anthropic	301	215	522	0.026999	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1751	trace-751-1761057680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 14:41:20.663+00	1880	Sample prompt for testing iteration 751	Sample response from AI model for iteration 751	\N	success	claude-3-opus	anthropic	514	25	80	0.047186	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1752	trace-752-1761061280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 15:41:20.663+00	1656	Sample prompt for testing iteration 752	\N	Request timeout after 1656ms	timeout	mixtral-8x7b	mistral	121	206	660	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1760	trace-760-1761086480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 22:41:20.663+00	1078	Sample prompt for testing iteration 760	Sample response from AI model for iteration 760	\N	success	gemini-pro	google	224	196	165	0.009238	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1763	trace-763-1761046880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 11:41:20.663+00	290	Sample prompt for testing iteration 763	Sample response from AI model for iteration 763	\N	success	mixtral-8x7b	mistral	207	129	273	0.008078	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1766	trace-766-1761090080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 23:41:20.663+00	1768	Sample prompt for testing iteration 766	Sample response from AI model for iteration 766	\N	success	mixtral-8x7b	mistral	87	80	306	0.005569	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1767	trace-767-1761079280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 20:41:20.663+00	1948	Sample prompt for testing iteration 767	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	466	206	141	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1776	trace-776-1761028880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 06:41:20.663+00	1177	Sample prompt for testing iteration 776	Sample response from AI model for iteration 776	\N	success	claude-3-opus	anthropic	190	95	430	0.051226	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1790	trace-790-1761007280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 00:41:20.663+00	826	Sample prompt for testing iteration 790	Sample response from AI model for iteration 790	\N	success	gpt-4-turbo	openai	509	35	181	0.034319	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1792	trace-792-1761090080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 23:41:20.663+00	1401	Sample prompt for testing iteration 792	Sample response from AI model for iteration 792	\N	success	claude-3-opus	anthropic	415	175	624	0.033574	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1797	trace-797-1761010880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 01:41:20.663+00	232	Sample prompt for testing iteration 797	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	192	163	594	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1801	trace-801-1761054080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 13:41:20.663+00	1916	Sample prompt for testing iteration 801	\N	Sample error message: API_ERROR	error	mixtral-8x7b	mistral	65	183	233	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1803	trace-803-1761032480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 07:41:20.663+00	1520	Sample prompt for testing iteration 803	Sample response from AI model for iteration 803	\N	success	gpt-4-turbo	openai	416	101	283	0.019117	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1815	trace-815-1761028880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 06:41:20.663+00	1784	Sample prompt for testing iteration 815	Sample response from AI model for iteration 815	\N	success	gpt-4-turbo	openai	394	170	256	0.059745	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1822	trace-822-1761036080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 08:41:20.663+00	1817	Sample prompt for testing iteration 822	Sample response from AI model for iteration 822	\N	success	gpt-4-turbo	openai	427	146	451	0.048922	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1823	trace-823-1761079280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 20:41:20.663+00	474	Sample prompt for testing iteration 823	Sample response from AI model for iteration 823	\N	success	mixtral-8x7b	mistral	118	132	617	0.005951	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1828	trace-828-1761090080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 23:41:20.663+00	4145	Sample prompt for testing iteration 828	Sample response from AI model for iteration 828	\N	success	mixtral-8x7b	mistral	80	149	570	0.004751	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1837	trace-837-1761039680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 09:41:20.663+00	1929	Sample prompt for testing iteration 837	Sample response from AI model for iteration 837	\N	success	gpt-4-turbo	openai	317	110	183	0.011737	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1840	trace-840-1761021680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 04:41:20.663+00	1841	Sample prompt for testing iteration 840	\N	Sample error message: API_ERROR	error	gemini-pro	google	436	54	626	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1846	trace-846-1761057680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 14:41:20.663+00	381	Sample prompt for testing iteration 846	Sample response from AI model for iteration 846	\N	success	claude-3-opus	anthropic	249	136	354	0.064906	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1847	trace-847-1761079280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 20:41:20.663+00	521	Sample prompt for testing iteration 847	Sample response from AI model for iteration 847	\N	success	gpt-4-turbo	openai	357	195	122	0.056290	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1851	trace-851-1761072080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 18:41:20.663+00	1048	Sample prompt for testing iteration 851	Sample response from AI model for iteration 851	\N	success	gemini-pro	google	312	131	180	0.020626	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1860	trace-860-1761021680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 04:41:20.663+00	537	Sample prompt for testing iteration 860	\N	Request timeout after 537ms	timeout	mixtral-8x7b	mistral	84	194	467	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1876	trace-876-1761018080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 03:41:20.663+00	823	Sample prompt for testing iteration 876	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	374	73	706	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1880	trace-880-1761054080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 13:41:20.663+00	225	Sample prompt for testing iteration 880	Sample response from AI model for iteration 880	\N	success	gpt-4-turbo	openai	469	25	546	0.046986	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1887	trace-887-1761028880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 06:41:20.663+00	938	Sample prompt for testing iteration 887	Sample response from AI model for iteration 887	\N	success	claude-3-opus	anthropic	362	184	764	0.026550	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1890	trace-890-1761050480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 12:41:20.663+00	181	Sample prompt for testing iteration 890	Sample response from AI model for iteration 890	\N	success	mixtral-8x7b	mistral	133	46	229	0.009233	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1892	trace-892-1761010880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 01:41:20.663+00	902	Sample prompt for testing iteration 892	\N	Sample error message: API_ERROR	error	gemini-pro	google	282	214	195	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1905	trace-905-1761007280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 00:41:20.663+00	648	Sample prompt for testing iteration 905	Sample response from AI model for iteration 905	\N	success	mixtral-8x7b	mistral	474	98	692	0.003621	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1906	trace-906-1761046880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 11:41:20.663+00	766	Sample prompt for testing iteration 906	Sample response from AI model for iteration 906	\N	success	gemini-pro	google	236	102	103	0.016727	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1914	trace-914-1761039680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 09:41:20.663+00	1062	Sample prompt for testing iteration 914	\N	Sample error message: API_ERROR	error	claude-3-opus	anthropic	181	215	118	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1923	trace-923-1761014480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 02:41:20.663+00	3321	Sample prompt for testing iteration 923	\N	Request timeout after 3321ms	timeout	claude-3-opus	anthropic	456	135	223	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1925	trace-925-1761079280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	2025-10-21 20:41:20.663+00	1773	Sample prompt for testing iteration 925	\N	Sample error message: API_ERROR	error	gpt-4-turbo	openai	447	208	228	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-005
1931	trace-931-1761025280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 05:41:20.663+00	562	Sample prompt for testing iteration 931	Sample response from AI model for iteration 931	\N	success	claude-3-opus	anthropic	349	202	81	0.051818	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1939	trace-939-1761079280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 20:41:20.663+00	1024	Sample prompt for testing iteration 939	Sample response from AI model for iteration 939	\N	success	gpt-4-turbo	openai	519	25	364	0.041065	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1952	trace-952-1761082880.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 21:41:20.663+00	891	Sample prompt for testing iteration 952	Sample response from AI model for iteration 952	\N	success	gpt-4-turbo	openai	145	160	592	0.057782	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1957	trace-957-1761057680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	2025-10-21 14:41:20.663+00	510	Sample prompt for testing iteration 957	Sample response from AI model for iteration 957	\N	success	claude-3-opus	anthropic	529	198	348	0.037459	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-004
1961	trace-961-1761079280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	2025-10-21 20:41:20.663+00	2008	Sample prompt for testing iteration 961	Sample response from AI model for iteration 961	\N	success	gpt-4-turbo	openai	480	118	365	0.014116	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1962	trace-962-1761036080.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 08:41:20.663+00	188	Sample prompt for testing iteration 962	Sample response from AI model for iteration 962	\N	success	gpt-4-turbo	openai	228	188	149	0.052909	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-002
1963	trace-963-1761021680.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 04:41:20.663+00	536	Sample prompt for testing iteration 963	Sample response from AI model for iteration 963	\N	success	gpt-4-turbo	openai	185	56	268	0.034243	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
1984	trace-984-1761025280.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 05:41:20.663+00	1181	Sample prompt for testing iteration 984	Sample response from AI model for iteration 984	\N	success	claude-3-opus	anthropic	257	215	399	0.064781	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-003
1988	trace-988-1761086480.663000	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	2025-10-21 22:41:20.663+00	249	Sample prompt for testing iteration 988	\N	Request timeout after 249ms	timeout	gemini-pro	google	422	39	672	\N	{"max_tokens": 1000, "environment": "development", "temperature": 0.7}	{test,synthetic}	user-001
\.


--
-- Data for Name: _hyper_2_9_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_2_9_chunk (hour, workspace_id, agent_id, model, request_count, avg_latency_ms, p50_latency_ms, p95_latency_ms, p99_latency_ms, max_latency_ms, total_tokens_input, total_tokens_output, total_cost_usd, success_count, error_count, timeout_count) FROM stdin;
2025-10-22 18:00:00+00	00000000-0000-0000-0000-000000000001	agent-claude	claude-3-opus	1	523.0000000000000000	523	523	523	523	350	135	0.072016	1	0	0
2025-10-22 18:00:00+00	00000000-0000-0000-0000-000000000001	agent-claude	gemini-pro	3	1098.0000000000000000	1387	1417.6	1420.32	1421	408	387	0.022040	1	2	0
2025-10-22 18:00:00+00	00000000-0000-0000-0000-000000000001	agent-claude	gpt-4-turbo	1	766.0000000000000000	766	766	766	766	264	95	0.029137	1	0	0
2025-10-22 18:00:00+00	00000000-0000-0000-0000-000000000001	agent-gemini	gemini-pro	1	295.0000000000000000	295	295	295	295	486	67	0.008310	1	0	0
2025-10-22 18:00:00+00	00000000-0000-0000-0000-000000000001	agent-gemini	mixtral-8x7b	2	591.0000000000000000	591	708	718.4	721	748	402	0.018140	2	0	0
2025-10-22 18:00:00+00	00000000-0000-0000-0000-000000000001	agent-gpt4	claude-3-opus	4	930.2500000000000000	926.5	1352.95	1363.39	1366	1794	627	0.245297	4	0	0
2025-10-22 18:00:00+00	00000000-0000-0000-0000-000000000001	agent-gpt4	gemini-pro	1	711.0000000000000000	711	711	711	711	208	53	\N	0	1	0
2025-10-22 18:00:00+00	00000000-0000-0000-0000-000000000001	agent-gpt4	gpt-4-turbo	1	1894.0000000000000000	1894	1894	1894	1894	542	116	0.049106	1	0	0
2025-10-22 18:00:00+00	00000000-0000-0000-0000-000000000001	agent-mixtral	gemini-pro	1	1668.0000000000000000	1668	1668	1668	1668	269	61	\N	0	0	1
\.


--
-- Data for Name: _hyper_3_11_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_3_11_chunk (day, workspace_id, agent_id, model, request_count, avg_latency_ms, p50_latency_ms, p95_latency_ms, p99_latency_ms, total_tokens_input, total_tokens_output, total_cost_usd, success_count, error_count) FROM stdin;
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	claude-3-opus	17	1502.0000000000000000	1246	3552.999999999999	4295.4	5789	2375	0.651778	15	1
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gemini-pro	12	1597.2500000000000000	1244.5	3683.25	3773.45	3009	1686	0.102083	7	3
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gpt-4-turbo	20	1369.6000000000000000	1265	2221.5999999999976	4389.12	4918	2392	0.464862	14	3
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	mixtral-8x7b	13	1605.0769230769230769	1731	2992.199999999999	4088.04	4011	2032	0.057059	7	1
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	claude-3-opus	29	1794.2068965517241379	1537	3810	4346.639999999999	9174	3780	1.013359	22	4
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gemini-pro	16	982.8125000000000000	1180	1686	1784.4	4435	2265	0.192012	13	3
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gpt-4-turbo	26	999.0000000000000000	796	1977.2499999999998	3994.7499999999995	6438	3309	0.652226	21	2
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	mixtral-8x7b	25	1199.4000000000000000	781	3379.399999999998	4489.16	7779	3615	0.166002	20	1
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	claude-3-opus	21	1041.3809523809523810	662	2375	2759	7063	2947	0.719313	14	5
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gemini-pro	16	1289.2500000000000000	1191	2757.7499999999995	3251.5499999999997	4994	1999	0.104537	9	5
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gpt-4-turbo	20	1357.7000000000000000	1107.5	3291.2	3339.84	7165	2347	0.477975	13	6
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	mixtral-8x7b	22	1252.9545454545454545	1257	2085.2	3713.45	6079	2749	0.130837	18	2
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	claude-3-opus	15	1026.0666666666666667	1019	1873.6999999999998	2018.74	4684	1649	0.288344	7	4
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gemini-pro	23	1060.5217391304347826	743	3273.6999999999985	4134.84	6158	2562	0.296420	19	4
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gpt-4-turbo	16	1320.5000000000000000	1229.5	2305.7499999999986	3392.35	5940	2121	0.385214	11	3
2025-10-21 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	mixtral-8x7b	14	1595.8571428571428571	1575.5	3020.349999999999	4102.469999999999	4461	1400	0.062919	10	1
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	claude-3-opus	16	1529.1875000000000000	1327.5	3752.25	3865.65	5015	1916	0.495496	10	4
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gemini-pro	26	931.0769230769230769	758.5	1987.4999999999998	2059	5977	3193	0.285532	19	5
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gpt-4-turbo	20	1257.6000000000000000	1039	1978.2999999999975	4293.259999999999	7275	3002	0.560590	15	3
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	mixtral-8x7b	19	1177.9473684210526316	1077	3018.1999999999994	3559.64	4979	2384	0.079651	11	4
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	claude-3-opus	20	1311.8000000000000000	1369.5	2061.65	2086.73	6277	2343	0.718275	17	2
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gemini-pro	19	1297.5263157894736842	1050	3583.699999999999	4531.94	5546	2023	0.192697	12	4
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gpt-4-turbo	19	1400.7368421052631579	1291	2293.399999999998	4225.879999999999	6252	2113	0.601548	16	0
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	mixtral-8x7b	23	1332.1739130434782609	1048	2993.7999999999993	3679.3999999999996	6946	3030	0.148822	17	4
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	claude-3-opus	20	1057.6500000000000000	996.5	1770.4499999999998	1990.09	6166	1959	0.669969	17	2
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gemini-pro	14	1347.0000000000000000	1412.5	2025.45	2070.69	3826	1752	0.090030	6	5
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gpt-4-turbo	16	1014.5000000000000000	1110.5	1734.75	1767.75	4848	1908	0.317060	9	2
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	mixtral-8x7b	16	1674.8125000000000000	1353.5	4103.249999999999	4639.05	4891	2040	0.086733	12	1
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	claude-3-opus	25	1688.6000000000000000	1245	4514.2	4879.08	5734	3245	0.748646	16	4
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gemini-pro	19	1345.2631578947368421	1145	2868	2940	5613	2646	0.262855	15	1
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gpt-4-turbo	14	1049.1428571428571429	838.5	2097.1999999999994	2633.8399999999997	4732	1787	0.250686	10	2
2025-10-20 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	mixtral-8x7b	18	1284.8333333333333333	1297.5	1846	1859.6	5705	1749	0.133549	16	1
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	claude-3-opus	22	1224.9545454545454545	1132.5	2592.9999999999995	3644.68	6608	2323	0.739493	14	3
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gemini-pro	12	1142.0833333333333333	1208.5	2094.65	2207.73	3954	1040	0.157010	10	1
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gpt-4-turbo	14	1355.0000000000000000	1198.5	3025.9499999999985	4407.59	3610	1903	0.305980	9	0
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	mixtral-8x7b	21	1303.8571428571428571	1486	2028	2967.2	6683	2260	0.092851	13	2
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	claude-3-opus	10	1392.3000000000000000	1005	3345.249999999999	4178.65	3227	1356	0.268458	7	1
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gemini-pro	14	1559.2857142857142857	1300	3499.999999999999	4217.599999999999	4163	1722	0.157022	11	1
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gpt-4-turbo	15	1315.2666666666666667	1502	2028.3	2034.46	3827	1843	0.354484	10	2
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	mixtral-8x7b	18	1200.2222222222222222	752.5	3212.8	3234.56	5664	2205	0.069599	9	6
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	claude-3-opus	25	1511.4800000000000000	1303	3103.7999999999993	4135.36	7164	2895	0.965974	20	3
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gemini-pro	11	1271.2727272727272727	1344	2728.999999999999	3371.3999999999996	2472	1172	0.162713	9	2
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gpt-4-turbo	15	877.7333333333333333	935	1813.8	1833.96	4784	1757	0.224030	7	5
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	mixtral-8x7b	19	861.2105263157894737	729	1875.1999999999998	1999.04	5044	2400	0.138383	17	1
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	claude-3-opus	20	1116.2500000000000000	1024	2831.6499999999996	3358.33	6281	2291	0.662158	15	2
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gemini-pro	22	1284.8636363636363636	1068.5	3268.4999999999986	3865.8199999999997	7315	2752	0.240761	16	3
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gpt-4-turbo	23	1071.3478260869565217	1325	1844.3999999999999	1978.1	6460	2931	0.343757	12	4
2025-10-19 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	mixtral-8x7b	13	1603.1538461538461538	1296	3313.1999999999994	4044.24	2591	1549	0.066190	8	3
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	claude-3-opus	10	812.9000000000000000	545.5	2335.749999999999	3064.75	3054	1114	0.344083	7	3
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gemini-pro	17	1312.5882352941176471	1387	2447.9999999999986	3587.2	4832	1969	0.179751	10	5
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gpt-4-turbo	11	1712.0909090909090909	1342	4569.5	4757.1	3185	1258	0.423705	10	0
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	mixtral-8x7b	12	1414.9166666666666667	1180.5	3308.3499999999985	4612.07	4013	1287	0.075074	9	0
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	claude-3-opus	14	1303.4285714285714286	1199	2621.6499999999987	3962.7299999999996	4126	1410	0.520238	12	1
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gemini-pro	19	1162.5263157894736842	1038	3347.6	3416.72	6489	2750	0.189313	13	4
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gpt-4-turbo	13	1569.6923076923076923	1628	3015.1999999999994	3410.24	3587	1770	0.217115	8	1
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	mixtral-8x7b	18	1589.8333333333333333	1329.5	2924.6499999999983	4468.929999999999	5312	2345	0.087169	11	1
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	claude-3-opus	16	1186.5000000000000000	1243	2088.7499999999995	2332.95	5199	1950	0.689822	12	4
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gemini-pro	19	1764.4210526315789474	1661	3158.299999999999	4125.26	5165	2270	0.205091	13	3
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gpt-4-turbo	18	1333.5000000000000000	1296.5	2493.0999999999976	4433.82	5393	2353	0.467086	14	1
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	mixtral-8x7b	15	1181.1333333333333333	1277	2000.7999999999997	2267.36	4215	1761	0.081031	13	1
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	claude-3-opus	13	1137.0769230769230769	565	2954.3999999999983	4325.28	4287	1583	0.346916	9	2
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gemini-pro	20	1267.9000000000000000	1307.5	3424.2499999999995	3716.85	6078	2260	0.212746	14	1
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gpt-4-turbo	19	1310.8421052631578947	1183	2305.199999999998	4221.839999999999	5360	2255	0.446170	15	2
2025-10-22 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	mixtral-8x7b	13	1299.0000000000000000	1211	2700.399999999999	3440.08	3550	1557	0.071761	10	1
\.


--
-- Data for Name: _hyper_3_12_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._hyper_3_12_chunk (day, workspace_id, agent_id, model, request_count, avg_latency_ms, p50_latency_ms, p95_latency_ms, p99_latency_ms, total_tokens_input, total_tokens_output, total_cost_usd, success_count, error_count) FROM stdin;
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	claude-3-opus	20	746.5000000000000000	513	1870.8	1928.56	6260	2221	0.498820	12	6
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gemini-pro	15	1286.8666666666666667	1200	1950.1	2060.42	4445	1560	0.130400	12	1
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gpt-4-turbo	22	1369.5909090909090909	1184.5	3814.5499999999984	3985.84	7782	2869	0.667943	17	1
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	mixtral-8x7b	12	1384.2500000000000000	1094	3187.9499999999985	4495.19	3558	1461	0.068529	9	1
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	claude-3-opus	11	1825.1818181818181818	1370	4831.5	4865.5	3034	1208	0.358383	7	2
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gemini-pro	19	1384.5789473684210526	1117	3100.7999999999993	3776.16	5639	2484	0.281001	18	0
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gpt-4-turbo	17	986.8823529411764706	1034	1786	1853.2	4667	2037	0.529074	14	2
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	mixtral-8x7b	20	1255.3500000000000000	1028	2656.9999999999995	2976.2	6267	2281	0.117369	15	2
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	claude-3-opus	16	1791.0000000000000000	1501	4077.25	4113.85	5028	2022	0.376402	9	5
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gemini-pro	21	1302.1428571428571429	954	3579	3715.8	6838	2726	0.191022	15	4
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gpt-4-turbo	16	1796.6250000000000000	1344.5	3986	4137.2	5081	1774	0.504065	13	2
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	mixtral-8x7b	15	1679.7333333333333333	1165	4594.8	4732.56	4448	1914	0.074168	10	3
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	claude-3-opus	23	1046.2173913043478261	793	2555.5999999999995	2608	6822	2775	0.614357	14	6
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gemini-pro	17	1398.0588235294117647	1522	3318.199999999999	4330.04	4459	2131	0.172777	13	2
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gpt-4-turbo	24	1132.4166666666666667	1102	2013.6	2071.81	6795	2974	0.638687	16	5
2025-10-18 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	mixtral-8x7b	21	1315.7142857142857143	1176	3222	3709.2	6134	2463	0.082240	11	5
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	claude-3-opus	8	1370.8750000000000000	1651	2093.15	2096.23	2073	963	0.308200	6	1
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gemini-pro	20	1275.3500000000000000	1051.5	2573.6999999999994	3329.14	6208	2664	0.182722	15	0
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	gpt-4-turbo	16	1211.6250000000000000	1111	2257.4999999999995	2676.2999999999997	4699	2146	0.420874	12	2
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	mixtral-8x7b	19	1554.4736842105263158	1502	2797.899999999999	3574.7799999999997	6298	2423	0.083184	12	2
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	claude-3-opus	12	1333.4166666666666667	1365	1833.3999999999999	1944.28	4176	1438	0.326554	8	0
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gemini-pro	19	1694.3684210526315789	1549	3704.7	3918.54	5854	2405	0.173119	12	4
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	gpt-4-turbo	20	1395.1000000000000000	1226.5	3824.7499999999995	4216.15	5869	2306	0.571434	16	2
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	mixtral-8x7b	15	1258.4666666666666667	1148	2223.3999999999996	2479.88	4366	1657	0.078648	10	4
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	claude-3-opus	12	932.5000000000000000	825.5	1817.1499999999999	2040.23	2974	1385	0.294060	7	5
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gemini-pro	11	1070.3636363636363636	902	1774.9999999999998	1881.3999999999999	3781	1333	0.163310	10	1
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	gpt-4-turbo	10	1059.3000000000000000	966	1668.45	1675.29	2923	1107	0.357873	8	0
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	mixtral-8x7b	12	1543.0000000000000000	1600	2784.849999999999	3608.97	4151	1474	0.067843	9	1
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	claude-3-opus	17	1029.1764705882352941	767	2427.599999999999	3191.12	4705	2222	0.674678	15	1
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gemini-pro	11	1152.1818181818181818	1051	1901.5	1961.9	3379	1662	0.127287	8	3
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	gpt-4-turbo	9	1324.6666666666666667	1371	2020.2	2060.84	2478	1019	0.279705	6	1
2025-10-17 00:00:00+00	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	mixtral-8x7b	17	1068.7058823529411765	1071	1933.1999999999998	2026.6399999999999	5437	2488	0.063783	10	3
\.


--
-- Data for Name: _materialized_hypertable_2; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._materialized_hypertable_2 (hour, workspace_id, agent_id, model, request_count, avg_latency_ms, p50_latency_ms, p95_latency_ms, p99_latency_ms, max_latency_ms, total_tokens_input, total_tokens_output, total_cost_usd, success_count, error_count, timeout_count) FROM stdin;
\.


--
-- Data for Name: _materialized_hypertable_3; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal._materialized_hypertable_3 (day, workspace_id, agent_id, model, request_count, avg_latency_ms, p50_latency_ms, p95_latency_ms, p99_latency_ms, total_tokens_input, total_tokens_output, total_cost_usd, success_count, error_count) FROM stdin;
\.


--
-- Data for Name: compress_hyper_6_10_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal.compress_hyper_6_10_chunk (_ts_meta_count, workspace_id, agent_id, id, _ts_meta_min_2, _ts_meta_max_2, trace_id, _ts_meta_min_1, _ts_meta_max_1, "timestamp", latency_ms, input, output, error, _ts_meta_min_4, _ts_meta_max_4, status, _ts_meta_min_3, _ts_meta_max_3, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, _ts_meta_min_5, _ts_meta_max_5, tags, _ts_meta_v2_bloom1_user_id, user_id) FROM stdin;
9	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	BAAAAAAAAAAEdwAAAAAAAAOKAAAACQAAAAIAAAAAAAAAqg7wzJ5d34CcAABnpKhC0js=	trace-143-1760560880.663000	trace-971-1760568080.663000	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAAAJAAAAGnRyYWNlLTc4LTE3NjA1NzEwODUuMTcxNTc2AAAAG3RyYWNlLTk0NC0xNzYwNTY4MDgwLjY2MzAwMAAAABt0cmFjZS05NzEtMTc2MDU2ODA4MC42NjMwMDAAAAAbdHJhY2UtMzYxLTE3NjA1Njc0ODUuMTcxNTc2AAAAG3RyYWNlLTY2My0xNzYwNTY3NDg1LjE3MTU3NgAAABt0cmFjZS02NzktMTc2MDU2NzQ4NS4xNzE1NzYAAAAbdHJhY2UtMTYwLTE3NjA1NjM4ODUuMTcxNTc2AAAAG3RyYWNlLTIzNy0xNzYwNTYzODg1LjE3MTU3NgAAABt0cmFjZS0xNDMtMTc2MDU2MDg4MC42NjMwMDA=	2025-10-15 20:41:20.663+00	2025-10-15 23:31:25.171576+00	BAAAAuQ3Sq3Z2P////9M6tZgAAAACQAAAAgAAAAA7u7e7gAFyHNV1JbwAAXIdLv+6i8AAAABZipTQEb89MBG/PS/AAAAAAAAAAAAAAABrSdH/wAAAAGtJ0gAAAAAAWYqUz8=	BAAAAAAAAAAB9/////////x8AAAACQAAAAMAAAAAAAAKuw7kB/QZLw8GAA4DGxG8GYcAAAAAAAAI2w==	AQBwZ19jYXRhbG9nAHRleHQAAAEAAAAJAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk0NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzYxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY2MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NzkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTYwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIzNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNDM=	AQFwZ19jYXRhbG9nAHRleHQAAQAAAAkAAAABAAAAAAAAAAEAAAAAAAAAAgEAAAAIAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5NzEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNjEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NjMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NzkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNjAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMzcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNDM=	AQFwZ19jYXRhbG9nAHRleHQAAQAAAAkAAAABAAAAAAAAAAEAAAAAAAAB/QEAAAABAAAAH1NhbXBsZSBlcnJvciBtZXNzYWdlOiBBUElfRVJST1I=	error	success	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAACQAAAAEAAAAAAAAAAQAAAAAAAAACAAEAAAACAAAAB3N1Y2Nlc3MAAAAFZXJyb3I=	gemini-pro	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAACQAAAAEAAAAAAAAAAgAAAAAAASIEAAEAAAADAAAADG1peHRyYWwtOHg3YgAAAApnZW1pbmktcHJvAAAAC2dwdC00LXR1cmJv	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAACQAAAAEAAAAAAAAAAgAAAAAAASIEAAEAAAADAAAAB21pc3RyYWwAAAAGZ29vZ2xlAAAABm9wZW5haQ==	BAAAAAAAAAAB2AAAAAAAAAC2AAAACQAAAAIAAAAAAAAAqgBaMgGtMTL+AAATAWdXZYc=	BAAAAAAAAAAAH//////////AAAAACQAAAAIAAAAAAAAAeQUpCR3PBt1KAAAAAAAa2ak=	BAAAAAAAAAABmP////////+tAAAACQAAAAIAAAAAAAAAqgJTPxbWe9TYAAAPZMtHgQ4=	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAAkAAAABAAAAAAAAAAEAAAAAAAAAAgEAAAAIAAAADAAC//8AAAAGAG4TiAAAAAwAAv//AAAABgA9HCAAAAAMAAL//wAAAAYALAyAAAAADAAC//8AAAAGAUkR+AAAAAwAAv//AAAABgBnBkAAAAAMAAL//wAAAAYBJgJYAAAADAAC//8AAAAGACQGQAAAAAwAAv//AAAABgBaJkg=	AgBwZ19jYXRhbG9nAGpzb25iAAAAAAkAAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAAkAAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x0005e4403b82e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAACQAAAAEAAAAAAAAAAgAAAAAAA6gkAAEAAAAEAAAACHVzZXItMDAzAAAACHVzZXItMDA1AAAACHVzZXItMDA0AAAACHVzZXItMDAy
16	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	BAAAAAAAAAABQv////////71AAAAEAAAAAQAAAAAAACruwwICBsIKwr4A14CPhDWFd8UgA23AC8GXQAAUdzOwFVD	trace-164-1760564480.663000	trace-942-1760571680.663000	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAAAQAAAAG3RyYWNlLTQwNC0xNzYwNTcxNjgwLjY2MzAwMAAAABt0cmFjZS03NjItMTc2MDU3MTY4MC42NjMwMDAAAAAadHJhY2UtODItMTc2MDU3MTY4MC42NjMwMDAAAAAbdHJhY2UtOTQyLTE3NjA1NzE2ODAuNjYzMDAwAAAAGXRyYWNlLTItMTc2MDU3MTA4NS4xNzE1NzYAAAAbdHJhY2UtMjE3LTE3NjA1NzEwODUuMTcxNTc2AAAAG3RyYWNlLTcxOS0xNzYwNTcxMDg1LjE3MTU3NgAAABt0cmFjZS02NTItMTc2MDU2ODA4MC42NjMwMDAAAAAbdHJhY2UtNzcwLTE3NjA1NjgwODAuNjYzMDAwAAAAG3RyYWNlLTg2NC0xNzYwNTY4MDgwLjY2MzAwMAAAABt0cmFjZS0yMDItMTc2MDU2NzQ4NS4xNzE1NzYAAAAbdHJhY2UtMTY0LTE3NjA1NjQ0ODAuNjYzMDAwAAAAG3RyYWNlLTQ1Mi0xNzYwNTY0NDgwLjY2MzAwMAAAABt0cmFjZS0yMDEtMTc2MDU2Mzg4NS4xNzE1NzYAAAAbdHJhY2UtNTg5LTE3NjA1NjM4ODUuMTcxNTc2AAAAG3RyYWNlLTMyMi0xNzYwNTYwMjg1LjE3MTU3Ng==	2025-10-15 20:31:25.171576+00	2025-10-15 23:41:20.663+00	BAAAAuQ3Jy9feP////8pbFwAAAAAEAAAAAwAAO3u3u7d7gAFyHOc0YuwAAXIc5zRi68AAAAAAAAAAEb89MBG/PS/AAAAAAAAAAAAAAABZipTPwAAAAFmKlNARvz0vwAAAAAAAAABHy1efwAAAAFmKlNARvz0wEb89L8AAAABrSdH/w==	BAAAAAAAAAABff////////+iAAAAEAAAAAQAAAAAAACquxLKBGsf5xvcEl8PogxiGhUJplUo3RLXNgAAAAGmFvbz	AQBwZ19jYXRhbG9nAHRleHQAAAEAAAAQAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQwNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NjIAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTQyAAAAJVNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjE3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDcxOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NTIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzcwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg2NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTY0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ1MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMDEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTg5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMyMg==	AQFwZ19jYXRhbG9nAHRleHQAAQAAABAAAAABAAAAAAAAAAEAAAAAAAAAQgEAAAAOAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDA0AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5NDIAAAAtU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjE3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjUyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzcwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODY0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjAyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTY0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDUyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjAxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTg5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzIy	AQFwZ19jYXRhbG9nAHRleHQAAQAAABAAAAABAAAAAAAAAAEAAAAAAAD/vQEAAAACAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAzMDQ4bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDI0MDJtcw==	success	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAEAAAAAEAAAAAAAAAAQAAAAAAAABCAAEAAAACAAAAB3N1Y2Nlc3MAAAAHdGltZW91dA==	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAEAAAAAEAAAAAAAAAAgAAAABniJEEAAEAAAAEAAAAC2dwdC00LXR1cmJvAAAADWNsYXVkZS0zLW9wdXMAAAAMbWl4dHJhbC04eDdiAAAACmdlbWluaS1wcm8=	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAEAAAAAEAAAAAAAAAAgAAAABniJEEAAEAAAAEAAAABm9wZW5haQAAAAlhbnRocm9waWMAAAAHbWlzdHJhbAAAAAZnb29nbGU=	BAAAAAAAAAAB9AAAAAAAAAA5AAAAEAAAAAMAAAAAAAAKmQe6lYKKVeXQDbysEsdz6YkAABgUTlOV5g==	BAAAAAAAAAAAF/////////9DAAAAEAAAAAMAAAAAAAAJmQFg/RCG5EzkBBDtCcSBnHwAAACt50js4g==	BAAAAAAAAAAC9wAAAAAAAAHOAAAAEAAAAAMAAAAAAAAKqQfem7KBeb4iAXw5IvMf1IgD3Azw21xGyw==	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAABAAAAABAAAAAAAAAAEAAAAAAAAAQgEAAAAOAAAADAAC//8AAAAGAZoVfAAAAAwAAv//AAAABgCxCcQAAAAMAAL//wAAAAYByxfUAAAADAAC//8AAAAGAngg0AAAAAwAAv//AAAABgHUE+wAAAAMAAL//wAAAAYANiBsAAAADAAC//8AAAAGAiIFFAAAAAwAAv//AAAABgA8BEwAAAAMAAL//wAAAAYB+Q88AAAADAAC//8AAAAGAGgmSAAAAAwAAv//AAAABgCRIAgAAAAMAAL//wAAAAYBuxr0AAAADAAC//8AAAAGAGoOdAAAAAwAAv//AAAABgD1GJw=	AgBwZ19jYXRhbG9nAGpzb25iAAAAABAAAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAABAAAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAEAAAAAEAAAAAAAAAAwAALMKIkDRAAAEAAAAFAAAACHVzZXItMDAyAAAACHVzZXItMDA1AAAACHVzZXItMDAzAAAACHVzZXItMDAxAAAACHVzZXItMDA0
14	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	BAAAAAAAAAACXgAAAAAAAACeAAAADgAAAAMAAAAAAAALqgDBiQU1iBiMC0NGvfy2sNgL2g2FBVMR4g==	trace-208-1760568080.663000	trace-99-1760571680.663000	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAAAOAAAAGnRyYWNlLTk0LTE3NjA1NzE2ODAuNjYzMDAwAAAAGnRyYWNlLTk5LTE3NjA1NzE2ODAuNjYzMDAwAAAAG3RyYWNlLTQzNy0xNzYwNTcxMDg1LjE3MTU3NgAAABt0cmFjZS04NzEtMTc2MDU3MTA4NS4xNzE1NzYAAAAbdHJhY2UtMjA4LTE3NjA1NjgwODAuNjYzMDAwAAAAG3RyYWNlLTY1My0xNzYwNTY4MDgwLjY2MzAwMAAAABt0cmFjZS02MzYtMTc2MDU2NzQ4NS4xNzE1NzYAAAAbdHJhY2UtNDA5LTE3NjA1NjQ0ODAuNjYzMDAwAAAAG3RyYWNlLTYxNi0xNzYwNTY0NDgwLjY2MzAwMAAAABt0cmFjZS0zODEtMTc2MDU2Mzg4NS4xNzE1NzYAAAAbdHJhY2UtNDM1LTE3NjA1NjA4ODAuNjYzMDAwAAAAG3RyYWNlLTgwNy0xNzYwNTYwODgwLjY2MzAwMAAAABt0cmFjZS00NDgtMTc2MDU2MDI4NS4xNzE1NzYAAAAbdHJhY2UtNjA2LTE3NjA1NjAyODUuMTcxNTc2	2025-10-15 20:31:25.171576+00	2025-10-15 23:41:20.663+00	BAAAAuQ3Jy9feAAAAAAAAAAAAAAADgAAAAwAAN7u7u7t7gAFyHOc0YuwAAXIc5zRi69G/PTARvz0vwAAAAFmKlM/AAAAAWYqU0AAAAAARvz0vwAAAAEfLV5/AAAAAWYqU0AAAAAARvz0vwAAAAEfLV5/AAAAAWYqU0BG/PTARvz0vw==	BAAAAAAAAAAO2gAAAAAAAAOdAAAADgAAAAQAAAAAAACLugF9BYYx4B/GHA4PrjBxIVwCAAWoDmQmuwAAAAAAAADY	AQBwZ19jYXRhbG9nAHRleHQAAAEAAAAOAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk0AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQzNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjA4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY1MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MzYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDA5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYxNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzODEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDM1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgwNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NDgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjA2	AQFwZ19jYXRhbG9nAHRleHQAAQAAAA4AAAABAAAAAAAAAAEAAAAAAAACAAEAAAANAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTQAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQzNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg3MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDIwOAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY1MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYzNgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQwOQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYxNgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQzNQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgwNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ0OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYwNg==	AQFwZ19jYXRhbG9nAHRleHQAAQAAAA4AAAABAAAAAAAAAAEAAAAAAAA9/wEAAAABAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxNjYybXM=	success	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAADgAAAAEAAAAAAAAAAQAAAAAAAAIAAAEAAAACAAAAB3N1Y2Nlc3MAAAAHdGltZW91dA==	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAADgAAAAEAAAAAAAAAAgAAAAAGiGgUAAEAAAADAAAADWNsYXVkZS0zLW9wdXMAAAAMbWl4dHJhbC04eDdiAAAACmdlbWluaS1wcm8=	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAADgAAAAEAAAAAAAAAAgAAAAAGiGgUAAEAAAADAAAACWFudGhyb3BpYwAAAAdtaXN0cmFsAAAABmdvb2dsZQ==	BAAAAAAAAAABiQAAAAAAAAERAAAADgAAAAMAAAAAAAAKmQYl0JFQ08EAAoSDZQdRCPwAAAAAAEpimw==	BAAAAAAAAAAAiQAAAAAAAABbAAAADgAAAAMAAAAAAAAImQJcKTiIKV2OBWSAF442sO8AAAAAAAC0zg==	BAAAAAAAAAACIv////////9OAAAADgAAAAMAAAAAAAAKqQrT5cOPL46uBjFQgKoAcukAAAAGHXaA0w==	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAA4AAAABAAAAAAAAAAEAAAAAAAACAAEAAAANAAAADAAC//8AAAAGAgAhNAAAAAwAAv//AAAABgB4C7gAAAAMAAL//wAAAAYAWRJcAAAADAAC//8AAAAGALcD6AAAAAwAAv//AAAABgDyJkgAAAAMAAL//wAAAAYA+BV8AAAADAAC//8AAAAGAGMbvAAAAAwAAv//AAAABgAlEAQAAAAMAAL//wAAAAYCMiGYAAAADAAC//8AAAAGAlwXcAAAAAwAAv//AAAABgDRDBwAAAAMAAL//wAAAAYAbQMgAAAADAAC//8AAAAGAGYmrA==	AgBwZ19jYXRhbG9nAGpzb25iAAAAAA4AAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAA4AAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4502b83e40c	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAADgAAAAEAAAAAAAAAAgAAAAAHjSQkAAEAAAAEAAAACHVzZXItMDAxAAAACHVzZXItMDA0AAAACHVzZXItMDAzAAAACHVzZXItMDA1
17	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	BAAAAAAAAAAFFAAAAAAAAAA7AAAAEQAAAAQAAAAAAACrqgJcVqMnn1owAQAOn9DmVJUOOhGFAr4BPgAAAAAGRLJK	trace-119-1760567485.171576	trace-958-1760571085.171576	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAAARAAAAG3RyYWNlLTMwNC0xNzYwNTcxNjgwLjY2MzAwMAAAABt0cmFjZS0zMzMtMTc2MDU3MTY4MC42NjMwMDAAAAAbdHJhY2UtOTU4LTE3NjA1NzEwODUuMTcxNTc2AAAAG3RyYWNlLTI3Ni0xNzYwNTY4MDgwLjY2MzAwMAAAABt0cmFjZS04OTYtMTc2MDU2ODA4MC42NjMwMDAAAAAbdHJhY2UtOTI5LTE3NjA1NjgwODAuNjYzMDAwAAAAG3RyYWNlLTExOS0xNzYwNTY3NDg1LjE3MTU3NgAAABt0cmFjZS0zMzMtMTc2MDU2NzQ4NS4xNzE1NzYAAAAbdHJhY2UtNDMwLTE3NjA1Njc0ODUuMTcxNTc2AAAAG3RyYWNlLTY1NS0xNzYwNTY3NDg1LjE3MTU3NgAAABp0cmFjZS0zOS0xNzYwNTY0NDgwLjY2MzAwMAAAABt0cmFjZS03NzQtMTc2MDU2NDQ4MC42NjMwMDAAAAAbdHJhY2UtMjY2LTE3NjA1NjM4ODUuMTcxNTc2AAAAG3RyYWNlLTU3OS0xNzYwNTYzODg1LjE3MTU3NgAAABt0cmFjZS0xODUtMTc2MDU2MDg4MC42NjMwMDAAAAAbdHJhY2UtMjQxLTE3NjA1NjA4ODAuNjYzMDAwAAAAG3RyYWNlLTMwMC0xNzYwNTYwODgwLjY2MzAwMA==	2025-10-15 20:41:20.663+00	2025-10-15 23:41:20.663+00	BAAAAuQ3Sq3Z2AAAAAAAAAAAAAAAEQAAAA4AHu3u7d7u7gAFyHOc0YuwAAXIc5zRi68AAAAARvz0vwAAAAEfLV5/AAAAAWYqU0BG/PS/AAAAAAAAAABG/PTAAAAAAAAAAAAAAAABZipTPwAAAAFmKlNARvz0wEb89L8AAAABZipTPwAAAAFmKlNAAAAAAAAAAAA=	BAAAAAAAAAAC+P////////+0AAAAEQAAAAQAAAAAAAC7ugJmNSVvFKKOGgoTRwemAREZYiCNHVQj2QJ7DBgRDQMW	AQBwZ19jYXRhbG9nAHRleHQAAAEAAAARAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMwNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMzMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTU4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI3NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4OTYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTI5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDExOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMzMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDMwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY1NQAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NzQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjY2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU3OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxODUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjQxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMwMA==	AQFwZ19jYXRhbG9nAHRleHQAAQAAABEAAAABAAAAAAAAAAEAAAAAAAAkKAEAAAANAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzA0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzMzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTU4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODk2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTE5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzMzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDMwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjU1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzc0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjY2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTg1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjQxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzAw	AQFwZ19jYXRhbG9nAHRleHQAAQAAABEAAAABAAAAAAAAAAEAAAAAAAHb1wEAAAAEAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA4MzZtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTc1NW1zAAAAH1NhbXBsZSBlcnJvciBtZXNzYWdlOiBBUElfRVJST1IAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE5MDBtcw==	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAEQAAAAEAAAAAAAAAAgAAAAAEIARAAAEAAAADAAAAB3N1Y2Nlc3MAAAAHdGltZW91dAAAAAVlcnJvcg==	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAEQAAAAEAAAAAAAAAAgAAAACwzZMkAAEAAAAEAAAAC2dwdC00LXR1cmJvAAAADWNsYXVkZS0zLW9wdXMAAAAKZ2VtaW5pLXBybwAAAAxtaXh0cmFsLTh4N2I=	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAEQAAAAEAAAAAAAAAAgAAAACwzZMkAAEAAAAEAAAABm9wZW5haQAAAAlhbnRocm9waWMAAAAGZ29vZ2xlAAAAB21pc3RyYWw=	BAAAAAAAAAAA6P/////////KAAAAEQAAAAMAAAAAAAAJmQH5iZQL+WZgABERSAJTtEkAAKFYJhJpYA==	BAAAAAAAAAAA2AAAAAAAAAAWAAAAEQAAAAMAAAAAAAAJmQV0u08GaP2IAQjZWZTQxd4AAAcSD/Xwiw==	BAAAAAAAAAACCwAAAAAAAAD9AAAAEQAAAAQAAAAAAACqqgRsN9L5KuCoAokpUMAV4X0FSxHEQHMW9gAAAAAAECRa	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAABEAAAABAAAAAAAAAAEAAAAAAAAkKAEAAAANAAAADAAC//8AAAAGAPAM5AAAAAwAAv//AAAABgGgCigAAAAKAAH//wAAAAYAvAAAAAwAAv//AAAABgBtHUwAAAAMAAL//wAAAAYCuAZAAAAADAAC//8AAAAGAI4dTAAAAAwAAv//AAAABgJDB2wAAAAMAAL//wAAAAYAXQGQAAAADAAC//8AAAAGAEUeeAAAAAwAAv//AAAABgD5FFAAAAAMAAL//wAAAAYAaxRQAAAADAAC//8AAAAGAPEO2AAAAAwAAv//AAAABgFECow=	AgBwZ19jYXRhbG9nAGpzb25iAAAAABEAAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAABEAAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAEQAAAAEAAAAAAAAAAwAEgCLDKjKIAAEAAAAFAAAACHVzZXItMDAyAAAACHVzZXItMDA1AAAACHVzZXItMDAzAAAACHVzZXItMDAxAAAACHVzZXItMDA0
\.


--
-- Data for Name: compress_hyper_6_13_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal.compress_hyper_6_13_chunk (_ts_meta_count, workspace_id, agent_id, id, _ts_meta_min_2, _ts_meta_max_2, trace_id, _ts_meta_min_1, _ts_meta_max_1, "timestamp", latency_ms, input, output, error, _ts_meta_min_4, _ts_meta_max_4, status, _ts_meta_min_3, _ts_meta_max_3, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, _ts_meta_min_5, _ts_meta_max_5, tags, _ts_meta_v2_bloom1_user_id, user_id) FROM stdin;
76	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	BAAAAAAAAAAC7wAAAAAAAAHHAAAATAAAABGrqqqqq7q6uwAAAAAAAAALAtYAngi5CTAEfgUjEbQQsQWUNf2koVN/DCcQ7AZQEHUByTVQaf1sKxKyCzEBTgC8BT4LERH2EzsARx67OG5yWQS2PxzSfvDZBxpEfVqtdaMBq3xegD/N/wN9Ix1SFncrC6a308J9Bo0Od0qJ8ImU0w70Fq0J9gjaAY4rdMgGMoUAAAAAEDQQWQ==	trace-115-1760625085.171576	trace-997-1760625085.171576	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABMAAAAG3RyYWNlLTE3Ni0xNzYwNjU4MDgwLjY2MzAwMAAAABt0cmFjZS0yMzUtMTc2MDY1ODA4MC42NjMwMDAAAAAbdHJhY2UtMzczLTE3NjA2NTgwODAuNjYzMDAwAAAAG3RyYWNlLTg3NC0xNzYwNjU4MDgwLjY2MzAwMAAAABt0cmFjZS0yMzgtMTc2MDY1NzQ4NS4xNzE1NzYAAAAbdHJhY2UtODY4LTE3NjA2NTc0ODUuMTcxNTc2AAAAG3RyYWNlLTg0MC0xNzYwNjUzODg1LjE3MTU3NgAAABt0cmFjZS0zODctMTc2MDY1MDg4MC42NjMwMDAAAAAbdHJhY2UtNDg2LTE3NjA2NTA4ODAuNjYzMDAwAAAAG3RyYWNlLTI5NC0xNzYwNjUwMjg1LjE3MTU3NgAAABt0cmFjZS04NDgtMTc2MDY1MDI4NS4xNzE1NzYAAAAbdHJhY2UtOTcwLTE3NjA2NTAyODUuMTcxNTc2AAAAG3RyYWNlLTgwNi0xNzYwNjQ3MjgwLjY2MzAwMAAAABt0cmFjZS01MzUtMTc2MDY0NjY4NS4xNzE1NzYAAAAadHJhY2UtNzItMTc2MDY0NjY4NS4xNzE1NzYAAAAbdHJhY2UtNzc1LTE3NjA2NDM2ODAuNjYzMDAwAAAAG3RyYWNlLTkyMi0xNzYwNjQzNjgwLjY2MzAwMAAAABt0cmFjZS01MTEtMTc2MDY0MzA4NS4xNzE1NzYAAAAbdHJhY2UtMTI3LTE3NjA2NDAwODAuNjYzMDAwAAAAG3RyYWNlLTY5MC0xNzYwNjQwMDgwLjY2MzAwMAAAABt0cmFjZS04MjYtMTc2MDY0MDA4MC42NjMwMDAAAAAbdHJhY2UtNzMzLTE3NjA2MzY0ODAuNjYzMDAwAAAAG3RyYWNlLTczNC0xNzYwNjM2NDgwLjY2MzAwMAAAABt0cmFjZS05MDItMTc2MDYzNjQ4MC42NjMwMDAAAAAbdHJhY2UtNjM3LTE3NjA2MzU4ODUuMTcxNTc2AAAAG3RyYWNlLTc2NS0xNzYwNjMyODgwLjY2MzAwMAAAABt0cmFjZS00MzEtMTc2MDYzMjI4NS4xNzE1NzYAAAAbdHJhY2UtMzk2LTE3NjA2MjkyODAuNjYzMDAwAAAAG3RyYWNlLTk0NC0xNzYwNjI4Njg1LjE3MTU3NgAAABt0cmFjZS0xNjMtMTc2MDYyNTY4MC42NjMwMDAAAAAadHJhY2UtODEtMTc2MDYyNTY4MC42NjMwMDAAAAAbdHJhY2UtMTE1LTE3NjA2MjUwODUuMTcxNTc2AAAAG3RyYWNlLTU4NS0xNzYwNjI1MDg1LjE3MTU3NgAAABt0cmFjZS04MDktMTc2MDYyNTA4NS4xNzE1NzYAAAAbdHJhY2UtOTk3LTE3NjA2MjUwODUuMTcxNTc2AAAAGnRyYWNlLTc2LTE3NjA2MjIwODAuNjYzMDAwAAAAG3RyYWNlLTEzOS0xNzYwNjIxNDg1LjE3MTU3NgAAABt0cmFjZS04NDMtMTc2MDYyMTQ4NS4xNzE1NzYAAAAadHJhY2UtNDItMTc2MDYxODQ4MC42NjMwMDAAAAAbdHJhY2UtODQ0LTE3NjA2MTg0ODAuNjYzMDAwAAAAG3RyYWNlLTkyNC0xNzYwNjE4NDgwLjY2MzAwMAAAABt0cmFjZS02MTYtMTc2MDYxNzg4NS4xNzE1NzYAAAAadHJhY2UtMTctMTc2MDYxNDg4MC42NjMwMDAAAAAbdHJhY2UtODcwLTE3NjA2MTQyODUuMTcxNTc2AAAAG3RyYWNlLTYzMi0xNzYwNjExMjgwLjY2MzAwMAAAABt0cmFjZS02MDItMTc2MDYxMDY4NS4xNzE1NzYAAAAadHJhY2UtODItMTc2MDYxMDY4NS4xNzE1NzYAAAAbdHJhY2UtNDE4LTE3NjA2MDc2ODAuNjYzMDAwAAAAG3RyYWNlLTc1OS0xNzYwNjA3NjgwLjY2MzAwMAAAABt0cmFjZS04ODYtMTc2MDYwNDA4MC42NjMwMDAAAAAadHJhY2UtOTUtMTc2MDYwNDA4MC42NjMwMDAAAAAbdHJhY2UtMTI0LTE3NjA2MDM0ODUuMTcxNTc2AAAAG3RyYWNlLTg1OC0xNzYwNjAzNDg1LjE3MTU3NgAAABt0cmFjZS0zMTEtMTc2MDYwMDQ4MC42NjMwMDAAAAAbdHJhY2UtMzE3LTE3NjA2MDA0ODAuNjYzMDAwAAAAG3RyYWNlLTQ4NC0xNzYwNTk5ODg1LjE3MTU3NgAAABt0cmFjZS02NTEtMTc2MDU5OTg4NS4xNzE1NzYAAAAbdHJhY2UtMjk5LTE3NjA1OTMyODAuNjYzMDAwAAAAG3RyYWNlLTQ3Ni0xNzYwNTkyNjg1LjE3MTU3NgAAABt0cmFjZS0xNDQtMTc2MDU4OTY4MC42NjMwMDAAAAAbdHJhY2UtMTk0LTE3NjA1ODk2ODAuNjYzMDAwAAAAG3RyYWNlLTE0My0xNzYwNTg5MDg1LjE3MTU3NgAAABt0cmFjZS0zNjQtMTc2MDU4OTA4NS4xNzE1NzYAAAAbdHJhY2UtMTgxLTE3NjA1ODYwODAuNjYzMDAwAAAAG3RyYWNlLTE0Ni0xNzYwNTg1NDg1LjE3MTU3NgAAABt0cmFjZS0yNDQtMTc2MDU4NTQ4NS4xNzE1NzYAAAAbdHJhY2UtNjE3LTE3NjA1ODI0ODAuNjYzMDAwAAAAGnRyYWNlLTg3LTE3NjA1ODE4ODUuMTcxNTc2AAAAG3RyYWNlLTQ3MS0xNzYwNTc4Mjg1LjE3MTU3NgAAABt0cmFjZS01MzItMTc2MDU3ODI4NS4xNzE1NzYAAAAbdHJhY2UtNTQzLTE3NjA1NzgyODUuMTcxNTc2AAAAG3RyYWNlLTE2Ni0xNzYwNTc1MjgwLjY2MzAwMAAAABt0cmFjZS00NDEtMTc2MDU3NTI4MC42NjMwMDAAAAAbdHJhY2UtOTE1LTE3NjA1NzUyODAuNjYzMDAwAAAAG3RyYWNlLTI5Ni0xNzYwNTc0Njg1LjE3MTU3NgAAABt0cmFjZS03NTEtMTc2MDU3NDY4NS4xNzE1NzY=	2025-10-16 00:31:25.171576+00	2025-10-16 23:41:20.663+00	BAAAAuQ6gX3veAAAAAAAAAAAAAAATAAAAEHu7u7u3u7d7u7t3u7u7e7u3u3u7u7u7e7e7u7u7u3u7gAAAAAAAAANAAXIm9iAS7AABcib2IBLrwAAAAAAAAAARvz0wEb89L8AAAABrSdH/wAAAABG/PTAAAAAAWYqU0BG/PTARvz0vwAAAAAAAAAAAAAAAWYqUz8AAAABHy1egAAAAABG/PTAAAAAAWYqUz8AAAABZipTQAAAAABG/PS/AAAAAR8tXn8AAAABZipTQAAAAAAAAAAAAAAAAa0nR/8AAAABrSdIAEb89L8AAAAAAAAAAR8tXn8AAAABHy1egAAAAAEfLV5/AAAAAR8tXoAAAAABHy1efwAAAAFmKlNARvz0wEb89L8AAAAAAAAAAAAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAFmKlM/AAAAAWYqU0BG/PS/AAAAAAAAAAEfLV5/AAAAAR8tXoAAAAABHy1efwAAAAEfLV6AAAAAAEb89MAAAAABZipTPwAAAAFmKlNAAAAAAa0nR/8AAAABrSdIAEb89MBG/PS/AAAAAWYqUz8AAAABZipTQEb89MBG/PS/AAAAAxNRmz8AAAACzFSmgAAAAAEfLV5/AAAAAWYqU0BG/PTARvz0vwAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAFmKlM/AAAAAR8tXoAAAAABZipTPwAAAAGtJ0gAAAAAAAAAAAAAAAABZipTPwAAAAFmKlNARvz0vwAAAAAAAAAARvz0wA==	BAAAAAAAAAAGywAAAAAAAADIAAAATAAAABKrq7uru7uruwAAAAAAAACqD1EjeEDrI4QGUAGICusPqgGkJ75CORugCiUleOqKs1MLKwSACmsU2iyHF4INFgVjHDQKHBV7HHgdLww1MFI5KwlkB7sCsRxqAukDsXN0Za8R6BZ/FkQLORt+MGsi4AzBAzsD9gdqEsUEACMRxkhiER+TGJwNRQZCDSY4lmh8ouUDmvB6eiyO6QAAAAOyvlyI	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABMAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE3NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMzUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzczAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg3NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMzgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODY4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg0MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzODcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDg2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI5NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NDgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTcwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgwNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MzUAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzc1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkyMgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTI3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY5MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MjYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzMzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDczNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjM3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc2NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzk2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk0NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNjMAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTE1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU4NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MDkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTk3AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDEzOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NDMAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODQ0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkyNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MTYAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODcwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYzMgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MDIAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDE4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc1OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4ODYAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTI0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg1OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzE3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ4NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjk5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ3NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNDQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTk0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE0MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNjQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTgxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE0NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNDQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjE3AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ3MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MzIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTQzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE2NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NDEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTE1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI5NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NTE=	AQFwZ19jYXRhbG9nAHRleHQAAQAAAEwAAAACAAAAAAAAABGnkAECbUgZGAAAAAAAAAYFAQAAADMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNzYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMzUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNzMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NjgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NDAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzODcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyOTQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NDgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1MzUAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc3NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDkyMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUxMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEyNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgyNgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDczMwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDkwMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc2NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk0NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDExNQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU4NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk5NwAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTM5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODQzAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NDQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MTYAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg3MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYzMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYwMgAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDE4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzU5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODg2AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMjQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMTEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMTcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNDQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxOTQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNjQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyNDQAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ3MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUzMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU0MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE2NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ0MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc1MQ==	AgFwZ19jYXRhbG9nAHRleHQAAAAAGQAAAAIAAAAAAAAARACHBgBQQDIQAAAADAALAKkAAABMAAAAAgAAAAAAAAARWG/+/ZK35ucAAAAAAAAJ+gABAAAADQAAAB9TYW1wbGUgZXJyb3IgbWVzc2FnZTogQVBJX0VSUk9SAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxMTkzbXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDQ2MjFtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTQ2MG1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAyNjAzbXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE1MzFtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMzUwbXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDczOG1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxODM0bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDM4NG1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciAzMDdtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTEyMW1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxNTM5bXM=	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATAAAAAMAAAAAAAACIhhSEIABggJAhBpBAAACAAgAAAAAACQAEQABAAAAAwAAAAdzdWNjZXNzAAAABWVycm9yAAAAB3RpbWVvdXQ=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATAAAAAMAAAAAAAACIizcNWJ5njWEaCOGCImFBfcAAAAAAO384gABAAAABAAAAA1jbGF1ZGUtMy1vcHVzAAAADG1peHRyYWwtOHg3YgAAAApnZW1pbmktcHJvAAAAC2dwdC00LXR1cmJv	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATAAAAAMAAAAAAAACIizcNWJ5njWEaCOGCImFBfcAAAAAAO384gABAAAABAAAAAlhbnRocm9waWMAAAAHbWlzdHJhbAAAAAZnb29nbGUAAAAGb3BlbmFp	BAAAAAAAAAACDgAAAAAAAAELAAAATAAAAA8JqqqaqaqZqgGPViMRN1OSBahDkV4F8RMG3F2id6D25QRyKQnHQKa+BW0uoKEb8aAEuzjh+wE0hACkdHI1WLIYAt4ZcVVH49sCVyfkPzDB5wBSSO5BucjsAmJQ8lIPQR8DRidxxAgwlAHfBOF1N0RTBDFlg+0BwnAAAAAAAA34mQ==	BAAAAAAAAAAAjgAAAAAAAAAJAAAATAAAAA0ACZmZmZmZiQQleg7BFo1kHmF4JgHbQFADHE5mlDQtIAH0b1iWk4g3B4EZPEjCmB4AnFUTy+JBSwTpdzcL1wkxB3CVKxnzmEUB3OQIUpdCQQCo5S+PJFQ6A2FBH4PA0HMDsLcR1YScTAAAAAAAAtkt	BAAAAAAAAAACxAAAAAAAAABqAAAATAAAAA8JmqqpmaqqqgOqHbR1GmHcBaklYOMuQn8Ib4JEzxi1TAFIK1TUWtccAA5qxgUXsgYEukQx0y6CkQdD69yR9CQBDq8AAw6d/ywMPEDhuBbiSAj9XQRDXCKnAZAi0/h6mc4C5zsECRXR7ACIH2QrDiOKDI/Wc0rBgOsAAAAAAATepA==	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAEwAAAACAAAAAAAAABGnkAECbUgZGAAAAAAAAAYFAQAAADMAAAAMAAL//wAAAAYCXRXgAAAADAAC//8AAAAGADYD6AAAAAwAAv//AAAABgIbEfgAAAAMAAL//wAAAAYAPhOIAAAADAAC//8AAAAGAWQQaAAAAAwAAv//AAAABgEFDnQAAAAMAAL//wAAAAYBjQH0AAAADAAC//8AAAAGAGYc6AAAAAwAAv//AAAABgBQB2wAAAAMAAL//wAAAAYAjx7cAAAADAAC//8AAAAGAHwK8AAAAAwAAv//AAAABgCtGWQAAAAMAAL//wAAAAYBWgnEAAAADAAC//8AAAAGAGYRlAAAAAwAAv//AAAABgB2CcQAAAAMAAL//wAAAAYAKwzkAAAADAAC//8AAAAGAuQOdAAAAAwAAv//AAAABgCyFeAAAAAMAAL//wAAAAYA+wwcAAAADAAC//8AAAAGAUYPoAAAAAwAAv//AAAABgFUB2wAAAAMAAL//wAAAAYBegOEAAAADAAC//8AAAAGAWgmSAAAAAwAAv//AAAABgBjGWQAAAAMAAL//wAAAAYAWhlkAAAADAAC//8AAAAGATEdTAAAAAwAAv//AAAABgIoFXwAAAAMAAL//wAAAAYAVhu8AAAADAAC//8AAAAGAVwakAAAAAwAAv//AAAABgBuF9QAAAAMAAL//wAAAAYAJh54AAAADAAC//8AAAAGAF4ZyAAAAAwAAv//AAAABgFTEZQAAAAMAAL//wAAAAYAjQdsAAAADAAC//8AAAAGATgl5AAAAAwAAv//AAAABgDkA+gAAAAMAAL//wAAAAYBQQtUAAAADAAC//8AAAAGAQgR+AAAAAwAAv//AAAABgA0CPwAAAAMAAL//wAAAAYC5xzoAAAADAAC//8AAAAGAMUJYAAAAAwAAv//AAAABgCrGWQAAAAMAAL//wAAAAYAdRH4AAAADAAC//8AAAAGAbwbWAAAAAwAAv//AAAABgHQBXgAAAAMAAL//wAAAAYBcAcIAAAADAAC//8AAAAGAXwlgAAAAAwAAv//AAAABgJLHhQAAAAMAAL//wAAAAYAngDIAAAADAAC//8AAAAGAGsF3AAAAAwAAv//AAAABgEGGvQ=	AgBwZ19jYXRhbG9nAGpzb25iAAAAAEwAAAABAAAAAAAAAA8AAATAAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAEwAAAABAAAAAAAAAA8AAATAAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATAAAAAQAAAAAAAAzMwaYgEikaSIIFEhNxlhQqBwUoggwRImTGgAAABUZESBTAAEAAAAFAAAACHVzZXItMDAzAAAACHVzZXItMDA0AAAACHVzZXItMDAyAAAACHVzZXItMDA1AAAACHVzZXItMDAx
74	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	BAAAAAAAAAADUf////////v+AAAASgAAABG7u6q6u7q7ugAAAAAAAAAKCaBesNiIeOgLLBJNEwoN+QuBAUYHzwUIErwD9woHEHwNxDWIDQsaAQJ8ESgRLwSnELMANBJCE+0Akw0SE4UUtAMCDVss1pHiEcYNnQFmBFUCGAzUGkrTGQJNAlD2s2zxDvMAXAFVAdgStwIxA74QuAmMCGYP6xeUADgHwxKEFYEL5X+EKQJQaQ==	trace-1000-1760582480.663000	trace-995-1760614285.171576	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABKAAAAG3RyYWNlLTE0MC0xNzYwNjU4MDgwLjY2MzAwMAAAABt0cmFjZS0xODgtMTc2MDY1ODA4MC42NjMwMDAAAAAbdHJhY2UtMzQ0LTE3NjA2NTgwODAuNjYzMDAwAAAAG3RyYWNlLTc0Mi0xNzYwNjU3NDg1LjE3MTU3NgAAABt0cmFjZS0zNzItMTc2MDY1MDg4MC42NjMwMDAAAAAbdHJhY2UtMjEzLTE3NjA2NTAyODUuMTcxNTc2AAAAG3RyYWNlLTQ5MS0xNzYwNjQ3MjgwLjY2MzAwMAAAABt0cmFjZS00MjYtMTc2MDY0NjY4NS4xNzE1NzYAAAAbdHJhY2UtNzkxLTE3NjA2NDY2ODUuMTcxNTc2AAAAG3RyYWNlLTgwMC0xNzYwNjQzNjgwLjY2MzAwMAAAABt0cmFjZS04MDktMTc2MDY0MzY4MC42NjMwMDAAAAAbdHJhY2UtOTgxLTE3NjA2NDM2ODAuNjYzMDAwAAAAG3RyYWNlLTY4MC0xNzYwNjQzMDg1LjE3MTU3NgAAABt0cmFjZS00ODktMTc2MDY0MDA4MC42NjMwMDAAAAAadHJhY2UtMTQtMTc2MDYzNjQ4MC42NjMwMDAAAAAadHJhY2UtMzEtMTc2MDYzNTg4NS4xNzE1NzYAAAAbdHJhY2UtNDQ2LTE3NjA2MzI4ODAuNjYzMDAwAAAAG3RyYWNlLTU4MC0xNzYwNjMyODgwLjY2MzAwMAAAABt0cmFjZS02MjUtMTc2MDYzMjg4MC42NjMwMDAAAAAbdHJhY2UtNjM5LTE3NjA2MzIyODUuMTcxNTc2AAAAGnRyYWNlLTgxLTE3NjA2MzIyODUuMTcxNTc2AAAAG3RyYWNlLTI4NS0xNzYwNjI5MjgwLjY2MzAwMAAAABt0cmFjZS04OTMtMTc2MDYyOTI4MC42NjMwMDAAAAAbdHJhY2UtMzAxLTE3NjA2Mjg2ODUuMTcxNTc2AAAAG3RyYWNlLTkwNS0xNzYwNjI4Njg1LjE3MTU3NgAAABt0cmFjZS04MjctMTc2MDYyNTY4MC42NjMwMDAAAAAbdHJhY2UtMTk4LTE3NjA2MjUwODUuMTcxNTc2AAAAG3RyYWNlLTkwNi0xNzYwNjI1MDg1LjE3MTU3NgAAABt0cmFjZS02NDAtMTc2MDYyMjA4MC42NjMwMDAAAAAbdHJhY2UtMjM2LTE3NjA2MjE0ODUuMTcxNTc2AAAAG3RyYWNlLTQ4Mi0xNzYwNjE4NDgwLjY2MzAwMAAAABt0cmFjZS0yMjktMTc2MDYxNzg4NS4xNzE1NzYAAAAbdHJhY2UtNjQ5LTE3NjA2MTQyODUuMTcxNTc2AAAAG3RyYWNlLTk5NS0xNzYwNjE0Mjg1LjE3MTU3NgAAABt0cmFjZS01ODItMTc2MDYxMTI4MC42NjMwMDAAAAAbdHJhY2UtNDUyLTE3NjA2MTA2ODUuMTcxNTc2AAAAG3RyYWNlLTc1Mi0xNzYwNjEwNjg1LjE3MTU3NgAAABt0cmFjZS05NDUtMTc2MDYxMDY4NS4xNzE1NzYAAAAbdHJhY2UtNTIzLTE3NjA2MDc2ODAuNjYzMDAwAAAAG3RyYWNlLTU0Ni0xNzYwNjA3NjgwLjY2MzAwMAAAABt0cmFjZS03NDgtMTc2MDYwNzY4MC42NjMwMDAAAAAbdHJhY2UtMjA3LTE3NjA2MDcwODUuMTcxNTc2AAAAG3RyYWNlLTk0MS0xNzYwNjA3MDg1LjE3MTU3NgAAABt0cmFjZS0yNzgtMTc2MDYwNDA4MC42NjMwMDAAAAAadHJhY2UtMTYtMTc2MDYwMDQ4MC42NjMwMDAAAAAbdHJhY2UtMjc5LTE3NjA2MDA0ODAuNjYzMDAwAAAAG3RyYWNlLTQzOS0xNzYwNjAwNDgwLjY2MzAwMAAAABt0cmFjZS04NjctMTc2MDYwMDQ4MC42NjMwMDAAAAAbdHJhY2UtNjM4LTE3NjA1OTk4ODUuMTcxNTc2AAAAG3RyYWNlLTg0NC0xNzYwNTk5ODg1LjE3MTU3NgAAABt0cmFjZS0xNzMtMTc2MDU5Njg4MC42NjMwMDAAAAAbdHJhY2UtNDgzLTE3NjA1OTY4ODAuNjYzMDAwAAAAG3RyYWNlLTQ5OC0xNzYwNTk2ODgwLjY2MzAwMAAAABt0cmFjZS03NDktMTc2MDU5Njg4MC42NjMwMDAAAAAbdHJhY2UtODI5LTE3NjA1OTY4ODAuNjYzMDAwAAAAG3RyYWNlLTk1NS0xNzYwNTk2ODgwLjY2MzAwMAAAABt0cmFjZS0xNjctMTc2MDU5NjI4NS4xNzE1NzYAAAAbdHJhY2UtNTE5LTE3NjA1OTYyODUuMTcxNTc2AAAAG3RyYWNlLTM1MC0xNzYwNTkzMjgwLjY2MzAwMAAAABt0cmFjZS05MDAtMTc2MDU5MzI4MC42NjMwMDAAAAAadHJhY2UtNTQtMTc2MDU5MjY4NS4xNzE1NzYAAAAbdHJhY2UtMjI2LTE3NjA1ODk2ODAuNjYzMDAwAAAAG3RyYWNlLTM2MC0xNzYwNTg5MDg1LjE3MTU3NgAAABt0cmFjZS01NjktMTc2MDU4OTA4NS4xNzE1NzYAAAAcdHJhY2UtMTAwMC0xNzYwNTgyNDgwLjY2MzAwMAAAABt0cmFjZS02NzgtMTc2MDU4MTg4NS4xNzE1NzYAAAAbdHJhY2UtNzI2LTE3NjA1Nzg4ODAuNjYzMDAwAAAAG3RyYWNlLTc4MC0xNzYwNTc4ODgwLjY2MzAwMAAAABt0cmFjZS04NjItMTc2MDU3ODg4MC42NjMwMDAAAAAbdHJhY2UtODkxLTE3NjA1Nzg4ODAuNjYzMDAwAAAAG3RyYWNlLTkwMS0xNzYwNTc4ODgwLjY2MzAwMAAAABt0cmFjZS0zNzgtMTc2MDU3NTI4MC42NjMwMDAAAAAbdHJhY2UtODc1LTE3NjA1NzUyODAuNjYzMDAwAAAAG3RyYWNlLTg0OS0xNzYwNTc0Njg1LjE3MTU3Ng==	2025-10-16 00:31:25.171576+00	2025-10-16 23:41:20.663+00	BAAAAuQ6gX3veP/////cgYWgAAAASgAAADzu7u3u7u7t7u7u7u7u7e7t7tvu3e7u3u0AAN7s7u7u7gAFyJvYgEuwAAXIm9iAS69G/PS/AAAAAAAAAALMVKZ/AAAAAsxUpoAAAAABHy1efwAAAAEfLV6AAAAAAEb89MAAAAABZipTPwAAAAFmKlNARvz0vwAAAAAAAAABHy1efwAAAABG/PS/AAAAAWYqU0AAAAABHy1efwAAAAFmKlNARvz0vwAAAAAAAAAARvz0wAAAAAFmKlM/AAAAAWYqU0BG/PTARvz0vwAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAFmKlM/AAAAAR8tXoAAAAABHy1efwAAAAEfLV6AAAAAAWYqUz8AAAABrSdIAAAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAFmKlM/AAAAAWYqU0BG/PS/AAAAAAAAAABG/PTAAAAAAWYqUz8AAAAARvz0vwAAAAGtJ0gAAAAAAAAAAABG/PTARvz0vwAAAAFmKlM/AAAAAWYqU0AAAAAAAAAAAEb89MBG/PS/AAAAAWYqUz8AAAABZipTQAAAAABG/PS/AAAAAR8tXn8AAAABHy1egAAAAABG/PTAAAAAAxNRmz8AAAACzFSmgAAAAAEfLV5/AAAAAWYqU0AAAAAAAAAAAAAAAAGtJ0f/AAAAAa0nSAAAAAAARvz0vw==	BAAAAAAAAAAA3f////////5DAAAASgAAABG7uqq6q7q7ugAAAAAAAAAKBVTP9Bi1nC4UYiHHBHgK3AHYC+QfIRCkFU4z9x9WAb4Pc6ctucbl8Qv6FrQmbyIGALYCIyPYMdkGlzMGAcKLwQcdJosQrlrKGQkVvgLtBlMBJTI655dM9AHyd2SZWeFmASRk8/xiDNcQWQEZDVQGVyuaIRUDyhV8HBkN+BquMVEAAAAFrduguA==	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABKAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE0MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxODgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzQ0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc0MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNzIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjEzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ5MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MjYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzkxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgwMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MDkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTgxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY4MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0ODkAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTQAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDQ2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU4MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MjUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjM5AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI4NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4OTMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzAxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkwNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MjcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTk4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkwNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NDAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjM2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ4MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMjkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjQ5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk5NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1ODIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDUyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc1MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NDUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTIzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU0NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NDgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjA3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk0MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNzgAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjc5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQzOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NjcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjM4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg0NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNzMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDgzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ5OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NDkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODI5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk1NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNjcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTE5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM1MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MDAAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjI2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM2MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1NjkAAAAoU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTAwMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NzgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzI2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc4MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NjIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODkxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkwMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNzgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODc1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg0OQ==	AQFwZ19jYXRhbG9nAHRleHQAAQAAAEoAAAACAAAAAAAAABHIDCAgqiCAAQAAAAAAAAKeAQAAADYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxODgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNDQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3NDIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNzIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMTMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0OTEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0MjYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3OTEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MDAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MDkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5ODEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2ODAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0ODkAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ0NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU4MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYyNQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYzOQAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODkzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzAxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTA1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTk4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjQwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDgyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjQ5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTk1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTgyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDUyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzUyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTIzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTQ2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzQ4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjA3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTQxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjc4AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0MzkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NjcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MzgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NDQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0OTgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3NDkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MjkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5NTUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNjcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1MTkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNTAAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDIyNgAAADBTYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEwMDAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4OTEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MDEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NzU=	AgFwZ19jYXRhbG9nAHRleHQAAAAAFAAAAAIAAAAAAAAARJgHZUMAIAEAAAAAAAAAywoAAABKAAAAAgAAAAAAAAARN/Pf31Xff/4AAAAAAAABYQABAAAADQAAAB9TYW1wbGUgZXJyb3IgbWVzc2FnZTogQVBJX0VSUk9SAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciAyMjJtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTgxOG1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxODYwbXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDYyM21zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciAzMzBtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgNTIxbXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDUyNW1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxMTg3bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDQzMjdtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTE1NG1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciAzODRtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMjIxbXM=	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAASgAAAAMAAAAAAAACIhkRWVUVVVVUJZVVpVlVUVUAAAAAAAmUqQABAAAAAwAAAAVlcnJvcgAAAAdzdWNjZXNzAAAAB3RpbWVvdXQ=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAASgAAAAMAAAAAAAACIvMJAT2CBgQUOXHUthyP9fAAAAAAAANbOAABAAAABAAAAAxtaXh0cmFsLTh4N2IAAAAKZ2VtaW5pLXBybwAAAA1jbGF1ZGUtMy1vcHVzAAAAC2dwdC00LXR1cmJv	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAASgAAAAMAAAAAAAACIvMJAT2CBgQUOXHUthyP9fAAAAAAAANbOAABAAAABAAAAAdtaXN0cmFsAAAABmdvb2dsZQAAAAlhbnRocm9waWMAAAAGb3BlbmFp	BAAAAAAAAAABdQAAAAAAAAD1AAAASgAAAA8KqqqZqaqqqgP3IvT6ShKUA8kakxIqVPAFGSyDMmAWHAHGGCEtPRWeAj9F43smAs0A9Ud0xhWwLAg5czRVaHfWAoQ/doJQEJoGbVZ7UmJ1MQtyEWAGxV4qADApVAAYsqUGIWLijSGyXgGUIIFtMNVaBBUB4EgoI38AAAAAAAAE6A==	BAAAAAAAAAAAzAAAAAAAAAB2AAAASgAAAAwAAJmZiZmZmQUJsSIQ5fzgA33KM1Ok3FMGHNwakFS5CwYgGANIEt22AyygDMUALXMEoQJqV2VU2gQhCRJFWDJvPyQhXKcG/JsCpKRkKVohOwMRK3wjGClHAaCuTkoCKNUEaDEfVaQ0SQ==	BAAAAAAAAAABugAAAAAAAAADAAAASgAAAA8KqqqqqqqqqgL6GvDwWtUkBG88Avg2saEBaR9wLysAjwhAQ5A0MdYIACwsoVFNyREBgxRkA0Ij2QRXFSBzFoHCAjMvwIk8dH4AUT9VtlqUMgCGBUGiZdU0B2FHgbcykxoAazMWPnB4CAg/OuIXHKDuBz4Ckust2K4AACwTUj5JXQ==	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAEoAAAACAAAAAAAAABHIDCAgqiCAAQAAAAAAAAKeAQAAADYAAAAMAAL//wAAAAYAXx9AAAAADAAC//8AAAAGAHYe3AAAAAwAAv//AAAABgAnF9QAAAAMAAL//wAAAAYALQXcAAAADAAC//8AAAAGAPEYnAAAAAwAAv//AAAABgA9CigAAAAMAAL//wAAAAYAaiUcAAAADAAC//8AAAAGAUomrAAAAAwAAv//AAAABgC7E4gAAAAMAAL//wAAAAYARRtYAAAADAAC//8AAAAGADkV4AAAAAwAAv//AAAABgE8JqwAAAAMAAL//wAAAAYAdBu8AAAADAAC//8AAAAGADEK8AAAAAwAAv//AAAABgBIG1gAAAAMAAL//wAAAAYA2BBoAAAADAAC//8AAAAGAQEBLAAAAAwAAv//AAAABgB3HtwAAAAMAAL//wAAAAYA+B7cAAAADAAC//8AAAAGACsOEAAAAAwAAv//AAAABgBGGcgAAAAMAAL//wAAAAYAOwrwAAAADAAC//8AAAAGAEMLuAAAAAwAAv//AAAABgFMJRwAAAAMAAL//wAAAAYBahJcAAAADAAC//8AAAAGADIjKAAAAAwAAv//AAAABgB3GcgAAAAMAAL//wAAAAYBliLEAAAADAAC//8AAAAGAesixAAAAAwAAv//AAAABgBEArwAAAAMAAL//wAAAAYBHg88AAAADAAC//8AAAAGASIfpAAAAAwAAv//AAAABgIGINAAAAAMAAL//wAAAAYBcQnEAAAADAAC//8AAAAGAGgZZAAAAAwAAv//AAAABgC5DnQAAAAMAAL//wAAAAYAUQakAAAADAAC//8AAAAGAMgCvAAAAAwAAv//AAAABgBzGQAAAAAMAAL//wAAAAYBGgyAAAAADAAC//8AAAAGAN4QBAAAAAoAAf//AAAABgAtAAAADAAC//8AAAAGAMEfQAAAAAwAAv//AAAABgB+E+wAAAAMAAL//wAAAAYBSxH4AAAADAAC//8AAAAGAJQHbAAAAAwAAv//AAAABgBTB9AAAAAMAAL//wAAAAYBTSPwAAAADAAC//8AAAAGALwHCAAAAAwAAv//AAAABgEDDIAAAAAKAAH//wAAAAYAMQAAAAwAAv//AAAABgJXGDgAAAAMAAL//wAAAAYAgRAEAAAADAAC//8AAAAGAOMFeA==	AgBwZ19jYXRhbG9nAGpzb25iAAAAAEoAAAABAAAAAAAAAA8AAASgAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAEoAAAABAAAAAAAAAA8AAASgAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAASgAAAAQAAAAAAAAzMzTZCSRjbbQIFhlMKOGBFOQ4lAxIZCgYhAAAAAEEkcZLAAEAAAAFAAAACHVzZXItMDAzAAAACHVzZXItMDAyAAAACHVzZXItMDAxAAAACHVzZXItMDA1AAAACHVzZXItMDA0
77	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	BAAAAAAAAAAD0QAAAAAAAABcAAAATQAAABGqqqq7q6qqqwAAAAAAAAAJBBQFRhQBDu4BQADCi5lLHQRvtgRluWubACFP0Bzg720BoC1wQRGFBg1fTAEV0a3DEUEEnACWCfgMVLjVO1rq6A0nAkwLKQf4AMAHdhJjF1wNTpRQkgxgTARFDAUv4m/rB4Zu0+BpGIAOuy6U1ANSEwnzAcCSAy2sBaUjA+MoKYwAAAAAAAAD6g==	trace-100-1760632880.663000	trace-985-1760585485.171576	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABNAAAAG3RyYWNlLTkxMS0xNzYwNjU0NDgwLjY2MzAwMAAAABt0cmFjZS0yNjEtMTc2MDY1MDg4MC42NjMwMDAAAAAbdHJhY2UtMjg2LTE3NjA2NTA4ODAuNjYzMDAwAAAAG3RyYWNlLTgzMy0xNzYwNjUwODgwLjY2MzAwMAAAABt0cmFjZS05NTctMTc2MDY1MDI4NS4xNzE1NzYAAAAbdHJhY2UtMzA3LTE3NjA2NDcyODAuNjYzMDAwAAAAG3RyYWNlLTMzMS0xNzYwNjQ3MjgwLjY2MzAwMAAAABt0cmFjZS0zNjEtMTc2MDY0NzI4MC42NjMwMDAAAAAbdHJhY2UtNTUxLTE3NjA2NDcyODAuNjYzMDAwAAAAG3RyYWNlLTI1NS0xNzYwNjQ2Njg1LjE3MTU3NgAAABt0cmFjZS00NDItMTc2MDY0NjY4NS4xNzE1NzYAAAAadHJhY2UtNjYtMTc2MDY0NjY4NS4xNzE1NzYAAAAbdHJhY2UtMTQ2LTE3NjA2NDM2ODAuNjYzMDAwAAAAG3RyYWNlLTY1OC0xNzYwNjQzNjgwLjY2MzAwMAAAABt0cmFjZS0xOTUtMTc2MDY0MzA4NS4xNzE1NzYAAAAbdHJhY2UtNTMxLTE3NjA2NDMwODUuMTcxNTc2AAAAG3RyYWNlLTg4MS0xNzYwNjQzMDg1LjE3MTU3NgAAABt0cmFjZS01OTItMTc2MDYzOTQ4NS4xNzE1NzYAAAAbdHJhY2UtMjg2LTE3NjA2MzU4ODUuMTcxNTc2AAAAG3RyYWNlLTYyMy0xNzYwNjM1ODg1LjE3MTU3NgAAABt0cmFjZS0xMDAtMTc2MDYzMjg4MC42NjMwMDAAAAAbdHJhY2UtNTQ0LTE3NjA2MzI4ODAuNjYzMDAwAAAAG3RyYWNlLTYyNC0xNzYwNjMyODgwLjY2MzAwMAAAABt0cmFjZS05MTItMTc2MDYzMjg4MC42NjMwMDAAAAAbdHJhY2UtNDM4LTE3NjA2MzIyODUuMTcxNTc2AAAAG3RyYWNlLTY0MS0xNzYwNjMyMjg1LjE3MTU3NgAAABt0cmFjZS03MDUtMTc2MDYzMjI4NS4xNzE1NzYAAAAbdHJhY2UtMzc3LTE3NjA2MjkyODAuNjYzMDAwAAAAG3RyYWNlLTMzNy0xNzYwNjI4Njg1LjE3MTU3NgAAABt0cmFjZS01NzMtMTc2MDYyODY4NS4xNzE1NzYAAAAbdHJhY2UtODg0LTE3NjA2Mjg2ODUuMTcxNTc2AAAAG3RyYWNlLTc4NS0xNzYwNjI1NjgwLjY2MzAwMAAAABt0cmFjZS00NzctMTc2MDYyNTA4NS4xNzE1NzYAAAAbdHJhY2UtNTY1LTE3NjA2MjUwODUuMTcxNTc2AAAAG3RyYWNlLTM4MC0xNzYwNjIyMDgwLjY2MzAwMAAAABt0cmFjZS01MjUtMTc2MDYyMjA4MC42NjMwMDAAAAAbdHJhY2UtMTkxLTE3NjA2MTc4ODUuMTcxNTc2AAAAG3RyYWNlLTQzNS0xNzYwNjE3ODg1LjE3MTU3NgAAABt0cmFjZS02OTktMTc2MDYxNDg4MC42NjMwMDAAAAAbdHJhY2UtNTM0LTE3NjA2MTEyODAuNjYzMDAwAAAAG3RyYWNlLTY2My0xNzYwNjExMjgwLjY2MzAwMAAAABt0cmFjZS0xMDgtMTc2MDYxMDY4NS4xNzE1NzYAAAAbdHJhY2UtNTQzLTE3NjA2MDc2ODAuNjYzMDAwAAAAG3RyYWNlLTYyNC0xNzYwNjA3MDg1LjE3MTU3NgAAABt0cmFjZS02NjAtMTc2MDYwNzA4NS4xNzE1NzYAAAAbdHJhY2UtNzkyLTE3NjA2MDcwODUuMTcxNTc2AAAAG3RyYWNlLTk2Mi0xNzYwNjA3MDg1LjE3MTU3NgAAABt0cmFjZS0yMzEtMTc2MDYwNDA4MC42NjMwMDAAAAAbdHJhY2UtNTczLTE3NjA2MDQwODAuNjYzMDAwAAAAG3RyYWNlLTcyOC0xNzYwNjAzNDg1LjE3MTU3NgAAABt0cmFjZS01ODYtMTc2MDYwMDQ4MC42NjMwMDAAAAAbdHJhY2UtNDA2LTE3NjA1OTk4ODUuMTcxNTc2AAAAGnRyYWNlLTM3LTE3NjA1OTMyODAuNjYzMDAwAAAAGXRyYWNlLTQtMTc2MDU5MzI4MC42NjMwMDAAAAAadHJhY2UtNjctMTc2MDU5MzI4MC42NjMwMDAAAAAbdHJhY2UtNTgzLTE3NjA1OTI2ODUuMTcxNTc2AAAAG3RyYWNlLTE4Ny0xNzYwNTg5NjgwLjY2MzAwMAAAABt0cmFjZS05NTAtMTc2MDU4OTA4NS4xNzE1NzYAAAAbdHJhY2UtMjA5LTE3NjA1ODYwODAuNjYzMDAwAAAAG3RyYWNlLTU4MS0xNzYwNTg1NDg1LjE3MTU3NgAAABt0cmFjZS05MTYtMTc2MDU4NTQ4NS4xNzE1NzYAAAAbdHJhY2UtOTg1LTE3NjA1ODU0ODUuMTcxNTc2AAAAGnRyYWNlLTI3LTE3NjA1ODI0ODAuNjYzMDAwAAAAG3RyYWNlLTY4Ny0xNzYwNTgyNDgwLjY2MzAwMAAAABt0cmFjZS05NzQtMTc2MDU4MjQ4MC42NjMwMDAAAAAbdHJhY2UtMzc1LTE3NjA1ODE4ODUuMTcxNTc2AAAAG3RyYWNlLTUyNi0xNzYwNTgxODg1LjE3MTU3NgAAABt0cmFjZS03MDItMTc2MDU4MTg4NS4xNzE1NzYAAAAbdHJhY2UtOTUxLTE3NjA1ODE4ODUuMTcxNTc2AAAAG3RyYWNlLTIxNC0xNzYwNTc4ODgwLjY2MzAwMAAAABt0cmFjZS0yMDMtMTc2MDU3ODI4NS4xNzE1NzYAAAAbdHJhY2UtNDE0LTE3NjA1NzgyODUuMTcxNTc2AAAAG3RyYWNlLTk0Ni0xNzYwNTc4Mjg1LjE3MTU3NgAAABt0cmFjZS05ODAtMTc2MDU3ODI4NS4xNzE1NzYAAAAbdHJhY2UtMjk0LTE3NjA1NzUyODAuNjYzMDAwAAAAG3RyYWNlLTg4NS0xNzYwNTc0Njg1LjE3MTU3NgAAABt0cmFjZS05NzctMTc2MDU3NDY4NS4xNzE1NzY=	2025-10-16 00:31:25.171576+00	2025-10-16 22:41:20.663+00	BAAAAuQ6gX3veAAAAAAAAAAAAAAATQAAAEDu7t7u3e7e7u7u7u7e7t3u7e7u7u7e7u7e7t7u3e7e7gAFyJorWQOwAAXIm9iAS68AAAABrSdIAEb89L8AAAAAAAAAAR8tXn8AAAABZipTQAAAAAAAAAAARvz0wEb89L8AAAAAAAAAAAAAAAFmKlM/AAAAAWYqU0BG/PTARvz0vwAAAAAAAAAAAAAAAa0nR/8AAAAAAAAAAAAAAAGtJ0gAAAAAAWYqUz8AAAABZipTQAAAAAAAAAAARvz0wEb89L8AAAAAAAAAAAAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAFmKlM/AAAAAWYqU0AAAAAB9CQ8vwAAAAH0JDzAAAAAAWYqUz8AAAAARvz0vwAAAAGtJ0gAAAAAAEb89L8AAAABHy1efwAAAAEfLV6AAAAAAEb89MAAAAAAAAAAAAAAAAFmKlM/AAAAAWYqU0AAAAAARvz0vwAAAAEfLV5/AAAAAR8tXoAAAAACzFSmfwAAAAMTUZtARvz0vwAAAAAAAAABHy1efwAAAAEfLV6AAAAAAR8tXn8AAAABHy1egAAAAABG/PTAAAAAAWYqUz8AAAABZipTQEb89L8AAAAAAAAAAEb89MAAAAAAAAAAAAAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAAAAAAAAAAAAWYqUz8AAAABHy1egAAAAABG/PTA	BAAAAAAAAAAC6P////////3uAAAATQAAABOru6u7ururuwAAAAAAAAq7J34Msw9xD0IbUB+PHXgtCRNKApsLAwA3BqQzt+CKu6MYsA4FA8wC/xUTCV4JihYTDO9hQu40GR4KDhcSLR8dGALYCyYcWwPiDIwDQAqrB5ANhwgIESYbswVIq9hWNRRmGa0RZgxJBw4d6goVB2IO8AS0Fu0yzEBjDpDRVmgMBIIJ8A4vETgVVQGVCIAREQlCAAAAAAAABFs=	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABNAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkxMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNjEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjg2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgzMwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NTcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzA3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMzMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNjEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTUxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI1NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NDIAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTQ2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY1OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxOTUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTMxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg4MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1OTIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjg2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYyMwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMDAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTQ0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYyNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MTIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDM4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY0MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MDUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzc3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMzNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1NzMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODg0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc4NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NzcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTY1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM4MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MjUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTkxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQzNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2OTkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTM0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY2MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMDgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTQzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYyNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NjAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzkyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk2MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTczAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDcyOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1ODYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDA2AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM3AAAAJVNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTgzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE4NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NTAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjA5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU4MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MTYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTg1AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY4NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NzQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzc1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUyNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTUxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIxNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMDMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDE0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk0NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5ODAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjk0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg4NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5Nzc=	AQFwZ19jYXRhbG9nAHRleHQAAQAAAE0AAAACAAAAAAAAABEEdQjJgEMwgAAAAAAAAAmgAQAAADcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MTEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyNjEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyODYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MzMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5NTcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMDcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMzEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1NTEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyNTUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0NDIAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE5NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUzMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI4NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYyMwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEwMAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU0NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDkxMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQzOAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY0MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDcwNQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDM3NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDMzNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU3MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg4NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU2NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDM4MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE5MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQzNQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY2MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEwOAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU0MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY2MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc5MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk2MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDIzMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDcyOAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQwNgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU4MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE4NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk1MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU4MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDkxNgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk4NQAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjg3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTc0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzc1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTI2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzAyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTUxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjAzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTgwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjk0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTc3	AgFwZ19jYXRhbG9nAHRleHQAAAAAFgAAAAIAAAAAAAAARAmAAHBgVDIQAAAAAAAMC6AAAABNAAAAAgAAAAAAAAAR+4r3Nn+8z38AAAAAAAAWXwABAAAADQAAAB9TYW1wbGUgZXJyb3IgbWVzc2FnZTogQVBJX0VSUk9SAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxOTgybXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDk0N21zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA4ODhtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgOTEzbXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDEzMzdtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMjYxbXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE0NDVtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMzc3bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDQ5MG1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciA0NzY3bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE1MzBtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTg3Mm1z	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATQAAAAMAAAAAAAACIkAAIAoKAEAAACAWIQBAYEIAAAAAAEJIAAABAAAAAwAAAAdzdWNjZXNzAAAABWVycm9yAAAAB3RpbWVvdXQ=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATQAAAAMAAAAAAAACIttHN31MmYYQwRAlrSBsnYsAAAAAA9D83AABAAAABAAAAApnZW1pbmktcHJvAAAAC2dwdC00LXR1cmJvAAAADWNsYXVkZS0zLW9wdXMAAAAMbWl4dHJhbC04eDdi	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATQAAAAMAAAAAAAACIttHN31MmYYQwRAlrSBsnYsAAAAAA9D83AABAAAABAAAAAZnb29nbGUAAAAGb3BlbmFpAAAACWFudGhyb3BpYwAAAAdtaXN0cmFs	BAAAAAAAAAABsgAAAAAAAADxAAAATQAAAA4AqqmpqZmamQahsX/jyyZ2DU26GyVtjSgBiFE19lQzhAhUikJAJJYqBzE+O1tZMUQFkL8WI12TawDSax0QoAz/AHYfoRs89CQLsatia0icngV5QmBkJ3CRD4E5Iz46AtYBBx+UGBTScwRAPfSWIRCCAAA0QfEmpJ8=	BAAAAAAAAAAANP////////+4AAAATQAAAA0ACZmZmJmZmQDg/wTCQdy4AggCFwKVLYgBQMIixdCoaQL4Jw0d+klzBNQsEUXB6NsDQCYq0UdN6l/IqyPALHlxA4yUTKea4YkFIiV4F5RQGwCZzYySkBggAeg0d+pIDNwAOAY3lhEsrAAAAAAAV3Ve	BAAAAAAAAAAAof////////4JAAAATQAAAA8KqZqqqqqpqgElDQBtVXS6AC0iZj9KoMQB+RuWcGAsKAGOJFKdesQJBqx9V4pZEVwDkBPyBAWjowK8LcWZa8d/BMhO02oG81cE5TIgIy4k+QVmJNBAFtL+AZIQcuNPxSEKzaRxkraKFQBGl0ieGnCjAJdJlKQk0xQAAIV3PjSSDg==	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAE0AAAACAAAAAAAAABEEdQjJgEMwgAAAAAAAAAmgAQAAADcAAAAMAAL//wAAAAYAaAj8AAAADAAC//8AAAAGAEQOEAAAAAwAAv//AAAABgB2ITQAAAAMAAL//wAAAAYA3h4UAAAADAAC//8AAAAGAncUUAAAAAwAAv//AAAABgHgCPwAAAAMAAL//wAAAAYA0xH4AAAADAAC//8AAAAGAKUBkAAAAAwAAv//AAAABgH+GvQAAAAMAAL//wAAAAYBbCWAAAAADAAC//8AAAAGALIOEAAAAAwAAv//AAAABgBpFwwAAAAMAAL//wAAAAYBghGUAAAADAAC//8AAAAGAFYTiAAAAAwAAv//AAAABgFGGcgAAAAMAAL//wAAAAYATAXcAAAADAAC//8AAAAGAiEixAAAAAwAAv//AAAABgDkE+wAAAAMAAL//wAAAAYAPRAEAAAADAAC//8AAAAGARQB9AAAAAwAAv//AAAABgDQGWQAAAAMAAL//wAAAAYAvxAEAAAADAAC//8AAAAGAGwl5AAAAAwAAv//AAAABgC/GDgAAAAMAAL//wAAAAYA+wj8AAAADAAC//8AAAAGAQMXDAAAAAwAAv//AAAABgA1F3AAAAAMAAL//wAAAAYCIQSwAAAADAAC//8AAAAGACodTAAAAAwAAv//AAAABgDNDtgAAAAMAAL//wAAAAYARwUUAAAADAAC//8AAAAGAXwlHAAAAAwAAv//AAAABgBZBEwAAAAMAAL//wAAAAYAzgSwAAAADAAC//8AAAAGAlMakAAAAAwAAv//AAAABgBpIfwAAAAMAAL//wAAAAYAYQMgAAAADAAC//8AAAAGAY0O2AAAAAwAAv//AAAABgA+IygAAAAMAAL//wAAAAYARhXgAAAADAAC//8AAAAGAFohmAAAAAwAAv//AAAABgB6H6QAAAAMAAL//wAAAAYA2SasAAAADAAC//8AAAAGAKYiYAAAAAwAAv//AAAABgCEI4wAAAAMAAL//wAAAAYAKgu4AAAADAAC//8AAAAGAJ8CWAAAAAwAAv//AAAABgA1HngAAAAMAAL//wAAAAYA9xicAAAADAAC//8AAAAGACQWRAAAAAwAAv//AAAABgBBDzwAAAAMAAL//wAAAAYAWg2sAAAADAAC//8AAAAGAFoNrAAAAAwAAv//AAAABgD+EMwAAAAMAAL//wAAAAYAXQXc	AgBwZ19jYXRhbG9nAGpzb25iAAAAAE0AAAABAAAAAAAAAA8AAATQAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAE0AAAABAAAAAAAAAA8AAATQAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATQAAAAQAAAAAAAAzMyIJILMabTRAABwwqEwENxQSy2CJCkSEIgAAATQgAZRKAAEAAAAFAAAACHVzZXItMDAxAAAACHVzZXItMDAzAAAACHVzZXItMDAyAAAACHVzZXItMDA1AAAACHVzZXItMDA0
70	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	BAAAAAAAAAAAbf////////slAAAARgAAABCrq7uqu6uqqgRtp6jznpviATyGwW2tdhYO2Q0CkSSSZgDyRLAMOU8+BBIEQRDIDW8CxxcAwq/vGQgvD4MUAAXtBRQDsA5dEUgPqwoKDDvRdQDLjqQpfv0AEMsCewZoALURxQQdAgoRRgXtAzQHbRWWAh8xaTHGYLACggL7EVIOCQAAAAAApDM7	trace-109-1760578285.171576	trace-987-1760600480.663000	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABGAAAAG3RyYWNlLTUyMS0xNzYwNjU4MDgwLjY2MzAwMAAAABt0cmFjZS03NzMtMTc2MDY1ODA4MC42NjMwMDAAAAAbdHJhY2UtODc5LTE3NjA2NTc0ODUuMTcxNTc2AAAAG3RyYWNlLTMyNi0xNzYwNjU0NDgwLjY2MzAwMAAAABt0cmFjZS0yMDYtMTc2MDY1MDg4MC42NjMwMDAAAAAbdHJhY2UtODY1LTE3NjA2NTA4ODAuNjYzMDAwAAAAG3RyYWNlLTEzNi0xNzYwNjQ3MjgwLjY2MzAwMAAAABt0cmFjZS0yMjQtMTc2MDY0NjY4NS4xNzE1NzYAAAAbdHJhY2UtMzkwLTE3NjA2NDY2ODUuMTcxNTc2AAAAG3RyYWNlLTcxNC0xNzYwNjQ2Njg1LjE3MTU3NgAAABt0cmFjZS0zNDUtMTc2MDY0MzY4MC42NjMwMDAAAAAbdHJhY2UtNjgzLTE3NjA2NDM2ODAuNjYzMDAwAAAAG3RyYWNlLTY5Mi0xNzYwNjQzNjgwLjY2MzAwMAAAABt0cmFjZS04MDUtMTc2MDY0MzY4MC42NjMwMDAAAAAadHJhY2UtMTctMTc2MDY0MzA4NS4xNzE1NzYAAAAbdHJhY2UtMTgwLTE3NjA2NDMwODUuMTcxNTc2AAAAG3RyYWNlLTgwMS0xNzYwNjQzMDg1LjE3MTU3NgAAABt0cmFjZS00MjgtMTc2MDY0MDA4MC42NjMwMDAAAAAbdHJhY2UtNTA1LTE3NjA2NDAwODAuNjYzMDAwAAAAG3RyYWNlLTcwMy0xNzYwNjQwMDgwLjY2MzAwMAAAABt0cmFjZS0xODEtMTc2MDYzOTQ4NS4xNzE1NzYAAAAbdHJhY2UtODA3LTE3NjA2Mzk0ODUuMTcxNTc2AAAAG3RyYWNlLTg4OC0xNzYwNjM5NDg1LjE3MTU3NgAAABt0cmFjZS00OTAtMTc2MDYzNjQ4MC42NjMwMDAAAAAbdHJhY2UtMTU5LTE3NjA2MzU4ODUuMTcxNTc2AAAAG3RyYWNlLTIzNS0xNzYwNjM1ODg1LjE3MTU3NgAAABt0cmFjZS00MDgtMTc2MDYzNTg4NS4xNzE1NzYAAAAbdHJhY2UtNzY1LTE3NjA2MzU4ODUuMTcxNTc2AAAAG3RyYWNlLTc2Ni0xNzYwNjM1ODg1LjE3MTU3NgAAABl0cmFjZS04LTE3NjA2MzU4ODUuMTcxNTc2AAAAG3RyYWNlLTgxMC0xNzYwNjI5MjgwLjY2MzAwMAAAABt0cmFjZS02MjYtMTc2MDYyNTY4MC42NjMwMDAAAAAbdHJhY2UtMzk0LTE3NjA2MjUwODUuMTcxNTc2AAAAG3RyYWNlLTM3NC0xNzYwNjIyMDgwLjY2MzAwMAAAABt0cmFjZS01MTUtMTc2MDYyMTQ4NS4xNzE1NzYAAAAbdHJhY2UtMTI4LTE3NjA2MTc4ODUuMTcxNTc2AAAAG3RyYWNlLTM5MS0xNzYwNjE3ODg1LjE3MTU3NgAAABt0cmFjZS00NjctMTc2MDYxNzg4NS4xNzE1NzYAAAAadHJhY2UtNjQtMTc2MDYxNzg4NS4xNzE1NzYAAAAbdHJhY2UtOTQ3LTE3NjA2MTc4ODUuMTcxNTc2AAAAG3RyYWNlLTkxMC0xNzYwNjE0ODgwLjY2MzAwMAAAABt0cmFjZS04NjctMTc2MDYxNDI4NS4xNzE1NzYAAAAbdHJhY2UtNDg4LTE3NjA2MTEyODAuNjYzMDAwAAAAGnRyYWNlLTkzLTE3NjA2MTEyODAuNjYzMDAwAAAAG3RyYWNlLTE2NS0xNzYwNjEwNjg1LjE3MTU3NgAAABt0cmFjZS0zNzgtMTc2MDYxMDY4NS4xNzE1NzYAAAAbdHJhY2UtNDg5LTE3NjA2MTA2ODUuMTcxNTc2AAAAG3RyYWNlLTUwOS0xNzYwNjEwNjg1LjE3MTU3NgAAABt0cmFjZS0zNDktMTc2MDYwNDA4MC42NjMwMDAAAAAbdHJhY2UtODcxLTE3NjA2MDQwODAuNjYzMDAwAAAAG3RyYWNlLTI0My0xNzYwNjAzNDg1LjE3MTU3NgAAABt0cmFjZS04MjYtMTc2MDYwMzQ4NS4xNzE1NzYAAAAbdHJhY2UtNjcwLTE3NjA2MDA0ODAuNjYzMDAwAAAAG3RyYWNlLTk4Ny0xNzYwNjAwNDgwLjY2MzAwMAAAABp0cmFjZS0yOS0xNzYwNTk5ODg1LjE3MTU3NgAAABt0cmFjZS04MzQtMTc2MDU5OTg4NS4xNzE1NzYAAAAbdHJhY2UtNjg4LTE3NjA1OTYyODUuMTcxNTc2AAAAG3RyYWNlLTk1Mi0xNzYwNTk2Mjg1LjE3MTU3NgAAABt0cmFjZS00NTctMTc2MDU5MjY4NS4xNzE1NzYAAAAadHJhY2UtNTAtMTc2MDU4OTA4NS4xNzE1NzYAAAAbdHJhY2UtMjMwLTE3NjA1ODYwODAuNjYzMDAwAAAAG3RyYWNlLTIzMy0xNzYwNTg2MDgwLjY2MzAwMAAAABt0cmFjZS02MzEtMTc2MDU4NjA4MC42NjMwMDAAAAAbdHJhY2UtNzU3LTE3NjA1ODYwODAuNjYzMDAwAAAAGnRyYWNlLTg2LTE3NjA1ODU0ODUuMTcxNTc2AAAAG3RyYWNlLTYzMi0xNzYwNTgxODg1LjE3MTU3NgAAABt0cmFjZS03OTYtMTc2MDU4MTg4NS4xNzE1NzYAAAAbdHJhY2UtMjgxLTE3NjA1Nzg4ODAuNjYzMDAwAAAAG3RyYWNlLTM1Mi0xNzYwNTc4ODgwLjY2MzAwMAAAABt0cmFjZS0xMDktMTc2MDU3ODI4NS4xNzE1NzY=	2025-10-16 01:31:25.171576+00	2025-10-16 23:41:20.663+00	BAAAAuQ7WBGTeP/////cgYWgAAAARgAAADXu7d7t7u7u7u7s7u7+ze7d7e3u7e7e7d4AAAAAAA3u7gAFyJvYgEuwAAXIm9iAS68AAAAARvz0vwAAAAEfLV5/AAAAAEb89L8AAAABrSdIAAAAAAGtJ0f/AAAAAWYqU0AAAAAARvz0wAAAAAFmKlM/AAAAAWYqU0AAAAAAAAAAAEb89MBG/PS/AAAAAAAAAAAAAAABZipTPwAAAAFmKlNARvz0vwAAAAAAAAAARvz0wAAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAAAAAAAAAAAAxNRmz8AAAAhZipTQAAAAAEfLV5/AAAAAR8tXoAAAAABZipTPwAAAAGtJ0gAAAAAAAAAAAAAAAABZipTPwAAAAEfLV6AAAAAAR8tXn8AAAABZipTQEb89MBG/PS/AAAAAAAAAAAAAAADE1GbPwAAAAMTUZtARvz0wEb89L8AAAABZipTPwAAAAFmKlNARvz0wEb89L8AAAABrSdH/wAAAAGtJ0gAAAAAAa0nR/9G/PTAAAAAAAAAAAFmKlNAAAAAAAAAAAAAAAAARvz0vwAAAAFmKlM/AAAAAa0nSAAAAAABZipTPwAAAAFmKlNAAAAAAEb89L8=	BAAAAAAAAAAMzwAAAAAAAAvEAAAARgAAABC7uqq7u7uqqgoMhPIhwb2WAyP8r+9u4aUD5SYgqAoU1wEQ6k2fhZySAggahwVeBRwIMAtqET0TNACfApILtBetCWwG2BEjCdwHUQacDZoVKwPCEykWvAsJD66jt0SMtagMbBWXbwakKwShE8NFtU7BE0ICIg9JCqwachBHA/wPdQAAKvAbwQP7	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABGAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUyMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NzMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODc5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMyNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMDYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODY1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDEzNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMjQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzkwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDcxNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNDUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjgzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY5MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MDUAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTgwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgwMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MjgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTA1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDcwMwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxODEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODA3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg4OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0OTAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTU5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIzNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MDgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzY1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc2NgAAACVTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgxMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MjYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzk0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM3NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MTUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTI4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM5MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NjcAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTQ3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkxMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NjcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDg4AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE2NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNzgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDg5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUwOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNDkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODcxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI0MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MjYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjcwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk4NwAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MzQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjg4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk1MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NTcAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjMwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIzMwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzU3AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYzMgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3OTYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjgxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM1MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMDk=	AQFwZ19jYXRhbG9nAHRleHQAAQAAAEYAAAACAAAAAAAAABESASczQmIAAAAAAAAAAAApAQAAADMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1MjEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3NzMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NzkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMjYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMDYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NjUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMzYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMjQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzOTAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3MTQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNDUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2ODMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2OTIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MDUAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE4MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgwMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUwNQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDcwMwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE4MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ5MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE1OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQwOAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc2NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc2NgAAAC1TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MjYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1MTUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMjgAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk0NwAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDkzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTY1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDg5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTA5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODcxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjQzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODI2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjcwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTg3AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MzQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2ODgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0NTcAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDIzMwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYzMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc1NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYzMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc5NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDM1Mg==	AgFwZ19jYXRhbG9nAHRleHQAAAAAEwAAAAIAAAAAAAAARAdlQwIAAAEAAAAAAAAAAAgAAABGAAAAAgAAAAAAAAAR7f7YzL2d//8AAAAAAAAAFgABAAAACQAAAB9TYW1wbGUgZXJyb3IgbWVzc2FnZTogQVBJX0VSUk9SAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxODc2bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDg0MW1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAyNDk4bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE3MDFtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTA3NW1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxMDk4bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDEyNTltcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTkwOW1z	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARgAAAAMAAAAAAAACIhAEJAQAAAAAAQgAAggpCQUAAAAAAAAEQgABAAAAAwAAAAdzdWNjZXNzAAAABWVycm9yAAAAB3RpbWVvdXQ=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARgAAAAMAAAAAAAACIhhvAxxA4moUcGP/R3Np12gAAAAAAAADSQABAAAABAAAAApnZW1pbmktcHJvAAAADWNsYXVkZS0zLW9wdXMAAAAMbWl4dHJhbC04eDdiAAAAC2dwdC00LXR1cmJv	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARgAAAAMAAAAAAAACIhhvAxxA4moUcGP/R3Np12gAAAAAAAADSQABAAAABAAAAAZnb29nbGUAAAAJYW50aHJvcGljAAAAB21pc3RyYWwAAAAGb3BlbmFp	BAAAAAAAAAABnAAAAAAAAACzAAAARgAAAA0ACZmpqaqpqgCXL0YrKUDOA4kUNAQvUaICjLVKDisn8ABJU4Q/FLLyAhhBkpQJ4xED1lR0aEkSyAaM1aON1ImzAPQCNItkInEAfIq37waVNAQbWUCnLlIOB0fAYcK5EYEL/15G3B2K1wAAepmzuQDc	BAAAAAAAAAAA2wAAAAAAAACyAAAARgAAAAsAAAmZmIiZmQMMnCeYsoBYA52KNEujvGoD+GlU1OIAjQG8MmGg1rERfxk51p8HsMP65916B/SjijadZNq7k2AeAcQBNJOS0AsBfOhHRcAwNgbIuS2TMchQAAAAaAzD5SE=	BAAAAAAAAAAC5wAAAAAAAAC6AAAARgAAAA4AmqqqqpqamgEuBnJYSFKkCLFqm1cInGYAQxTzRYUmWwRv/Ddg/cE1Bu6K03o/JPcLNYudnLaSmwYpGUNwLJOIARAN4QQAAgYCnyeB7USk7QDHX0ZJBcJKBmte4/8hga8A70yz0gti+gTpRiFFCOEMAAAAAAAAJz4=	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAEYAAAACAAAAAAAAABESASczQmIAAAAAAAAAAAApAQAAADMAAAAMAAL//wAAAAYASQ2sAAAADAAC//8AAAAGAeMH0AAAAAwAAv//AAAABgGLCPwAAAAMAAL//wAAAAYAbA88AAAADAAC//8AAAAGAFEYnAAAAAwAAv//AAAABgBhE+wAAAAMAAL//wAAAAYAbwBkAAAADAAC//8AAAAGAPUImAAAAAwAAv//AAAABgAtCvAAAAAMAAL//wAAAAYAuwZAAAAADAAC//8AAAAGAFcPoAAAAAwAAv//AAAABgHTBXgAAAAMAAL//wAAAAYAjx4UAAAADAAC//8AAAAGAOQkVAAAAAwAAv//AAAABgDrFRgAAAAMAAL//wAAAAYCDAV4AAAADAAC//8AAAAGAGQdTAAAAAwAAv//AAAABgHJBEwAAAAMAAL//wAAAAYAoSS4AAAADAAC//8AAAAGAcEGQAAAAAwAAv//AAAABgCBJYAAAAAMAAL//wAAAAYCKROIAAAADAAC//8AAAAGAGIc6AAAAAwAAv//AAAABgF+IAgAAAAMAAL//wAAAAYApCZIAAAADAAC//8AAAAGACAe3AAAAAwAAv//AAAABgBjFRgAAAAMAAL//wAAAAYAaxfUAAAADAAC//8AAAAGASUCvAAAAAwAAv//AAAABgFFAZAAAAAMAAL//wAAAAYAiQzkAAAADAAC//8AAAAGAfwl5AAAAAwAAv//AAAABgJCIGwAAAAMAAL//wAAAAYAfiS4AAAADAAC//8AAAAGAV8DIAAAAAwAAv//AAAABgIIGvQAAAAMAAL//wAAAAYAtArwAAAADAAC//8AAAAGAsICvAAAAAwAAv//AAAABgE0FFAAAAAMAAL//wAAAAYB2gj8AAAADAAC//8AAAAGAU8dTAAAAAwAAv//AAAABgIpDIAAAAAMAAL//wAAAAYAwRg4AAAADAAC//8AAAAGAE4KKAAAAAwAAv//AAAABgG6DUgAAAAMAAL//wAAAAYAlB7cAAAADAAC//8AAAAGAlEMgAAAAAwAAv//AAAABgGpF9QAAAAMAAL//wAAAAYALBicAAAADAAC//8AAAAGADIO2AAAAAwAAv//AAAABgI6BXg=	AgBwZ19jYXRhbG9nAGpzb25iAAAAAEYAAAABAAAAAAAAAA8AAARgAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAEYAAAABAAAAAAAAAA8AAARgAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARgAAAAQAAAAAAAAzMxIgBhcTIiaIMARRGFhQBMI4UYyEwgmgigAAAAAAEJiMAAEAAAAFAAAACHVzZXItMDAxAAAACHVzZXItMDA0AAAACHVzZXItMDA1AAAACHVzZXItMDAzAAAACHVzZXItMDAy
\.


--
-- Data for Name: compress_hyper_6_14_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal.compress_hyper_6_14_chunk (_ts_meta_count, workspace_id, agent_id, id, _ts_meta_min_2, _ts_meta_max_2, trace_id, _ts_meta_min_1, _ts_meta_max_1, "timestamp", latency_ms, input, output, error, _ts_meta_min_4, _ts_meta_max_4, status, _ts_meta_min_3, _ts_meta_max_3, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, _ts_meta_min_5, _ts_meta_max_5, tags, _ts_meta_v2_bloom1_user_id, user_id) FROM stdin;
63	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	BAAAAAAAAAADzwAAAAAAAACaAAAAPwAAAA4Aq7uqqqu7ug90hXBzKrU6Gb8ISg5eFNcAOQF0BAUT5BJACMsBJgMJDQ0CkRTaFrcB5qeKhRGJhAFVc4pQ5TKDC5a81BFuBisMZwsZZn+S2gAVXEaJRn3EEMoMpQQ1BOYS7g4LAAUBhQDkAnsKmhIXBJJTEVRpt7Q=	trace-120-1760668285.171576	trace-996-1760743885.171576	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAAA/AAAAG3RyYWNlLTY2OS0xNzYwNzQzODg1LjE3MTU3NgAAABt0cmFjZS05OTYtMTc2MDc0Mzg4NS4xNzE1NzYAAAAbdHJhY2UtMjY1LTE3NjA3NDA4ODAuNjYzMDAwAAAAG3RyYWNlLTQ2Ni0xNzYwNzQwMjg1LjE3MTU3NgAAABt0cmFjZS02NDUtMTc2MDczNzI4MC42NjMwMDAAAAAbdHJhY2UtMTU2LTE3NjA3MzY2ODUuMTcxNTc2AAAAG3RyYWNlLTUwNi0xNzYwNzM2Njg1LjE3MTU3NgAAABt0cmFjZS05MTctMTc2MDczMzY4MC42NjMwMDAAAAAadHJhY2UtMzItMTc2MDczMzA4NS4xNzE1NzYAAAAbdHJhY2UtNjkzLTE3NjA3MzMwODUuMTcxNTc2AAAAG3RyYWNlLTgzOS0xNzYwNzMzMDg1LjE3MTU3NgAAABt0cmFjZS0xNzEtMTc2MDczMDA4MC42NjMwMDAAAAAbdHJhY2UtNDc0LTE3NjA3MzAwODAuNjYzMDAwAAAAG3RyYWNlLTM4OC0xNzYwNzI2NDgwLjY2MzAwMAAAABt0cmFjZS00NDktMTc2MDcyNjQ4MC42NjMwMDAAAAAbdHJhY2UtMzg0LTE3NjA3MjU4ODUuMTcxNTc2AAAAG3RyYWNlLTY1NS0xNzYwNzIyODgwLjY2MzAwMAAAABp0cmFjZS0xOC0xNzYwNzE1MDg1LjE3MTU3NgAAABp0cmFjZS01MC0xNzYwNzEyMDgwLjY2MzAwMAAAABt0cmFjZS03NTMtMTc2MDcxMjA4MC42NjMwMDAAAAAbdHJhY2UtNzg1LTE3NjA3MTE0ODUuMTcxNTc2AAAAGnRyYWNlLTM1LTE3NjA3MDg0ODAuNjYzMDAwAAAAG3RyYWNlLTQyNS0xNzYwNzA4NDgwLjY2MzAwMAAAABt0cmFjZS00NjgtMTc2MDcwNzg4NS4xNzE1NzYAAAAbdHJhY2UtODUxLTE3NjA3MDc4ODUuMTcxNTc2AAAAG3RyYWNlLTQ3Ny0xNzYwNzA0ODgwLjY2MzAwMAAAABt0cmFjZS03ODEtMTc2MDcwNDg4MC42NjMwMDAAAAAbdHJhY2UtMjUxLTE3NjA3MDQyODUuMTcxNTc2AAAAGnRyYWNlLTQxLTE3NjA3MDQyODUuMTcxNTc2AAAAG3RyYWNlLTc1NS0xNzYwNzA0Mjg1LjE3MTU3NgAAABt0cmFjZS0yOTgtMTc2MDcwMTI4MC42NjMwMDAAAAAadHJhY2UtNTEtMTc2MDcwMTI4MC42NjMwMDAAAAAbdHJhY2UtNjg0LTE3NjA3MDEyODAuNjYzMDAwAAAAG3RyYWNlLTc5Ni0xNzYwNzAxMjgwLjY2MzAwMAAAABt0cmFjZS0zOTctMTc2MDcwMDY4NS4xNzE1NzYAAAAbdHJhY2UtNDgxLTE3NjA3MDA2ODUuMTcxNTc2AAAAG3RyYWNlLTkzMC0xNzYwNzAwNjg1LjE3MTU3NgAAABt0cmFjZS0zNTgtMTc2MDY5NzA4NS4xNzE1NzYAAAAbdHJhY2UtOTg5LTE3NjA2OTcwODUuMTcxNTc2AAAAG3RyYWNlLTUzMS0xNzYwNjk0MDgwLjY2MzAwMAAAABt0cmFjZS00ODUtMTc2MDY5MzQ4NS4xNzE1NzYAAAAbdHJhY2UtMjAxLTE3NjA2OTA0ODAuNjYzMDAwAAAAG3RyYWNlLTM1My0xNzYwNjkwNDgwLjY2MzAwMAAAABt0cmFjZS02NjgtMTc2MDY4OTg4NS4xNzE1NzYAAAAbdHJhY2UtNzIxLTE3NjA2ODk4ODUuMTcxNTc2AAAAG3RyYWNlLTc2My0xNzYwNjg5ODg1LjE3MTU3NgAAABt0cmFjZS00MzItMTc2MDY4Njg4MC42NjMwMDAAAAAbdHJhY2UtNTYyLTE3NjA2ODY4ODAuNjYzMDAwAAAAGnRyYWNlLTczLTE3NjA2ODYyODUuMTcxNTc2AAAAG3RyYWNlLTczMy0xNzYwNjg2Mjg1LjE3MTU3NgAAABt0cmFjZS0xOTgtMTc2MDY4MzI4MC42NjMwMDAAAAAbdHJhY2UtNjYwLTE3NjA2ODMyODAuNjYzMDAwAAAAG3RyYWNlLTMyNC0xNzYwNjc5MDg1LjE3MTU3NgAAABt0cmFjZS00MTEtMTc2MDY3NjA4MC42NjMwMDAAAAAbdHJhY2UtMTgyLTE3NjA2NzE4ODUuMTcxNTc2AAAAG3RyYWNlLTMxMC0xNzYwNjcxODg1LjE3MTU3NgAAABt0cmFjZS0xMjAtMTc2MDY2ODI4NS4xNzE1NzYAAAAadHJhY2UtNDQtMTc2MDY2ODI4NS4xNzE1NzYAAAAbdHJhY2UtOTU0LTE3NjA2NjgyODUuMTcxNTc2AAAAGnRyYWNlLTE4LTE3NjA2NjUyODAuNjYzMDAwAAAAG3RyYWNlLTI1Mi0xNzYwNjYxNjgwLjY2MzAwMAAAABt0cmFjZS04MjEtMTc2MDY2MTA4NS4xNzE1NzYAAAAbdHJhY2UtOTc1LTE3NjA2NjEwODUuMTcxNTc2	2025-10-17 00:31:25.171576+00	2025-10-17 23:31:25.171576+00	BAAAAuROn1VPeAAAAAAAAAAAAAAAPwAAADfu7u7e7u7u7u3e7t7t7u7u7e7t7u3u7u4AAAAADe7u7gAFyMPNMhbwAAXIw80yFu8AAAABZipTPwAAAAEfLV6AAAAAAR8tXn8AAAABHy1egAAAAABG/PTAAAAAAWYqUz8AAAABHy1egAAAAABG/PTAAAAAAWYqUz8AAAABZipTQAAAAAGtJ0f/AAAAAa0nSAAAAAAARvz0vwAAAAEfLV5/AAAAAjshMX8AAAACOyExgAAAAAFmKlNAAAAAAEb89L8AAAABHy1efwAAAAFmKlNARvz0wEb89L8AAAABZipTPwAAAAFmKlNARvz0wEb89L8AAAAAAAAAAAAAAAFmKlM/AAAAAWYqU0AAAAAAAAAAAEb89MBG/PS/AAAAAAAAAAAAAAABrSdH/wAAAAGtJ0gAAAAAAWYqUz8AAAABHy1egAAAAAEfLV5/AAAAAWYqU0BG/PTARvz0vwAAAAAAAAAAAAAAAWYqUz8AAAABZipTQEb89MBG/PS/AAAAAWYqUz8AAAABZipTQAAAAAH0JDy/jfnpf4356YAAAAAB9CQ8wAAAAAGtJ0f/AAAAAa0nSAAAAAAAAAAAAAAAAAFmKlM/AAAAAEb89L8AAAABZipTQAAAAABG/PTA	BAAAAAAAAAABH/////////mVAAAAPwAAAA8Ku7q6q6q7qwvFE9IaVxBGA9BJdsoUov0NMwzPEeAHiwqJEVoVvxqsCO5Z2CD6+LAF8D6HkaRGzQy4AakUswARA3qU2GxFtPwCIoQqD8BqeRNhEL4GdwNzBUL2EkY8ip4hGQhUAK4ErgkkEd8SBhFIDQ0OQgtGEaMAAAAAAAAMrw==	AQBwZ19jYXRhbG9nAHRleHQAAAEAAAA/AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY2OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5OTYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjY1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ2NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NDUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTU2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUwNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MTcAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjkzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgzOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDc0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM4OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NDkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzg0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY1NQAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxOAAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NTMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzg1AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQyNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NjgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODUxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ3NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3ODEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjUxAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc1NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyOTgAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjg0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc5NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzOTcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDgxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkzMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNTgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTg5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUzMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0ODUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjAxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM1MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NjgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzIxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc2MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MzIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTYyAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDczAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDczMwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxOTgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjYwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMyNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTgyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMxMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMjAAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTU0AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI1MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MjEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTc1	AQFwZ19jYXRhbG9nAHRleHQAAQAAAD8AAAABAAAAAAAAAAFlCBADigZdAAEAAAAtAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjY5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTk2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjY1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDY2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjQ1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTU2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTA2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTE3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjkzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzg4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzg0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjU1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzUzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzg1AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0MjUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0NjgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NTEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3ODEAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc1NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI5OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDM5NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ4MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDkzMAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDM1OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk4OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUzMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ4NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDIwMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDM1MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY2OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc2MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQzMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU2MgAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDczAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzMzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTk4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzI0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDExAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTgyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzEwAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDQAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxOAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI1Mg==	AgFwZ19jYXRhbG9nAHRleHQAAAAAEgAAAAIAAAAAAAAARLqYFxZUExIQAAAAAAAAANwAAAA/AAAAAQAAAAAAAAABGvfv/HX5ov8AAQAAAA4AAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDExNTJtcwAAAB9TYW1wbGUgZXJyb3IgbWVzc2FnZTogQVBJX0VSUk9SAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAyMDY2bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDk2Mm1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxNjcxbXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE2MDJtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMzc2OW1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA2NjRtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgNTI0bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDIwNDBtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTQ0NG1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA0NzBtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTkzMG1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciAyODdtcw==	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAPwAAAAIAAAAAAAAAIoBEABgSYQAAFBEAQAEAAAkAAQAAAAMAAAAHc3VjY2VzcwAAAAd0aW1lb3V0AAAABWVycm9y	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAPwAAAAIAAAAAAAAAIg6iIzB+4s/kNza7oupQe/QAAQAAAAQAAAALZ3B0LTQtdHVyYm8AAAANY2xhdWRlLTMtb3B1cwAAAAxtaXh0cmFsLTh4N2IAAAAKZ2VtaW5pLXBybw==	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAPwAAAAIAAAAAAAAAIg6iIzB+4s/kNza7oupQe/QAAQAAAAQAAAAGb3BlbmFpAAAACWFudGhyb3BpYwAAAAdtaXN0cmFsAAAABmdvb2dsZQ==	BAAAAAAAAAABMAAAAAAAAABEAAAAPwAAAAwAAKqZqqmamQsxHcRToQUiBrzRuiI5cf0EFjGRHgnQ5Ae3nKFICBQZBdiPGAW0VdoBdB71AD9QFQKHBOILPmN7Ac9AhIsLdG4MkelM46zHJgLBS1OH+MTCAbQlYAxBEnYAAAAAACbEPQ==	BAAAAAAAAAAAxQAAAAAAAABsAAAAPwAAAAsAAAmZmZmZmQMFLAxPsFCMBTGPe4+xpJQC9LmXnnRJKQH8YFFhxISKA7QuANAC1EQFWDgBHrjoRQKVNAbLs4GbAGgdGcfWUQEFfVRf00Q83gG8ZkpNQQioAAAAABwFnMI=	BAAAAAAAAAACKAAAAAAAAABvAAAAPwAAAAwAAJmqqqmqqggieJgIprX+A+4a41dFZysEMCRwvjxG3wECKyK9FuR9Az5IxlRH1HoAnBwQsS5UGgP/JNS8ENFkA64pEF4sNJACATr28HezYgDGMiQRJsHMAaTPDIjymi8NuxXa+0Rwdg==	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAD8AAAABAAAAAAAAAAFlCBADigZdAAEAAAAtAAAADAAC//8AAAAGAk8H0AAAAAwAAv//AAAABgKMA+gAAAAMAAL//wAAAAYAThosAAAADAAC//8AAAAGAGcTJAAAAAwAAv//AAAABgDWCPwAAAAMAAL//wAAAAYAngcIAAAADAAC//8AAAAGAfMZZAAAAAwAAv//AAAABgBkDnQAAAAMAAL//wAAAAYAoQwcAAAADAAC//8AAAAGAG0a9AAAAAwAAv//AAAABgI5DBwAAAAMAAL//wAAAAYCRxJcAAAADAAC//8AAAAGAW4a9AAAAAwAAv//AAAABgA4C1QAAAAMAAL//wAAAAYCRBtYAAAADAAC//8AAAAGACYKKAAAAAwAAv//AAAABgCgAZAAAAAMAAL//wAAAAYAOxMkAAAADAAC//8AAAAGAF4QBAAAAAwAAv//AAAABgBMEsAAAAAMAAL//wAAAAYAOQ88AAAADAAC//8AAAAGAHccIAAAAAwAAv//AAAABgC3CcQAAAAMAAL//wAAAAYAcxBoAAAADAAC//8AAAAGAJEbWAAAAAwAAv//AAAABgB/ASwAAAAMAAL//wAAAAYAOwqMAAAADAAC//8AAAAGAS8F3AAAAAwAAv//AAAABgIkIZgAAAAMAAL//wAAAAYBKwDIAAAADAAC//8AAAAGAjgfQAAAAAwAAv//AAAABgKyA4QAAAAMAAL//wAAAAYAdgOEAAAADAAC//8AAAAGAEIQBAAAAAwAAv//AAAABgBAHOgAAAAMAAL//wAAAAYAIQlgAAAADAAC//8AAAAGAJQmrAAAAAwAAv//AAAABgAhCPwAAAAMAAL//wAAAAYAkRtYAAAADAAC//8AAAAGACsfpAAAAAwAAv//AAAABgCpFXwAAAAMAAL//wAAAAYAPhwgAAAADAAC//8AAAAGASoVfAAAAAwAAv//AAAABgCVA4QAAAAMAAL//wAAAAYAjyUc	AgBwZ19jYXRhbG9nAGpzb25iAAAAAD8AAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAD8AAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAPwAAAAMAAAAAAAADM0SRIRaKZRAAAlMssRNAQxgUEBAUYC0k0AABAAAABQAAAAh1c2VyLTAwNQAAAAh1c2VyLTAwMwAAAAh1c2VyLTAwMQAAAAh1c2VyLTAwMgAAAAh1c2VyLTAwNA==
66	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	BAAAAAAAAAABWv////////7XAAAAQgAAAA8Ju7qquqqrqxDNDD4FYwLsCC8kFbutxDIHiRMaEbsP3gBcVaY7EBCWBrDGzXkfs0YFJHuHzRWn6QLojwvDBgXZA2UNFBMVCpQMawzxxy6CFQeJZqeZM+1MBLGTppNhHP4ZDQgGEDQNWwAQBVIMLRVyAPgPrBe1CQAAAAAAAAoGeQ==	trace-11-1760679085.171576	trace-991-1760719280.663000	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABCAAAAG3RyYWNlLTM3NC0xNzYwNzQzODg1LjE3MTU3NgAAABp0cmFjZS01OC0xNzYwNzQzODg1LjE3MTU3NgAAABt0cmFjZS0zMDktMTc2MDc0MDg4MC42NjMwMDAAAAAbdHJhY2UtNDA5LTE3NjA3NDAyODUuMTcxNTc2AAAAGnRyYWNlLTQ2LTE3NjA3NDAyODUuMTcxNTc2AAAAGnRyYWNlLTczLTE3NjA3MzcyODAuNjYzMDAwAAAAG3RyYWNlLTM2Ni0xNzYwNzMwMDgwLjY2MzAwMAAAABt0cmFjZS0zNzAtMTc2MDczMDA4MC42NjMwMDAAAAAbdHJhY2UtMzI2LTE3NjA3Mjk0ODUuMTcxNTc2AAAAG3RyYWNlLTMxMy0xNzYwNzI2NDgwLjY2MzAwMAAAABp0cmFjZS0zMC0xNzYwNzI1ODg1LjE3MTU3NgAAABt0cmFjZS0xOTItMTc2MDcyMjg4MC42NjMwMDAAAAAbdHJhY2UtMzg5LTE3NjA3MjI4ODAuNjYzMDAwAAAAG3RyYWNlLTY2MS0xNzYwNzIyODgwLjY2MzAwMAAAABt0cmFjZS04MDQtMTc2MDcyMjg4MC42NjMwMDAAAAAbdHJhY2UtMTQ5LTE3NjA3MTkyODAuNjYzMDAwAAAAG3RyYWNlLTE3OS0xNzYwNzE5MjgwLjY2MzAwMAAAABt0cmFjZS0yNTUtMTc2MDcxOTI4MC42NjMwMDAAAAAbdHJhY2UtNzUwLTE3NjA3MTkyODAuNjYzMDAwAAAAG3RyYWNlLTk5MS0xNzYwNzE5MjgwLjY2MzAwMAAAABt0cmFjZS01MDctMTc2MDcxODY4NS4xNzE1NzYAAAAbdHJhY2UtNjEzLTE3NjA3MTg2ODUuMTcxNTc2AAAAG3RyYWNlLTU3NS0xNzYwNzE1NjgwLjY2MzAwMAAAABt0cmFjZS01MjQtMTc2MDcxMjA4MC42NjMwMDAAAAAbdHJhY2UtNjQ2LTE3NjA3MTIwODAuNjYzMDAwAAAAG3RyYWNlLTc2OS0xNzYwNzExNDg1LjE3MTU3NgAAABt0cmFjZS04ODAtMTc2MDcxMTQ4NS4xNzE1NzYAAAAbdHJhY2UtNjQ5LTE3NjA3MDg0ODAuNjYzMDAwAAAAG3RyYWNlLTY2OS0xNzYwNzA4NDgwLjY2MzAwMAAAABt0cmFjZS03MzctMTc2MDcwODQ4MC42NjMwMDAAAAAbdHJhY2UtMjk5LTE3NjA3MDc4ODUuMTcxNTc2AAAAGXRyYWNlLTUtMTc2MDcwNzg4NS4xNzE1NzYAAAAadHJhY2UtODMtMTc2MDcwNzg4NS4xNzE1NzYAAAAbdHJhY2UtNTE1LTE3NjA3MDQ4ODAuNjYzMDAwAAAAG3RyYWNlLTUwNC0xNzYwNzA0Mjg1LjE3MTU3NgAAABt0cmFjZS0xNjctMTc2MDcwMTI4MC42NjMwMDAAAAAbdHJhY2UtMzk1LTE3NjA3MDEyODAuNjYzMDAwAAAAG3RyYWNlLTM1Ni0xNzYwNjk3NjgwLjY2MzAwMAAAABt0cmFjZS02ODktMTc2MDY5NzY4MC42NjMwMDAAAAAbdHJhY2UtNzk0LTE3NjA2OTc2ODAuNjYzMDAwAAAAG3RyYWNlLTc5NS0xNzYwNjk3NjgwLjY2MzAwMAAAABt0cmFjZS0yMDYtMTc2MDY5NzA4NS4xNzE1NzYAAAAbdHJhY2UtMzE5LTE3NjA2OTcwODUuMTcxNTc2AAAAG3RyYWNlLTg0Ny0xNzYwNjk3MDg1LjE3MTU3NgAAABt0cmFjZS00MDItMTc2MDY5MzQ4NS4xNzE1NzYAAAAbdHJhY2UtNzc4LTE3NjA2OTM0ODUuMTcxNTc2AAAAG3RyYWNlLTE4OS0xNzYwNjg2Mjg1LjE3MTU3NgAAABt0cmFjZS0yNjMtMTc2MDY4MzI4MC42NjMwMDAAAAAbdHJhY2UtNTYwLTE3NjA2ODMyODAuNjYzMDAwAAAAGnRyYWNlLTE1LTE3NjA2Nzk2ODAuNjYzMDAwAAAAG3RyYWNlLTY1MS0xNzYwNjc5NjgwLjY2MzAwMAAAABt0cmFjZS02ODYtMTc2MDY3OTY4MC42NjMwMDAAAAAadHJhY2UtMTEtMTc2MDY3OTA4NS4xNzE1NzYAAAAbdHJhY2UtNDEwLTE3NjA2NzkwODUuMTcxNTc2AAAAG3RyYWNlLTgzNi0xNzYwNjc2MDgwLjY2MzAwMAAAABp0cmFjZS01NS0xNzYwNjc1NDg1LjE3MTU3NgAAABp0cmFjZS0xOS0xNzYwNjcyNDgwLjY2MzAwMAAAABt0cmFjZS00MjQtMTc2MDY3MTg4NS4xNzE1NzYAAAAbdHJhY2UtNTEwLTE3NjA2NzE4ODUuMTcxNTc2AAAAG3RyYWNlLTYwNC0xNzYwNjcxODg1LjE3MTU3NgAAABt0cmFjZS04NTAtMTc2MDY2ODg4MC42NjMwMDAAAAAadHJhY2UtNjEtMTc2MDY2ODI4NS4xNzE1NzYAAAAbdHJhY2UtMjc4LTE3NjA2NjQ2ODUuMTcxNTc2AAAAG3RyYWNlLTYxOS0xNzYwNjY0Njg1LjE3MTU3NgAAABt0cmFjZS02NDMtMTc2MDY2NDY4NS4xNzE1NzYAAAAbdHJhY2UtMzQ2LTE3NjA2NjEwODUuMTcxNTc2	2025-10-17 00:31:25.171576+00	2025-10-17 23:31:25.171576+00	BAAAAuROn1VPeP////8pbFwAAAAAQgAAADfu3u7u7u7u7u7u7t3u3u7c7u7t7u7u7t0AAAAADu7u7QAFyMPNMhbwAAXIw80yFu8AAAABZipTPwAAAAEfLV6AAAAAAEb89MAAAAABZipTPwAAAAH0JDy/AAAAA1pOkAAAAAAARvz0vwAAAAEfLV5/AAAAAR8tXoAAAAABHy1efwAAAAFmKlNAAAAAAAAAAAAAAAABrSdH/wAAAAGtJ0gAAAAAAAAAAABG/PTARvz0vwAAAAFmKlM/AAAAAEb89L8AAAABrSdIAEb89MBG/PS/AAAAAWYqUz8AAAABZipTQEb89L8AAAAAAAAAAEb89MAAAAABZipTPwAAAAEfLV6AAAAAAR8tXn8AAAABZipTQAAAAAGtJ0f/AAAAAa0nSAAAAAAAAAAAAEb89MBG/PS/AAAAAAAAAAAAAAABrSdH/wAAAAGtJ0gAAAAAA1pOj/8AAAAB9CQ8wAAAAAFmKlNAAAAAAa0nR/8AAAABrSdIAEb89L8AAAAAAAAAAEb89MAAAAABZipTPwAAAAEfLV6AAAAAAR8tXn8AAAABHy1egAAAAABG/PTAAAAAAWYqUz8AAAABHy1egAAAAAFmKlM/AAAAAa0nSAAAAAAAAAAAAAAAAAGtJ0f/	BAAAAAAAAAADwAAAAAAAAAMiAAAAQgAAAA8Lu6qruru6qgAeugPD/H2mAg9YE9RgbJ8MAyej2Csh4AzeCREBXAkkAZUEHRgQGr8TswzoBtMC/AfsfNQ2OLx2BLkTtitLFAoPdyWaNEUdJgB1BIjrmOYcA/RM5omTRtMGPDQwjgG2Mx6OCKQRQwTAE4Ymoym0Mf8AABAmCU8B0Q==	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABCAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM3NAAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMDkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDA5AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ2AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDczAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM2NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNzAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzI2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMxMwAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxOTIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzg5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY2MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MDQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTQ5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE3OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNTUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzUwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk5MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MDcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjEzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU3NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MjQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjQ2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc2OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4ODAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjQ5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY2OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MzcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjk5AAAAJVNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTE1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUwNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNjcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzk1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM1NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2ODkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzk0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc5NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMDYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzE5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg0NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzc4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE4OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNjMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTYwAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY1MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2ODYAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDEwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgzNgAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1NQAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MjQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTEwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYwNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NTAAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjc4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYxOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NDMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzQ2	AQFwZ19jYXRhbG9nAHRleHQAAQAAAEIAAAACAAAAAAAAABFGQAUKqILpQAAAAAAAAAACAQAAAC4AAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNzQAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDMwOQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQwOQAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ2AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNzAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMTMAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDM4OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE3OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc1MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk5MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUwNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYxMwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU3NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY0NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc2OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg4MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY2OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI5OQAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTA0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzk1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzU2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjg5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzk0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjA2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODQ3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDAyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzc4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTg5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjYzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTYwAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NTEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2ODYAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQxMAAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU1AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MDQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NTAAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYxOQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY0Mw==	AgFwZ19jYXRhbG9nAHRleHQAAAAAFAAAAAIAAAAAAAAARCkodiVDIiIQAAAAAAAAoiIAAABCAAAAAgAAAAAAAAARub/69Vd9Fr8AAAAAAAAAAQABAAAACwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTIzNW1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxMzE2bXMAAAAfU2FtcGxlIGVycm9yIG1lc3NhZ2U6IEFQSV9FUlJPUgAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTU0OW1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxODA0bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE0ODdtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTM4MG1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxNzA2bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDkzMW1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxODY3bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDk2MG1z	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAQgAAAAMAAAAAAAABIkhAQASogRAAICggAAASAEQAAAAAAAAAAgABAAAAAwAAAAdzdWNjZXNzAAAAB3RpbWVvdXQAAAAFZXJyb3I=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAQgAAAAMAAAAAAAACInJt9qM+iCQkiK5Hoz0jSDYAAAAAAAAABwABAAAABAAAAApnZW1pbmktcHJvAAAADWNsYXVkZS0zLW9wdXMAAAALZ3B0LTQtdHVyYm8AAAAMbWl4dHJhbC04eDdi	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAQgAAAAMAAAAAAAACInJt9qM+iCQkiK5Hoz0jSDYAAAAAAAAABwABAAAABAAAAAZnb29nbGUAAAAJYW50aHJvcGljAAAABm9wZW5haQAAAAdtaXN0cmFs	BAAAAAAAAAABI/////////8kAAAAQgAAAA0ACqqqqZmpmgWfHEI8RpLGBUXyW/N8G04M4auxnbivDgL8BiHLN+TvA20AMekIrksGwptlgccRrwJgkqb9SWxxAjVOxEszoaMARiswJEIjMwU/R0BDOfMuAQ4HUiRLFSgGbh3SCwDgTgAAAAAAAAVN	BAAAAAAAAAAAagAAAAAAAAA1AAAAQgAAAAsAAAmZmZmZmQJ8Zh7XaO1eAuh5O5HREAoDEaNJm5ZYlQJQBDRCkbBAAny6KBqUKCEF2DUB1HbAywBxz0qVZ2RRBhQUMoqxjSQCgK02hnE9WgYYsRjE9IjTA5iRFQcTGVk=	BAAAAAAAAAAClQAAAAAAAACYAAAAQgAAAA0ACaqqmaqpqgVBLYHQJnGOAV1aovMZcooFgMNttl3iqQaFlMn7YwHPBGJBtLwuMzIHD1xAwiSzKwJMuVpiQscMAN1vYn0uz2ICKE6o9YUiqwYhS2StTQVtBWkcAg8hd0wAaAFRbCV1WgAAAAAcLybY	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAEIAAAACAAAAAAAAABFGQAUKqILpQAAAAAAAAAACAQAAAC4AAAAMAAL//wAAAAYAQQBkAAAADAAC//8AAAAGAekO2AAAAAwAAv//AAAABgJTBqQAAAAMAAL//wAAAAYA0yOMAAAADAAC//8AAAAGALkgbAAAAAwAAv//AAAABgIFDtgAAAAMAAL//wAAAAYAMgzkAAAACgAB//8AAAAGAZMAAAAMAAL//wAAAAYAkAH0AAAADAAC//8AAAAGARUBkAAAAAwAAv//AAAABgB3IygAAAAMAAL//wAAAAYBOSMoAAAADAAC//8AAAAGAJ4EsAAAAAwAAv//AAAABgCBC7gAAAAMAAL//wAAAAYCWg7YAAAADAAC//8AAAAGACsDhAAAAAwAAv//AAAABgDqGDgAAAAMAAL//wAAAAYANBr0AAAADAAC//8AAAAGAaUOdAAAAAwAAv//AAAABgDSETAAAAAMAAL//wAAAAYAShJcAAAADAAC//8AAAAGAUkI/AAAAAwAAv//AAAABgBkCowAAAAMAAL//wAAAAYA8QZAAAAADAAC//8AAAAGAcEWRAAAAAwAAv//AAAABgCMHbAAAAAMAAL//wAAAAYA/RJcAAAADAAC//8AAAAGAEoVGAAAAAwAAv//AAAABgCLETAAAAAMAAL//wAAAAYCqRGUAAAADAAC//8AAAAGAEkmSAAAAAwAAv//AAAABgAnFeAAAAAMAAL//wAAAAYA7SJgAAAADAAC//8AAAAGAHAgbAAAAAwAAv//AAAABgCHBkAAAAAMAAL//wAAAAYB4QOEAAAADAAC//8AAAAGAjAKjAAAAAwAAv//AAAABgAqFkQAAAAMAAL//wAAAAYA/AakAAAADAAC//8AAAAGAOoa9AAAAAwAAv//AAAABgFRAZAAAAAMAAL//wAAAAYBgiS4AAAADAAC//8AAAAGAGkEsAAAAAwAAv//AAAABgERFwwAAAAMAAL//wAAAAYBhAqMAAAADAAC//8AAAAGAH8EsA==	AgBwZ19jYXRhbG9nAGpzb25iAAAAAEIAAAABAAAAAAAAAA8AAAQgAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAEIAAAABAAAAAAAAAA8AAAQgAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAQgAAAAQAAAAAAAAjMyEKUIbaEDKINxhSNEBlQMNIQkmgwgGCogAAAAAAAAAIAAEAAAAFAAAACHVzZXItMDAxAAAACHVzZXItMDA0AAAACHVzZXItMDAzAAAACHVzZXItMDAyAAAACHVzZXItMDA1
45	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	BAAAAAAAAAADtAAAAAAAAAN/AAAALQAAAAsAAAqqu6u6uxlmEY0EOQlMCLIFRQy+GG0BfXHcPGLzRwheASELCgbHABUCPwzyFSsO2Vrym+kl0QL5AAUERRQiBtYM4hIrCIQANSLlIQwndQYEitDhOpYSAAAAAAAACb4=	trace-105-1760701280.663000	trace-982-1760715680.663000	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAAAtAAAAG3RyYWNlLTE5MC0xNzYwNzQ0NDgwLjY2MzAwMAAAABt0cmFjZS04MzktMTc2MDc0NDQ4MC42NjMwMDAAAAAbdHJhY2UtMjQxLTE3NjA3NDAyODUuMTcxNTc2AAAAG3RyYWNlLTg5NC0xNzYwNzM3MjgwLjY2MzAwMAAAABt0cmFjZS00MjAtMTc2MDcyOTQ4NS4xNzE1NzYAAAAbdHJhY2UtNTc3LTE3NjA3Mjk0ODUuMTcxNTc2AAAAGnRyYWNlLTU5LTE3NjA3Mjk0ODUuMTcxNTc2AAAAG3RyYWNlLTY1NC0xNzYwNzI5NDg1LjE3MTU3NgAAABt0cmFjZS04MjktMTc2MDcyOTQ4NS4xNzE1NzYAAAAbdHJhY2UtMjEyLTE3NjA3MjU4ODUuMTcxNTc2AAAAG3RyYWNlLTE2MS0xNzYwNzIyODgwLjY2MzAwMAAAABt0cmFjZS0xOTktMTc2MDcyMjg4MC42NjMwMDAAAAAadHJhY2UtNDYtMTc2MDcyMjg4MC42NjMwMDAAAAAadHJhY2UtMjUtMTc2MDcyMjI4NS4xNzE1NzYAAAAbdHJhY2UtNDE3LTE3NjA3MjIyODUuMTcxNTc2AAAAG3RyYWNlLTY2NC0xNzYwNzIyMjg1LjE3MTU3NgAAABt0cmFjZS05ODItMTc2MDcxNTY4MC42NjMwMDAAAAAbdHJhY2UtNTkwLTE3NjA3MTUwODUuMTcxNTc2AAAAG3RyYWNlLTg1NS0xNzYwNzE1MDg1LjE3MTU3NgAAABt0cmFjZS04MzItMTc2MDcxMTQ4NS4xNzE1NzYAAAAbdHJhY2UtNzk4LTE3NjA3MDc4ODUuMTcxNTc2AAAAGnRyYWNlLTE5LTE3NjA3MDQyODUuMTcxNTc2AAAAG3RyYWNlLTEwNS0xNzYwNzAxMjgwLjY2MzAwMAAAABt0cmFjZS04NTctMTc2MDcwMTI4MC42NjMwMDAAAAAbdHJhY2UtODgxLTE3NjA3MDEyODAuNjYzMDAwAAAAGXRyYWNlLTQtMTc2MDcwMDY4NS4xNzE1NzYAAAAbdHJhY2UtNzA0LTE3NjA3MDA2ODUuMTcxNTc2AAAAG3RyYWNlLTg1Ny0xNzYwNjk3MDg1LjE3MTU3NgAAABl0cmFjZS03LTE3NjA2OTA0ODAuNjYzMDAwAAAAG3RyYWNlLTc3Ni0xNzYwNjg5ODg1LjE3MTU3NgAAABt0cmFjZS02MzUtMTc2MDY4Njg4MC42NjMwMDAAAAAbdHJhY2UtMTY4LTE3NjA2ODI2ODUuMTcxNTc2AAAAG3RyYWNlLTM1MC0xNzYwNjgyNjg1LjE3MTU3NgAAABt0cmFjZS00MDctMTc2MDY3NjA4MC42NjMwMDAAAAAbdHJhY2UtNTA5LTE3NjA2NzYwODAuNjYzMDAwAAAAG3RyYWNlLTcwOC0xNzYwNjc2MDgwLjY2MzAwMAAAABt0cmFjZS0yNTAtMTc2MDY3MjQ4MC42NjMwMDAAAAAadHJhY2UtNzEtMTc2MDY3MjQ4MC42NjMwMDAAAAAbdHJhY2UtODY1LTE3NjA2NzE4ODUuMTcxNTc2AAAAG3RyYWNlLTQzNi0xNzYwNjY1MjgwLjY2MzAwMAAAABt0cmFjZS01MzgtMTc2MDY2NTI4MC42NjMwMDAAAAAbdHJhY2UtNTI3LTE3NjA2NjE2ODAuNjYzMDAwAAAAG3RyYWNlLTQwNS0xNzYwNjYxMDg1LjE3MTU3NgAAABp0cmFjZS01My0xNzYwNjYxMDg1LjE3MTU3NgAAABt0cmFjZS05NDgtMTc2MDY2MTA4NS4xNzE1NzY=	2025-10-17 00:31:25.171576+00	2025-10-17 23:41:20.663+00	BAAAAuROn1VPeAAAAAAAAAAAAAAALQAAACbu7t3u7O7u7u7u7u7u7t7tAAAAAADe7u4ABcjEFC8LsAAFyMQULwuvAAAAAfQkPL8AAAAAjfnpgAAAAAI7ITF/AAAAA6FLhMAAAAAAAAAAAAAAAAGtJ0f/AAAAAEb89MAAAAABZipTQEb89L8AAAAAAAAAAEb89MAAAAADE1GbPwAAAALMVKaAAAAAAEb89MAAAAABrSdH/wAAAAAAAAAAAAAAAEb89MAAAAABZipTQEb89L8AAAAAAAAAAEb89MAAAAABrSdH/wAAAAFmKlM/AAAAAsxUpoAAAAABHy1efwAAAACN+el/AAAAAfQkPMAAAAADE1GbPwAAAAMTUZtAAAAAAAAAAAAAAAABrSdH/wAAAAGtJ0gAAAAAAEb89L8AAAACzFSmfwAAAAMTUZtAAAAAAa0nR/8AAAABZipTQAAAAABG/PTA	BAAAAAAAAAADDv////////yBAAAALQAAAAoAAACrurq7qgksGGddGJTUCAyBkcALhnciXQmuCpQF1w9DDwYFGRC0CJbnM8xCA/ANkBALCUIAlw0VDXncR63fFUEITgWIA5IHjBOHBvwN7Ay/uwbbcZpK	AQBwZ19jYXRhbG9nAHRleHQAAAEAAAAtAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE5MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MzkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjQxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg5NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MjAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTc3AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY1NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MjkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjEyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE2MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxOTkAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDYAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDE3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY2NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5ODIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTkwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg1NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MzIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzk4AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDEwNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NTcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODgxAAAAJVNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzA0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg1NwAAACVTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc3NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MzUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTY4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM1MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MDcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTA5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDcwOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNTAAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODY1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQzNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MzgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTI3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQwNQAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NDg=	AQFwZ19jYXRhbG9nAHRleHQAAQAAAC0AAAABAAAAAAAAAAEAAAg0EoIjAAEAAAAiAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTkwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODM5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjQxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODk0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDIwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTc3AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NTQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNjEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxOTkAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQxNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY2NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk4MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg1NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgzMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc5OAAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTA1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODgxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzA0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODU3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzc2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjM1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTY4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzUwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDA3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzA4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODY1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDM2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTM4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTI3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDA1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTQ4	AgFwZ19jYXRhbG9nAHRleHQAAAAACwAAAAEAAAAAAAAAAwAAAAEAYAQIAAAALQAAAAEAAAAAAAAAAQAAF8vtfdz/AAEAAAAFAAAAH1NhbXBsZSBlcnJvciBtZXNzYWdlOiBBUElfRVJST1IAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDExMjhtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTE3MG1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxOTMxbXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE2Nzdtcw==	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAALQAAAAIAAAAAAAAAIgEEQAgECQAAAAAAAACABSAAAQAAAAMAAAAHc3VjY2VzcwAAAAVlcnJvcgAAAAd0aW1lb3V0	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAALQAAAAIAAAAAAAAAIj6H8Z+7UljkAAAAAAAsWrQAAQAAAAQAAAALZ3B0LTQtdHVyYm8AAAAKZ2VtaW5pLXBybwAAAA1jbGF1ZGUtMy1vcHVzAAAADG1peHRyYWwtOHg3Yg==	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAALQAAAAIAAAAAAAAAIj6H8Z+7UljkAAAAAAAsWrQAAQAAAAQAAAAGb3BlbmFpAAAABmdvb2dsZQAAAAlhbnRocm9waWMAAAAHbWlzdHJhbA==	BAAAAAAAAAABTgAAAAAAAAELAAAALQAAAAgAAAAAqZmZqgIbL4THFsFaBM5mNDQMQAQB9GkVwDS7LwF4TqI8FGl8Cr7casbhic0NYeWZVYK5rADApyIdhk0dBbJsE/APwj0=	BAAAAAAAAAAAbP/////////xAAAALQAAAAgAAAAAmZmZmQS5FT+AJl0uAoAIDgWEhBcEneh2RUeKIwSFSBoPs3gEA+RlOYPQMFsBiPohwDZWPAIEHggKMPBlAAAAAAAjtVo=	BAAAAAAAAAAB7v////////+oAAAALQAAAAkAAAAKqaqqmgBgABCdOXQMC4TX9pfem1EGPAsFsVkhowHbB7TEPNPVAd04pTlxomEA/DaoP43kyQUJ8gm60T1yBgt4xokKoA0AAAAEhz1jJA==	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAC0AAAABAAAAAAAAAAEAAAg0EoIjAAEAAAAiAAAADAAC//8AAAAGAjglHAAAAAwAAv//AAAABgBCEZQAAAAMAAL//wAAAAYBVxwgAAAADAAC//8AAAAGAHAa9AAAAAwAAv//AAAABgI+AZAAAAAMAAL//wAAAAYBQCDQAAAADAAC//8AAAAGAPgD6AAAAAwAAv//AAAABgDKCWAAAAAMAAL//wAAAAYAaxzoAAAADAAC//8AAAAGAMEZyAAAAAwAAv//AAAABgA8EsAAAAAMAAL//wAAAAYASAj8AAAADAAC//8AAAAGAfEMgAAAAAwAAv//AAAABgBJF9QAAAAMAAL//wAAAAYAgyRUAAAACgAB//8AAAAGAeAAAAAMAAL//wAAAAYA7iMoAAAADAAC//8AAAAGAgYDIAAAAAwAAv//AAAABgB3EMwAAAAMAAL//wAAAAYAIA50AAAADAAC//8AAAAGAXMPoAAAAAwAAv//AAAABgFpDUgAAAAMAAL//wAAAAYAHyLEAAAADAAC//8AAAAGAFIINAAAAAwAAv//AAAABgG+IfwAAAAMAAL//wAAAAYBoiOMAAAADAAC//8AAAAGAK8FFAAAAAwAAv//AAAABgGYJkgAAAAMAAL//wAAAAYArx54AAAADAAC//8AAAAGAF0GpAAAAAwAAv//AAAABgCAJFQAAAAMAAL//wAAAAYAXRRQAAAADAAC//8AAAAGAhAPoAAAAAwAAv//AAAABgInFXw=	AgBwZ19jYXRhbG9nAGpzb25iAAAAAC0AAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAC0AAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAALQAAAAMAAAAAAAADMyBcRZCSBQaIFsiSMBxiQMQAAAAAAAAAoQABAAAABQAAAAh1c2VyLTAwMQAAAAh1c2VyLTAwNQAAAAh1c2VyLTAwNAAAAAh1c2VyLTAwMwAAAAh1c2VyLTAwMg==
54	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	BAAAAAAAAAAB2AAAAAAAAAECAAAANgAAAA0ACrq7u7qquxDeETcDdQi6BlAP8BObAkgGHiLI/VoNFQHNBHYiQrBzBxhARYPFSokBFxFMCrsIPQPmAiMOrBC/EwIC5QaxBA0V2BlrGDYVBwRBAVkPhBWpCTdDDxT9Ff4DyBCIEu0E+AAAAAAAdSp1	trace-105-1760722285.171576	trace-997-1760668880.663000	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAAA2AAAAG3RyYWNlLTExNy0xNzYwNzQ0NDgwLjY2MzAwMAAAABt0cmFjZS03OTEtMTc2MDc0NDQ4MC42NjMwMDAAAAAbdHJhY2UtMjYxLTE3NjA3NDM4ODUuMTcxNTc2AAAAG3RyYWNlLTg5MC0xNzYwNzQzODg1LjE3MTU3NgAAABt0cmFjZS04MTEtMTc2MDc0MDg4MC42NjMwMDAAAAAbdHJhY2UtMjIyLTE3NjA3NDAyODUuMTcxNTc2AAAAG3RyYWNlLTY3My0xNzYwNzQwMjg1LjE3MTU3NgAAABt0cmFjZS05MzItMTc2MDczNzI4MC42NjMwMDAAAAAbdHJhY2UtNTE2LTE3NjA3MzM2ODAuNjYzMDAwAAAAG3RyYWNlLTgyMC0xNzYwNzMzNjgwLjY2MzAwMAAAABt0cmFjZS05NzMtMTc2MDczMzA4NS4xNzE1NzYAAAAbdHJhY2UtNDA0LTE3NjA3Mjk0ODUuMTcxNTc2AAAAG3RyYWNlLTYxOC0xNzYwNzI5NDg1LjE3MTU3NgAAABt0cmFjZS03NzQtMTc2MDcyOTQ4NS4xNzE1NzYAAAAbdHJhY2UtMzk2LTE3NjA3MjU4ODUuMTcxNTc2AAAAG3RyYWNlLTgwMy0xNzYwNzI1ODg1LjE3MTU3NgAAABt0cmFjZS0xNzQtMTc2MDcyMjg4MC42NjMwMDAAAAAbdHJhY2UtMzE0LTE3NjA3MjI4ODAuNjYzMDAwAAAAG3RyYWNlLTEwNS0xNzYwNzIyMjg1LjE3MTU3NgAAABt0cmFjZS00NzQtMTc2MDcyMjI4NS4xNzE1NzYAAAAbdHJhY2UtMTM3LTE3NjA3MTg2ODUuMTcxNTc2AAAAG3RyYWNlLTMxNC0xNzYwNzE4Njg1LjE3MTU3NgAAABt0cmFjZS0zOTktMTc2MDcxMjA4MC42NjMwMDAAAAAbdHJhY2UtNDI5LTE3NjA3MTIwODAuNjYzMDAwAAAAGnRyYWNlLTg1LTE3NjA3MTE0ODUuMTcxNTc2AAAAG3RyYWNlLTk1NS0xNzYwNzExNDg1LjE3MTU3NgAAABt0cmFjZS02ODUtMTc2MDcwODQ4MC42NjMwMDAAAAAbdHJhY2UtMjcxLTE3NjA3MDc4ODUuMTcxNTc2AAAAG3RyYWNlLTczNS0xNzYwNzA3ODg1LjE3MTU3NgAAABt0cmFjZS05MjUtMTc2MDcwNzg4NS4xNzE1NzYAAAAbdHJhY2UtNjE0LTE3NjA3MDQ4ODAuNjYzMDAwAAAAG3RyYWNlLTc4NC0xNzYwNzA0ODgwLjY2MzAwMAAAABp0cmFjZS05Ny0xNzYwNzA0ODgwLjY2MzAwMAAAABp0cmFjZS0zOS0xNzYwNzA0Mjg1LjE3MTU3NgAAABt0cmFjZS00MTQtMTc2MDcwMTI4MC42NjMwMDAAAAAadHJhY2UtOTctMTc2MDcwMDY4NS4xNzE1NzYAAAAbdHJhY2UtODc5LTE3NjA2OTc2ODAuNjYzMDAwAAAAG3RyYWNlLTQwNy0xNzYwNjk3MDg1LjE3MTU3NgAAABt0cmFjZS03MzEtMTc2MDY5MDQ4MC42NjMwMDAAAAAbdHJhY2UtMjgyLTE3NjA2ODk4ODUuMTcxNTc2AAAAG3RyYWNlLTgxOS0xNzYwNjg5ODg1LjE3MTU3NgAAABt0cmFjZS0xODMtMTc2MDY4Njg4MC42NjMwMDAAAAAZdHJhY2UtMi0xNzYwNjg2ODgwLjY2MzAwMAAAABt0cmFjZS01ODgtMTc2MDY4Njg4MC42NjMwMDAAAAAbdHJhY2UtMTQ5LTE3NjA2ODI2ODUuMTcxNTc2AAAAG3RyYWNlLTY0MC0xNzYwNjgyNjg1LjE3MTU3NgAAABt0cmFjZS02NjctMTc2MDY3OTY4MC42NjMwMDAAAAAbdHJhY2UtNTE0LTE3NjA2Njg4ODAuNjYzMDAwAAAAG3RyYWNlLTk5Ny0xNzYwNjY4ODgwLjY2MzAwMAAAABp0cmFjZS01Ny0xNzYwNjY4Mjg1LjE3MTU3NgAAABt0cmFjZS0yMzMtMTc2MDY2NDY4NS4xNzE1NzYAAAAbdHJhY2UtODkzLTE3NjA2NjQ2ODUuMTcxNTc2AAAAG3RyYWNlLTIxNC0xNzYwNjYxMDg1LjE3MTU3NgAAABt0cmFjZS00NzItMTc2MDY2MTA4NS4xNzE1NzY=	2025-10-17 00:31:25.171576+00	2025-10-17 23:41:20.663+00	BAAAAuROn1VPeAAAAAAAAAAAAAAANgAAADHu7u7u7u7t7u7t7t7t7u7e7u7u7u7u7u4AAAAAAAAADgAFyMQULwuwAAXIxBQvC69G/PTARvz0vwAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAFmKlM/AAAAAEb89L8AAAABrSdIAAAAAABG/PS/AAAAAWYqUz8AAAABrSdIAAAAAAAAAAAAAAAAAa0nR/8AAAABrSdIAAAAAAFmKlM/AAAAAWYqU0BG/PTARvz0vwAAAAGtJ0f/AAAAAa0nSAAAAAADE1GbPwAAAAMTUZtARvz0wEb89L8AAAABZipTPwAAAAEfLV6AAAAAAEb89MAAAAABZipTPwAAAAFmKlNARvz0vwAAAAAAAAABHy1efwAAAAEfLV6AAAAAAR8tXn8AAAABHy1egAAAAALMVKZ/AAAAAsxUpoAAAAAARvz0wAAAAAFmKlM/AAAAAWYqU0AAAAAAAAAAAAAAAAH0JDy/AAAAAfQkPMAAAAABZipTPwAAAAOhS4S/AAAABQd12AAAAAAARvz0vwAAAAFmKlM/AAAAAa0nSAAAAAABrSdH/wAAAAGtJ0gA	BAAAAAAAAAACcv////////7HAAAANgAAAA0ACrurururuw8hA6EBygT6DhQLxwbvFgoI+RDQDHsC8Qso2/tuWHMWBnsZ0CPPDDYPyBSbD4oGrwoneeTgbbMDGV0UJgjpBxANmgkbCssT+gKMZ00bzkibG68RgAadAVMHkADbE5EdLAAAAADujZQg	AQBwZ19jYXRhbG9nAHRleHQAAAEAAAA2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDExNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3OTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjYxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg5MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjIyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY3MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MzIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTE2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgyMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NzMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDA0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYxOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NzQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzk2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgwMwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNzQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzE0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDEwNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NzQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTM3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMxNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzOTkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDI5AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk1NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2ODUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjcxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDczNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MjUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjE0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc4NAAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NwAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MTQAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODc5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQwNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjgyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgxOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxODMAAAAlU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1ODgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTQ5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY0MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NjcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTE0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk5NwAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMzMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODkzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIxNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NzI=	AQFwZ19jYXRhbG9nAHRleHQAAQAAADYAAAABAAAAAAAAAAEAAMCUCwWjBAEAAAAnAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTE3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzkxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODkwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODExAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjIyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjczAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTMyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTczAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDA0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjE4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzk2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzE0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDc0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTM3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzE0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzk5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDI5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjg1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzM1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTI1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjE0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzg0AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTcAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzOQAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDA3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzMxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODE5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTgzAAAALVNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU4OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE0OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY0MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk5NwAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjMzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODkzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjE0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDcy	AgFwZ19jYXRhbG9nAHRleHQAAAAADwAAAAEAAAAAAAAAAwAAC6WSsaSIAAAANgAAAAEAAAAAAAAAAQA/P2v0+lz7AAEAAAAIAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxOTA0bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE5NDRtcwAAAB9TYW1wbGUgZXJyb3IgbWVzc2FnZTogQVBJX0VSUk9SAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxMjgybXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDg5OG1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA5NTVtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMjAxNm1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciAxNTdtcw==	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAANgAAAAIAAAAAAAAAIgCJABGICQAQAAAAAJAAghAAAQAAAAMAAAAHc3VjY2VzcwAAAAd0aW1lb3V0AAAABWVycm9y	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAANgAAAAIAAAAAAAAAIvCp9q5ewbjkAAAKfCYvtD8AAQAAAAQAAAAKZ2VtaW5pLXBybwAAAAtncHQtNC10dXJibwAAAAxtaXh0cmFsLTh4N2IAAAANY2xhdWRlLTMtb3B1cw==	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAANgAAAAIAAAAAAAAAIvCp9q5ewbjkAAAKfCYvtD8AAQAAAAQAAAAGZ29vZ2xlAAAABm9wZW5haQAAAAdtaXN0cmFsAAAACWFudGhyb3BpYw==	BAAAAAAAAAABgQAAAAAAAAAWAAAANgAAAAsAAAmaqqmaqgPOElK3BaHUAWsFEVYVpEcAFgyhkyXUQgBqL88TNHygCS1eQB+11mgEbQ5ECFS0CAGXQyQZKwHEAAYJcMFHI+8CvBUUQF5ypApChobh1qJrAAAAAAAAAh8=	BAAAAAAAAAAAqgAAAAAAAAAlAAAANgAAAAkAAAAJmJmZmQD9BkzQZbUWBaU8SaL6AaUA/KM00cRA+wMmKEXCE9WkBkWwDJqXcRsB8C0mVCRE1JgxPiTD2kTVAliXDYKi2UUAAAA1D/QI7w==	BAAAAAAAAAAAiP////////4YAAAANgAAAAsAAAqpqqqqqgBaRIjfM4FOBDQpUxY9MdQDsw5A01ynjwDXUgb1OgJeAXohVSl/I+cB2Q9gqxrgLwK6SleejZTcAd84ITBjMloJwL5HbFrgaADsAaE0MuZPAAAABBcaMKo=	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAADYAAAABAAAAAAAAAAEAAMCUCwWjBAEAAAAnAAAADAAC//8AAAAGANYg0AAAAAwAAv//AAAABgG2HngAAAAMAAL//wAAAAYBlQ2sAAAADAAC//8AAAAGANsMHAAAAAwAAv//AAAABgBEFeAAAAAMAAL//wAAAAYBxR4UAAAADAAC//8AAAAGACQMHAAAAAwAAv//AAAABgCWEsAAAAAMAAL//wAAAAYBORaoAAAADAAC//8AAAAGAG8JxAAAAAwAAv//AAAABgHzAMgAAAAMAAL//wAAAAYBXRZEAAAADAAC//8AAAAGAEQMgAAAAAwAAv//AAAABgAhIAgAAAAMAAL//wAAAAYB1Ru8AAAADAAC//8AAAAGAKQYOAAAAAwAAv//AAAABgHZIygAAAAMAAL//wAAAAYAXyBsAAAADAAC//8AAAAGAEUM5AAAAAwAAv//AAAABgBtFeAAAAAMAAL//wAAAAYCJyGYAAAADAAC//8AAAAGAlIl5AAAAAwAAv//AAAABgIWHIQAAAAMAAL//wAAAAYCVQMgAAAADAAC//8AAAAGAFsMHAAAAAwAAv//AAAABgHtDtgAAAAMAAL//wAAAAYCewiYAAAADAAC//8AAAAGAp8TJAAAAAwAAv//AAAABgEhBkAAAAAMAAL//wAAAAYAMxRQAAAADAAC//8AAAAGANQVfAAAAAwAAv//AAAABgBSG1gAAAAMAAL//wAAAAYCJAu4AAAADAAC//8AAAAGAM0TJAAAAAwAAv//AAAABgIaHngAAAAMAAL//wAAAAYArBtYAAAADAAC//8AAAAGAVshmAAAAAwAAv//AAAABgA0I/AAAAAMAAL//wAAAAYAJBdw	AgBwZ19jYXRhbG9nAGpzb25iAAAAADYAAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAADYAAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAANgAAAAMAAAAAAAADM0QSBKACEjRAOJJkgJhsFEQAAAAGWXE0BAABAAAABQAAAAh1c2VyLTAwMQAAAAh1c2VyLTAwMgAAAAh1c2VyLTAwNQAAAAh1c2VyLTAwMwAAAAh1c2VyLTAwNA==
\.


--
-- Data for Name: compress_hyper_6_15_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal.compress_hyper_6_15_chunk (_ts_meta_count, workspace_id, agent_id, id, _ts_meta_min_2, _ts_meta_max_2, trace_id, _ts_meta_min_1, _ts_meta_max_1, "timestamp", latency_ms, input, output, error, _ts_meta_min_4, _ts_meta_max_4, status, _ts_meta_min_3, _ts_meta_max_3, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, _ts_meta_min_5, _ts_meta_max_5, tags, _ts_meta_v2_bloom1_user_id, user_id) FROM stdin;
69	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	BAAAAAAAAAADZf////////ySAAAARQAAABCquqq7uru7qgCiMRvO5xhCATIGMd3JDVMQlg/RAV0CSAy0CvUJUAWnAFgDqxCQEvECoQs5EzwNBQDjAMRDomH6AOgI3RRADU0EQgm9EvIMXRA8EiMLjAY3AXSEyEkJk7sKBsHrsTdRJAlcstDWOEz9Fd8QiAk/AywChAngJAZ7+gAAAAAAjZHN	trace-10-1760823085.171576	trace-995-1760798480.663000	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABFAAAAGnRyYWNlLTU3LTE3NjA4MzA4ODAuNjYzMDAwAAAAG3RyYWNlLTI2NS0xNzYwODMwMjg1LjE3MTU3NgAAABt0cmFjZS05ODQtMTc2MDgzMDI4NS4xNzE1NzYAAAAbdHJhY2UtMzEwLTE3NjA4MjcyODAuNjYzMDAwAAAAG3RyYWNlLTcxNy0xNzYwODI3MjgwLjY2MzAwMAAAABt0cmFjZS00MTgtMTc2MDgyNjY4NS4xNzE1NzYAAAAbdHJhY2UtNzI3LTE3NjA4MjY2ODUuMTcxNTc2AAAAG3RyYWNlLTc5Ny0xNzYwODI2Njg1LjE3MTU3NgAAABt0cmFjZS04MTctMTc2MDgyNjY4NS4xNzE1NzYAAAAbdHJhY2UtOTkwLTE3NjA4MjY2ODUuMTcxNTc2AAAAG3RyYWNlLTQ1NS0xNzYwODIzNjgwLjY2MzAwMAAAABt0cmFjZS03NDUtMTc2MDgyMzY4MC42NjMwMDAAAAAadHJhY2UtMTAtMTc2MDgyMzA4NS4xNzE1NzYAAAAbdHJhY2UtMzk4LTE3NjA4MjMwODUuMTcxNTc2AAAAGnRyYWNlLTYyLTE3NjA4MjMwODUuMTcxNTc2AAAAG3RyYWNlLTkxOC0xNzYwODIzMDg1LjE3MTU3NgAAABt0cmFjZS0zNzEtMTc2MDgxOTQ4NS4xNzE1NzYAAAAbdHJhY2UtNDUwLTE3NjA4MTY0ODAuNjYzMDAwAAAAG3RyYWNlLTEwNC0xNzYwODE1ODg1LjE3MTU3NgAAABt0cmFjZS04NzgtMTc2MDgxNTg4NS4xNzE1NzYAAAAbdHJhY2UtMTgyLTE3NjA4MTI4ODAuNjYzMDAwAAAAG3RyYWNlLTUzMC0xNzYwODEyODgwLjY2MzAwMAAAABt0cmFjZS0yMTEtMTc2MDgxMjI4NS4xNzE1NzYAAAAbdHJhY2UtMzU0LTE3NjA4MDkyODAuNjYzMDAwAAAAGnRyYWNlLTYwLTE3NjA4MDkyODAuNjYzMDAwAAAAG3RyYWNlLTQyOS0xNzYwODA4Njg1LjE3MTU3NgAAABp0cmFjZS01MS0xNzYwODA4Njg1LjE3MTU3NgAAABt0cmFjZS05NzItMTc2MDgwNTA4NS4xNzE1NzYAAAAbdHJhY2UtMzQ3LTE3NjA4MDIwODAuNjYzMDAwAAAAG3RyYWNlLTcyOC0xNzYwNzk4NDgwLjY2MzAwMAAAABt0cmFjZS05OTUtMTc2MDc5ODQ4MC42NjMwMDAAAAAbdHJhY2UtNTU5LTE3NjA3OTc4ODUuMTcxNTc2AAAAG3RyYWNlLTcxNS0xNzYwNzk0ODgwLjY2MzAwMAAAABt0cmFjZS03MzYtMTc2MDc5NDg4MC42NjMwMDAAAAAbdHJhY2UtODczLTE3NjA3OTQ4ODAuNjYzMDAwAAAAG3RyYWNlLTQyNy0xNzYwNzk0Mjg1LjE3MTU3NgAAABt0cmFjZS00MDYtMTc2MDc4NzY4MC42NjMwMDAAAAAbdHJhY2UtMTM4LTE3NjA3ODQwODAuNjYzMDAwAAAAG3RyYWNlLTQxNS0xNzYwNzg0MDgwLjY2MzAwMAAAABt0cmFjZS04OTYtMTc2MDc4MzQ4NS4xNzE1NzYAAAAbdHJhY2UtODU1LTE3NjA3ODA0ODAuNjYzMDAwAAAAG3RyYWNlLTQ5Mi0xNzYwNzc5ODg1LjE3MTU3NgAAABt0cmFjZS0yMDctMTc2MDc3Njg4MC42NjMwMDAAAAAbdHJhY2UtNDQ0LTE3NjA3NzY4ODAuNjYzMDAwAAAAG3RyYWNlLTYwNC0xNzYwNzc2ODgwLjY2MzAwMAAAABt0cmFjZS03MDMtMTc2MDc3NjI4NS4xNzE1NzYAAAAbdHJhY2UtODY0LTE3NjA3NzYyODUuMTcxNTc2AAAAG3RyYWNlLTIxMS0xNzYwNzczMjgwLjY2MzAwMAAAABt0cmFjZS03MDQtMTc2MDc2OTY4MC42NjMwMDAAAAAbdHJhY2UtNzU0LTE3NjA3Njk2ODAuNjYzMDAwAAAAG3RyYWNlLTMwNy0xNzYwNzY5MDg1LjE3MTU3NgAAABt0cmFjZS00MTEtMTc2MDc2OTA4NS4xNzE1NzYAAAAbdHJhY2UtNzk4LTE3NjA3NjYwODAuNjYzMDAwAAAAG3RyYWNlLTUyMi0xNzYwNzYyNDgwLjY2MzAwMAAAABt0cmFjZS02OTYtMTc2MDc2MjQ4MC42NjMwMDAAAAAbdHJhY2UtOTc3LTE3NjA3NjI0ODAuNjYzMDAwAAAAG3RyYWNlLTgyNy0xNzYwNzYxODg1LjE3MTU3NgAAABt0cmFjZS04NzUtMTc2MDc2MTg4NS4xNzE1NzYAAAAbdHJhY2UtMzI5LTE3NjA3NTg4ODAuNjYzMDAwAAAAG3RyYWNlLTU5OS0xNzYwNzU4Mjg1LjE3MTU3NgAAABt0cmFjZS05ODUtMTc2MDc1NTI4MC42NjMwMDAAAAAbdHJhY2UtNTcxLTE3NjA3NTQ2ODUuMTcxNTc2AAAAG3RyYWNlLTY5MC0xNzYwNzU0Njg1LjE3MTU3NgAAABt0cmFjZS03NTctMTc2MDc1NDY4NS4xNzE1NzYAAAAbdHJhY2UtODQyLTE3NjA3NTQ2ODUuMTcxNTc2AAAAGXRyYWNlLTYtMTc2MDc1MTY4MC42NjMwMDAAAAAbdHJhY2UtNDkyLTE3NjA3NDgwODAuNjYzMDAwAAAAG3RyYWNlLTc0Ny0xNzYwNzQ4MDgwLjY2MzAwMAAAABt0cmFjZS04NjktMTc2MDc0NzQ4NS4xNzE1NzY=	2025-10-18 00:31:25.171576+00	2025-10-18 23:41:20.663+00	BAAAAuRivSyveP/////cgYWgAAAARQAAADnu7u3e7N7u7u7u3u7t7e7u7t7u3u7t7u4AAAAN7u7e7gAFyOxP3cuwAAXI7JbawG8AAAAARvz0wAAAAAFmKlM/AAAAAWYqU0BG/PTARvz0vwAAAAAAAAAAAAAAAWYqUz8AAAABZipTQEb89MBG/PS/AAAAAAAAAAAAAAABrSdH/wAAAABG/PTAAAAAAR8tXoAAAAAARvz0wAAAAAFmKlM/AAAAAWYqU0AAAAAARvz0vwAAAAEfLV5/AAAAAWYqU0BG/PTARvz0vwAAAAGtJ0f/Rvz0v0b89MAAAAABrSdIAAAAAABG/PS/AAAAAR8tXn8AAAABZipTQEb89L8AAAAAAAAAAsxUpn8AAAABZipTQAAAAAGtJ0gAAAAAAEb89L8AAAABHy1efwAAAAEfLV6AAAAAAR8tXn8AAAABZipTQEb89L8AAAAAAAAAAEb89MAAAAABZipTPwAAAABG/PS/AAAAAa0nSABG/PTARvz0vwAAAAFmKlM/AAAAAEb89L8AAAABrSdIAEb89L8AAAAAAAAAAEb89MAAAAABZipTPwAAAAEfLV6AAAAAAR8tXn8AAAABHy1egAAAAABG/PTAAAAAAAAAAAAAAAABZipTPwAAAABG/PS/AAAAAa0nSAAAAAAARvz0vw==	BAAAAAAAAAAPRgAAAAAAAAuwAAAARQAAABC7uqu6uqurugNyIAPlfdhaINIE3wUwA8cBhgRoD+41awwXbOMcYqWHG0YzXyoyCwMA1bTmOwAGdwc/cysnxql9EFUJCgF2A7oMRWACgqp/UBFyBiUDJARkAJkL3w0qE3cKwz/HzrZ72AxVboWReIKuBhANpBHpC0AJhwPmDeoQkQAAAAAeDgXB	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABFAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI2NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5ODQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzEwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDcxNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MTgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzI3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc5NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MTcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTkwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ1NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NDUAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzk4AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkxOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDUwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDEwNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NzgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTgyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUzMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzU0AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQyOQAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NzIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzQ3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDcyOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5OTUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTU5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDcxNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MzYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODczAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQyNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MDYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTM4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQxNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4OTYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODU1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ5MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMDcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDQ0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYwNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MDMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODY0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIxMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MDQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzU0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMwNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzk4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUyMgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2OTYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTc3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgyNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NzUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzI5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU5OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5ODUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTcxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY5MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NTcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODQyAAAAJVNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDkyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc0NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4Njk=	AQFwZ19jYXRhbG9nAHRleHQAAQAAAEUAAAACAAAAAAAAABFSZGIJiKIgFAAAAAAAAAAAAQAAADIAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI2NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDMxMAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQxOAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDcyNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc5NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgxNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk5MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ1NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc0NQAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEwAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MTgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNzEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMDQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NzgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxODIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMTEAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQyOQAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzQ3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzI4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTk1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzM2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODczAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDA2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTM4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDE1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODk2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODU1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjA3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDQ0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjA0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjExAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzA0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzU0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDExAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzk4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTc3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODI3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzI5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTk5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTcxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzU3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODQyAAAALVNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ5MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc0NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg2OQ==	AgFwZ19jYXRhbG9nAHRleHQAAAAAEwAAAAIAAAAAAAAARJGHFhEVQxIQAAAAAAAAChEAAABFAAAAAgAAAAAAAAARrZud9ndd3+sAAAAAAAAAHwABAAAACwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgNjk0bXMAAAAfU2FtcGxlIGVycm9yIG1lc3NhZ2U6IEFQSV9FUlJPUgAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMjQ3bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE4ODVtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTU5OW1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA3NDdtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgODY5bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE4NTFtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMjUybXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDM0MW1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxMzY0bXM=	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARQAAAAMAAAAAAAABIoBARAgEAAIQEggYEBgEAIIAAAAAAAAAAAABAAAAAwAAAAdzdWNjZXNzAAAAB3RpbWVvdXQAAAAFZXJyb3I=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARQAAAAMAAAAAAAACIp/W91uY1CeQWsNngom2pYIAAAAAAAABXwABAAAABAAAAAxtaXh0cmFsLTh4N2IAAAALZ3B0LTQtdHVyYm8AAAANY2xhdWRlLTMtb3B1cwAAAApnZW1pbmktcHJv	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARQAAAAMAAAAAAAACIp/W91uY1CeQWsNngom2pYIAAAAAAAABXwABAAAABAAAAAdtaXN0cmFsAAAABm9wZW5haQAAAAlhbnRocm9waWMAAAAGZ29vZ2xl	BAAAAAAAAAAAa/////////+PAAAARQAAAA4AiaqqqaqqqgQwLJAENdOEAdolYvke4lsAlwiTfgPkSQQyAbGzIgIhAA0XcNQHxAcE72nj0x/T3gowh9CfOL7wAQw9xEslQ5cEmz9gEhFjvwGNJ1SOMxI8Ah8jFcxdNCAAyyRUOB+yfgF5Uy/LLlqrAAAAAAAA524=	BAAAAAAAAAAAgwAAAAAAAAAlAAAARQAAAAwAAEmZmJmZmQLIskzF0WhaBJUgU1xnjE4D8EQGzIUNFgKZTYibddnnBO0MPEI1yWkErXiXYsQFKAF6N6OM0ZSMBy0IE0gm5UgCJXBnXsmWaAIgTwxGlaEPBWGlKwvoDTAAAAAAAAAADQ==	BAAAAAAAAAABVv////////9PAAAARQAAAA4AmqqaqqqpqgC5ETPogdU2AmMkg3hKMoABgNAZ0dH0UgQ3L1cqTVFCAToQgjEh9rAFb1niqzBC9QLFfSWrIID4ApoLYKtFZKEBFyTEsE1TIwJYREWqNGGLBF9UhPsaEwIGFBKxoUw3qgSaXhGAXee5AAAAAAAC7nM=	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAEUAAAACAAAAAAAAABFSZGIJiKIgFAAAAAAAAAAAAQAAADIAAAAMAAL//wAAAAYAJwiYAAAADAAC//8AAAAGAEoBkAAAAAwAAv//AAAABgKmC1QAAAAMAAL//wAAAAYBtxnIAAAADAAC//8AAAAGAach/AAAAAwAAv//AAAABgBhDIAAAAAMAAL//wAAAAYAfAdsAAAADAAC//8AAAAGAlUGQAAAAAwAAv//AAAABgE6CDQAAAAMAAL//wAAAAYAXw50AAAADAAC//8AAAAGAGshmAAAAAwAAv//AAAABgFiINAAAAAMAAL//wAAAAYCcAzkAAAADAAC//8AAAAGAEQM5AAAAAwAAv//AAAABgJTFRgAAAAMAAL//wAAAAYBmRGUAAAADAAC//8AAAAGAEUUUAAAAAwAAv//AAAABgBiA+gAAAAMAAL//wAAAAYBViWAAAAADAAC//8AAAAGAWoH0AAAAAwAAv//AAAABgFcCowAAAAMAAL//wAAAAYAsyLEAAAADAAC//8AAAAGAMMgbAAAAAwAAv//AAAABgFrDzwAAAAMAAL//wAAAAYAPCWAAAAADAAC//8AAAAGACABkAAAAAwAAv//AAAABgEZDUgAAAAMAAL//wAAAAYCNyOMAAAADAAC//8AAAAGANIF3AAAAAwAAv//AAAABgGUJLgAAAAMAAL//wAAAAYBdQOEAAAADAAC//8AAAAGAIkZyAAAAAwAAv//AAAABgF+JRwAAAAMAAL//wAAAAYCGg4QAAAADAAC//8AAAAGAToc6AAAAAwAAv//AAAABgEwC1QAAAAMAAL//wAAAAYAMA7YAAAADAAC//8AAAAGANIEsAAAAAwAAv//AAAABgBqAMgAAAAMAAL//wAAAAYBZwPoAAAADAAC//8AAAAGAJ0XcAAAAAwAAv//AAAABgBlCvAAAAAMAAL//wAAAAYASSZIAAAADAAC//8AAAAGAs4SXAAAAAwAAv//AAAABgDZGpAAAAAMAAL//wAAAAYAQBEwAAAADAAC//8AAAAGADkKKAAAAAwAAv//AAAABgDeJFQAAAAMAAL//wAAAAYBPRosAAAADAAC//8AAAAGAYUcIA==	AgBwZ19jYXRhbG9nAGpzb25iAAAAAEUAAAABAAAAAAAAAA8AAARQAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAEUAAAABAAAAAAAAAA8AAARQAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARQAAAAQAAAAAAAAzM0CDJIJUiDKIFKJEtFFlOKIkC4AgomGWXAAAAAAAALZjAAEAAAAFAAAACHVzZXItMDA0AAAACHVzZXItMDAyAAAACHVzZXItMDAzAAAACHVzZXItMDAxAAAACHVzZXItMDA1
67	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	BAAAAAAAAAACvf////////tNAAAAQwAAAA8Kqqqqu6q7uwTrCmAQDQriA8AQuxBwBsMT5wfOAH0DhAJ4CjQVWReiAHV9J3c0UYoCm7GuJ09AQgS2BmoHNQEoD0EFHRSkESMAnBlilwQtwAGKO2AarkzRBAa4D63wzbkBjdbv04prMw3LAK1Uu1L6A/ksJLFGSaIAAAAKNx/zcg==	trace-111-1760762480.663000	trace-963-1760808685.171576	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABDAAAAG3RyYWNlLTM5My0xNzYwODMwODgwLjY2MzAwMAAAABt0cmFjZS03MzEtMTc2MDgzMDI4NS4xNzE1NzYAAAAbdHJhY2UtMzk3LTE3NjA4MjcyODAuNjYzMDAwAAAAG3RyYWNlLTQzMy0xNzYwODI3MjgwLjY2MzAwMAAAABt0cmFjZS02MDMtMTc2MDgyNjY4NS4xNzE1NzYAAAAbdHJhY2UtODc3LTE3NjA4MjM2ODAuNjYzMDAwAAAAGXRyYWNlLTktMTc2MDgyMzY4MC42NjMwMDAAAAAbdHJhY2UtNjIxLTE3NjA4MjMwODUuMTcxNTc2AAAAG3RyYWNlLTY4My0xNzYwODIzMDg1LjE3MTU3NgAAABt0cmFjZS02ODItMTc2MDgxOTQ4NS4xNzE1NzYAAAAbdHJhY2UtNjgwLTE3NjA4MTY0ODAuNjYzMDAwAAAAG3RyYWNlLTEzMC0xNzYwODE1ODg1LjE3MTU3NgAAABt0cmFjZS02MDUtMTc2MDgxMjg4MC42NjMwMDAAAAAbdHJhY2UtMzQ3LTE3NjA4MTIyODUuMTcxNTc2AAAAG3RyYWNlLTM5NS0xNzYwODEyMjg1LjE3MTU3NgAAABt0cmFjZS03NTktMTc2MDgxMjI4NS4xNzE1NzYAAAAbdHJhY2UtMzIwLTE3NjA4MDkyODAuNjYzMDAwAAAAG3RyYWNlLTQ2Mi0xNzYwODA5MjgwLjY2MzAwMAAAABt0cmFjZS02NDgtMTc2MDgwODY4NS4xNzE1NzYAAAAbdHJhY2UtODM1LTE3NjA4MDg2ODUuMTcxNTc2AAAAG3RyYWNlLTk2My0xNzYwODA4Njg1LjE3MTU3NgAAABt0cmFjZS0xMjQtMTc2MDgwNTY4MC42NjMwMDAAAAAbdHJhY2UtOTE5LTE3NjA4MDU2ODAuNjYzMDAwAAAAG3RyYWNlLTkwMi0xNzYwODA1MDg1LjE3MTU3NgAAABt0cmFjZS0zMDYtMTc2MDgwMjA4MC42NjMwMDAAAAAbdHJhY2UtMzc2LTE3NjA4MDIwODAuNjYzMDAwAAAAG3RyYWNlLTU5NC0xNzYwODAyMDgwLjY2MzAwMAAAABt0cmFjZS04ODktMTc2MDgwMTQ4NS4xNzE1NzYAAAAZdHJhY2UtNS0xNzYwNzk4NDgwLjY2MzAwMAAAABt0cmFjZS03MjQtMTc2MDc5ODQ4MC42NjMwMDAAAAAbdHJhY2UtMjQ5LTE3NjA3OTQyODUuMTcxNTc2AAAAG3RyYWNlLTQxNi0xNzYwNzkxMjgwLjY2MzAwMAAAABt0cmFjZS05MjgtMTc2MDc5MTI4MC42NjMwMDAAAAAbdHJhY2UtNDg3LTE3NjA3ODcwODUuMTcxNTc2AAAAG3RyYWNlLTgwNi0xNzYwNzg3MDg1LjE3MTU3NgAAABt0cmFjZS0xNTgtMTc2MDc4NDA4MC42NjMwMDAAAAAbdHJhY2UtMTc4LTE3NjA3ODQwODAuNjYzMDAwAAAAG3RyYWNlLTQwMS0xNzYwNzg0MDgwLjY2MzAwMAAAABt0cmFjZS03MDItMTc2MDc4NDA4MC42NjMwMDAAAAAbdHJhY2UtMzYyLTE3NjA3ODM0ODUuMTcxNTc2AAAAG3RyYWNlLTQxNi0xNzYwNzc5ODg1LjE3MTU3NgAAABt0cmFjZS00ODMtMTc2MDc3OTg4NS4xNzE1NzYAAAAadHJhY2UtMjUtMTc2MDc3Njg4MC42NjMwMDAAAAAbdHJhY2UtNzY0LTE3NjA3NzY4ODAuNjYzMDAwAAAAG3RyYWNlLTc0Ni0xNzYwNzc2Mjg1LjE3MTU3NgAAABt0cmFjZS02NTQtMTc2MDc3MzI4MC42NjMwMDAAAAAbdHJhY2UtNTU1LTE3NjA3NzI2ODUuMTcxNTc2AAAAG3RyYWNlLTkyOC0xNzYwNzcyNjg1LjE3MTU3NgAAABt0cmFjZS04MTYtMTc2MDc2OTY4MC42NjMwMDAAAAAbdHJhY2UtMjcwLTE3NjA3NjYwODAuNjYzMDAwAAAAG3RyYWNlLTgzMS0xNzYwNzY2MDgwLjY2MzAwMAAAABt0cmFjZS0zNjYtMTc2MDc2NTQ4NS4xNzE1NzYAAAAbdHJhY2UtNjIwLTE3NjA3NjU0ODUuMTcxNTc2AAAAG3RyYWNlLTY3NS0xNzYwNzY1NDg1LjE3MTU3NgAAABt0cmFjZS0xMTEtMTc2MDc2MjQ4MC42NjMwMDAAAAAadHJhY2UtNDgtMTc2MDc2MTg4NS4xNzE1NzYAAAAbdHJhY2UtNjkxLTE3NjA3NjE4ODUuMTcxNTc2AAAAG3RyYWNlLTMzOS0xNzYwNzU4ODgwLjY2MzAwMAAAABt0cmFjZS0yMjEtMTc2MDc1ODI4NS4xNzE1NzYAAAAbdHJhY2UtMzM2LTE3NjA3NTgyODUuMTcxNTc2AAAAGnRyYWNlLTEzLTE3NjA3NTUyODAuNjYzMDAwAAAAGnRyYWNlLTg5LTE3NjA3NTUyODAuNjYzMDAwAAAAG3RyYWNlLTUxOC0xNzYwNzUxNjgwLjY2MzAwMAAAABt0cmFjZS00MzgtMTc2MDc0ODA4MC42NjMwMDAAAAAbdHJhY2UtNzk5LTE3NjA3NDgwODAuNjYzMDAwAAAAG3RyYWNlLTkwNC0xNzYwNzQ4MDgwLjY2MzAwMAAAABt0cmFjZS03MDEtMTc2MDc0NzQ4NS4xNzE1NzY=	2025-10-18 00:31:25.171576+00	2025-10-18 23:41:20.663+00	BAAAAuRivSyveP/////cgYWgAAAAQwAAADzu3u7u3u7u7u7u7u7e7u7t7e7u7u7u7t4AAN7u7u7u7gAFyOxP3cuwAAXI7JbawG8AAAABHy1efwAAAAFmKlNAAAAAAEb89L8AAAABHy1efwAAAAFmKlNARvz0wEb89L8AAAABrSdH/wAAAABG/PTAAAAAAR8tXoAAAAABHy1efwAAAAEfLV6AAAAAAEb89MAAAAABZipTPwAAAAFmKlNARvz0wEb89L8AAAAAAAAAAAAAAAFmKlM/AAAAAWYqU0AAAAAARvz0vwAAAAEfLV5/AAAAAWYqU0BG/PS/AAAAAAAAAAEfLV5/AAAAAWYqU0AAAAAB9CQ8vwAAAACN+emAAAAAAWYqU0AAAAAB9CQ8vwAAAAH0JDzAAAAAAWYqUz8AAAABZipTQAAAAAAAAAAAAAAAAEb89L8AAAABZipTPwAAAAGtJ0gAAAAAAWYqUz8AAAABZipTQAAAAABG/PS/AAAAAR8tXn8AAAABHy1egAAAAABG/PTAAAAAAWYqUz8AAAAARvz0vwAAAAGtJ0gARvz0wEb89L8AAAAAAAAAAAAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAFmKlM/AAAAAWYqU0AAAAABrSdH/wAAAAAAAAAAAAAAAa0nSABG/PS/AAAAAA==	BAAAAAAAAAAFaf////////l5AAAAQwAAABC7u7u7qruruwySBfQZRRA6BuwQoxBSEJcJYxXiEpcGqgb/t0einDDAJXsOughOCpkC0wt2DpUeUAjOWNDnmOmXCtAatwUqI18bOiZLCyUMThFbClIBkgMcBUUMXhi9ElwOCAYrAv8JXgW8Dk8WVBJ3F68bDArDBj0NdAHBCl0RUh/ZMyI2uQ1Y	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABDAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM5MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzk3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQzMwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MDMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODc3AAAAJVNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjIxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY4MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2ODIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjgwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDEzMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MDUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzQ3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM5NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NTkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzIwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ2MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NDgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODM1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk2MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMjQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTE5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkwMgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMDYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzc2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU5NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4ODkAAAAlU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MjQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjQ5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQxNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MjgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDg3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgwNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNTgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTc4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQwMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzYyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQxNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0ODMAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzY0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc0NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NTQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTU1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkyOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MTYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjcwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgzMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNjYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjIwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY3NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMTEAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjkxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMzOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMjEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzM2AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDEzAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUxOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MzgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzk5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkwNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MDE=	AQFwZ19jYXRhbG9nAHRleHQAAQAAAEMAAAACAAAAAAAAABEICQAhFwghCAAAAAAAAAAAAQAAADYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzOTMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3MzEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzOTcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MDMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NzcAAAAtU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjIxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjgyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjgwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTMwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjA1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzk1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzU5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzIwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDYyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjQ4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTYzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTI0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTE5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTAyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODg5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzI0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjQ5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDE2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDg3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODA2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTU4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTc4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzAyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzYyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDE2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDgzAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3NjQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3NDYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NTQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1NTUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MjgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyNzAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MzEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MjAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NzUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMTEAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY5MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDMzOQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDIyMQAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEzAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1MTgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0MzgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3OTkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MDQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3MDE=	AgFwZ19jYXRhbG9nAHRleHQAAAAADQAAAAEAAAAAAAAAAwAAAEnk0saIAAAAQwAAAAIAAAAAAAAAEff2/97o9973AAAAAAAAAAcAAQAAAAgAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE3MzZtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTc3Mm1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciAzNDdtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMzAwN21zAAAAH1NhbXBsZSBlcnJvciBtZXNzYWdlOiBBUElfRVJST1IAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDU0MG1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA1MTJtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgOTIybXM=	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAQwAAAAMAAAAAAAABIgEmAEAEAQBAAIAAgQAACAIAAAAAAAAAAAABAAAAAwAAAAdzdWNjZXNzAAAAB3RpbWVvdXQAAAAFZXJyb3I=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAQwAAAAMAAAAAAAABIjeCmlYNWISk0h2UtIEej28AAAAAAAAAAAABAAAABAAAAAxtaXh0cmFsLTh4N2IAAAAKZ2VtaW5pLXBybwAAAAtncHQtNC10dXJibwAAAA1jbGF1ZGUtMy1vcHVz	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAQwAAAAMAAAAAAAABIjeCmlYNWISk0h2UtIEej28AAAAAAAAAAAABAAAABAAAAAdtaXN0cmFsAAAABmdvb2dsZQAAAAZvcGVuYWkAAAAJYW50aHJvcGlj	BAAAAAAAAAAAugAAAAAAAAB9AAAAQwAAAA0ACqqqqZmqqgLnODYOclQsBFMcYAoWFKYDmwJxxCN0NgSJBpL8HJNCByBWI/Wd+pQHikcB3GISfQZBFZh7BPRtAH5AkkAc4m8D+lCTXkxUgAQUNfVGWBF8BE08YbETw6UDZQxh2x2BkgAANANzAGQq	BAAAAAAAAAAAjP/////////5AAAAQwAAAAwAAHmZmZmZmQeVYBIB1lU8BjAdLE/mVaICIBVLHFdKAwW0HD2AURFPBdASM9jm7VgCCBkChLMZ1QMRnQ8ThjSGADk0dNaClHIBKVltnBVw6wElFWAMMUSqA1nBUQ1lpQAAAAAAAAAASw==	BAAAAAAAAAACOwAAAAAAAAGjAAAAQwAAAA0ACqqpqqqpqgVpGBNwLRI+Am4BJKEzo+4G/WL4xS96uQNxSSQbILSUBCckpEUX48wB/ysgTC6VSgDiDdY0WRBABFo8cVYz0R4FrEeG4yFklwUdDsScN9JuByAFtLElolgAz2xoDXjoSwOwPQYNLCKN	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAEMAAAACAAAAAAAAABEICQAhFwghCAAAAAAAAAAAAQAAADYAAAAMAAL//wAAAAYAISRUAAAADAAC//8AAAAGAJIdsAAAAAwAAv//AAAABgJKH6QAAAAMAAL//wAAAAYAQABkAAAADAAC//8AAAAGAPggbAAAAAwAAv//AAAABgBvIZgAAAAMAAL//wAAAAYByCUcAAAADAAC//8AAAAGAfgQBAAAAAwAAv//AAAABgBcG7wAAAAMAAL//wAAAAYAoQooAAAADAAC//8AAAAGADwUUAAAAAwAAv//AAAABgBMHhQAAAAMAAL//wAAAAYAVBwgAAAADAAC//8AAAAGAbwj8AAAAAwAAv//AAAABgCtEyQAAAAMAAL//wAAAAYAqBEwAAAADAAC//8AAAAGAcwQBAAAAAwAAv//AAAABgFkB9AAAAAMAAL//wAAAAYAYhqQAAAADAAC//8AAAAGAYEakAAAAAwAAv//AAAABgCuFFAAAAAMAAL//wAAAAYAbgEsAAAADAAC//8AAAAGAL4ImAAAAAwAAv//AAAABgCAJqwAAAAMAAL//wAAAAYBog88AAAADAAC//8AAAAGAXgX1AAAAAwAAv//AAAABgCsJkgAAAAMAAL//wAAAAYC2x4UAAAADAAC//8AAAAGAEIg0AAAAAwAAv//AAAABgDpHbAAAAAMAAL//wAAAAYCDQrwAAAADAAC//8AAAAGAuIImAAAAAwAAv//AAAABgDrEfgAAAAMAAL//wAAAAYAbgZAAAAADAAC//8AAAAGAPELVAAAAAwAAv//AAAABgBJEfgAAAAMAAL//wAAAAYAZQZAAAAADAAC//8AAAAGANQgCAAAAAwAAv//AAAABgC8FqgAAAAMAAL//wAAAAYBwQg0AAAADAAC//8AAAAGACMNSAAAAAwAAv//AAAABgBSCPwAAAAMAAL//wAAAAYAsyasAAAADAAC//8AAAAGANoH0AAAAAwAAv//AAAABgC+GWQAAAAMAAL//wAAAAYCRw4QAAAADAAC//8AAAAGADcWqAAAAAwAAv//AAAABgFiBqQAAAAMAAL//wAAAAYAISS4AAAADAAC//8AAAAGAMoUtAAAAAwAAv//AAAABgHYGcgAAAAMAAL//wAAAAYAZhXgAAAADAAC//8AAAAGAHUNSAAAAAwAAv//AAAABgAgF9Q=	AgBwZ19jYXRhbG9nAGpzb25iAAAAAEMAAAABAAAAAAAAAA8AAAQwAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAEMAAAABAAAAAAAAAA8AAAQwAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAQwAAAAQAAAAAAAAzMyDiBhCaTBSIAFxQQhkwtRRG0EBIJGI2mwAAAAAAAAUSAAEAAAAFAAAACHVzZXItMDAzAAAACHVzZXItMDAyAAAACHVzZXItMDAxAAAACHVzZXItMDA1AAAACHVzZXItMDA0
68	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	BAAAAAAAAAAAR/////////sRAAAARAAAABCru6u7qqq6qwE5DXwUMwxsBIE2iHoPyrsFb1IA4MQNvQmEDG8VSgzdDv0e1aAylp0JvfyMJXcNygZWY/Cc4Gt/AwThDjMDQhkR1hSrB+IGDRFGD/ECrgFHEzAQXQ28DPEB2dbuvTbKEQfhElAKdQJIFekJqgtADdcBzQlQED0WiAAAAAAAAAt9	trace-101-1760779885.171576	trace-98-1760773280.663000	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABEAAAAG3RyYWNlLTU5MC0xNzYwODMwODgwLjY2MzAwMAAAABt0cmFjZS01OTQtMTc2MDgzMDI4NS4xNzE1NzYAAAAbdHJhY2UtMzI0LTE3NjA4MjcyODAuNjYzMDAwAAAAG3RyYWNlLTg5Ny0xNzYwODI3MjgwLjY2MzAwMAAAABp0cmFjZS05Ni0xNzYwODI3MjgwLjY2MzAwMAAAABt0cmFjZS00MjEtMTc2MDgyNjY4NS4xNzE1NzYAAAAbdHJhY2UtODMxLTE3NjA4MjY2ODUuMTcxNTc2AAAAG3RyYWNlLTY3Ny0xNzYwODIzNjgwLjY2MzAwMAAAABt0cmFjZS05NDYtMTc2MDgyMDA4MC42NjMwMDAAAAAbdHJhY2UtNDU2LTE3NjA4MTk0ODUuMTcxNTc2AAAAG3RyYWNlLTUzNC0xNzYwODE5NDg1LjE3MTU3NgAAABt0cmFjZS03MjQtMTc2MDgxOTQ4NS4xNzE1NzYAAAAbdHJhY2UtNTcwLTE3NjA4MTY0ODAuNjYzMDAwAAAAG3RyYWNlLTcyMC0xNzYwODE2NDgwLjY2MzAwMAAAABt0cmFjZS0yMjMtMTc2MDgxNTg4NS4xNzE1NzYAAAAbdHJhY2UtNDUxLTE3NjA4MTI4ODAuNjYzMDAwAAAAGnRyYWNlLTg3LTE3NjA4MTI4ODAuNjYzMDAwAAAAG3RyYWNlLTk0MS0xNzYwODEyODgwLjY2MzAwMAAAABt0cmFjZS05NDgtMTc2MDgwOTI4MC42NjMwMDAAAAAbdHJhY2UtNTUwLTE3NjA4MDU2ODAuNjYzMDAwAAAAG3RyYWNlLTg3Mi0xNzYwODA1NjgwLjY2MzAwMAAAABt0cmFjZS05NDctMTc2MDgwNTY4MC42NjMwMDAAAAAbdHJhY2UtMTAzLTE3NjA4MDUwODUuMTcxNTc2AAAAGnRyYWNlLTI0LTE3NjA4MDUwODUuMTcxNTc2AAAAG3RyYWNlLTg5Ny0xNzYwODA1MDg1LjE3MTU3NgAAABt0cmFjZS0yMTUtMTc2MDgwMTQ4NS4xNzE1NzYAAAAbdHJhY2UtNTUzLTE3NjA3OTg0ODAuNjYzMDAwAAAAG3RyYWNlLTY0NC0xNzYwNzk4NDgwLjY2MzAwMAAAABt0cmFjZS0yNjMtMTc2MDc5Nzg4NS4xNzE1NzYAAAAbdHJhY2UtNjc3LTE3NjA3OTQyODUuMTcxNTc2AAAAG3RyYWNlLTE2OS0xNzYwNzkxMjgwLjY2MzAwMAAAABt0cmFjZS04NjEtMTc2MDc5MDY4NS4xNzE1NzYAAAAbdHJhY2UtMzY0LTE3NjA3ODc2ODAuNjYzMDAwAAAAG3RyYWNlLTU5OC0xNzYwNzg3NjgwLjY2MzAwMAAAABt0cmFjZS04NTgtMTc2MDc4NzY4MC42NjMwMDAAAAAbdHJhY2UtMzAwLTE3NjA3ODcwODUuMTcxNTc2AAAAG3RyYWNlLTU0Mi0xNzYwNzg3MDg1LjE3MTU3NgAAABt0cmFjZS0xNzAtMTc2MDc4MDQ4MC42NjMwMDAAAAAadHJhY2UtMjMtMTc2MDc4MDQ4MC42NjMwMDAAAAAbdHJhY2UtODg1LTE3NjA3ODA0ODAuNjYzMDAwAAAAG3RyYWNlLTEwMS0xNzYwNzc5ODg1LjE3MTU3NgAAABt0cmFjZS02MDAtMTc2MDc3OTg4NS4xNzE1NzYAAAAbdHJhY2UtOTM1LTE3NjA3Nzk4ODUuMTcxNTc2AAAAG3RyYWNlLTYxMy0xNzYwNzc2ODgwLjY2MzAwMAAAABt0cmFjZS0yNTAtMTc2MDc3NjI4NS4xNzE1NzYAAAAadHJhY2UtOTgtMTc2MDc3MzI4MC42NjMwMDAAAAAbdHJhY2UtMjg5LTE3NjA3NzI2ODUuMTcxNTc2AAAAG3RyYWNlLTIzOC0xNzYwNzY5NjgwLjY2MzAwMAAAABp0cmFjZS05Mi0xNzYwNzY5MDg1LjE3MTU3NgAAABt0cmFjZS00MDItMTc2MDc2NjA4MC42NjMwMDAAAAAbdHJhY2UtNDIzLTE3NjA3NjYwODAuNjYzMDAwAAAAG3RyYWNlLTg4Mi0xNzYwNzY2MDgwLjY2MzAwMAAAABt0cmFjZS00NTQtMTc2MDc2NTQ4NS4xNzE1NzYAAAAbdHJhY2UtNzQ1LTE3NjA3NjU0ODUuMTcxNTc2AAAAG3RyYWNlLTc5OS0xNzYwNzY1NDg1LjE3MTU3NgAAABt0cmFjZS0xNDUtMTc2MDc2MjQ4MC42NjMwMDAAAAAbdHJhY2UtMTUyLTE3NjA3NjE4ODUuMTcxNTc2AAAAG3RyYWNlLTUwMy0xNzYwNzU4ODgwLjY2MzAwMAAAABt0cmFjZS04NDUtMTc2MDc1ODg4MC42NjMwMDAAAAAbdHJhY2UtNDE1LTE3NjA3NTgyODUuMTcxNTc2AAAAG3RyYWNlLTQyNS0xNzYwNzU4Mjg1LjE3MTU3NgAAABt0cmFjZS02NzItMTc2MDc1NTI4MC42NjMwMDAAAAAbdHJhY2UtMTE0LTE3NjA3NTQ2ODUuMTcxNTc2AAAAG3RyYWNlLTQ0MC0xNzYwNzUxNjgwLjY2MzAwMAAAABt0cmFjZS02ODctMTc2MDc1MTA4NS4xNzE1NzYAAAAbdHJhY2UtMTI2LTE3NjA3NDgwODAuNjYzMDAwAAAAG3RyYWNlLTMzNC0xNzYwNzQ4MDgwLjY2MzAwMAAAABp0cmFjZS03MS0xNzYwNzQ3NDg1LjE3MTU3Ng==	2025-10-18 00:31:25.171576+00	2025-10-18 23:41:20.663+00	BAAAAuRivSyveP/////cgYWgAAAARAAAADru7u7e7u3u7u3u7u7u7d7u7t3u7u7u3e4AAADe7u7t7gAFyOxP3cuwAAXI7JbawG8AAAABHy1efwAAAAFmKlNARvz0vwAAAAAAAAAARvz0wAAAAAFmKlM/AAAAAEb89L8AAAABZipTQAAAAABG/PTAAAAAAWYqUz8AAAABZipTQAAAAABG/PS/AAAAAR8tXn8AAAABZipTQAAAAAAAAAAAAAAAAa0nR/8AAAAAAAAAAAAAAAGtJ0gARvz0vwAAAAAAAAAARvz0wAAAAAGtJ0f/AAAAAEb89MAAAAABZipTQAAAAABG/PS/AAAAAWYqUz8AAAAARvz0wAAAAAEfLV6AAAAAAR8tXn8AAAABZipTQEb89L8AAAAAAAAAAEb89MAAAAADE1GbPwAAAAMTUZtARvz0vwAAAAAAAAAARvz0wAAAAAFmKlM/AAAAAR8tXoAAAAABHy1efwAAAAEfLV6AAAAAAR8tXn8AAAABHy1egAAAAAEfLV5/AAAAAWYqU0BG/PS/AAAAAAAAAABG/PTAAAAAAWYqUz8AAAABHy1egAAAAAEfLV5/AAAAAWYqU0BG/PTARvz0vwAAAAFmKlM/AAAAAR8tXoAAAAABHy1efwAAAAEfLV6AAAAAAR8tXn8AAAABZipTQAAAAABG/PS/	BAAAAAAAAAALJAAAAAAAAAPnAAAARAAAABGru6u7uru7uwAAAAAAAAAKJW0hjCZ5F8oL/Q+2BTYOyAQ2JE8mgha7BxcKgAsxEjwjNgK2BUoILw4MDgsCgCXdC+4GexBN8N0X0A95G7AmSRYaMmUkzhdrF0Q0VSBIA5UOJR2kKlcWPg+YD7P7CCgeACwGEgK2EpM5uTF0EgcAoAWVAXgRIAh+AMkAzIjU1ZgAAAAAAAAEsA==	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABEAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU5MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1OTQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzI0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg5NwAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MjEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODMxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY3NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NDYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDU2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUzNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MjQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTcwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDcyMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMjMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDUxAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk0MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NDgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTUwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg3MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NDcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTAzAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg5NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMTUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTUzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY0NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNjMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjc3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE2OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NjEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzY0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU5OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NTgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzAwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU0MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNzAAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODg1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDEwMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MDAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTM1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYxMwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNTAAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjg5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIzOAAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDIzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg4MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NTQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzQ1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc5OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNDUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTUyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUwMwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NDUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDE1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQyNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NzIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTE0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ0MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2ODcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTI2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMzNAAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MQ==	AQFwZ19jYXRhbG9nAHRleHQAAQAAAEQAAAACAAAAAAAAABERRSATAhTqiAAAAAAAAAAFAQAAAC8AAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1OTAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1OTQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMjQAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQyMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgzMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk0NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUzNAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU3MAAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTQxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTUwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTQ3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTAzAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4OTcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1NTMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NDQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyNjMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NzcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNjkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NjEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NTgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMDAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNzAAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg4NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEwMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYwMAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDkzNQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYxMwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI1MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI4OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDIzOAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQwMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg4MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ1NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc0NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE0NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUwMwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg0NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQxNQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY3MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDExNAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ0MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEyNgAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDcx	AgFwZ19jYXRhbG9nAHRleHQAAAAAFQAAAAEAAAAAAAAAAwAAHwoEDRAAAAAARAAAAAIAAAAAAAAAEe663+z96xV3AAAAAAAAAAoAAQAAAAgAAAAfU2FtcGxlIGVycm9yIG1lc3NhZ2U6IEFQSV9FUlJPUgAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTE0M21zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxOTU2bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE4NjFtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgNDA2Mm1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA2ODNtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgNTQ2bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDI1Mm1z	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARAAAAAMAAAAAAAABIgAEAhCoREBAAQEQEggAAQkAAAAAAAAABQABAAAAAwAAAAdzdWNjZXNzAAAABWVycm9yAAAAB3RpbWVvdXQ=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARAAAAAMAAAAAAAACIrO6c3K0waPkpA2y6WFihzkAAAAAAAAAXgABAAAABAAAAAtncHQtNC10dXJibwAAAAxtaXh0cmFsLTh4N2IAAAAKZ2VtaW5pLXBybwAAAA1jbGF1ZGUtMy1vcHVz	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARAAAAAMAAAAAAAACIrO6c3K0waPkpA2y6WFihzkAAAAAAAAAXgABAAAABAAAAAZvcGVuYWkAAAAHbWlzdHJhbAAAAAZnb29nbGUAAAAJYW50aHJvcGlj	BAAAAAAAAAABoQAAAAAAAAAQAAAARAAAAA0AB6mqqqmZmQiAaZS+0nlaAnH66PzBb48EKwMlguBUcweMYSeAMO1YAdSxbZEz3qgAxSyiWUpDHwPPHaGfAnBfAyowFDxotvwCez2EZ0RD1QDRO9WaRrL6AtixcbTZ+QIASx8DS0CiswAAAAAAACWm	BAAAAAAAAAAAYf////////+NAAAARAAAAAsAAAmZmZiZiQEpO2CUMczgtHPg64kZukgFwnU7DkLUNQbGWDjHsCA6JrfmLn91vhAAYCIv2qLsRwDI0WEUcEwYAm1mXEclRWIC0N8M3mlVjgOQcFbV4KElAAAAYtSE7B8=	BAAAAAAAAAACdgAAAAAAAAFPAAAARAAAAA4AmqqqqpqqqQL9L3J/T8Z4A9sUwFkMYQQDfj0FLx4VHAHLB6DtBfKRBAwsUIZPNpYOkIVTpfIAkwJfMrP6JUZ9AoYy0u1IoagHb2DlN0WhmQJSeta0YlcsA8IJEVhqVmwAD1rCaQpTHQF1QQOTDsLxAAAAAAAAA1I=	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAEQAAAACAAAAAAAAABERRSATAhTqiAAAAAAAAAAFAQAAAC8AAAAMAAL//wAAAAYB+gGQAAAADAAC//8AAAAGAB8XcAAAAAwAAv//AAAABgCCEfgAAAAMAAL//wAAAAYBzgzkAAAADAAC//8AAAAGAK4F3AAAAAwAAv//AAAABgCPBkAAAAAMAAL//wAAAAYAfgPoAAAADAAC//8AAAAGAZ8gbAAAAAwAAv//AAAABgHeDzwAAAAMAAL//wAAAAYAsSRUAAAADAAC//8AAAAGASYZZAAAAAwAAv//AAAABgApEMwAAAAMAAL//wAAAAYBNSRUAAAADAAC//8AAAAGAXkaLAAAAAwAAv//AAAABgBFF9QAAAAMAAL//wAAAAYAUAUUAAAADAAC//8AAAAGATsBLAAAAAwAAv//AAAABgB+HOgAAAAMAAL//wAAAAYCYQDIAAAADAAC//8AAAAGAVEImAAAAAwAAv//AAAABgDJB2wAAAAMAAL//wAAAAYAUCH8AAAADAAC//8AAAAGASomSAAAAAwAAv//AAAABgIrHngAAAAMAAL//wAAAAYANgiYAAAADAAC//8AAAAGAGsTJAAAAAwAAv//AAAABgBUD6AAAAAMAAL//wAAAAYAZwSwAAAADAAC//8AAAAGARkakAAAAAwAAv//AAAABgDmINAAAAAMAAL//wAAAAYAMxV8AAAADAAC//8AAAAGAEkQzAAAAAwAAv//AAAABgB+ElwAAAAMAAL//wAAAAYAVRr0AAAADAAC//8AAAAGAGwZAAAAAAwAAv//AAAABgJpJkgAAAAKAAH//wAAAAYA6gAAAAwAAv//AAAABgIcGiwAAAAMAAL//wAAAAYAMxu8AAAADAAC//8AAAAGAg4ZZAAAAAwAAv//AAAABgJBDzwAAAAMAAL//wAAAAYBzRDMAAAADAAC//8AAAAGAHEEsAAAAAwAAv//AAAABgCXHCAAAAAMAAL//wAAAAYAUAEsAAAADAAC//8AAAAGAWMGpAAAAAwAAv//AAAABgBeJFQ=	AgBwZ19jYXRhbG9nAGpzb25iAAAAAEQAAAABAAAAAAAAAA8AAARAAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAEQAAAABAAAAAAAAAA8AAARAAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARAAAAAQAAAAAAAAzMzbIQiUcMcaINNEAhuKKEhJGUIiCk22RCwAAAAAAAAKhAAEAAAAFAAAACHVzZXItMDAzAAAACHVzZXItMDAxAAAACHVzZXItMDAyAAAACHVzZXItMDA1AAAACHVzZXItMDA0
85	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	BAAAAAAAAAAF3QAAAAAAAABgAAAAVQAAABO6qrqqq7qauwAAAAAAAAi6Gf4SqwMHCLYXgwuiDnIabwUULhYvOMwAAe+0K0YFJSwAhAZVLdxuZQwhELQHOQYcAa8ByRHODqcBjgVbDt1TIgQgeWgbMZGOBfeXQtl2LBUFGlsyGaknJwyyFasOfgQ1Ax+ARg0IEJoAYAY3MAq1owmuPbD7FSI5CbAB+xEEFG0ATkPkzTksVwERAncQfg0FAAAAAAAAAKM=	trace-1-1760805085.171576	trace-986-1760769085.171576	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABVAAAAG3RyYWNlLTExNS0xNzYwODMwODgwLjY2MzAwMAAAABt0cmFjZS04NDItMTc2MDgzMDg4MC42NjMwMDAAAAAbdHJhY2UtMTc5LTE3NjA4MzAyODUuMTcxNTc2AAAAG3RyYWNlLTg0My0xNzYwODI3MjgwLjY2MzAwMAAAABt0cmFjZS0xMjMtMTc2MDgyNjY4NS4xNzE1NzYAAAAbdHJhY2UtMjUyLTE3NjA4MjY2ODUuMTcxNTc2AAAAG3RyYWNlLTg3MC0xNzYwODIzNjgwLjY2MzAwMAAAABt0cmFjZS00NzgtMTc2MDgyMzA4NS4xNzE1NzYAAAAbdHJhY2UtNjIyLTE3NjA4MjMwODUuMTcxNTc2AAAAG3RyYWNlLTIyMC0xNzYwODIwMDgwLjY2MzAwMAAAABp0cmFjZS0yNi0xNzYwODIwMDgwLjY2MzAwMAAAABt0cmFjZS00NjMtMTc2MDgxOTQ4NS4xNzE1NzYAAAAbdHJhY2UtNTUwLTE3NjA4MTk0ODUuMTcxNTc2AAAAG3RyYWNlLTc4Ny0xNzYwODE5NDg1LjE3MTU3NgAAABt0cmFjZS04NTktMTc2MDgxOTQ4NS4xNzE1NzYAAAAbdHJhY2UtOTc5LTE3NjA4MTk0ODUuMTcxNTc2AAAAGnRyYWNlLTEyLTE3NjA4MTY0ODAuNjYzMDAwAAAAG3RyYWNlLTUxOS0xNzYwODE2NDgwLjY2MzAwMAAAABt0cmFjZS05NjQtMTc2MDgxNjQ4MC42NjMwMDAAAAAbdHJhY2UtNTY2LTE3NjA4MTU4ODUuMTcxNTc2AAAAG3RyYWNlLTkzMS0xNzYwODE1ODg1LjE3MTU3NgAAABt0cmFjZS02MzMtMTc2MDgxMjI4NS4xNzE1NzYAAAAbdHJhY2UtMjg0LTE3NjA4MDg2ODUuMTcxNTc2AAAAGXRyYWNlLTEtMTc2MDgwNTA4NS4xNzE1NzYAAAAbdHJhY2UtNTAwLTE3NjA4MDUwODUuMTcxNTc2AAAAGnRyYWNlLTc0LTE3NjA4MDUwODUuMTcxNTc2AAAAG3RyYWNlLTc4Ni0xNzYwODAyMDgwLjY2MzAwMAAAABt0cmFjZS05NDUtMTc2MDgwMjA4MC42NjMwMDAAAAAbdHJhY2UtMjI4LTE3NjA4MDE0ODUuMTcxNTc2AAAAG3RyYWNlLTc5MC0xNzYwODAxNDg1LjE3MTU3NgAAABt0cmFjZS0xMjMtMTc2MDc5ODQ4MC42NjMwMDAAAAAbdHJhY2UtMjQwLTE3NjA3OTg0ODAuNjYzMDAwAAAAG3RyYWNlLTc1OC0xNzYwNzk4NDgwLjY2MzAwMAAAABt0cmFjZS01MDUtMTc2MDc5Nzg4NS4xNzE1NzYAAAAbdHJhY2UtNjY3LTE3NjA3OTc4ODUuMTcxNTc2AAAAG3RyYWNlLTc4Ni0xNzYwNzk3ODg1LjE3MTU3NgAAABt0cmFjZS0xMDQtMTc2MDc5NDg4MC42NjMwMDAAAAAbdHJhY2UtNjIxLTE3NjA3OTQ4ODAuNjYzMDAwAAAAG3RyYWNlLTc0MS0xNzYwNzk0ODgwLjY2MzAwMAAAABt0cmFjZS04MjMtMTc2MDc5NDI4NS4xNzE1NzYAAAAbdHJhY2UtODc2LTE3NjA3OTQyODUuMTcxNTc2AAAAG3RyYWNlLTQ1Ny0xNzYwNzkxMjgwLjY2MzAwMAAAABt0cmFjZS00OTEtMTc2MDc5MDY4NS4xNzE1NzYAAAAbdHJhY2UtNDcwLTE3NjA3ODcwODUuMTcxNTc2AAAAGnRyYWNlLTg0LTE3NjA3ODcwODUuMTcxNTc2AAAAG3RyYWNlLTkwOC0xNzYwNzg3MDg1LjE3MTU3NgAAABt0cmFjZS05NjgtMTc2MDc4NzA4NS4xNzE1NzYAAAAbdHJhY2UtMTEyLTE3NjA3ODM0ODUuMTcxNTc2AAAAG3RyYWNlLTYwOS0xNzYwNzgzNDg1LjE3MTU3NgAAABt0cmFjZS04MzctMTc2MDc4MzQ4NS4xNzE1NzYAAAAbdHJhY2UtMzM1LTE3NjA3Nzk4ODUuMTcxNTc2AAAAG3RyYWNlLTQ4Ni0xNzYwNzc5ODg1LjE3MTU3NgAAABp0cmFjZS05OC0xNzYwNzc5ODg1LjE3MTU3NgAAABt0cmFjZS01NjUtMTc2MDc3Njg4MC42NjMwMDAAAAAbdHJhY2UtMjU4LTE3NjA3NzYyODUuMTcxNTc2AAAAG3RyYWNlLTU3Ni0xNzYwNzc2Mjg1LjE3MTU3NgAAABt0cmFjZS05NzEtMTc2MDc3NjI4NS4xNzE1NzYAAAAbdHJhY2UtMzAxLTE3NjA3NzMyODAuNjYzMDAwAAAAG3RyYWNlLTg1Ni0xNzYwNzcyNjg1LjE3MTU3NgAAABt0cmFjZS00MzctMTc2MDc2OTY4MC42NjMwMDAAAAAbdHJhY2UtNjE4LTE3NjA3Njk2ODAuNjYzMDAwAAAAGnRyYWNlLTc3LTE3NjA3Njk2ODAuNjYzMDAwAAAAG3RyYWNlLTQ1MC0xNzYwNzY5MDg1LjE3MTU3NgAAABt0cmFjZS03NDMtMTc2MDc2OTA4NS4xNzE1NzYAAAAbdHJhY2UtOTg2LTE3NjA3NjkwODUuMTcxNTc2AAAAG3RyYWNlLTI3Ny0xNzYwNzY2MDgwLjY2MzAwMAAAABt0cmFjZS0yODMtMTc2MDc2NjA4MC42NjMwMDAAAAAbdHJhY2UtNDU4LTE3NjA3NjYwODAuNjYzMDAwAAAAG3RyYWNlLTUwNy0xNzYwNzY2MDgwLjY2MzAwMAAAABp0cmFjZS02Mi0xNzYwNzY2MDgwLjY2MzAwMAAAABt0cmFjZS04NTYtMTc2MDc2NjA4MC42NjMwMDAAAAAadHJhY2UtMzUtMTc2MDc2NTQ4NS4xNzE1NzYAAAAbdHJhY2UtMzkyLTE3NjA3NjU0ODUuMTcxNTc2AAAAG3RyYWNlLTQ5NS0xNzYwNzY1NDg1LjE3MTU3NgAAABt0cmFjZS04MzgtMTc2MDc2MjQ4MC42NjMwMDAAAAAbdHJhY2UtNjAxLTE3NjA3NTg4ODAuNjYzMDAwAAAAG3RyYWNlLTgyMS0xNzYwNzU4ODgwLjY2MzAwMAAAABt0cmFjZS00MjYtMTc2MDc1NTI4MC42NjMwMDAAAAAbdHJhY2UtNTc0LTE3NjA3NTUyODAuNjYzMDAwAAAAG3RyYWNlLTc2MS0xNzYwNzU1MjgwLjY2MzAwMAAAABt0cmFjZS0yODEtMTc2MDc1NDY4NS4xNzE1NzYAAAAbdHJhY2UtOTEyLTE3NjA3NTQ2ODUuMTcxNTc2AAAAG3RyYWNlLTIyNy0xNzYwNzUxNjgwLjY2MzAwMAAAABt0cmFjZS00MDUtMTc2MDc0ODA4MC42NjMwMDAAAAAbdHJhY2UtNTAxLTE3NjA3NDgwODAuNjYzMDAw	2025-10-18 00:41:20.663+00	2025-10-18 23:41:20.663+00	BAAAAuRi4Ksp2AAAAAAAAAAAAAAAVQAAAEPe7N7u7u7u7u3u3e7e7u3u7t7u7u7t7u7t7u7u2+7d7gAAAAAAAA7uAAXI7E/dy7AABcjsT93LrwAAAABG/PS/AAAAAR8tXn8AAAABHy1egAAAAABG/PTAAAAAAWYqUz8AAAABHy1egAAAAABG/PTAAAAAAWYqUz8AAAABZipTQEb89MBG/PS/AAAAAAAAAAAAAAABZipTPwAAAAFmKlNARvz0vwAAAAAAAAAARvz0wAAAAAGtJ0f/AAAAAAAAAAAAAAABrSdIAAAAAAAAAAAAAAAAAWYqUz8AAAABZipTQEb89MBG/PS/AAAAAWYqUz8AAAABZipTQEb89L8AAAAAAAAAAEb89MAAAAABZipTPwAAAAFmKlNARvz0vwAAAAAAAAAARvz0wAAAAAFmKlM/AAAAAR8tXoAAAAABZipTPwAAAAGtJ0gAAAAAAAAAAAAAAAABrSdH/wAAAAGtJ0gAAAAAAAAAAAAAAAABrSdH/wAAAAGtJ0gAAAAAAAAAAAAAAAABZipTPwAAAAEfLV6AAAAAAEb89MAAAAABZipTPwAAAAEfLV6AAAAAAR8tXn8AAAABZipTQEb89L8AAAAAAAAAAEb89MAAAAABZipTPwAAAAFmKlNAAAAAAAAAAABG/PTARvz0vwAAAAAAAAAAAAAAAWYqUz8AAAAARvz0vwAAAAGtJ0gAAAAAAa0nR/8AAAABrSdIAEb89L8AAAAAAAAAAEb89MAAAAABZipTPwAAAABG/PS/AAAAAa0nSAA=	BAAAAAAAAAAGlAAAAAAAAALIAAAAVQAAABSrq7u7uruquwAAAAAAALu7F2EM7AYLBRYFhQGiBEcQ4gR5QeAAQiEjAf1P9rIzBlEPCgEyDwcOLBc+MaUhthL1AVwJkWgU0jMi3As/CUsL9AB/GQINMx+bAs8HCRJqEZcX+Qe6BEIGxghUEQ4QTwsuGpwjhx/gGLcNhfhIJSLYIQaADGMElxEyCbWQ4DFv804MQhTpB8US5hCBB/ELdgIcCuUAAAJrEqADdAuWFNMTtA==	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABVAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDExNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTc5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg0MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMjMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjUyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg3MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NzgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjIyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIyMAAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NjMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTUwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc4NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NTkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTc5AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDEyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUxOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NjQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTY2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkzMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MzMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjg0AAAAJVNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTAwAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc4NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NDUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjI4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc5MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMjMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjQwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc1OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MDUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjY3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc4NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMDQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjIxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc0MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MjMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODc2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ1NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0OTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDcwAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkwOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NjgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTEyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYwOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MzcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzM1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ4NgAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1NjUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjU4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU3NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NzEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzAxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg1NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MzcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjE4AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ1MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NDMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTg2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI3NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyODMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDU4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUwNwAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NTYAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzkyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ5NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MzgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjAxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgyMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MjYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTc0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc2MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyODEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTEyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIyNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MDUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTAx	AgFwZ19jYXRhbG9nAHRleHQAAAAANgAAAAUAAAAAAAZmVP7cuph2VDIQDNcBvatJyjAI4oYH3nXG2gtsrqponmlkAAAADLHC+6gAAABVAAAAAgAAAAAAAAAR2AB2laAAQgsAAAAAAAxfmAABAAAAMwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE3OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEyMwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI1MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg3MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ3OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYyMgAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDYzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTUwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzg3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTc5AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1MTkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5NjQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1NjYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MzEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MzMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyODQAAAAtU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTAwAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3ODYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5NDUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMjgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1MDUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MjEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3NDEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NzYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0NzAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMTIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MDkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MzcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMzUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0ODYAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU2NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI1OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU3NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk3MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDMwMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg1NgAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTg2AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjc3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjgzAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0MjYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3NjEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyODEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MTIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1MDE=	AgFwZ19jYXRhbG9nAHRleHQAAAAAHwAAAAIAAAAAAAAARCgnImJSQyIQAiItyyopIiIAAABVAAAAAgAAAAAAAAARJ/+Jal//vfQAAAAAABOgZwABAAAADgAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgNjUxbXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDUyOG1zAAAAH1NhbXBsZSBlcnJvciBtZXNzYWdlOiBBUElfRVJST1IAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDM2Mm1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA0MjRtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTg1OW1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA0ODNtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTU2bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDMyMjJtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgNzc4bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDY4NG1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciAyNDRtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTYyNm1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxOTkxbXM=	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAVQAAAAMAAAAAAAACIpFVVVVFWVWQppVVVWJJlGQAAAGlZgIWFQABAAAAAwAAAAd0aW1lb3V0AAAAB3N1Y2Nlc3MAAAAFZXJyb3I=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAVQAAAAMAAAAAAAACIscFnWrQxOXkMH8rwFTCopYAAABwyk/73QABAAAABAAAAAtncHQtNC10dXJibwAAAAxtaXh0cmFsLTh4N2IAAAAKZ2VtaW5pLXBybwAAAA1jbGF1ZGUtMy1vcHVz	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAVQAAAAMAAAAAAAACIscFnWrQxOXkMH8rwFTCopYAAABwyk/73QABAAAABAAAAAZvcGVuYWkAAAAHbWlzdHJhbAAAAAZnb29nbGUAAAAJYW50aHJvcGlj	BAAAAAAAAAAA/f////////+WAAAAVQAAABCZqaqaqqmZqgJYRhQ2XXPYAWIqc+RHsg4FStFQPg+cVgWONKfEaCGnDJmvsJHdnzoFb1OihQ8CrwOqEBGwHHLmAstOYp8qhSMBBgUDI1YDcQTNWW8Focw9AjsWQcEe4B4CUhu0VGr0xAn0U7B/gm3xAkFCY3EZ9L4K/xrP2mTmPAAAAAYLd1bw	BAAAAAAAAAAAxAAAAAAAAABMAAAAVQAAAA8FmZmZmZmZmQEhfX+TEChyBQXoUEshlAAFCcMWC+HMNgVkOFWPUaxyBDzmBIjhPHgDxDYhANQBEwUsrFfSYSgOAXSuFMLiDTYGERcBxcF8OgkFdCHb6EQWCBIlbIqQGRwDFAosWuKlUQI4XABMyI3uBqEtK1SBXP0AAAAAAAAAEA==	BAAAAAAAAAABwP////////9fAAAAVQAAABGqqqqqqqqaqgAAAAAAAAAKBXo5Ee0D0kIDnGI0xDGQ8wSIRxF8DEA7DJiaSyiUerEGVT3Amz3GoQTvQsNXCuPWAREVcxBCtGgH+Dszsy+BrACxB+GtJUUFAfQwVC4vUdoEkUpA7RRQawRyJ9AmScHzBKSCc6pCR2kFzAVi8zLTiATdUkS5NcUJBuEo4ZYLARgAABQTX0gCOg==	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAFUAAAACAAAAAAAAABHYAHaVoABCCwAAAAAADF+YAQAAADYAAAAMAAL//wAAAAYAYRlkAAAADAAC//8AAAAGADsD6AAAAAwAAv//AAAABgBBGQAAAAAMAAL//wAAAAYAeAlgAAAADAAC//8AAAAGAKkI/AAAAAwAAv//AAAABgHRCPwAAAAMAAL//wAAAAYCIxnIAAAADAAC//8AAAAGAbMH0AAAAAwAAv//AAAABgCtDBwAAAAMAAL//wAAAAYBwhg4AAAADAAC//8AAAAGAgkchAAAAAwAAv//AAAABgDWF9QAAAAMAAL//wAAAAYATiH8AAAADAAC//8AAAAGAGsgCAAAAAwAAv//AAAABgBwD6AAAAAMAAL//wAAAAYAdgnEAAAADAAC//8AAAAGAqsRMAAAAAwAAv//AAAABgBFBqQAAAAMAAL//wAAAAYAghfUAAAADAAC//8AAAAGAFADhAAAAAwAAv//AAAABgAnIsQAAAAMAAL//wAAAAYCHiMoAAAADAAC//8AAAAGAgcNSAAAAAwAAv//AAAABgEHFXwAAAAMAAL//wAAAAYAcQOEAAAADAAC//8AAAAGAFUD6AAAAAwAAv//AAAABgBQCvAAAAAMAAL//wAAAAYCOgdsAAAADAAC//8AAAAGAGEUtAAAAAwAAv//AAAABgBoGpAAAAAMAAL//wAAAAYB2h2wAAAADAAC//8AAAAGACID6AAAAAwAAv//AAAABgDeAMgAAAAMAAL//wAAAAYCISasAAAADAAC//8AAAAGASUbvAAAAAwAAv//AAAABgFkDBwAAAAMAAL//wAAAAYB6xPsAAAADAAC//8AAAAGAI4ZZAAAAAwAAv//AAAABgCGHUwAAAAMAAL//wAAAAYBIwlgAAAADAAC//8AAAAGAoYF3AAAAAwAAv//AAAABgDEIAgAAAAMAAL//wAAAAYBVhr0AAAADAAC//8AAAAGAjYETAAAAAwAAv//AAAABgBAHtwAAAAMAAL//wAAAAYCIQyAAAAADAAC//8AAAAGAF0h/AAAAAwAAv//AAAABgDeIygAAAAMAAL//wAAAAYCFgooAAAADAAC//8AAAAGAMMHCAAAAAwAAv//AAAABgHiF3AAAAAMAAL//wAAAAYB5ABkAAAADAAC//8AAAAGAe4I/AAAAAwAAv//AAAABgBrCJg=	AgBwZ19jYXRhbG9nAGpzb25iAAAAAFUAAAABAAAAAAAAAA8AAAVQAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAFUAAAABAAAAAAAAAA8AAAVQAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAVQAAAAUAAAAAAAIzMwBcSYQjZISINMkOFIMhuMIUE04SYCDIwhJjhMIThgiBAAAAAAAAAAMAAQAAAAUAAAAIdXNlci0wMDIAAAAIdXNlci0wMDMAAAAIdXNlci0wMDQAAAAIdXNlci0wMDEAAAAIdXNlci0wMDU=
\.


--
-- Data for Name: compress_hyper_6_16_chunk; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: postgres
--

COPY _timescaledb_internal.compress_hyper_6_16_chunk (_ts_meta_count, workspace_id, agent_id, id, _ts_meta_min_2, _ts_meta_max_2, trace_id, _ts_meta_min_1, _ts_meta_max_1, "timestamp", latency_ms, input, output, error, _ts_meta_min_4, _ts_meta_max_4, status, _ts_meta_min_3, _ts_meta_max_3, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, _ts_meta_min_5, _ts_meta_max_5, tags, _ts_meta_v2_bloom1_user_id, user_id) FROM stdin;
69	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-claude	BAAAAAAAAAADrv////////84AAAARQAAAA8Kqqqqq6qrugy5IrGJUxkEEnsDhwsSCr4KjQZOD7EXogD+EEU6LvpoBE3piVkup9sMOIvwXAwQFwLUC/ERlA6lBYRZU19MAtAA8WP9gqPw7wQ4jtECh+IFDNMUpbhWcXgK7R1SpyXMNAx4hPN1AU4uCu5rEjgHREEAAAAAAFFN+w==	trace-113-1760838080.663000	trace-999-1760841085.171576	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABFAAAAG3RyYWNlLTE1NC0xNzYwOTE3MjgwLjY2MzAwMAAAABt0cmFjZS02NDMtMTc2MDkxNzI4MC42NjMwMDAAAAAbdHJhY2UtOTM1LTE3NjA5MTcyODAuNjYzMDAwAAAAG3RyYWNlLTk0OS0xNzYwOTE3MjgwLjY2MzAwMAAAABt0cmFjZS0zMzQtMTc2MDkxNjY4NS4xNzE1NzYAAAAadHJhY2UtOTQtMTc2MDkxNjY4NS4xNzE1NzYAAAAbdHJhY2UtMjcxLTE3NjA5MTM2ODAuNjYzMDAwAAAAG3RyYWNlLTk5Ni0xNzYwOTEzNjgwLjY2MzAwMAAAABt0cmFjZS0zNTUtMTc2MDkxMzA4NS4xNzE1NzYAAAAbdHJhY2UtNzM5LTE3NjA5MTAwODAuNjYzMDAwAAAAG3RyYWNlLTExNC0xNzYwOTA2NDgwLjY2MzAwMAAAABt0cmFjZS0yOTYtMTc2MDkwNjQ4MC42NjMwMDAAAAAbdHJhY2UtMTI3LTE3NjA5MDU4ODUuMTcxNTc2AAAAG3RyYWNlLTI5MC0xNzYwOTA1ODg1LjE3MTU3NgAAABp0cmFjZS03Ny0xNzYwOTA1ODg1LjE3MTU3NgAAABt0cmFjZS01MzMtMTc2MDkwMjI4NS4xNzE1NzYAAAAbdHJhY2UtMTE5LTE3NjA4OTU2ODAuNjYzMDAwAAAAG3RyYWNlLTgzMi0xNzYwODk1NjgwLjY2MzAwMAAAABt0cmFjZS01MzktMTc2MDg5MjA4MC42NjMwMDAAAAAbdHJhY2UtNjE5LTE3NjA4OTIwODAuNjYzMDAwAAAAG3RyYWNlLTUwMi0xNzYwODkxNDg1LjE3MTU3NgAAABt0cmFjZS0yNTMtMTc2MDg4ODQ4MC42NjMwMDAAAAAbdHJhY2UtNDUzLTE3NjA4ODg0ODAuNjYzMDAwAAAAG3RyYWNlLTY0MS0xNzYwODg4NDgwLjY2MzAwMAAAABt0cmFjZS03MzItMTc2MDg4ODQ4MC42NjMwMDAAAAAbdHJhY2UtODY5LTE3NjA4ODg0ODAuNjYzMDAwAAAAG3RyYWNlLTg4Ni0xNzYwODg3ODg1LjE3MTU3NgAAABt0cmFjZS00NjctMTc2MDg4NDg4MC42NjMwMDAAAAAbdHJhY2UtMTczLTE3NjA4ODQyODUuMTcxNTc2AAAAG3RyYWNlLTEyOS0xNzYwODgxMjgwLjY2MzAwMAAAABt0cmFjZS01NTYtMTc2MDg4MDY4NS4xNzE1NzYAAAAbdHJhY2UtMzQ1LTE3NjA4NzcwODUuMTcxNTc2AAAAG3RyYWNlLTQ5NC0xNzYwODc3MDg1LjE3MTU3NgAAABt0cmFjZS0yNTEtMTc2MDg3NDA4MC42NjMwMDAAAAAbdHJhY2UtNTc2LTE3NjA4NzQwODAuNjYzMDAwAAAAG3RyYWNlLTE4Ni0xNzYwODcwNDgwLjY2MzAwMAAAABt0cmFjZS01MDItMTc2MDg3MDQ4MC42NjMwMDAAAAAbdHJhY2UtNjk4LTE3NjA4NzA0ODAuNjYzMDAwAAAAG3RyYWNlLTU4Mi0xNzYwODY5ODg1LjE3MTU3NgAAABt0cmFjZS0xOTUtMTc2MDg2Njg4MC42NjMwMDAAAAAZdHJhY2UtOC0xNzYwODY2ODgwLjY2MzAwMAAAABt0cmFjZS03MDAtMTc2MDg2NjI4NS4xNzE1NzYAAAAbdHJhY2UtMTMzLTE3NjA4NjI2ODUuMTcxNTc2AAAAG3RyYWNlLTY1My0xNzYwODYyNjg1LjE3MTU3NgAAABt0cmFjZS0zMDItMTc2MDg1OTY4MC42NjMwMDAAAAAbdHJhY2UtODA4LTE3NjA4NTkwODUuMTcxNTc2AAAAG3RyYWNlLTg1NC0xNzYwODU5MDg1LjE3MTU3NgAAABp0cmFjZS04OC0xNzYwODU2MDgwLjY2MzAwMAAAABt0cmFjZS02MzAtMTc2MDg1NTQ4NS4xNzE1NzYAAAAbdHJhY2UtOTA0LTE3NjA4NTU0ODUuMTcxNTc2AAAAG3RyYWNlLTM0My0xNzYwODUyNDgwLjY2MzAwMAAAABt0cmFjZS0xNDAtMTc2MDg1MTg4NS4xNzE1NzYAAAAbdHJhY2UtNDk5LTE3NjA4NTE4ODUuMTcxNTc2AAAAG3RyYWNlLTE2MC0xNzYwODQ4ODgwLjY2MzAwMAAAABt0cmFjZS00ODEtMTc2MDg0ODg4MC42NjMwMDAAAAAbdHJhY2UtNTY3LTE3NjA4NDg4ODAuNjYzMDAwAAAAG3RyYWNlLTI1NC0xNzYwODQ4Mjg1LjE3MTU3NgAAABt0cmFjZS03NTYtMTc2MDg0ODI4NS4xNzE1NzYAAAAbdHJhY2UtMjY4LTE3NjA4NDUyODAuNjYzMDAwAAAAG3RyYWNlLTMzNy0xNzYwODQ1MjgwLjY2MzAwMAAAABt0cmFjZS0zNDItMTc2MDg0NDY4NS4xNzE1NzYAAAAbdHJhY2UtOTQzLTE3NjA4NDQ2ODUuMTcxNTc2AAAAG3RyYWNlLTk5OS0xNzYwODQxMDg1LjE3MTU3NgAAABt0cmFjZS0xMTMtMTc2MDgzODA4MC42NjMwMDAAAAAbdHJhY2UtNTExLTE3NjA4MzgwODAuNjYzMDAwAAAAGnRyYWNlLTUyLTE3NjA4MzgwODAuNjYzMDAwAAAAG3RyYWNlLTk5Mi0xNzYwODM4MDgwLjY2MzAwMAAAABt0cmFjZS0xNDItMTc2MDgzNDQ4MC42NjMwMDAAAAAbdHJhY2UtOTQyLTE3NjA4MzM4ODUuMTcxNTc2	2025-10-19 00:31:25.171576+00	2025-10-19 23:41:20.663+00	BAAAAuR22wQPeP/////cgYWgAAAARQAAADzu7u3u7u7d7u7u7u7u7O7u7u7u7u7u7u0AAO7e7t7u3gAFyRSLjIuwAAXJFIuMi68AAAAAAAAAAEb89MBG/PS/AAAAAWYqUz8AAAABZipTQAAAAABG/PS/AAAAAR8tXn8AAAAARvz0vwAAAAGtJ0gARvz0wEb89L8AAAAAAAAAAAAAAAGtJ0f/AAAAAWYqUz8AAAADE1GbQAAAAAGtJ0f/AAAAAa0nSAAAAAAARvz0vwAAAAEfLV5/AAAAAWYqU0AAAAAAAAAAAAAAAABG/PS/AAAAAR8tXn8AAAABHy1egAAAAAEfLV5/AAAAAR8tXoAAAAABZipTPwAAAAGtJ0gAAAAAAWYqUz8AAAABZipTQAAAAAGtJ0f/AAAAAa0nSABG/PS/AAAAAAAAAAEfLV5/AAAAAWYqU0AAAAAARvz0vwAAAAFmKlM/AAAAAa0nSAAAAAABZipTPwAAAAEfLV6AAAAAAEb89MAAAAABZipTPwAAAAEfLV6AAAAAAEb89MAAAAABZipTPwAAAAEfLV6AAAAAAEb89MAAAAABZipTPwAAAAFmKlNARvz0vwAAAAAAAAAARvz0wAAAAAFmKlM/AAAAAWYqU0BG/PTARvz0vwAAAAGtJ0f/AAAAAEb89MAAAAABZipTQAAAAAAAAAAAAAAAAa0nR/8AAAABZipTQA==	BAAAAAAAAAAHWgAAAAAAAAIWAAAARQAAABG7urq7u7u7ugAAAAAAAAAKA60mwl2s2kQM6wXjCXoDEBE+B5MMyxY8AZsRexmgEu0xByDsCgkFyAbwA+YZIyYcAloT2ByBDh4NpRFqBMwQEQ2dEgwCWwRFFe4YJxZACDcJNroxPyk2FxKdB54AKgRKB+87CSPBheQNDAu0EPcMlBVAAZ0YZiNtBTwPWyX4NysAAAAAAEdbtA==	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABFAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE1NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NDMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTM1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk0OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMzQAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjcxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk5NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNTUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzM5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDExNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyOTYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTI3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI5MAAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MzMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTE5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgzMgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MzkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjE5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUwMgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNTMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDUzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY0MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MzIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODY5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg4NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NjcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTczAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDEyOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1NTYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzQ1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ5NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTc2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE4NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjk4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU4MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxOTUAAAAlU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MDAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTMzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY1MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODA4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg1NAAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MzAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTA0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM0MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNDAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDk5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE2MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0ODEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTY3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI1NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NTYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjY4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMzNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTQzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk5OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMTMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTExAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk5MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTQy	AQFwZ19jYXRhbG9nAHRleHQAAQAAAEUAAAACAAAAAAAAABGJQPDUrkGCIAAAAAAAAAAEAQAAAC4AAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNTQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NDMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MzUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5NDkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMzQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyNzEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5OTYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNTUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMTQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyOTYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMjcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyOTAAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgzMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUzOQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYxOQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUwMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI1MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY0MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDczMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE3MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU1NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ5NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI1MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE4NgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY5OAAAAC1TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3MDAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMzMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NTMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MzAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MDQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNDMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNDAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0OTkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNjAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1NjcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3NTYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyNjgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNDIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5NDMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5OTkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1MTEAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE0MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk0Mg==	AgFwZ19jYXRhbG9nAHRleHQAAAAAFwAAAAIAAAAAAAAAVNy6mHYVQyEQAAAABEMAhe4AAABFAAAAAgAAAAAAAAARdr8PK1G+fd8AAAAAAAAAGwABAAAAEgAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTM3bXMAAAAfU2FtcGxlIGVycm9yIG1lc3NhZ2U6IEFQSV9FUlJPUgAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTQ4Nm1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxMTk5bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDIwMDRtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTI0bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDY0OW1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxOTE0bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDUxOG1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxNjk3bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE4NzdtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMjk5bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDUyNG1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciAxNzJtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMzY5bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDU4N21zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA2NzFtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMjQzbXM=	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARQAAAAMAAAAAAAABIkSUEAGACAQAgEIgAFUAURAAAAAAAAAABAABAAAAAwAAAAdzdWNjZXNzAAAAB3RpbWVvdXQAAAAFZXJyb3I=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARQAAAAMAAAAAAAACIq1UxWa/ZbkkzWKbuCYKFsUAAAAAAAAAhwABAAAABAAAAAtncHQtNC10dXJibwAAAA1jbGF1ZGUtMy1vcHVzAAAADG1peHRyYWwtOHg3YgAAAApnZW1pbmktcHJv	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARQAAAAMAAAAAAAACIq1UxWa/ZbkkzWKbuCYKFsUAAAAAAAAAhwABAAAABAAAAAZvcGVuYWkAAAAJYW50aHJvcGljAAAAB21pc3RyYWwAAAAGZ29vZ2xl	BAAAAAAAAAABiQAAAAAAAAD2AAAARQAAAA0ACaqqmZqqmQX5Mi5U1nZCBiQ+COH/CrUA1j9VZDvyigJ0GYJFJ0FRAWgVQ3crxC8BkToDHhQVIAl10J13imReCYe6SEZ09pwCcAfgeCQxLAP4I3QbZSULAyUZo0kqgXEB5RUD7Gz2KAAAAMINUyEn	BAAAAAAAAAAA0AAAAAAAAABsAAAARQAAAAwAAJmZmZmZmQd05iRL5t1GAvTxbBDTTlAGZIoRQTKQfATUGk2oFjEIA4V8YEVB9ZoAZFAklfSIAwPgkVHTgFQ7AY0+F1ASOCAFhIAF0UDs3wVALzJPlug0AvSyDUOhoRsAAAAAFqTk0A==	BAAAAAAAAAAC5wAAAAAAAAKaAAAARQAAAA4AqqmqqqqqqgLzCjOsY9PkAztSxOkgAloC8E+SbjOzQAIQDtJ9LICUAq4R8e1jZdkCM0l3WmQRIAMgCLCBSZbqBzJgd0hwsVQCTzThVBwm+wAgGXCUVaVxCNat4AEpfNQAawYEKRfkFgM2ByDuVDS+AAAACfpcsas=	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAEUAAAACAAAAAAAAABGJQPDUrkGCIAAAAAAAAAAEAQAAAC4AAAAMAAL//wAAAAYBdyGYAAAADAAC//8AAAAGAhsfQAAAAAwAAv//AAAABgAxElwAAAAMAAL//wAAAAYBORBoAAAADAAC//8AAAAGARgM5AAAAAwAAv//AAAABgB5H0AAAAAMAAL//wAAAAYAPBXgAAAADAAC//8AAAAGArQmrAAAAAwAAv//AAAABgCBGiwAAAAMAAL//wAAAAYCAASwAAAADAAC//8AAAAGAOAmSAAAAAwAAv//AAAABgBBIGwAAAAMAAL//wAAAAYAPwiYAAAADAAC//8AAAAGAjYCWAAAAAwAAv//AAAABgAnGWQAAAAMAAL//wAAAAYBZAfQAAAADAAC//8AAAAGAn8T7AAAAAwAAv//AAAABgGqFLQAAAAMAAL//wAAAAYAxxZEAAAADAAC//8AAAAGAPQjjAAAAAwAAv//AAAABgLXEfgAAAAMAAL//wAAAAYALwrwAAAADAAC//8AAAAGAPgVGAAAAAwAAv//AAAABgKUE+wAAAAMAAL//wAAAAYA0B4UAAAADAAC//8AAAAGAuQGQAAAAAwAAv//AAAABgA9HbAAAAAMAAL//wAAAAYAMRJcAAAADAAC//8AAAAGAdMCWAAAAAwAAv//AAAABgFfGiwAAAAMAAL//wAAAAYB4AH0AAAADAAC//8AAAAGACMbWAAAAAwAAv//AAAABgDLBEwAAAAMAAL//wAAAAYAPhGUAAAADAAC//8AAAAGAHATJAAAAAwAAv//AAAABgAgB2wAAAAMAAL//wAAAAYAfREwAAAADAAC//8AAAAGAPkV4AAAAAwAAv//AAAABgBxC7gAAAAMAAL//wAAAAYCigRMAAAACgAB//8AAAAGANoAAAAMAAL//wAAAAYBwhLAAAAADAAC//8AAAAGAJgM5AAAAAwAAv//AAAABgFiF9QAAAAMAAL//wAAAAYAeRZEAAAADAAC//8AAAAGAH4e3A==	AgBwZ19jYXRhbG9nAGpzb25iAAAAAEUAAAABAAAAAAAAAA8AAARQAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAEUAAAABAAAAAAAAAA8AAARQAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARQAAAAQAAAAAAAAzM0cDAcgbTbSINsKNxFqAqBIBCAUohEFHFAAAAAAAACjhAAEAAAAFAAAACHVzZXItMDAyAAAACHVzZXItMDAxAAAACHVzZXItMDAzAAAACHVzZXItMDA0AAAACHVzZXItMDA1
57	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gemini	BAAAAAAAAAAGZwAAAAAAAANZAAAAOQAAAA0ACquqq7upqwdtFWQaOQ5iChKSlriaTdUD86svyODv8wzehnJjN4GAEV4GVQI/BMsQoBSZEWgRoxF+CwcCggTPDDQKrXGtDdsAaZ3tqSkDwwaYYdGILbOCD5UQJgj7ATcLNNyRZCDG0gAAAAAAAAWa	trace-102-1760856080.663000	trace-983-1760845280.663000	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAAA5AAAAG3RyYWNlLTg0MS0xNzYwOTE3MjgwLjY2MzAwMAAAABt0cmFjZS0zMjUtMTc2MDkxNjY4NS4xNzE1NzYAAAAbdHJhY2UtNTQ3LTE3NjA5MTM2ODAuNjYzMDAwAAAAG3RyYWNlLTgxOC0xNzYwOTEzNjgwLjY2MzAwMAAAABt0cmFjZS0zMTgtMTc2MDkwOTQ4NS4xNzE1NzYAAAAadHJhY2UtNTItMTc2MDkwOTQ4NS4xNzE1NzYAAAAbdHJhY2UtNjQ2LTE3NjA5MDk0ODUuMTcxNTc2AAAAGnRyYWNlLTY3LTE3NjA5MDk0ODUuMTcxNTc2AAAAG3RyYWNlLTc3Ny0xNzYwOTA5NDg1LjE3MTU3NgAAABt0cmFjZS05ODEtMTc2MDkwOTQ4NS4xNzE1NzYAAAAbdHJhY2UtMTU1LTE3NjA5MDY0ODAuNjYzMDAwAAAAG3RyYWNlLTQwMC0xNzYwOTA2NDgwLjY2MzAwMAAAABt0cmFjZS01NDktMTc2MDkwNjQ4MC42NjMwMDAAAAAbdHJhY2UtMjI4LTE3NjA5MDI4ODAuNjYzMDAwAAAAGnRyYWNlLTMzLTE3NjA5MDI4ODAuNjYzMDAwAAAAGnRyYWNlLTMwLTE3NjA4OTkyODAuNjYzMDAwAAAAG3RyYWNlLTQ3MS0xNzYwODk5MjgwLjY2MzAwMAAAABt0cmFjZS02MDYtMTc2MDg5OTI4MC42NjMwMDAAAAAbdHJhY2UtNjY1LTE3NjA4OTg2ODUuMTcxNTc2AAAAG3RyYWNlLTM3MS0xNzYwODk1NjgwLjY2MzAwMAAAABt0cmFjZS00NjMtMTc2MDg5NTY4MC42NjMwMDAAAAAbdHJhY2UtMjY3LTE3NjA4OTIwODAuNjYzMDAwAAAAG3RyYWNlLTI2MC0xNzYwODkxNDg1LjE3MTU3NgAAABt0cmFjZS00NzYtMTc2MDg4ODQ4MC42NjMwMDAAAAAbdHJhY2UtNDM0LTE3NjA4ODc4ODUuMTcxNTc2AAAAG3RyYWNlLTYyMC0xNzYwODg0ODgwLjY2MzAwMAAAABt0cmFjZS0xNjktMTc2MDg4NDI4NS4xNzE1NzYAAAAbdHJhY2UtODQ2LTE3NjA4ODQyODUuMTcxNTc2AAAAG3RyYWNlLTkwNy0xNzYwODg0Mjg1LjE3MTU3NgAAABt0cmFjZS0yODktMTc2MDg4MTI4MC42NjMwMDAAAAAbdHJhY2UtMjU5LTE3NjA4ODA2ODUuMTcxNTc2AAAAG3RyYWNlLTQ2OC0xNzYwODc3NjgwLjY2MzAwMAAAABt0cmFjZS05MDMtMTc2MDg3NzA4NS4xNzE1NzYAAAAbdHJhY2UtNzIyLTE3NjA4NzQwODAuNjYzMDAwAAAAG3RyYWNlLTgyMC0xNzYwODczNDg1LjE3MTU3NgAAABl0cmFjZS0zLTE3NjA4Njk4ODUuMTcxNTc2AAAAG3RyYWNlLTc0OC0xNzYwODY5ODg1LjE3MTU3NgAAABp0cmFjZS0xMS0xNzYwODYzMjgwLjY2MzAwMAAAABt0cmFjZS02MDItMTc2MDg2MzI4MC42NjMwMDAAAAAbdHJhY2UtNDQ0LTE3NjA4NjI2ODUuMTcxNTc2AAAAG3RyYWNlLTU0OS0xNzYwODYyNjg1LjE3MTU3NgAAABt0cmFjZS02MDEtMTc2MDg1OTA4NS4xNzE1NzYAAAAbdHJhY2UtMTAyLTE3NjA4NTYwODAuNjYzMDAwAAAAG3RyYWNlLTIzNy0xNzYwODU2MDgwLjY2MzAwMAAAABt0cmFjZS01NjgtMTc2MDg1MjQ4MC42NjMwMDAAAAAbdHJhY2UtMTE2LTE3NjA4NDg4ODAuNjYzMDAwAAAAG3RyYWNlLTUwOC0xNzYwODQ4ODgwLjY2MzAwMAAAABt0cmFjZS03NDQtMTc2MDg0ODg4MC42NjMwMDAAAAAbdHJhY2UtODMwLTE3NjA4NDgyODUuMTcxNTc2AAAAG3RyYWNlLTk4My0xNzYwODQ1MjgwLjY2MzAwMAAAABt0cmFjZS0xNDEtMTc2MDgzODA4MC42NjMwMDAAAAAbdHJhY2UtMTcyLTE3NjA4MzgwODAuNjYzMDAwAAAAG3RyYWNlLTQ2NS0xNzYwODM4MDgwLjY2MzAwMAAAABt0cmFjZS05MzYtMTc2MDgzODA4MC42NjMwMDAAAAAbdHJhY2UtNjQyLTE3NjA4Mzc0ODUuMTcxNTc2AAAAG3RyYWNlLTc4Mi0xNzYwODM3NDg1LjE3MTU3NgAAABt0cmFjZS02MzktMTc2MDgzNDQ4MC42NjMwMDA=	2025-10-19 00:41:20.663+00	2025-10-19 23:41:20.663+00	BAAAAuR2/oKJ2P////9M6tZgAAAAOQAAADDt7u7u6+7u7u7u7u7e7u7u7d7u3u7u7e4ABckUi4yLsAAFyRTSiYBvAAAAAR8tXn8AAAABZipTQAAAAAH0JDy/AAAAAfQkPMAAAAAAAAAAAAAAAAFmKlM/AAAAAWYqU0AAAAAAAAAAAAAAAAGtJ0f/AAAAAa0nSAAAAAABrSdH/wAAAAGtJ0gARvz0vwAAAAAAAAABHy1efwAAAAFmKlNAAAAAAa0nR/8AAAABZipTQAAAAAEfLV5/AAAAAR8tXoAAAAABHy1efwAAAAEfLV6AAAAAAEb89MAAAAABZipTPwAAAAEfLV6AAAAAAR8tXn8AAAABHy1egAAAAAEfLV5/AAAAAR8tXoAAAAABZipTPwAAAAGtJ0gAAAAAAxNRmz8AAAADE1GbQEb89MBG/PS/AAAAAa0nR/8AAAAARvz0wAAAAAFmKlNAAAAAAa0nR/8AAAAAAAAAAAAAAAGtJ0gARvz0vwAAAAAAAAABHy1efwAAAAH0JDy/AAAAA1pOkAAAAAAAAAAAAEb89MBG/PS/AAAAAWYqUz8=	BAAAAAAAAAARLQAAAAAAAA6xAAAAOQAAAA4Au7u7qru7uxPmEPMExgO8D1gK0BqTAaMIzwIsDdQUGwO1C5wTDQyMMhEPTgFrB/wMRgGZDOcowgUULx+4blvzAMxgLzf470EUHxD7D4wDEhIDFi4WBx2+EwcGAASUBMgk1xxmF0cYJAhfAXsEJhRaAAAZXA8YBuU=	AQBwZ19jYXRhbG9nAHRleHQAAAEAAAA5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg0MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMjUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTQ3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgxOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMTgAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjQ2AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc3NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5ODEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTU1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQwMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1NDkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjI4AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMzAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ3MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MDYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjY1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM3MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NjMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjY3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI2MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0NzYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDM0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYyMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNjkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODQ2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkwNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyODkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjU5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ2OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MDMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzIyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgyMAAAACVTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc0OAAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MDIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDQ0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU0OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MDEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTAyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIzNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1NjgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTE2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUwOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NDQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODMwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk4MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNDEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTcyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ2NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MzYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjQyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc4MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2Mzk=	AQFwZ19jYXRhbG9nAHRleHQAAQAAADkAAAABAAAAAAAAAAEAkPJaMFMCEgEAAAAlAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODQxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTQ3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODE4AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NDYAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc3NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE1NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQwMAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU0OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDIyOAAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDMzAAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2NjUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNzEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyNjcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0NzYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0MzQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MjAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxNjkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NDYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyNTkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0NjgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MDMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MjAAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQ0NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU0OQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEwMgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDIzNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDgzMAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk4MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE0MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE3MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDkzNgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY0MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYzOQ==	AgFwZ19jYXRhbG9nAHRleHQAAAAAFAAAAAIAAAAAAAAARIdlFBExEhEQAAAAAAAAGpEAAAA5AAAAAQAAAAAAAAABAW8Npc+s/e0AAQAAAAsAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE1NjdtcwAAAB9TYW1wbGUgZXJyb3IgbWVzc2FnZTogQVBJX0VSUk9SAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxODYybXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDIwMjVtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMzE1MW1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAyMDczbXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDk0NW1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxODIwbXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDM4M21zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA3MDltcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMjA3Mm1z	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAOQAAAAIAAAAAAAAAIgkAIgYACAIEAACBAGUEEkgAAQAAAAMAAAAHc3VjY2VzcwAAAAd0aW1lb3V0AAAABWVycm9y	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAOQAAAAIAAAAAAAAAIplWtI+9x3ukAALIwpxF798AAQAAAAQAAAANY2xhdWRlLTMtb3B1cwAAAAtncHQtNC10dXJibwAAAApnZW1pbmktcHJvAAAADG1peHRyYWwtOHg3Yg==	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAOQAAAAIAAAAAAAAAIplWtI+9x3ukAALIwpxF798AAQAAAAQAAAAJYW50aHJvcGljAAAABm9wZW5haQAAAAZnb29nbGUAAAAHbWlzdHJhbA==	BAAAAAAAAAABW/////////82AAAAOQAAAAsAAAmpqaqZmQuNSguQa04GAVWPwQVc5yANkT9KXSHMMgmS0fiftJ0nANIJ8P0WkFIEGh5z9Gm0MgyS6WKCQE9xB2hsc4YMgsEK+4O2AMV/oQEAKyRbGcABAAAAAAAAAzE=	BAAAAAAAAAAAhv/////////jAAAAOQAAAAoAAACZmZmZmQDsLUyL1zWqBMwVD1UFLIoDOH9EVugWagU0r1gbtBgOAAC4G9QzKYQGXh6BS4HYTwDowXafctimA6kUnGzIvLIGUY+FDVGs1QAAAAAMNUm7	BAAAAAAAAAAAv/////////4fAAAAOQAAAAwAAKqqqqqqqgNHJ/VETnLEAA9MFkppll4C/UAjp0RBCwHXTqS5GGE0Bslz52lzY0MDnW/HmzPCrAC2BOT1WwBBBMEaoBMRIX0CSyZiSQn0wgFnGYB0RHPKAAlGZMcE00IAAAAAAEIRAw==	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAADkAAAABAAAAAAAAAAEAkPJaMFMCEgEAAAAlAAAADAAC//8AAAAGAMsGpAAAAAoAAf//AAAABgD1AAAADAAC//8AAAAGAG0DhAAAAAwAAv//AAAABgCOBRQAAAAMAAL//wAAAAYAXQEsAAAADAAC//8AAAAGARofQAAAAAwAAv//AAAABgBEDUgAAAAMAAL//wAAAAYBfR2wAAAADAAC//8AAAAGACoDIAAAAAwAAv//AAAABgH5HbAAAAAMAAL//wAAAAYAVgtUAAAADAAC//8AAAAGAD8JxAAAAAwAAv//AAAABgCkC7gAAAAMAAL//wAAAAYCBQEsAAAADAAC//8AAAAGAIwDIAAAAAwAAv//AAAABgD5ASwAAAAMAAL//wAAAAYA2xH4AAAADAAC//8AAAAGAHUfQAAAAAwAAv//AAAABgDyCowAAAAMAAL//wAAAAYCFB+kAAAADAAC//8AAAAGAiobWAAAAAwAAv//AAAABgGII4wAAAAMAAL//wAAAAYAUBtYAAAADAAC//8AAAAGAG4SwAAAAAwAAv//AAAABgERDBwAAAAMAAL//wAAAAYAgR7cAAAADAAC//8AAAAGACACvAAAAAwAAv//AAAABgFnH6QAAAAMAAL//wAAAAYCfyE0AAAADAAC//8AAAAGAJcRMAAAAAwAAv//AAAABgCHEGgAAAAMAAL//wAAAAYAtgDIAAAADAAC//8AAAAGASEhNAAAAAwAAv//AAAABgBGGcgAAAAMAAL//wAAAAYAeiDQAAAADAAC//8AAAAGAdYjKAAAAAwAAv//AAAABgBdD6A=	AgBwZ19jYXRhbG9nAGpzb25iAAAAADkAAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAADkAAAABAAAAAAAAAAEAAAAAAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAAOQAAAAMAAAAAAAADMzIAKBBEMZSIEqByQuEQCOEAAAERIGiGyAABAAAABQAAAAh1c2VyLTAwMwAAAAh1c2VyLTAwMgAAAAh1c2VyLTAwNAAAAAh1c2VyLTAwNQAAAAh1c2VyLTAwMQ==
70	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-gpt4	BAAAAAAAAAABIAAAAAAAAAAaAAAARgAAABCqurqqq7u7qgwxEzSStTm4BHpcF8+FCywHiQItA6UD5AytAbwF/REOFMMHZgGvC6YArAPgATYNIgOaAA8MnhEfCjbpMOjw7tUHTHQxH3EkjwSntsJKelLTAMtocVIP4McPqhBBBdgDBA8XcsB4fpD+D08AlwkDFQgMy0fn70vPoAAAAAAAClqs	trace-131-1760906480.663000	trace-994-1760888480.663000	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABGAAAAG3RyYWNlLTI0NC0xNzYwOTE3MjgwLjY2MzAwMAAAABp0cmFjZS0zOC0xNzYwOTE3MjgwLjY2MzAwMAAAABt0cmFjZS00MTctMTc2MDkxNzI4MC42NjMwMDAAAAAbdHJhY2UtNjQyLTE3NjA5MTcyODAuNjYzMDAwAAAAG3RyYWNlLTMwNi0xNzYwOTE2Njg1LjE3MTU3NgAAABt0cmFjZS00MDAtMTc2MDkxNjY4NS4xNzE1NzYAAAAbdHJhY2UtNTU4LTE3NjA5MTM2ODAuNjYzMDAwAAAAG3RyYWNlLTcxNi0xNzYwOTEzNjgwLjY2MzAwMAAAABt0cmFjZS0xMzctMTc2MDkxMDA4MC42NjMwMDAAAAAbdHJhY2UtMTMxLTE3NjA5MDY0ODAuNjYzMDAwAAAAG3RyYWNlLTYyMy0xNzYwOTAyODgwLjY2MzAwMAAAABt0cmFjZS02NDgtMTc2MDkwMjg4MC42NjMwMDAAAAAbdHJhY2UtMzk0LTE3NjA4OTkyODAuNjYzMDAwAAAAG3RyYWNlLTE3NS0xNzYwODk4Njg1LjE3MTU3NgAAABt0cmFjZS0xMzktMTc2MDg5NTY4MC42NjMwMDAAAAAbdHJhY2UtMzM2LTE3NjA4OTU2ODAuNjYzMDAwAAAAG3RyYWNlLTc1NS0xNzYwODk1NjgwLjY2MzAwMAAAABt0cmFjZS01NTEtMTc2MDg5NTA4NS4xNzE1NzYAAAAbdHJhY2UtODM4LTE3NjA4OTUwODUuMTcxNTc2AAAAG3RyYWNlLTkwOS0xNzYwODk1MDg1LjE3MTU3NgAAABt0cmFjZS05MjctMTc2MDg5MjA4MC42NjMwMDAAAAAbdHJhY2UtMjg3LTE3NjA4OTE0ODUuMTcxNTc2AAAAG3RyYWNlLTMyOC0xNzYwODkxNDg1LjE3MTU3NgAAABt0cmFjZS01MjQtMTc2MDg5MTQ4NS4xNzE1NzYAAAAbdHJhY2UtMjE2LTE3NjA4ODg0ODAuNjYzMDAwAAAAG3RyYWNlLTk5NC0xNzYwODg4NDgwLjY2MzAwMAAAABt0cmFjZS01ODAtMTc2MDg4Nzg4NS4xNzE1NzYAAAAbdHJhY2UtNzgxLTE3NjA4ODc4ODUuMTcxNTc2AAAAG3RyYWNlLTk3NC0xNzYwODg3ODg1LjE3MTU3NgAAABt0cmFjZS02MjgtMTc2MDg4NDg4MC42NjMwMDAAAAAbdHJhY2UtMzgzLTE3NjA4ODQyODUuMTcxNTc2AAAAGnRyYWNlLTY1LTE3NjA4ODEyODAuNjYzMDAwAAAAG3RyYWNlLTg2My0xNzYwODgxMjgwLjY2MzAwMAAAABt0cmFjZS03OTUtMTc2MDg4MDY4NS4xNzE1NzYAAAAadHJhY2UtMzQtMTc2MDg3NzY4MC42NjMwMDAAAAAbdHJhY2UtNjg5LTE3NjA4NzcwODUuMTcxNTc2AAAAG3RyYWNlLTI0OS0xNzYwODc0MDgwLjY2MzAwMAAAABt0cmFjZS02NjUtMTc2MDg3NDA4MC42NjMwMDAAAAAbdHJhY2UtMTUxLTE3NjA4NzA0ODAuNjYzMDAwAAAAG3RyYWNlLTU3MS0xNzYwODcwNDgwLjY2MzAwMAAAABt0cmFjZS02MjktMTc2MDg3MDQ4MC42NjMwMDAAAAAbdHJhY2UtNzA4LTE3NjA4Njk4ODUuMTcxNTc2AAAAGnRyYWNlLTgwLTE3NjA4Njk4ODUuMTcxNTc2AAAAG3RyYWNlLTkxNC0xNzYwODY5ODg1LjE3MTU3NgAAABt0cmFjZS0xNTItMTc2MDg2Njg4MC42NjMwMDAAAAAbdHJhY2UtMjkwLTE3NjA4NjY4ODAuNjYzMDAwAAAAG3RyYWNlLTU1NS0xNzYwODY2ODgwLjY2MzAwMAAAABt0cmFjZS05ODktMTc2MDg2MzI4MC42NjMwMDAAAAAbdHJhY2UtNTg3LTE3NjA4NTk2ODAuNjYzMDAwAAAAGnRyYWNlLTgzLTE3NjA4NTYwODAuNjYzMDAwAAAAG3RyYWNlLTk2NS0xNzYwODU1NDg1LjE3MTU3NgAAABt0cmFjZS01OTUtMTc2MDg0ODg4MC42NjMwMDAAAAAbdHJhY2UtMTQ0LTE3NjA4NDgyODUuMTcxNTc2AAAAG3RyYWNlLTY5OC0xNzYwODQ4Mjg1LjE3MTU3NgAAABt0cmFjZS0zNzktMTc2MDg0NTI4MC42NjMwMDAAAAAadHJhY2UtNDctMTc2MDg0NTI4MC42NjMwMDAAAAAbdHJhY2UtNzc1LTE3NjA4NDQ2ODUuMTcxNTc2AAAAG3RyYWNlLTQyMS0xNzYwODQxNjgwLjY2MzAwMAAAABt0cmFjZS0xMzUtMTc2MDg0MTA4NS4xNzE1NzYAAAAbdHJhY2UtNTQxLTE3NjA4MzgwODAuNjYzMDAwAAAAG3RyYWNlLTc5My0xNzYwODM4MDgwLjY2MzAwMAAAABt0cmFjZS05NjktMTc2MDgzODA4MC42NjMwMDAAAAAbdHJhY2UtMTg1LTE3NjA4Mzc0ODUuMTcxNTc2AAAAG3RyYWNlLTQwMS0xNzYwODM3NDg1LjE3MTU3NgAAABt0cmFjZS0yMjMtMTc2MDgzNDQ4MC42NjMwMDAAAAAadHJhY2UtMjktMTc2MDgzNDQ4MC42NjMwMDAAAAAbdHJhY2UtNDEwLTE3NjA4MzQ0ODAuNjYzMDAwAAAAG3RyYWNlLTE1My0xNzYwODMzODg1LjE3MTU3NgAAABt0cmFjZS0yNjItMTc2MDgzMzg4NS4xNzE1NzYAAAAbdHJhY2UtMjg4LTE3NjA4MzM4ODUuMTcxNTc2	2025-10-19 00:31:25.171576+00	2025-10-19 23:41:20.663+00	BAAAAuR22wQPeAAAAAAAAAAAAAAARgAAADnt3u7u3u7d7u7u7u7u7e7e7u7u7t7u7d4AAAAN3u7e7gAFyRSLjIuwAAXJFIuMi68AAAAAAAAAAEb89MBG/PS/AAAAAWYqUz8AAAABZipTQAAAAAGtJ0f/AAAAAAAAAAAAAAABrSdIAAAAAAGtJ0f/AAAAAWYqU0AAAAABHy1efwAAAAFmKlNARvz0vwAAAAAAAAAARvz0wAAAAAFmKlM/AAAAAR8tXoAAAAAARvz0wAAAAAFmKlM/AAAAAWYqU0BG/PTARvz0vwAAAAAAAAAAAAAAAWYqUz8AAAABHy1egAAAAAEfLV5/AAAAAWYqU0AAAAAARvz0vwAAAAEfLV5/AAAAAR8tXoAAAAABHy1efwAAAAFmKlNAAAAAAa0nR/8AAAABrSdIAEb89L8AAAAAAAAAAEb89MAAAAABZipTPwAAAAFmKlNAAAAAAAAAAAAAAAABrSdH/wAAAAAAAAAAAAAAAWYqU0AAAAACzFSmfwAAAALMVKaAAAAAAEb89MAAAAABZipTPwAAAAFmKlNAAAAAAEb89L8AAAABHy1efwAAAAEfLV6AAAAAAR8tXn8AAAABZipTQEb89L8AAAAAAAAAAEb89MAAAAABZipTPwAAAAFmKlNARvz0vwAAAAAAAAAARvz0wA==	BAAAAAAAAAAEMv////////woAAAARgAAABCqu7urq6uruwwiBrYShwqkKkwv0xiCDDkCKAs/IKIrIQAF5/12LBLwBOcQLhP/CSwJPZMc1Hy3XA3QGw0S8ANoCcjYt+Ze1CQd/yDWGM8FjgGL97qSSskeCxQHTg7xDPYXuAXXDYoUEQcvBiMdnCrdEgEP3ACFAWYDpitlzT+7yA/HQgSEdCoD	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABGAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI0NAAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MTcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjQyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMwNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA0MDAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTU4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDcxNgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMzcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTMxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYyMwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NDgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzk0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE3NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMzkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzM2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc1NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1NTEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODM4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkwOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MjcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjg3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMyOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1MjQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjE2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk5NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1ODAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzgxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk3NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MjgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzgzAAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDg2MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3OTUAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjg5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDI0OQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2NjUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTUxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU3MQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA2MjkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzA4AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkxNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxNTIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjkwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU1NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5ODkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTg3AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk2NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA1OTUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTQ0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY5OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNzkAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzc1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQyMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMzUAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTQxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDc5MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NjkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMTg1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQwMQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMjMAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDEwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE1MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyNjIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjg4	AQFwZ19jYXRhbG9nAHRleHQAAQAAAEYAAAACAAAAAAAAABEyUCQCyDwAIAAAAAAAAAAIAQAAADUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyNDQAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzOAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQxNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY0MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDMwNgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU1OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDcxNgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEzNwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEzMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYyMwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDY0OAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDM5NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE3NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEzOQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDMzNgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc1NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU1MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDMyOAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDUyNAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDIxNgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk5NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU4MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk3NAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDYyOAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDg2MwAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDM0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjg5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjQ5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjY1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTUxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTcxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNjI5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzA4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTE0AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTUyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTU1AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gOTg5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTg3AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5NjUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1OTUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2OTgAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDc3NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDEzNQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU0MQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDE4NQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQwMQAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDIyMwAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI5AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNDEwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjYyAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMjg4	AgFwZ19jYXRhbG9nAHRleHQAAAAAEQAAAAEAAAAAAAAAAwAGAAsDCBAAAAAARgAAAAIAAAAAAAAAEc2v2/03w//fAAAAAAAAADcAAQAAAAcAAAAfU2FtcGxlIGVycm9yIG1lc3NhZ2U6IEFQSV9FUlJPUgAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgOTA1bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDEwNzFtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgOTUxbXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDI0MG1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA1NDZtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTAyMm1z	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARgAAAAMAAAAAAAACImBACVAAAAQABQQSAAgQAAgAAAAAAAAAgAABAAAAAwAAAAdzdWNjZXNzAAAABWVycm9yAAAAB3RpbWVvdXQ=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARgAAAAMAAAAAAAACIoRklrAYAeFUogk+N/NMkTgAAAAAAAAAlQABAAAABAAAAA1jbGF1ZGUtMy1vcHVzAAAADG1peHRyYWwtOHg3YgAAAAtncHQtNC10dXJibwAAAApnZW1pbmktcHJv	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARgAAAAMAAAAAAAACIoRklrAYAeFUogk+N/NMkTgAAAAAAAAAlQABAAAABAAAAAlhbnRocm9waWMAAAAHbWlzdHJhbAAAAAZvcGVuYWkAAAAGZ29vZ2xl	BAAAAAAAAAAAiAAAAAAAAAAjAAAARgAAAA0ACZmpmaqaqQXXkt7dJDT0AeEV44FU4uME4mF1AieSAgM2tjNX1Bp7AjcKkstEwZkDF1NlExMD9AjATWK0VUhmCZ1qtBH89N4EdCQ1BoShEQTSN1J1UWI1BQCcSFMk9XUJH25wRkdsxgAAAAAj5bwn	BAAAAAAAAAAAwQAAAAAAAABwAAAARgAAAAsAAAmZmYmImQdejmbWimW0A7VwSNAilHwIpFrJfO/ICc7XLyUoM0xVBd1aA9fTmDI6IxlaFxMhzggVrChAIvCdBJEtUpVxeNgJ0aENjoKETQm+JiNHUAlbAAAAKgljrdA=	BAAAAAAAAAABDv/////////+AAAARgAAAA4AqqqqqqqqqQy0I68vlYbMBoNFZE9QIB4B/BZEV0YiSgOPFyQ3cAXFADRMJbUiI3oDMFj0VBUEQwUZLLM2LeONAagCIbEJdbYGLR7jACwwDwEUQXIqQPaEBJKJeHyVtq4DfxiiZxmTIgcJiQPrM9WAAAAsIfdG1oY=	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAEYAAAACAAAAAAAAABEyUCQCyDwAIAAAAAAAAAAIAQAAADUAAAAMAAL//wAAAAYCpxMkAAAADAAC//8AAAAGAB4gCAAAAAwAAv//AAAABgB1BEwAAAAMAAL//wAAAAYAah1MAAAADAAC//8AAAAGACwZyAAAAAwAAv//AAAABgCYFkQAAAAMAAL//wAAAAYArAK8AAAADAAC//8AAAAGADcVGAAAAAwAAv//AAAABgKpASwAAAAMAAL//wAAAAYCwBr0AAAADAAC//8AAAAGAPQhNAAAAAwAAv//AAAABgIzEyQAAAAMAAL//wAAAAYA4gnEAAAADAAC//8AAAAGAHYHCAAAAAwAAv//AAAABgC/FXwAAAAMAAL//wAAAAYBNAV4AAAADAAC//8AAAAGAQEH0AAAAAwAAv//AAAABgBLETAAAAAMAAL//wAAAAYCBgwcAAAADAAC//8AAAAGAbsfpAAAAAwAAv//AAAABgBnEfgAAAAMAAL//wAAAAYAxyRUAAAADAAC//8AAAAGAtghmAAAAAwAAv//AAAABgBlEGgAAAAMAAL//wAAAAYCHwMgAAAADAAC//8AAAAGALsCvAAAAAwAAv//AAAABgKxCPwAAAAMAAL//wAAAAYAew1IAAAADAAC//8AAAAGAS4MgAAAAAwAAv//AAAABgBIGDgAAAAMAAL//wAAAAYBjARMAAAADAAC//8AAAAGAZEj8AAAAAwAAv//AAAABgDuJRwAAAAMAAL//wAAAAYAbRXgAAAADAAC//8AAAAGAKEYnAAAAAwAAv//AAAABgDbFLQAAAAMAAL//wAAAAYA6g50AAAADAAC//8AAAAGAGoV4AAAAAwAAv//AAAABgA4BXgAAAAMAAL//wAAAAYAcgu4AAAADAAC//8AAAAGAkEkVAAAAAwAAv//AAAABgDAGWQAAAAMAAL//wAAAAYBGSJgAAAADAAC//8AAAAGACsbvAAAAAwAAv//AAAABgFPDhAAAAAMAAL//wAAAAYCvQXcAAAADAAC//8AAAAGASca9AAAAAwAAv//AAAABgHDETAAAAAMAAL//wAAAAYAHyH8AAAADAAC//8AAAAGAF8OdAAAAAwAAv//AAAABgBhINAAAAAMAAL//wAAAAYBziH8AAAADAAC//8AAAAGAjAixA==	AgBwZ19jYXRhbG9nAGpzb25iAAAAAEYAAAABAAAAAAAAAA8AAARgAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAEYAAAABAAAAAAAAAA8AAARgAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAARgAAAAQAAAAAAAAzMxECQJQQjJaIJMhRmBoNkhAhCEEGkxEGIQAAAAAAAKkJAAEAAAAFAAAACHVzZXItMDAyAAAACHVzZXItMDA1AAAACHVzZXItMDA0AAAACHVzZXItMDAzAAAACHVzZXItMDAx
78	37160be9-7d69-43b5-8d5f-9d7b5e14a57a	agent-mixtral	BAAAAAAAAAAAFP////////2yAAAATgAAABGqqquru5urqgAAAAAAAAAKASKQ6TPW/lYNjuyxhTmh1xEjBy4FhQQsDdEZQUULPZoMjhi/CTYMuglhhgaKsRJCC3QG/wBwAxUG+QUqDywSfRaQEZsIrAWLAkwPhTCL9YUSqg55AHUCjwXmlJLIGOU/B2x1UPUJQKYBaRjDB0rAkwgBZwULExChDA0dAskAaZYAAAAGnxvqTA==	trace-101-1760906480.663000	trace-993-1760855485.171576	AQBwZ19jYXRhbG9nAHZhcmNoYXIAAAEAAABOAAAAG3RyYWNlLTgzNS0xNzYwOTE3MjgwLjY2MzAwMAAAABt0cmFjZS05NTAtMTc2MDkxMzY4MC42NjMwMDAAAAAbdHJhY2UtODg3LTE3NjA5MTMwODUuMTcxNTc2AAAAG3RyYWNlLTk4My0xNzYwOTEzMDg1LjE3MTU3NgAAABt0cmFjZS0yMjQtMTc2MDkxMDA4MC42NjMwMDAAAAAbdHJhY2UtMjI5LTE3NjA5MTAwODAuNjYzMDAwAAAAG3RyYWNlLTY5NS0xNzYwOTEwMDgwLjY2MzAwMAAAABt0cmFjZS05NjYtMTc2MDkxMDA4MC42NjMwMDAAAAAbdHJhY2UtMzQzLTE3NjA5MDk0ODUuMTcxNTc2AAAAG3RyYWNlLTQ1NS0xNzYwOTA5NDg1LjE3MTU3NgAAABt0cmFjZS0xMDEtMTc2MDkwNjQ4MC42NjMwMDAAAAAadHJhY2UtNDAtMTc2MDkwNjQ4MC42NjMwMDAAAAAbdHJhY2UtODk4LTE3NjA5MDY0ODAuNjYzMDAwAAAAG3RyYWNlLTU2Mi0xNzYwOTA1ODg1LjE3MTU3NgAAABt0cmFjZS05NjctMTc2MDkwNTg4NS4xNzE1NzYAAAAbdHJhY2UtMjgyLTE3NjA5MDI4ODAuNjYzMDAwAAAAG3RyYWNlLTQzNC0xNzYwOTAyODgwLjY2MzAwMAAAABt0cmFjZS03ODgtMTc2MDkwMjg4MC42NjMwMDAAAAAbdHJhY2UtMzczLTE3NjA5MDIyODUuMTcxNTc2AAAAG3RyYWNlLTU4Ny0xNzYwODk4Njg1LjE3MTU3NgAAABt0cmFjZS05ODAtMTc2MDg5NTY4MC42NjMwMDAAAAAbdHJhY2UtMjA1LTE3NjA4OTUwODUuMTcxNTc2AAAAGnRyYWNlLTM3LTE3NjA4OTUwODUuMTcxNTc2AAAAG3RyYWNlLTE1OC0xNzYwODkxNDg1LjE3MTU3NgAAABt0cmFjZS0zMTMtMTc2MDg5MTQ4NS4xNzE1NzYAAAAbdHJhY2UtMzgyLTE3NjA4OTE0ODUuMTcxNTc2AAAAG3RyYWNlLTQ2NC0xNzYwODkxNDg1LjE3MTU3NgAAABt0cmFjZS03NDEtMTc2MDg5MTQ4NS4xNzE1NzYAAAAbdHJhY2UtMzE4LTE3NjA4ODg0ODAuNjYzMDAwAAAAG3RyYWNlLTUwMC0xNzYwODg4NDgwLjY2MzAwMAAAABt0cmFjZS03MzgtMTc2MDg4ODQ4MC42NjMwMDAAAAAadHJhY2UtODAtMTc2MDg4ODQ4MC42NjMwMDAAAAAbdHJhY2UtODg4LTE3NjA4ODg0ODAuNjYzMDAwAAAAG3RyYWNlLTMyOS0xNzYwODg3ODg1LjE3MTU3NgAAABt0cmFjZS03MTItMTc2MDg4Nzg4NS4xNzE1NzYAAAAbdHJhY2UtNzU2LTE3NjA4ODQ4ODAuNjYzMDAwAAAAG3RyYWNlLTkwNy0xNzYwODg0ODgwLjY2MzAwMAAAABt0cmFjZS0zNDgtMTc2MDg4MTI4MC42NjMwMDAAAAAbdHJhY2UtODk5LTE3NjA4ODEyODAuNjYzMDAwAAAAG3RyYWNlLTE5Ni0xNzYwODgwNjg1LjE3MTU3NgAAABt0cmFjZS0zODEtMTc2MDg3NzY4MC42NjMwMDAAAAAbdHJhY2UtODU5LTE3NjA4NzQwODAuNjYzMDAwAAAAG3RyYWNlLTIxNy0xNzYwODcwNDgwLjY2MzAwMAAAABt0cmFjZS0yMzktMTc2MDg3MDQ4MC42NjMwMDAAAAAbdHJhY2UtMzg1LTE3NjA4NzA0ODAuNjYzMDAwAAAAG3RyYWNlLTgyNS0xNzYwODcwNDgwLjY2MzAwMAAAABt0cmFjZS05MzctMTc2MDg3MDQ4MC42NjMwMDAAAAAbdHJhY2UtOTkwLTE3NjA4NzA0ODAuNjYzMDAwAAAAG3RyYWNlLTE5MC0xNzYwODY5ODg1LjE3MTU3NgAAABt0cmFjZS03NzktMTc2MDg2OTg4NS4xNzE1NzYAAAAbdHJhY2UtNjk2LTE3NjA4NTkwODUuMTcxNTc2AAAAG3RyYWNlLTgxMi0xNzYwODU5MDg1LjE3MTU3NgAAABt0cmFjZS0yODQtMTc2MDg1NjA4MC42NjMwMDAAAAAbdHJhY2UtNTY3LTE3NjA4NTU0ODUuMTcxNTc2AAAAG3RyYWNlLTYwNS0xNzYwODU1NDg1LjE3MTU3NgAAABt0cmFjZS03MjYtMTc2MDg1NTQ4NS4xNzE1NzYAAAAbdHJhY2UtOTIxLTE3NjA4NTU0ODUuMTcxNTc2AAAAG3RyYWNlLTk5My0xNzYwODU1NDg1LjE3MTU3NgAAABt0cmFjZS0xMjYtMTc2MDg1MTg4NS4xNzE1NzYAAAAbdHJhY2UtMjA5LTE3NjA4NTE4ODUuMTcxNTc2AAAAG3RyYWNlLTIxOC0xNzYwODUxODg1LjE3MTU3NgAAABt0cmFjZS04MjUtMTc2MDg1MTg4NS4xNzE1NzYAAAAadHJhY2UtNDQtMTc2MDg0ODg4MC42NjMwMDAAAAAbdHJhY2UtNDYxLTE3NjA4NDg4ODAuNjYzMDAwAAAAG3RyYWNlLTY5Ny0xNzYwODQ4ODgwLjY2MzAwMAAAABt0cmFjZS04NTItMTc2MDg0ODg4MC42NjMwMDAAAAAbdHJhY2UtODU0LTE3NjA4NDg4ODAuNjYzMDAwAAAAG3RyYWNlLTIxMC0xNzYwODQ1MjgwLjY2MzAwMAAAABt0cmFjZS0zOTAtMTc2MDg0NTI4MC42NjMwMDAAAAAbdHJhY2UtNTQ1LTE3NjA4NDQ2ODUuMTcxNTc2AAAAG3RyYWNlLTkyNy0xNzYwODQ0Njg1LjE3MTU3NgAAABt0cmFjZS0zMTItMTc2MDg0MTY4MC42NjMwMDAAAAAbdHJhY2UtMzQwLTE3NjA4NDE2ODAuNjYzMDAwAAAAG3RyYWNlLTYwMC0xNzYwODM4MDgwLjY2MzAwMAAAABt0cmFjZS0zMTctMTc2MDgzNzQ4NS4xNzE1NzYAAAAbdHJhY2UtMzUyLTE3NjA4Mzc0ODUuMTcxNTc2AAAAG3RyYWNlLTYxMC0xNzYwODM3NDg1LjE3MTU3NgAAABp0cmFjZS0yMC0xNzYwODMzODg1LjE3MTU3Ng==	2025-10-19 00:31:25.171576+00	2025-10-19 23:41:20.663+00	BAAAAuR22wQPeP////8pbFwAAAAATgAAADnt7u3u3e7u7u7u7tzuzu7uzu3u3e7u2+0AAAAO3u7t7gAFyRSLjIuwAAXJFjiz068AAAABZipTQAAAAABG/PTAAAAAAWYqUz8AAAABZipTQAAAAAAAAAAARvz0wEb89L8AAAABZipTPwAAAAFmKlNARvz0vwAAAAAAAAAARvz0wAAAAAFmKlM/AAAAAWYqU0BG/PS/AAAAAAAAAAFmKlM/AAAAAEb89MAAAAABHy1egAAAAABG/PTAAAAAAa0nR/8AAAABrSdIAAAAAAAAAAAAAAAAAWYqUz8AAAABZipTQAAAAAAAAAAARvz0wEb89L8AAAABZipTPwAAAAFmKlNAAAAAAa0nR/8AAAABrSdIAAAAAABG/PS/AAAAAR8tXn8AAAAARvz0vwAAAAGtJ0gAAAAAAAAAAABG/PTARvz0vwAAAAUHddf/AAAABQd12AAAAAABZipTPwAAAAEfLV6AAAAAAEb89MAAAAAAAAAAAAAAAAGtJ0f/AAAAAa0nSAAAAAAAAAAAAAAAAAFmKlM/AAAAAWYqU0AAAAAAAAAAAAAAAAGtJ0f/AAAAAa0nSABG/PTARvz0vwAAAAFmKlM/AAAAAWYqU0AAAAABrSdH/wAAAAFmKlNAAAAAAEb89MAAAAABrSdH/w==	BAAAAAAAAAAEL/////////4mAAAATgAAABKru6q6q6urugAAAAAAAACrDK9wJQzCG6Q6PRWcHLgW7Q0lFTIepzBcDhoxUUMlOTIGFgGxB9ARYQV9GGUQNjc3DI4QywIeCLQBs3sE8q7yWAPCAJj/qyj3AisJ9BU/C0wFSg5AuhGB7wR5WVlCbFNXADsVYwtKB9gxfBo3BUcUTAQzBacjGjsvCIJqs8p3eqYSMRA4AygLzQAAAAAAevnu	AQBwZ19jYXRhbG9nAHRleHQAAAEAAABOAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgzNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NTAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODg3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk4MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMjQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjI5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY5NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NjYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzQzAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ1NQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMDEAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODk4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU2MgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5NjcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjgyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQzNAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3ODgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzczAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDU4NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5ODAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjA1AAAAJlNhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDM3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE1OAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMTMAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzgyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDQ2NAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NDEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzE4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDUwMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MzgAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODg4AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDMyOQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MTIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNzU2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkwNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzNDgAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODk5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE5NgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzODEAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODU5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIxNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMzkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzg1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgyNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA5MzcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTkwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDE5MAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3NzkAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNjk2AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDgxMgAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyODQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTY3AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYwNQAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA3MjYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gOTIxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDk5MwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAxMjYAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMjA5AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIxOAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4MjUAAAAmU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDQAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNDYxAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDY5NwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiA4NTIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gODU0AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDIxMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzOTAAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gNTQ1AAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDkyNwAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMTIAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzQwAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYwMAAAACdTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAzMTcAAAAnU2FtcGxlIHByb21wdCBmb3IgdGVzdGluZyBpdGVyYXRpb24gMzUyAAAAJ1NhbXBsZSBwcm9tcHQgZm9yIHRlc3RpbmcgaXRlcmF0aW9uIDYxMAAAACZTYW1wbGUgcHJvbXB0IGZvciB0ZXN0aW5nIGl0ZXJhdGlvbiAyMA==	AQFwZ19jYXRhbG9nAHRleHQAAQAAAE4AAAACAAAAAAAAABHiEQZCBioXAgAAAAAAACqNAQAAADMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MzUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4ODcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5ODMAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMjQAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMjkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2OTUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5NjYAAAAuU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA0MAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDU2MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk2NwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDI4MgAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDQzNAAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDM3MwAAAC9TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDk4MAAAAC5TYW1wbGUgcmVzcG9uc2UgZnJvbSBBSSBtb2RlbCBmb3IgaXRlcmF0aW9uIDM3AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMTU4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzEzAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzQxAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gMzE4AAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNTAwAAAAL1NhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gNzM4AAAALlNhbXBsZSByZXNwb25zZSBmcm9tIEFJIG1vZGVsIGZvciBpdGVyYXRpb24gODAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4ODgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3MTIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3NTYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MDcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNDgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxOTYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzODEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMzkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzODUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MjUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MzcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5OTAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3NzkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2OTYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4MTIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1NjcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MDUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA3MjYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MjEAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAxMjYAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMDkAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAyMTgAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA4NTIAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzOTAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA1NDUAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA5MjcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzNDAAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiAzMTcAAAAvU2FtcGxlIHJlc3BvbnNlIGZyb20gQUkgbW9kZWwgZm9yIGl0ZXJhdGlvbiA2MTA=	AgFwZ19jYXRhbG9nAHRleHQAAAAAGwAAAAIAAAAAAAAARIdhVBEREyEQAAAPEe3LoZEAAABOAAAAAgAAAAAAAAARHe75vfnV6P0AAAAAAAAVcgABAAAAEAAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTQyN21zAAAAH1NhbXBsZSBlcnJvciBtZXNzYWdlOiBBUElfRVJST1IAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDQwN21zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA0OThtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTA5bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDE0MjRtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTY1OW1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA4MTNtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTUxNm1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciAxODdtcwAAABtSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMjQ1bXMAAAAbUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDk3OW1zAAAAG1JlcXVlc3QgdGltZW91dCBhZnRlciA0NjFtcwAAABxSZXF1ZXN0IHRpbWVvdXQgYWZ0ZXIgMTI5Nm1zAAAAHFJlcXVlc3QgdGltZW91dCBhZnRlciAxNjQ4bXMAAAAcUmVxdWVzdCB0aW1lb3V0IGFmdGVyIDEwNzFtcw==	error	timeout	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATgAAAAMAAAAAAAACIgAoCIgBGgAEZAgBAQAYEAQAAAAABIhAUQABAAAAAwAAAAdzdWNjZXNzAAAAB3RpbWVvdXQAAAAFZXJyb3I=	claude-3-opus	mixtral-8x7b	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATgAAAAMAAAAAAAACIlUyY/gpjtJAoxNg4paFfyIAAAAAAWKS0QABAAAABAAAAAtncHQtNC10dXJibwAAAA1jbGF1ZGUtMy1vcHVzAAAACmdlbWluaS1wcm8AAAAMbWl4dHJhbC04eDdi	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATgAAAAMAAAAAAAACIlUyY/gpjtJAoxNg4paFfyIAAAAAAWKS0QABAAAABAAAAAZvcGVuYWkAAAAJYW50aHJvcGljAAAABmdvb2dsZQAAAAdtaXN0cmFs	BAAAAAAAAAABRAAAAAAAAACmAAAATgAAAA8JqqmqqqqZmgCdPTX2UtLkBjiBCcvBJC4BAaUkIfMAPgAuPVuZii5AAr1qhwsyIQIEjAuQZAGw8QCcH8KJJYUbAwEvE8AZUAAA8w8VPGv2VAVYOxRAMrDiD4WKHIkCf8UAPBCgWkK00AYAVVSISZKSBIgssM9Ixh0AAAB+EAgWFw==	BAAAAAAAAAAAvgAAAAAAAABYAAAATgAAAA0ACZmImZmZmQF1lUsQaQ1EAEzQI0nQqTwDjKYJ1YREKQTsazmOVyETBdSwGhn1YNoB6IUXh2AghgR1HGNVgLknAnT2CNgUuLSaNE9cXm0hMsy3XNdSyHHhAbwTCJpJZPQCHPuBmdfZIwAAAAAABMAr	BAAAAAAAAAABdP////////6oAAAATgAAAA8KqqqpqqmaqgIwNXB2RRQyAZk001xrNeIDcgblXzqDSAj0WFLIGvOPA9F5LFocKU4EO2zjMSszpgIQRBFPT8HtA9g21iiClIAHkEJllPJNkwUWJqWhIuKBAp0Q8yVoxvUApwvFWTxkEgIbNSR4cFMEAZE5ctAG4csD5xxCfwY1Rg==	AQFwZ19jYXRhbG9nAG51bWVyaWMAAQAAAE4AAAACAAAAAAAAABHiEQZCBioXAgAAAAAAACqNAQAAADMAAAAMAAL//wAAAAYAaAu4AAAADAAC//8AAAAGAJcINAAAAAwAAv//AAAABgKsGvQAAAAMAAL//wAAAAYAywwcAAAADAAC//8AAAAGAjATiAAAAAwAAv//AAAABgHWINAAAAAMAAL//wAAAAYARiE0AAAADAAC//8AAAAGAFIixAAAAAwAAv//AAAABgB3HOgAAAAMAAL//wAAAAYAagJYAAAADAAC//8AAAAGAP8DhAAAAAwAAv//AAAABgClG7wAAAAMAAL//wAAAAYAJxGUAAAADAAC//8AAAAGAIANrAAAAAwAAv//AAAABgDhGWQAAAAMAAL//wAAAAYA8Q2sAAAADAAC//8AAAAGAEkI/AAAAAwAAv//AAAABgDqHCAAAAAMAAL//wAAAAYBXAfQAAAADAAC//8AAAAGApQhNAAAAAwAAv//AAAABgHwFXwAAAAMAAL//wAAAAYBTBnIAAAADAAC//8AAAAGANwAyAAAAAwAAv//AAAABgCEIfwAAAAMAAL//wAAAAYCKiGYAAAADAAC//8AAAAGAC8ZAAAAAAwAAv//AAAABgBbBRQAAAAMAAL//wAAAAYCZyJgAAAADAAC//8AAAAGAb4g0AAAAAwAAv//AAAABgDrC7gAAAAMAAL//wAAAAYANhAEAAAADAAC//8AAAAGAfwNSAAAAAoAAf//AAAABgCaAAAADAAC//8AAAAGAIMAyAAAAAwAAv//AAAABgDTINAAAAAMAAL//wAAAAYAvB54AAAADAAC//8AAAAGAC0aLAAAAAwAAv//AAAABgJUFRgAAAAMAAL//wAAAAYAfhqQAAAADAAC//8AAAAGAgIakAAAAAwAAv//AAAABgB+IAgAAAAMAAL//wAAAAYBfiH8AAAADAAC//8AAAAGAIMSwAAAAAwAAv//AAAABgBvJqwAAAAMAAL//wAAAAYApxH4AAAADAAC//8AAAAGAHUHCAAAAAwAAv//AAAABgEvIZgAAAAMAAL//wAAAAYBjAPoAAAADAAC//8AAAAGAK0jjAAAAAwAAv//AAAABgDYFeAAAAAMAAL//wAAAAYBbxyE	AgBwZ19jYXRhbG9nAGpzb25iAAAAAE4AAAABAAAAAAAAAA8AAATgAAAAAAABAAAAAQAAAEcBeyJtYXhfdG9rZW5zIjogMTAwMCwgImVudmlyb25tZW50IjogImRldmVsb3BtZW50IiwgInRlbXBlcmF0dXJlIjogMC43fQ==	{test,synthetic}	{test,synthetic}	AgBwZ19jYXRhbG9nAF92YXJjaGFyAAAAAE4AAAABAAAAAAAAAA8AAATgAAAAAAABAAAAAQAAACkAAAABAAAAAAAABBMAAAACAAAAAQAAAAR0ZXN0AAAACXN5bnRoZXRpYw==	\\x4005e4503b83e40d	AgBwZ19jYXRhbG9nAHZhcmNoYXIAAAAATgAAAAQAAAAAAAAzM0MUUcCgiDaIFskxEktRIJwIjG4AFCBCCwAAACgaASThAAEAAAAFAAAACHVzZXItMDAzAAAACHVzZXItMDA0AAAACHVzZXItMDA1AAAACHVzZXItMDAyAAAACHVzZXItMDAx
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.events (id, event_id, "timestamp", workspace_id, agent_id, event_type, severity, title, description, metadata, acknowledged, acknowledged_at, acknowledged_by) FROM stdin;
\.


--
-- Data for Name: performance_metrics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.performance_metrics ("timestamp", workspace_id, agent_id, metric_name, value, unit, metadata) FROM stdin;
\.


--
-- Data for Name: traces; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.traces (id, trace_id, workspace_id, agent_id, "timestamp", latency_ms, input, output, error, status, model, model_provider, tokens_input, tokens_output, tokens_total, cost_usd, metadata, tags, user_id) FROM stdin;
\.


--
-- Name: chunk_column_stats_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_column_stats_id_seq', 1, false);


--
-- Name: chunk_constraint_name; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_constraint_name', 8, true);


--
-- Name: chunk_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_id_seq', 16, true);


--
-- Name: continuous_agg_migrate_plan_step_step_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.continuous_agg_migrate_plan_step_step_id_seq', 1, false);


--
-- Name: dimension_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.dimension_id_seq', 5, true);


--
-- Name: dimension_slice_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.dimension_slice_id_seq', 11, true);


--
-- Name: hypertable_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_catalog.hypertable_id_seq', 8, true);


--
-- Name: bgw_job_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_config; Owner: postgres
--

SELECT pg_catalog.setval('_timescaledb_config.bgw_job_id_seq', 1007, true);


--
-- Name: events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.events_id_seq', 1, false);


--
-- Name: traces_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.traces_id_seq', 2000, true);


--
-- Name: _hyper_1_1_chunk 1_1_traces_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_1_chunk
    ADD CONSTRAINT "1_1_traces_pkey" PRIMARY KEY ("timestamp", trace_id);


--
-- Name: _hyper_1_2_chunk 2_2_traces_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_2_chunk
    ADD CONSTRAINT "2_2_traces_pkey" PRIMARY KEY ("timestamp", trace_id);


--
-- Name: _hyper_1_3_chunk 3_3_traces_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_3_chunk
    ADD CONSTRAINT "3_3_traces_pkey" PRIMARY KEY ("timestamp", trace_id);


--
-- Name: _hyper_1_4_chunk 4_4_traces_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_4_chunk
    ADD CONSTRAINT "4_4_traces_pkey" PRIMARY KEY ("timestamp", trace_id);


--
-- Name: _hyper_1_5_chunk 5_5_traces_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_5_chunk
    ADD CONSTRAINT "5_5_traces_pkey" PRIMARY KEY ("timestamp", trace_id);


--
-- Name: _hyper_1_6_chunk 6_6_traces_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_6_chunk
    ADD CONSTRAINT "6_6_traces_pkey" PRIMARY KEY ("timestamp", trace_id);


--
-- Name: _hyper_1_7_chunk 7_7_traces_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_7_chunk
    ADD CONSTRAINT "7_7_traces_pkey" PRIMARY KEY ("timestamp", trace_id);


--
-- Name: _hyper_1_8_chunk 8_8_traces_pkey; Type: CONSTRAINT; Schema: _timescaledb_internal; Owner: postgres
--

ALTER TABLE ONLY _timescaledb_internal._hyper_1_8_chunk
    ADD CONSTRAINT "8_8_traces_pkey" PRIMARY KEY ("timestamp", trace_id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY ("timestamp", event_id);


--
-- Name: performance_metrics performance_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.performance_metrics
    ADD CONSTRAINT performance_metrics_pkey PRIMARY KEY ("timestamp", workspace_id, agent_id, metric_name);


--
-- Name: traces traces_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traces
    ADD CONSTRAINT traces_pkey PRIMARY KEY ("timestamp", trace_id);


--
-- Name: _hyper_1_1_chunk_idx_traces_agent_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_agent_timestamp ON _timescaledb_internal._hyper_1_1_chunk USING btree (agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_1_chunk_idx_traces_cost_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_cost_analysis ON _timescaledb_internal._hyper_1_1_chunk USING btree (workspace_id, model, "timestamp" DESC) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_1_chunk_idx_traces_error_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_error_analysis ON _timescaledb_internal._hyper_1_1_chunk USING btree (workspace_id, agent_id, status, "timestamp" DESC) WHERE ((status)::text = 'error'::text);


--
-- Name: _hyper_1_1_chunk_idx_traces_latency_percentiles; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_latency_percentiles ON _timescaledb_internal._hyper_1_1_chunk USING btree (workspace_id, "timestamp" DESC) INCLUDE (latency_ms, status);


--
-- Name: _hyper_1_1_chunk_idx_traces_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_model ON _timescaledb_internal._hyper_1_1_chunk USING btree (model);


--
-- Name: _hyper_1_1_chunk_idx_traces_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_status ON _timescaledb_internal._hyper_1_1_chunk USING btree (status) WHERE ((status)::text <> 'success'::text);


--
-- Name: _hyper_1_1_chunk_idx_traces_tags; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_tags ON _timescaledb_internal._hyper_1_1_chunk USING gin (tags);


--
-- Name: _hyper_1_1_chunk_idx_traces_trace_id_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE UNIQUE INDEX _hyper_1_1_chunk_idx_traces_trace_id_timestamp ON _timescaledb_internal._hyper_1_1_chunk USING btree (trace_id, "timestamp");


--
-- Name: _hyper_1_1_chunk_idx_traces_workspace_agent; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_workspace_agent ON _timescaledb_internal._hyper_1_1_chunk USING btree (workspace_id, agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_1_chunk_idx_traces_workspace_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_workspace_model ON _timescaledb_internal._hyper_1_1_chunk USING btree (workspace_id, model, "timestamp" DESC);


--
-- Name: _hyper_1_1_chunk_idx_traces_workspace_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_workspace_status ON _timescaledb_internal._hyper_1_1_chunk USING btree (workspace_id, status, "timestamp" DESC);


--
-- Name: _hyper_1_1_chunk_idx_traces_workspace_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_workspace_timestamp ON _timescaledb_internal._hyper_1_1_chunk USING btree (workspace_id, "timestamp" DESC);


--
-- Name: _hyper_1_1_chunk_idx_traces_workspace_timestamp_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_workspace_timestamp_status ON _timescaledb_internal._hyper_1_1_chunk USING btree (workspace_id, "timestamp" DESC, status) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_1_chunk_idx_traces_workspace_user; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_idx_traces_workspace_user ON _timescaledb_internal._hyper_1_1_chunk USING btree (workspace_id, user_id, "timestamp" DESC);


--
-- Name: _hyper_1_1_chunk_traces_timestamp_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_1_chunk_traces_timestamp_idx ON _timescaledb_internal._hyper_1_1_chunk USING btree ("timestamp" DESC);


--
-- Name: _hyper_1_2_chunk_idx_traces_agent_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_agent_timestamp ON _timescaledb_internal._hyper_1_2_chunk USING btree (agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_2_chunk_idx_traces_cost_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_cost_analysis ON _timescaledb_internal._hyper_1_2_chunk USING btree (workspace_id, model, "timestamp" DESC) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_2_chunk_idx_traces_error_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_error_analysis ON _timescaledb_internal._hyper_1_2_chunk USING btree (workspace_id, agent_id, status, "timestamp" DESC) WHERE ((status)::text = 'error'::text);


--
-- Name: _hyper_1_2_chunk_idx_traces_latency_percentiles; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_latency_percentiles ON _timescaledb_internal._hyper_1_2_chunk USING btree (workspace_id, "timestamp" DESC) INCLUDE (latency_ms, status);


--
-- Name: _hyper_1_2_chunk_idx_traces_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_model ON _timescaledb_internal._hyper_1_2_chunk USING btree (model);


--
-- Name: _hyper_1_2_chunk_idx_traces_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_status ON _timescaledb_internal._hyper_1_2_chunk USING btree (status) WHERE ((status)::text <> 'success'::text);


--
-- Name: _hyper_1_2_chunk_idx_traces_tags; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_tags ON _timescaledb_internal._hyper_1_2_chunk USING gin (tags);


--
-- Name: _hyper_1_2_chunk_idx_traces_trace_id_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE UNIQUE INDEX _hyper_1_2_chunk_idx_traces_trace_id_timestamp ON _timescaledb_internal._hyper_1_2_chunk USING btree (trace_id, "timestamp");


--
-- Name: _hyper_1_2_chunk_idx_traces_workspace_agent; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_workspace_agent ON _timescaledb_internal._hyper_1_2_chunk USING btree (workspace_id, agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_2_chunk_idx_traces_workspace_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_workspace_model ON _timescaledb_internal._hyper_1_2_chunk USING btree (workspace_id, model, "timestamp" DESC);


--
-- Name: _hyper_1_2_chunk_idx_traces_workspace_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_workspace_status ON _timescaledb_internal._hyper_1_2_chunk USING btree (workspace_id, status, "timestamp" DESC);


--
-- Name: _hyper_1_2_chunk_idx_traces_workspace_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_workspace_timestamp ON _timescaledb_internal._hyper_1_2_chunk USING btree (workspace_id, "timestamp" DESC);


--
-- Name: _hyper_1_2_chunk_idx_traces_workspace_timestamp_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_workspace_timestamp_status ON _timescaledb_internal._hyper_1_2_chunk USING btree (workspace_id, "timestamp" DESC, status) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_2_chunk_idx_traces_workspace_user; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_idx_traces_workspace_user ON _timescaledb_internal._hyper_1_2_chunk USING btree (workspace_id, user_id, "timestamp" DESC);


--
-- Name: _hyper_1_2_chunk_traces_timestamp_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_2_chunk_traces_timestamp_idx ON _timescaledb_internal._hyper_1_2_chunk USING btree ("timestamp" DESC);


--
-- Name: _hyper_1_3_chunk_idx_traces_agent_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_agent_timestamp ON _timescaledb_internal._hyper_1_3_chunk USING btree (agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_3_chunk_idx_traces_cost_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_cost_analysis ON _timescaledb_internal._hyper_1_3_chunk USING btree (workspace_id, model, "timestamp" DESC) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_3_chunk_idx_traces_error_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_error_analysis ON _timescaledb_internal._hyper_1_3_chunk USING btree (workspace_id, agent_id, status, "timestamp" DESC) WHERE ((status)::text = 'error'::text);


--
-- Name: _hyper_1_3_chunk_idx_traces_latency_percentiles; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_latency_percentiles ON _timescaledb_internal._hyper_1_3_chunk USING btree (workspace_id, "timestamp" DESC) INCLUDE (latency_ms, status);


--
-- Name: _hyper_1_3_chunk_idx_traces_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_model ON _timescaledb_internal._hyper_1_3_chunk USING btree (model);


--
-- Name: _hyper_1_3_chunk_idx_traces_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_status ON _timescaledb_internal._hyper_1_3_chunk USING btree (status) WHERE ((status)::text <> 'success'::text);


--
-- Name: _hyper_1_3_chunk_idx_traces_tags; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_tags ON _timescaledb_internal._hyper_1_3_chunk USING gin (tags);


--
-- Name: _hyper_1_3_chunk_idx_traces_trace_id_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE UNIQUE INDEX _hyper_1_3_chunk_idx_traces_trace_id_timestamp ON _timescaledb_internal._hyper_1_3_chunk USING btree (trace_id, "timestamp");


--
-- Name: _hyper_1_3_chunk_idx_traces_workspace_agent; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_workspace_agent ON _timescaledb_internal._hyper_1_3_chunk USING btree (workspace_id, agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_3_chunk_idx_traces_workspace_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_workspace_model ON _timescaledb_internal._hyper_1_3_chunk USING btree (workspace_id, model, "timestamp" DESC);


--
-- Name: _hyper_1_3_chunk_idx_traces_workspace_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_workspace_status ON _timescaledb_internal._hyper_1_3_chunk USING btree (workspace_id, status, "timestamp" DESC);


--
-- Name: _hyper_1_3_chunk_idx_traces_workspace_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_workspace_timestamp ON _timescaledb_internal._hyper_1_3_chunk USING btree (workspace_id, "timestamp" DESC);


--
-- Name: _hyper_1_3_chunk_idx_traces_workspace_timestamp_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_workspace_timestamp_status ON _timescaledb_internal._hyper_1_3_chunk USING btree (workspace_id, "timestamp" DESC, status) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_3_chunk_idx_traces_workspace_user; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_idx_traces_workspace_user ON _timescaledb_internal._hyper_1_3_chunk USING btree (workspace_id, user_id, "timestamp" DESC);


--
-- Name: _hyper_1_3_chunk_traces_timestamp_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_3_chunk_traces_timestamp_idx ON _timescaledb_internal._hyper_1_3_chunk USING btree ("timestamp" DESC);


--
-- Name: _hyper_1_4_chunk_idx_traces_agent_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_agent_timestamp ON _timescaledb_internal._hyper_1_4_chunk USING btree (agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_4_chunk_idx_traces_cost_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_cost_analysis ON _timescaledb_internal._hyper_1_4_chunk USING btree (workspace_id, model, "timestamp" DESC) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_4_chunk_idx_traces_error_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_error_analysis ON _timescaledb_internal._hyper_1_4_chunk USING btree (workspace_id, agent_id, status, "timestamp" DESC) WHERE ((status)::text = 'error'::text);


--
-- Name: _hyper_1_4_chunk_idx_traces_latency_percentiles; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_latency_percentiles ON _timescaledb_internal._hyper_1_4_chunk USING btree (workspace_id, "timestamp" DESC) INCLUDE (latency_ms, status);


--
-- Name: _hyper_1_4_chunk_idx_traces_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_model ON _timescaledb_internal._hyper_1_4_chunk USING btree (model);


--
-- Name: _hyper_1_4_chunk_idx_traces_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_status ON _timescaledb_internal._hyper_1_4_chunk USING btree (status) WHERE ((status)::text <> 'success'::text);


--
-- Name: _hyper_1_4_chunk_idx_traces_tags; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_tags ON _timescaledb_internal._hyper_1_4_chunk USING gin (tags);


--
-- Name: _hyper_1_4_chunk_idx_traces_trace_id_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE UNIQUE INDEX _hyper_1_4_chunk_idx_traces_trace_id_timestamp ON _timescaledb_internal._hyper_1_4_chunk USING btree (trace_id, "timestamp");


--
-- Name: _hyper_1_4_chunk_idx_traces_workspace_agent; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_workspace_agent ON _timescaledb_internal._hyper_1_4_chunk USING btree (workspace_id, agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_4_chunk_idx_traces_workspace_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_workspace_model ON _timescaledb_internal._hyper_1_4_chunk USING btree (workspace_id, model, "timestamp" DESC);


--
-- Name: _hyper_1_4_chunk_idx_traces_workspace_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_workspace_status ON _timescaledb_internal._hyper_1_4_chunk USING btree (workspace_id, status, "timestamp" DESC);


--
-- Name: _hyper_1_4_chunk_idx_traces_workspace_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_workspace_timestamp ON _timescaledb_internal._hyper_1_4_chunk USING btree (workspace_id, "timestamp" DESC);


--
-- Name: _hyper_1_4_chunk_idx_traces_workspace_timestamp_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_workspace_timestamp_status ON _timescaledb_internal._hyper_1_4_chunk USING btree (workspace_id, "timestamp" DESC, status) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_4_chunk_idx_traces_workspace_user; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_idx_traces_workspace_user ON _timescaledb_internal._hyper_1_4_chunk USING btree (workspace_id, user_id, "timestamp" DESC);


--
-- Name: _hyper_1_4_chunk_traces_timestamp_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_4_chunk_traces_timestamp_idx ON _timescaledb_internal._hyper_1_4_chunk USING btree ("timestamp" DESC);


--
-- Name: _hyper_1_5_chunk_idx_traces_agent_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_agent_timestamp ON _timescaledb_internal._hyper_1_5_chunk USING btree (agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_5_chunk_idx_traces_cost_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_cost_analysis ON _timescaledb_internal._hyper_1_5_chunk USING btree (workspace_id, model, "timestamp" DESC) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_5_chunk_idx_traces_error_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_error_analysis ON _timescaledb_internal._hyper_1_5_chunk USING btree (workspace_id, agent_id, status, "timestamp" DESC) WHERE ((status)::text = 'error'::text);


--
-- Name: _hyper_1_5_chunk_idx_traces_latency_percentiles; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_latency_percentiles ON _timescaledb_internal._hyper_1_5_chunk USING btree (workspace_id, "timestamp" DESC) INCLUDE (latency_ms, status);


--
-- Name: _hyper_1_5_chunk_idx_traces_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_model ON _timescaledb_internal._hyper_1_5_chunk USING btree (model);


--
-- Name: _hyper_1_5_chunk_idx_traces_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_status ON _timescaledb_internal._hyper_1_5_chunk USING btree (status) WHERE ((status)::text <> 'success'::text);


--
-- Name: _hyper_1_5_chunk_idx_traces_tags; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_tags ON _timescaledb_internal._hyper_1_5_chunk USING gin (tags);


--
-- Name: _hyper_1_5_chunk_idx_traces_trace_id_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE UNIQUE INDEX _hyper_1_5_chunk_idx_traces_trace_id_timestamp ON _timescaledb_internal._hyper_1_5_chunk USING btree (trace_id, "timestamp");


--
-- Name: _hyper_1_5_chunk_idx_traces_workspace_agent; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_workspace_agent ON _timescaledb_internal._hyper_1_5_chunk USING btree (workspace_id, agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_5_chunk_idx_traces_workspace_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_workspace_model ON _timescaledb_internal._hyper_1_5_chunk USING btree (workspace_id, model, "timestamp" DESC);


--
-- Name: _hyper_1_5_chunk_idx_traces_workspace_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_workspace_status ON _timescaledb_internal._hyper_1_5_chunk USING btree (workspace_id, status, "timestamp" DESC);


--
-- Name: _hyper_1_5_chunk_idx_traces_workspace_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_workspace_timestamp ON _timescaledb_internal._hyper_1_5_chunk USING btree (workspace_id, "timestamp" DESC);


--
-- Name: _hyper_1_5_chunk_idx_traces_workspace_timestamp_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_workspace_timestamp_status ON _timescaledb_internal._hyper_1_5_chunk USING btree (workspace_id, "timestamp" DESC, status) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_5_chunk_idx_traces_workspace_user; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_idx_traces_workspace_user ON _timescaledb_internal._hyper_1_5_chunk USING btree (workspace_id, user_id, "timestamp" DESC);


--
-- Name: _hyper_1_5_chunk_traces_timestamp_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_5_chunk_traces_timestamp_idx ON _timescaledb_internal._hyper_1_5_chunk USING btree ("timestamp" DESC);


--
-- Name: _hyper_1_6_chunk_idx_traces_agent_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_agent_timestamp ON _timescaledb_internal._hyper_1_6_chunk USING btree (agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_6_chunk_idx_traces_cost_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_cost_analysis ON _timescaledb_internal._hyper_1_6_chunk USING btree (workspace_id, model, "timestamp" DESC) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_6_chunk_idx_traces_error_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_error_analysis ON _timescaledb_internal._hyper_1_6_chunk USING btree (workspace_id, agent_id, status, "timestamp" DESC) WHERE ((status)::text = 'error'::text);


--
-- Name: _hyper_1_6_chunk_idx_traces_latency_percentiles; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_latency_percentiles ON _timescaledb_internal._hyper_1_6_chunk USING btree (workspace_id, "timestamp" DESC) INCLUDE (latency_ms, status);


--
-- Name: _hyper_1_6_chunk_idx_traces_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_model ON _timescaledb_internal._hyper_1_6_chunk USING btree (model);


--
-- Name: _hyper_1_6_chunk_idx_traces_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_status ON _timescaledb_internal._hyper_1_6_chunk USING btree (status) WHERE ((status)::text <> 'success'::text);


--
-- Name: _hyper_1_6_chunk_idx_traces_tags; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_tags ON _timescaledb_internal._hyper_1_6_chunk USING gin (tags);


--
-- Name: _hyper_1_6_chunk_idx_traces_trace_id_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE UNIQUE INDEX _hyper_1_6_chunk_idx_traces_trace_id_timestamp ON _timescaledb_internal._hyper_1_6_chunk USING btree (trace_id, "timestamp");


--
-- Name: _hyper_1_6_chunk_idx_traces_workspace_agent; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_workspace_agent ON _timescaledb_internal._hyper_1_6_chunk USING btree (workspace_id, agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_6_chunk_idx_traces_workspace_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_workspace_model ON _timescaledb_internal._hyper_1_6_chunk USING btree (workspace_id, model, "timestamp" DESC);


--
-- Name: _hyper_1_6_chunk_idx_traces_workspace_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_workspace_status ON _timescaledb_internal._hyper_1_6_chunk USING btree (workspace_id, status, "timestamp" DESC);


--
-- Name: _hyper_1_6_chunk_idx_traces_workspace_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_workspace_timestamp ON _timescaledb_internal._hyper_1_6_chunk USING btree (workspace_id, "timestamp" DESC);


--
-- Name: _hyper_1_6_chunk_idx_traces_workspace_timestamp_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_workspace_timestamp_status ON _timescaledb_internal._hyper_1_6_chunk USING btree (workspace_id, "timestamp" DESC, status) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_6_chunk_idx_traces_workspace_user; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_idx_traces_workspace_user ON _timescaledb_internal._hyper_1_6_chunk USING btree (workspace_id, user_id, "timestamp" DESC);


--
-- Name: _hyper_1_6_chunk_traces_timestamp_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_6_chunk_traces_timestamp_idx ON _timescaledb_internal._hyper_1_6_chunk USING btree ("timestamp" DESC);


--
-- Name: _hyper_1_7_chunk_idx_traces_agent_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_agent_timestamp ON _timescaledb_internal._hyper_1_7_chunk USING btree (agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_7_chunk_idx_traces_cost_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_cost_analysis ON _timescaledb_internal._hyper_1_7_chunk USING btree (workspace_id, model, "timestamp" DESC) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_7_chunk_idx_traces_error_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_error_analysis ON _timescaledb_internal._hyper_1_7_chunk USING btree (workspace_id, agent_id, status, "timestamp" DESC) WHERE ((status)::text = 'error'::text);


--
-- Name: _hyper_1_7_chunk_idx_traces_latency_percentiles; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_latency_percentiles ON _timescaledb_internal._hyper_1_7_chunk USING btree (workspace_id, "timestamp" DESC) INCLUDE (latency_ms, status);


--
-- Name: _hyper_1_7_chunk_idx_traces_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_model ON _timescaledb_internal._hyper_1_7_chunk USING btree (model);


--
-- Name: _hyper_1_7_chunk_idx_traces_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_status ON _timescaledb_internal._hyper_1_7_chunk USING btree (status) WHERE ((status)::text <> 'success'::text);


--
-- Name: _hyper_1_7_chunk_idx_traces_tags; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_tags ON _timescaledb_internal._hyper_1_7_chunk USING gin (tags);


--
-- Name: _hyper_1_7_chunk_idx_traces_trace_id_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE UNIQUE INDEX _hyper_1_7_chunk_idx_traces_trace_id_timestamp ON _timescaledb_internal._hyper_1_7_chunk USING btree (trace_id, "timestamp");


--
-- Name: _hyper_1_7_chunk_idx_traces_workspace_agent; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_workspace_agent ON _timescaledb_internal._hyper_1_7_chunk USING btree (workspace_id, agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_7_chunk_idx_traces_workspace_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_workspace_model ON _timescaledb_internal._hyper_1_7_chunk USING btree (workspace_id, model, "timestamp" DESC);


--
-- Name: _hyper_1_7_chunk_idx_traces_workspace_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_workspace_status ON _timescaledb_internal._hyper_1_7_chunk USING btree (workspace_id, status, "timestamp" DESC);


--
-- Name: _hyper_1_7_chunk_idx_traces_workspace_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_workspace_timestamp ON _timescaledb_internal._hyper_1_7_chunk USING btree (workspace_id, "timestamp" DESC);


--
-- Name: _hyper_1_7_chunk_idx_traces_workspace_timestamp_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_workspace_timestamp_status ON _timescaledb_internal._hyper_1_7_chunk USING btree (workspace_id, "timestamp" DESC, status) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_7_chunk_idx_traces_workspace_user; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_idx_traces_workspace_user ON _timescaledb_internal._hyper_1_7_chunk USING btree (workspace_id, user_id, "timestamp" DESC);


--
-- Name: _hyper_1_7_chunk_traces_timestamp_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_7_chunk_traces_timestamp_idx ON _timescaledb_internal._hyper_1_7_chunk USING btree ("timestamp" DESC);


--
-- Name: _hyper_1_8_chunk_idx_traces_agent_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_agent_timestamp ON _timescaledb_internal._hyper_1_8_chunk USING btree (agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_8_chunk_idx_traces_cost_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_cost_analysis ON _timescaledb_internal._hyper_1_8_chunk USING btree (workspace_id, model, "timestamp" DESC) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_8_chunk_idx_traces_error_analysis; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_error_analysis ON _timescaledb_internal._hyper_1_8_chunk USING btree (workspace_id, agent_id, status, "timestamp" DESC) WHERE ((status)::text = 'error'::text);


--
-- Name: _hyper_1_8_chunk_idx_traces_latency_percentiles; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_latency_percentiles ON _timescaledb_internal._hyper_1_8_chunk USING btree (workspace_id, "timestamp" DESC) INCLUDE (latency_ms, status);


--
-- Name: _hyper_1_8_chunk_idx_traces_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_model ON _timescaledb_internal._hyper_1_8_chunk USING btree (model);


--
-- Name: _hyper_1_8_chunk_idx_traces_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_status ON _timescaledb_internal._hyper_1_8_chunk USING btree (status) WHERE ((status)::text <> 'success'::text);


--
-- Name: _hyper_1_8_chunk_idx_traces_tags; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_tags ON _timescaledb_internal._hyper_1_8_chunk USING gin (tags);


--
-- Name: _hyper_1_8_chunk_idx_traces_trace_id_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE UNIQUE INDEX _hyper_1_8_chunk_idx_traces_trace_id_timestamp ON _timescaledb_internal._hyper_1_8_chunk USING btree (trace_id, "timestamp");


--
-- Name: _hyper_1_8_chunk_idx_traces_workspace_agent; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_workspace_agent ON _timescaledb_internal._hyper_1_8_chunk USING btree (workspace_id, agent_id, "timestamp" DESC);


--
-- Name: _hyper_1_8_chunk_idx_traces_workspace_model; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_workspace_model ON _timescaledb_internal._hyper_1_8_chunk USING btree (workspace_id, model, "timestamp" DESC);


--
-- Name: _hyper_1_8_chunk_idx_traces_workspace_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_workspace_status ON _timescaledb_internal._hyper_1_8_chunk USING btree (workspace_id, status, "timestamp" DESC);


--
-- Name: _hyper_1_8_chunk_idx_traces_workspace_timestamp; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_workspace_timestamp ON _timescaledb_internal._hyper_1_8_chunk USING btree (workspace_id, "timestamp" DESC);


--
-- Name: _hyper_1_8_chunk_idx_traces_workspace_timestamp_status; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_workspace_timestamp_status ON _timescaledb_internal._hyper_1_8_chunk USING btree (workspace_id, "timestamp" DESC, status) WHERE (cost_usd IS NOT NULL);


--
-- Name: _hyper_1_8_chunk_idx_traces_workspace_user; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_idx_traces_workspace_user ON _timescaledb_internal._hyper_1_8_chunk USING btree (workspace_id, user_id, "timestamp" DESC);


--
-- Name: _hyper_1_8_chunk_traces_timestamp_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_1_8_chunk_traces_timestamp_idx ON _timescaledb_internal._hyper_1_8_chunk USING btree ("timestamp" DESC);


--
-- Name: _hyper_2_9_chunk__materialized_hypertable_2_agent_id_hour_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_2_9_chunk__materialized_hypertable_2_agent_id_hour_idx ON _timescaledb_internal._hyper_2_9_chunk USING btree (agent_id, hour DESC);


--
-- Name: _hyper_2_9_chunk__materialized_hypertable_2_hour_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_2_9_chunk__materialized_hypertable_2_hour_idx ON _timescaledb_internal._hyper_2_9_chunk USING btree (hour DESC);


--
-- Name: _hyper_2_9_chunk__materialized_hypertable_2_model_hour_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_2_9_chunk__materialized_hypertable_2_model_hour_idx ON _timescaledb_internal._hyper_2_9_chunk USING btree (model, hour DESC);


--
-- Name: _hyper_2_9_chunk__materialized_hypertable_2_workspace_id_hour_i; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_2_9_chunk__materialized_hypertable_2_workspace_id_hour_i ON _timescaledb_internal._hyper_2_9_chunk USING btree (workspace_id, hour DESC);


--
-- Name: _hyper_3_11_chunk__materialized_hypertable_3_agent_id_day_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_3_11_chunk__materialized_hypertable_3_agent_id_day_idx ON _timescaledb_internal._hyper_3_11_chunk USING btree (agent_id, day DESC);


--
-- Name: _hyper_3_11_chunk__materialized_hypertable_3_day_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_3_11_chunk__materialized_hypertable_3_day_idx ON _timescaledb_internal._hyper_3_11_chunk USING btree (day DESC);


--
-- Name: _hyper_3_11_chunk__materialized_hypertable_3_model_day_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_3_11_chunk__materialized_hypertable_3_model_day_idx ON _timescaledb_internal._hyper_3_11_chunk USING btree (model, day DESC);


--
-- Name: _hyper_3_11_chunk__materialized_hypertable_3_workspace_id_day_i; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_3_11_chunk__materialized_hypertable_3_workspace_id_day_i ON _timescaledb_internal._hyper_3_11_chunk USING btree (workspace_id, day DESC);


--
-- Name: _hyper_3_12_chunk__materialized_hypertable_3_agent_id_day_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_3_12_chunk__materialized_hypertable_3_agent_id_day_idx ON _timescaledb_internal._hyper_3_12_chunk USING btree (agent_id, day DESC);


--
-- Name: _hyper_3_12_chunk__materialized_hypertable_3_day_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_3_12_chunk__materialized_hypertable_3_day_idx ON _timescaledb_internal._hyper_3_12_chunk USING btree (day DESC);


--
-- Name: _hyper_3_12_chunk__materialized_hypertable_3_model_day_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_3_12_chunk__materialized_hypertable_3_model_day_idx ON _timescaledb_internal._hyper_3_12_chunk USING btree (model, day DESC);


--
-- Name: _hyper_3_12_chunk__materialized_hypertable_3_workspace_id_day_i; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _hyper_3_12_chunk__materialized_hypertable_3_workspace_id_day_i ON _timescaledb_internal._hyper_3_12_chunk USING btree (workspace_id, day DESC);


--
-- Name: _materialized_hypertable_2_agent_id_hour_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _materialized_hypertable_2_agent_id_hour_idx ON _timescaledb_internal._materialized_hypertable_2 USING btree (agent_id, hour DESC);


--
-- Name: _materialized_hypertable_2_hour_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _materialized_hypertable_2_hour_idx ON _timescaledb_internal._materialized_hypertable_2 USING btree (hour DESC);


--
-- Name: _materialized_hypertable_2_model_hour_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _materialized_hypertable_2_model_hour_idx ON _timescaledb_internal._materialized_hypertable_2 USING btree (model, hour DESC);


--
-- Name: _materialized_hypertable_2_workspace_id_hour_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _materialized_hypertable_2_workspace_id_hour_idx ON _timescaledb_internal._materialized_hypertable_2 USING btree (workspace_id, hour DESC);


--
-- Name: _materialized_hypertable_3_agent_id_day_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _materialized_hypertable_3_agent_id_day_idx ON _timescaledb_internal._materialized_hypertable_3 USING btree (agent_id, day DESC);


--
-- Name: _materialized_hypertable_3_day_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _materialized_hypertable_3_day_idx ON _timescaledb_internal._materialized_hypertable_3 USING btree (day DESC);


--
-- Name: _materialized_hypertable_3_model_day_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _materialized_hypertable_3_model_day_idx ON _timescaledb_internal._materialized_hypertable_3 USING btree (model, day DESC);


--
-- Name: _materialized_hypertable_3_workspace_id_day_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX _materialized_hypertable_3_workspace_id_day_idx ON _timescaledb_internal._materialized_hypertable_3 USING btree (workspace_id, day DESC);


--
-- Name: compress_hyper_6_10_chunk_workspace_id_agent_id__ts_meta_mi_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX compress_hyper_6_10_chunk_workspace_id_agent_id__ts_meta_mi_idx ON _timescaledb_internal.compress_hyper_6_10_chunk USING btree (workspace_id, agent_id, _ts_meta_min_1 DESC, _ts_meta_max_1 DESC, _ts_meta_min_2, _ts_meta_max_2, _ts_meta_min_3, _ts_meta_max_3, _ts_meta_min_4, _ts_meta_max_4, _ts_meta_min_5, _ts_meta_max_5);


--
-- Name: compress_hyper_6_13_chunk_workspace_id_agent_id__ts_meta_mi_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX compress_hyper_6_13_chunk_workspace_id_agent_id__ts_meta_mi_idx ON _timescaledb_internal.compress_hyper_6_13_chunk USING btree (workspace_id, agent_id, _ts_meta_min_1 DESC, _ts_meta_max_1 DESC, _ts_meta_min_2, _ts_meta_max_2, _ts_meta_min_3, _ts_meta_max_3, _ts_meta_min_4, _ts_meta_max_4, _ts_meta_min_5, _ts_meta_max_5);


--
-- Name: compress_hyper_6_14_chunk_workspace_id_agent_id__ts_meta_mi_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX compress_hyper_6_14_chunk_workspace_id_agent_id__ts_meta_mi_idx ON _timescaledb_internal.compress_hyper_6_14_chunk USING btree (workspace_id, agent_id, _ts_meta_min_1 DESC, _ts_meta_max_1 DESC, _ts_meta_min_2, _ts_meta_max_2, _ts_meta_min_3, _ts_meta_max_3, _ts_meta_min_4, _ts_meta_max_4, _ts_meta_min_5, _ts_meta_max_5);


--
-- Name: compress_hyper_6_15_chunk_workspace_id_agent_id__ts_meta_mi_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX compress_hyper_6_15_chunk_workspace_id_agent_id__ts_meta_mi_idx ON _timescaledb_internal.compress_hyper_6_15_chunk USING btree (workspace_id, agent_id, _ts_meta_min_1 DESC, _ts_meta_max_1 DESC, _ts_meta_min_2, _ts_meta_max_2, _ts_meta_min_3, _ts_meta_max_3, _ts_meta_min_4, _ts_meta_max_4, _ts_meta_min_5, _ts_meta_max_5);


--
-- Name: compress_hyper_6_16_chunk_workspace_id_agent_id__ts_meta_mi_idx; Type: INDEX; Schema: _timescaledb_internal; Owner: postgres
--

CREATE INDEX compress_hyper_6_16_chunk_workspace_id_agent_id__ts_meta_mi_idx ON _timescaledb_internal.compress_hyper_6_16_chunk USING btree (workspace_id, agent_id, _ts_meta_min_1 DESC, _ts_meta_max_1 DESC, _ts_meta_min_2, _ts_meta_max_2, _ts_meta_min_3, _ts_meta_max_3, _ts_meta_min_4, _ts_meta_max_4, _ts_meta_min_5, _ts_meta_max_5);


--
-- Name: events_timestamp_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX events_timestamp_idx ON public.events USING btree ("timestamp" DESC);


--
-- Name: idx_events_event_id_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_events_event_id_timestamp ON public.events USING btree (event_id, "timestamp");


--
-- Name: idx_events_type_severity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_events_type_severity ON public.events USING btree (event_type, severity, "timestamp" DESC);


--
-- Name: idx_events_unacknowledged; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_events_unacknowledged ON public.events USING btree (acknowledged, "timestamp" DESC) WHERE (acknowledged = false);


--
-- Name: idx_events_workspace_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_events_workspace_timestamp ON public.events USING btree (workspace_id, "timestamp" DESC);


--
-- Name: idx_perf_agent_metric; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_perf_agent_metric ON public.performance_metrics USING btree (agent_id, metric_name, "timestamp" DESC);


--
-- Name: idx_perf_workspace_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_perf_workspace_timestamp ON public.performance_metrics USING btree (workspace_id, "timestamp" DESC);


--
-- Name: idx_traces_agent_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_agent_timestamp ON public.traces USING btree (agent_id, "timestamp" DESC);


--
-- Name: idx_traces_cost_analysis; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_cost_analysis ON public.traces USING btree (workspace_id, model, "timestamp" DESC) WHERE (cost_usd IS NOT NULL);


--
-- Name: idx_traces_error_analysis; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_error_analysis ON public.traces USING btree (workspace_id, agent_id, status, "timestamp" DESC) WHERE ((status)::text = 'error'::text);


--
-- Name: idx_traces_latency_percentiles; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_latency_percentiles ON public.traces USING btree (workspace_id, "timestamp" DESC) INCLUDE (latency_ms, status);


--
-- Name: idx_traces_model; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_model ON public.traces USING btree (model);


--
-- Name: idx_traces_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_status ON public.traces USING btree (status) WHERE ((status)::text <> 'success'::text);


--
-- Name: idx_traces_tags; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_tags ON public.traces USING gin (tags);


--
-- Name: idx_traces_trace_id_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_traces_trace_id_timestamp ON public.traces USING btree (trace_id, "timestamp");


--
-- Name: idx_traces_workspace_agent; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_workspace_agent ON public.traces USING btree (workspace_id, agent_id, "timestamp" DESC);


--
-- Name: idx_traces_workspace_model; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_workspace_model ON public.traces USING btree (workspace_id, model, "timestamp" DESC);


--
-- Name: idx_traces_workspace_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_workspace_status ON public.traces USING btree (workspace_id, status, "timestamp" DESC);


--
-- Name: idx_traces_workspace_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_workspace_timestamp ON public.traces USING btree (workspace_id, "timestamp" DESC);


--
-- Name: idx_traces_workspace_timestamp_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_workspace_timestamp_status ON public.traces USING btree (workspace_id, "timestamp" DESC, status) WHERE (cost_usd IS NOT NULL);


--
-- Name: idx_traces_workspace_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traces_workspace_user ON public.traces USING btree (workspace_id, user_id, "timestamp" DESC);


--
-- Name: performance_metrics_timestamp_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX performance_metrics_timestamp_idx ON public.performance_metrics USING btree ("timestamp" DESC);


--
-- Name: traces_timestamp_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX traces_timestamp_idx ON public.traces USING btree ("timestamp" DESC);


--
-- Name: _hyper_1_1_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_1_1_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('1');


--
-- Name: _hyper_1_2_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_1_2_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('1');


--
-- Name: _hyper_1_3_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_1_3_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('1');


--
-- Name: _hyper_1_4_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_1_4_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('1');


--
-- Name: _hyper_1_5_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_1_5_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('1');


--
-- Name: _hyper_1_6_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_1_6_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('1');


--
-- Name: _hyper_1_7_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_1_7_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('1');


--
-- Name: _hyper_1_8_chunk ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON _timescaledb_internal._hyper_1_8_chunk FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('1');


--
-- Name: _compressed_hypertable_6 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_6 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_7 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_7 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_8 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_8 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _materialized_hypertable_2 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._materialized_hypertable_2 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _materialized_hypertable_3 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._materialized_hypertable_3 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: traces ts_cagg_invalidation_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ts_cagg_invalidation_trigger AFTER INSERT OR DELETE OR UPDATE ON public.traces FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.continuous_agg_invalidation_trigger('1');


--
-- Name: events ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.events FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: performance_metrics ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.performance_metrics FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: traces ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.traces FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- PostgreSQL database dump complete
--

