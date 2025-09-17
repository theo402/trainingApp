# Training App - Project Overview

## Project Description

The Training App is a comprehensive fitness and exercise tracking platform designed to help users manage their workout routines, track exercises, and monitor their fitness progress. The project consists of a robust backend API built with Rust and a modern mobile application developed with Flutter.

## Architecture Overview

### Backend (Rust + PostgreSQL + TimescaleDB)
- **Framework**: Rust with Axum web framework for high-performance API endpoints
- **Database**: PostgreSQL with TimescaleDB extension for time-series sensor data
- **Authentication**: JWT-based stateless authentication with access/refresh tokens
- **Security**: Argon2id password hashing and comprehensive input validation
- **Data Model**: Exercise-first design where exercises are independent entities

### Frontend (Flutter Mobile App)
- **Framework**: Flutter with Dart for cross-platform mobile development
- **State Management**: Provider pattern for clean, reactive state management
- **UI/UX**: Material Design 3 with custom theming and responsive design
- **API Integration**: Dio HTTP client with automatic token management
- **Storage**: Flutter Secure Storage for credential management

## Core Features Implemented

### 🔐 Authentication System
- User registration and login with email/password
- JWT token management with automatic refresh
- Secure credential storage on mobile devices
- Session persistence and automatic logout

### 🏋️ Exercise Type Management
- Create custom exercise types with flexible metadata schemas
- JSON Schema validation for exercise-specific data fields
- Category-based organization (Strength, Cardio, Flexibility, etc.)
- Global and user-defined exercise types
- Dynamic form generation based on exercise type schemas

### 💪 Exercise Management
- Full CRUD operations for individual exercises
- Dynamic exercise creation forms that adapt to selected exercise type
- Metadata validation and type conversion (text, numbers, booleans)
- Filtering by category and exercise type
- Detailed exercise views with all associated data

### 📱 Mobile Application Features
- Cross-platform Flutter app (Android/iOS)
- Intuitive navigation with bottom tab bar
- Form validation and error handling
- Loading states and offline-friendly design
- Pull-to-refresh functionality

### 🗄️ Database Design
- PostgreSQL with proper indexing and constraints
- TimescaleDB hypertables for sensor data (prepared for future use)
- Soft deletion pattern for data recovery
- Comprehensive migration system
- Seed data for global exercise types

## Technical Highlights

### Backend Architecture
```
src/
├── controllers/     # Business logic and request handlers
├── models/         # Database queries and data structures
├── routes/         # API endpoint definitions
├── middleware/     # Authentication, logging, error handling
├── services/       # External service integrations
└── utils/          # Validation helpers and utilities
```

### Mobile App Architecture
```
lib/
├── models/         # Data models with JSON serialization
├── providers/      # State management with Provider pattern
├── services/       # API client and service layer
├── screens/        # UI screens and user interfaces
└── widgets/        # Reusable UI components
```

### Key Technical Decisions
1. **Exercise-First Design**: Exercises can exist independently without workouts
2. **JSON Schema Validation**: Exercise types define custom metadata validation
3. **Stateless Authentication**: JWT tokens for scalable authentication
4. **Soft Deletes**: All entities support recovery with deleted_at timestamps
5. **Type-Safe API**: Comprehensive input validation and error handling

## API Endpoints

### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - User authentication
- `GET /auth/profile` - Get current user profile

### Exercise Types
- `GET /exercise-types` - List available exercise types
- `POST /exercise-types` - Create custom exercise type
- `GET /exercise-types/:id` - Get exercise type details
- `PATCH /exercise-types/:id` - Update exercise type
- `DELETE /exercise-types/:id` - Delete exercise type

### Exercises
- `GET /exercises` - List exercises with filtering
- `POST /exercises` - Create new exercise
- `GET /exercises/:id` - Get exercise details
- `PATCH /exercises/:id` - Update exercise
- `DELETE /exercises/:id` - Delete exercise

## Database Schema

### Core Tables
- **users**: User accounts with encrypted passwords
- **exercise_types**: Exercise categories with JSON schema definitions
- **exercises**: Individual exercise entries with metadata
- **sensor_timeseries**: TimescaleDB hypertable for sensor data (prepared)

### Relationships
- Users can create custom exercise types (in addition to global ones)
- Exercises belong to exercise types and inherit their metadata schema
- All entities support soft deletion for data recovery

## Installation and Setup

### Backend Setup
```bash
# Start PostgreSQL with TimescaleDB
sudo systemctl start postgresql

# Create database and run migrations
cargo run --bin migrate

# Seed global exercise types
cargo run --bin seed

# Start development server
cargo run
```

### Mobile App Setup
```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build APK for Android
flutter build apk --release
```

## Current State

The project currently implements a solid foundation for exercise and workout tracking:

