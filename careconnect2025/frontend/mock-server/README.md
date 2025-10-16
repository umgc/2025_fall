# CareConnect Mock API Server

A Dart-based mock server that simulates the CareConnect backend APIs for frontend development and testing.

## Quick Start

1. **Install dependencies:**
   ```bash
   cd mock-server
   dart pub get
   ```

2. **Start the server:**
   ```bash
   dart run server.dart
   ```

3. **Update your Flutter app:**
   - Update your `.env` file to point to the mock server:
   ```
   BACKEND_BASE_URL=http://localhost:9090
   ```

## Demo Credentials

- **Patient:** `john@example.com` / `password123`
- **Caregiver:** `sarah@example.com` / `password123`

## Available Endpoints

### Authentication
- `POST /v1/api/auth/login` - User login
- `POST /v1/api/auth/register` - User registration
- `POST /v1/api/auth/logout` - User logout
- `GET /v1/api/auth/profile` - Get user profile

### Caregivers
- `POST /v1/api/caregivers` - Register caregiver
- `GET /v1/api/caregivers/:id` - Get caregiver profile
- `GET /v1/api/caregivers/:id/patients` - Get caregiver's patients
- `POST /v1/api/caregivers/:id/patients` - Add patient to caregiver

### Patients
- `GET /v1/api/patients/:id` - Get patient profile
- `GET /v1/api/patients/:id/profile/enhanced` - Get enhanced patient profile
- `POST /v1/api/patients/mood-pain-log` - Submit mood and pain log

### Feed
- `GET /v1/api/feed/all` - Get all posts
- `GET /v1/api/feed/user/:userId` - Get user's posts
- `POST /v1/api/feed/create` - Create new post

### Analytics
- `GET /v1/api/analytics/vitals` - Get patient vitals data

### Subscriptions
- `GET /v1/api/subscriptions/plans` - Get available plans
- `GET /v1/api/subscriptions/user/:userId` - Get user subscription

### Tasks
- `GET /v1/api/tasks/patient/:patientId` - Get patient tasks
- `POST /v1/api/tasks/patient/:patientId` - Create patient task
- `DELETE /v1/api/tasks/:taskId` - Delete task

### Files
- `POST /v1/api/files/users/:userId/upload` - Upload file
- `GET /v1/api/files/users/:userId` - Get user files

### Family Members
- `GET /v1/api/family-members/patients` - Get accessible patients
- `GET /v1/api/family-members/patients/:id/dashboard` - Get patient dashboard

## Mock Data

The server includes pre-populated mock data:
- 2 demo users (1 patient, 1 caregiver)
- Sample posts and tasks
- Mock vitals data
- Subscription plans

## Authentication

The server uses JWT tokens. Include the token in requests:
```
Authorization: Bearer <token>
```

## File Uploads

File uploads are handled with multipart/form-data and return mock S3 URLs.

## CORS

CORS is enabled for all origins to support local development.