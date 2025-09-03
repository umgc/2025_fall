# CareConnect 2025

A comprehensive healthcare management application built with Flutter frontend and Spring Boot backend, designed to provide seamless healthcare services and communication.

## 🏗️ Project Structure

```
careconnect2025/
├── frontend/                 # Flutter application (Web, iOS, Android, Desktop)
├── backend/                  # Spring Boot REST API
│   └── core/                # Main backend application
└── terraform_aws/           # AWS infrastructure as code
```

## 🚀 Quick Start

### Prerequisites

Before you begin, ensure you have the following installed:

#### For Frontend (Flutter)
- **Flutter SDK** (version 3.8.1 or higher)
- **Dart SDK** (included with Flutter)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **VS Code** or **Android Studio** (recommended IDEs)

#### For Backend (Spring Boot)
- **Java 17** (OpenJDK or Oracle JDK)
- **Maven** (version 3.6+)
- **MySQL** (version 8.0+)

#### For Infrastructure
- **Terraform** (version 1.0+)
- **AWS CLI** (configured with credentials)

## 💻 Platform-Specific Installation

### 🍎 macOS Installation

#### Install Homebrew (if not already installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Install Flutter
```bash
brew install --cask flutter
```

#### Install Java 17
```bash
brew install openjdk@17
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### Install Maven
```bash
brew install maven
```

#### Install MySQL
```bash
brew install mysql
brew services start mysql
```

#### Install Terraform
```bash
brew install terraform
```

### 🪟 Windows Installation

#### Install Chocolatey (if not already installed)
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

#### Install Flutter
```powershell
choco install flutter
```

#### Install Java 17
```powershell
choco install openjdk17
```

#### Install Maven
```powershell
choco install maven
```

#### Install MySQL
```powershell
choco install mysql
```

#### Install Terraform
```powershell
choco install terraform
```

#### Alternative: Manual Installation
1. **Flutter**: Download from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
2. **Java**: Download OpenJDK 17 from [adoptium.net](https://adoptium.net/temurin/releases/?version=17)
3. **Maven**: Download from [maven.apache.org](https://maven.apache.org/download.cgi)
4. **MySQL**: Download from [dev.mysql.com](https://dev.mysql.com/downloads/mysql/)

### 🐧 Linux Installation

#### Ubuntu/Debian
```bash
# Update package list
sudo apt update

# Install Flutter dependencies
sudo apt install curl git unzip xz-utils zip libglu1-mesa

# Install Java 17
sudo apt install openjdk-17-jdk

# Install Maven
sudo apt install maven

# Install MySQL
sudo apt install mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql

# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update && sudo apt install terraform
```

#### CentOS/RHEL/Fedora
```bash
# Install Flutter dependencies
sudo yum install curl git unzip xz

# Install Java 17
sudo yum install java-17-openjdk-devel

# Install Maven
sudo yum install maven

# Install MySQL
sudo yum install mysql-server
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Install Terraform
sudo yum install yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum install terraform
```

## 🔧 Installation & Setup

### 1. Clone and Setup Frontend

```bash
cd frontend

# Install Flutter dependencies
flutter pub get

# Verify Flutter installation
flutter doctor

# Run the application (choose your platform)
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d ios             # iOS
flutter run -d macos           # macOS
flutter run -d windows         # Windows
flutter run -d linux           # Linux
```

**Quick Web Development:**
```bash
# Use the provided startup script
chmod +x startup.sh          # macOS/Linux
# On Windows, use: startup.bat
./startup.sh                 # macOS/Linux
# On Windows: startup.bat
```

### 2. Setup Backend

```bash
cd backend/core

# Make scripts executable (macOS/Linux only)
chmod +x run.sh
chmod +x mvnw

# Install dependencies and run
./mvnw clean install
./run.sh
```

**Windows Alternative:**
```cmd
cd backend\core
mvnw.cmd clean install
run.bat
```

**Alternative: Manual Setup**
```bash
# Set environment variables
export JDBC_URI="jdbc:mysql://localhost:3306/careconnect?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true"
export DB_USER="root"
export DB_PASSWORD="password"
export HIBERNATE_DDL_AUTO="update"

# Run with Maven
./mvnw spring-boot:run
```

### 3. Database Setup

#### macOS/Linux
```bash
# Start MySQL service
sudo systemctl start mysql          # Linux
brew services start mysql           # macOS

