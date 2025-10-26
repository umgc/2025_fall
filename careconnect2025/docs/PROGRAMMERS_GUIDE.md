# CareConnect 2025 Programmer's Guide

## Introduction

### Purpose

This Programmer Guide provides comprehensive documentation for developing, maintaining, and troubleshooting the CareConnect system. It covers all technical aspects, including development setup, coding standards, system integrations, and development lifecycle tools.

### Intended Audience

This document is for developers, engineers, and system administrators working on the CareConnect project. It serves as both an onboarding guide for new team members and a reference manual for existing developers.

### Technology Overview

CareConnect is built with modern, scalable technologies:
- **Frontend**: Flutter (cross-platform mobile/web)
- **Backend**: Spring Boot 3.4.5 with Java 17
- **Database**: PostgreSQL with JPA/Hibernate
- **AI Integration**: Spring AI + DeepSeek/LangChain4j
- **Security**: JWT-based authentication
- **Real-time**: WebSocket communication
- **Cloud**: AWS infrastructure

## Architecture Overview

### System Architecture

CareConnect follows a microservices-inspired architecture with clear separation between frontend, backend, and data layers.

```
┌─────────────────────────────────────────────────────────────────┐
│                        Frontend Layer                           │
├─────────────────────────────────────────────────────────────────┤
│  Flutter App (Web, iOS, Android, Desktop)                      │
│  ├── Provider (State Management)                               │
│  ├── GoRouter (Navigation)                                     │
│  ├── Dio (HTTP Client)                                         │
│  └── Features (Modular Architecture)                           │
└─────────────────────────────────────────────────────────────────┘
                                │
                         HTTP/WebSocket
                                │
┌─────────────────────────────────────────────────────────────────┐
│                        Backend Layer                            │
├─────────────────────────────────────────────────────────────────┤
│  Spring Boot Application                                        │
│  ├── Controllers (REST API)                                    │
│  ├── Services (Business Logic)                                 │
│  ├── Repositories (Data Access)                                │
│  ├── WebSocket (Real-time Communication)                       │
│  └── Security (JWT Authentication)                             │
└─────────────────────────────────────────────────────────────────┘
                                │
                           JDBC/JPA
                                │
┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                              │
├─────────────────────────────────────────────────────────────────┤
│  MySQL Database                                                 │
│  ├── User Management                                            │
│  ├── Health Data                                                │
│  ├── Communication                                              │
│  └── File Storage                                               │
└─────────────────────────────────────────────────────────────────┘
```

### Technology Stack

**Frontend (Flutter):**
- **Framework**: Flutter 3.9.2+
- **State Management**: Provider
- **Routing**: GoRouter
- **HTTP Client**: Dio
- **Local Storage**: SharedPreferences, SQLite
- **Real-time**: WebSocket, Socket.IO

**Backend (Spring Boot):**
- **Framework**: Spring Boot 3.4.5
- **Security**: Spring Security + JWT
- **Data Access**: Spring Data JPA
- **Database**: PostgreSQL 15+
- **WebSocket**: Spring WebSocket
- **Documentation**: OpenAPI 3

**Infrastructure:**
- **Cloud Provider**: AWS
- **Infrastructure as Code**: Terraform
- **Containerization**: Docker
- **CI/CD**: GitHub Actions

## Development Environment Setup

### Prerequisites

Ensure you have the following installed:
- **Flutter SDK**: 3.9.2+
- **Java**: OpenJDK 17
- **Maven**: 3.6+
- **MySQL**: 8.0+
- **Git**: Latest version
- **IDE**: VS Code, Android Studio, or IntelliJ IDEA

### Project Structure

```
careconnect2025/
├── frontend/                   # Flutter application
│   ├── lib/
│   │   ├── config/            # Configuration files
│   │   ├── features/          # Feature modules
│   │   ├── models/            # Data models
│   │   ├── providers/         # State management
│   │   ├── services/          # API services
│   │   └── main.dart          # App entry point
│   ├── assets/                # Static assets
│   ├── test/                  # Unit tests
│   └── pubspec.yaml           # Dependencies
├── backend/                   # Spring Boot application
│   └── core/
│       ├── src/main/java/com/careconnect/
│       │   ├── controller/    # REST controllers
│       │   ├── service/       # Business logic
│       │   ├── repository/    # Data access
│       │   ├── model/         # Entity models
│       │   ├── dto/           # Data transfer objects
│       │   ├── config/        # Configuration
│       │   └── exception/     # Exception handling
│       ├── src/main/resources/ # Configuration files
│       └── pom.xml            # Maven dependencies
├── terraform_aws/             # AWS infrastructure
└── docs/                      # Documentation
```

### Environment Configuration

#### Frontend Environment (.env)

```bash
# API Configuration
CC_BASE_URL_WEB=http://localhost:8080
CC_BASE_URL_ANDROID=http://10.0.2.2:8080
CC_BASE_URL_OTHER=http://localhost:8080

# JWT Configuration
JWT_SECRET=your_jwt_secret_key_here

# AI Services
DEEPSEEK_API_KEY=your_deepseek_api_key
OPENAI_API_KEY=your_openai_api_key

# Backend Authentication
CC_BACKEND_TOKEN=your_backend_token
```

#### Backend Configuration (application.properties)

```properties
# Database Configuration
spring.datasource.url=jdbc:mysql://localhost:3306/careconnect?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true
spring.datasource.username=careconnect
spring.datasource.password=your_password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA Configuration
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect

# Server Configuration
server.port=8080
server.servlet.context-path=/

# JWT Configuration
jwt.secret=your_jwt_secret_key_32_characters_minimum
jwt.expiration=86400000

# CORS Configuration
cors.allowed-origins=http://localhost:3000,http://localhost:50030,http://127.0.0.1:3000
```

## Frontend Development (Flutter)

### Project Architecture

The frontend follows a feature-based modular architecture:

```
lib/
├── config/                    # App configuration
│   ├── environment_config.dart
│   ├── network/
│   └── theme/
├── features/                  # Feature modules
│   ├── auth/                  # Authentication
│   ├── dashboard/             # Main dashboard
│   ├── health/                # Health tracking
│   ├── communication/         # Messaging & calls
│   ├── social/                # Social features
│   └── [feature_name]/
│       ├── data/              # Data layer
│       ├── models/            # Domain models
│       ├── presentation/      # UI layer
│       └── services/          # Feature services
├── shared/                    # Shared components
│   ├── widgets/
│   ├── utils/
│   └── constants/
└── main.dart
```

### State Management

CareConnect uses Provider for state management:

```dart
// providers/auth_provider.dart
class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _authService.login(email, password);
      _currentUser = response.user;
      await _tokenManager.saveTokens(response.tokens);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
```

### Routing Configuration

Using GoRouter for navigation:

```dart
// config/router_config.dart
final GoRouter routerConfig = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
      routes: [
        GoRoute(
          path: 'health',
          builder: (context, state) => const HealthScreen(),
        ),
        GoRoute(
          path: 'messages',
          builder: (context, state) => const MessagesScreen(),
        ),
      ],
    ),
  ],
  redirect: (context, state) {
    final isLoggedIn = context.read<AuthProvider>().currentUser != null;
    final isLoginRoute = state.uri.path == '/login';

    if (!isLoggedIn && !isLoginRoute) {
      return '/login';
    }
    if (isLoggedIn && isLoginRoute) {
      return '/dashboard';
    }
    return null;
  },
);
```

### HTTP Client Configuration

Dio configuration with interceptors:

```dart
// config/network/api_client.dart
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: EnvironmentConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(AuthInterceptor());
    _dio.interceptors.add(LoggingInterceptor());
    _dio.interceptors.add(ErrorInterceptor());
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await TokenManager.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await TokenManager.refreshToken();
      if (refreshed) {
        // Retry the original request
        final clonedRequest = await _dio.fetch(err.requestOptions);
        handler.resolve(clonedRequest);
        return;
      }
    }
    handler.next(err);
  }
}
```

### Feature Module Structure

Example feature module structure:

```dart
// features/health/models/vital_sign.dart
class VitalSign {
  final String id;
  final String type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String? notes;

  VitalSign({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.notes,
  });

  factory VitalSign.fromJson(Map<String, dynamic> json) {
    return VitalSign(
      id: json['id'],
      type: json['type'],
      value: json['value'].toDouble(),
      unit: json['unit'],
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'],
    );
  }
}

// features/health/services/health_service.dart
class HealthService {
  final ApiClient _apiClient;

  HealthService(this._apiClient);

  Future<List<VitalSign>> getVitalSigns() async {
    try {
      final response = await _apiClient.get('/api/health/vitals');
      return (response.data as List)
          .map((json) => VitalSign.fromJson(json))
          .toList();
    } catch (e) {
      throw HealthException('Failed to fetch vital signs: $e');
    }
  }

  Future<VitalSign> recordVitalSign(VitalSign vitalSign) async {
    try {
      final response = await _apiClient.post(
        '/api/health/vitals',
        data: vitalSign.toJson(),
      );
      return VitalSign.fromJson(response.data);
    } catch (e) {
      throw HealthException('Failed to record vital sign: $e');
    }
  }
}
```

## Backend Development (Spring Boot)

### Project Structure

```java
com.careconnect/
├── CareconnectBackendApplication.java  # Main application
├── config/                             # Configuration classes
│   ├── SecurityConfig.java
│   ├── WebSocketConfig.java
│   └── OpenApiConfig.java
├── controller/                         # REST controllers
├── service/                            # Business logic
├── repository/                         # Data access layer
├── model/                              # JPA entities
├── dto/                                # Data transfer objects
├── exception/                          # Exception handling
└── util/                               # Utility classes
```

### Entity Models

Example entity with JPA annotations:

```java
// model/User.java
@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener.class)
public class User extends Auditable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    @Email
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String firstName;

    @Column(nullable = false)
    private String lastName;

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    private UserRole role;

    @Column(nullable = false)
    private Boolean active = true;

    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL)
    private List<VitalSign> vitalSigns = new ArrayList<>();

    // Constructors, getters, setters
}

// model/VitalSign.java
@Entity
@Table(name = "vital_signs")
public class VitalSign extends Auditable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String type;

    @Column(nullable = false)
    private Double value;

    @Column(nullable = false)
    private String unit;

    @Column
    private String notes;

    @Column(nullable = false)
    private LocalDateTime measurementTime;

    // Constructors, getters, setters
}
```

### Repository Layer

Using Spring Data JPA:

```java
// repository/UserRepository.java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    List<User> findByRoleAndActiveTrue(UserRole role);

    @Query("SELECT u FROM User u WHERE u.role = :role AND u.active = true")
    List<User> findActiveUsersByRole(@Param("role") UserRole role);

    boolean existsByEmail(String email);
}

// repository/VitalSignRepository.java
@Repository
public interface VitalSignRepository extends JpaRepository<VitalSign, Long> {

    List<VitalSign> findByUserIdOrderByMeasurementTimeDesc(Long userId);

    List<VitalSign> findByUserIdAndTypeOrderByMeasurementTimeDesc(
        Long userId, String type);

    @Query("SELECT v FROM VitalSign v WHERE v.user.id = :userId " +
           "AND v.measurementTime BETWEEN :start AND :end")
    List<VitalSign> findByUserIdAndDateRange(
        @Param("userId") Long userId,
        @Param("start") LocalDateTime start,
        @Param("end") LocalDateTime end);
}
```

### Service Layer

Business logic implementation:

```java
// service/HealthService.java
@Service
@Transactional
public class HealthService {

    private final VitalSignRepository vitalSignRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public HealthService(VitalSignRepository vitalSignRepository,
                        UserRepository userRepository,
                        NotificationService notificationService) {
        this.vitalSignRepository = vitalSignRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    public List<VitalSignDTO> getVitalSigns(Long userId) {
        List<VitalSign> vitalSigns = vitalSignRepository
            .findByUserIdOrderByMeasurementTimeDesc(userId);

        return vitalSigns.stream()
            .map(this::convertToDTO)
            .collect(Collectors.toList());
    }

    public VitalSignDTO recordVitalSign(Long userId, VitalSignDTO vitalSignDTO) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        VitalSign vitalSign = new VitalSign();
        vitalSign.setUser(user);
        vitalSign.setType(vitalSignDTO.getType());
        vitalSign.setValue(vitalSignDTO.getValue());
        vitalSign.setUnit(vitalSignDTO.getUnit());
        vitalSign.setNotes(vitalSignDTO.getNotes());
        vitalSign.setMeasurementTime(LocalDateTime.now());

        vitalSign = vitalSignRepository.save(vitalSign);

        // Check for alerts
        checkVitalSignAlerts(vitalSign);

        return convertToDTO(vitalSign);
    }

    private void checkVitalSignAlerts(VitalSign vitalSign) {
        // Implement alert logic based on vital sign thresholds
        if (isAbnormalReading(vitalSign)) {
            notificationService.sendAlert(
                vitalSign.getUser(),
                "Abnormal vital sign detected: " + vitalSign.getType(),
                AlertType.HEALTH_ALERT
            );
        }
    }

    private VitalSignDTO convertToDTO(VitalSign vitalSign) {
        // Convert entity to DTO
        return VitalSignDTO.builder()
            .id(vitalSign.getId())
            .type(vitalSign.getType())
            .value(vitalSign.getValue())
            .unit(vitalSign.getUnit())
            .notes(vitalSign.getNotes())
            .measurementTime(vitalSign.getMeasurementTime())
            .build();
    }
}
```

### Controller Layer

REST API endpoints:

```java
// controller/HealthController.java
@RestController
@RequestMapping("/api/health")
@PreAuthorize("hasRole('PATIENT') or hasRole('CAREGIVER')")
@Tag(name = "Health", description = "Health data management")
public class HealthController {

    private final HealthService healthService;

    public HealthController(HealthService healthService) {
        this.healthService = healthService;
    }

    @GetMapping("/vitals")
    @Operation(summary = "Get user's vital signs")
    public ResponseEntity<List<VitalSignDTO>> getVitalSigns(
            Authentication authentication) {

        Long userId = getUserIdFromAuthentication(authentication);
        List<VitalSignDTO> vitalSigns = healthService.getVitalSigns(userId);

        return ResponseEntity.ok(vitalSigns);
    }

    @PostMapping("/vitals")
    @Operation(summary = "Record a new vital sign")
    public ResponseEntity<VitalSignDTO> recordVitalSign(
            @Valid @RequestBody VitalSignDTO vitalSignDTO,
            Authentication authentication) {

        Long userId = getUserIdFromAuthentication(authentication);
        VitalSignDTO savedVitalSign = healthService.recordVitalSign(userId, vitalSignDTO);

        return ResponseEntity.status(HttpStatus.CREATED).body(savedVitalSign);
    }

    @GetMapping("/vitals/{type}")
    @Operation(summary = "Get vital signs by type")
    public ResponseEntity<List<VitalSignDTO>> getVitalSignsByType(
            @PathVariable String type,
            Authentication authentication) {

        Long userId = getUserIdFromAuthentication(authentication);
        List<VitalSignDTO> vitalSigns = healthService.getVitalSignsByType(userId, type);

        return ResponseEntity.ok(vitalSigns);
    }

    private Long getUserIdFromAuthentication(Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        return userPrincipal.getId();
    }
}
```

## Database Design

### Entity Relationship Diagram

```
Users                          VitalSigns
┌─────────────────────┐       ┌─────────────────────┐
│ id (PK)             │       │ id (PK)             │
│ email (UQ)          │       │ user_id (FK)        │
│ password            │       │ type                │
│ first_name          │       │ value               │
│ last_name           │       │ unit                │
│ role                │       │ notes               │
│ active              │       │ measurement_time    │
│ created_at          │       │ created_at          │
│ updated_at          │       │ updated_at          │
└─────────────────────┘       └─────────────────────┘
          │                            │
          └────────────1:N─────────────┘

CaregiverPatientLink          ChatMessages
┌─────────────────────┐       ┌─────────────────────┐
│ id (PK)             │       │ id (PK)             │
│ caregiver_id (FK)   │       │ sender_id (FK)      │
│ patient_id (FK)     │       │ receiver_id (FK)    │
│ status              │       │ content             │
│ created_at          │       │ message_type        │
│ updated_at          │       │ sent_at             │
└─────────────────────┘       └─────────────────────┘
```

### Database Schema

