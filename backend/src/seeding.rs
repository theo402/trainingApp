use sqlx::PgPool;
use crate::models::exercise_type::schemas;

pub async fn seed_global_exercise_types(pool: &PgPool) -> Result<(), sqlx::Error> {
    // Check if global exercise types already exist
    let count = sqlx::query!("SELECT COUNT(*) as count FROM exercise_types WHERE is_global = true")
        .fetch_one(pool)
        .await?;

    if count.count.unwrap_or(0) > 0 {
        println!("Global exercise types already exist, skipping seeding");
        return Ok(());
    }

    println!("Seeding global exercise types...");

    // Strength Training Exercises
    let strength_exercises = vec![
        ("Bench Press", "Chest", "Upper body strength exercise targeting chest, shoulders, and triceps"),
        ("Squat", "Legs", "Lower body compound exercise targeting quadriceps, glutes, and hamstrings"),
        ("Deadlift", "Back", "Full body compound exercise focusing on posterior chain"),
        ("Pull-up", "Back", "Upper body bodyweight exercise targeting lats and biceps"),
        ("Overhead Press", "Shoulders", "Vertical pressing movement for shoulders and triceps"),
        ("Barbell Row", "Back", "Horizontal pulling exercise for mid-back and biceps"),
        ("Dumbbell Curl", "Arms", "Isolation exercise for biceps"),
        ("Tricep Dips", "Arms", "Bodyweight exercise targeting triceps"),
    ];

    let strength_schema = schemas::strength_training_schema();

    let strength_count = strength_exercises.len();
    for (name, category, description) in &strength_exercises {
        sqlx::query!(
            "INSERT INTO exercise_types (name, description, category, metadata_schema, is_global, user_id)
             VALUES ($1, $2, $3, $4, true, NULL)",
            name,
            description,
            category,
            strength_schema
        )
        .execute(pool)
        .await?;
    }

    // Cardio Exercises
    let cardio_exercises = vec![
        ("Running", "Cardio", "Outdoor or treadmill running for cardiovascular fitness"),
        ("Cycling", "Cardio", "Stationary or outdoor cycling exercise"),
        ("Swimming", "Cardio", "Full body low-impact cardiovascular exercise"),
        ("Rowing", "Cardio", "Full body cardio using rowing machine or boat"),
        ("Elliptical", "Cardio", "Low-impact cardio machine exercise"),
        ("Jump Rope", "Cardio", "High-intensity cardiovascular exercise"),
        ("Stair Climbing", "Cardio", "Cardio exercise using stairs or stair machine"),
    ];

    let cardio_schema = schemas::cardio_schema();

    let cardio_count = cardio_exercises.len();
    for (name, category, description) in &cardio_exercises {
        sqlx::query!(
            "INSERT INTO exercise_types (name, description, category, metadata_schema, is_global, user_id)
             VALUES ($1, $2, $3, $4, true, NULL)",
            name,
            description,
            category,
            cardio_schema
        )
        .execute(pool)
        .await?;
    }

    // Bodyweight Exercises
    let bodyweight_exercises = vec![
        ("Push-ups", "Bodyweight", "Upper body bodyweight exercise"),
        ("Sit-ups", "Core", "Core strengthening bodyweight exercise"),
        ("Plank", "Core", "Isometric core exercise"),
        ("Lunges", "Legs", "Unilateral lower body exercise"),
        ("Burpees", "Full Body", "High-intensity full body exercise"),
        ("Mountain Climbers", "Full Body", "Dynamic full body cardio exercise"),
    ];

    let bodyweight_schema = schemas::bodyweight_schema();

    let bodyweight_count = bodyweight_exercises.len();
    for (name, category, description) in &bodyweight_exercises {
        sqlx::query!(
            "INSERT INTO exercise_types (name, description, category, metadata_schema, is_global, user_id)
             VALUES ($1, $2, $3, $4, true, NULL)",
            name,
            description,
            category,
            bodyweight_schema
        )
        .execute(pool)
        .await?;
    }

    // Flexibility/Stretching Exercises
    let flexibility_exercises = vec![
        ("Hamstring Stretch", "Flexibility", "Stretching exercise for hamstring muscles"),
        ("Hip Flexor Stretch", "Flexibility", "Stretching exercise for hip flexors"),
        ("Shoulder Stretch", "Flexibility", "Upper body stretching for shoulders"),
        ("Calf Stretch", "Flexibility", "Lower leg stretching exercise"),
        ("Yoga Flow", "Flexibility", "Dynamic yoga sequence for flexibility and strength"),
    ];

    let flexibility_schema = schemas::flexibility_schema();

    let flexibility_count = flexibility_exercises.len();
    for (name, category, description) in &flexibility_exercises {
        sqlx::query!(
            "INSERT INTO exercise_types (name, description, category, metadata_schema, is_global, user_id)
             VALUES ($1, $2, $3, $4, true, NULL)",
            name,
            description,
            category,
            flexibility_schema
        )
        .execute(pool)
        .await?;
    }

    println!("Successfully seeded {} global exercise types",
        strength_count + cardio_count + bodyweight_count + flexibility_count);

    Ok(())
}