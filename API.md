# CX Infrastructure API Documentation

This document provides comprehensive API documentation for the CX Dev & Test Infrastructure services.

## Table of Contents

- [Authentication](#authentication)
- [AI Model APIs](#ai-model-apis)
- [Data Management APIs](#data-management-apis)
- [Infrastructure APIs](#infrastructure-apis)
- [Monitoring APIs](#monitoring-apis)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [SDK Examples](#sdk-examples)

## Authentication

All API endpoints require authentication using JSON Web Tokens (JWT) provided by Clerk 5.77.0.

### Getting an Access Token

```bash
curl -X POST "https://api.clerk.com/v1/sessions" \
  -H "Authorization: Bearer YOUR_SECRET_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "your_username",
    "password": "your_password"
  }'
```

### Using the Token

Include the JWT token in the Authorization header:

```bash
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## AI Model APIs

### Llama 3 Chat Completions

**Endpoint:** `POST http://192.168.10.28:8000/v1/chat/completions`

#### Request Format

```json
{
  "model": "llama-3-chat",
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful AI assistant."
    },
    {
      "role": "user", 
      "content": "Explain quantum computing in simple terms."
    }
  ],
  "max_tokens": 1000,
  "temperature": 0.7,
  "stream": false
}
```

#### Response Format

```json
{
  "id": "chat-12345",
  "object": "chat.completion",
  "created": 1690123456,
  "model": "llama-3-chat",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Quantum computing is a revolutionary approach..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 25,
    "completion_tokens": 150,
    "total_tokens": 175
  },
  "performance": {
    "inference_time_ms": 87,
    "queue_time_ms": 12,
    "gpu_utilization": 84.7
  }
}
```

#### cURL Example

```bash
curl -X POST "http://192.168.10.28:8000/v1/chat/completions" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3-chat",
    "messages": [
      {"role": "user", "content": "Hello, world!"}
    ],
    "max_tokens": 100
  }'
```

### Llama 3 Instruct Completions

**Endpoint:** `POST http://192.168.10.29:8000/v1/completions`

#### Request Format

```json
{
  "model": "llama-3-instruct",
  "prompt": "Write a Python function to calculate fibonacci numbers:",
  "max_tokens": 500,
  "temperature": 0.3,
  "stop": ["\n\n"],
  "suffix": ""
}
```

#### Response Format

```json
{
  "id": "cmpl-67890",
  "object": "text_completion",
  "created": 1690123456,
  "model": "llama-3-instruct", 
  "choices": [
    {
      "text": "def fibonacci(n):\n    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)",
      "index": 0,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 15,
    "completion_tokens": 45,
    "total_tokens": 60
  }
}
```

### Embedding Generation

**Endpoint:** `POST http://192.168.10.31:11434/api/embeddings`

#### Request Format

```json
{
  "model": "llama-3-embeddings",
  "input": [
    "The quick brown fox jumps over the lazy dog",
    "Machine learning is a subset of artificial intelligence"
  ]
}
```

#### Response Format

```json
{
  "object": "list",
  "data": [
    {
      "object": "embedding",
      "embedding": [0.123, -0.456, 0.789, ...],
      "index": 0
    },
    {
      "object": "embedding", 
      "embedding": [0.321, -0.654, 0.987, ...],
      "index": 1
    }
  ],
  "model": "llama-3-embeddings",
  "usage": {
    "prompt_tokens": 20,
    "total_tokens": 20
  }
}
```

## Data Management APIs

### Vector Database (Qdrant)

**Base URL:** `http://192.168.10.30:6333`

#### Create Collection

```bash
curl -X PUT "http://192.168.10.30:6333/collections/my_collection" \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 4096,
      "distance": "Cosine"
    }
  }'
```

#### Insert Vectors

```bash
curl -X PUT "http://192.168.10.30:6333/collections/my_collection/points" \
  -H "Content-Type: application/json" \
  -d '{
    "points": [
      {
        "id": 1,
        "vector": [0.1, 0.2, 0.3, ...],
        "payload": {"text": "Sample document"}
      }
    ]
  }'
```

#### Search Vectors

```bash
curl -X POST "http://192.168.10.30:6333/collections/my_collection/points/search" \
  -H "Content-Type: application/json" \
  -d '{
    "vector": [0.1, 0.2, 0.3, ...],
    "limit": 10,
    "with_payload": true
  }'
```

### PostgreSQL Database

**Connection String:** `postgresql://username:password@192.168.10.35:5432/citadel_db`

#### Available Schemas

- **ai_models** - Model metadata and configurations
- **embeddings** - Vector embeddings and mappings
- **users** - User accounts and permissions
- **experiments** - ML experiment tracking
- **monitoring** - System metrics and logs

#### Example Queries

```sql
-- Get model performance metrics
SELECT 
    model_name,
    avg_inference_time_ms,
    total_requests,
    success_rate
FROM ai_models.performance_metrics
WHERE created_at >= NOW() - INTERVAL '24 hours';

-- Find similar embeddings
SELECT 
    doc_id,
    similarity_score
FROM embeddings.document_vectors
WHERE vector <-> $1 < 0.3
ORDER BY vector <-> $1
LIMIT 10;
```

### Redis Cache

**Connection:** `redis://192.168.10.35:6379`

#### Common Operations

```bash
# Cache model responses
SET "llama:chat:12345" '{"response": "Hello world", "tokens": 2}' EX 3600

# Get cached response
GET "llama:chat:12345"

# Cache user sessions
HSET "session:user123" "last_seen" "2025-07-28T10:30:00Z" "model_preference" "llama-3-chat"

# Get session data
HGETALL "session:user123"
```

## Infrastructure APIs

### API Gateway

**Base URL:** `http://192.168.10.39:8000`

All requests are routed through the API Gateway which provides:

- **Load Balancing** across AI model servers
- **Rate Limiting** and throttling
- **Request/Response Logging**
- **Authentication Validation**
- **API Versioning**

#### Health Check

```bash
curl "http://192.168.10.39:8000/health"
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2025-07-28T10:30:00Z",
  "services": {
    "llama_chat": "healthy",
    "llama_instruct": "healthy", 
    "embeddings": "healthy",
    "vector_db": "healthy",
    "database": "healthy"
  },
  "performance": {
    "avg_response_time_ms": 87,
    "requests_per_second": 1250
  }
}
```

#### Service Status

```bash
curl "http://192.168.10.39:8000/api/v1/status"
```

### Web Interface

**URL:** `http://192.168.10.38`

The OpenWebUI provides:

- **Interactive Chat Interface**
- **Model Selection**
- **Conversation History**
- **System Monitoring Dashboard**

## Monitoring APIs

### Prometheus Metrics

**Base URL:** `http://192.168.10.37:9090`

#### Key Metrics

```bash
# Query AI inference latency
curl "http://192.168.10.37:9090/api/v1/query?query=ai_inference_duration_seconds"

# Query GPU utilization
curl "http://192.168.10.37:9090/api/v1/query?query=nvidia_gpu_utilization_percentage"

# Query request rates
curl "http://192.168.10.37:9090/api/v1/query?query=rate(http_requests_total[5m])"
```

#### Custom Metrics

- `ai_inference_duration_seconds` - Model inference time
- `ai_queue_size` - Pending requests in queue
- `ai_model_memory_usage_bytes` - GPU memory consumption
- `vector_search_duration_seconds` - Vector database query time
- `cache_hit_ratio` - Redis cache effectiveness

### Grafana Dashboards

**Base URL:** `http://192.168.10.37:3000`

#### Available Dashboards

1. **AI Infrastructure Overview** - High-level system metrics
2. **Model Performance** - Inference times and accuracy
3. **Resource Utilization** - CPU, GPU, memory usage
4. **Network Performance** - Latency and throughput
5. **Error Monitoring** - Error rates and incident tracking

## Error Handling

### Standard Error Format

All APIs return errors in a consistent format:

```json
{
  "error": {
    "type": "validation_error",
    "message": "Invalid request parameters",
    "code": "INVALID_PARAMS",
    "details": {
      "field": "max_tokens",
      "issue": "Must be between 1 and 4000"
    },
    "request_id": "req_123456789"
  }
}
```

### Error Codes

| Code | Description | HTTP Status |
|------|-------------|-------------|
| `INVALID_AUTH` | Invalid or expired token | 401 |
| `INSUFFICIENT_PERMS` | Insufficient permissions | 403 |
| `INVALID_PARAMS` | Invalid request parameters | 400 |
| `MODEL_UNAVAILABLE` | AI model temporarily unavailable | 503 |
| `RATE_LIMITED` | Too many requests | 429 |
| `INTERNAL_ERROR` | Internal server error | 500 |
| `TIMEOUT` | Request timeout | 504 |

## Rate Limiting

### Default Limits

| Endpoint | Requests per Minute | Burst Limit |
|----------|-------------------|-------------|
| `/v1/chat/completions` | 60 | 10 |
| `/v1/completions` | 60 | 10 |
| `/api/embeddings` | 120 | 20 |
| `/collections/*/search` | 300 | 50 |
| `/health` | 600 | 100 |

### Rate Limit Headers

```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1690123456
X-RateLimit-Retry-After: 60
```

### Handling Rate Limits

```python
import time
import requests

def api_request_with_retry(url, data, headers, max_retries=3):
    for attempt in range(max_retries):
        response = requests.post(url, json=data, headers=headers)
        
        if response.status_code == 429:
            retry_after = int(response.headers.get('X-RateLimit-Retry-After', 60))
            time.sleep(retry_after)
            continue
            
        return response
    
    raise Exception("Max retries exceeded")
```

## SDK Examples

### Python SDK

```python
import openai
from typing import List, Dict, Any

class CXInfrastructureClient:
    def __init__(self, api_key: str, base_url: str = "http://192.168.10.39:8000"):
        self.client = openai.OpenAI(
            api_key=api_key,
            base_url=base_url
        )
    
    def chat_completion(
        self, 
        messages: List[Dict[str, str]], 
        model: str = "llama-3-chat",
        **kwargs
    ) -> Dict[str, Any]:
        """Generate chat completion using Llama 3 Chat model."""
        return self.client.chat.completions.create(
            model=model,
            messages=messages,
            **kwargs
        )
    
    def text_completion(
        self, 
        prompt: str, 
        model: str = "llama-3-instruct",
        **kwargs
    ) -> Dict[str, Any]:
        """Generate text completion using Llama 3 Instruct model."""
        return self.client.completions.create(
            model=model,
            prompt=prompt,
            **kwargs
        )
    
    def create_embedding(
        self, 
        texts: List[str], 
        model: str = "llama-3-embeddings"
    ) -> List[List[float]]:
        """Generate embeddings for text inputs."""
        response = self.client.embeddings.create(
            model=model,
            input=texts
        )
        return [item.embedding for item in response.data]

# Usage example
client = CXInfrastructureClient(api_key="your-jwt-token")

# Chat completion
response = client.chat_completion([
    {"role": "user", "content": "Explain machine learning"}
])
print(response.choices[0].message.content)

# Text completion
response = client.text_completion("def fibonacci(n):")
print(response.choices[0].text)

# Embeddings
embeddings = client.create_embedding([
    "Machine learning is fascinating",
    "AI will transform the world"
])
```

### JavaScript SDK

```javascript
class CXInfrastructureClient {
    constructor(apiKey, baseUrl = 'http://192.168.10.39:8000') {
        this.apiKey = apiKey;
        this.baseUrl = baseUrl;
    }
    
    async chatCompletion(messages, model = 'llama-3-chat', options = {}) {
        const response = await fetch(`${this.baseUrl}/v1/chat/completions`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${this.apiKey}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                model,
                messages,
                ...options
            })
        });
        
        return response.json();
    }
    
    async textCompletion(prompt, model = 'llama-3-instruct', options = {}) {
        const response = await fetch(`${this.baseUrl}/v1/completions`, {
            method: 'POST', 
            headers: {
                'Authorization': `Bearer ${this.apiKey}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                model,
                prompt,
                ...options
            })
        });
        
        return response.json();
    }
}

