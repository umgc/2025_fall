This is for the development branch only.

Backend:
1. Build the Lambda Package (The test.skip is necessary for now)
mvn clean package -P assembly-zip -Dmaven.test.skip


2. Create Lambda Function (AWS CLI)
aws lambda create-function \
   --function-name careconnect-backend \
   --runtime java17 \
   --role arn:aws:iam::YOUR_ACCOUNT:role/lambda-execution-role \
   --handler com.careconnect.CcLambdaHandler::handleRequest \
   --zip-file fileb://target/careconnect-backend-0.0.2-SNAPSHOT-lambda-package.zip \
   --timeout 30 \
   --memory-size 1024

3. Set Environment Variables
aws lambda update-function-configuration \
   --function-name careconnect-backend \
   --environment Variables='{
     "SPRING_PROFILES_ACTIVE":"prod",
     "JDBC_URI":"your-rds-endpoint",
     "DB_USER":"your-db-user",
     "DB_PASSWORD":"your-db-password"
   }' 

4. Create API Gateway
aws apigatewayv2 create-api \
   --name careconnect-api \
   --protocol-type HTTP \
   --target arn:aws:lambda:REGION:ACCOUNT:function:careconnect-backend


Frontend:
1. In AWS Amplify Console:
    - Connect your Git repository
    - Select branch (developer)
    - Configure build settings (use the amplify.yml)
    - Deploy
  3. Environment variables that are required:
# API Configuration
CC_BASE_URL_WEB=<enter careconnect backend url>
CC_BASE_URL_ANDROID=http://10.0.2.2:8080
CC_BASE_URL_OTHER=http://localhost:8080

# AI Service Configuration (You can just leave these as is for now.)
OPENAI_API_KEY=your_openai_api_key_here 
DEEPSEEK_API_KEY=your_deepseek_api_key_here
deepSeek_uri=https://api.deepseek.com/v1/chat/completions

# Authentication (You can just leave these as if for now )
JWT_SECRET=your_secure_jwt_secret_32_chars_minimum
CC_BACKEND_TOKEN=your_backend_token_here