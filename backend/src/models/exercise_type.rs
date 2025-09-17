use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use time::OffsetDateTime;
use uuid::Uuid;
use validator::Validate;

#[derive(Debug, FromRow, Serialize)]
pub struct ExerciseType {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub category: Option<String>,
    pub metadata_schema: serde_json::Value,
    pub is_global: bool,
    pub user_id: Option<Uuid>,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub deleted_at: Option<OffsetDateTime>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreateExerciseTypeRequest {
    #[validate(length(min = 1, max = 255))]
    pub name: String,
    #[validate(length(max = 1000))]
    pub description: Option<String>,
    #[validate(length(max = 100))]
    pub category: Option<String>,
    pub metadata_schema: Option<serde_json::Value>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateExerciseTypeRequest {
    #[validate(length(min = 1, max = 255))]
    pub name: Option<String>,
    #[validate(length(max = 1000))]
    pub description: Option<String>,
    #[validate(length(max = 100))]
    pub category: Option<String>,
    pub metadata_schema: Option<serde_json::Value>,
}

#[derive(Debug, Serialize)]
pub struct ExerciseTypeResponse {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub category: Option<String>,
    pub metadata_schema: serde_json::Value,
    pub is_global: bool,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
}

impl From<ExerciseType> for ExerciseTypeResponse {
    fn from(exercise_type: ExerciseType) -> Self {
        Self {
            id: exercise_type.id,
            name: exercise_type.name,
            description: exercise_type.description,
            category: exercise_type.category,
            metadata_schema: exercise_type.metadata_schema,
            is_global: exercise_type.is_global,
            created_at: exercise_type.created_at,
            updated_at: exercise_type.updated_at,
        }
    }
}

// Common metadata schemas for different exercise types
pub mod schemas {
    use serde_json::{json, Value};

    pub fn strength_training_schema() -> Value {
        json!({
            "type": "object",
            "properties": {
                "sets": {
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 100
                },
                "reps": {
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 1000
                },
                "weight": {
                    "type": "number",
                    "minimum": 0,
                    "maximum": 10000
                },
                "weight_unit": {
                    "type": "string",
                    "enum": ["kg", "lbs"]
                },
                "rest_seconds": {
                    "type": "integer",
                    "minimum": 0,
                    "maximum": 3600
                }
            },
            "required": ["sets", "reps"]
        })
    }

    pub fn cardio_schema() -> Value {
        json!({
            "type": "object",
            "properties": {
                "duration_minutes": {
                    "type": "number",
                    "minimum": 0,
                    "maximum": 1440
                },
                "distance": {
                    "type": "number",
                    "minimum": 0
                },
                "distance_unit": {
                    "type": "string",
                    "enum": ["km", "miles", "meters"]
                },
                "calories": {
                    "type": "integer",
                    "minimum": 0,
                    "maximum": 10000
                },
                "avg_heart_rate": {
                    "type": "integer",
                    "minimum": 40,
                    "maximum": 220
                },
                "max_heart_rate": {
                    "type": "integer",
                    "minimum": 40,
                    "maximum": 220
                }
            }
        })
    }

    pub fn bodyweight_schema() -> Value {
        json!({
            "type": "object",
            "properties": {
                "sets": {
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 100
                },
                "reps": {
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 1000
                },
                "duration_seconds": {
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 3600
                },
                "rest_seconds": {
                    "type": "integer",
                    "minimum": 0,
                    "maximum": 3600
                }
            }
        })
    }

    pub fn flexibility_schema() -> Value {
        json!({
            "type": "object",
            "properties": {
                "duration_seconds": {
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 3600
                },
                "intensity": {
                    "type": "integer",
                    "minimum": 1,
                    "maximum": 10
                },
                "notes": {
                    "type": "string",
                    "maxLength": 500
                }
            },
            "required": ["duration_seconds"]
        })
    }
}