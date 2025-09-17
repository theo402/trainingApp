mod common;

use axum_test::TestServer;
use serde_json::json;
use common::TestApp;

#[tokio::test]
async fn test_user_registration_success() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    let request_body = json!({
        "email": "test@example.com",
        "password": "password123",
        "first_name": "Test",
        "last_name": "User"
    });

    let response = server
        .post("/api/auth/register")
        .json(&request_body)
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert!(body.get("user").is_some());
    assert!(body.get("access_token").is_some());
    assert!(body.get("refresh_token").is_some());

    let user = &body["user"];
    assert_eq!(user["email"], "test@example.com");
    assert_eq!(user["first_name"], "Test");
    assert_eq!(user["last_name"], "User");
}

#[tokio::test]
async fn test_user_registration_duplicate_email() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    let request_body = json!({
        "email": "duplicate@example.com",
        "password": "password123"
    });

    // First registration should succeed
    let response = server
        .post("/api/auth/register")
        .json(&request_body)
        .await;
    response.assert_status_ok();

    // Second registration with same email should fail
    let response = server
        .post("/api/auth/register")
        .json(&request_body)
        .await;

    response.assert_status(axum::http::StatusCode::CONFLICT);

    let body: serde_json::Value = response.json();
    assert!(body["error"].as_str().unwrap().contains("already exists"));
}

#[tokio::test]
async fn test_user_registration_invalid_email() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    let request_body = json!({
        "email": "invalid-email",
        "password": "password123"
    });

    let response = server
        .post("/api/auth/register")
        .json(&request_body)
        .await;

    response.assert_status(axum::http::StatusCode::BAD_REQUEST);

    let body: serde_json::Value = response.json();
    assert_eq!(body["error"], "Validation failed");
}

#[tokio::test]
async fn test_user_registration_short_password() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    let request_body = json!({
        "email": "test@example.com",
        "password": "123" // Too short
    });

    let response = server
        .post("/api/auth/register")
        .json(&request_body)
        .await;

    response.assert_status(axum::http::StatusCode::BAD_REQUEST);

    let body: serde_json::Value = response.json();
    assert_eq!(body["error"], "Validation failed");
}

#[tokio::test]
async fn test_user_login_success() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    // First register a user
    let register_body = json!({
        "email": "login@example.com",
        "password": "password123"
    });

    server
        .post("/api/auth/register")
        .json(&register_body)
        .await
        .assert_status_ok();

    // Now login
    let login_body = json!({
        "email": "login@example.com",
        "password": "password123"
    });

    let response = server
        .post("/api/auth/login")
        .json(&login_body)
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert!(body.get("user").is_some());
    assert!(body.get("access_token").is_some());
    assert!(body.get("refresh_token").is_some());

    let user = &body["user"];
    assert_eq!(user["email"], "login@example.com");
}

#[tokio::test]
async fn test_user_login_invalid_credentials() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    let login_body = json!({
        "email": "nonexistent@example.com",
        "password": "password123"
    });

    let response = server
        .post("/api/auth/login")
        .json(&login_body)
        .await;

    response.assert_status(axum::http::StatusCode::UNAUTHORIZED);

    let body: serde_json::Value = response.json();
    assert!(body["error"].as_str().unwrap().contains("Invalid email or password"));
}

#[tokio::test]
async fn test_user_login_wrong_password() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    // Register a user
    let register_body = json!({
        "email": "wrongpass@example.com",
        "password": "password123"
    });

    server
        .post("/api/auth/register")
        .json(&register_body)
        .await
        .assert_status_ok();

    // Try to login with wrong password
    let login_body = json!({
        "email": "wrongpass@example.com",
        "password": "wrongpassword"
    });

    let response = server
        .post("/api/auth/login")
        .json(&login_body)
        .await;

    response.assert_status(axum::http::StatusCode::UNAUTHORIZED);

    let body: serde_json::Value = response.json();
    assert!(body["error"].as_str().unwrap().contains("Invalid email or password"));
}

#[tokio::test]
async fn test_profile_endpoint_with_valid_token() {
    let test_app = TestApp::new().await;

    // Create test user and get token first
    let (user_id, email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    let response = server
        .get("/api/profile")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    let user_data = &body["user"];
    assert_eq!(user_data["id"], user_id.to_string());
    assert_eq!(user_data["email"], email);
}

#[tokio::test]
async fn test_profile_endpoint_without_token() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    let response = server
        .get("/api/profile")
        .await;

    response.assert_status(axum::http::StatusCode::UNAUTHORIZED);

    let body: serde_json::Value = response.json();
    assert!(body["error"].as_str().unwrap().contains("Missing authorization header"));
}

#[tokio::test]
async fn test_profile_endpoint_with_invalid_token() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    let response = server
        .get("/api/profile")
        .add_header("Authorization", "Bearer invalid-token")
        .await;

    response.assert_status(axum::http::StatusCode::UNAUTHORIZED);

    let body: serde_json::Value = response.json();
    assert!(body["error"].as_str().unwrap().contains("Invalid or expired token"));
}

#[tokio::test]
async fn test_health_endpoint() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    let response = server
        .get("/api/health")
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert_eq!(body["status"], "healthy");
}

#[tokio::test]
async fn test_root_endpoint() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    let response = server
        .get("/api")
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert_eq!(body["message"], "Training App Backend API");
    assert_eq!(body["version"], "0.1.0");
}