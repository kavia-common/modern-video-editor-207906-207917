# PostgreSQL schema + seed setup (statement-by-statement)

This repo’s PostgreSQL schema is designed to be applied **one SQL statement at a time** via `psql -c "..."`, per container rules.

## Important note about ports
- `database/startup.sh` currently starts PostgreSQL on `${PORT:-5001}`
- In this environment, PostgreSQL was observed running on **port 5000**.
- Always connect using the command in `database/db_connection.txt` **or** use the active port discovered via `ss -ltnp | grep postgres`.

## How to connect
From `modern-video-editor-207906-207917/database`:

```bash
# Preferred: use the repo-provided connection command (may need port update)
CONN="$(cat db_connection.txt)"
echo "$CONN"

# Or explicit (update port if needed)
psql "postgresql://appuser:dbuser123@localhost:5000/myapp"
```

## Verify current schema
```bash
psql "postgresql://appuser:dbuser123@localhost:5000/myapp" -c \
"SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name;"
```

Expected tables:
- projects
- media_assets
- timeline_tracks
- timeline_clips
- clip_trims
- transitions
- export_jobs
- export_job_events

## Apply schema (DDL) — execute ONE statement at a time

> Tip: in bash, set a variable once:
> `CONN='psql postgresql://appuser:dbuser123@localhost:5000/myapp'`

### 1) Extensions / helpers
```bash
$CONN -c "CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;"
```

```bash
$CONN -c "CREATE OR REPLACE FUNCTION public.set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;"
```

### 2) Core tables

```bash
$CONN -c "CREATE TABLE IF NOT EXISTS public.projects (id uuid DEFAULT gen_random_uuid() NOT NULL, name text NOT NULL, description text, width integer DEFAULT 1920 NOT NULL, height integer DEFAULT 1080 NOT NULL, fps numeric(6,3) DEFAULT 30.000 NOT NULL, duration_ms bigint DEFAULT 0 NOT NULL, created_at timestamp with time zone DEFAULT now() NOT NULL, updated_at timestamp with time zone DEFAULT now() NOT NULL);"
```

```bash
$CONN -c "CREATE TABLE IF NOT EXISTS public.media_assets (id uuid DEFAULT gen_random_uuid() NOT NULL, project_id uuid NOT NULL, kind text NOT NULL, source_uri text NOT NULL, original_filename text, mime_type text, size_bytes bigint, duration_ms bigint, width integer, height integer, fps numeric(6,3), has_audio boolean DEFAULT false NOT NULL, metadata jsonb DEFAULT '{}'::jsonb NOT NULL, created_at timestamp with time zone DEFAULT now() NOT NULL, CONSTRAINT media_assets_kind_check CHECK ((kind = ANY (ARRAY['video'::text, 'audio'::text, 'image'::text]))));"
```

```bash
$CONN -c "CREATE TABLE IF NOT EXISTS public.timeline_tracks (id uuid DEFAULT gen_random_uuid() NOT NULL, project_id uuid NOT NULL, track_type text NOT NULL, name text NOT NULL, sort_order integer DEFAULT 0 NOT NULL, muted boolean DEFAULT false NOT NULL, locked boolean DEFAULT false NOT NULL, created_at timestamp with time zone DEFAULT now() NOT NULL, CONSTRAINT timeline_tracks_track_type_check CHECK ((track_type = ANY (ARRAY['video'::text, 'audio'::text, 'overlay'::text]))));"
```

```bash
$CONN -c "CREATE TABLE IF NOT EXISTS public.timeline_clips (id uuid DEFAULT gen_random_uuid() NOT NULL, project_id uuid NOT NULL, track_id uuid NOT NULL, media_asset_id uuid, clip_type text NOT NULL, name text, start_ms bigint DEFAULT 0 NOT NULL, end_ms bigint DEFAULT 0 NOT NULL, in_ms bigint DEFAULT 0 NOT NULL, out_ms bigint DEFAULT 0 NOT NULL, speed numeric(8,4) DEFAULT 1.0 NOT NULL, opacity numeric(5,4) DEFAULT 1.0 NOT NULL, volume numeric(8,4) DEFAULT 1.0 NOT NULL, transform jsonb DEFAULT '{}'::jsonb NOT NULL, created_at timestamp with time zone DEFAULT now() NOT NULL, CONSTRAINT chk_clip_in_out CHECK ((out_ms >= in_ms)), CONSTRAINT chk_clip_range CHECK ((end_ms >= start_ms)), CONSTRAINT timeline_clips_clip_type_check CHECK ((clip_type = ANY (ARRAY['media'::text, 'title'::text, 'color'::text, 'generator'::text]))));"
```

