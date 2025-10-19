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
# Install Flutter via Homebrew
brew install --cask flutter

# Verify installation
flutter doctor

# Accept Android licenses (if developing for Android)
flutter doctor --android-licenses
```

#### Install Java 17
```bash
# Install OpenJDK 17
brew install openjdk@17

# Add to PATH (choose your shell)
# For zsh (default on macOS Catalina+)
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@17"' >> ~/.zshrc
source ~/.zshrc

# For bash
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.bash_profile
echo 'export JAVA_HOME="/opt/homebrew/opt/openjdk@17"' >> ~/.bash_profile
source ~/.bash_profile

# Verify installation
java -version
```

#### Install Maven
```bash
brew install maven
mvn -version
```

#### Install MySQL
```bash
# Install MySQL
brew install mysql

# Start MySQL service
brew services start mysql

# Secure MySQL installation (recommended)
mysql_secure_installation

# Create database for CareConnect
mysql -u root -p
# In MySQL shell:
# CREATE DATABASE careconnect;
# CREATE USER 'careconnect'@'localhost' IDENTIFIED BY 'your_password';
# GRANT ALL PRIVILEGES ON careconnect.* TO 'careconnect'@'localhost';
# FLUSH PRIVILEGES;
# EXIT;
```

#### Install Development Tools
```bash
# Install Git (if not already installed)
brew install git

# Install Visual Studio Code (optional)
brew install --cask visual-studio-code

# Install Android Studio (for Android development)
brew install --cask android-studio

# Install Terraform (for AWS deployment)
brew install terraform
```

### 🪟 Windows Installation

#### Method 1: Using Package Managers (Recommended)

##### Install Chocolatey (Package Manager)
Open **PowerShell as Administrator** and run:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

##### Install Flutter
```powershell
# Install Flutter
choco install flutter

# Add Flutter to PATH (if not automatically added)
# Add C:\tools\flutter\bin to your system PATH

# Verify installation
flutter doctor

# Accept Android licenses
flutter doctor --android-licenses
```

##### Install Java 17
```powershell
# Install OpenJDK 17
choco install openjdk17

# Set JAVA_HOME environment variable
# Go to System Properties > Environment Variables
# Add: JAVA_HOME = C:\Program Files\Eclipse Adoptium\jdk-17.x.x.x-hotspot
# Add to PATH: %JAVA_HOME%\bin

# Verify installation
java -version
```

##### Install Maven
```powershell
choco install maven
mvn -version
```

##### Install MySQL
```powershell
# Install MySQL
choco install mysql

# Start MySQL service
net start mysql

# Secure installation (run MySQL Command Line Client)
# mysql -u root -p
# CREATE DATABASE careconnect;
# CREATE USER 'careconnect'@'localhost' IDENTIFIED BY 'your_password';
# GRANT ALL PRIVILEGES ON careconnect.* TO 'careconnect'@'localhost';
# FLUSH PRIVILEGES;
```

##### Install Development Tools
```powershell
# Install Git
choco install git

# Install Visual Studio Code
choco install vscode

# Install Android Studio
choco install androidstudio

# Install Terraform
choco install terraform
```

#### Method 2: Manual Installation
If you prefer manual installation or encounter issues with Chocolatey:

1. **Flutter**:
   - Download from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
   - Extract to `C:\flutter`
   - Add `C:\flutter\bin` to your PATH

2. **Java 17**:
   - Download OpenJDK 17 from [adoptium.net](https://adoptium.net/temurin/releases/?version=17)
   - Install and set JAVA_HOME environment variable

3. **Maven**:
   - Download from [maven.apache.org](https://maven.apache.org/download.cgi)
   - Extract and add `bin` folder to PATH

4. **MySQL**:
   - Download from [dev.mysql.com](https://dev.mysql.com/downloads/mysql/)
   - Use MySQL Installer for complete setup

5. **Android Studio**:
   - Download from [developer.android.com](https://developer.android.com/studio)

#### Windows-Specific Notes
- Use **PowerShell as Administrator** for installations
- Add tools to **System PATH** via Environment Variables
- Install **Visual Studio Build Tools** if you encounter compilation issues
- Enable **Developer Mode** in Windows Settings for better development experience

### 🐧 Linux Installation

#### Ubuntu/Debian
```bash
# Update package list
sudo apt update && sudo apt upgrade -y

# Install system dependencies
sudo apt install -y curl git unzip xz-utils zip libglu1-mesa cmake ninja-build clang pkg-config libgtk-3-dev

# Install Flutter
# Method 1: Using snapd (recommended)
sudo snap install flutter --classic

