# CareConnect 2025 Programmer's Guide

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Development Environment Setup](#development-environment-setup)
3. [Frontend Development (Flutter)](#frontend-development-flutter)
4. [Backend Development (Spring Boot)](#backend-development-spring-boot)
5. [Database Design](#database-design)
6. [API Documentation](#api-documentation)
7. [Authentication & Security](#authentication--security)
8. [Real-time Communication](#real-time-communication)
9. [AI Integration](#ai-integration)
10. [Device Integration](#device-integration)
11. [File Upload & Management](#file-upload--management)
12. [Testing Strategies](#testing-strategies)
13. [Performance Optimization](#performance-optimization)
14. [Deployment Pipeline](#deployment-pipeline)
15. [Monitoring & Logging](#monitoring--logging)
16. [Code Standards & Best Practices](#code-standards--best-practices)
17. [Contributing Guidelines](#contributing-guidelines)
18. [Troubleshooting](#troubleshooting)

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
- **Database**: MySQL 8.0+
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

### API Endpoints

#### Authentication Endpoints

```
POST   /api/auth/login          # User login
POST   /api/auth/register       # User registration
POST   /api/auth/refresh        # Refresh JWT token
POST   /api/auth/logout         # User logout
POST   /api/auth/forgot         # Password reset request
POST   /api/auth/reset          # Password reset confirmation
```

#### Health Management Endpoints

```
GET    /api/health/vitals       # Get user's vital signs
POST   /api/health/vitals       # Record new vital sign
GET    /api/health/vitals/{type} # Get vital signs by type
DELETE /api/health/vitals/{id}   # Delete vital sign

GET    /api/health/medications  # Get medications
POST   /api/health/medications  # Add medication
PUT    /api/health/medications/{id} # Update medication
DELETE /api/health/medications/{id} # Delete medication

GET    /api/health/allergies    # Get allergies
POST   /api/health/allergies    # Add allergy
DELETE /api/health/allergies/{id} # Delete allergy
```

#### Communication Endpoints

```
GET    /api/messages            # Get user messages
POST   /api/messages            # Send message
GET    /api/messages/{id}       # Get specific message
DELETE /api/messages/{id}       # Delete message

GET    /api/conversations       # Get conversations
POST   /api/conversations       # Start new conversation
GET    /api/conversations/{id}  # Get conversation details
```

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

### Security Configuration

```java
// config/SecurityConfig.java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity(prePostEnabled = true)
public class SecurityConfig {

    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;
    private final JwtRequestFilter jwtRequestFilter;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf().disable()
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/api/public/**").permitAll()
                .requestMatchers("/swagger-ui/**", "/v3/api-docs/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/health/**").hasAnyRole("PATIENT", "CAREGIVER")
                .requestMatchers(HttpMethod.POST, "/api/health/**").hasAnyRole("PATIENT", "CAREGIVER")
                .anyRequest().authenticated())
            .exceptionHandling().authenticationEntryPoint(jwtAuthenticationEntryPoint)
            .and()
            .addFilterBefore(jwtRequestFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
```

## Real-time Communication

### WebSocket Configuration

```java
// config/WebSocketConfig.java
@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(new ChatWebSocketHandler(), "/ws/chat")
                .setAllowedOrigins("*");
    }
}

// handler/ChatWebSocketHandler.java
@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        String userId = getUserIdFromSession(session);
        sessions.put(userId, session);
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) throws Exception {
        String userId = getUserIdFromSession(session);
        ChatMessage chatMessage = objectMapper.readValue(message.getPayload(), ChatMessage.class);

        // Save message to database
        chatMessageService.saveMessage(chatMessage);

        // Send to recipient if online
        WebSocketSession recipientSession = sessions.get(chatMessage.getRecipientId());
        if (recipientSession != null && recipientSession.isOpen()) {
            recipientSession.sendMessage(message);
        }
    }
}
```

### Real-time Notifications

```java
// service/NotificationService.java
@Service
public class NotificationService {

    private final SimpMessagingTemplate messagingTemplate;
    private final FirebaseMessaging firebaseMessaging;

    public void sendNotification(String userId, NotificationDTO notification) {
        // Send via WebSocket if user is online
        messagingTemplate.convertAndSendToUser(
            userId, "/queue/notifications", notification);

        // Send push notification
        sendPushNotification(userId, notification);
    }

    private void sendPushNotification(String userId, NotificationDTO notification) {
        try {
            Message message = Message.builder()
                .putData("title", notification.getTitle())
                .putData("body", notification.getBody())
                .putData("type", notification.getType())
                .setToken(getUserDeviceToken(userId))
                .build();

            firebaseMessaging.send(message);
        } catch (Exception e) {
            log.error("Failed to send push notification", e);
        }
    }
}
```

## AI Integration

### AI Service Integration

```dart
// services/ai_service.dart
class AIService {
  final Dio _dio;
  final String _apiKey;

  AIService(this._dio, this._apiKey);

  Future<String> processVoiceCommand(String command) async {
    try {
      final response = await _dio.post('/api/ai/voice-command', data: {
        'command': command,
        'context': await _getContextData(),
      });

      return response.data['response'];
    } catch (e) {
      throw AIException('Failed to process voice command: $e');
    }
  }

  Future<List<String>> getHealthRecommendations() async {
    try {
      final response = await _dio.get('/api/ai/recommendations');
      return List<String>.from(response.data['recommendations']);
    } catch (e) {
      throw AIException('Failed to get recommendations: $e');
    }
  }

  Future<Map<String, dynamic>> _getContextData() async {
    // Gather context data for AI processing
    return {
      'recent_vitals': await _getRecentVitals(),
      'medications': await _getCurrentMedications(),
      'mood_history': await _getRecentMoodData(),
    };
  }
}
```

### Voice Command Processing

```java
// service/AIService.java
@Service
public class AIService {

    private final OpenAIClient openAIClient;
    private final HealthService healthService;

    public AICommandResponse processVoiceCommand(String userId, String command) {
        // Analyze command intent
        CommandIntent intent = analyzeIntent(command);

        switch (intent.getType()) {
            case RECORD_VITALS:
                return processVitalRecording(userId, intent);
            case SCHEDULE_APPOINTMENT:
                return processAppointmentScheduling(userId, intent);
            case GET_HEALTH_SUMMARY:
                return processHealthSummary(userId);
            default:
                return new AICommandResponse("I didn't understand that command.");
        }
    }

    private CommandIntent analyzeIntent(String command) {
        // Use NLP to analyze command intent
        String prompt = "Analyze the following command and extract intent and parameters: " + command;

        ChatCompletionRequest request = ChatCompletionRequest.builder()
            .model("gpt-3.5-turbo")
            .messages(List.of(new ChatMessage("user", prompt)))
            .build();

        ChatCompletionResult result = openAIClient.createChatCompletion(request);

        // Parse response to extract intent
        return parseIntentFromResponse(result.getChoices().get(0).getMessage().getContent());
    }
}
```

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

#### Flutter Build Issues

```bash
# Clear Flutter cache
flutter clean
flutter pub cache clean
flutter pub get

# Reset Flutter installation
flutter channel stable
flutter upgrade
flutter doctor -v
```

#### Backend Compilation Issues

```bash
# Clean Maven cache
./mvnw clean
rm -rf ~/.m2/repository

# Reinstall dependencies
./mvnw dependency:resolve
./mvnw clean compile
```

#### Database Connection Issues

```sql
-- Check MySQL status
SHOW PROCESSLIST;
SHOW VARIABLES LIKE '%timeout%';

-- Reset connections
FLUSH PRIVILEGES;
RESTART;
```

### Performance Debugging

#### Frontend Performance

```dart
// Enable performance overlay
import 'package:flutter/rendering.dart';

void main() {
  debugPaintSizeEnabled = true; // Shows widget boundaries
  runApp(MyApp());
}

// Profile widget rebuilds
class PerformanceWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('PerformanceWidget rebuilt at ${DateTime.now()}');
    return Container();
  }
}
```

#### Backend Performance

```java
// Enable JVM profiling
java -XX:+FlightRecorder -XX:StartFlightRecording=duration=60s,filename=profile.jfr -jar app.jar

// SQL query logging
logging.level.org.hibernate.SQL=DEBUG
logging.level.org.hibernate.type.descriptor.sql.BasicBinder=TRACE
```

### Memory Management

```dart
// Flutter memory optimization
class OptimizedImageWidget extends StatelessWidget {
  final String imageUrl;

  const OptimizedImageWidget({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      cacheWidth: 200, // Limit cache size
      cacheHeight: 200,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.error);
      },
    );
  }
}
```

---

*This guide covers the essential aspects of developing with the CareConnect platform. For specific implementation details, refer to the code comments and additional documentation in the respective modules.*

*Last Updated: October 2025*
*Version: 2025.1.0*