```bash
$CONN -c "CREATE TABLE IF NOT EXISTS public.clip_trims (id uuid DEFAULT gen_random_uuid() NOT NULL, clip_id uuid NOT NULL, kind text NOT NULL, trim_in_ms bigint, trim_out_ms bigint, created_at timestamp with time zone DEFAULT now() NOT NULL, CONSTRAINT chk_trim_values CHECK ((((trim_in_ms IS NULL) OR (trim_in_ms >= 0)) AND ((trim_out_ms IS NULL) OR (trim_out_ms >= 0)))), CONSTRAINT clip_trims_kind_check CHECK ((kind = ANY (ARRAY['in'::text, 'out'::text, 'both'::text]))));"
```

```bash
$CONN -c "CREATE TABLE IF NOT EXISTS public.transitions (id uuid DEFAULT gen_random_uuid() NOT NULL, project_id uuid NOT NULL, track_id uuid NOT NULL, from_clip_id uuid NOT NULL, to_clip_id uuid NOT NULL, transition_type text DEFAULT 'crossfade'::text NOT NULL, duration_ms bigint DEFAULT 1000 NOT NULL, easing text DEFAULT 'linear'::text NOT NULL, params jsonb DEFAULT '{}'::jsonb NOT NULL, created_at timestamp with time zone DEFAULT now() NOT NULL, CONSTRAINT chk_transition_duration CHECK ((duration_ms >= 0)));"
```

```bash
$CONN -c "CREATE TABLE IF NOT EXISTS public.export_jobs (id uuid DEFAULT gen_random_uuid() NOT NULL, project_id uuid NOT NULL, preset text DEFAULT 'mp4_h264'::text NOT NULL, output_uri text, status text NOT NULL, progress numeric(5,2) DEFAULT 0.00 NOT NULL, error_message text, started_at timestamp with time zone, finished_at timestamp with time zone, created_at timestamp with time zone DEFAULT now() NOT NULL, updated_at timestamp with time zone DEFAULT now() NOT NULL, CONSTRAINT export_jobs_status_check CHECK ((status = ANY (ARRAY['queued'::text, 'running'::text, 'succeeded'::text, 'failed'::text, 'canceled'::text]))));"
```

```bash
$CONN -c "CREATE TABLE IF NOT EXISTS public.export_job_events (id bigint NOT NULL, export_job_id uuid NOT NULL, event_type text NOT NULL, message text, progress numeric(5,2), created_at timestamp with time zone DEFAULT now() NOT NULL, CONSTRAINT export_job_events_event_type_check CHECK ((event_type = ANY (ARRAY['created'::text, 'queued'::text, 'started'::text, 'progress'::text, 'completed'::text, 'failed'::text, 'canceled'::text]))));"
```

### 3) Sequence for export_job_events.id
```bash
$CONN -c "CREATE SEQUENCE IF NOT EXISTS public.export_job_events_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;"
```

```bash
$CONN -c "ALTER SEQUENCE public.export_job_events_id_seq OWNED BY public.export_job_events.id;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.export_job_events ALTER COLUMN id SET DEFAULT nextval('public.export_job_events_id_seq'::regclass);"
```

### 4) Primary keys (execute individually)
```bash
$CONN -c "ALTER TABLE ONLY public.projects ADD CONSTRAINT projects_pkey PRIMARY KEY (id);"
```

```bash
$CONN -c "ALTER TABLE ONLY public.media_assets ADD CONSTRAINT media_assets_pkey PRIMARY KEY (id);"
```

```bash
$CONN -c "ALTER TABLE ONLY public.timeline_tracks ADD CONSTRAINT timeline_tracks_pkey PRIMARY KEY (id);"
```

```bash
$CONN -c "ALTER TABLE ONLY public.timeline_clips ADD CONSTRAINT timeline_clips_pkey PRIMARY KEY (id);"
```

```bash
$CONN -c "ALTER TABLE ONLY public.clip_trims ADD CONSTRAINT clip_trims_pkey PRIMARY KEY (id);"
```

```bash
$CONN -c "ALTER TABLE ONLY public.transitions ADD CONSTRAINT transitions_pkey PRIMARY KEY (id);"
```

```bash
$CONN -c "ALTER TABLE ONLY public.export_jobs ADD CONSTRAINT export_jobs_pkey PRIMARY KEY (id);"
```