// Usage example
const client = new CXInfrastructureClient('your-jwt-token');

// Chat completion
const chatResponse = await client.chatCompletion([
    { role: 'user', content: 'Hello, world!' }
]);
console.log(chatResponse.choices[0].message.content);
```

### curl Examples

```bash
# Chat completion with streaming
curl -X POST "http://192.168.10.39:8000/v1/chat/completions" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3-chat",
    "messages": [
      {"role": "user", "content": "Write a haiku about AI"}
    ],
    "stream": true,
    "max_tokens": 100
  }' \
  --no-buffer

# Vector search
curl -X POST "http://192.168.10.30:6333/collections/documents/points/search" \
  -H "Content-Type: application/json" \
  -d '{
    "vector": [0.1, 0.2, 0.3, 0.4],
    "limit": 5,
    "with_payload": true,
    "filter": {
      "must": [
        {"key": "category", "match": {"value": "technology"}}
      ]
    }
  }'

# Health check with detailed info
curl "http://192.168.10.39:8000/health?detailed=true" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Best Practices

### Performance Optimization

1. **Batch Requests** when possible to reduce overhead
2. **Use Caching** for frequently accessed data
3. **Monitor Response Times** and adjust timeouts accordingly
4. **Implement Exponential Backoff** for retries

### Security Considerations

1. **Never Log JWT Tokens** or sensitive data
2. **Validate Input** before sending to APIs
3. **Use HTTPS** in production environments
4. **Rotate API Keys** regularly

### Error Handling

1. **Check Status Codes** before processing responses
2. **Parse Error Messages** for actionable information
3. **Implement Circuit Breakers** for external dependencies
4. **Log Errors** with request IDs for debugging

---

**Document Version:** 1.0  
**Last Updated:** July 28, 2025  
**Maintainers:** CX Infrastructure Team
