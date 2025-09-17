mod common;

use axum_test::TestServer;
use serde_json::json;
use common::TestApp;

#[tokio::test]
async fn test_create_exercise() {
    let test_app = TestApp::new().await;

    // Seed exercise types
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Get an exercise type to use
    let exercise_types_response = server
        .get("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    exercise_types_response.assert_status_ok();
    let exercise_types_body: serde_json::Value = exercise_types_response.json();
    let exercise_types = exercise_types_body["exercise_types"].as_array().unwrap();
    assert!(!exercise_types.is_empty());

    let exercise_type_id = exercise_types[0]["id"].as_str().unwrap();

    // Create an exercise with appropriate metadata for the exercise type
    let request_body = json!({
        "exercise_type_id": exercise_type_id,
        "name": "Test Exercise",
        "notes": "Felt good today",
        "metadata": {
            "sets": 3,
            "reps": 10
        }
    });

    let response = server
        .post("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert_eq!(body["name"], "Test Exercise");
    assert_eq!(body["notes"], "Felt good today");
    assert_eq!(body["exercise_type_id"], exercise_type_id);
    assert!(body["id"].is_string());
    assert_eq!(body["metadata"]["sets"], 3);
    assert_eq!(body["metadata"]["reps"], 10);
}

#[tokio::test]
async fn test_create_exercise_with_workout() {
    let test_app = TestApp::new().await;

    // Seed exercise types
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Create a workout first (we'll need to create this endpoint)
    // For now, let's test without workout_id
    let exercise_types_response = server
        .get("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    let exercise_types_body: serde_json::Value = exercise_types_response.json();
    let exercise_types = exercise_types_body["exercise_types"].as_array().unwrap();
    let exercise_type_id = exercise_types[0]["id"].as_str().unwrap();

    let request_body = json!({
        "exercise_type_id": exercise_type_id,
        "name": "Test Exercise",
        "metadata": {
            "sets": 3,
            "reps": 10
        }
    });

    let response = server
        .post("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    response.assert_status_ok();
}

#[tokio::test]
async fn test_create_exercise_invalid_exercise_type() {
    let test_app = TestApp::new().await;

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Try to create exercise with non-existent exercise type
    let request_body = json!({
        "exercise_type_id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Test Exercise"
    });

    let response = server
        .post("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    response.assert_status(axum::http::StatusCode::BAD_REQUEST);

    let body: serde_json::Value = response.json();
    assert!(body["error"].as_str().unwrap().contains("not found or not accessible"));
}

#[tokio::test]
async fn test_list_exercises() {
    let test_app = TestApp::new().await;

    // Seed exercise types
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Get exercise types
    let exercise_types_response = server
        .get("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    let exercise_types_body: serde_json::Value = exercise_types_response.json();
    let exercise_types = exercise_types_body["exercise_types"].as_array().unwrap();
    let exercise_type_id = exercise_types[0]["id"].as_str().unwrap();

    // Create some exercises
    for i in 1..=3 {
        let request_body = json!({
            "exercise_type_id": exercise_type_id,
            "name": format!("Exercise {}", i),
            "metadata": {
                "sets": 3,
                "reps": 10
            }
        });

        server
            .post("/api/exercises")
            .add_header("Authorization", format!("Bearer {}", token))
            .json(&request_body)
            .await
            .assert_status_ok();
    }

    // List exercises
    let response = server
        .get("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    let exercises = body["exercises"].as_array().unwrap();
    assert_eq!(exercises.len(), 3);
}

#[tokio::test]
async fn test_filter_exercises_by_exercise_type() {
    let test_app = TestApp::new().await;

    // Seed exercise types
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Get exercise types
    let exercise_types_response = server
        .get("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    let exercise_types_body: serde_json::Value = exercise_types_response.json();
    let exercise_types = exercise_types_body["exercise_types"].as_array().unwrap();

    // Take two different exercise types
    let exercise_type_1_id = exercise_types[0]["id"].as_str().unwrap();
    let exercise_type_2_id = exercise_types[1]["id"].as_str().unwrap();

    // Create exercises with different types
    let request_body_1 = json!({
        "exercise_type_id": exercise_type_1_id,
        "name": "Type 1 Exercise",
        "metadata": {
            "sets": 3,
            "reps": 10
        }
    });

    let request_body_2 = json!({
        "exercise_type_id": exercise_type_2_id,
        "name": "Type 2 Exercise",
        "metadata": {
            "sets": 3,
            "reps": 10
        }
    });

    server
        .post("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body_1)
        .await
        .assert_status_ok();

    server
        .post("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body_2)
        .await
        .assert_status_ok();

    // Filter by first exercise type
    let response = server
        .get(&format!("/api/exercises?exercise_type_id={}", exercise_type_1_id))
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    let exercises = body["exercises"].as_array().unwrap();
    assert_eq!(exercises.len(), 1);
    assert_eq!(exercises[0]["exercise_type_id"], exercise_type_1_id);
}

#[tokio::test]
async fn test_filter_exercises_by_category() {
    let test_app = TestApp::new().await;

    // Seed exercise types
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Get exercise types
    let exercise_types_response = server
        .get("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    let exercise_types_body: serde_json::Value = exercise_types_response.json();
    let exercise_types = exercise_types_body["exercise_types"].as_array().unwrap();

    // Find a cardio exercise type
    let cardio_exercise_type = exercise_types
        .iter()
        .find(|et| et["category"] == "Cardio")
        .expect("Should have cardio exercise type");

    let cardio_type_id = cardio_exercise_type["id"].as_str().unwrap();

    // Create a cardio exercise
    let request_body = json!({
        "exercise_type_id": cardio_type_id,
        "name": "Cardio Exercise",
        "metadata": {
            "distance": 5.0,
            "distance_unit": "km",
            "duration_minutes": 30.0
        }
    });

    server
        .post("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await
        .assert_status_ok();

    // Filter by cardio category
    let response = server
        .get("/api/exercises?category=Cardio")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    let exercises = body["exercises"].as_array().unwrap();
    assert!(!exercises.is_empty());

    // All returned exercises should be cardio
    for exercise in exercises {
        assert_eq!(exercise["exercise_type_category"], "Cardio");
    }
}

#[tokio::test]
async fn test_get_exercise() {
    let test_app = TestApp::new().await;

    // Seed exercise types
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Get exercise types and create an exercise
    let exercise_types_response = server
        .get("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    let exercise_types_body: serde_json::Value = exercise_types_response.json();
    let exercise_types = exercise_types_body["exercise_types"].as_array().unwrap();
    let exercise_type_id = exercise_types[0]["id"].as_str().unwrap();

    let request_body = json!({
        "exercise_type_id": exercise_type_id,
        "name": "Test Exercise",
        "notes": "Test notes",
        "metadata": {
            "sets": 3,
            "reps": 10
        }
    });

    let create_response = server
        .post("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    create_response.assert_status_ok();
    let created: serde_json::Value = create_response.json();
    let exercise_id = created["id"].as_str().unwrap();

    // Get the exercise
    let response = server
        .get(&format!("/api/exercises/{}", exercise_id))
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert_eq!(body["id"], exercise_id);
    assert_eq!(body["name"], "Test Exercise");
    assert_eq!(body["notes"], "Test notes");
    assert_eq!(body["metadata"]["sets"], 3);
    assert_eq!(body["metadata"]["reps"], 10);
}

#[tokio::test]
async fn test_update_exercise() {
    let test_app = TestApp::new().await;

    // Seed exercise types
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Get exercise types and create an exercise
    let exercise_types_response = server
        .get("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    let exercise_types_body: serde_json::Value = exercise_types_response.json();
    let exercise_types = exercise_types_body["exercise_types"].as_array().unwrap();
    let exercise_type_id = exercise_types[0]["id"].as_str().unwrap();

    let request_body = json!({
        "exercise_type_id": exercise_type_id,
        "name": "Original Exercise",
        "metadata": {
            "sets": 3,
            "reps": 10
        }
    });

    let create_response = server
        .post("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    create_response.assert_status_ok();
    let created: serde_json::Value = create_response.json();
    let exercise_id = created["id"].as_str().unwrap();

    // Update the exercise
    let update_body = json!({
        "name": "Updated Exercise",
        "notes": "Updated notes",
        "metadata": {"sets": 4, "reps": 12}
    });

    let response = server
        .patch(&format!("/api/exercises/{}", exercise_id))
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&update_body)
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert_eq!(body["name"], "Updated Exercise");
    assert_eq!(body["notes"], "Updated notes");
    assert_eq!(body["metadata"]["sets"], 4);
    assert_eq!(body["metadata"]["reps"], 12);
}

#[tokio::test]
async fn test_delete_exercise() {
    let test_app = TestApp::new().await;

    // Seed exercise types
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Get exercise types and create an exercise
    let exercise_types_response = server
        .get("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    let exercise_types_body: serde_json::Value = exercise_types_response.json();
    let exercise_types = exercise_types_body["exercise_types"].as_array().unwrap();
    let exercise_type_id = exercise_types[0]["id"].as_str().unwrap();

    let request_body = json!({
        "exercise_type_id": exercise_type_id,
        "name": "Exercise To Delete",
        "metadata": {
            "sets": 3,
            "reps": 10
        }
    });

    let create_response = server
        .post("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    create_response.assert_status_ok();
    let created: serde_json::Value = create_response.json();
    let exercise_id = created["id"].as_str().unwrap();

    // Delete the exercise
    let response = server
        .delete(&format!("/api/exercises/{}", exercise_id))
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    response.assert_status_ok();

    let body: serde_json::Value = response.json();
    assert!(body["message"].as_str().unwrap().contains("deleted successfully"));

    // Verify it's no longer accessible
    let get_response = server
        .get(&format!("/api/exercises/{}", exercise_id))
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    get_response.assert_status(axum::http::StatusCode::NOT_FOUND);
}

#[tokio::test]
async fn test_exercise_metadata_validation() {
    let test_app = TestApp::new().await;

    // Seed exercise types
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create test user and get token
    let (user_id, _email) = test_app.create_test_user().await;
    let token = test_app.generate_test_token(user_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Get a strength exercise type (which should have schema requiring sets/reps)
    let exercise_types_response = server
        .get("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token))
        .await;

    let exercise_types_body: serde_json::Value = exercise_types_response.json();
    let exercise_types = exercise_types_body["exercise_types"].as_array().unwrap();

    // Find a strength exercise type
    let strength_exercise_type = exercise_types
        .iter()
        .find(|et| et["category"] == "Chest" || et["category"] == "Legs" || et["category"] == "Back")
        .expect("Should have strength exercise type");

    let strength_type_id = strength_exercise_type["id"].as_str().unwrap();

    // Try to create exercise with invalid metadata (string instead of number for sets)
    let request_body = json!({
        "exercise_type_id": strength_type_id,
        "name": "Invalid Exercise",
        "metadata": {
            "sets": "three", // Should be a number
            "reps": 10
        }
    });

    let response = server
        .post("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token))
        .json(&request_body)
        .await;

    response.assert_status(axum::http::StatusCode::BAD_REQUEST);

    let body: serde_json::Value = response.json();
    assert!(body["error"].as_str().unwrap().contains("Invalid metadata"));
}

#[tokio::test]
async fn test_unauthorized_access_exercises() {
    let test_app = TestApp::new().await;
    let server = TestServer::new(test_app.app).unwrap();

    // Try to access without token
    let response = server
        .get("/api/exercises")
        .await;

    response.assert_status(axum::http::StatusCode::UNAUTHORIZED);

    // Try to create without token
    let request_body = json!({
        "exercise_type_id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "Unauthorized Exercise"
    });

    let response = server
        .post("/api/exercises")
        .json(&request_body)
        .await;

    response.assert_status(axum::http::StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn test_user_isolation_exercises() {
    let test_app = TestApp::new().await;

    // Seed exercise types
    training_app_backend::seeding::seed_global_exercise_types(&test_app.pool)
        .await
        .expect("Failed to seed global exercise types");

    // Create two test users
    let (user1_id, _) = test_app.create_test_user().await;
    let (user2_id, _) = test_app.create_test_user_with_email("user2@test.com").await;

    let token1 = test_app.generate_test_token(user1_id);
    let token2 = test_app.generate_test_token(user2_id);

    let server = TestServer::new(test_app.app).unwrap();

    // Get exercise types
    let exercise_types_response = server
        .get("/api/exercise-types")
        .add_header("Authorization", format!("Bearer {}", token1))
        .await;

    let exercise_types_body: serde_json::Value = exercise_types_response.json();
    let exercise_types = exercise_types_body["exercise_types"].as_array().unwrap();
    let exercise_type_id = exercise_types[0]["id"].as_str().unwrap();

    // User 1 creates an exercise
    let request_body = json!({
        "exercise_type_id": exercise_type_id,
        "name": "User 1 Exercise",
        "metadata": {
            "sets": 3,
            "reps": 10
        }
    });

    let create_response = server
        .post("/api/exercises")
        .add_header("Authorization", format!("Bearer {}", token1))
        .json(&request_body)
        .await;

    create_response.assert_status_ok();
    let created: serde_json::Value = create_response.json();
    let exercise_id = created["id"].as_str().unwrap();

    // User 2 tries to access User 1's exercise
    let response = server
        .get(&format!("/api/exercises/{}", exercise_id))
        .add_header("Authorization", format!("Bearer {}", token2))
        .await;

    response.assert_status(axum::http::StatusCode::NOT_FOUND);

    // User 2 tries to update User 1's exercise
    let update_body = json!({
        "name": "Hacked Exercise"
    });

    let response = server
        .patch(&format!("/api/exercises/{}", exercise_id))
        .add_header("Authorization", format!("Bearer {}", token2))
        .json(&update_body)
        .await;

    response.assert_status(axum::http::StatusCode::NOT_FOUND);

    // User 2 tries to delete User 1's exercise
    let response = server
        .delete(&format!("/api/exercises/{}", exercise_id))
        .add_header("Authorization", format!("Bearer {}", token2))
        .await;

    response.assert_status(axum::http::StatusCode::NOT_FOUND);
}