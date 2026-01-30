# Schema verification report

This report captures the live DB inspection performed for step **02.01 Implement PostgreSQL schema and seed data**.

## Connection
- `database/db_connection.txt` contents: `psql postgresql://appuser:dbuser123@localhost:5001/myapp`
- Attempting to connect to port **5001** returned: connection refused
- A PostgreSQL server was found running on port **5000**:
  - process: `/usr/lib/postgresql/16/bin/postgres -D /var/lib/postgresql/data -p 5000`
  - listening sockets: `127.0.0.1:5000` and `[::1]:5000`

Successful connection used:
- `psql postgresql://appuser:dbuser123@localhost:5000/myapp`

## Tables present (public schema)
The following tables were present and verified in the running DB:
1. `projects`
2. `media_assets`
3. `timeline_tracks`
4. `timeline_clips`
5. `clip_trims`
6. `transitions`
7. `export_jobs`
8. `export_job_events`

## Seed data present
Row counts observed:
- projects: 1
- timeline_tracks: 2
- timeline_clips: 2
- media_assets: 1
- export_jobs: 1

## Notes
- The schema structure and sample seed data match what is contained in `database/database_backup.sql`.
- For a reproducible procedure that follows the container rule “execute SQL statements one at a time”, see: `database/SCHEMA_SETUP.md`.
