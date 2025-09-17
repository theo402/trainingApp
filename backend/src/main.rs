use sqlx::PgPool;
use std::net::SocketAddr;
use tower_http::set_header::SetResponseHeaderLayer;
use tracing_subscriber;

use training_app_backend::{
    auth::JwtService,
    config::Config,
    create_app,
    state::AppState,
};

#[tokio::main]
async fn main() {
    // Load environment variables
    dotenvy::dotenv().ok();

    // Initialize tracing
    tracing_subscriber::fmt::init();

    // Setup database connection
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");

    let pool = PgPool::connect(&database_url)
        .await
        .expect("Failed to connect to database");

    // Setup JWT service
    let jwt_secret = std::env::var("JWT_SECRET")
        .expect("JWT_SECRET must be set");
    let jwt_service = JwtService::new(&jwt_secret);

    // Create shared state
    let state = AppState {
        pool,
        jwt_service: jwt_service.clone(),
    };

    // Load configuration
    let config = Config::from_env()
        .expect("Failed to load configuration");

    // Create application
    let mut app = create_app(state);

    // Add HTTPS enforcement in production
    if config.is_production() {
        use axum::http::HeaderValue;
        app = app.layer(SetResponseHeaderLayer::overriding(
            axum::http::header::STRICT_TRANSPORT_SECURITY,
            HeaderValue::from_static("max-age=31536000; includeSubDomains; preload"),
        ));
    }

    let addr = SocketAddr::from(([127, 0, 0, 1], config.port));
    tracing::info!("Server running on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
