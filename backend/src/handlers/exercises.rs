use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
};
use serde::Deserialize;
use serde_json::{json, Value};
use time::OffsetDateTime;
use uuid::Uuid;
use validator::Validate;

use crate::{
    middleware::auth::AuthUser,
    models::exercise::{
        CreateExerciseRequest, ExerciseResponse, ExerciseWithType, UpdateExerciseRequest,
    },
    state::AppState,
};

#[derive(Debug, Deserialize)]
pub struct ExerciseQuery {
    pub exercise_type_id: Option<Uuid>,
    pub workout_id: Option<Uuid>,
    pub category: Option<String>,
    pub start_date: Option<String>, // ISO date string
    pub end_date: Option<String>,   // ISO date string
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

pub async fn list_exercises(
    State(state): State<AppState>,
    auth_user: axum::Extension<AuthUser>,
    Query(params): Query<ExerciseQuery>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let limit = params.limit.unwrap_or(50).min(100);
    let offset = params.offset.unwrap_or(0);

    // Parse date filters if provided
    let start_date = if let Some(start_str) = params.start_date {
        match OffsetDateTime::parse(&start_str, &time::format_description::well_known::Rfc3339) {
            Ok(date) => Some(date),
            Err(_) => {
                return Err((
                    StatusCode::BAD_REQUEST,
                    Json(json!({"error": "Invalid start_date format. Use ISO 8601/RFC3339 format."})),
                ));
            }
        }
    } else {
        None
    };

    let end_date = if let Some(end_str) = params.end_date {
        match OffsetDateTime::parse(&end_str, &time::format_description::well_known::Rfc3339) {
            Ok(date) => Some(date),
            Err(_) => {
                return Err((
                    StatusCode::BAD_REQUEST,
                    Json(json!({"error": "Invalid end_date format. Use ISO 8601/RFC3339 format."})),
                ));
            }
        }
    } else {
        None
    };

    // Build query based on filters
    let exercises = match (
        &params.exercise_type_id,
        &params.workout_id,
        &params.category,
        &start_date,
        &end_date,
    ) {
        // Filter by exercise type
        (Some(exercise_type_id), None, None, None, None) => {
            sqlx::query_as!(
                ExerciseWithType,
                r#"
                SELECT e.id, e.user_id, e.exercise_type_id, et.name as exercise_type_name,
                       et.category as exercise_type_category, et.metadata_schema as exercise_type_metadata_schema,
                       e.workout_id, e.name, e.notes, e.metadata, e.performed_at, e.created_at, e.updated_at
                FROM exercises e
                JOIN exercise_types et ON e.exercise_type_id = et.id
                WHERE e.deleted_at IS NULL AND e.user_id = $1 AND e.exercise_type_id = $2
                ORDER BY e.performed_at DESC
                LIMIT $3 OFFSET $4
                "#,
                auth_user.id,
                exercise_type_id,
                limit,
                offset
            )
            .fetch_all(&state.pool)
            .await
        }
        // Filter by workout
        (None, Some(workout_id), None, None, None) => {
            sqlx::query_as!(
                ExerciseWithType,
                r#"
                SELECT e.id, e.user_id, e.exercise_type_id, et.name as exercise_type_name,
                       et.category as exercise_type_category, et.metadata_schema as exercise_type_metadata_schema,
                       e.workout_id, e.name, e.notes, e.metadata, e.performed_at, e.created_at, e.updated_at
                FROM exercises e
                JOIN exercise_types et ON e.exercise_type_id = et.id
                WHERE e.deleted_at IS NULL AND e.user_id = $1 AND e.workout_id = $2
                ORDER BY e.performed_at DESC
                LIMIT $3 OFFSET $4
                "#,
                auth_user.id,
                workout_id,
                limit,
                offset
            )
            .fetch_all(&state.pool)
            .await
        }
        // Filter by category
        (None, None, Some(category), None, None) => {
            sqlx::query_as!(
                ExerciseWithType,
                r#"
                SELECT e.id, e.user_id, e.exercise_type_id, et.name as exercise_type_name,
                       et.category as exercise_type_category, et.metadata_schema as exercise_type_metadata_schema,
                       e.workout_id, e.name, e.notes, e.metadata, e.performed_at, e.created_at, e.updated_at
                FROM exercises e
                JOIN exercise_types et ON e.exercise_type_id = et.id
                WHERE e.deleted_at IS NULL AND e.user_id = $1 AND et.category = $2
                ORDER BY e.performed_at DESC
                LIMIT $3 OFFSET $4
                "#,
                auth_user.id,
                category,
                limit,
                offset
            )
            .fetch_all(&state.pool)
            .await
        }
        // Filter by date range
        (None, None, None, Some(start), Some(end)) => {
            sqlx::query_as!(
                ExerciseWithType,
                r#"
                SELECT e.id, e.user_id, e.exercise_type_id, et.name as exercise_type_name,
                       et.category as exercise_type_category, et.metadata_schema as exercise_type_metadata_schema,
                       e.workout_id, e.name, e.notes, e.metadata, e.performed_at, e.created_at, e.updated_at
                FROM exercises e
                JOIN exercise_types et ON e.exercise_type_id = et.id
                WHERE e.deleted_at IS NULL AND e.user_id = $1 AND e.performed_at BETWEEN $2 AND $3
                ORDER BY e.performed_at DESC
                LIMIT $4 OFFSET $5
                "#,
                auth_user.id,
                start,
                end,
                limit,
                offset
            )
            .fetch_all(&state.pool)
            .await
        }
        // Default: all user exercises
        _ => {
            sqlx::query_as!(
                ExerciseWithType,
                r#"
                SELECT e.id, e.user_id, e.exercise_type_id, et.name as exercise_type_name,
                       et.category as exercise_type_category, et.metadata_schema as exercise_type_metadata_schema,
                       e.workout_id, e.name, e.notes, e.metadata, e.performed_at, e.created_at, e.updated_at
                FROM exercises e
                JOIN exercise_types et ON e.exercise_type_id = et.id
                WHERE e.deleted_at IS NULL AND e.user_id = $1
                ORDER BY e.performed_at DESC
                LIMIT $2 OFFSET $3
                "#,
                auth_user.id,
                limit,
                offset
            )
            .fetch_all(&state.pool)
            .await
        }
    }
    .map_err(|e| {
        tracing::error!("Database error fetching exercises: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let responses: Vec<ExerciseResponse> = exercises
        .into_iter()
        .map(ExerciseResponse::from)
        .collect();

    Ok(Json(json!({
        "exercises": responses,
        "pagination": {
            "limit": limit,
            "offset": offset,
            "count": responses.len()
        }
    })))
}

pub async fn get_exercise(
    State(state): State<AppState>,
    auth_user: axum::Extension<AuthUser>,
    Path(id): Path<Uuid>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let exercise = sqlx::query_as!(
        ExerciseWithType,
        r#"
        SELECT e.id, e.user_id, e.exercise_type_id, et.name as exercise_type_name,
               et.category as exercise_type_category, et.metadata_schema as exercise_type_metadata_schema,
               e.workout_id, e.name, e.notes, e.metadata, e.performed_at, e.created_at, e.updated_at
        FROM exercises e
        JOIN exercise_types et ON e.exercise_type_id = et.id
        WHERE e.id = $1 AND e.deleted_at IS NULL AND e.user_id = $2
        "#,
        id,
        auth_user.id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error fetching exercise: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let exercise = exercise.ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(json!({"error": "Exercise not found"})),
        )
    })?;

    Ok(Json(json!(ExerciseResponse::from(exercise))))
}

pub async fn create_exercise(
    State(state): State<AppState>,
    auth_user: axum::Extension<AuthUser>,
    Json(payload): Json<CreateExerciseRequest>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    // Validate request
    if let Err(errors) = payload.validate() {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Validation failed",
                "details": errors
            })),
        ));
    }

    // Verify exercise type exists and user has access to it
    let exercise_type = sqlx::query!(
        "SELECT id, metadata_schema FROM exercise_types WHERE id = $1 AND deleted_at IS NULL AND (is_global = true OR user_id = $2)",
        payload.exercise_type_id,
        auth_user.id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error checking exercise type: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let exercise_type = exercise_type.ok_or_else(|| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({"error": "Exercise type not found or not accessible"})),
        )
    })?;

    // Validate metadata against schema if provided
    let metadata = payload.metadata.unwrap_or_else(|| json!({}));
    if let Err(e) = validate_exercise_metadata(&metadata, &exercise_type.metadata_schema) {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Invalid metadata",
                "details": e
            })),
        ));
    }

    // If workout_id is provided, verify user owns the workout
    if let Some(workout_id) = payload.workout_id {
        let workout_exists = sqlx::query!(
            "SELECT id FROM workouts WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL",
            workout_id,
            auth_user.id
        )
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error checking workout: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Internal server error"})),
            )
        })?;

        if workout_exists.is_none() {
            return Err((
                StatusCode::BAD_REQUEST,
                Json(json!({"error": "Workout not found or not accessible"})),
            ));
        }
    }

    let performed_at = payload.performed_at.unwrap_or_else(OffsetDateTime::now_utc);

    let exercise = sqlx::query_as!(
        ExerciseWithType,
        r#"
        WITH inserted_exercise AS (
            INSERT INTO exercises (user_id, exercise_type_id, workout_id, name, notes, metadata, performed_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING id, user_id, exercise_type_id, workout_id, name, notes, metadata, performed_at, created_at, updated_at
        )
        SELECT ie.id, ie.user_id, ie.exercise_type_id, et.name as exercise_type_name,
               et.category as exercise_type_category, et.metadata_schema as exercise_type_metadata_schema,
               ie.workout_id, ie.name, ie.notes, ie.metadata, ie.performed_at, ie.created_at, ie.updated_at
        FROM inserted_exercise ie
        JOIN exercise_types et ON ie.exercise_type_id = et.id
        "#,
        auth_user.id,
        payload.exercise_type_id,
        payload.workout_id,
        payload.name,
        payload.notes,
        metadata,
        performed_at
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error creating exercise: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    Ok(Json(json!(ExerciseResponse::from(exercise))))
}

pub async fn update_exercise(
    State(state): State<AppState>,
    auth_user: axum::Extension<AuthUser>,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateExerciseRequest>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    // Validate request
    if let Err(errors) = payload.validate() {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({
                "error": "Validation failed",
                "details": errors
            })),
        ));
    }

    // Check if exercise exists and user owns it
    let existing = sqlx::query!(
        "SELECT id, exercise_type_id FROM exercises WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL",
        id,
        auth_user.id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error fetching exercise: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let existing = existing.ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(json!({"error": "Exercise not found"})),
        )
    })?;

    // If exercise_type_id is being updated, verify the new type exists and user has access
    let new_exercise_type_id = payload.exercise_type_id.unwrap_or(existing.exercise_type_id);
    let exercise_type = sqlx::query!(
        "SELECT id, metadata_schema FROM exercise_types WHERE id = $1 AND deleted_at IS NULL AND (is_global = true OR user_id = $2)",
        new_exercise_type_id,
        auth_user.id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error checking exercise type: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let exercise_type = exercise_type.ok_or_else(|| {
        (
            StatusCode::BAD_REQUEST,
            Json(json!({"error": "Exercise type not found or not accessible"})),
        )
    })?;

    // Validate metadata against schema if provided
    if let Some(ref metadata) = payload.metadata {
        if let Err(e) = validate_exercise_metadata(metadata, &exercise_type.metadata_schema) {
            return Err((
                StatusCode::BAD_REQUEST,
                Json(json!({
                    "error": "Invalid metadata",
                    "details": e
                })),
            ));
        }
    }

    // If workout_id is being updated, verify user owns the workout
    if let Some(workout_id) = payload.workout_id {
        let workout_exists = sqlx::query!(
            "SELECT id FROM workouts WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL",
            workout_id,
            auth_user.id
        )
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error checking workout: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Internal server error"})),
            )
        })?;

        if workout_exists.is_none() {
            return Err((
                StatusCode::BAD_REQUEST,
                Json(json!({"error": "Workout not found or not accessible"})),
            ));
        }
    }

    // Check if any fields are provided for update
    if payload.exercise_type_id.is_none()
        && payload.workout_id.is_none()
        && payload.name.is_none()
        && payload.notes.is_none()
        && payload.metadata.is_none()
        && payload.performed_at.is_none() {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({"error": "No fields to update"})),
        ));
    }

    // Update the exercise
    let exercise = sqlx::query_as!(
        ExerciseWithType,
        r#"
        WITH updated_exercise AS (
            UPDATE exercises
            SET exercise_type_id = COALESCE($2, exercise_type_id),
                workout_id = COALESCE($3, workout_id),
                name = COALESCE($4, name),
                notes = COALESCE($5, notes),
                metadata = COALESCE($6, metadata),
                performed_at = COALESCE($7, performed_at),
                updated_at = NOW()
            WHERE id = $1 AND user_id = $8 AND deleted_at IS NULL
            RETURNING id, user_id, exercise_type_id, workout_id, name, notes, metadata, performed_at, created_at, updated_at
        )
        SELECT ue.id, ue.user_id, ue.exercise_type_id, et.name as exercise_type_name,
               et.category as exercise_type_category, et.metadata_schema as exercise_type_metadata_schema,
               ue.workout_id, ue.name, ue.notes, ue.metadata, ue.performed_at, ue.created_at, ue.updated_at
        FROM updated_exercise ue
        JOIN exercise_types et ON ue.exercise_type_id = et.id
        "#,
        id,
        payload.exercise_type_id,
        payload.workout_id,
        payload.name,
        payload.notes,
        payload.metadata,
        payload.performed_at,
        auth_user.id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error updating exercise: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let exercise = exercise.ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(json!({"error": "Exercise not found or you don't have permission to modify it"})),
        )
    })?;

    Ok(Json(json!(ExerciseResponse::from(exercise))))
}