```sql
-- Users table
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role ENUM('PATIENT', 'CAREGIVER', 'FAMILY_MEMBER') NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Vital signs table
CREATE TABLE vital_signs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    type VARCHAR(50) NOT NULL,
    value DECIMAL(10,2) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    notes TEXT,
    measurement_time DATETIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_vital_signs_user_id ON vital_signs(user_id);
CREATE INDEX idx_vital_signs_type ON vital_signs(type);
CREATE INDEX idx_vital_signs_measurement_time ON vital_signs(measurement_time);
```

## API Documentation

### OpenAPI Configuration

```java
// config/OpenApiConfig.java
@Configuration
@EnableWebSecurity
public class OpenApiConfig {

    @Bean
    public OpenAPI customOpenAPI() {
        return new OpenAPI()
            .info(new Info()
                .title("CareConnect API")
                .version("1.0.0")
                .description("Healthcare management platform API"))
            .addSecurityItem(new SecurityRequirement().addList("bearerAuth"))
            .components(new Components()
                .addSecuritySchemes("bearerAuth",
                    new SecurityScheme()
                        .type(SecurityScheme.Type.HTTP)
                        .scheme("bearer")
                        .bearerFormat("JWT")));
    }
}
```

### RESTful API Endpoints

The CareConnect backend provides a comprehensive RESTful API with over 100 endpoints organized by functional domains. All endpoints follow consistent patterns with proper HTTP methods, status codes, and JSON responses.

#### Base URL and Versioning

All API endpoints are prefixed with `/v1/api/` (with some legacy endpoints at `/api/`). The backend runs on Spring Boot with embedded Tomcat.

```
Base URL: http://localhost:8080/v1/api
Production: https://your-domain.com/v1/api
```

#### Authentication & Authorization

Most endpoints require Bearer token authentication obtained through the login process:

```http
Authorization: Bearer <jwt-token>
```

**Public Endpoints (No Authentication Required):**
- All `/v1/api/auth/**` endpoints (registration, login, password reset)
- `/v1/api/emergency/**` endpoints (emergency PDF access)
- `/v1/api/public/**` endpoints
- Email verification and OAuth callbacks

#### Core API Endpoints by Domain

##### 1. Authentication (`/v1/api/auth`)

**Registration & Login**
```http
POST /v1/api/auth/register
Content-Type: application/json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "role": "PATIENT"
}

POST /v1/api/auth/login
Content-Type: application/json
{
  "email": "user@example.com",
  "password": "password123"
}
Response: {
  "token": "jwt-token",
  "user": {...},
  "patientId": 123,
  "caregiverId": null
}
```

**Password Management**
```http
POST /v1/api/auth/password/forgot
POST /v1/api/auth/password/change
GET /v1/api/auth/password/reset?token=abc123
```

**OAuth & Third-Party Integration**
```http
GET /v1/api/auth/sso/google
POST /v1/api/auth/sso/alexa/code
POST /v1/api/auth/sso/alexa/token
```

##### 2. Patient Management (`/v1/api/patients`)

**Patient Profile**
```http
GET /v1/api/patients/{patientId}
PUT /v1/api/patients/{patientId}
GET /v1/api/patients/me  # Current patient's profile
GET /v1/api/patients/{patientId}/profile/enhanced  # With medical data
```

**Mood & Pain Tracking**
```http
POST /v1/api/patients/mood-pain-log
{
  "mood": 7,
  "pain": 3,
  "timestamp": "2024-01-15T10:30:00Z",
  "notes": "Feeling better today"
}

GET /v1/api/patients/mood-pain-log/range?startDate=2024-01-01&endDate=2024-01-31
GET /v1/api/patients/mood-pain-log/analytics?startDate=2024-01-01&endDate=2024-01-31
```

**Medication Management**
```http
GET /v1/api/patients/{patientId}/medications
POST /v1/api/patients/{patientId}/medications
DELETE /v1/api/patients/{patientId}/medications/{medicationId}  # Soft delete
```

**Family Member Relations**
```http
GET /v1/api/patients/{patientId}/family-members
POST /v1/api/patients/{patientId}/family-members
{
  "email": "family@example.com",
  "firstName": "Jane",
  "lastName": "Doe",
  "relationship": "daughter",
  "permissions": ["VIEW_PROFILE", "VIEW_VITALS"]
}
```

##### 3. Caregiver Operations (`/v1/api/caregivers`)

```http
GET /v1/api/caregivers/{caregiverId}/patients?email=patient@example.com&name=John
POST /v1/api/caregivers/{caregiverId}/patients
{
  "email": "newpatient@example.com",
  "firstName": "New",
  "lastName": "Patient",
  "dateOfBirth": "1990-01-01",
  "emergencyContactName": "Contact Name",
  "emergencyContactPhone": "555-0123"
}

POST /v1/api/caregivers/{caregiverId}/patients/add
{
  "email": "existing@example.com"
}
```

##### 4. Analytics & Vital Signs (`/v1/api/analytics`)

**Dashboard & Vitals**
```http
GET /v1/api/analytics/dashboard?patientId=123&days=30
GET /v1/api/analytics/vitals?patientId=123&days=7

POST /v1/api/analytics/vitals
{
  "patientId": 123,
  "vitalType": "BLOOD_PRESSURE",
  "systolic": 120,
  "diastolic": 80,
  "timestamp": "2024-01-15T10:30:00Z",
  "notes": "Morning reading"
}
```

**Data Export**
```http
GET /v1/api/analytics/export/vitals/csv?patientId=123&days=30
GET /v1/api/analytics/export/vitals/pdf?patientId=123&days=30
```

**Live Data Streaming**
```http
GET /v1/api/analytics/live?patientId=123
Accept: text/event-stream
# Returns Server-Sent Events stream
```

##### 5. Task Management

**Version 2 (Current)**
```http
GET /v2/api/tasks/patient/{patientId}
POST /v2/api/tasks/patient/{patientId}
{
  "title": "Take medication",
  "description": "Take morning pills",
  "dueDate": "2024-01-15T09:00:00Z",
  "priority": "HIGH",
  "completed": false
}

PUT /v2/api/tasks/{id}/complete
{
  "isComplete": true
}

DELETE /v2/api/tasks/{id}?deleteSeries=true  # For recurring tasks
```

##### 6. Messaging & Communication (`/v1/api/messages`)

```http
POST /v1/api/messages/send
{
  "senderId": 123,
  "receiverId": 456,
  "content": "How are you feeling today?",
  "messageType": "TEXT"
}

GET /v1/api/messages/conversation?user1=123&user2=456
GET /v1/api/messages/inbox/{userId}
```

##### 7. Notifications (`/v1/api/notifications`)

**Push Notifications**
```http
POST /v1/api/notifications/send
{
  "title": "Medication Reminder",
  "body": "Time to take your morning medication",
  "fcmTokens": ["fcm-token-1", "fcm-token-2"],
  "notificationType": "MEDICATION_REMINDER",
  "data": {
    "medicationId": "123",
    "patientId": "456"
  }
}
```

**Specialized Alerts**
```http
POST /v1/api/notifications/vital-alert/{patientId}?vitalType=BLOOD_PRESSURE&vitalValue=180/120&alertLevel=HIGH
POST /v1/api/notifications/emergency-alert/{patientId}?emergencyType=FALL_DETECTED&location=Living Room
POST /v1/api/notifications/medication-reminder/{patientId}?medicationName=Aspirin&dosage=100mg&scheduledTime=09:00
```

##### 8. File Management (`/v1/api/files`)

```http
POST /v1/api/files/upload
Content-Type: multipart/form-data
file: <binary-data>
category: "MEDICAL_RECORDS"
description: "Lab results from 2024-01-15"
patientId: 123

GET /v1/api/files/{fileId}/download
GET /v1/api/files/my-files?category=MEDICAL_RECORDS
GET /v1/api/files/patient/{patientId}?category=PRESCRIPTIONS
DELETE /v1/api/files/{fileId}
```

##### 9. Emergency Services (`/v1/api/emergency`)

**Public Emergency Access (No Authentication)**
```http
GET /v1/api/emergency/{emergencyId}.pdf
# Returns Vial of Life PDF with patient emergency information
# emergencyId format: VIAL123456

GET /v1/api/emergency/download/{emergencyId}.pdf
# Forces download instead of browser viewing
```

##### 10. Electronic Visit Verification (EVV) (`/v1/api/evv`)

```http
POST /v1/api/evv/participants
{
  "participantName": "John Doe",
  "participantId": "P123456",
  "serviceType": "PERSONAL_CARE",
  "authorizedHours": 40
}

POST /v1/api/evv/records
{
  "participantId": "P123456",
  "providerId": "PRV789",
  "serviceDate": "2024-01-15",
  "clockInTime": "09:00:00",
  "clockOutTime": "17:00:00",
  "serviceLocation": "123 Main St",
  "servicesProvided": ["PERSONAL_CARE", "MEAL_PREPARATION"],
  "gpsCoordinates": {
    "latitude": 38.9072,
    "longitude": -77.0369
  }
}

GET /v1/api/evv/records/search?participantId=P123456&startDate=2024-01-01&endDate=2024-01-31
```

##### 11. Alexa Integration (`/v1/api/alexa`)

```http
GET /v1/api/alexa/calendarTasks/get?filter=week
Authorization: Bearer <alexa-access-token>

POST /v1/api/alexa/calendarTasks/add
Authorization: Bearer <alexa-access-token>
{
  "name": "Doctor appointment",
  "description": "Annual checkup with Dr. Smith",
  "date": "2024-01-20",
  "timeOfDay": "MORNING",
  "priority": "HIGH"
}
```

##### 12. Subscription Management (`/v1/api/subscriptions`)

```http
GET /v1/api/subscriptions/plans
POST /v1/api/subscriptions/create?plan=premium&userId=123&amount=2999
GET /v1/api/subscriptions/user/{userId}/active
POST /v1/api/subscriptions/{id}/cancel
POST /v1/api/subscriptions/upgrade-or-downgrade?oldSubscriptionId=sub_123&newPriceId=price_456
```

#### Error Handling

All endpoints return consistent error responses:

```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed for field 'email'",
  "path": "/v1/api/auth/register"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (missing/invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict (duplicate resource)
- `500` - Internal Server Error

#### Rate Limiting

API endpoints implement rate limiting based on user role:
- **Public endpoints**: 100 requests per hour per IP
- **Authenticated users**: 1000 requests per hour per user
- **Emergency endpoints**: No rate limiting

#### Data Formats

**Date/Time**: ISO 8601 format (`2024-01-15T10:30:00Z`)
**Pagination**:
```json
{
  "content": [...],
  "pageable": {
    "page": 0,
    "size": 20,
    "sort": "createdAt,desc"
  },
  "totalElements": 100,
  "totalPages": 5
}
```

#### WebSocket Integration

Real-time communication endpoints at `/ws`:
- `/ws/notifications` - Real-time notifications
- `/ws/vitals` - Live vital signs updates
- `/ws/chat` - Messaging system

## Authentication & Security

### JWT Implementation

```java
// util/JwtUtil.java
@Component
public class JwtUtil {

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration}")
    private long jwtExpiration;

    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        return createToken(claims, userDetails.getUsername());
    }

    private String createToken(Map<String, Object> claims, String subject) {
        return Jwts.builder()
            .setClaims(claims)
            .setSubject(subject)
            .setIssuedAt(new Date(System.currentTimeMillis()))
            .setExpiration(new Date(System.currentTimeMillis() + jwtExpiration))
            .signWith(getSigningKey(), SignatureAlgorithm.HS256)
            .compact();
    }

    public Boolean validateToken(String token, UserDetails userDetails) {
        final String username = getUsernameFromToken(token);
        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }

    private Key getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(jwtSecret);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