✅ **Complete authentication system** with secure token management
✅ **Flexible exercise type system** with custom metadata schemas
✅ **Full exercise CRUD operations** with dynamic form generation
✅ **Professional mobile UI** with Material Design 3
✅ **Robust backend API** with comprehensive validation
✅ **Database design** ready for future features

## Future Features and Roadmap

### 🎯 Immediate Priorities (Phase 5)

#### Workout Management System
- **Workout Planning**: Create workout templates and schedules
- **Workout Sessions**: Start, pause, resume, and complete workouts
- **Exercise Sequencing**: Add exercises to workouts with sets/reps/duration
- **Workout History**: Track completed workouts and progression
- **Workout Templates**: Save and reuse common workout routines

#### Enhanced Exercise Features
- **Exercise Photos/Videos**: Upload and view exercise demonstrations
- **Exercise Instructions**: Detailed step-by-step instructions
- **Exercise Variations**: Link related exercises and progressions
- **Equipment Tracking**: Tag exercises with required equipment

### 📊 Analytics and Tracking (Phase 6)

#### Progress Analytics
- **Performance Metrics**: Track strength, endurance, and skill progression
- **Visual Charts**: Progress graphs and trend analysis
- **Personal Records**: Track and celebrate PRs across exercises
- **Body Measurements**: Track weight, body fat, measurements over time
- **Goal Setting**: Set and track fitness goals with progress indicators

#### Advanced Statistics
- **Workout Volume**: Calculate total volume, frequency, intensity
- **Recovery Tracking**: Monitor rest periods and recovery metrics
- **Streak Tracking**: Workout streaks and consistency metrics
- **Comparative Analysis**: Compare performance across time periods

### 📱 Mobile App Enhancements (Phase 7)

#### User Experience Improvements
- **Offline Mode**: Full offline functionality with sync capabilities
- **Timer Integration**: Built-in rest timers and workout timers
- **Quick Actions**: Rapid exercise logging and workout shortcuts
- **Search and Filters**: Advanced search across exercises and workouts
- **Dark Mode**: Complete dark theme implementation

#### Social Features
- **Exercise Sharing**: Share workouts and exercises with other users
- **Community Feed**: See public workouts and achievements
- **Friends System**: Connect with other users and compare progress
- **Challenges**: Group challenges and competitions

### 🔧 Technical Enhancements (Phase 8)

#### Performance and Scalability
- **Caching Layer**: Redis for improved API performance
- **Database Optimization**: Query optimization and indexing improvements
- **File Storage**: S3-compatible storage for media files
- **Background Sync**: Intelligent sync for offline-first experience

#### Advanced Features
- **Push Notifications**: Workout reminders and achievement notifications
- **Export/Import**: Backup and restore user data
- **Integrations**: Connect with fitness trackers and health apps
- **Multi-language Support**: Internationalization for global users

### 🏃 Sensor Integration (Phase 9)

#### Real-time Data Collection
- **Heart Rate Monitoring**: Integration with HR sensors and wearables
- **Movement Tracking**: Accelerometer and gyroscope data collection
- **Form Analysis**: Real-time exercise form feedback
- **Environmental Data**: Temperature, humidity tracking during workouts

#### IoT Device Support
- **Smart Equipment**: Integration with smart gym equipment
- **Wearable Devices**: Smartwatch and fitness tracker integration
- **Custom Sensors**: Support for custom hardware sensors
- **Data Visualization**: Real-time sensor data charts and analysis

### 🔮 Advanced Features (Phase 10)

#### AI and Machine Learning
- **Workout Recommendations**: AI-powered workout suggestions
- **Form Correction**: Computer vision for exercise form analysis
- **Predictive Analytics**: Injury prevention and performance prediction
- **Personal Training AI**: Virtual coaching and adaptive programs

#### Platform Expansion
- **Web Application**: Full-featured web interface
- **Desktop Apps**: Native desktop applications
- **Tablet Optimization**: Enhanced UI for tablet devices
- **Smart TV Apps**: Workout guidance on large screens

## Development Environment

### Required Tools
- **Rust**: 1.70+ with Cargo
- **PostgreSQL**: 14+ with TimescaleDB extension
- **Flutter**: 3.10+ with Dart SDK
- **Git**: For version control

### Development Commands
```bash
# Backend
cargo run                    # Start development server
cargo test                   # Run all tests
cargo run --bin migrate      # Run database migrations

# Mobile
flutter run                  # Run on device/emulator
flutter test                 # Run widget tests
flutter build apk           # Build Android APK
```

## Contributing

The project follows modern development practices:
- **Clean Architecture**: Separation of concerns and modularity
- **Test Coverage**: Comprehensive unit and integration tests
- **Type Safety**: Full type safety in both Rust and Dart
- **Code Quality**: Automated linting and formatting
- **Documentation**: Comprehensive code and API documentation

This training app represents a solid foundation for a comprehensive fitness tracking platform, with a clear roadmap for expansion into advanced features like AI-powered coaching, social fitness communities, and real-time sensor integration.