pub async fn delete_exercise(
    State(state): State<AppState>,
    auth_user: axum::Extension<AuthUser>,
    Path(id): Path<Uuid>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    // Soft delete the exercise
    let deleted = sqlx::query!(
        "UPDATE exercises SET deleted_at = NOW() WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL",
        id,
        auth_user.id
    )
    .execute(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error deleting exercise: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    if deleted.rows_affected() == 0 {
        return Err((
            StatusCode::NOT_FOUND,
            Json(json!({"error": "Exercise not found or you don't have permission to delete it"})),
        ));
    }

    Ok(Json(json!({"message": "Exercise deleted successfully"})))
}

// Helper function to validate exercise metadata against exercise type schema
fn validate_exercise_metadata(
    metadata: &serde_json::Value,
    schema: &serde_json::Value,
) -> Result<(), String> {
    // Basic validation - ensure metadata is an object
    if !metadata.is_object() {
        return Err("Metadata must be a JSON object".to_string());
    }

    // If schema requires specific properties, validate them
    if let Some(schema_obj) = schema.as_object() {
        if let Some(properties) = schema_obj.get("properties") {
            if let Some(props_obj) = properties.as_object() {
                let metadata_obj = metadata.as_object().unwrap();

                // Check required properties exist
                for (prop_name, prop_schema) in props_obj {
                    if let Some(prop_schema_obj) = prop_schema.as_object() {
                        // Check if property is required (simplified check)
                        if let Some(required_props) = schema_obj.get("required") {
                            if let Some(required_array) = required_props.as_array() {
                                if required_array.iter().any(|v| v.as_str() == Some(prop_name)) {
                                    if !metadata_obj.contains_key(prop_name) {
                                        return Err(format!("Required property '{}' is missing", prop_name));
                                    }
                                }
                            }
                        }

                        // Basic type validation
                        if let Some(metadata_value) = metadata_obj.get(prop_name) {
                            if let Some(expected_type) = prop_schema_obj.get("type") {
                                if let Some(type_str) = expected_type.as_str() {
                                    let valid = match type_str {
                                        "string" => metadata_value.is_string(),
                                        "number" => metadata_value.is_number(),
                                        "integer" => metadata_value.is_number() && metadata_value.as_f64().map_or(false, |f| f.fract() == 0.0),
                                        "boolean" => metadata_value.is_boolean(),
                                        "array" => metadata_value.is_array(),
                                        "object" => metadata_value.is_object(),
                                        _ => true, // Allow unknown types
                                    };

                                    if !valid {
                                        return Err(format!("Property '{}' must be of type '{}'", prop_name, type_str));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Ok(())
}