```bash
$CONN -c "ALTER TABLE ONLY public.export_job_events ADD CONSTRAINT export_job_events_pkey PRIMARY KEY (id);"
```

### 5) Foreign keys (execute individually)
```bash
$CONN -c "ALTER TABLE ONLY public.media_assets ADD CONSTRAINT media_assets_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.timeline_tracks ADD CONSTRAINT timeline_tracks_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.timeline_clips ADD CONSTRAINT timeline_clips_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.timeline_clips ADD CONSTRAINT timeline_clips_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.timeline_tracks(id) ON DELETE CASCADE;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.timeline_clips ADD CONSTRAINT timeline_clips_media_asset_id_fkey FOREIGN KEY (media_asset_id) REFERENCES public.media_assets(id) ON DELETE SET NULL;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.clip_trims ADD CONSTRAINT clip_trims_clip_id_fkey FOREIGN KEY (clip_id) REFERENCES public.timeline_clips(id) ON DELETE CASCADE;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.export_jobs ADD CONSTRAINT export_jobs_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.export_job_events ADD CONSTRAINT export_job_events_export_job_id_fkey FOREIGN KEY (export_job_id) REFERENCES public.export_jobs(id) ON DELETE CASCADE;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.transitions ADD CONSTRAINT transitions_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.transitions ADD CONSTRAINT transitions_track_id_fkey FOREIGN KEY (track_id) REFERENCES public.timeline_tracks(id) ON DELETE CASCADE;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.transitions ADD CONSTRAINT transitions_from_clip_id_fkey FOREIGN KEY (from_clip_id) REFERENCES public.timeline_clips(id) ON DELETE CASCADE;"
```

```bash
$CONN -c "ALTER TABLE ONLY public.transitions ADD CONSTRAINT transitions_to_clip_id_fkey FOREIGN KEY (to_clip_id) REFERENCES public.timeline_clips(id) ON DELETE CASCADE;"
```

### 6) Triggers for updated_at
```bash
$CONN -c "DROP TRIGGER IF EXISTS trg_projects_updated_at ON public.projects;"
```

```bash
$CONN -c "CREATE TRIGGER trg_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();"
```

```bash
$CONN -c "DROP TRIGGER IF EXISTS trg_export_jobs_updated_at ON public.export_jobs;"
```

```bash
$CONN -c "CREATE TRIGGER trg_export_jobs_updated_at BEFORE UPDATE ON public.export_jobs FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();"
```

### 7) Indexes (execute individually)
```bash
$CONN -c "CREATE INDEX IF NOT EXISTS idx_projects_updated_at ON public.projects USING btree (updated_at DESC);"
```

```bash
$CONN -c "CREATE INDEX IF NOT EXISTS idx_media_assets_project_id ON public.media_assets USING btree (project_id);"
```

```bash
$CONN -c "CREATE INDEX IF NOT EXISTS idx_timeline_tracks_project_id_order ON public.timeline_tracks USING btree (project_id, sort_order);"
```

```bash
$CONN -c "CREATE INDEX IF NOT EXISTS idx_timeline_clips_project_time ON public.timeline_clips USING btree (project_id, start_ms);"
```

```bash
$CONN -c "CREATE INDEX IF NOT EXISTS idx_timeline_clips_track_time ON public.timeline_clips USING btree (track_id, start_ms);"
```

```bash
$CONN -c "CREATE INDEX IF NOT EXISTS idx_clip_trims_clip_id ON public.clip_trims USING btree (clip_id);"
```

```bash
$CONN -c "CREATE INDEX IF NOT EXISTS idx_transitions_project_track ON public.transitions USING btree (project_id, track_id);"
```

```bash
$CONN -c "CREATE INDEX IF NOT EXISTS idx_export_jobs_project_created ON public.export_jobs USING btree (project_id, created_at DESC);"
```

```bash
$CONN -c "CREATE INDEX IF NOT EXISTS idx_export_job_events_job_time ON public.export_job_events USING btree (export_job_id, created_at);"
```

## Seed data (minimal) — one INSERT at a time

These IDs match the existing `database_backup.sql` seed data.

```bash
$CONN -c "INSERT INTO public.projects (id, name, description, width, height, fps, duration_ms) VALUES ('11111111-1111-1111-1111-111111111111','Demo Project','Seed project with a simple timeline',1920,1080,30.000,10000) ON CONFLICT (id) DO NOTHING;"
```