```

### JWT Authentication Filter

The CareConnect backend uses a custom JWT authentication filter that provides comprehensive token-based authentication with automatic token renewal and multi-source token resolution.

#### JwtAuthenticationFilter Implementation

```java
// security/JwtAuthenticationFilter.java
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(JwtAuthenticationFilter.class);
    private static final String COOKIE_NAME = "AUTH";

    // Paths excluded from JWT authentication
    private static final List<String> EXCLUDED_PATHS = Arrays.asList(
        "/swagger-ui",
        "/v3/api-docs",
        "/swagger-resources",
        "/webjars",
        "/v1/api/auth",           // Authentication endpoints
        "/api/v1/auth",
        "/v1/api/test",           // Test endpoints
        "/v1/api/caregivers",     // Public caregiver registration
        "/v1/api/subscriptions",  // Public subscription info
        "/v1/api/email-test",     // Email testing
        "/v1/api/emergency"       // Emergency PDF access (no auth required)
    );

    private final JwtTokenProvider jwt;
    private final UserDetailsService uds;

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return EXCLUDED_PATHS.stream().anyMatch(path::startsWith);
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req,
                                    HttpServletResponse res,
                                    FilterChain chain)
            throws ServletException, IOException {

        String requestURI = req.getRequestURI();
        log.debug("Processing JWT authentication for: {}", requestURI);

        // 1. Resolve token from header or cookie
        String token = resolveToken(req);

        // 2. Validate token and build authentication
        if (token != null && jwt.validateToken(token)) {
            Claims claims = jwt.getClaims(token);
            String email = claims.getSubject();
            String role = claims.get("role", String.class);

            // Role-specific user loading for precise authentication
            UserDetails userDetails;
            if (role != null && uds instanceof UserDetailsServiceImpl) {
                userDetails = ((UserDetailsServiceImpl) uds)
                    .loadUserByEmailAndRole(email, role);
            } else {
                userDetails = uds.loadUserByUsername(email);
            }

            UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken(
                    userDetails, null, userDetails.getAuthorities());
            auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(req));
            SecurityContextHolder.getContext().setAuthentication(auth);

            // 3. Silent token renewal (if < 5 minutes remaining)
            if (jwt.needsRenewal(claims)) {
                String renewed = jwt.refresh(claims);
                ResponseCookie cookie = ResponseCookie.from(COOKIE_NAME, renewed)
                    .httpOnly(true)
                    .secure(true)
                    .sameSite("Lax")
                    .path("/")
                    .maxAge(Duration.ofHours(3))  // 3-hour sliding window
                    .build();
                res.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
                log.debug("Token renewed for user: {}", email);
            }
        }

        chain.doFilter(req, res);
    }

    private String resolveToken(HttpServletRequest req) {
        // Check Bearer header first
        String header = req.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            return header.substring(7);
        }

        // Fallback to HttpOnly cookie
        if (req.getCookies() != null) {
            return Arrays.stream(req.getCookies())
                .filter(c -> COOKIE_NAME.equals(c.getName()))
                .findFirst()
                .map(Cookie::getValue)
                .orElse(null);
        }
        return null;
    }
}
```

#### Key Features

**Multi-Source Token Resolution:**
- Primary: `Authorization: Bearer <token>` header
- Fallback: HttpOnly `AUTH` cookie for web clients
- Secure cookie configuration (HttpOnly, Secure, SameSite)

**Path-Based Exclusions:**
- Public authentication endpoints (`/v1/api/auth/**`)
- Emergency access endpoints (`/v1/api/emergency/**`)
- API documentation (`/swagger-ui/**`, `/v3/api-docs/**`)
- Public registration endpoints

**Automatic Token Renewal:**
- Silent renewal when < 5 minutes remaining
- 3-hour sliding window maximum
- Maintains user session without interruption

**Role-Based Authentication:**
- Extracts role from JWT claims
- Role-specific user loading for multi-role scenarios
- Prevents authentication ambiguity

### Security Configuration

```java
// config/SecurityConfig.java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf().disable()
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authorizeHttpRequests(authz -> authz
                // Public endpoints
                .requestMatchers("/v1/api/auth/**").permitAll()
                .requestMatchers("/v1/api/emergency/**").permitAll()
                .requestMatchers("/v1/api/public/**").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()

                // Role-based endpoints
                .requestMatchers("/v1/api/patients/**").hasAnyRole("PATIENT", "CAREGIVER", "FAMILY_MEMBER")
                .requestMatchers("/v1/api/caregivers/**").hasAnyRole("CAREGIVER", "ADMIN")
                .requestMatchers("/v1/api/family-members/**").hasRole("FAMILY_MEMBER")
                .requestMatchers("/v1/api/admin/**").hasRole("ADMIN")

                // Default authentication required
                .anyRequest().authenticated())
            .exceptionHandling()
                .authenticationEntryPoint(jwtAuthenticationEntryPoint)
            .and()
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}
```

### JWT Token Provider

```java
// security/JwtTokenProvider.java
@Component
public class JwtTokenProvider {

    @Value("${jwt.secret}")
    private String jwtSecret;

    @Value("${jwt.expiration:3600000}") // 1 hour default
    private long jwtExpiration;

    private static final long RENEWAL_THRESHOLD = 5 * 60 * 1000; // 5 minutes

    public String generateToken(UserDetails userDetails, String role) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("role", role);
        claims.put("authorities", userDetails.getAuthorities());

        return createToken(claims, userDetails.getUsername());
    }

    private String createToken(Map<String, Object> claims, String subject) {
        Date now = new Date();
        Date validity = new Date(now.getTime() + jwtExpiration);

        return Jwts.builder()
            .setClaims(claims)
            .setSubject(subject)
            .setIssuedAt(now)
            .setExpiration(validity)
            .signWith(getSigningKey(), SignatureAlgorithm.HS256)
            .compact();
    }

    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            log.debug("Invalid JWT token: {}", e.getMessage());
            return false;
        }
    }

    public Claims getClaims(String token) {
        return Jwts.parserBuilder()
            .setSigningKey(getSigningKey())
            .build()
            .parseClaimsJws(token)
            .getBody();
    }

    public boolean needsRenewal(Claims claims) {
        Date expiration = claims.getExpiration();
        long timeUntilExpiry = expiration.getTime() - System.currentTimeMillis();
        return timeUntilExpiry < RENEWAL_THRESHOLD;
    }

    public String refresh(Claims claims) {
        // Create new token with extended expiration
        Map<String, Object> newClaims = new HashMap<>(claims);
        return createToken(newClaims, claims.getSubject());
    }

    private Key getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(jwtSecret);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
```

### User Details Service Implementation

```java
// security/UserDetailsServiceImpl.java
@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(email)
            .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));

        return UserPrincipal.create(user);
    }

    // Role-specific loading for multi-role scenarios
    public UserDetails loadUserByEmailAndRole(String email, String role)
            throws UsernameNotFoundException {
        User user = userRepository.findByEmailAndRole(email, UserRole.valueOf(role))
            .orElseThrow(() -> new UsernameNotFoundException(
                "User not found with email: " + email + " and role: " + role));

        return UserPrincipal.create(user);
    }
}

// security/UserPrincipal.java
@Getter
@AllArgsConstructor
public class UserPrincipal implements UserDetails {

    private Long id;
    private String email;
    private String password;
    private Collection<? extends GrantedAuthority> authorities;
    private boolean enabled;

    public static UserPrincipal create(User user) {
        List<GrantedAuthority> authorities = List.of(
            new SimpleGrantedAuthority("ROLE_" + user.getRole().name())
        );

        return new UserPrincipal(
            user.getId(),
            user.getEmail(),
            user.getPassword(),
            authorities,
            user.getActive()
        );
    }

    @Override
    public String getUsername() { return email; }

    @Override
    public boolean isAccountNonExpired() { return true; }

    @Override
    public boolean isAccountNonLocked() { return true; }

    @Override
    public boolean isCredentialsNonExpired() { return true; }

    @Override
    public boolean isEnabled() { return enabled; }
}
```

### Security Features

**Password Security:**
- BCrypt hashing with strength 12
- Minimum 8 characters with complexity requirements
- Password history prevention (last 5 passwords)

**Session Management:**
- Stateless JWT-based authentication
- Automatic token renewal for active sessions
- Secure cookie storage for web clients

**CORS Configuration:**
```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOriginPatterns(List.of("*"));
    configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
    configuration.setAllowedHeaders(List.of("*"));
    configuration.setAllowCredentials(true);

    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
}
```

**Rate Limiting:**
- API rate limiting based on user role and endpoint
- Brute force protection for authentication endpoints
- Emergency endpoint exemption from rate limits

## Real-time Communication

CareConnect implements a comprehensive WebSocket-based real-time communication system specifically designed for healthcare applications. The system uses a **dual-mode architecture** that automatically switches between local development and AWS production environments.

### Architecture Overview

The WebSocket system provides three main communication channels:
- **`/ws/careconnect`** - General healthcare updates (AI notifications, vital signs, medication reminders)
- **`/ws/calls`** - Video/audio call management and SMS notifications
- **`/ws/notifications`** - Basic notification delivery

### WebSocket Configuration

#### Dual-Mode Configuration

```java
// config/WebSocketModeConfig.java
@Configuration
@ConditionalOnProperty(name = "careconnect.websocket.enabled", havingValue = "true", matchIfMissing = true)
public class WebSocketModeConfig {

    @Bean
    @ConditionalOnMissingBean(name = "awsWebSocketApiEndpoint")
    public WebSocketConfig localWebSocketConfig() {
        return new WebSocketConfig(); // Local development mode
    }

    @Bean
    @ConditionalOnBean(name = "awsWebSocketApiEndpoint")
    public AwsWebSocketService awsWebSocketService() {
        return new AwsWebSocketService(); // AWS production mode
    }
}

// config/WebSocketConfig.java
@Configuration
@EnableWebSocket
@Slf4j
public class WebSocketConfig implements WebSocketConfigurer {

    @Value("${careconnect.websocket.allowed-origins}")
    private String allowedOrigins;

    private final CareConnectWebSocketHandler careConnectHandler;
    private final CallNotificationHandler callHandler;
    private final NotificationWebSocketHandler notificationHandler;

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        String[] origins = allowedOrigins.split(",");

        // Main healthcare WebSocket with SockJS fallback
        registry.addHandler(careConnectHandler, "/ws/careconnect")
                .setAllowedOrigins(origins)
                .withSockJS();

        // Call management WebSocket with SockJS fallback
        registry.addHandler(callHandler, "/ws/calls")
                .setAllowedOrigins(origins)
                .withSockJS();

        // Basic notifications (no SockJS)
        registry.addHandler(notificationHandler, "/ws/notifications")
                .setAllowedOrigins(origins);
    }
}
```

### WebSocket Handlers

#### CareConnectWebSocketHandler - Healthcare Communications

```java
@Component
@Slf4j
public class CareConnectWebSocketHandler extends TextWebSocketHandler {

    private final JwtTokenProvider jwtTokenProvider;
    private final WebSocketConnectionService connectionService;
    private final Map<Long, WebSocketSession> userSessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        log.info("WebSocket connection established: {}", session.getId());
        session.getAttributes().put("connectionTime", System.currentTimeMillis());

        // Send initial connection message
        sendMessage(session, Map.of(
            "type", "connection-established",
            "message", "WebSocket connection successful",
            "sessionId", session.getId()
        ));
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        try {
            Map<String, Object> payload = objectMapper.readValue(message.getPayload(), Map.class);
            String messageType = (String) payload.get("type");

            switch (messageType) {
                case "authenticate":
                    handleAuthentication(session, payload);
                    break;
                case "heartbeat":
                    handleHeartbeat(session);
                    break;
                case "ai-chat-notification":
                    handleAIChatNotification(session, payload);
                    break;
                case "mood-pain-log-update":
                    handleMoodPainLogUpdate(session, payload);
                    break;
                case "medication-reminder":
                    handleMedicationReminder(session, payload);
                    break;
                case "vital-signs-alert":
                    handleVitalSignsAlert(session, payload);
                    break;
                case "emergency-alert":
                    handleEmergencyAlert(session, payload);
                    break;
                default:
                    log.warn("Unknown message type: {}", messageType);
            }
        } catch (Exception e) {
            log.error("Error handling WebSocket message", e);
            sendErrorMessage(session, "Invalid message format");
        }
    }

    private void handleAuthentication(WebSocketSession session, Map<String, Object> payload) {
        try {
            String token = (String) payload.get("token");
            Long userId = getLongValue(payload, "userId");

            if (jwtTokenProvider.validateToken(token)) {
                Claims claims = jwtTokenProvider.getClaims(token);
                String email = claims.getSubject();
                String role = claims.get("role", String.class);

                // Store user info in session
                session.getAttributes().put("userId", userId);
                session.getAttributes().put("email", email);
                session.getAttributes().put("role", role);
                session.getAttributes().put("authenticated", true);

                // Map user to session
                userSessions.put(userId, session);

                // Persist connection
                connectionService.saveConnection(session.getId(), email, userId, "authenticated");

                sendMessage(session, Map.of(
                    "type", "authentication-success",
                    "userId", userId,
                    "email", email,
                    "role", role
                ));

                log.info("User {} authenticated via WebSocket", email);
            } else {
                sendMessage(session, Map.of(
                    "type", "authentication-error",
                    "message", "Invalid token"
                ));
            }
        } catch (Exception e) {
            log.error("Authentication error", e);
            sendErrorMessage(session, "Authentication failed");
        }
    }

    private void handleEmergencyAlert(WebSocketSession session, Map<String, Object> payload) {
        // High-priority emergency handling
        Long patientId = getLongValue(payload, "patientId");
        String alertType = (String) payload.get("alertType");
        String message = (String) payload.get("message");

        // Notify all caregivers and family members
        broadcastToUsersByRole(patientId, "emergency-alert", Map.of(
            "patientId", patientId,
            "alertType", alertType,
            "message", message,
            "timestamp", System.currentTimeMillis(),
            "priority", "HIGH"
        ), List.of("CAREGIVER", "FAMILY_MEMBER"));

        log.warn("Emergency alert sent for patient {}: {}", patientId, alertType);
    }
}
```

#### CallNotificationHandler - Video/Audio Calls

```java
@Component
@Slf4j
public class CallNotificationHandler extends TextWebSocketHandler {

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        Map<String, Object> payload = objectMapper.readValue(message.getPayload(), Map.class);
        String messageType = (String) payload.get("type");

        switch (messageType) {
            case "send-video-call-invitation":
                handleVideoCallInvitation(session, payload);
                break;
            case "accept-call":
                handleAcceptCall(session, payload);
                break;
            case "decline-call":
                handleDeclineCall(session, payload);
                break;
            case "end-call":
                handleEndCall(session, payload);
                break;
            case "send-sms-notification":
                handleSMSNotification(session, payload);
                break;
        }
    }

    private void handleVideoCallInvitation(WebSocketSession session, Map<String, Object> payload) {
        String fromUserId = (String) payload.get("fromUserId");
        String toUserId = (String) payload.get("toUserId");
        String callType = (String) payload.get("callType"); // "video" or "audio"
        String roomId = (String) payload.get("roomId");

        // Find recipient session and send invitation
        WebSocketSession recipientSession = findSessionByUserId(toUserId);
        if (recipientSession != null && recipientSession.isOpen()) {
            sendMessage(recipientSession, Map.of(
                "type", "incoming-call",
                "fromUserId", fromUserId,
                "callType", callType,
                "roomId", roomId,
                "timestamp", System.currentTimeMillis()
            ));
            log.info("Call invitation sent from {} to {}", fromUserId, toUserId);
        }
    }
}
```

### Security Implementation

#### JWT Authentication

```java
// WebSocket authentication check
private void handleAuthentication(WebSocketSession session, Map<String, Object> payload) {
    String token = (String) payload.get("token");
    if (jwtTokenProvider.validateToken(token)) {
        Claims claims = jwtTokenProvider.getClaims(token);
        String email = claims.getSubject();
        String role = claims.get("role", String.class);

        // Store authenticated user info
        session.getAttributes().put("authenticated", true);
        session.getAttributes().put("email", email);
        session.getAttributes().put("role", role);

        userSessions.put(userId, session);
        connectionService.saveConnection(session.getId(), email, userId, "authenticated");
    }
}
```

#### CORS Configuration

```properties
# application.properties
careconnect.websocket.allowed-origins=http://localhost:*,https://*.careconnect.com
careconnect.websocket.connection-ttl-minutes=30
```

### Connection Management

#### WebSocket Connection Entity

```java
// model/WebSocketConnection.java
@Entity
@Table(name = "websocket_connections")
public class WebSocketConnection {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true)
    private String connectionId;

    @Column(nullable = false)
    private String userEmail;

    private Long userId;

    @Enumerated(EnumType.STRING)
    private SubscriptionType subscriptionType; // email-verification, authenticated, notifications

    @Enumerated(EnumType.STRING)
    private ConnectionType connectionType; // LOCAL, AWS

    private LocalDateTime connectedAt;
    private LocalDateTime lastActivityAt;
    private LocalDateTime expiresAt;
    private Boolean isActive = true;
}
```

#### Connection Service

```java
// service/WebSocketConnectionService.java
@Service
@Transactional
public class WebSocketConnectionService {

    public void saveConnection(String connectionId, String email, Long userId, String subscriptionType) {
        WebSocketConnection connection = new WebSocketConnection();
        connection.setConnectionId(connectionId);
        connection.setUserEmail(email);
        connection.setUserId(userId);
        connection.setSubscriptionType(SubscriptionType.valueOf(subscriptionType.toUpperCase()));
        connection.setConnectionType(detectConnectionType());
        connection.setConnectedAt(LocalDateTime.now());
        connection.setExpiresAt(LocalDateTime.now().plusMinutes(getConnectionTTL()));
        connection.setIsActive(true);

        repository.save(connection);
    }

    @Scheduled(fixedRate = 300000) // Every 5 minutes
    public void cleanupExpiredConnections() {
        List<WebSocketConnection> expired = repository.findExpiredConnections(LocalDateTime.now());
        expired.forEach(conn -> {
            conn.setIsActive(false);
            repository.save(conn);
        });
        log.info("Cleaned up {} expired WebSocket connections", expired.size());
    }
}
```

### REST API Integration

#### WebSocket Controller

```java
// controller/WebSocketController.java
@RestController
@RequestMapping("/api/websocket")
@PreAuthorize("hasAnyRole('PATIENT', 'CAREGIVER', 'FAMILY_MEMBER', 'ADMIN')")
public class WebSocketController {

    @PostMapping("/call-invitation")
    public ResponseEntity<String> sendCallInvitation(@RequestBody CallInvitationRequest request) {
        WebSocketSession recipientSession = webSocketHandler.getSessionByUserId(request.getToUserId());
        if (recipientSession != null && recipientSession.isOpen()) {
            webSocketHandler.sendMessage(recipientSession, Map.of(
                "type", "incoming-call",
                "fromUserId", request.getFromUserId(),
                "callType", request.getCallType(),
                "roomId", request.getRoomId()
            ));
            return ResponseEntity.ok("Call invitation sent");
        }
        return ResponseEntity.status(404).body("User not online");
    }

    @PostMapping("/medication-reminder")
    @PreAuthorize("hasAnyRole('CAREGIVER', 'ADMIN')")
    public ResponseEntity<String> sendMedicationReminder(@RequestBody MedicationReminderRequest request) {
        broadcastToPatient(request.getPatientId(), "medication-reminder", Map.of(
            "medicationName", request.getMedicationName(),
            "dosage", request.getDosage(),
            "timeToTake", request.getTimeToTake(),
            "instructions", request.getInstructions()
        ));
        return ResponseEntity.ok("Medication reminder sent");
    }

    @PostMapping("/emergency-alert")
    @PreAuthorize("hasAnyRole('PATIENT', 'CAREGIVER', 'ADMIN')")
    public ResponseEntity<String> sendEmergencyAlert(@RequestBody EmergencyAlertRequest request) {
        // High-priority emergency broadcast
        broadcastToUsersByRole(request.getPatientId(), "emergency-alert", Map.of(
            "alertType", request.getAlertType(),
            "message", request.getMessage(),
            "location", request.getLocation(),
            "priority", "CRITICAL"
        ), List.of("CAREGIVER", "FAMILY_MEMBER", "ADMIN"));

        return ResponseEntity.ok("Emergency alert broadcasted");
    }

    @GetMapping("/online-users")
    @PreAuthorize("hasAnyRole('CAREGIVER', 'ADMIN')")
    public ResponseEntity<List<OnlineUserInfo>> getOnlineUsers() {
        List<OnlineUserInfo> onlineUsers = webSocketHandler.getOnlineUsers();
        return ResponseEntity.ok(onlineUsers);
    }
}
```

### Client-Side Integration (Flutter)

#### WebSocket Service

```dart
// services/websocket_backend_service.dart
class CareConnectWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _streamSubscription;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<void> connect() async {
    try {
      final wsUrl = _getWebSocketUrl();
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _streamSubscription = _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          _messageController.add(data);
          _handleMessage(data);
        },
        onError: (error) => _handleError(error),
        onDone: () => _handleDisconnection(),
      );

      // Authenticate after connection
      await _authenticate();

    } catch (e) {
      throw WebSocketException('Connection failed: $e');
    }
  }

  Future<void> _authenticate() async {
    final token = await _getAuthToken();
    final userId = await _getCurrentUserId();

    final authMessage = {
      'type': 'authenticate',
      'token': token,
      'userId': userId,
    };

    _channel?.sink.add(jsonEncode(authMessage));
  }

  void sendMoodPainLog(int mood, int pain, String notes) {
    final message = {
      'type': 'mood-pain-log-update',
      'mood': mood,
      'pain': pain,
      'notes': notes,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _channel?.sink.add(jsonEncode(message));
  }

  void _handleMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'authentication-success':
        _onAuthenticationSuccess(data);
        break;
      case 'incoming-call':
        _showIncomingCallDialog(data);
        break;
      case 'medication-reminder':
        _showMedicationReminder(data);
        break;
      case 'emergency-alert':
        _showEmergencyAlert(data);
        break;
      case 'ai-chat-notification':
        _handleAIChatResponse(data);
        break;
    }
  }
}
```

### AWS Integration

#### AWS WebSocket Service

```java
// service/AwsWebSocketService.java
@Service
@ConditionalOnProperty(name = "careconnect.websocket.mode", havingValue = "aws")
public class AwsWebSocketService {

    @Value("${careconnect.websocket.aws.api-gateway-endpoint}")
    private String apiGatewayEndpoint;

    private final AmazonApiGatewayManagementApiClientBuilder clientBuilder;

    public void sendMessageToConnection(String connectionId, Object message) {
        try {
            AmazonApiGatewayManagementApi client = clientBuilder
                .withEndpointConfiguration(new EndpointConfiguration(apiGatewayEndpoint, "us-east-1"))
                .build();

            PostToConnectionRequest request = new PostToConnectionRequest()
                .withConnectionId(connectionId)
                .withData(ByteBuffer.wrap(objectMapper.writeValueAsBytes(message)));

            client.postToConnection(request);
        } catch (Exception e) {
            log.error("Failed to send message to AWS WebSocket connection {}", connectionId, e);
        }
    }

    public void broadcastToAllConnections(Object message) {
        List<WebSocketConnection> activeConnections = connectionRepository.findActiveAWSConnections();

        activeConnections.parallelStream().forEach(conn ->
            sendMessageToConnection(conn.getConnectionId(), message)
        );
    }
}
```

### Healthcare-Specific Message Types

The system supports specialized healthcare message types:

```java
// Healthcare-specific WebSocket messages
public enum HealthcareMessageType {
    AI_CHAT_NOTIFICATION,           // AI assistant responses
    MOOD_PAIN_LOG_UPDATE,          // Patient mood/pain tracking
    MEDICATION_REMINDER,           // Medication schedules
    VITAL_SIGNS_ALERT,            // Critical health alerts
    EMERGENCY_ALERT,              // Emergency SOS calls
    FAMILY_MEMBER_REQUEST,        // Family connection requests
    APPOINTMENT_REMINDER,         // Healthcare appointments
    FALL_DETECTION_ALERT,         // Fall detection from IoT devices
    MEDICATION_ADHERENCE_UPDATE,  // Medication compliance tracking
    HEALTH_GOAL_PROGRESS,         // Patient health goal updates
}
```

This comprehensive WebSocket implementation provides real-time communication capabilities specifically tailored for healthcare applications, with robust security, scalable architecture, and seamless integration between development and production environments.

## AI Integration

CareConnect integrates advanced AI capabilities using **DeepSeek** as the primary AI provider through **LangChain4j** and **Spring AI** frameworks. The system provides healthcare-focused AI chat assistance, document processing, and medical data analysis.

### Architecture Overview

The AI integration follows a dual-framework approach:
- **LangChain4j**: Primary AI framework for chat functionality and memory management
- **Spring AI**: Structured data extraction and document processing
- **DeepSeek**: Cost-effective AI provider with OpenAI-compatible API
- **Security Layer**: Comprehensive input/output sanitization and governance controls

### AI Configuration

#### Main Configuration Class

```java
// config/AIChatServiceConfig.java
@Configuration
@ConditionalOnProperty(name = "careconnect.deepseek.enabled", havingValue = "true", matchIfMissing = true)
public class AIChatServiceConfig {

    @Value("${deepseek.api.key}")
    private String deepSeekApiKey;

    @Value("${deepseek.api.url:https://api.deepseek.com/v1}")
    private String deepSeekApiUrl;

    @Bean
    public ChatModel chatModel() {
        return OpenAiChatModel.builder()
            .apiKey(deepSeekApiKey)
            .baseUrl(deepSeekApiUrl)
            .modelName("deepseek-chat")
            .temperature(0.7)
            .maxTokens(2048)
            .build();
    }

    @Bean
    public SpringAIChatModel springAIChatModel() {
        return new OpenAiChatModel(
            OpenAiApi.builder()
                .apiKey(deepSeekApiKey)
                .baseUrl(deepSeekApiUrl)
                .build()
        );
    }
}
```

#### Configuration Properties

```properties
# AI Service Configuration
ai.model.provider=deepseek
deepseek.api.key=${DEEPSEEK_API_KEY:your-api-key}
deepseek.api.url=https://api.deepseek.com/v1
careconnect.deepseek.enabled=true

# Spring AI Configuration
spring.ai.openai.api-key=${DEEPSEEK_API_KEY}
spring.ai.openai.base-url=https://api.deepseek.com
spring.ai.openai.chat.options.model=deepseek-chat
spring.ai.openai.chat.options.temperature=0.7
spring.ai.openai.chat.options.max-tokens=2048
```

### Core AI Services

#### DefaultAIChatService - Main Chat Implementation

```java
// service/DefaultAIChatService.java
@Service
@ConditionalOnProperty(name = "careconnect.deepseek.enabled", havingValue = "true", matchIfMissing = true)
public class DefaultAIChatService implements AIChatService {

    private final ChatModel chatModel;
    private final ChatMemoryFactory chatMemoryFactory;
    private final InputSanitizationService inputSanitizationService;
    private final ResponseSanitizationService responseSanitizationService;
    private final LangChainGovernanceService governanceService;

    public AiChatResponse sendMessage(Long userId, String message, Long patientId) {
        // Governance checks
        governanceService.checkRateLimit(userId);
        governanceService.validateMessageLength(message);

        // Sanitize input
        String sanitizedMessage = inputSanitizationService.sanitize(message);

        // Build context with medical data
        String medicalContext = buildMedicalContext(patientId);

        // Create AI chain with memory
        ConversationalRetrievalChain chain = ConversationalRetrievalChain.builder()
            .chatModel(chatModel)
            .chatMemory(chatMemoryFactory.createMemory(userId))
            .systemPrompt(buildSystemPrompt(medicalContext))
            .build();

        // Generate response
        String aiResponse = chain.execute(sanitizedMessage);

        // Sanitize response
        String sanitizedResponse = responseSanitizationService.sanitize(aiResponse);

        // Save conversation
        return saveChatMessage(userId, patientId, sanitizedMessage, sanitizedResponse);
    }

    private String buildMedicalContext(Long patientId) {
        PatientMedicalData medicalData = medicalDataService.getPatientData(patientId);

        StringBuilder context = new StringBuilder();
        context.append("Patient Medical Context:\n");

        if (medicalData.hasVitals()) {
            context.append("Recent Vitals: ").append(medicalData.getVitalsSummary()).append("\n");
        }

        if (medicalData.hasMedications()) {
            context.append("Current Medications: ").append(medicalData.getMedicationsList()).append("\n");
        }

        if (medicalData.hasAllergies()) {
            context.append("Known Allergies: ").append(medicalData.getAllergiesList()).append("\n");
        }

        return context.toString();
    }

    private String buildSystemPrompt(String medicalContext) {
        return """
            You are a healthcare assistant for CareConnect. Guidelines:
            1. Provide information and support, never diagnose or prescribe
            2. Encourage users to consult healthcare professionals for medical decisions
            3. Use the provided medical context to give relevant, personalized responses
            4. Be empathetic, professional, and clear
            5. If unsure about medical information, recommend consulting a doctor

            %s
            """.formatted(medicalContext);
    }
}
```

#### LlmExtractionService - Document Processing

```java
// service/invoice/LlmExtractionService.java
@Service
@ConditionalOnProperty(name = "careconnect.deepseek.enabled", havingValue = "true", matchIfMissing = true)
public class LlmExtractionService {

    private final ChatModel chatModel; // Spring AI ChatModel

    public InvoiceData extractInvoiceData(String rawInvoiceText) {
        String extractionPrompt = """
            Extract structured data from this healthcare invoice. Return JSON with:
            - provider: {name, address, phone, email, taxId}
            - patient: {name, address, phone, email, dateOfBirth, patientId}
            - services: [{code, description, quantity, unitPrice, totalPrice, date}]
            - payments: [{method, amount, date, confirmationNumber}]
            - totals: {subtotal, tax, discount, totalAmount, amountDue}
            - dates: {serviceDate, dueDate, issueDate}
            - aiSummary: Brief summary of the invoice
            - recommendedActions: Array of patient action recommendations

            Invoice text:
            %s
            """.formatted(rawInvoiceText);

        ChatResponse response = chatModel.call(new Prompt(extractionPrompt));
        String jsonResponse = response.getResult().getOutput().getContent();

        try {
            return objectMapper.readValue(jsonResponse, InvoiceData.class);
        } catch (JsonProcessingException e) {
            throw new AIProcessingException("Failed to parse AI response: " + e.getMessage());
        }
    }

    public String generateInvoiceSummary(InvoiceData invoiceData) {
        String summaryPrompt = """
            Create a patient-friendly summary of this healthcare invoice:

            Provider: %s
            Services: %s
            Total Amount: $%.2f
            Due Date: %s

            Include:
            1. What services were provided
            2. Payment amount and due date
            3. Any action items for the patient
            4. Payment options if applicable
            """.formatted(
                invoiceData.getProvider().getName(),
                invoiceData.getServicesDescription(),
                invoiceData.getTotals().getTotalAmount(),
                invoiceData.getDates().getDueDate()
            );

        ChatResponse response = chatModel.call(new Prompt(summaryPrompt));
        return response.getResult().getOutput().getContent();
    }
}
```

### Chat Memory Management

#### ChatMemoryFactory

```java
// service/memory/ChatMemoryFactory.java
@Service
public class ChatMemoryFactory {

    @Value("${ai.chat.memory.timeout:900}") // 15 minutes
    private long memoryTimeoutSeconds;

    @Value("${ai.chat.memory.max-messages:15}")
    private int maxMessages;

    public ChatMemory createMemory(Long userId) {
        return MessageWindowChatMemory.builder()
            .id(userId)
            .maxMessages(maxMessages)
            .chatMemoryStore(createMemoryStore(userId))
            .build();
    }

    private ChatMemoryStore createMemoryStore(Long userId) {
        return new DatabaseChatMemoryStore(userId, memoryTimeoutSeconds);
    }
}

// Custom database-backed memory store
public class DatabaseChatMemoryStore implements ChatMemoryStore {

    private final ChatMessageRepository chatMessageRepository;
    private final Long userId;
    private final long timeoutSeconds;

    @Override
    public List<ChatMessage> getMessages(Object memoryId) {
        LocalDateTime cutoff = LocalDateTime.now().minusSeconds(timeoutSeconds);

        return chatMessageRepository
            .findByUserIdAndCreatedAtAfterOrderByCreatedAt(userId, cutoff)
            .stream()
            .map(this::convertToLangChainMessage)
            .collect(Collectors.toList());
    }

    @Override
    public void updateMessages(Object memoryId, List<ChatMessage> messages) {
        // Save new messages to database
        messages.forEach(message -> {
            if (!messageExists(message)) {
                saveChatMessage(message);
            }
        });
    }
}
```

### Security and Governance

#### LangChainGovernanceService

```java
// service/LangChainGovernanceService.java
@Service
public class LangChainGovernanceService {

    private static final int MAX_REQUESTS_PER_MINUTE = 10;
    private static final int MAX_REQUESTS_PER_HOUR = 60;
    private static final int MAX_MESSAGE_LENGTH = 4000;

    private final RedisTemplate<String, Object> redisTemplate;

    public void checkRateLimit(Long userId) {
        String minuteKey = "rate_limit:user:" + userId + ":minute:" +
                          (System.currentTimeMillis() / 60000);
        String hourKey = "rate_limit:user:" + userId + ":hour:" +
                        (System.currentTimeMillis() / 3600000);

        Long minuteCount = redisTemplate.opsForValue().increment(minuteKey);
        if (minuteCount == 1) {
            redisTemplate.expire(minuteKey, Duration.ofMinutes(1));
        }

        Long hourCount = redisTemplate.opsForValue().increment(hourKey);
        if (hourCount == 1) {
            redisTemplate.expire(hourKey, Duration.ofHours(1));
        }

        if (minuteCount > MAX_REQUESTS_PER_MINUTE) {
            throw new RateLimitExceededException("Too many requests per minute");
        }

        if (hourCount > MAX_REQUESTS_PER_HOUR) {
            throw new RateLimitExceededException("Too many requests per hour");
        }
    }

    public void validateMessageLength(String message) {
        if (message.length() > MAX_MESSAGE_LENGTH) {
            throw new MessageTooLongException(
                "Message exceeds maximum length of " + MAX_MESSAGE_LENGTH + " characters"
            );
        }
    }

    public void auditAIInteraction(Long userId, String input, String output,
                                  String model, Long tokens) {
        AiInteractionAudit audit = AiInteractionAudit.builder()
            .userId(userId)
            .input(input)
            .output(output)
            .model(model)
            .tokensUsed(tokens)
            .timestamp(LocalDateTime.now())
            .build();

        auditRepository.save(audit);
    }
}
```

#### Input/Output Sanitization

```java
// service/InputSanitizationService.java
@Service
public class InputSanitizationService {

    private static final List<String> BLOCKED_PATTERNS = List.of(
        "(?i).*diagnose.*",
        "(?i).*prescribe.*medication.*",
        "(?i).*medical advice.*",
        "(?i).*ignore.*previous.*instructions.*"
    );

    public String sanitize(String input) {
        // Remove potentially harmful patterns
        String sanitized = input;

        for (String pattern : BLOCKED_PATTERNS) {
            sanitized = sanitized.replaceAll(pattern, "[FILTERED]");
        }

        // Limit length
        if (sanitized.length() > 4000) {
            sanitized = sanitized.substring(0, 4000) + "...";
        }

        // Basic XSS protection
        sanitized = StringEscapeUtils.escapeHtml4(sanitized);

        return sanitized;
    }
}

// service/ResponseSanitizationService.java
@Service
public class ResponseSanitizationService {

    private static final List<String> MEDICAL_DISCLAIMERS = List.of(
        "Please consult with your healthcare provider",
        "This is not medical advice",
        "Always verify with a medical professional"
    );

    public String sanitize(String aiResponse) {
        // Add medical disclaimers if response contains medical terms
        if (containsMedicalTerms(aiResponse)) {
            aiResponse += "\n\n⚠️ " + getRandomDisclaimer();
        }

        // Remove any potential harmful content
        aiResponse = removePotentiallyHarmfulContent(aiResponse);

        return aiResponse;
    }

    private boolean containsMedicalTerms(String response) {
        return response.toLowerCase().matches(
            ".*(symptom|treatment|medication|diagnosis|dosage|prescription).*"
        );
    }
}
```

### User AI Configuration

#### UserAIConfig Entity

```java
// model/UserAIConfig.java
@Entity
@Table(name = "user_ai_config")
public class UserAIConfig {

    @Id
    private Long userId;

    @Column(name = "ai_provider")
    @Enumerated(EnumType.STRING)
    private AIProvider aiProvider = AIProvider.DEEPSEEK;

    @Column(name = "model_name")
    private String modelName = "deepseek-chat";

    @Column(name = "include_vitals")
    private Boolean includeVitals = true;

    @Column(name = "include_medications")
    private Boolean includeMedications = true;

    @Column(name = "include_notes")
    private Boolean includeNotes = false;

    @Column(name = "include_allergies")
    private Boolean includeAllergies = true;

    @Column(name = "max_tokens")
    private Integer maxTokens = 2048;

    @Column(name = "temperature")
    private Double temperature = 0.7;

    @Column(name = "conversation_history_limit")
    private Integer conversationHistoryLimit = 10;

    @Column(name = "custom_system_prompt")
    private String customSystemPrompt;

    // Default configurations for different user types
    public static UserAIConfig defaultPatientConfig(Long userId) {
        UserAIConfig config = new UserAIConfig();
        config.setUserId(userId);
        config.setCustomSystemPrompt(DEFAULT_PATIENT_PROMPT);
        return config;
    }

    public static UserAIConfig defaultCaregiverConfig(Long userId) {
        UserAIConfig config = new UserAIConfig();
        config.setUserId(userId);
        config.setIncludeNotes(true);
        config.setConversationHistoryLimit(20);
        config.setCustomSystemPrompt(DEFAULT_CAREGIVER_PROMPT);
        return config;
    }

    private static final String DEFAULT_PATIENT_PROMPT = """
        You are a helpful healthcare assistant. Provide information and support
        while encouraging consultation with healthcare professionals for medical decisions.
        Be empathetic, clear, and never provide diagnostic or prescriptive advice.
        """;

    private static final String DEFAULT_CAREGIVER_PROMPT = """
        You are an AI assistant for healthcare professionals. Provide clinical
        insights and information while emphasizing professional judgment.
        Include relevant patient data context in your responses.
        """;
}
```

### API Endpoints

#### AIChatController

```java
// controller/AIChatController.java
@RestController
@RequestMapping("/v1/api/ai-chat")
@PreAuthorize("hasRole('PATIENT') or hasRole('CAREGIVER')")
public class AIChatController {

    private final AIChatService aiChatService;
    private final UserAIConfigService configService;

    @PostMapping("/chat")
    @Operation(summary = "Send message to AI assistant")
    public ResponseEntity<AiChatResponse> sendMessage(
            @Valid @RequestBody AiChatRequest request,
            Authentication authentication) {

        Long userId = getUserId(authentication);
        AiChatResponse response = aiChatService.sendMessage(
            userId, request.getMessage(), request.getPatientId());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/conversations/{patientId}")
    @Operation(summary = "Get patient conversations")
    public ResponseEntity<List<ChatConversationResponse>> getConversations(
            @PathVariable Long patientId,
            Authentication authentication) {

        Long userId = getUserId(authentication);
        // Verify access to patient data
        patientAccessService.verifyAccess(userId, patientId);

        List<ChatConversationResponse> conversations =
            aiChatService.getConversations(patientId);

        return ResponseEntity.ok(conversations);
    }

    @GetMapping("/config")
    @Operation(summary = "Get AI configuration")
    public ResponseEntity<UserAIConfig> getConfig(Authentication authentication) {
        Long userId = getUserId(authentication);
        UserAIConfig config = configService.getUserConfig(userId);
        return ResponseEntity.ok(config);
    }

    @PostMapping("/config")
    @Operation(summary = "Update AI configuration")
    public ResponseEntity<UserAIConfig> updateConfig(
            @Valid @RequestBody UserAIConfig config,
            Authentication authentication) {

        Long userId = getUserId(authentication);
        config.setUserId(userId);
        UserAIConfig savedConfig = configService.saveConfig(config);

        return ResponseEntity.ok(savedConfig);
    }
}
```

### Database Schema

#### AI-Related Tables

```sql
-- User AI Configuration
CREATE TABLE user_ai_config (
    user_id BIGINT PRIMARY KEY,
    ai_provider VARCHAR(50) DEFAULT 'DEEPSEEK',
    model_name VARCHAR(100) DEFAULT 'deepseek-chat',
    include_vitals BOOLEAN DEFAULT TRUE,
    include_medications BOOLEAN DEFAULT TRUE,
    include_notes BOOLEAN DEFAULT FALSE,
    include_allergies BOOLEAN DEFAULT TRUE,
    max_tokens INTEGER DEFAULT 2048,
    temperature DECIMAL(3,2) DEFAULT 0.70,
    conversation_history_limit INTEGER DEFAULT 10,
    custom_system_prompt TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Chat Conversations
CREATE TABLE chat_conversations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    patient_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    title VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Chat Messages
CREATE TABLE chat_messages (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    conversation_id BIGINT NOT NULL,
    message_type ENUM('USER', 'AI') NOT NULL,
    content TEXT NOT NULL,
    tokens_used INTEGER,
    model_used VARCHAR(100),
    processing_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES chat_conversations(id) ON DELETE CASCADE
);

-- AI Interaction Audit
CREATE TABLE ai_interaction_audit (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    input_text TEXT,
    output_text TEXT,
    model_used VARCHAR(100),
    tokens_used INTEGER,
    processing_time_ms INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX idx_chat_conversations_patient_user ON chat_conversations(patient_id, user_id);
CREATE INDEX idx_chat_messages_conversation_created ON chat_messages(conversation_id, created_at);
CREATE INDEX idx_ai_audit_user_timestamp ON ai_interaction_audit(user_id, timestamp);
```

### Development and Testing

#### Mock AI Service for Development

```java
// service/MockAIChatService.java
@Service
@Profile("dev")
@ConditionalOnProperty(name = "careconnect.deepseek.enabled", havingValue = "false")
public class MockAIChatService implements AIChatService {

    @Override
    public AiChatResponse sendMessage(Long userId, String message, Long patientId) {
        // Simulate processing time
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        String mockResponse = generateMockResponse(message);

        return AiChatResponse.builder()
            .response(mockResponse)
            .tokensUsed(calculateMockTokens(message, mockResponse))
            .model("mock-model")
            .processingTimeMs(1000L)
            .build();
    }

    private String generateMockResponse(String message) {
        if (message.toLowerCase().contains("pain")) {
            return "I understand you're experiencing pain. Please describe your pain level on a scale of 1-10 and consider speaking with your healthcare provider if it persists.";
        } else if (message.toLowerCase().contains("medication")) {
            return "For medication questions, please consult with your pharmacist or healthcare provider. They can provide the most accurate and safe guidance for your specific situation.";
        } else {
            return "Thank you for your message. I'm here to provide general health information and support. For specific medical advice, please consult with your healthcare provider.";
        }
    }
}
```

The CareConnect AI integration provides a comprehensive, healthcare-focused AI solution with robust security, flexible configuration, and production-ready features for both patient support and clinical assistance.

## Device Integration

### Wearable Device Integration

```dart
// services/device_integration_service.dart
class DeviceIntegrationService {
  final HealthDataService _healthDataService;

  Future<void> syncFitbitData() async {
    try {
      final fitbitData = await FitbitConnector.instance.getTodaysActivitySummary();

      // Convert Fitbit data to our format
      final healthData = HealthData(
        steps: fitbitData.summary?.steps,
        heartRate: fitbitData.summary?.restingHeartRate,
        calories: fitbitData.summary?.caloriesOut,
        distance: fitbitData.summary?.distances?.first.distance,
        timestamp: DateTime.now(),
      );

      await _healthDataService.saveHealthData(healthData);
    } catch (e) {
      throw DeviceIntegrationException('Fitbit sync failed: $e');
    }
  }

  Future<void> setupDeviceSync() async {
    // Setup periodic sync
    Timer.periodic(Duration(hours: 1), (timer) {
      syncAllConnectedDevices();
    });
  }

  Future<void> syncAllConnectedDevices() async {
    final connectedDevices = await getConnectedDevices();

    for (final device in connectedDevices) {
      switch (device.type) {
        case DeviceType.fitbit:
          await syncFitbitData();
          break;
        case DeviceType.appleWatch:
          await syncAppleHealthData();
          break;
        case DeviceType.bloodPressureMonitor:
          await syncBloodPressureData();
          break;
      }
    }
  }
}
```

## USPS Integration

CareConnect integrates with the USPS Informed Delivery service to help patients and caregivers track incoming mail and packages. This feature is particularly valuable for elderly patients who may miss important medical correspondence or medication deliveries.

### Architecture Overview

The USPS integration provides:
- **Mail Digest Retrieval**: Fetches daily mail summaries from USPS Informed Delivery
- **Multi-Provider Support**: Works with Gmail and Outlook for USPS email parsing
- **Caching Layer**: Reduces API calls with intelligent caching
- **Mock Fallback**: Provides test data when email integration is unavailable

**Note**: This integration currently requires Google OAuth authentication for Gmail access, which is still pending configuration.

### Backend Implementation

#### USPSDigestService - Core Service

```java
// service/USPSDigestService.java
@Service
@RequiredArgsConstructor
public class USPSDigestService {
    private final EmailCredentialRepo credRepo;
    private final USPSDigestCacheRepo cacheRepo;
    private final GmailClient gmailClient;
    private final OutlookClient outlookClient;
    private final GmailParser gmailParser;
    private final OutlookParser outlookParser;

    public Optional<USPSDigest> latestForUser(String userId) {
        // 1. Check cache first (6-hour TTL)
        var cached = cacheRepo.findFirstByUserIdAndExpiresAtAfterOrderByDigestDateDesc(userId, Instant.now());
        if (cached.isPresent()) {
            try {
                return Optional.of(objectMapper.readValue(cached.get().getPayloadJson(), USPSDigest.class));
            } catch (Exception ignored) {}
        }

        // 2. Try Gmail integration
        var gmail = credRepo.findFirstByUserIdAndProviderOrderByIdDesc(userId, EmailCredential.Provider.GMAIL);
        if (gmail.isPresent()) {
            var accessToken = decrypt(gmail.get().getAccessTokenEnc());
            var rawDigest = gmailClient.fetchLatestDigest(accessToken);
            if (rawDigest.isPresent()) {
                var digest = gmailParser.toDomain(rawDigest.get());
                cache(userId, digest);
                return Optional.of(digest);
            }
        }

        // 3. Try Outlook integration
        var outlook = credRepo.findFirstByUserIdAndProviderOrderByIdDesc(userId, EmailCredential.Provider.OUTLOOK);
        if (outlook.isPresent()) {
            var accessToken = decrypt(outlook.get().getAccessTokenEnc());
            var rawDigest = outlookClient.fetchLatestDigest(accessToken);
            if (rawDigest.isPresent()) {
                var digest = outlookParser.toDomain(rawDigest.get());
                cache(userId, digest);
                return Optional.of(digest);
            }
        }

        // 4. Mock fallback for testing and demonstration
        var mockDigest = mockDigest();
        cache(userId, mockDigest);
        return Optional.of(mockDigest);
    }

    private void cache(String userId, USPSDigest digest) {
        try {
            var cache = new USPSDigestCache();
            cache.setUserId(userId);
            cache.setDigestDate(digest.digestDate() != null ? digest.digestDate().toInstant() : Instant.now());
            cache.setPayloadJson(objectMapper.writeValueAsString(digest));
            cache.setExpiresAt(Instant.now().plus(Duration.ofHours(6))); // 6-hour cache
            cacheRepo.save(cache);
        } catch (Exception ignored) {
            // Cache failure should not affect main functionality
        }
    }

    private USPSDigest mockDigest() {
        var now = OffsetDateTime.now(ZoneOffset.UTC);
        var packageItem = new PackageItem(
            "9400100000000000000000",
            now.plusDays(1).toString(),
            ActionLinks.defaults("https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=9400100000000000000000")
        );
        var mailPiece = new MailPiece(
            "m-1",
            "ACME Bank",
            "Monthly statement",
            "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nNDAnIGhlaWdodD0nMjAnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHJlY3Qgd2lkdGg9JzQwJyBoZWlnaHQ9JzIwJyBmaWxsPSIjZGRkIi8+PC9zdmc+",
            now.toString(),
            ActionLinks.defaults(null)
        );
        return new USPSDigest(now, List.of(mailPiece), List.of(packageItem));
    }
}
```

#### USPS REST Controller

```java
// controller/USPSController.java
@RestController
@RequestMapping("/v1/api/usps")
@RequiredArgsConstructor
public class USPSController {

    private final USPSDigestService service;

    @GetMapping("/mail")
    public ResponseEntity<USPSDigest> getDigest(@AuthenticationPrincipal Jwt jwt) {
        var userId = jwt != null ? jwt.getSubject() : "demo-user"; // Fallback for testing
        var digest = service.latestForUser(userId)
            .orElseGet(() -> new USPSDigest(null, List.of(), List.of()));
        return ResponseEntity.ok(digest);
    }
}
```

#### Data Models

```java
// model/USPSDigest.java
public record USPSDigest(
    OffsetDateTime digestDate,
    List<MailPiece> mailPieces,
    List<PackageItem> packages
) {}

// model/MailPiece.java
public record MailPiece(
    String id,
    String sender,
    String subject,
    String imageUrl,
    String deliveryDate,
    ActionLinks actionLinks
) {}

// model/PackageItem.java
public record PackageItem(
    String trackingNumber,
    String expectedDelivery,
    ActionLinks actionLinks
) {}

// model/ActionLinks.java
public record ActionLinks(
    String trackingUrl,
    String detailsUrl
) {
    public static ActionLinks defaults(String trackingUrl) {
        return new ActionLinks(trackingUrl, null);
    }
}
```

### Frontend Implementation

#### InformedDeliveryService - API Client

```dart
// services/informed_delivery_service.dart
class InformedDeliveryService {
  static Future<Map<String, dynamic>> fetchInformedDelivery() async {
    final headers = await AuthTokenManager.getAuthHeaders();

    final response = await http.get(
      Uri.parse('${ApiConstants.informedDelivery}/mail'),
      headers: headers,
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception("Not authorized. Please log in again.");
    } else {
      throw Exception("Failed to fetch informed delivery data: ${response.statusCode}");
    }
  }
}

// API Constants
class ApiConstants {
  static final String _host = getBackendBaseUrl();
  static final String informedDelivery = '$_host/v1/api/usps';
}
```

#### Frontend Display Integration

```dart
// features/informed_delivery/informed_delivery_screen.dart
class InformedDeliveryScreen extends StatefulWidget {
  @override
  _InformedDeliveryScreenState createState() => _InformedDeliveryScreenState();
}

class _InformedDeliveryScreenState extends State<InformedDeliveryScreen> {
  Map<String, dynamic>? digestData;
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadInformedDelivery();
  }

  Future<void> loadInformedDelivery() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await InformedDeliveryService.fetchInformedDelivery();
      setState(() {
        digestData = data;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mail & Packages'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : error != null
          ? Center(child: Text('Error: $error'))
          : buildDigestContent(),
    );
  }

  Widget buildDigestContent() {
    if (digestData == null) return Center(child: Text('No data available'));

    return RefreshIndicator(
      onRefresh: loadInformedDelivery,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildMailPiecesSection(),
              SizedBox(height: 20),
              buildPackagesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMailPiecesSection() {
    final mailPieces = digestData!['mailPieces'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Mail', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 10),
            ...mailPieces.map((mail) => buildMailItem(mail)).toList(),
            if (mailPieces.isEmpty) Text('No mail expected today'),
          ],
        ),
      ),
    );
  }

  Widget buildPackagesSection() {
    final packages = digestData!['packages'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Package Tracking', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 10),
            ...packages.map((pkg) => buildPackageItem(pkg)).toList(),
            if (packages.isEmpty) Text('No packages being tracked'),
          ],
        ),
      ),
    );
  }
}
```

### Database Schema

```sql
-- USPS Digest Cache Table
CREATE TABLE usps_digest_cache (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(255) NOT NULL,
    digest_date TIMESTAMP NOT NULL,
    payload_json TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_user_expires (user_id, expires_at),
    INDEX idx_user_digest_date (user_id, digest_date DESC)
);

-- Email Credentials for OAuth Integration
CREATE TABLE email_credentials (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id VARCHAR(255) NOT NULL,
    provider ENUM('GMAIL', 'OUTLOOK') NOT NULL,
    access_token_enc TEXT NOT NULL,
    refresh_token_enc TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_user_provider (user_id, provider),
    INDEX idx_expires_at (expires_at)
);
```

### Configuration

#### Application Properties

```properties
# USPS Integration Settings
careconnect.usps.enabled=true
careconnect.usps.cache.ttl-hours=6
careconnect.usps.mock.enabled=${USPS_MOCK_MODE:true}

# Email Integration (Pending Google OAuth Setup)
careconnect.email.gmail.client-id=${GMAIL_CLIENT_ID:}
careconnect.email.gmail.client-secret=${GMAIL_CLIENT_SECRET:}
careconnect.email.outlook.client-id=${OUTLOOK_CLIENT_ID:}
careconnect.email.outlook.client-secret=${OUTLOOK_CLIENT_SECRET:}

# Encryption for stored credentials
careconnect.encryption.key=${ENCRYPTION_KEY:default-dev-key}
```

### Security Considerations

- **OAuth Integration**: Requires secure storage of email access tokens
- **Token Encryption**: Email credentials are encrypted at rest
- **Cache Security**: Digest data cached with user-specific keys
- **Rate Limiting**: Prevents excessive API calls to email providers

### Known Limitations

1. **Google OAuth Pending**: Gmail integration requires Google OAuth 2.0 setup
2. **Mock Data**: Currently uses mock data when email integration unavailable
3. **Email Parsing**: Depends on USPS email format consistency
4. **Cache Invalidation**: Manual refresh required for real-time updates

### Future Enhancements

- **Push Notifications**: Alert users of important mail/packages
- **OCR Integration**: Extract text from mail piece images
- **Smart Filtering**: Categorize mail by medical/financial importance
- **Medication Delivery Tracking**: Special handling for pharmacy deliveries

## Vial of Life Integration

CareConnect includes a comprehensive Vial of Life PDF generation system designed for emergency medical situations. The system creates professionally formatted emergency information documents that can be accessed by first responders via QR codes or emergency IDs.

### Architecture Overview

The Vial of Life integration provides:
- **Emergency PDF Generation**: Creates standardized emergency medical information forms
- **Patient Data Integration**: Automatically populates patient medical data
- **QR Code Access**: Public emergency access without authentication
- **Professional Formatting**: Medical-grade PDF layouts with clear typography
- **Emergency Contact Integration**: Includes family member and caregiver contacts

### Backend Implementation

#### VialOfLifePdfService - Core PDF Generation

```java
// service/VialOfLifePdfService.java
@Service
public class VialOfLifePdfService {

    private static final Logger logger = LoggerFactory.getLogger(VialOfLifePdfService.class);

    @Autowired
    private PatientService patientService;

    @Autowired
    private MedicationService medicationService;

    @Autowired
    private FamilyMemberService familyMemberService;

    /**
     * Generate a pre-filled Vial of Life PDF for a patient
     */
    public byte[] generateVialOfLifePdf(String emergencyId) throws Exception {
        logger.info("Generating Vial of Life PDF for emergency ID: {}", emergencyId);

        // Extract patient ID from emergency ID format: VIAL123456
        Long patientId = extractPatientIdFromEmergencyId(emergencyId);

        // Gather patient information
        Optional<PatientProfileDTO> patientProfile = patientService.getPatientProfile(patientId);
        if (patientProfile.isEmpty()) {
            throw new IllegalArgumentException("Patient not found for emergency ID: " + emergencyId);
        }

        // Get additional medical data
        List<MedicationDTO> medications = medicationService.getAllMedicationsForPatient(patientId);
        List<FamilyMemberLinkResponse> emergencyContacts = familyMemberService.getFamilyMembersByPatientId(patientId);

        return createProfessionalEmergencyPdf(patientProfile.get(), medications, emergencyContacts);
    }

    /**
     * Create professional emergency PDF document using Apache PDFBox
     */
    private byte[] createProfessionalEmergencyPdf(PatientProfileDTO patient,
                                                 List<MedicationDTO> medications,
                                                 List<FamilyMemberLinkResponse> emergencyContacts) throws IOException {

        ByteArrayOutputStream baos = new ByteArrayOutputStream();

        try (PDDocument document = new PDDocument()) {
            PDPage page = new PDPage();
            document.addPage(page);

            try (PDPageContentStream contentStream = new PDPageContentStream(document, page)) {
                float pageWidth = page.getMediaBox().getWidth();
                float pageHeight = page.getMediaBox().getHeight();
                float margin = 50;
                float yPosition = pageHeight - margin;

                // Draw medical cross header
                drawRedCrossHeader(contentStream, pageWidth, yPosition);
                yPosition -= 80;

                // Document title
                drawTitle(contentStream, pageWidth, yPosition);
                yPosition -= 50;

                // Patient Information Section
                yPosition = drawPatientInfoSection(contentStream, patient, margin, yPosition);
                yPosition -= 30;

                // Critical Medical Information Section
                yPosition = drawMedicalInfoSection(contentStream, patient, medications, margin, yPosition);
                yPosition -= 30;

                // Emergency Contacts Section
                yPosition = drawEmergencyContactsSection(contentStream, emergencyContacts, margin, yPosition);
                yPosition -= 40;

                // Professional footer
                drawFooter(contentStream, pageWidth, yPosition);
            }

            document.save(baos);
        }

        return baos.toByteArray();
    }

    /**
     * Draw red cross medical symbol header
     */
    private void drawRedCrossHeader(PDPageContentStream contentStream, float pageWidth, float yPosition) throws IOException {
        float crossSize = 40;
        float crossX = pageWidth / 2 - crossSize / 2;
        float crossY = yPosition - crossSize;

        // Draw red medical cross
        contentStream.setNonStrokingColor(Color.RED);
        contentStream.addRect(crossX - 5, crossY + crossSize/3, crossSize + 10, crossSize/3);
        contentStream.fill();
        contentStream.addRect(crossX + crossSize/3, crossY - 5, crossSize/3, crossSize + 10);
        contentStream.fill();
        contentStream.setNonStrokingColor(Color.BLACK);

        // Header text
        contentStream.beginText();
        contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 18);
        String headerText = "EMERGENCY MEDICAL INFORMATION";
        float textWidth = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD).getStringWidth(headerText) / 1000 * 18;
        contentStream.newLineAtOffset((pageWidth - textWidth) / 2, crossY - 25);
        contentStream.showText(headerText);
        contentStream.endText();
    }

    /**
     * Draw patient information section with clean formatting
     */
    private float drawPatientInfoSection(PDPageContentStream contentStream, PatientProfileDTO patient, float margin, float yPosition) throws IOException {
        drawSectionTitle(contentStream, "PATIENT INFORMATION", margin, yPosition);
        yPosition -= 25;

        yPosition = drawInfoLine(contentStream, "Name:", patient.firstName() + " " + patient.lastName(), margin, yPosition);

        if (patient.dob() != null) {
            try {
                LocalDate dobDate = LocalDate.parse(patient.dob());
                int age = Period.between(dobDate, LocalDate.now()).getYears();
                yPosition = drawInfoLine(contentStream, "Date of Birth:", patient.dob() + " (Age: " + age + ")", margin, yPosition);
            } catch (Exception e) {
                yPosition = drawInfoLine(contentStream, "Date of Birth:", patient.dob(), margin, yPosition);
            }
        }

        if (patient.gender() != null) {
            yPosition = drawInfoLine(contentStream, "Gender:", patient.gender().toString(), margin, yPosition);
        }

        if (patient.phone() != null) {
            yPosition = drawInfoLine(contentStream, "Phone:", patient.phone(), margin, yPosition);
        }

        return yPosition;
    }

    /**
     * Draw critical medical information with highlighted allergies
     */
    private float drawMedicalInfoSection(PDPageContentStream contentStream, PatientProfileDTO patient, List<MedicationDTO> medications, float margin, float yPosition) throws IOException {
        drawSectionTitle(contentStream, "CRITICAL MEDICAL INFORMATION", margin, yPosition);
        yPosition -= 25;

        // Critical Allergies (highlighted in red)
        if (patient.allergies() != null && !patient.allergies().isEmpty()) {
            contentStream.beginText();
            contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 11);
            contentStream.setNonStrokingColor(Color.RED);
            contentStream.newLineAtOffset(margin, yPosition);
            contentStream.showText("CRITICAL ALLERGIES:");
            contentStream.endText();
            contentStream.setNonStrokingColor(Color.BLACK);
            yPosition -= 18;

            for (var allergy : patient.allergies()) {
                String allergyText = "• " + allergy.allergen();
                if (allergy.severity() != null) {
                    allergyText += " [" + allergy.severity().toString() + "]";
                }
                if (allergy.reaction() != null) {
                    allergyText += " - " + allergy.reaction();
                }
                yPosition = drawBulletPoint(contentStream, allergyText, margin + 10, yPosition);
            }
            yPosition -= 10;
        }

        // Current Active Medications
        if (medications != null && !medications.isEmpty()) {
            List<MedicationDTO> activeMeds = medications.stream()
                .filter(MedicationDTO::isActive)
                .toList();

            if (!activeMeds.isEmpty()) {
                yPosition = drawInfoLine(contentStream, "Current Medications:", "", margin, yPosition);
                yPosition -= 5;

                for (MedicationDTO med : activeMeds) {
                    String medText = "• " + med.medicationName();
                    if (med.dosage() != null) {
                        medText += " - " + med.dosage();
                    }
                    if (med.frequency() != null) {
                        medText += " (" + med.frequency() + ")";
                    }
                    yPosition = drawBulletPoint(contentStream, medText, margin + 10, yPosition);
                }
            }
        }

        return yPosition;
    }

    /**
     * Draw emergency contacts section
     */
    private float drawEmergencyContactsSection(PDPageContentStream contentStream, List<FamilyMemberLinkResponse> emergencyContacts, float margin, float yPosition) throws IOException {
        drawSectionTitle(contentStream, "EMERGENCY CONTACTS", margin, yPosition);
        yPosition -= 25;

        if (emergencyContacts != null && !emergencyContacts.isEmpty()) {
            for (FamilyMemberLinkResponse contact : emergencyContacts) {
                String contactText = contact.familyMemberName();
                if (contact.relationship() != null) {
                    contactText += " (" + contact.relationship() + ")";
                }
                yPosition = drawInfoLine(contentStream, "Contact:", contactText, margin, yPosition);

                if (contact.familyMemberEmail() != null) {
                    yPosition = drawInfoLine(contentStream, "Email:", contact.familyMemberEmail(), margin, yPosition);
                }
                yPosition -= 5;
            }
        } else {
            yPosition = drawInfoLine(contentStream, "", "No emergency contacts on file", margin, yPosition);
        }

        return yPosition;
    }

    /**
     * Draw professional footer with generation info
     */
    private void drawFooter(PDPageContentStream contentStream, float pageWidth, float yPosition) throws IOException {
        // Draw separator line
        contentStream.setStrokingColor(Color.GRAY);
        contentStream.moveTo(50, yPosition + 10);
        contentStream.lineTo(pageWidth - 50, yPosition + 10);
        contentStream.stroke();

        // Footer information
        contentStream.beginText();
        contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 9);
        contentStream.setNonStrokingColor(Color.GRAY);
        contentStream.newLineAtOffset(50, yPosition - 10);
        contentStream.showText("This document contains confidential medical information.");
        contentStream.endText();

        contentStream.beginText();
        contentStream.newLineAtOffset(50, yPosition - 25);
        contentStream.showText("Generated by CareConnect Emergency Information System - For medical emergencies, contact 911 immediately.");
        contentStream.endText();

        // Generation timestamp
        contentStream.beginText();
        contentStream.newLineAtOffset(pageWidth - 200, yPosition - 10);
        contentStream.showText("Generated: " + LocalDate.now().format(DateTimeFormatter.ofPattern("MM/dd/yyyy")));
        contentStream.endText();

        contentStream.setNonStrokingColor(Color.BLACK);
    }

    /**
     * Helper method to draw section titles with background
     */
    private void drawSectionTitle(PDPageContentStream contentStream, String title, float margin, float yPosition) throws IOException {
        // Background rectangle for section title
        contentStream.setNonStrokingColor(new Color(240, 240, 240));
        contentStream.addRect(margin - 5, yPosition - 15, 500, 20);
        contentStream.fill();

        // Title text
        contentStream.beginText();
        contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 12);
        contentStream.setNonStrokingColor(Color.BLACK);
        contentStream.newLineAtOffset(margin, yPosition - 12);
        contentStream.showText(title);
        contentStream.endText();
    }

    /**
     * Helper method for formatting information lines
     */
    private float drawInfoLine(PDPageContentStream contentStream, String label, String value, float margin, float yPosition) throws IOException {
        contentStream.beginText();
        contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD), 10);
        contentStream.newLineAtOffset(margin, yPosition);
        contentStream.showText(label);
        contentStream.endText();

        if (!value.isEmpty()) {
            contentStream.beginText();
            contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 10);
            contentStream.newLineAtOffset(margin + 100, yPosition);
            contentStream.showText(value);
            contentStream.endText();
        }

        return yPosition - 18;
    }

    /**
     * Helper method for bullet point formatting
     */
    private float drawBulletPoint(PDPageContentStream contentStream, String text, float margin, float yPosition) throws IOException {
        contentStream.beginText();
        contentStream.setFont(new PDType1Font(Standard14Fonts.FontName.HELVETICA), 10);
        contentStream.newLineAtOffset(margin, yPosition);
        contentStream.showText(text);
        contentStream.endText();

        return yPosition - 15;
    }

    /**
     * Extract patient ID from emergency ID format: VIAL123456
     */
    private Long extractPatientIdFromEmergencyId(String emergencyId) {
        try {
            if (emergencyId.startsWith("VIAL")) {
                String idPart = emergencyId.substring(4);
                return Long.parseLong(idPart);
            }
        } catch (NumberFormatException e) {
            logger.error("Could not parse patient ID from emergency ID: {}", emergencyId);
        }

        throw new IllegalArgumentException("Invalid emergency ID format: " + emergencyId);
    }
}
```

#### Emergency Controller - Public Access

```java
// controller/EmergencyController.java
@RestController
@RequestMapping("/v1/api/emergency")
@Tag(name = "Emergency Information", description = "Emergency medical information and Vial of Life PDF generation")
public class EmergencyController {

