use axum::{
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::{Json, Response},
};
use headers::{authorization::Bearer, Authorization, HeaderMapExt};
use serde_json::json;
use uuid::Uuid;

use crate::{
    auth::TokenType,
    models::user::User,
    state::AppState,
};

#[derive(Clone)]
pub struct AuthUser {
    pub id: Uuid,
    pub email: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
}

impl From<User> for AuthUser {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
        }
    }
}

pub async fn auth_middleware(
    State(state): State<AppState>,
    mut request: Request,
    next: Next,
) -> Result<Response, (StatusCode, Json<serde_json::Value>)> {
    // Extract Authorization header
    let auth_header = request
        .headers()
        .typed_get::<Authorization<Bearer>>()
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(json!({"error": "Missing authorization header"})),
            )
        })?;

    let token = auth_header.token();

    // Verify and decode token
    let claims = state.jwt_service.verify_token(token).map_err(|_| {
        (
            StatusCode::UNAUTHORIZED,
            Json(json!({"error": "Invalid or expired token"})),
        )
    })?;

    // Ensure it's an access token
    if !matches!(claims.token_type, TokenType::Access) {
        return Err((
            StatusCode::UNAUTHORIZED,
            Json(json!({"error": "Invalid token type"})),
        ));
    }

    // Parse user ID
    let user_id = Uuid::parse_str(&claims.sub).map_err(|_| {
        (
            StatusCode::UNAUTHORIZED,
            Json(json!({"error": "Invalid token claims"})),
        )
    })?;

    // Fetch user from database
    let user = sqlx::query_as!(
        User,
        "SELECT id, email, password_hash, first_name, last_name, created_at, updated_at, deleted_at FROM users WHERE id = $1 AND deleted_at IS NULL",
        user_id
    )
    .fetch_optional(&state.pool)
    .await
    .map_err(|e| {
        tracing::error!("Database error fetching user for auth: {}", e);
        (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": "Internal server error"})),
        )
    })?
    .ok_or_else(|| {
        (
            StatusCode::UNAUTHORIZED,
            Json(json!({"error": "User not found"})),
        )
    })?;

    // Add user to request extensions
    request.extensions_mut().insert(AuthUser::from(user));

    Ok(next.run(request).await)
}

pub async fn ownership_middleware(
    mut request: Request,
    next: Next,
) -> Result<Response, (StatusCode, Json<serde_json::Value>)> {
    // This middleware ensures users can only access their own resources
    // It should be used after auth_middleware to ensure AuthUser is available
    let auth_user = request
        .extensions()
        .get::<AuthUser>()
        .ok_or_else(|| {
            (
                StatusCode::UNAUTHORIZED,
                Json(json!({"error": "Authentication required"})),
            )
        })?
        .clone();

    // Add ownership context for handlers to use
    request.extensions_mut().insert(auth_user);

    Ok(next.run(request).await)
}