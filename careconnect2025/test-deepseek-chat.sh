#!/bin/bash

# Test script for DeepSeek AI Chat integration
echo "🤖 Testing DeepSeek AI Chat Integration"
echo "========================================"

# Wait for backend to be ready
echo "⏳ Waiting for backend to start..."
for i in {1..30}; do
    if curl -s http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ Backend is ready!"
        break
    fi
    echo "   Attempt $i/30 - Backend not ready yet..."
    sleep 2
done

# Check if backend is ready
if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "❌ Backend failed to start within 60 seconds"
    exit 1
fi

# Test login to get JWT token
echo ""
echo "🔐 Testing login to get JWT token..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/v1/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "simple@test.com",
    "password": "password123"
  }')

echo "Login response: $LOGIN_RESPONSE"

# Extract JWT token
JWT_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$JWT_TOKEN" ]; then
    echo "❌ Failed to get JWT token from login response"
    exit 1
fi

echo "✅ JWT token obtained: ${JWT_TOKEN:0:20}..."

# Test AI Chat endpoint
echo ""
echo "🤖 Testing AI Chat endpoint with DeepSeek..."
CHAT_RESPONSE=$(curl -s -X POST http://localhost:8080/v1/api/ai-chat/chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{
    "message": "Hello, can you help me understand my health data?",
    "patientId": 1,
    "userId": 1,
    "chatType": "GENERAL_SUPPORT",
    "preferredModel": "deepseek-chat",
    "temperature": 0.7,
    "maxTokens": 500
  }')

echo "Chat response: $CHAT_RESPONSE"

# Check if response contains AI response
if echo "$CHAT_RESPONSE" | grep -q '"aiResponse"'; then
    echo "✅ AI Chat endpoint is working!"
    
    # Extract and display the AI response
    AI_RESPONSE=$(echo $CHAT_RESPONSE | grep -o '"aiResponse":"[^"]*"' | cut -d'"' -f4)
    echo ""
    echo "🤖 AI Response: $AI_RESPONSE"
    
    # Check if it's using DeepSeek
    if echo "$CHAT_RESPONSE" | grep -q '"aiProvider":"DEEPSEEK"'; then
        echo "✅ DeepSeek provider is being used!"
    else
        echo "⚠️  AI provider might not be DeepSeek (check response)"
    fi
else
    echo "❌ AI Chat endpoint failed or returned unexpected response"
    echo "Response: $CHAT_RESPONSE"
fi

echo ""
echo "🏁 Test completed!"