    private static final Logger logger = LoggerFactory.getLogger(EmergencyController.class);

    @Autowired
    private VialOfLifePdfService vialOfLifePdfService;

    /**
     * Generate and serve Vial of Life PDF for emergency use (PUBLIC ACCESS)
     */
    @GetMapping("/{emergencyId}.pdf")
    @Operation(
        summary = "🚨 Get Emergency PDF",
        description = """
            Generate a pre-filled Vial of Life PDF document for emergency responders.

            This endpoint is designed to be accessed via QR codes in emergency situations.
            It returns an official Vial of Life form pre-populated with the patient's:
            - Basic information (name, DOB, blood type)
            - Critical allergies and medical conditions
            - Current medications
            - Emergency contact information

            **Security Note:** This endpoint uses emergency ID tokens for access control.
            """,
        tags = {"Emergency Information", "🚨 Emergency Response"}
    )
    @ApiResponses({
        @ApiResponse(responseCode = "200", description = "PDF generated and returned successfully"),
        @ApiResponse(responseCode = "404", description = "Patient not found for emergency ID"),
        @ApiResponse(responseCode = "500", description = "Error generating PDF")
    })
    public ResponseEntity<byte[]> getEmergencyPdf(
            @Parameter(description = "Emergency ID (format: VIAL123456)", example = "VIAL123456")
            @PathVariable String emergencyId) {

        try {
            logger.info("🚨 Emergency PDF request for ID: {}", emergencyId);

            // Generate PDF
            byte[] pdfBytes = vialOfLifePdfService.generateVialOfLifePdf(emergencyId);

            // Set response headers for PDF
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_PDF);
            headers.setContentDisposition(ContentDisposition.inline()
                .filename("vial_of_life_" + emergencyId + ".pdf")
                .build());
            headers.setContentLength(pdfBytes.length);
            headers.setCacheControl("no-cache, no-store, must-revalidate");

            logger.info("✅ Emergency PDF generated successfully for: {}", emergencyId);
            return new ResponseEntity<>(pdfBytes, headers, HttpStatus.OK);

        } catch (IllegalArgumentException e) {
            logger.error("❌ Invalid emergency ID: {}", emergencyId);
            return ResponseEntity.notFound().build();
        } catch (Exception e) {
            logger.error("💥 Error generating emergency PDF for ID: {}", emergencyId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Force download version of emergency PDF
     */
    @GetMapping("/download/{emergencyId}.pdf")
    @Operation(summary = "Download Emergency PDF", description = "Force download of Vial of Life PDF")
    public ResponseEntity<byte[]> downloadEmergencyPdf(@PathVariable String emergencyId) {

        try {
            byte[] pdfBytes = vialOfLifePdfService.generateVialOfLifePdf(emergencyId);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_OCTET_STREAM);
            headers.setContentDisposition(ContentDisposition.attachment()
                .filename("vial_of_life_" + emergencyId + ".pdf")
                .build());

            return new ResponseEntity<>(pdfBytes, headers, HttpStatus.OK);

        } catch (Exception e) {
            logger.error("Error generating downloadable emergency PDF", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
```

### Security Configuration

#### Public Emergency Access

```java
// Emergency endpoints are configured as permitAll() in SecurityConfig
.requestMatchers("/v1/api/emergency/**").permitAll()  // No authentication required

// JWT Authentication Filter excludes emergency endpoints
private static final List<String> EXCLUDED_PATHS = Arrays.asList(
    "/v1/api/emergency"  // Emergency PDF access (no auth required)
);
```

### Emergency ID Format

- **Format**: `VIAL{patientId}` (e.g., `VIAL123456`)
- **Usage**: Embedded in QR codes for first responder access
- **Security**: Emergency IDs are not sensitive but provide controlled access

### QR Code Integration

```java
// QR Code generation for emergency access
public String generateEmergencyQRCode(Long patientId) {
    String emergencyId = "VIAL" + patientId;
    String emergencyUrl = baseUrl + "/v1/api/emergency/" + emergencyId + ".pdf";

    // Generate QR code pointing to emergency PDF
    return qrCodeService.generateQRCode(emergencyUrl);
}
```

### PDF Features

#### Professional Medical Formatting
- **Red Cross Header**: Medical symbol for easy identification
- **Clear Typography**: High-contrast fonts for readability
- **Structured Sections**: Patient info, medical data, emergency contacts
- **Critical Allergies**: Highlighted in red for immediate attention
- **Generation Timestamp**: Shows when document was created

#### Information Included
- **Patient Demographics**: Name, DOB, age, gender, phone
- **Critical Medical Data**: Allergies with severity levels
- **Current Medications**: Active medications with dosage and frequency
- **Emergency Contacts**: Family members and caregivers with contact info
- **Legal Footer**: Confidentiality notice and system attribution

### Dependencies

#### Maven Dependencies
```xml
<!-- Apache PDFBox for PDF generation -->
<dependency>
    <groupId>org.apache.pdfbox</groupId>
    <artifactId>pdfbox</artifactId>
    <version>3.0.0</version>
</dependency>
```

### Configuration Properties

```properties
# Vial of Life Configuration
careconnect.vial.enabled=true
careconnect.vial.base-url=${BASE_URL:http://localhost:8080}

# PDF Generation Settings
careconnect.pdf.cache.enabled=false  # Always generate fresh for emergencies
careconnect.pdf.quality=high
```

### Error Handling

```java
// Comprehensive error handling for emergency situations
@ExceptionHandler(IllegalArgumentException.class)
public ResponseEntity<String> handleInvalidEmergencyId(IllegalArgumentException e) {
    logger.warn("Invalid emergency ID provided: {}", e.getMessage());
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
        .body("Emergency information not found");
}

@ExceptionHandler(Exception.class)
public ResponseEntity<String> handlePdfGenerationError(Exception e) {
    logger.error("PDF generation failed", e);
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
        .body("Emergency PDF temporarily unavailable");
}
```

### Usage Example

#### Emergency Access URL
```
https://careconnect.example.com/v1/api/emergency/VIAL123456.pdf
```

#### QR Code Integration
First responders scan QR code → Instantly access patient's critical medical information → Make informed emergency decisions

### Future Enhancements

- **Multi-language Support**: Emergency PDFs in multiple languages
- **Photo Integration**: Include patient photo for identification
- **Medical Conditions**: Add chronic conditions and recent procedures
- **Insurance Information**: Include insurance details for billing
- **Advanced Care Directives**: Include DNR and other care preferences
- **Digital Signature**: Cryptographic verification of document authenticity

## File Upload & Management

### File Upload Service

```java
// service/FileUploadService.java
@Service
public class FileUploadService {

    @Value("${app.upload.dir}")
    private String uploadDir;

    private final UserFileRepository userFileRepository;

    public UserFileDTO uploadFile(MultipartFile file, Long userId, String category) {
        validateFile(file);

        String fileName = generateUniqueFileName(file.getOriginalFilename());
        String filePath = uploadDir + "/" + userId + "/" + category + "/" + fileName;

        try {
            // Create directory if not exists
            Files.createDirectories(Paths.get(filePath).getParent());

            // Save file
            Files.copy(file.getInputStream(), Paths.get(filePath));

            // Save metadata to database
            UserFile userFile = new UserFile();
            userFile.setUserId(userId);
            userFile.setFileName(file.getOriginalFilename());
            userFile.setFilePath(filePath);
            userFile.setFileSize(file.getSize());
            userFile.setContentType(file.getContentType());
            userFile.setCategory(category);

            userFile = userFileRepository.save(userFile);

            return convertToDTO(userFile);

        } catch (IOException e) {
            throw new FileStorageException("Could not store file " + fileName, e);
        }
    }

    private void validateFile(MultipartFile file) {
        if (file.isEmpty()) {
            throw new FileStorageException("Cannot store empty file");
        }

        // Check file size (10MB limit)
        if (file.getSize() > 10 * 1024 * 1024) {
            throw new FileStorageException("File size exceeds 10MB limit");
        }

        // Check file type
        String contentType = file.getContentType();
        if (!isAllowedContentType(contentType)) {
            throw new FileStorageException("File type not allowed: " + contentType);
        }
    }
}
```

### Frontend File Upload

```dart
// services/file_upload_service.dart
class FileUploadService {
  final ApiClient _apiClient;

  Future<UploadedFile> uploadFile(File file, String category) async {
    try {
      String fileName = path.basename(file.path);

      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'category': category,
      });

      final response = await _apiClient.post(
        '/api/files/upload',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
        onSendProgress: (sent, total) {
          // Update upload progress
          double progress = sent / total;
          _uploadProgressController.add(progress);
        },
      );

      return UploadedFile.fromJson(response.data);
    } catch (e) {
      throw FileUploadException('Upload failed: $e');
    }
  }

  Future<List<UploadedFile>> getUserFiles(String? category) async {
    try {
      final response = await _apiClient.get(
        '/api/files',
        queryParameters: category != null ? {'category': category} : null,
      );

      return (response.data as List)
          .map((json) => UploadedFile.fromJson(json))
          .toList();
    } catch (e) {
      throw FileUploadException('Failed to fetch files: $e');
    }
  }
}
```

## Testing Strategies

### Unit Testing (Flutter)

```dart
// test/services/health_service_test.dart
void main() {
  group('HealthService', () {
    late HealthService healthService;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      healthService = HealthService(mockApiClient);
    });

    test('should fetch vital signs successfully', () async {
      // Arrange
      final mockResponse = [
        {'id': '1', 'type': 'blood_pressure', 'value': 120.0, 'unit': 'mmHg'}
      ];
      when(mockApiClient.get('/api/health/vitals'))
          .thenAnswer((_) async => Response(data: mockResponse, statusCode: 200));

      // Act
      final result = await healthService.getVitalSigns();

      // Assert
      expect(result, isA<List<VitalSign>>());
      expect(result.length, equals(1));
      expect(result.first.type, equals('blood_pressure'));
    });

    test('should throw exception on network error', () async {
      // Arrange
      when(mockApiClient.get('/api/health/vitals'))
          .thenThrow(DioException(requestOptions: RequestOptions()));

      // Act & Assert
      expect(() => healthService.getVitalSigns(),
             throwsA(isA<HealthException>()));
    });
  });
}
```

### Integration Testing (Spring Boot)

```java
// test/integration/HealthControllerIntegrationTest.java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
@Transactional
class HealthControllerIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    private String jwtToken;
    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = createTestUser();
        userRepository.save(testUser);
        jwtToken = jwtUtil.generateToken(new UserPrincipal(testUser));
    }

