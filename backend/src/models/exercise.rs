use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Exercise {
    pub id: Uuid,
    pub user_id: Uuid,
    pub exercise_type_id: Uuid,
    pub workout_id: Option<Uuid>,
    pub name: Option<String>,
    pub notes: Option<String>,
    pub metadata: serde_json::Value,
    #[serde(with = "time::serde::rfc3339")]
    pub performed_at: OffsetDateTime,
    #[serde(with = "time::serde::rfc3339")]
    pub created_at: OffsetDateTime,
    #[serde(with = "time::serde::rfc3339")]
    pub updated_at: OffsetDateTime,
    #[serde(with = "time::serde::rfc3339::option")]
    pub deleted_at: Option<OffsetDateTime>,
}

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct CreateExerciseRequest {
    pub exercise_type_id: Uuid,
    pub workout_id: Option<Uuid>,
    #[validate(length(min = 1, max = 255, message = "Name must be between 1 and 255 characters"))]
    pub name: Option<String>,
    #[validate(length(max = 2000, message = "Notes cannot exceed 2000 characters"))]
    pub notes: Option<String>,
    pub metadata: Option<serde_json::Value>,
    #[serde(default, with = "time::serde::rfc3339::option")]
    pub performed_at: Option<OffsetDateTime>,
}

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct UpdateExerciseRequest {
    pub exercise_type_id: Option<Uuid>,
    pub workout_id: Option<Uuid>,
    #[validate(length(min = 1, max = 255, message = "Name must be between 1 and 255 characters"))]
    pub name: Option<String>,
    #[validate(length(max = 2000, message = "Notes cannot exceed 2000 characters"))]
    pub notes: Option<String>,
    pub metadata: Option<serde_json::Value>,
    #[serde(default, with = "time::serde::rfc3339::option")]
    pub performed_at: Option<OffsetDateTime>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ExerciseResponse {
    pub id: Uuid,
    pub user_id: Uuid,
    pub exercise_type_id: Uuid,
    pub exercise_type_name: String,
    pub exercise_type_category: Option<String>,
    pub workout_id: Option<Uuid>,
    pub name: Option<String>,
    pub notes: Option<String>,
    pub metadata: serde_json::Value,
    #[serde(with = "time::serde::rfc3339")]
    pub performed_at: OffsetDateTime,
    #[serde(with = "time::serde::rfc3339")]
    pub created_at: OffsetDateTime,
    #[serde(with = "time::serde::rfc3339")]
    pub updated_at: OffsetDateTime,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ExerciseWithType {
    pub id: Uuid,
    pub user_id: Uuid,
    pub exercise_type_id: Uuid,
    pub exercise_type_name: String,
    pub exercise_type_category: Option<String>,
    pub exercise_type_metadata_schema: serde_json::Value,
    pub workout_id: Option<Uuid>,
    pub name: Option<String>,
    pub notes: Option<String>,
    pub metadata: serde_json::Value,
    #[serde(with = "time::serde::rfc3339")]
    pub performed_at: OffsetDateTime,
    #[serde(with = "time::serde::rfc3339")]
    pub created_at: OffsetDateTime,
    #[serde(with = "time::serde::rfc3339")]
    pub updated_at: OffsetDateTime,
}

impl From<ExerciseWithType> for ExerciseResponse {
    fn from(exercise: ExerciseWithType) -> Self {
        Self {
            id: exercise.id,
            user_id: exercise.user_id,
            exercise_type_id: exercise.exercise_type_id,
            exercise_type_name: exercise.exercise_type_name,
            exercise_type_category: exercise.exercise_type_category,
            workout_id: exercise.workout_id,
            name: exercise.name,
            notes: exercise.notes,
            metadata: exercise.metadata,
            performed_at: exercise.performed_at,
            created_at: exercise.created_at,
            updated_at: exercise.updated_at,
        }
    }
}