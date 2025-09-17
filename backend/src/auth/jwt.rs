use anyhow::Result;
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use time::{Duration, OffsetDateTime};
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String, // User ID
    pub exp: i64,    // Expiration time
    pub iat: i64,    // Issued at
    pub token_type: TokenType,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum TokenType {
    Access,
    Refresh,
}

#[derive(Clone)]
pub struct JwtService {
    encoding_key: EncodingKey,
    decoding_key: DecodingKey,
}

impl JwtService {
    pub fn new(secret: &str) -> Self {
        Self {
            encoding_key: EncodingKey::from_secret(secret.as_ref()),
            decoding_key: DecodingKey::from_secret(secret.as_ref()),
        }
    }

    pub fn generate_access_token(&self, user_id: Uuid) -> Result<String> {
        let now = OffsetDateTime::now_utc();
        let expires_at = now + Duration::hours(24); // 24 hours

        let claims = Claims {
            sub: user_id.to_string(),
            exp: expires_at.unix_timestamp(),
            iat: now.unix_timestamp(),
            token_type: TokenType::Access,
        };

        encode(&Header::default(), &claims, &self.encoding_key)
            .map_err(|e| anyhow::anyhow!("Failed to generate access token: {}", e))
    }

    pub fn generate_refresh_token(&self, user_id: Uuid) -> Result<String> {
        let now = OffsetDateTime::now_utc();
        let expires_at = now + Duration::days(30); // 30 days

        let claims = Claims {
            sub: user_id.to_string(),
            exp: expires_at.unix_timestamp(),
            iat: now.unix_timestamp(),
            token_type: TokenType::Refresh,
        };

        encode(&Header::default(), &claims, &self.encoding_key)
            .map_err(|e| anyhow::anyhow!("Failed to generate refresh token: {}", e))
    }

    pub fn verify_token(&self, token: &str) -> Result<Claims> {
        let validation = Validation::new(Algorithm::HS256);
        let token_data = decode::<Claims>(token, &self.decoding_key, &validation)
            .map_err(|e| anyhow::anyhow!("Failed to verify token: {}", e))?;

        Ok(token_data.claims)
    }

    pub fn extract_user_id(&self, token: &str) -> Result<Uuid> {
        let claims = self.verify_token(token)?;
        Uuid::parse_str(&claims.sub)
            .map_err(|e| anyhow::anyhow!("Invalid user ID in token: {}", e))
    }
}