# Method 2: Manual installation
# wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
# tar xf flutter_linux_3.24.5-stable.tar.xz
# sudo mv flutter /opt/
# echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
# source ~/.bashrc

# Verify Flutter installation
flutter doctor
flutter doctor --android-licenses

# Install Java 17
sudo apt install -y openjdk-17-jdk openjdk-17-jre

# Set JAVA_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
source ~/.bashrc

# Verify Java installation
java -version

# Install Maven
sudo apt install -y maven
mvn -version

# Install MySQL
sudo apt install -y mysql-server mysql-client

# Start and enable MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# Secure MySQL installation
sudo mysql_secure_installation

# Create database and user
sudo mysql -u root -p << EOF
CREATE DATABASE careconnect;
CREATE USER 'careconnect'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON careconnect.* TO 'careconnect'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Install development tools
sudo apt install -y build-essential

# Install Android Studio (optional)
sudo snap install android-studio --classic

# Install VS Code (optional)
sudo snap install code --classic

# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update && sudo apt install terraform
```

#### CentOS/RHEL/Fedora
```bash
# For RHEL/CentOS 8+/Fedora
sudo dnf update -y

# Install system dependencies
sudo dnf install -y curl git unzip xz which cmake ninja-build clang pkg-config gtk3-devel

# For older versions, use yum instead of dnf
# sudo yum update -y
# sudo yum install -y curl git unzip xz which

# Install Flutter (manual method for RHEL/CentOS)
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
sudo mv flutter /opt/
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verify Flutter
flutter doctor

# Install Java 17
sudo dnf install -y java-17-openjdk java-17-openjdk-devel
# For older versions: sudo yum install java-17-openjdk java-17-openjdk-devel

# Set JAVA_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
source ~/.bashrc

# Install Maven
sudo dnf install -y maven
# For older versions: sudo yum install maven

# Install MySQL
sudo dnf install -y mysql-server mysql
# For older versions: sudo yum install mysql-server mysql

# Start MySQL
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Install Terraform
sudo dnf install -y yum-utils
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install terraform

# For older versions:
# sudo yum install yum-utils
# sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
# sudo yum install terraform
```

#### Arch Linux
```bash
# Update system
sudo pacman -Syu

# Install Flutter
yay -S flutter  # Using AUR helper
# Or download from official site manually

# Install dependencies
sudo pacman -S jdk17-openjdk maven mysql git base-devel cmake ninja clang pkg-config gtk3

# Start services
sudo systemctl start mysqld
sudo systemctl enable mysqld

# Install Terraform
yay -S terraform
```

#### Linux-Specific Notes
- **Permissions**: Add user to `plugdev` group for device access: `sudo usermod -a -G plugdev $USER`
- **Flutter Desktop**: Install additional packages for Linux desktop development
- **Android Development**: Download Android SDK manually or use Android Studio
- **Firewall**: Configure firewall for development ports (8080, 3000, etc.)
- **Environment Variables**: Add to `~/.bashrc`, `~/.zshrc`, or `~/.profile` depending on your shell

## 🔧 Installation & Setup

### 1. Clone Repository
```bash
# Clone the repository
git clone <repository_url>
cd careconnect2025

# Verify directory structure
ls -la
```

### 2. Frontend Setup

```bash
cd frontend

# Create environment file
cp .env.example .env    # If .env.example exists
# OR create .env file manually with required variables

# Install Flutter dependencies
flutter pub get

# Verify Flutter installation and resolve issues
flutter doctor
flutter doctor -v  # Verbose output for detailed diagnostics

# Accept Android licenses (for Android development)
flutter doctor --android-licenses

# Clean and rebuild if needed
flutter clean
flutter pub get

# Run the application (choose your target platform)
flutter run -d chrome          # Web browser
flutter run -d android         # Android emulator/device
flutter run -d ios             # iOS simulator (macOS only)
flutter run -d macos           # macOS desktop
flutter run -d windows         # Windows desktop
flutter run -d linux           # Linux desktop

# List available devices
flutter devices

# Run with specific device ID
flutter run -d <device_id>
```

**Environment Configuration:**
Create a `.env` file in the frontend directory:
```bash
# API Configuration
CC_BASE_URL_WEB=http://localhost:8080
CC_BASE_URL_ANDROID=http://10.0.2.2:8080
CC_BASE_URL_OTHER=http://localhost:8080

# JWT Secret
JWT_SECRET=your_jwt_secret_key_here

# API Keys (optional)
DEEPSEEK_API_KEY=your_deepseek_api_key
OPENAI_API_KEY=your_openai_api_key

