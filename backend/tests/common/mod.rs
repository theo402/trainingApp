use axum::Router;
use sqlx::{PgPool, Row};
use std::sync::Once;
use training_app_backend::{
    auth::JwtService,
    state::AppState,
};

static INIT: Once = Once::new();

pub struct TestApp {
    pub pool: PgPool,
    pub jwt_service: JwtService,
    pub app: Router,
}

impl TestApp {
    pub async fn new() -> Self {
        // Initialize tracing once
        INIT.call_once(|| {
            tracing_subscriber::fmt::init();
        });

        // Use test database
        let database_url = std::env::var("TEST_DATABASE_URL")
            .unwrap_or_else(|_| "postgresql://postgres@localhost/training_app_test".to_string());

        let pool = PgPool::connect(&database_url)
            .await
            .expect("Failed to connect to test database");

        // Check if tables exist, create if not
        let table_exists = sqlx::query("SELECT EXISTS(SELECT FROM information_schema.tables WHERE table_name = 'users')")
            .fetch_one(&pool)
            .await
            .ok();

        let needs_migration = if let Some(row) = table_exists {
            !row.get::<bool, _>(0)
        } else {
            true
        };

        if needs_migration {
            // Run migrations if tables don't exist
            let migration_sql = include_str!("../../migrations/001_initial_schema.sql");
            sqlx::raw_sql(migration_sql)
                .execute(&pool)
                .await
                .expect("Failed to run migrations");
        }

        // Clean database before each test (just data, not schema)
        Self::clean_database(&pool).await;

        let jwt_service = JwtService::new("test-secret-key");

        let state = AppState {
            pool: pool.clone(),
            jwt_service: jwt_service.clone(),
        };

        let app = training_app_backend::create_app(state);

        Self {
            pool,
            jwt_service,
            app,
        }
    }

    pub async fn clean_database(pool: &PgPool) {
        // Just truncate tables instead of dropping them to avoid schema conflicts
        let tables = vec!["sensor_timeseries", "exercises", "workouts", "exercise_types", "users"];

        for table in tables {
            sqlx::query(&format!("TRUNCATE TABLE {} CASCADE", table))
                .execute(pool)
                .await
                .ok(); // Ignore errors if table doesn't exist
        }
    }

    pub async fn create_test_user(&self) -> (uuid::Uuid, String) {
        let user_id = uuid::Uuid::new_v4();
        let email = format!("test-{}@example.com", user_id);
        self.create_test_user_with_email(&email).await
    }

    pub async fn create_test_user_with_email(&self, email: &str) -> (uuid::Uuid, String) {
        let user_id = uuid::Uuid::new_v4();
        let password_hash = training_app_backend::auth::PasswordService::hash_password("password123")
            .expect("Failed to hash password");

        sqlx::query!(
            "INSERT INTO users (id, email, password_hash) VALUES ($1, $2, $3)",
            user_id,
            email,
            password_hash
        )
        .execute(&self.pool)
        .await
        .expect("Failed to create test user");

        (user_id, email.to_string())
    }

    pub fn generate_test_token(&self, user_id: uuid::Uuid) -> String {
        self.jwt_service
            .generate_access_token(user_id)
            .expect("Failed to generate test token")
    }
}