```bash
$CONN -c "INSERT INTO public.timeline_tracks (id, project_id, track_type, name, sort_order, muted, locked) VALUES ('33333333-3333-3333-3333-333333333333','11111111-1111-1111-1111-111111111111','video','Video 1',0,false,false) ON CONFLICT (id) DO NOTHING;"
```

```bash
$CONN -c "INSERT INTO public.timeline_tracks (id, project_id, track_type, name, sort_order, muted, locked) VALUES ('44444444-4444-4444-4444-444444444444','11111111-1111-1111-1111-111111111111','audio','Audio 1',1,false,false) ON CONFLICT (id) DO NOTHING;"
```

```bash
$CONN -c "INSERT INTO public.media_assets (id, project_id, kind, source_uri, original_filename, mime_type, duration_ms, width, height, fps, has_audio, metadata) VALUES ('22222222-2222-2222-2222-222222222222','11111111-1111-1111-1111-111111111111','video','/uploads/demo.mp4','demo.mp4','video/mp4',10000,1920,1080,30.000,true,'{}'::jsonb) ON CONFLICT (id) DO NOTHING;"
```

```bash
$CONN -c "INSERT INTO public.timeline_clips (id, project_id, track_id, media_asset_id, clip_type, name, start_ms, end_ms, in_ms, out_ms, speed, opacity, volume, transform) VALUES ('55555555-5555-5555-5555-555555555555','11111111-1111-1111-1111-111111111111','33333333-3333-3333-3333-333333333333','22222222-2222-2222-2222-222222222222','media','Demo Clip A',0,5000,0,5000,1.0,1.0,1.0,'{}'::jsonb) ON CONFLICT (id) DO NOTHING;"
```

```bash
$CONN -c "INSERT INTO public.timeline_clips (id, project_id, track_id, media_asset_id, clip_type, name, start_ms, end_ms, in_ms, out_ms, speed, opacity, volume, transform) VALUES ('66666666-6666-6666-6666-666666666666','11111111-1111-1111-1111-111111111111','33333333-3333-3333-3333-333333333333','22222222-2222-2222-2222-222222222222','media','Demo Clip B',5000,10000,5000,10000,1.0,1.0,1.0,'{}'::jsonb) ON CONFLICT (id) DO NOTHING;"
```

```bash
$CONN -c "INSERT INTO public.clip_trims (id, clip_id, kind, trim_in_ms, trim_out_ms) VALUES ('77777777-7777-7777-7777-777777777777','55555555-5555-5555-5555-555555555555','both',250,250) ON CONFLICT (id) DO NOTHING;"
```

```bash
$CONN -c "INSERT INTO public.transitions (id, project_id, track_id, from_clip_id, to_clip_id, transition_type, duration_ms, easing, params) VALUES ('88888888-8888-8888-8888-888888888888','11111111-1111-1111-1111-111111111111','33333333-3333-3333-3333-333333333333','55555555-5555-5555-5555-555555555555','66666666-6666-6666-6666-666666666666','crossfade',750,'ease_in_out','{}'::jsonb) ON CONFLICT (id) DO NOTHING;"
```

```bash
$CONN -c "INSERT INTO public.export_jobs (id, project_id, preset, output_uri, status, progress) VALUES ('99999999-9999-9999-9999-999999999999','11111111-1111-1111-1111-111111111111','mp4_h264','/exports/demo_project.mp4','succeeded',100.00) ON CONFLICT (id) DO NOTHING;"
```

```bash
$CONN -c "INSERT INTO public.export_job_events (export_job_id, event_type, message, progress) VALUES ('99999999-9999-9999-9999-999999999999','created','Export job created',NULL);"
```

```bash
$CONN -c "INSERT INTO public.export_job_events (export_job_id, event_type, message, progress) VALUES ('99999999-9999-9999-9999-999999999999','started','Export started',0.00);"
```

```bash
$CONN -c "INSERT INTO public.export_job_events (export_job_id, event_type, message, progress) VALUES ('99999999-9999-9999-9999-999999999999','progress','Encoding...',55.50);"
```

```bash
$CONN -c "INSERT INTO public.export_job_events (export_job_id, event_type, message, progress) VALUES ('99999999-9999-9999-9999-999999999999','completed','Export completed',100.00);"
```

## Quick seed verification
```bash
$CONN -c "SELECT (SELECT count(*) FROM projects) AS projects, (SELECT count(*) FROM timeline_tracks) AS tracks, (SELECT count(*) FROM timeline_clips) AS clips, (SELECT count(*) FROM media_assets) AS assets, (SELECT count(*) FROM export_jobs) AS export_jobs;"
```
