use sqlx::PgPool;

use crate::auth::JwtService;

#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub jwt_service: JwtService,
}