    @Test
    void shouldReturnVitalSignsForAuthenticatedUser() {
        // Arrange
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(jwtToken);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        // Act
        ResponseEntity<List> response = restTemplate.exchange(
            "/api/health/vitals",
            HttpMethod.GET,
            entity,
            List.class
        );

        // Assert
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
    }

    @Test
    void shouldCreateVitalSignSuccessfully() {
        // Arrange
        VitalSignDTO vitalSign = VitalSignDTO.builder()
            .type("blood_pressure")
            .value(120.0)
            .unit("mmHg")
            .build();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(jwtToken);
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<VitalSignDTO> entity = new HttpEntity<>(vitalSign, headers);

        // Act
        ResponseEntity<VitalSignDTO> response = restTemplate.exchange(
            "/api/health/vitals",
            HttpMethod.POST,
            entity,
            VitalSignDTO.class
        );

        // Assert
        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("blood_pressure", response.getBody().getType());
    }
}
```

### End-to-End Testing

```dart
// integration_test/app_test.dart
void main() {
  group('CareConnect E2E Tests', () {
    testWidgets('complete user journey', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login flow
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'password123');
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();

      // Verify dashboard is loaded
      expect(find.text('Dashboard'), findsOneWidget);

      // Navigate to health section
      await tester.tap(find.byKey(Key('health_tab')));
      await tester.pumpAndSettle();

      // Record vital sign
      await tester.tap(find.byKey(Key('add_vital_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(Key('vital_value')), '120');
      await tester.tap(find.byKey(Key('save_vital_button')));
      await tester.pumpAndSettle();

      // Verify vital sign was saved
      expect(find.text('120'), findsOneWidget);
    });
  });
}
```

## Performance Optimization

### Frontend Optimization

```dart
// Lazy loading and performance optimizations
class OptimizedListView extends StatefulWidget {
  @override
  _OptimizedListViewState createState() => _OptimizedListViewState();
}

class _OptimizedListViewState extends State<OptimizedListView> {
  final ScrollController _scrollController = ScrollController();
  final List<VitalSign> _vitalSigns = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _vitalSigns.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _vitalSigns.length) {
          return CircularProgressIndicator();
        }

        return ListTile(
          key: ValueKey(_vitalSigns[index].id),
          title: Text(_vitalSigns[index].type),
          subtitle: Text('${_vitalSigns[index].value} ${_vitalSigns[index].unit}'),
        );
      },
    );
  }
}
```

### Backend Optimization

```java
// Caching configuration
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        RedisCacheManager.Builder builder = RedisCacheManager
            .RedisCacheManagerBuilder
            .fromConnectionFactory(redisConnectionFactory())
            .cacheDefaults(cacheConfiguration(Duration.ofMinutes(10)));

        return builder.build();
    }

    private RedisCacheConfiguration cacheConfiguration(Duration ttl) {
        return RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(ttl)
            .disableCachingNullValues()
            .serializeKeysWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new GenericJackson2JsonRedisSerializer()));
    }
}

