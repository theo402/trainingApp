use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::Json,
};
use serde::Deserialize;
use serde_json::{json, Value};
use uuid::Uuid;
use validator::Validate;

use crate::{
    middleware::auth::AuthUser,
    models::exercise_type::{
        CreateExerciseTypeRequest, ExerciseType, ExerciseTypeResponse, UpdateExerciseTypeRequest,
    },
    state::AppState,
};

#[derive(Debug, Deserialize)]
pub struct ExerciseTypeQuery {
    pub category: Option<String>,
    pub global_only: Option<bool>,
    pub user_only: Option<bool>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

pub async fn list_exercise_types(
    State(state): State<AppState>,
    auth_user: axum::Extension<AuthUser>,
    Query(params): Query<ExerciseTypeQuery>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let limit = params.limit.unwrap_or(50).min(100);
    let offset = params.offset.unwrap_or(0);

    // Use separate queries based on filters for simplicity
    let exercise_types = match (&params.category, params.global_only, params.user_only) {
        // Filter by category and global only
        (Some(category), Some(true), _) => {
            sqlx::query_as!(
                ExerciseType,
                "SELECT id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at
                 FROM exercise_types
                 WHERE deleted_at IS NULL AND is_global = true AND category = $1
                 ORDER BY name ASC
                 LIMIT $2 OFFSET $3",
                category,
                limit,
                offset
            ).fetch_all(&state.pool).await
        }
        // Filter by category and user only
        (Some(category), _, Some(true)) => {
            sqlx::query_as!(
                ExerciseType,
                "SELECT id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at
                 FROM exercise_types
                 WHERE deleted_at IS NULL AND is_global = false AND user_id = $1 AND category = $2
                 ORDER BY name ASC
                 LIMIT $3 OFFSET $4",
                auth_user.id,
                category,
                limit,
                offset
            ).fetch_all(&state.pool).await
        }
        // Filter by category (both global and user)
        (Some(category), _, _) => {
            sqlx::query_as!(
                ExerciseType,
                "SELECT id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at
                 FROM exercise_types
                 WHERE deleted_at IS NULL AND (is_global = true OR user_id = $1) AND category = $2
                 ORDER BY is_global DESC, name ASC
                 LIMIT $3 OFFSET $4",
                auth_user.id,
                category,
                limit,
                offset
            ).fetch_all(&state.pool).await
        }
        // Global only
        (None, Some(true), _) => {
            sqlx::query_as!(
                ExerciseType,
                "SELECT id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at
                 FROM exercise_types
                 WHERE deleted_at IS NULL AND is_global = true
                 ORDER BY name ASC
                 LIMIT $1 OFFSET $2",
                limit,
                offset
            ).fetch_all(&state.pool).await
        }
        // User only
        (None, _, Some(true)) => {
            sqlx::query_as!(
                ExerciseType,
                "SELECT id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at
                 FROM exercise_types
                 WHERE deleted_at IS NULL AND is_global = false AND user_id = $1
                 ORDER BY name ASC
                 LIMIT $2 OFFSET $3",
                auth_user.id,
                limit,
                offset
            ).fetch_all(&state.pool).await
        }
        // Default: both global and user's own
        _ => {
            sqlx::query_as!(
                ExerciseType,
                "SELECT id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at
                 FROM exercise_types
                 WHERE deleted_at IS NULL AND (is_global = true OR user_id = $1)
                 ORDER BY is_global DESC, name ASC
                 LIMIT $2 OFFSET $3",
                auth_user.id,
                limit,
                offset
            ).fetch_all(&state.pool).await
        }
    }.map_err(|e| {
        tracing::error!("Database error fetching exercise types: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let responses: Vec<ExerciseTypeResponse> = exercise_types
        .into_iter()
        .map(ExerciseTypeResponse::from)
        .collect();

    Ok(Json(json!({
        "exercise_types": responses,
        "pagination": {
            "limit": limit,
            "offset": offset,
            "count": responses.len()
        }
    })))
}

pub async fn get_exercise_type(
    State(state): State<AppState>,
    auth_user: axum::Extension<AuthUser>,
    Path(id): Path<Uuid>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    let exercise_type = sqlx::query_as!(
        ExerciseType,
        "SELECT id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at
         FROM exercise_types
         WHERE id = $1 AND deleted_at IS NULL AND (is_global = true OR user_id = $2)",
        id,
        auth_user.id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error fetching exercise type: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let exercise_type = exercise_type.ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(json!({"error": "Exercise type not found"})),
        )
    })?;

    Ok(Json(json!(ExerciseTypeResponse::from(exercise_type))))
}

pub async fn create_exercise_type(
    State(state): State<AppState>,
    auth_user: axum::Extension<AuthUser>,
    Json(payload): Json<CreateExerciseTypeRequest>,
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

    // Validate metadata schema if provided
    if let Some(ref schema) = payload.metadata_schema {
        if let Err(e) = validate_json_schema(schema) {
            return Err((
                StatusCode::BAD_REQUEST,
                Json(json!({
                    "error": "Invalid metadata schema",
                    "details": e
                })),
            ));
        }
    }

    // Check for duplicate name for this user
    let existing = sqlx::query!(
        "SELECT id FROM exercise_types WHERE name = $1 AND user_id = $2 AND deleted_at IS NULL",
        payload.name,
        auth_user.id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error checking existing exercise type: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    if existing.is_some() {
        return Err((
            StatusCode::CONFLICT,
            Json(json!({"error": "Exercise type with this name already exists"})),
        ));
    }

    let metadata_schema = payload.metadata_schema.unwrap_or_else(|| json!({}));

    let exercise_type = sqlx::query_as!(
        ExerciseType,
        r#"
        INSERT INTO exercise_types (name, description, category, metadata_schema, is_global, user_id)
        VALUES ($1, $2, $3, $4, false, $5)
        RETURNING id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at
        "#,
        payload.name,
        payload.description,
        payload.category,
        metadata_schema,
        auth_user.id
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error creating exercise type: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    Ok(Json(json!(ExerciseTypeResponse::from(exercise_type))))
}

pub async fn update_exercise_type(
    State(state): State<AppState>,
    auth_user: axum::Extension<AuthUser>,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateExerciseTypeRequest>,
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

    // Validate metadata schema if provided
    if let Some(ref schema) = payload.metadata_schema {
        if let Err(e) = validate_json_schema(schema) {
            return Err((
                StatusCode::BAD_REQUEST,
                Json(json!({
                    "error": "Invalid metadata schema",
                    "details": e
                })),
            ));
        }
    }

    // Check if exercise type exists and user owns it
    let existing = sqlx::query!(
        "SELECT id, is_global FROM exercise_types WHERE id = $1 AND deleted_at IS NULL",
        id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error fetching exercise type: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let existing = existing.ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(json!({"error": "Exercise type not found"})),
        )
    })?;

    // Only allow updating user's own exercise types (not global ones)
    if existing.is_global {
        return Err((
            StatusCode::FORBIDDEN,
            Json(json!({"error": "Cannot modify global exercise types"})),
        ));
    }

    // Check if any fields are provided
    if payload.name.is_none() && payload.description.is_none() && payload.category.is_none() && payload.metadata_schema.is_none() {
        return Err((
            StatusCode::BAD_REQUEST,
            Json(json!({"error": "No fields to update"})),
        ));
    }

    // For simplicity, we'll use individual update queries based on what fields are provided
    let exercise_type = if let Some(name) = payload.name {
        if let Some(description) = payload.description {
            if let Some(category) = payload.category {
                if let Some(metadata_schema) = payload.metadata_schema {
                    sqlx::query_as!(
                        ExerciseType,
                        "UPDATE exercise_types SET name = $2, description = $3, category = $4, metadata_schema = $5, updated_at = NOW()
                         WHERE id = $1 AND user_id = $6 AND deleted_at IS NULL
                         RETURNING id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at",
                        id, name, description, category, metadata_schema, auth_user.id
                    ).fetch_optional(&state.pool).await
                } else {
                    sqlx::query_as!(
                        ExerciseType,
                        "UPDATE exercise_types SET name = $2, description = $3, category = $4, updated_at = NOW()
                         WHERE id = $1 AND user_id = $5 AND deleted_at IS NULL
                         RETURNING id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at",
                        id, name, description, category, auth_user.id
                    ).fetch_optional(&state.pool).await
                }
            } else {
                sqlx::query_as!(
                    ExerciseType,
                    "UPDATE exercise_types SET name = $2, description = $3, updated_at = NOW()
                     WHERE id = $1 AND user_id = $4 AND deleted_at IS NULL
                     RETURNING id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at",
                    id, name, description, auth_user.id
                ).fetch_optional(&state.pool).await
            }
        } else {
            sqlx::query_as!(
                ExerciseType,
                "UPDATE exercise_types SET name = $2, updated_at = NOW()
                 WHERE id = $1 AND user_id = $3 AND deleted_at IS NULL
                 RETURNING id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at",
                id, name, auth_user.id
            ).fetch_optional(&state.pool).await
        }
    } else {
        // Fetch current record to return updated version
        sqlx::query_as!(
            ExerciseType,
            "SELECT id, name, description, category, metadata_schema, is_global, user_id, created_at, updated_at, deleted_at
             FROM exercise_types WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL",
            id, auth_user.id
        ).fetch_optional(&state.pool).await
    }.map_err(|e| {
        tracing::error!("Database error updating exercise type: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let exercise_type = exercise_type.ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(json!({"error": "Exercise type not found or you don't have permission to modify it"})),
        )
    })?;

    Ok(Json(json!(ExerciseTypeResponse::from(exercise_type))))
}

pub async fn delete_exercise_type(
    State(state): State<AppState>,
    auth_user: axum::Extension<AuthUser>,
    Path(id): Path<Uuid>,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    // Check if exercise type exists and user owns it
    let existing = sqlx::query!(
        "SELECT id, is_global FROM exercise_types WHERE id = $1 AND deleted_at IS NULL",
        id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error fetching exercise type: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let existing = existing.ok_or_else(|| {
        (
            StatusCode::NOT_FOUND,
            Json(json!({"error": "Exercise type not found"})),
        )
    })?;

    // Only allow deleting user's own exercise types (not global ones)
    if existing.is_global {
        return Err((
            StatusCode::FORBIDDEN,
            Json(json!({"error": "Cannot delete global exercise types"})),
        ));
    }

    // Soft delete the exercise type
    let deleted = sqlx::query!(
        "UPDATE exercise_types SET deleted_at = NOW() WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL",
        id,
        auth_user.id
    )
    .execute(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error deleting exercise type: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    if deleted.rows_affected() == 0 {
        return Err((
            StatusCode::NOT_FOUND,
            Json(json!({"error": "Exercise type not found or you don't have permission to delete it"})),
        ));
    }

    Ok(Json(json!({"message": "Exercise type deleted successfully"})))
}

// Helper function to validate JSON schema
fn validate_json_schema(schema: &serde_json::Value) -> Result<(), String> {
    // Basic validation - ensure it's an object with a "type" field
    if !schema.is_object() {
        return Err("Schema must be a JSON object".to_string());
    }

    let obj = schema.as_object().unwrap();

    // Check for required "type" field
    if !obj.contains_key("type") {
        return Err("Schema must have a 'type' field".to_string());
    }

    // Validate that type is "object"
    if let Some(type_val) = obj.get("type") {
        if type_val != "object" {
            return Err("Schema type must be 'object'".to_string());
        }
    }

    // Additional validation could be added here
    // For now, we'll accept any valid JSON object with type: "object"

    Ok(())
}