# Create database (if not using auto-creation)
mysql -u root -p
CREATE DATABASE careconnect;
```

#### Windows
```cmd
# Start MySQL service
net start mysql

# Create database (if not using auto-creation)
mysql -u root -p
CREATE DATABASE careconnect;
```

### 4. Environment Configuration

Create environment files in the frontend directory:

**.env**
```bash
# API Configuration
API_BASE_URL=http://localhost:8080
FLUTTER_WEB_PORT=50030

# Firebase Configuration (if using)
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
```

**.env.local** (for local overrides)
```bash
# Local development overrides
API_BASE_URL=http://localhost:8080
DEBUG_MODE=true
```

## 🔧 Development

### Frontend Development

The Flutter app includes several key features:
- **Authentication & User Management**
- **AI Chat & Voice Commands**
- **Video Calling** (Agora + WebRTC)
- **Health Monitoring** (Fitbit integration)
- **Task Management**
- **Payment Processing** (Stripe)
- **Real-time Notifications**

**Key Dependencies:**
- `provider` - State management
- `go_router` - Navigation
- `dio` - HTTP client
- `firebase_core` - Firebase services
- `agora_rtc_engine` - Video calling
- `flutter_stripe` - Payment processing

### Backend Development

The Spring Boot application provides:
- **RESTful API endpoints**
- **JWT Authentication**
- **WebSocket support**
- **Database integration**
- **AI service integration**
- **Email & SMS services**

**Key Technologies:**
- Spring Boot 3.4.5
- Spring Security
- Spring Data JPA
- MySQL database
- WebSocket support
- Firebase Admin SDK

### Running Tests

```bash
# Frontend tests
cd frontend
flutter test

# Backend tests
cd backend/core
./mvnw test

# Run all tests with coverage
cd frontend
./run-all-tests.sh
```

## 🌐 Deployment

### AWS Infrastructure

The project includes Terraform configurations for AWS deployment:

```bash
cd terraform_aws

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply infrastructure
terraform apply
```

**Infrastructure Components:**
- VPC and networking
- RDS database
- ECS/Fargate for backend
- Amplify for frontend
- S3 for file storage
- CloudFront for CDN
- API Gateway for REST API

### Docker Deployment

```bash
# Build backend image
cd backend/core
docker build -t careconnect-backend .

# Run container
docker run -p 8080:8080 careconnect-backend
```

## 📱 Features

- **Multi-platform Support**: Web, iOS, Android, Desktop
- **Real-time Communication**: Video calls, chat, notifications
- **AI Integration**: Voice commands, chat assistance
- **Health Monitoring**: Wearable device integration
- **Payment Processing**: Stripe integration
- **Offline Support**: Local storage and sync
- **Security**: JWT authentication, encrypted communication

## 🛠️ Troubleshooting

### Common Issues

1. **Flutter Doctor Issues**
   ```bash
   flutter doctor --android-licenses
   flutter clean && flutter pub get
   ```

2. **Backend Connection Issues**
   - Verify MySQL is running
   - Check database credentials in `run.sh`
   - Ensure port 8080 is available

3. **Dependency Issues**
   ```bash
   # Frontend
   flutter pub cache clean
   flutter pub get
   
   # Backend
   ./mvnw clean install
   ```

### Platform-Specific Issues

#### macOS
- **Permission Issues**: Use `chmod +x` for scripts
- **Port Conflicts**: Check if ports are already in use with `lsof -i :PORT`
- **Java Path**: Ensure Java 17 is in your PATH

#### Windows
- **Script Execution**: Use `.bat` files instead of `.sh`
- **Path Issues**: Add Flutter and Java to system PATH
- **Antivirus**: Whitelist development directories

#### Linux
- **Package Dependencies**: Install required system packages
- **Permissions**: Use `sudo` for system-level operations
- **Service Management**: Use `systemctl` for MySQL

### Logs and Debugging

- **Frontend**: Use Flutter DevTools
- **Backend**: Check console output and logs
- **Database**: MySQL logs and connection status

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is proprietary software. All rights reserved.

## 🆘 Support

For technical support or questions:
- Check the existing documentation
- Review the test files for examples
- Examine the configuration files
- Check the security scripts for setup guidance

---

**Happy Coding! 🚀**
