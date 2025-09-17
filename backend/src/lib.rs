use axum::{
    routing::{delete, get, patch, post},
    Router,
    response::Json,
};
use serde_json::{json, Value};
use tower_http::cors::CorsLayer;

pub mod auth;
pub mod config;
pub mod handlers;
pub mod middleware;
pub mod models;
pub mod seeding;
pub mod state;

use handlers::auth::{login, register};
use handlers::exercise_types::{
    create_exercise_type, delete_exercise_type, get_exercise_type, list_exercise_types,
    update_exercise_type,
};
use handlers::exercises::{
    create_exercise, delete_exercise, get_exercise, list_exercises, update_exercise,
};
use middleware::auth::auth_middleware;
use state::AppState;

pub fn create_app(state: AppState) -> Router {
    // Protected routes (require authentication)
    let protected_routes = Router::new()
        .route("/profile", get(get_profile))
        .route("/exercise-types", get(list_exercise_types))
        .route("/exercise-types", post(create_exercise_type))
        .route("/exercise-types/:id", get(get_exercise_type))
        .route("/exercise-types/:id", patch(update_exercise_type))
        .route("/exercise-types/:id", delete(delete_exercise_type))
        .route("/exercises", get(list_exercises))
        .route("/exercises", post(create_exercise))
        .route("/exercises/:id", get(get_exercise))
        .route("/exercises/:id", patch(update_exercise))
        .route("/exercises/:id", delete(delete_exercise))
        .layer(axum::middleware::from_fn_with_state(
            state.clone(),
            auth_middleware,
        ));

    // Public routes
    let public_routes = Router::new()
        .route("/", get(root))
        .route("/health", get(health_check))
        .route("/auth/register", post(register))
        .route("/auth/login", post(login));

    // Build application with routes
    Router::new()
        .nest("/api", public_routes.merge(protected_routes))
        .with_state(state)
        .layer(CorsLayer::permissive())
}

async fn root() -> Json<Value> {
    Json(json!({
        "message": "Training App Backend API",
        "version": "0.1.0"
    }))
}

async fn health_check() -> Json<Value> {
    Json(json!({
        "status": "healthy"
    }))
}

async fn get_profile(
    auth_user: axum::Extension<middleware::auth::AuthUser>,
) -> Json<Value> {
    Json(json!({
        "user": {
            "id": auth_user.id,
            "email": auth_user.email,
            "first_name": auth_user.first_name,
            "last_name": auth_user.last_name
        }
    }))
}