#Enables the mock usps digest data
ENABLE_MOCK_USPS_DIGEST=true
# Enables the api call to fetch usps digest
ENABLE_USPS_DIGEST=false

# Backend Token
CC_BACKEND_TOKEN=your_backend_token
```

**Platform-Specific Commands:**
```bash
# Web development with hot reload
flutter run -d chrome --web-port=3000

# Android with specific emulator
flutter emulators --launch <emulator_name>
flutter run -d android

# iOS (macOS only)
open -a Simulator
flutter run -d ios

# Desktop
flutter config --enable-windows-desktop  # Windows
flutter config --enable-macos-desktop    # macOS
flutter config --enable-linux-desktop    # Linux
flutter run -d windows/macos/linux

# Build for production
flutter build web              # Web
flutter build apk             # Android APK
flutter build appbundle       # Android App Bundle
flutter build ios             # iOS (macOS only)
flutter build macos           # macOS
flutter build windows         # Windows
flutter build linux           # Linux
```

### 3. Backend Setup

```bash
cd backend/core

# Make scripts executable (macOS/Linux only)
chmod +x run.sh
chmod +x mvnw

# Verify Java and Maven versions
java -version    # Should show Java 17
mvn -version     # Should show Maven 3.6+

# Install dependencies and build
./mvnw clean install

# Set up environment variables (create application.properties or use environment)
# See backend configuration section below

# Run the backend server
./mvnw spring-boot:run
# OR use the provided script
./run.sh
```

**Windows Setup:**
```cmd
cd backend\core

# Verify installations
java -version
mvn -version

# Build project
mvnw.cmd clean install

# Run backend
mvnw.cmd spring-boot:run
# OR use batch file
run.bat
```

**Backend Environment Variables:**
Create `application.properties` in `backend/core/src/main/resources/` or set environment variables:
```properties
# Database Configuration
spring.datasource.url=jdbc:mysql://localhost:3306/careconnect?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true
spring.datasource.username=careconnect
spring.datasource.password=your_password
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# Hibernate Configuration
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

# Logging
logging.level.org.springframework=INFO
logging.level.com.careconnect=DEBUG
```

**Alternative Environment Variable Setup:**
```bash
# macOS/Linux
export JDBC_URI="jdbc:mysql://localhost:3306/careconnect?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true"
export DB_USER="careconnect"
export DB_PASSWORD="your_password"
export HIBERNATE_DDL_AUTO="update"
export JWT_SECRET="your_32_character_jwt_secret_key"

# Windows (PowerShell)
$env:JDBC_URI="jdbc:mysql://localhost:3306/careconnect?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true"
$env:DB_USER="careconnect"
$env:DB_PASSWORD="your_password"
$env:HIBERNATE_DDL_AUTO="update"
$env:JWT_SECRET="your_32_character_jwt_secret_key"
```

### 4. Database Setup

#### macOS/Linux
```bash
# Start MySQL service
sudo systemctl start mysql          # Linux
brew services start mysql           # macOS

# Connect to MySQL
mysql -u root -p

# Create database and user
CREATE DATABASE careconnect CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'careconnect'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON careconnect.* TO 'careconnect'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Test connection
mysql -u careconnect -p careconnect
```

#### Windows
```cmd
# Start MySQL service
net start mysql

# Connect and setup database
mysql -u root -p
CREATE DATABASE careconnect CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'careconnect'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON careconnect.* TO 'careconnect'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 5. Verify Installation

```bash
# Check if all services are running
# Frontend
cd frontend && flutter doctor

# Backend
cd backend/core && ./mvnw --version

# Database
mysql -u careconnect -p careconnect -e "SELECT 1;"

# Test backend API (in new terminal)
curl -X GET http://localhost:8080/actuator/health

# Test frontend access
# Open browser to http://localhost:3000 (or the port shown by flutter run)
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

#### 1. Flutter Doctor Issues
```bash
# Fix common Flutter issues
flutter doctor --android-licenses
flutter clean && flutter pub get
flutter doctor -v  # Verbose output

# Clear Flutter cache
flutter pub cache clean
rm -rf ~/.pub-cache  # Nuclear option (macOS/Linux)

# Reinstall Flutter (if needed)
flutter channel stable
flutter upgrade
```

#### 2. Backend Connection Issues
```bash
# Check if backend is running
curl -X GET http://localhost:8080/actuator/health
netstat -tulpn | grep :8080  # Linux/macOS
netstat -an | findstr :8080  # Windows

# Database connection issues
mysql -u careconnect -p careconnect -e "SHOW TABLES;"

