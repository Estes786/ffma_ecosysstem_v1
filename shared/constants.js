// Application-wide constants
export const API_ENDPOINTS = {
  BASE_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000',

  // Agent Factory
  AGENT_FACTORY: '/api/agent-factory',

  // Agents
  SENTIMENT_AGENT: '/api/sentiment-agent',
  RECOMMENDATION_AGENT: '/api/recommendation-agent',
  PERFORMANCE_MONITOR: '/api/performance-monitor',

  // Health checks
  HEALTH_CHECK: '/api/health',

  // Metrics
  METRICS: '/api/metrics'
};

// Database table names
export const TABLES = {
  TENANTS: 'tenants',
  USERS: 'users',
  AGENTS: 'agents',
  AGENT_TASKS: 'agent_tasks',
  AGENT_METRICS: 'agent_metrics',
  AGENT_LOGS: 'agent_logs',
  AGENT_DEPLOYMENTS: 'agent_deployments'
};

// Supabase configuration
export const SUPABASE_CONFIG = {
  URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
  ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,

  // Real-time channels
  CHANNELS: {
    AGENTS: 'agents-channel',
    TASKS: 'tasks-channel',
    METRICS: 'metrics-channel',
    LOGS: 'logs-channel'
  }
};

// HuggingFace models
export const HUGGINGFACE_MODELS = {
  SENTIMENT: 'cardiffnlp/twitter-roberta-base-sentiment-latest',
  EMBEDDINGS: 'sentence-transformers/all-MiniLM-L6-v2',
  CLASSIFICATION: 'facebook/bart-large-mnli',
  GENERATION: 'microsoft/DialoGPT-medium',
  EMOTION: 'j-hartmann/emotion-english-distilroberta-base'
};

// System configuration
export const SYSTEM_CONFIG = {
  // Pagination
  DEFAULT_PAGE_SIZE: 20,
  MAX_PAGE_SIZE: 100,

  // Timeouts (in milliseconds)
  API_TIMEOUT: 30000,
  DATABASE_TIMEOUT: 10000,
  REALTIME_TIMEOUT: 5000,

  // Retry configuration
  MAX_RETRIES: 3,
  RETRY_DELAY: 1000,

  // Performance thresholds
  PERFORMANCE_THRESHOLDS: {
    RESPONSE_TIME: 2000,
    SUCCESS_RATE: 0.95,
    ERROR_RATE: 0.05,
    HEALTH_SCORE: 0.8
  },

  // Monitoring intervals
  MONITORING_INTERVALS: {
    HEALTH_CHECK: 60000,      // 1 minute
    METRICS_COLLECTION: 300000, // 5 minutes
    LOG_CLEANUP: 3600000      // 1 hour
  }
};

// UI Configuration
export const UI_CONFIG = {
  COLORS: {
    PRIMARY: '#6366f1',
    SECONDARY: '#8b5cf6',
    SUCCESS: '#10b981',
    WARNING: '#f59e0b',
    ERROR: '#ef4444',
    INFO: '#06b6d4'
  },

  THEMES: {
    LIGHT: 'light',
    DARK: 'dark',
    SYSTEM: 'system'
  },

  ANIMATIONS: {
    DURATION: 300,
    EASING: 'ease-in-out'
  }
};

// Mobile app configuration
export const MOBILE_CONFIG = {
  FLUTTER: {
    PACKAGE_NAME: 'com.fmaa.ecosystem',
    APP_NAME: 'FMAA Dashboard',
    VERSION: '1.0.0+1'
  },

  NAVIGATION: {
    TABS: ['Dashboard', 'Agents', 'Tasks'],
    INITIAL_TAB: 0
  },

  REFRESH_INTERVALS: {
    DASHBOARD: 30000,
    AGENTS: 60000,
    TASKS: 45000
  }
};

// Security configuration
export const SECURITY_CONFIG = {
  JWT: {
    ALGORITHM: 'HS256',
    EXPIRATION: '24h',
    REFRESH_EXPIRATION: '7d'
  },

  CORS: {
    ALLOWED_ORIGINS: [
      'http://localhost:3000',
      'https://fmaa-ecosystem.vercel.app'
    ],
    ALLOWED_METHODS: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    ALLOWED_HEADERS: ['Content-Type', 'Authorization', 'X-Tenant-ID']
  },

  RATE_LIMITING: {
    WINDOW_MS: 900000, // 15 minutes
    MAX_REQUESTS: 100
  }
};

// Export all constants
export default {
  API_ENDPOINTS,
  TABLES,
  SUPABASE_CONFIG,
  HUGGINGFACE_MODELS,
  SYSTEM_CONFIG,
  UI_CONFIG,
  MOBILE_CONFIG,
  SECURITY_CONFIG
};
