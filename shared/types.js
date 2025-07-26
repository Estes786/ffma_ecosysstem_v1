// Shared TypeScript-style type definitions and constants
// Agent Types
export const AGENT_TYPES = {
  SENTIMENT: 'sentiment-analysis',
  RECOMMENDATION: 'recommendation',
  PERFORMANCE: 'performance-monitor',
  CUSTOM: 'custom'
};

// Agent Status
export const AGENT_STATUS = {
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  PENDING: 'pending',
  ERROR: 'error',
  DEPLOYED: 'deployed'
};

// Task Status
export const TASK_STATUS = {
  PENDING: 'pending',
  PROCESSING: 'processing',
  COMPLETED: 'completed',
  FAILED: 'failed',
  CANCELLED: 'cancelled'
};

// Task Priority
export const TASK_PRIORITY = {
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high',
  CRITICAL: 'critical'
};

// Agent Configuration Types
export const AGENT_CONFIG_TYPES = {
  SENTIMENT: {
    model: 'cardiffnlp/twitter-roberta-base-sentiment-latest',
    threshold: 0.5,
    batch_size: 10
  },
  RECOMMENDATION: {
    model: 'sentence-transformers/all-MiniLM-L6-v2',
    similarity_threshold: 0.7,
    max_results: 20
  },
  PERFORMANCE: {
    monitoring_interval: 300000, // 5 minutes
    health_check_timeout: 30000,
    alert_threshold: 0.8
  }
};

// HTTP Status Codes
export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL_SERVER_ERROR: 500
};

// Metric Types
export const METRIC_TYPES = {
  RESPONSE_TIME: 'response_time',
  SUCCESS_RATE: 'success_rate',
  ERROR_RATE: 'error_rate',
  THROUGHPUT: 'throughput',
  UPTIME: 'uptime',
  HEALTH_SCORE: 'health_score'
};

// Log Levels
export const LOG_LEVELS = {
  DEBUG: 'debug',
  INFO: 'info',
  WARN: 'warn',
  ERROR: 'error',
  FATAL: 'fatal'
};

// Permissions
export const PERMISSIONS = {
  READ_AGENTS: 'read:agents',
  WRITE_AGENTS: 'write:agents',
  DELETE_AGENTS: 'delete:agents',
  READ_TASKS: 'read:tasks',
  WRITE_TASKS: 'write:tasks',
  DELETE_TASKS: 'delete:tasks',
  READ_METRICS: 'read:metrics',
  ADMIN: 'admin'
};

// Error Types
export const ERROR_TYPES = {
  VALIDATION_ERROR: 'validation_error',
  AUTHENTICATION_ERROR: 'authentication_error',
  AUTHORIZATION_ERROR: 'authorization_error',
  NOT_FOUND_ERROR: 'not_found_error',
  INTERNAL_ERROR: 'internal_error',
  API_ERROR: 'api_error',
  NETWORK_ERROR: 'network_error'
};

// Default configurations
export const DEFAULT_CONFIGS = {
  PAGINATION: {
    limit: 20,
    offset: 0
  },
  TIMEOUT: {
    api: 30000,
    database: 10000
  },
  RETRY: {
    attempts: 3,
    delay: 1000
  }
};

// Validation schemas
export const VALIDATION_SCHEMAS = {
  AGENT: {
    name: { required: true, minLength: 1, maxLength: 100 },
    type: { required: true, enum: Object.values(AGENT_TYPES) },
    config: { required: false, type: 'object' }
  },
  TASK: {
    agent_id: { required: true, type: 'string' },
    input_data: { required: true, type: 'object' },
    priority: { required: false, enum: Object.values(TASK_PRIORITY) }
  }
};

// Export for easier usage
export default {
  AGENT_TYPES,
  AGENT_STATUS,
  TASK_STATUS,
  TASK_PRIORITY,
  AGENT_CONFIG_TYPES,
  HTTP_STATUS,
  METRIC_TYPES,
  LOG_LEVELS,
  PERMISSIONS,
  ERROR_TYPES,
  DEFAULT_CONFIGS,
  VALIDATION_SCHEMAS
};
