# Fall Detection System 🚨

A comprehensive fall detection monitoring system that integrates with AltumView cameras to provide real-time skeleton tracking, alert management, and video playback capabilities.

![Fall Detection System](https://img.shields.io/badge/Status-Production%20Ready-green)
![Java](https://img.shields.io/badge/Java-17-orange)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.0-green)

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [API Endpoints](#api-endpoints)
- [Technical Implementation](#technical-implementation)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This Fall Detection System provides a complete solution for monitoring elderly care facilities, hospitals, or homes using AltumView's advanced computer vision technology. The system processes real-time skeleton data to detect fall events and provides instant alerts with video playback capabilities.

### Key Components

- **Backend**: Spring Boot REST API with AltumView integration
- **Frontend**: Flutter web/mobile application for monitoring and management
- **Real-time Processing**: MQTT-based skeleton stream processing
- **Video Playback**: Skeleton recording decoder with frame-by-frame animation

## ✨ Features

### 🔴 Alert Management
- Real-time fall detection alerts
- Alert history and filtering
- Background image overlay with skeleton data
- Alert resolution tracking

### 📹 Video Playback
- Complete skeleton recording playback (86+ frames)
- Smooth animation with dynamic timing
- Frame-by-frame skeleton visualization
- Coordinate normalization and scaling

### 📱 Live Monitoring
- Real-time skeleton stream visualization
- MQTT-based live data streaming
- Multi-camera support
- Camera background image display

### 🏥 Camera Management
- Camera listing and configuration
- Background image retrieval
- Stream configuration management
- Camera health monitoring

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Spring Boot    │    │   AltumView     │
│                 │    │     Backend      │    │      API        │
│  ┌───────────┐  │    │                  │    │                 │
│  │  Alerts   │  │◄──►│  REST API        │◄──►│  Camera Data    │
│  │  Screen   │  │    │                  │    │                 │
│  └───────────┘  │    │  ┌─────────────┐ │    │  ┌────────────┐ │
│                 │    │  │   Skeleton  │ │    │  │   MQTT     │ │
│  ┌───────────┐  │    │  │   Decoder   │ │    │  │  Streams   │ │
│  │   Live    │  │◄──►│  └─────────────┘ │    │  └────────────┘ │
│  │ Skeleton  │  │    │                  │    │                 │
│  └───────────┘  │    │  ┌─────────────┐ │    │  ┌────────────┐ │
│                 │    │  │    MQTT     │ │◄──►│  │  Skeleton  │ │
│  ┌───────────┐  │    │  │   Client    │ │    │  │   Data     │ │
│  │  Camera   │  │    │  └─────────────┘ │    │  └────────────┘ │
│  │  Images   │  │    │                  │    │                 │
│  └───────────┘  │    └──────────────────┘    └─────────────────┘
└─────────────────┘
```

## 📋 Prerequisites

### Backend Requirements
- **Java 17** or higher
- **Maven 3.6+**
- **Spring Boot 3.2.0**
- **AltumView API credentials**

### Frontend Requirements
- **Flutter 3.0+**
- **Dart SDK 3.0+**
- **Web browser** (Chrome, Firefox, Safari)
- **Android/iOS device** (optional, for mobile)

### System Requirements
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 2GB free space
- **Network**: Stable internet connection for AltumView API

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd FallDetectionTest
```

### 2. Backend Setup

```bash
cd Backend

# Install dependencies
mvn clean install

# Run tests
mvn test

# Start the application
mvn spring-boot:run
```

The backend will start on `http://localhost:8080`

### 3. Frontend Setup

```bash
cd Frontend

# Get Flutter dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Or run on mobile device
flutter run
```

## ⚙️ Configuration

### Backend Configuration

Edit `Backend/src/main/resources/application.properties`:

```properties
# Server Configuration
server.port=8080
server.address=0.0.0.0

# AltumView API Configuration
altumview.oauth-url=https://oauth.altumview.com/v1.0
altumview.api-url=https://api.altumview.com/v1.0
altumview.mqtt-host=prod.altumview.com
altumview.mqtt-port=8084
altumview.client-id=YOUR_CLIENT_ID
altumview.client-secret=YOUR_CLIENT_SECRET
altumview.scope=camera:write room:write alert:write person:write user:write group:write invitation:write person_info:write

# Logging
logging.level.com.example.demo=INFO
```

### Frontend Configuration

Update API endpoint in `Frontend/lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:8080/api';
```

For production, change to your deployed backend URL.

## 📱 Usage

### 1. Start the System

1. **Start Backend**: `mvn spring-boot:run` in Backend directory
2. **Start Frontend**: `flutter run -d chrome` in Frontend directory
3. **Access Application**: Open `http://localhost:PORT` in your browser

### 2. Main Features

#### Alerts Screen
- View recent fall detection alerts
- Click on alerts to see skeleton video playback
- Background images with skeleton overlay
- Alert resolution status

#### Live Skeleton Monitoring
- Real-time skeleton stream from cameras
- Live visualization of detected persons
- Camera selection and configuration

#### Camera Management
- List all available cameras
- View camera background images
- Check camera status and configuration

### 3. Skeleton Video Playback

The system provides complete skeleton recording playback with:

- **Full Video Sequence**: All frames decoded (typically 86 frames for ~20 seconds)
- **Dynamic Timing**: Frame rate calculated from skeleton metadata
- **Smooth Animation**: Proper coordinate normalization and scaling
- **Interactive Controls**: Play/pause functionality

## 🔌 API Endpoints

### Alert Management
```
GET    /api/skeleton/alerts                     # Get all alerts
GET    /api/skeleton/alerts/{id}                # Get specific alert
GET    /api/skeleton/alerts/{id}/skeleton-decoded  # Get decoded skeleton data
GET    /api/skeleton/alerts/{id}/background-url    # Get background image URL
```

### Camera Management
```
GET    /api/skeleton/cameras                    # Get all cameras
GET    /api/skeleton/cameras/{id}/view          # Get camera view image
GET    /api/skeleton/cameras/{id}/background    # Get camera background
GET    /api/skeleton/stream-config/{id}         # Get stream configuration
```

### Real-time Streaming
```
WebSocket: ws://localhost:8080/skeleton-stream/{cameraId}
MQTT Topic: skeleton/stream/{cameraId}
```

## 🔧 Technical Implementation

### Skeleton Data Processing

#### Binary Format Decoding
The system processes AltumView's skeleton recording binary format:

```java
// Frame structure parsing
epochTime = buffer.getShort() & 0xFFFF;
curIndex += 3;
numParts = buffer.get() & 0xFF;
curIndex += 17;

// Keypoint extraction
for (int j = 0; j < numParts; j++) {
    int index = buffer.get() & 0xFF;
    curIndex += 2; // skip probability
    int xCoord = buffer.getShort() & 0xFFFF;
    int yCoord = buffer.getShort() & 0xFFFF;
    curIndex += 4;
}
```

#### Coordinate Normalization
Raw coordinates are normalized to screen coordinates:

```dart
double normalizedX = (rawX / frameWidth).clamp(0.0, 1.0);
double normalizedY = (rawY / frameHeight).clamp(0.0, 1.0);
```

#### Dynamic Frame Rate
Video timing is calculated from skeleton metadata:

```dart
final intervalMs = totalEpochTime / numFrames;
final clampedInterval = intervalMs.clamp(10.0, 1000.0);
Duration frameDuration = Duration(milliseconds: clampedInterval.round());
```

### MQTT Integration

Real-time skeleton streaming uses MQTT:

```java
@Component
public class SkeletonMqttClient {
    private void processSkeletonMessage(byte[] payload) {
        // Decode binary skeleton data
        // Normalize coordinates
        // Broadcast to WebSocket clients
    }
}
```

### Flutter State Management

The app uses Provider for state management:

```dart
class SkeletonState extends ChangeNotifier {
    List<SkeletonFrame> frames = [];
    bool isPlaying = false;
    int currentFrameIndex = 0;
    
    void playVideo() {
        isPlaying = true;
        notifyListeners();
    }
}
```

## 🐛 Troubleshooting

### Common Issues

#### Backend Won't Start
```bash
# Check Java version
java -version

# Check port availability
lsof -i :8080

# Check application.properties configuration
```

#### Frontend Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### No Skeleton Data
1. Verify AltumView API credentials
2. Check camera connectivity
3. Confirm MQTT connection
4. Review application logs

#### Video Playback Issues
1. Check skeleton file exists in alert
2. Verify binary decoder working: `mvn test -Dtest=SkeletonRecordingDecoderTest`
3. Confirm frame parsing: Check logs for "Decoded X frames"

### Debugging

#### Enable Debug Logging
```properties
# In application.properties
logging.level.com.example.demo=DEBUG
logging.level.org.springframework.web.client=DEBUG
```

#### Flutter Debug Mode
```bash
flutter run --debug
```

### Performance Optimization

#### Backend Optimization
- Increase JVM heap size: `-Xmx2G -Xms1G`
- Connection pooling for AltumView API
- Caching for frequently accessed data

#### Frontend Optimization
- Use `flutter run --release` for production
- Optimize image loading with caching
- Implement lazy loading for large datasets

## 📊 Monitoring and Logging

### Application Logs
```bash
# Backend logs
tail -f Backend/backend.log

# Application-specific logs
tail -f logs/fall-detection.log
```

### Health Checks
```bash
# Backend health
curl http://localhost:8080/actuator/health

# API connectivity
curl http://localhost:8080/api/skeleton/cameras
```

### Performance Metrics
- Monitor JVM memory usage
- Track API response times
- Monitor MQTT connection stability
- Flutter app performance profiling

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/new-feature`
3. **Make changes and test**
4. **Run tests**: `mvn test` (Backend) and `flutter test` (Frontend)
5. **Commit changes**: `git commit -m "Add new feature"`
6. **Push to branch**: `git push origin feature/new-feature`
7. **Create Pull Request**

### Code Standards

#### Backend (Java)
- Follow Spring Boot conventions
- Use Lombok for boilerplate code
- Comprehensive unit tests
- Proper error handling

#### Frontend (Dart/Flutter)
- Follow Flutter style guide
- Use Provider for state management
- Responsive design principles
- Material Design components

### Testing

#### Backend Tests
```bash
# Run all tests
mvn test

# Run specific test
mvn test -Dtest=SkeletonRecordingDecoderTest

# Generate coverage report
mvn jacoco:report
```

#### Frontend Tests
```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **AltumView** for providing the computer vision API and documentation
- **Flutter team** for the excellent cross-platform framework
- **Spring Boot** for the robust backend framework

## 📞 Support

For technical support or questions:

1. **Check the troubleshooting section** above
2. **Review the application logs** for error details
3. **Create an issue** in the repository with:
   - Environment details (OS, Java/Flutter versions)
   - Steps to reproduce the problem
   - Error messages and logs
   - Expected vs actual behavior

---

**Built with ❤️ for fall detection and elderly care monitoring**
