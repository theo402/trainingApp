mod common;

use axum_test::TestServer;
use serde_json::json;
use common::TestApp;

#[tokio::test]
async fn test_list_exercise_types_includes_global() {
    let test_app = TestApp::new().await;

    // Seed some global exercise types
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    let response = server
        .get("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    let exercise_types = &body["exercise_types"];
    assert!(exercise_types.is_array());

    let exercise_types_array = exercise_types.as_array().unwrap();
    assert!(!exercise_types_array.is_empty());

    // Check that we have global exercise types
    let has_global = exercise_types_array
        .iter()
        .any(|et| et["is_global"].as_bool().unwrap_or(false));
    assert!(has_global, "Should include global exercise types");
}

#[tokio::test]
async fn test_create_custom_exercise_type() {
    let test_app = TestApp::new().await;

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    let request_body = json!({
        "name": "Custom Strength Exercise",
        "description": "My custom exercise",
        "category": "Custom",
        "metadata_schema": {
            "type": "object",
            "properties": {
                "sets": {"type": "integer", "minimum": 1},
                "reps": {"type": "integer", "minimum": 1}
            }
        }
    });

    let response = server
        .post("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert_eq!(body["name"], "Custom Strength Exercise");
    assert_eq!(body["description"], "My custom exercise");
    assert_eq!(body["category"], "Custom");
    assert_eq!(body["is_global"], false);
    assert!(body["id"].is_string());
}

#[tokio::test]
async fn test_create_exercise_type_validation() {
    let test_app = TestApp::new().await;

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Test empty name
    let request_body = json!({
        "name": "",
        "description": "Test"
    });

    let response = server
        .post("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    response.assert_status(axum::http::StatusCode::BAD_REQUEST);

    let body: serde_json::Value = response.json();
    assert_eq!(body["error"], "Validation failed");
}

#[tokio::test]
async fn test_create_exercise_type_duplicate_name() {
    let test_app = TestApp::new().await;

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    let request_body = json!({
        "name": "Duplicate Exercise",
        "description": "First exercise"
    });

    // First creation should succeed
    let response = server
        .post("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    response.assert_status_ok();

    // Second creation with same name should fail
    let response = server
        .post("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    response.assert_status(axum::http::StatusCode::CONFLICT);

    let body: serde_json::Value = response.json();
    assert!(body["error"].as_str().unwrap().contains("already exists"));
}

#[tokio::test]
async fn test_get_exercise_type() {
    let test_app = TestApp::new().await;

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Create an exercise type first
    let request_body = json!({
        "name": "Test Exercise",
        "description": "Test description",
        "category": "Test"
    });

    let create_response = server
        .post("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    create_response.assert_status_ok();
    let created: serde_json::Value = create_response.json();
    let exercise_type_id = created["id"].as_str().unwrap();

    // Now get the exercise type
    let response = server
        .get(&format!("/api/exercise-types/{}", exercise_type_id))
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert_eq!(body["name"], "Test Exercise");
    assert_eq!(body["description"], "Test description");
    assert_eq!(body["category"], "Test");
}

#[tokio::test]
async fn test_update_exercise_type() {
    let test_app = TestApp::new().await;

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Create an exercise type first
    let request_body = json!({
        "name": "Original Exercise",
        "description": "Original description"
    });

    let create_response = server
        .post("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    create_response.assert_status_ok();
    let created: serde_json::Value = create_response.json();
    let exercise_type_id = created["id"].as_str().unwrap();

    // Update the exercise type
    let update_body = json!({
        "name": "Updated Exercise",
        "description": "Updated description"
    });

    let response = server
        .patch(&format!("/api/exercise-types/{}", exercise_type_id))
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&update_body)
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert_eq!(body["name"], "Updated Exercise");
    assert_eq!(body["description"], "Updated description");
}

#[tokio::test]
async fn test_cannot_update_global_exercise_type() {
    let test_app = TestApp::new().await;

    // Seed global exercise types first
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Get a global exercise type
    let list_response = server
        .get("/api/exercise-types?global_only=true")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    list_response.assert_status_ok();
    let list_body: serde_json::Value = list_response.json();
    let global_exercise_types = list_body["exercise_types"].as_array().unwrap();

    if !global_exercise_types.is_empty() {
        let global_id = global_exercise_types[0]["id"].as_str().unwrap();

        // Try to update the global exercise type
        let update_body = json!({
            "name": "Hacked Global Exercise"
        });

        let response = server
            .patch(&format!("/api/exercise-types/{}", global_id))
            .add_header("Authorization", format!("Bearer {}", token))
            .json(&update_body)
            .await;

        response.assert_status(axum::http::StatusCode::FORBIDDEN);

        let body: serde_json::Value = response.json();
        assert!(body["error"].as_str().unwrap().contains("Cannot modify global"));
    }
}

#[tokio::test]
async fn test_delete_exercise_type() {
    let test_app = TestApp::new().await;

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Create an exercise type first
    let request_body = json!({
        "name": "Exercise To Delete",
        "description": "Will be deleted"
    });

    let create_response = server
        .post("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    create_response.assert_status_ok();
    let created: serde_json::Value = create_response.json();
    let exercise_type_id = created["id"].as_str().unwrap();

    // Delete the exercise type
    let response = server
        .delete(&format!("/api/exercise-types/{}", exercise_type_id))
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert!(body["message"].as_str().unwrap().contains("deleted successfully"));

    // Verify it's no longer accessible
    let get_response = server
        .get(&format!("/api/exercise-types/{}", exercise_type_id))
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    get_response.assert_status(axum::http::StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn test_filter_by_category() {
    let test_app = TestApp::new().await;

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Create exercise types in different categories
    let cardio_body = json!({
        "name": "Test Cardio",
        "category": "Cardio"
    });

    let strength_body = json!({
        "name": "Test Strength",
        "category": "Strength"
    });

    server
        .post("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&cardio_body)
        .await
        .assert_status_ok();

    server
        .post("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&strength_body)
        .await
        .assert_status_ok();

    // Filter by Cardio category
    let response = server
        .get("/api/exercise-types?category=Cardio")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    let exercise_types = body["exercise_types"].as_array().unwrap();

    // All returned exercise types should be in Cardio category
    for exercise_type in exercise_types {
        let category = exercise_type["category"].as_str();
        if let Some(cat) = category {
            assert_eq!(cat, "Cardio");
        }
    }
}

#[tokio::test]
async fn test_user_only_filter() {
    let test_app = TestApp::new().await;

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Create a user exercise type
    let request_body = json!({
        "name": "User Exercise",
        "description": "User only exercise"
    });

    server
        .post("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await
        .assert_status_ok();

    // Filter by user only
    let response = server
        .get("/api/exercise-types?user_only=true")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    let exercise_types = body["exercise_types"].as_array().unwrap();

    // All returned exercise types should be user-created (not global)
    for exercise_type in exercise_types {
        assert_eq!(exercise_type["is_global"], false);
    }
}

#[tokio::test]
async fn test_unauthorized_access() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    // Try to access without token
    let response = server
        .get("/api/exercise-types")
        .await;

    response.assert_status(axum::http::StatusCode::UNAUTHORIZED);

    // Try to create without token
    let request_body = json!({
        "name": "Unauthorized Exercise"
    });

    let response = server
        .post("/api/exercise-types")
        .json(&request_body)
        .await;

    response.assert_status(axum::http::StatusCode::UNAUTHORIZED);
}