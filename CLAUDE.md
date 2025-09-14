Step‑by‑Step Implementation Roadmap
Phase 1 – Foundations
Project Setup

Initialize Rust backend project (Axum or Actix Web).

Initialize Flutter project (Android focus, but cross‑platform ready).

Set up Git repository and branching strategy.

Define .env structure for backend (DB URL, JWT secrets, etc.).

Database & Migrations

Install PostgreSQL + TimescaleDB locally.

Create initial schema: users, exercise_types, exercises, workouts, sensor_timeseries.

Add constraints, indexes, and soft delete fields.

Set up migration tool (sqlx migrate or similar).

Auth & Security

Implement user registration and login in Rust.

Password hashing with Argon2id.

JWT access + refresh tokens.

Middleware for authentication and ownership checks.

Enforce HTTPS in production.

Phase 2 – Core Data Model & API
Exercise Types

CRUD endpoints for exercise types (global + user‑specific).

JSON schema validation for metadata fields.

Exercises

CRUD endpoints for exercises.

Support creation without a workout.

Validation for metadata (no negative reps, weight, etc.).

Batch insert endpoint.

Workouts

CRUD endpoints for workouts.

Link/unlink exercises to workouts.

Auto‑update workout status when exercises are added.

Time ordering validation.

Phase 3 – Sensor Data & Analytics
Sensor Time Series

Endpoint to upload sensor data (bulk insert).

Link to exercises where applicable.

Store in TimescaleDB hypertable.

Analytics Endpoints

Aggregated stats (distance, pace, volume, etc.).

Progression over time.

Materialized views for performance.

Phase 4 – Flutter App Core
Local Data Layer

Set up Drift (SQLite) for offline storage.

Define local models mirroring API contracts.

Implement repository pattern.

Networking Layer

API client with Dio or http.

Auth token handling (refresh flow).

Error handling and retries.

Offline Sync

Queue unsynced changes with client‑generated UUIDs.

Exponential backoff retries.

Conflict resolution prompts for the user.

Phase 5 – Flutter App UI
Authentication Screens

Login, registration, logout flows.

Token persistence.

Exercise Logging

Quick‑add exercise screen.

Metadata form based on exercise type schema.

Option to link to an existing workout.

Workout Planning & Execution

Create planned workout.

Add exercises during session.

Mark workout as completed.

History & Analytics

Filterable history view.

Analytics dashboard with charts.

CSV export trigger (downloads from backend).

Phase 6 – Polish & Deployment
Testing

Backend: unit + integration tests for endpoints.

Frontend: widget + integration tests for sync flows.

API contract tests with Postman/Insomnia.

Performance & Security

Index tuning.

Rate limiting.

Audit logs for key actions.

Deployment

Backend: containerize with Docker, deploy to cloud (e.g., Fly.io, AWS).

Database: managed Postgres + TimescaleDB.

Flutter app: release to Google Play.

Phase 7 – Future Enhancements
Workout Templates

Pre‑defined exercise sets for quick planning.

Third‑Party Integrations

Import sensor data from Garmin, Polar, Strava APIs.

Push Notifications

Reminders for planned workouts.