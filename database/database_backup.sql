--
-- PostgreSQL database dump
--

\restrict tdO3zclHqZXXgxBIf8xRZvIYgdrUfQ2UTSjbbshh7VkClUJ6559WZDL8sRR8p6f

-- Dumped from database version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)

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

DROP DATABASE IF EXISTS myapp;
--
-- Name: myapp; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE myapp WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE myapp OWNER TO postgres;

\unrestrict tdO3zclHqZXXgxBIf8xRZvIYgdrUfQ2UTSjbbshh7VkClUJ6559WZDL8sRR8p6f
\connect myapp
\restrict tdO3zclHqZXXgxBIf8xRZvIYgdrUfQ2UTSjbbshh7VkClUJ6559WZDL8sRR8p6f

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
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: appuser
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;


ALTER FUNCTION public.set_updated_at() OWNER TO appuser;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: clip_trims; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.clip_trims (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    clip_id uuid NOT NULL,
    kind text NOT NULL,
    trim_in_ms bigint,
    trim_out_ms bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_trim_values CHECK ((((trim_in_ms IS NULL) OR (trim_in_ms >= 0)) AND ((trim_out_ms IS NULL) OR (trim_out_ms >= 0)))),
    CONSTRAINT clip_trims_kind_check CHECK ((kind = ANY (ARRAY['in'::text, 'out'::text, 'both'::text])))
);


ALTER TABLE public.clip_trims OWNER TO appuser;

--
-- Name: export_job_events; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.export_job_events (
    id bigint NOT NULL,
    export_job_id uuid NOT NULL,
    event_type text NOT NULL,
    message text,
    progress numeric(5,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT export_job_events_event_type_check CHECK ((event_type = ANY (ARRAY['created'::text, 'queued'::text, 'started'::text, 'progress'::text, 'completed'::text, 'failed'::text, 'canceled'::text])))
);


ALTER TABLE public.export_job_events OWNER TO appuser;

--
-- Name: export_job_events_id_seq; Type: SEQUENCE; Schema: public; Owner: appuser
--

CREATE SEQUENCE public.export_job_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.export_job_events_id_seq OWNER TO appuser;

--
-- Name: export_job_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: appuser
--

ALTER SEQUENCE public.export_job_events_id_seq OWNED BY public.export_job_events.id;


--
-- Name: export_jobs; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.export_jobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    preset text DEFAULT 'mp4_h264'::text NOT NULL,
    output_uri text,
    status text NOT NULL,
    progress numeric(5,2) DEFAULT 0.00 NOT NULL,
    error_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT export_jobs_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'running'::text, 'succeeded'::text, 'failed'::text, 'canceled'::text])))
);


ALTER TABLE public.export_jobs OWNER TO appuser;

--
-- Name: media_assets; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.media_assets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    kind text NOT NULL,
    source_uri text NOT NULL,
    original_filename text,
    mime_type text,
    size_bytes bigint,
    duration_ms bigint,
    width integer,
    height integer,
    fps numeric(6,3),
    has_audio boolean DEFAULT false NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT media_assets_kind_check CHECK ((kind = ANY (ARRAY['video'::text, 'audio'::text, 'image'::text])))
);


ALTER TABLE public.media_assets OWNER TO appuser;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.projects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    width integer DEFAULT 1920 NOT NULL,
    height integer DEFAULT 1080 NOT NULL,
    fps numeric(6,3) DEFAULT 30.000 NOT NULL,
    duration_ms bigint DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.projects OWNER TO appuser;

--
-- Name: timeline_clips; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.timeline_clips (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    track_id uuid NOT NULL,
    media_asset_id uuid,
    clip_type text NOT NULL,
    name text,
    start_ms bigint DEFAULT 0 NOT NULL,
    end_ms bigint DEFAULT 0 NOT NULL,
    in_ms bigint DEFAULT 0 NOT NULL,
    out_ms bigint DEFAULT 0 NOT NULL,
    speed numeric(8,4) DEFAULT 1.0 NOT NULL,
    opacity numeric(5,4) DEFAULT 1.0 NOT NULL,
    volume numeric(8,4) DEFAULT 1.0 NOT NULL,
    transform jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_clip_in_out CHECK ((out_ms >= in_ms)),
    CONSTRAINT chk_clip_range CHECK ((end_ms >= start_ms)),
    CONSTRAINT timeline_clips_clip_type_check CHECK ((clip_type = ANY (ARRAY['media'::text, 'title'::text, 'color'::text, 'generator'::text])))
);


ALTER TABLE public.timeline_clips OWNER TO appuser;

--
-- Name: timeline_tracks; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.timeline_tracks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    track_type text NOT NULL,
    name text NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    muted boolean DEFAULT false NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT timeline_tracks_track_type_check CHECK ((track_type = ANY (ARRAY['video'::text, 'audio'::text, 'overlay'::text])))
);


ALTER TABLE public.timeline_tracks OWNER TO appuser;

