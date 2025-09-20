-- Initial schema for Training App (Regular PostgreSQL version)
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ NULL
);

-- Exercise types table (global + user-defined)
CREATE TABLE exercise_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    metadata_schema JSONB NOT NULL DEFAULT '{}',
    is_global BOOLEAN NOT NULL DEFAULT false,
    user_id UUID NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ NULL,

    -- Ensure global exercise types have no user_id, user-defined have user_id
    CONSTRAINT exercise_types_global_check CHECK (
        (is_global = true AND user_id IS NULL) OR
        (is_global = false AND user_id IS NOT NULL)
    )
);

-- Workouts table
CREATE TABLE workouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    name VARCHAR(255),
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed')),
    planned_start TIMESTAMPTZ,
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ NULL
);

-- Exercises table (first-class entities)
CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    exercise_type_id UUID NOT NULL REFERENCES exercise_types(id),
    workout_id UUID NULL REFERENCES workouts(id),
    name VARCHAR(255),
    notes TEXT,
    metadata JSONB NOT NULL DEFAULT '{}',
    performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ NULL
);

-- Sensor time series table (Regular PostgreSQL table)
CREATE TABLE sensor_timeseries (
    time TIMESTAMPTZ NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id),
    exercise_id UUID NULL REFERENCES exercises(id),
    sensor_type VARCHAR(50) NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(20),
    metadata JSONB DEFAULT '{}'
);

-- Add indexes for performance
CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_deleted_at ON users(deleted_at);

CREATE INDEX idx_exercise_types_global ON exercise_types(is_global) WHERE deleted_at IS NULL;
CREATE INDEX idx_exercise_types_user_id ON exercise_types(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_exercise_types_category ON exercise_types(category) WHERE deleted_at IS NULL;

CREATE INDEX idx_workouts_user_id ON workouts(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_workouts_status ON workouts(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_workouts_planned_start ON workouts(planned_start) WHERE deleted_at IS NULL;

CREATE INDEX idx_exercises_user_id ON exercises(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_exercises_exercise_type_id ON exercises(exercise_type_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_exercises_workout_id ON exercises(workout_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_exercises_performed_at ON exercises(performed_at) WHERE deleted_at IS NULL;

-- Regular PostgreSQL indexes for sensor data
CREATE INDEX idx_sensor_timeseries_user_id_time ON sensor_timeseries(user_id, time DESC);
CREATE INDEX idx_sensor_timeseries_exercise_id_time ON sensor_timeseries(exercise_id, time DESC);
CREATE INDEX idx_sensor_timeseries_sensor_type_time ON sensor_timeseries(sensor_type, time DESC);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at timestamps
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exercise_types_updated_at BEFORE UPDATE ON exercise_types
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_workouts_updated_at BEFORE UPDATE ON workouts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exercises_updated_at BEFORE UPDATE ON exercises
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();