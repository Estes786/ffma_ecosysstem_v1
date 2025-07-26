# API Reference ðŸ“š

## Base URL
```
Production: https://your-app.vercel.app/api
Development: http://localhost:3000/api
```

## Authentication
All API endpoints require authentication using JWT tokens:
```
Authorization: Bearer <jwt_token>
```

## Endpoints

### Agent Factory

#### List Agents
```http
GET /api/agent-factory
```

**Query Parameters:**
- `status` (optional): Filter by agent status
- `type` (optional): Filter by agent type
- `limit` (optional): Number of results (default: 50)
- `offset` (optional): Pagination offset

**Response:**
```json
{
  "success": true,
  "data": {
    "agents": [
      {
        "id": "uuid",
        "name": "Sentiment Agent",
        "type": "sentiment",
        "status": "active",
        "version": "1.0.0",
        "created_at": "2024-01-01T00:00:00Z",
        "config": {}
      }
    ],
    "total": 10,
    "stats": {
      "active": 5,
      "inactive": 3,
      "error": 2
    }
  }
}
```

#### Create Agent
```http
POST /api/agent-factory
```

**Request Body:**
```json
{
  "name": "My Sentiment Agent",
  "type": "sentiment",
  "config": {
    "model": "cardiffnlp/twitter-roberta-base-sentiment-latest"
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "My Sentiment Agent",
    "type": "sentiment",
    "status": "inactive",
    "endpoint_url": "/api/sentiment-agent",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

#### Update Agent
```http
PUT /api/agent-factory/{id}
```

#### Delete Agent
```http
DELETE /api/agent-factory/{id}
```

### Sentiment Agent

#### Analyze Sentiment
```http
POST /api/sentiment-agent
```

**Request Body:**
```json
{
  "agent_id": "uuid",
  "input_data": {
    "text": "I love this product!",
    "batch": false
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "task_id": "uuid",
    "result": {
      "sentiment": "positive",
      "confidence": 0.95,
      "scores": {
        "positive": 0.95,
        "negative": 0.03,
        "neutral": 0.02
      }
    },
    "processing_time": 150
  }
}
```

#### Health Check
```http
GET /api/sentiment-agent/health
```

### Recommendation Agent

#### Get Recommendations
```http
POST /api/recommendation-agent
```

**Request Body:**
```json
{
  "agent_id": "uuid",
  "input_data": {
    "text": "Looking for action movies",
    "items": ["Movie 1", "Movie 2", "Movie 3"],
    "threshold": 0.7
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "task_id": "uuid",
    "result": {
      "recommendations": [
        {
          "item": "Movie 1",
          "similarity": 0.85,
          "confidence": 0.92
        }
      ]
    }
  }
}
```

### Performance Monitor

#### Get System Report
```http
GET /api/performance-monitor/report
```

**Response:**
```json
{
  "success": true,
  "data": {
    "system_health": {
      "overall_score": 85,
      "status": "healthy"
    },
    "agents": {
      "total": 10,
      "active": 8,
      "issues": 2
    },
    "performance": {
      "avg_response_time": 180,
      "error_rate": 0.02,
      "uptime": 99.9
    }
  }
}
```

## Error Handling

All endpoints return consistent error responses:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": {
      "field": "text",
      "issue": "Required field missing"
    }
  }
}
```

### Error Codes
- `VALIDATION_ERROR`: Invalid request data
- `AUTHENTICATION_ERROR`: Invalid or missing token
- `AUTHORIZATION_ERROR`: Insufficient permissions
- `AGENT_NOT_FOUND`: Agent doesn't exist
- `TASK_FAILED`: Agent processing failed
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `INTERNAL_ERROR`: Server error

## Rate Limiting

API endpoints are rate-limited:
- **Free tier**: 100 requests/hour
- **Pro tier**: 1000 requests/hour
- **Enterprise**: Custom limits

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1642723200
```

## Webhooks

Configure webhooks to receive real-time notifications:

### Task Completion
```json
{
  "event": "task.completed",
  "data": {
    "task_id": "uuid",
    "agent_id": "uuid",
    "status": "completed",
    "result": {}
  }
}
```

### Agent Status Change
```json
{
  "event": "agent.status_changed",
  "data": {
    "agent_id": "uuid",
    "old_status": "active",
    "new_status": "error"
  }
}
```