// Service with caching
@Service
public class CachedHealthService {

    @Cacheable(value = "user_vitals", key = "#userId")
    public List<VitalSignDTO> getVitalSigns(Long userId) {
        // Database query is cached
        return healthRepository.findByUserIdOrderByMeasurementTimeDesc(userId)
            .stream()
            .map(this::convertToDTO)
            .collect(Collectors.toList());
    }

    @CacheEvict(value = "user_vitals", key = "#userId")
    public VitalSignDTO recordVitalSign(Long userId, VitalSignDTO vitalSign) {
        // Cache is invalidated when new data is added
        return saveVitalSign(userId, vitalSign);
    }
}
```

### Database Optimization

```sql
-- Optimized indexes for common queries
CREATE INDEX idx_vital_signs_user_type_time ON vital_signs(user_id, type, measurement_time DESC);
CREATE INDEX idx_users_role_active ON users(role, active);
CREATE INDEX idx_messages_conversation_time ON messages(conversation_id, sent_at DESC);

-- Partitioning for large tables
ALTER TABLE vital_signs PARTITION BY RANGE (YEAR(measurement_time)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);
```

## Deployment Pipeline

### GitHub Actions CI/CD

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test-frontend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: frontend

    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.9.2'

    - name: Install dependencies
      run: flutter pub get

    - name: Run tests
      run: flutter test

    - name: Build web
      run: flutter build web

  test-backend:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: backend/core

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: test
          MYSQL_DATABASE: careconnect_test
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'adopt'

    - name: Cache Maven packages
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}

    - name: Run tests
      run: ./mvnw test
      env:
        SPRING_DATASOURCE_URL: jdbc:mysql://localhost:3306/careconnect_test
        SPRING_DATASOURCE_USERNAME: root
        SPRING_DATASOURCE_PASSWORD: test

  deploy-staging:
    needs: [test-frontend, test-backend]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'

    steps:
    - uses: actions/checkout@v3

    - name: Deploy to staging
      run: |
        # Deploy backend to staging
        docker build -t careconnect-backend:staging backend/core
        docker push ${{ secrets.ECR_REGISTRY }}/careconnect-backend:staging

        # Deploy frontend to staging
        cd frontend
        flutter build web
        aws s3 sync build/web s3://${{ secrets.STAGING_BUCKET }}

  deploy-production:
    needs: [test-frontend, test-backend]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
    - uses: actions/checkout@v3

    - name: Deploy to production
      run: |
        # Production deployment with blue-green strategy
        ./scripts/deploy-production.sh
```

