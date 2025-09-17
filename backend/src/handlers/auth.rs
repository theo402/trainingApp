use axum::{
    extract::State,
    http::StatusCode,
    response::Json,
};
use serde_json::{json, Value};
use validator::Validate;

use crate::{
    auth::PasswordService,
    models::user::{AuthResponse, CreateUserRequest, LoginRequest, User, UserResponse},
    state::AppState,
};

pub async fn register(
    State(state): State<AppState>,
    Json(payload): Json<CreateUserRequest>,
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

    // Check if user already exists
    let existing_user = sqlx::query!("SELECT id FROM users WHERE email = $1 AND deleted_at IS NULL", payload.email)
        .fetch_optional(&state.pool)
        .await
        .map_err(|e| {
            tracing::error!("Database error checking existing user: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Internal server error"})),
            )
        })?;

    if existing_user.is_some() {
        return Err((
            StatusCode::CONFLICT,
            Json(json!({"error": "User with this email already exists"})),
        ));
    }

    // Hash password
    let password_hash = PasswordService::hash_password(&payload.password)
        .map_err(|e| {
            tracing::error!("Failed to hash password: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Internal server error"})),
            )
        })?;

    // Create user
    let user = sqlx::query_as!(
        User,
        r#"
        INSERT INTO users (email, password_hash, first_name, last_name)
        VALUES ($1, $2, $3, $4)
        RETURNING id, email, password_hash, first_name, last_name, created_at, updated_at, deleted_at
        "#,
        payload.email,
        password_hash,
        payload.first_name,
        payload.last_name
    )
    .fetch_one(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error creating user: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    // Generate tokens
    let access_token = state.jwt_service.generate_access_token(user.id)
        .map_err(|e| {
            tracing::error!("Failed to generate access token: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Internal server error"})),
            )
        })?;

    let refresh_token = state.jwt_service.generate_refresh_token(user.id)
        .map_err(|e| {
            tracing::error!("Failed to generate refresh token: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Internal server error"})),
            )
        })?;

    let response = AuthResponse {
        user: UserResponse::from(user),
        access_token,
        refresh_token,
    };

    Ok(Json(json!(response)))
}

pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
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

    // Get user by email
    let user = sqlx::query_as!(
        User,
        "SELECT id, email, password_hash, first_name, last_name, created_at, updated_at, deleted_at FROM users WHERE email = $1 AND deleted_at IS NULL",
        payload.email
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error fetching user: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?;

    let user = user.ok_or_else(|| {
        (
            StatusCode::UNAUTHORIZED,
            Json(json!({"error": "Invalid email or password"})),
        )
    })?;

    // Verify password
    let is_valid = PasswordService::verify_password(&payload.password, &user.password_hash)
        .map_err(|e| {
            tracing::error!("Failed to verify password: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Internal server error"})),
            )
        })?;

    if !is_valid {
        return Err((
            StatusCode::UNAUTHORIZED,
            Json(json!({"error": "Invalid email or password"})),
        ));
    }

    // Generate tokens
    let access_token = state.jwt_service.generate_access_token(user.id)
        .map_err(|e| {
            tracing::error!("Failed to generate access token: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Internal server error"})),
            )
        })?;

    let refresh_token = state.jwt_service.generate_refresh_token(user.id)
        .map_err(|e| {
            tracing::error!("Failed to generate refresh token: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Internal server error"})),
            )
        })?;

    let response = AuthResponse {
        user: UserResponse::from(user),
        access_token,
        refresh_token,
    };

    Ok(Json(json!(response)))
}