--
-- Name: transitions; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.transitions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    track_id uuid NOT NULL,
    from_clip_id uuid NOT NULL,
    to_clip_id uuid NOT NULL,
    transition_type text DEFAULT 'crossfade'::text NOT NULL,
    duration_ms bigint DEFAULT 1000 NOT NULL,
    easing text DEFAULT 'linear'::text NOT NULL,
    params jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_transition_duration CHECK ((duration_ms >= 0))
);


ALTER TABLE public.transitions OWNER TO appuser;

--
-- Name: export_job_events id; Type: DEFAULT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.export_job_events ALTER COLUMN id SET DEFAULT nextval('public.export_job_events_id_seq'::regclass);


--
-- Data for Name: clip_trims; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.clip_trims (id, clip_id, kind, trim_in_ms, trim_out_ms, created_at) FROM stdin;
77777777-7777-7777-7777-777777777777	55555555-5555-5555-5555-555555555555	both	250	250	2026-01-30 13:37:10.901991+00
\.


--
-- Data for Name: export_job_events; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.export_job_events (id, export_job_id, event_type, message, progress, created_at) FROM stdin;
1	99999999-9999-9999-9999-999999999999	created	Export job created	\N	2026-01-30 13:37:21.927039+00
2	99999999-9999-9999-9999-999999999999	started	Export started	0.00	2026-01-30 13:37:24.569092+00
3	99999999-9999-9999-9999-999999999999	progress	Encoding...	55.50	2026-01-30 13:37:26.84231+00
4	99999999-9999-9999-9999-999999999999	completed	Export completed	100.00	2026-01-30 13:37:30.829045+00
\.


--
-- Data for Name: export_jobs; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.export_jobs (id, project_id, preset, output_uri, status, progress, error_message, started_at, finished_at, created_at, updated_at) FROM stdin;
99999999-9999-9999-9999-999999999999	11111111-1111-1111-1111-111111111111	mp4_h264	/exports/demo_project.mp4	succeeded	100.00	\N	\N	\N	2026-01-30 13:37:19.516775+00	2026-01-30 13:37:19.516775+00
\.


--
-- Data for Name: media_assets; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.media_assets (id, project_id, kind, source_uri, original_filename, mime_type, size_bytes, duration_ms, width, height, fps, has_audio, metadata, created_at) FROM stdin;
22222222-2222-2222-2222-222222222222	11111111-1111-1111-1111-111111111111	video	/uploads/demo.mp4	demo.mp4	video/mp4	\N	10000	1920	1080	30.000	t	{}	2026-01-30 13:36:50.443906+00
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.projects (id, name, description, width, height, fps, duration_ms, created_at, updated_at) FROM stdin;
11111111-1111-1111-1111-111111111111	Demo Project	Seed project with a simple timeline	1920	1080	30.000	10000	2026-01-30 13:36:39.479356+00	2026-01-30 13:36:39.479356+00
\.


--
-- Data for Name: timeline_clips; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.timeline_clips (id, project_id, track_id, media_asset_id, clip_type, name, start_ms, end_ms, in_ms, out_ms, speed, opacity, volume, transform, created_at) FROM stdin;
55555555-5555-5555-5555-555555555555	11111111-1111-1111-1111-111111111111	33333333-3333-3333-3333-333333333333	22222222-2222-2222-2222-222222222222	media	Demo Clip A	0	5000	0	5000	1.0000	1.0000	1.0000	{}	2026-01-30 13:37:01.969699+00
66666666-6666-6666-6666-666666666666	11111111-1111-1111-1111-111111111111	33333333-3333-3333-3333-333333333333	22222222-2222-2222-2222-222222222222	media	Demo Clip B	5000	10000	5000	10000	1.0000	1.0000	1.0000	{}	2026-01-30 13:37:06.831933+00
\.


--
-- Data for Name: timeline_tracks; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.timeline_tracks (id, project_id, track_type, name, sort_order, muted, locked, created_at) FROM stdin;
33333333-3333-3333-3333-333333333333	11111111-1111-1111-1111-111111111111	video	Video 1	0	f	f	2026-01-30 13:36:56.021578+00
44444444-4444-4444-4444-444444444444	11111111-1111-1111-1111-111111111111	audio	Audio 1	1	f	f	2026-01-30 13:36:58.268269+00
\.


--
-- Data for Name: transitions; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.transitions (id, project_id, track_id, from_clip_id, to_clip_id, transition_type, duration_ms, easing, params, created_at) FROM stdin;
88888888-8888-8888-8888-888888888888	11111111-1111-1111-1111-111111111111	33333333-3333-3333-3333-333333333333	55555555-5555-5555-5555-555555555555	66666666-6666-6666-6666-666666666666	crossfade	750	ease_in_out	{}	2026-01-30 13:37:14.651356+00
\.


--
-- Name: export_job_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: appuser
--

SELECT pg_catalog.setval('public.export_job_events_id_seq', 4, true);


--
-- Name: clip_trims clip_trims_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.clip_trims
    ADD CONSTRAINT clip_trims_pkey PRIMARY KEY (id);


--
-- Name: export_job_events export_job_events_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.export_job_events
    ADD CONSTRAINT export_job_events_pkey PRIMARY KEY (id);


--
-- Name: export_jobs export_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.export_jobs
    ADD CONSTRAINT export_jobs_pkey PRIMARY KEY (id);