### Docker Configuration

```dockerfile
# backend/core/Dockerfile
FROM openjdk:17-jdk-slim

WORKDIR /app

COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn
RUN ./mvnw dependency:go-offline

COPY src src
RUN ./mvnw package -DskipTests

EXPOSE 8080

CMD ["java", "-jar", "target/careconnect-backend-1.0.0.jar"]
```

### Terraform Infrastructure

```hcl
# terraform_aws/main.tf
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  environment = var.environment
  cidr_block = var.vpc_cidr
}

module "rds" {
  source = "./modules/rds"

  environment = var.environment
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  db_name = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

module "ecs" {
  source = "./modules/ecs"

  environment = var.environment
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  backend_image = var.backend_image
  db_host = module.rds.db_endpoint
}
```

## Monitoring & Logging

### Application Monitoring

```java
// config/MonitoringConfig.java
@Configuration
public class MonitoringConfig {

    @Bean
    public MeterRegistry meterRegistry() {
        return new PrometheusMeterRegistry(PrometheusConfig.DEFAULT);
    }

    @Bean
    public TimedAspect timedAspect(MeterRegistry registry) {
        return new TimedAspect(registry);
    }
}

// Custom metrics
@Service
public class MetricsService {

    private final Counter userLoginCounter;
    private final Timer apiResponseTimer;

    public MetricsService(MeterRegistry meterRegistry) {
        this.userLoginCounter = Counter.builder("user.login.count")
            .description("Number of user logins")
            .register(meterRegistry);

        this.apiResponseTimer = Timer.builder("api.response.time")
            .description("API response time")
            .register(meterRegistry);
    }

    public void recordLogin() {
        userLoginCounter.increment();
    }

    public void recordApiResponse(Duration duration) {
        apiResponseTimer.record(duration);
    }
}
```

### Logging Configuration

```yaml
# backend/core/src/main/resources/logback-spring.xml
<configuration>
    <springProfile name="!prod">
        <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
            <encoder>
                <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
            </encoder>
        </appender>
        <root level="INFO">
            <appender-ref ref="CONSOLE" />
        </root>
    </springProfile>

    <springProfile name="prod">
        <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
            <file>/app/logs/careconnect.log</file>
            <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
                <fileNamePattern>/app/logs/careconnect.%d{yyyy-MM-dd}.log</fileNamePattern>
                <maxHistory>30</maxHistory>
            </rollingPolicy>
            <encoder class="net.logstash.logback.encoder.LoggingEventCompositeJsonEncoder">
                <providers>
                    <timestamp />
                    <logLevel />
                    <loggerName />
                    <message />
                    <mdc />
                    <stackTrace />
                </providers>
            </encoder>
        </appender>
        <root level="INFO">
            <appender-ref ref="FILE" />
        </root>
    </springProfile>
</configuration>
```

## Code Standards & Best Practices

### Flutter Code Standards

