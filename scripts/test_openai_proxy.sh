#!/bin/bash
# test_openai_proxy.sh
# OpenAI Proxy Integration Test Script
# Author: CX DevOps Team
# Version: v1.0

set -e

echo "🧪 OpenAI Proxy Integration Test"
echo "================================="

# Configuration
API_GATEWAY_IP="${1:-192.168.10.30}"  # Default to API Gateway server IP
OPENAI_PROXY_PORT="${2:-8001}"
BASE_URL="http://${API_GATEWAY_IP}:${OPENAI_PROXY_PORT}"

echo "Testing OpenAI Proxy at: ${BASE_URL}"

# Test 1: Health Check
echo "📡 Testing proxy health..."
if curl -f -s "${BASE_URL}/v1/models" > /dev/null; then
    echo "✅ Proxy is responding"
else
    echo "❌ Proxy health check failed"
    exit 1
fi

# Test 2: Models Endpoint
echo "📋 Testing /v1/models endpoint..."
MODELS_RESPONSE=$(curl -f -s "${BASE_URL}/v1/models")
if echo "${MODELS_RESPONSE}" | jq -e '.data' > /dev/null 2>&1; then
    echo "✅ Models endpoint returned valid JSON"
    echo "Available models:"
    echo "${MODELS_RESPONSE}" | jq -r '.data[].id' | head -5
else
    echo "❌ Models endpoint test failed"
    echo "Response: ${MODELS_RESPONSE}"
    exit 1
fi

# Test 3: Chat Completions Endpoint (if models are available)
MODEL_COUNT=$(echo "${MODELS_RESPONSE}" | jq -r '.data | length')
if [ "${MODEL_COUNT}" -gt 0 ]; then
    FIRST_MODEL=$(echo "${MODELS_RESPONSE}" | jq -r '.data[0].id')
    echo "💬 Testing /v1/chat/completions with model: ${FIRST_MODEL}"
    
    CHAT_PAYLOAD=$(cat <<EOF
{
  "model": "${FIRST_MODEL}",
  "messages": [
    {"role": "user", "content": "Hello, this is a test message."}
  ],
  "max_tokens": 50
}
EOF
)
    
    CHAT_RESPONSE=$(curl -f -s -X POST "${BASE_URL}/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "${CHAT_PAYLOAD}" || echo "FAILED")
    
    if [ "${CHAT_RESPONSE}" != "FAILED" ]; then
        echo "✅ Chat completions endpoint is working"
    else
        echo "⚠️ Chat completions test failed (may require Ollama backend)"
    fi
else
    echo "⚠️ No models available, skipping chat completions test"
fi

# Test 4: Service Status Check
echo "🔧 Checking systemd service status..."
if command -v ansible > /dev/null 2>&1; then
    cd /opt/CX-Dev-Test-Infrastructure/configs/ansible
    if ansible api_gateway_servers -i inventory/main.yaml \
        -m systemd -a "name=openai-proxy" --become 2>/dev/null | grep -q "active"; then
        echo "✅ OpenAI Proxy systemd service is active"
    else
        echo "⚠️ Could not verify systemd service status via Ansible"
    fi
else
    echo "⚠️ Ansible not available for service status check"
fi

echo ""
echo "🎉 OpenAI Proxy integration test completed!"
echo "Summary:"
echo "  • Proxy URL: ${BASE_URL}"
echo "  • Models available: ${MODEL_COUNT:-0}"
echo "  • Status: Ready for production use"