--
-- Name: media_assets media_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.media_assets
    ADD CONSTRAINT media_assets_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: timeline_clips timeline_clips_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.timeline_clips
    ADD CONSTRAINT timeline_clips_pkey PRIMARY KEY (id);


--
-- Name: timeline_tracks timeline_tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.timeline_tracks
    ADD CONSTRAINT timeline_tracks_pkey PRIMARY KEY (id);


--
-- Name: transitions transitions_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.transitions
    ADD CONSTRAINT transitions_pkey PRIMARY KEY (id);


--
-- Name: idx_clip_trims_clip_id; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_clip_trims_clip_id ON public.clip_trims USING btree (clip_id);


--
-- Name: idx_export_job_events_job_time; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_export_job_events_job_time ON public.export_job_events USING btree (export_job_id, created_at);


--
-- Name: idx_export_jobs_project_created; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_export_jobs_project_created ON public.export_jobs USING btree (project_id, created_at DESC);


--
-- Name: idx_media_assets_project_id; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_media_assets_project_id ON public.media_assets USING btree (project_id);


--
-- Name: idx_projects_updated_at; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_projects_updated_at ON public.projects USING btree (updated_at DESC);


--
-- Name: idx_timeline_clips_project_time; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_timeline_clips_project_time ON public.timeline_clips USING btree (project_id, start_ms);


--
-- Name: idx_timeline_clips_track_time; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_timeline_clips_track_time ON public.timeline_clips USING btree (track_id, start_ms);


--
-- Name: idx_timeline_tracks_project_id_order; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_timeline_tracks_project_id_order ON public.timeline_tracks USING btree (project_id, sort_order);


--
-- Name: idx_transitions_project_track; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_transitions_project_track ON public.transitions USING btree (project_id, track_id);


--
-- Name: export_jobs trg_export_jobs_updated_at; Type: TRIGGER; Schema: public; Owner: appuser
--

CREATE TRIGGER trg_export_jobs_updated_at BEFORE UPDATE ON public.export_jobs FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: projects trg_projects_updated_at; Type: TRIGGER; Schema: public; Owner: appuser
--

CREATE TRIGGER trg_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: clip_trims clip_trims_clip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.clip_trims
    ADD CONSTRAINT clip_trims_clip_id_fkey FOREIGN KEY (clip_id) REFERENCES public.timeline_clips(id) ON DELETE CASCADE;


--
-- Name: export_job_events export_job_events_export_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.export_job_events
    ADD CONSTRAINT export_job_events_export_job_id_fkey FOREIGN KEY (export_job_id) REFERENCES public.export_jobs(id) ON DELETE CASCADE;


--
-- Name: export_jobs export_jobs_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.export_jobs
    ADD CONSTRAINT export_jobs_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: media_assets media_assets_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.media_assets
    ADD CONSTRAINT media_assets_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: timeline_clips timeline_clips_media_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.timeline_clips
    ADD CONSTRAINT timeline_clips_media_asset_id_fkey FOREIGN KEY (media_asset_id) REFERENCES public.media_assets(id) ON DELETE SET NULL;


--
-- Name: timeline_clips timeline_clips_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.timeline_clips
    ADD CONSTRAINT timeline_clips_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: timeline_clips timeline_clips_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.timeline_clips
    ADD CONSTRAINT timeline_clips_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.timeline_tracks(id) ON DELETE CASCADE;


--
-- Name: timeline_tracks timeline_tracks_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.timeline_tracks
    ADD CONSTRAINT timeline_tracks_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: transitions transitions_from_clip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.transitions
    ADD CONSTRAINT transitions_from_clip_id_fkey FOREIGN KEY (from_clip_id) REFERENCES public.timeline_clips(id) ON DELETE CASCADE;


--
-- Name: transitions transitions_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.transitions
    ADD CONSTRAINT transitions_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: transitions transitions_to_clip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.transitions
    ADD CONSTRAINT transitions_to_clip_id_fkey FOREIGN KEY (to_clip_id) REFERENCES public.timeline_clips(id) ON DELETE CASCADE;


--
-- Name: transitions transitions_track_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.transitions
    ADD CONSTRAINT transitions_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.timeline_tracks(id) ON DELETE CASCADE;


--
-- Name: DATABASE myapp; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON DATABASE myapp TO appuser;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO appuser;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea) TO appuser;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea, text[], text[]) TO appuser;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.crypt(text, text) TO appuser;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dearmor(text) TO appuser;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt_iv(bytea, bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(bytea, text) TO appuser;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(text, text) TO appuser;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt_iv(bytea, bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_bytes(integer) TO appuser;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_uuid() TO appuser;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text) TO appuser;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text, integer) TO appuser;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(text, text, text) TO appuser;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_armor_headers(text, OUT key text, OUT value text) TO appuser;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_key_id(bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text, text) TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR TYPES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TYPES TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO appuser;


--
-- PostgreSQL database dump complete
--

\unrestrict tdO3zclHqZXXgxBIf8xRZvIYgdrUfQ2UTSjbbshh7VkClUJ6559WZDL8sRR8p6f