```dart
// Good example - following naming conventions and structure
class HealthDataProvider extends ChangeNotifier {
  final HealthService _healthService;
  final List<VitalSign> _vitalSigns = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<VitalSign> get vitalSigns => List.unmodifiable(_vitalSigns);
  bool get isLoading => _isLoading;
  String? get error => _error;

  HealthDataProvider(this._healthService);

  Future<void> loadVitalSigns() async {
    _setLoading(true);
    _clearError();

    try {
      final signs = await _healthService.getVitalSigns();
      _vitalSigns.clear();
      _vitalSigns.addAll(signs);
    } catch (e) {
      _setError('Failed to load vital signs: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() => _setError(null);
}
```

### Java Code Standards

```java
// Good example - following SOLID principles and clean code
@Service
@Transactional
public class HealthServiceImpl implements HealthService {

    private static final Logger log = LoggerFactory.getLogger(HealthServiceImpl.class);

    private final VitalSignRepository vitalSignRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final VitalSignValidator vitalSignValidator;

    public HealthServiceImpl(
            VitalSignRepository vitalSignRepository,
            UserRepository userRepository,
            NotificationService notificationService,
            VitalSignValidator vitalSignValidator) {
        this.vitalSignRepository = vitalSignRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
        this.vitalSignValidator = vitalSignValidator;
    }

    @Override
    @Cacheable(value = "user_vitals", key = "#userId")
    public List<VitalSignDTO> getVitalSigns(Long userId) {
        log.debug("Fetching vital signs for user: {}", userId);

        List<VitalSign> vitalSigns = vitalSignRepository
            .findByUserIdOrderByMeasurementTimeDesc(userId);

        return vitalSigns.stream()
            .map(VitalSignMapper::toDTO)
            .collect(Collectors.toList());
    }

    @Override
    @CacheEvict(value = "user_vitals", key = "#userId")
    public VitalSignDTO recordVitalSign(Long userId, VitalSignRequest request) {
        log.info("Recording vital sign for user: {}", userId);

        // Validate input
        vitalSignValidator.validate(request);

        // Get user
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new UserNotFoundException(userId));

        // Create and save vital sign
        VitalSign vitalSign = VitalSignMapper.fromRequest(request, user);
        vitalSign = vitalSignRepository.save(vitalSign);

        // Process alerts
        processVitalSignAlerts(vitalSign);

        log.info("Successfully recorded vital sign: {}", vitalSign.getId());
        return VitalSignMapper.toDTO(vitalSign);
    }

    private void processVitalSignAlerts(VitalSign vitalSign) {
        if (VitalSignAnalyzer.isAbnormal(vitalSign)) {
            notificationService.sendHealthAlert(vitalSign);
        }
    }
}
```

### Git Commit Standards

```
feat: add vital signs tracking functionality
fix: resolve authentication token refresh issue
docs: update API documentation for health endpoints
style: format code according to style guide
refactor: extract common validation logic
test: add unit tests for health service
chore: update dependencies to latest versions

# Breaking changes
BREAKING CHANGE: change API response format for vital signs endpoint
```

## Contributing Guidelines

### Development Workflow

1. **Fork and Clone**: Fork the repository and clone your fork
2. **Branch**: Create a feature branch from `develop`
3. **Develop**: Make your changes following code standards
4. **Test**: Write and run tests for your changes
5. **Commit**: Make atomic commits with clear messages
6. **Push**: Push your branch to your fork
7. **PR**: Create a pull request to `develop` branch

### Code Review Process

```markdown
## Pull Request Checklist

- [ ] Code follows the established style guide
- [ ] All tests pass
- [ ] New functionality has adequate test coverage
- [ ] Documentation is updated if needed
- [ ] No breaking changes without proper migration
- [ ] Security implications are considered
- [ ] Performance impact is acceptable
```

### Setting Up Development Environment

```bash
# Clone repository
git clone https://github.com/your-org/careconnect2025.git
cd careconnect2025

# Setup frontend
cd frontend
flutter pub get
flutter doctor

# Setup backend
cd ../backend/core
./mvnw clean install

# Setup database
mysql -u root -p < scripts/init-db.sql

# Run tests
flutter test  # Frontend
./mvnw test   # Backend
```

## Troubleshooting

### Common Development Issues

#### Configuration Problems

**Environment Variable Issues**
```bash
# Check required environment variables
echo $SECURITY_JWT_SECRET      # Required for JWT authentication
echo $DEEPSEEK_API_KEY         # Required for AI features
echo $STRIPE_SECRET_KEY        # Required for subscriptions
echo $JDBC_URI                 # Database connection

# Set missing variables
export SECURITY_JWT_SECRET="your-jwt-secret-key"
export DEEPSEEK_API_KEY="your-deepseek-api-key"
```

**Profile-Specific Configuration Issues**
```properties
# application-dev.properties - Common issues:
spring.jpa.hibernate.ddl-auto=update  # Risky for production
spring.flyway.enabled=false           # Disabled due to circular dependencies

# Fix for production:
spring.jpa.hibernate.ddl-auto=validate
spring.flyway.enabled=true
```

**Database Migration Problems**
```bash
# Flyway is currently disabled due to circular dependency issues
# Temporary workaround uses JPA DDL auto-update

# Check current database schema
psql -h localhost -U careconnect -d careconnect -c "\dt"

# Manual migration approach
psql -h localhost -U careconnect -d careconnect -f src/main/resources/db/migration/V22__create_ai_chat_tables.sql
```

#### Flutter Build Issues

**Cache and Dependencies**
```bash
# Clear Flutter cache
flutter clean
flutter pub cache clean
flutter pub get

# Fix version conflicts
flutter pub deps
flutter pub upgrade

# Reset Flutter installation
flutter channel stable
flutter upgrade
flutter doctor -v
```

**Build Failures**
```bash
# Android build issues
cd android && ./gradlew clean
flutter build apk --debug

# iOS build issues
cd ios && pod install
flutter build ios --debug
```

#### Backend Compilation Issues

**Maven Dependencies**
```bash
# Clean Maven cache and resolve dependencies
./mvnw clean
rm -rf ~/.m2/repository
./mvnw dependency:resolve
./mvnw clean compile

# Spring Boot 3.4.5 with Java 17 requirement
java -version  # Must be Java 17+
```

**Spring Boot Issues**
```bash
# Check for circular dependencies
./mvnw compile 2>&1 | grep -i circular

# Resolve Spring AI milestone version conflicts
./mvnw dependency:tree | grep spring-ai
```

#### Database Connection Issues

**PostgreSQL Connection Problems**
```sql
-- Check PostgreSQL status
SELECT version();
SHOW max_connections;
SHOW shared_preload_libraries;

-- Connection pool issues
SELECT state, count(*) FROM pg_stat_activity GROUP BY state;

-- Reset connections
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle';
```

**HikariCP Connection Pool**
```properties
# Tune connection pool settings
spring.datasource.hikari.maximum-pool-size=10
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=20000
spring.datasource.hikari.idle-timeout=300000
```

### Authentication & Security Issues

#### JWT Token Problems

**Invalid Token Handling**
```java
// Common JWT issues in JwtAuthenticationFilter
if (token != null && jwt.validateToken(token)) {
    // Token is valid
} else {
    if (token != null) {
        log.warn("Invalid token provided");  // Check token expiration
    } else {
        log.debug("No token found in request");  // Missing Authorization header
    }
}
```

**Token Debugging**
```bash
# Decode JWT token (for debugging only)
echo "your-jwt-token" | cut -d. -f2 | base64 --decode | jq .

# Check token expiration
curl -H "Authorization: Bearer your-token" http://localhost:8080/v1/api/auth/validate
```

#### Password Reset Issues

**Reset Token Problems**
```java
// From UserPasswordService - token validation
boolean validateToken(String token, String email) {
    // Check both raw token and Base64 encoded versions
    // Common issue: Base64 encoding mismatches
}
```

#### OAuth Integration Issues

**Google OAuth Configuration**
```properties
# Development uses mock credentials - update for production
spring.security.oauth2.client.registration.google.client-id=your-real-client-id
spring.security.oauth2.client.registration.google.client-secret=your-real-client-secret
```

### WebSocket Connection Issues

#### Connection Management Problems

**Authentication Failures**
```java
// Common WebSocket authentication issues
private void handleAuthentication(WebSocketSession session, Map<String, Object> payload) {
    String token = (String) payload.get("token");
    if (jwtTokenProvider.validateToken(token)) {
        // Store authenticated user info
        session.getAttributes().put("authenticated", true);
    } else {
        // Authentication failed - connection will be closed
        sendMessage(session, Map.of("type", "authentication-error", "message", "Invalid token"));
    }
}
```

**Connection Cleanup Issues**
```java
// WebSocket transport errors may not properly clean up sessions
@Scheduled(fixedRate = 300000) // Every 5 minutes
public void cleanupExpiredConnections() {
    List<WebSocketConnection> expired = repository.findExpiredConnections(LocalDateTime.now());
    expired.forEach(conn -> conn.setIsActive(false));
}
```

**Client-Side Connection Issues**
```dart
// Flutter WebSocket reconnection logic
Future<void> _handleDisconnection() async {
  // Implement exponential backoff
  int retryCount = 0;
  while (retryCount < 5) {
    await Future.delayed(Duration(seconds: math.pow(2, retryCount).toInt()));
    try {
      await connect();
      break;
    } catch (e) {
      retryCount++;
    }
  }
}
```

### AI Service Integration Issues

#### DeepSeek API Problems

**API Key Configuration**
```java
// DeepSeekService initialization
if (apiKey == null || apiKey.trim().isEmpty()) {
    throw new IllegalStateException("DeepSeek API key is not configured");
}
```

**Network Timeout Issues**
```properties
# Increase timeout for AI API calls
careconnect.ai.timeout.connection=30000
careconnect.ai.timeout.read=60000
```

**JSON Parsing Failures**
```java
// AI response parsing errors
try {
    TaskDtoV2 aiTask = objectMapper.readValue(aiContent, TaskDtoV2.class);
    if (aiTask == null || aiTask.getName() == null) {
        log.error("Invalid AI Task generated: {}", aiTask);
        return; // Skip invalid AI responses
    }
} catch (JsonProcessingException e) {
    log.error("Error parsing AI response: {}", e.getMessage());
}
```

#### LangChain4j Integration Issues

**Memory Management Problems**
```properties
# Chat memory configuration issues
careconnect.chat.memory.default-max-messages=20
careconnect.chat.memory.premium-max-messages=50
careconnect.chat.memory.auto-cleanup=true
```

**Model Configuration Errors**
```java
// Model initialization
@Bean
public ChatLanguageModel deepSeekChatModel() {
    return OpenAiChatModel.builder()
        .baseUrl("https://api.deepseek.com/v1")
        .apiKey(deepSeekApiKey)
        .modelName("deepseek-chat")
        .temperature(0.7)
        .timeout(Duration.ofSeconds(60))
        .maxRetries(3)  // Add retry logic
        .build();
}
```

### Third-Party Integration Issues

#### Stripe Integration Problems

**Price ID Conversion Issues**
```java
// Common Stripe issues in StripeService
private String convertPlanIdToPriceId(String planId) {
    // Complex price ID mapping - ensure all plans are configured
    switch (planId.toLowerCase()) {
        case "basic": return "price_basic_monthly";
        case "premium": return "price_premium_monthly";
        default:
            log.error("Unknown plan ID: {}", planId);
            throw new AppException(HttpStatus.BAD_REQUEST, "Invalid plan ID");
    }
}
```

**Webhook Validation**
```java
// Stripe webhook signature validation
try {
    Webhook.constructEvent(payload, sigHeader, endpointSecret);
} catch (SignatureVerificationException e) {
    log.error("Invalid Stripe webhook signature");
    throw new AppException(HttpStatus.BAD_REQUEST, "Invalid signature");
}
```

#### AWS Integration Issues

**S3 Configuration Problems**
```properties
# Environment-specific S3 configuration
cloud.aws.s3.bucket=${AWS_S3_BUCKET_NAME:careconnect-dev}
cloud.aws.credentials.access-key=${AWS_ACCESS_KEY_ID}
cloud.aws.credentials.secret-key=${AWS_SECRET_ACCESS_KEY}
```

**WebSocket API Gateway Issues**
```java
// AWS WebSocket connection management
public void sendMessageToConnection(String connectionId, Object message) {
    try {
        AmazonApiGatewayManagementApi client = clientBuilder
            .withEndpointConfiguration(new EndpointConfiguration(apiGatewayEndpoint, "us-east-1"))
            .build();
        // Handle ConnectionGoneException for disconnected clients
    } catch (GoneException e) {
        log.info("Connection {} is no longer available", connectionId);
        connectionService.markConnectionInactive(connectionId);
    }
}
```

### Performance Issues

#### Database Performance Problems

**Slow Queries**
```sql
-- Enable PostgreSQL query logging
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1 second

-- Check slow queries
SELECT query, mean_exec_time, total_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 10;
```

**Connection Pool Exhaustion**
```properties
# Monitor and tune HikariCP settings
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.leak-detection-threshold=60000
logging.level.com.zaxxer.hikari=DEBUG
```

#### Memory Issues

**JVM Memory Tuning**
```bash
# Production JVM settings
java -Xms2g -Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 \
     -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/app/ \
     -jar careconnect-backend.jar
```

**Flutter Memory Optimization**
```dart
// Optimize image loading and caching
class OptimizedImageWidget extends StatelessWidget {
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      memCacheWidth: 300,
      memCacheHeight: 300,
      placeholder: (context, url) => CircularProgressIndicator(),
      errorWidget: (context, url, error) => Icon(Icons.error),
      // Implement image compression
      imageBuilder: (context, imageProvider) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: imageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
```

### Development Environment Issues

#### Docker and Containerization

**Database Container Issues**
```bash
# PostgreSQL container troubleshooting
docker logs careconnect-postgres
docker exec -it careconnect-postgres psql -U careconnect -d careconnect

# Reset database container
docker-compose down -v
docker-compose up -d postgres
```

**Port Conflicts**
```bash
# Check for port conflicts
lsof -i :8080  # Backend port
lsof -i :3000  # Frontend port
lsof -i :5432  # PostgreSQL port

# Kill conflicting processes
kill -9 <PID>
```

#### IDE and Tooling Issues

**IntelliJ IDEA Configuration**
```bash
# Clear IntelliJ caches
rm -rf ~/.IntelliJIdea*/system/caches
rm -rf ~/.IntelliJIdea*/system/index

# Reimport Maven project
mvn idea:idea
```

**VS Code Flutter Issues**
```json
// .vscode/settings.json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.debugExternalPackageLibraries": true,
  "dart.debugSdkLibraries": true
}
```

### Deployment Issues

#### Production Deployment Problems

**Environment Configuration**
```bash
# Check all required environment variables for production
required_vars=(
  "SECURITY_JWT_SECRET"
  "DEEPSEEK_API_KEY"
  "STRIPE_SECRET_KEY"
  "AWS_ACCESS_KEY_ID"
  "AWS_SECRET_ACCESS_KEY"
  "DATABASE_URL"
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var}" ]]; then
    echo "Missing required environment variable: $var"
  fi
done
```

**Health Check Failures**
```bash
# Test application health endpoints
curl -f http://localhost:8080/actuator/health || exit 1
curl -f http://localhost:8080/actuator/db || exit 1
```

#### Monitoring and Debugging

**Application Metrics**
```properties
# Enable actuator endpoints for monitoring
management.endpoints.web.exposure.include=health,info,metrics,prometheus
management.endpoint.health.show-details=always
```

**Logging Configuration**
```properties
# Production logging configuration
logging.level.org.springframework.security=INFO
logging.level.com.careconnect=INFO
logging.level.org.hibernate.SQL=WARN
logging.pattern.file=%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n
```

**Error Tracking**
```java
// Structured error logging
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGenericException(Exception e) {
        log.error("Unhandled exception occurred", e);
        ErrorResponse error = new ErrorResponse(
            "INTERNAL_ERROR",
            "An unexpected error occurred",
            System.currentTimeMillis()
        );
        return ResponseEntity.status(500).body(error);
    }
}
```

This comprehensive troubleshooting guide covers the most common issues encountered in the CareConnect platform, providing practical solutions and debugging strategies for developers.

---

*This guide covers the essential aspects of developing with the CareConnect platform. For specific implementation details, refer to the code comments and additional documentation in the respective modules.*

*Last Updated: October 2025*
*Version: 2025.1.0*