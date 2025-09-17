use std::env;

#[derive(Clone)]
pub struct Config {
    pub database_url: String,
    pub jwt_secret: String,
    pub port: u16,
    pub host: String,
    pub environment: String,
}

impl Config {
    pub fn from_env() -> Result<Self, env::VarError> {
        Ok(Self {
            database_url: env::var("DATABASE_URL")?,
            jwt_secret: env::var("JWT_SECRET")?,
            port: env::var("PORT")
                .unwrap_or_else(|_| "3000".to_string())
                .parse()
                .expect("PORT must be a valid number"),
            host: env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string()),
            environment: env::var("ENVIRONMENT").unwrap_or_else(|_| "development".to_string()),
        })
    }

    pub fn is_production(&self) -> bool {
        self.environment == "production"
    }
}