# Check backend logs
cd backend/core
./mvnw spring-boot:run --debug
```

#### 3. Database Issues
```bash
# MySQL not starting
sudo systemctl status mysql        # Linux
brew services list | grep mysql    # macOS
sc query mysql                     # Windows

# Reset MySQL password (if needed)
sudo mysql_secure_installation     # Linux/macOS

# Check database permissions
mysql -u root -p
SHOW GRANTS FOR 'careconnect'@'localhost';
```

#### 4. Port Conflicts
```bash
# Find processes using ports
lsof -i :8080    # macOS/Linux
lsof -i :3000    # macOS/Linux
netstat -ano | findstr :8080  # Windows

# Kill processes on specific port
kill -9 $(lsof -ti:8080)  # macOS/Linux
```

#### 5. Environment Variable Issues
```bash
# Check environment variables
echo $JAVA_HOME     # Should point to Java 17
echo $PATH          # Should include Flutter, Java, Maven
flutter --version   # Should show Flutter version
java -version       # Should show Java 17
mvn -version        # Should show Maven 3.6+

# Reset environment (if needed)
source ~/.bashrc    # Linux
source ~/.zshrc     # macOS (if using zsh)
```

### Platform-Specific Issues

#### macOS
```bash
# Permission Issues
sudo chown -R $(whoami) /usr/local/bin/flutter
chmod +x run.sh
chmod +x mvnw

# Xcode issues (for iOS development)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept

# Homebrew issues
brew doctor
brew update && brew upgrade

# Port conflicts
sudo lsof -i :8080 | grep LISTEN
```

#### Windows
```powershell
# PATH issues
echo $env:PATH
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Eclipse Adoptium\jdk-17.x.x.x-hotspot", "Machine")

# Flutter issues
flutter config --android-studio-dir="C:\Program Files\Android\Android Studio"
flutter doctor --android-licenses

# Service issues
Get-Service -Name "*mysql*"
Start-Service MySQL80  # Adjust service name as needed

# Firewall issues
New-NetFirewallRule -DisplayName "Flutter" -Direction Inbound -Port 3000 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "Spring Boot" -Direction Inbound -Port 8080 -Protocol TCP -Action Allow
```

#### Linux
```bash
# Package dependencies
sudo apt update
sudo apt install -y build-essential libssl-dev

# Service management
sudo systemctl start mysql
sudo systemctl enable mysql
sudo systemctl status mysql

# Permissions for Android development
sudo usermod -a -G plugdev $USER
sudo usermod -a -G dialout $USER

# Firewall configuration
sudo ufw allow 8080
sudo ufw allow 3000

# SELinux issues (CentOS/RHEL)
sudo setenforce 0  # Temporarily disable SELinux
# Edit /etc/selinux/config for permanent changes
```

### Development Environment Issues

#### IDE Configuration
```bash
# VS Code Flutter extension
code --install-extension Dart-Code.flutter

# Android Studio Flutter plugin
# File > Settings > Plugins > Search "Flutter" > Install

# IntelliJ IDEA
# File > Settings > Plugins > Marketplace > Search "Flutter"
```

#### Network Issues
```bash
# Proxy configuration (if behind corporate firewall)
flutter config --android-sdk /path/to/android/sdk
git config --global http.proxy http://proxy.company.com:8080

# DNS issues
# Add to /etc/hosts (Linux/macOS) or C:\Windows\System32\drivers\etc\hosts (Windows)
127.0.0.1 localhost
::1 localhost
```

#### Performance Issues
```bash
# Increase memory for Flutter build
export GRADLE_OPTS="-Dorg.gradle.jvmargs='-Xmx2048m -XX:MaxPermSize=512m'"

# Clear caches
flutter clean
./mvnw clean  # In backend directory

# Update dependencies
flutter pub upgrade
./mvnw dependency:resolve
```

### Debug Mode Commands

```bash
# Flutter debug mode
flutter run --debug -v
flutter run --profile  # Performance profiling
flutter build --debug  # Debug build

# Backend debug mode
./mvnw spring-boot:run -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"

# Database debug
mysql -u careconnect -p --verbose
```

### Getting Help

If issues persist:
1. Check the Flutter [troubleshooting guide](https://flutter.dev/docs/testing/debugging)
2. Review Spring Boot [common application properties](https://docs.spring.io/spring-boot/docs/current/reference/html/application-properties.html)
3. Check MySQL [error logs](https://dev.mysql.com/doc/refman/8.0/en/error-log.html)
4. Enable verbose logging in both frontend and backend
5. Check system logs (`dmesg`, Event Viewer, Console.app)

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
