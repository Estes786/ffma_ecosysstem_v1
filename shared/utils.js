// Shared utility functions
import { v4 as uuidv4 } from 'uuid';
import { HTTP_STATUS, ERROR_TYPES, LOG_LEVELS } from './types.js';

// ID Generation
export const generateId = (prefix = '') => {
  return prefix ? `${prefix}_${uuidv4()}` : uuidv4();
};

// Date utilities
export const formatDate = (date) => {
  return new Date(date).toISOString();
};

export const formatRelativeTime = (date) => {
  const now = new Date();
  const diff = now - new Date(date);

  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (days > 0) return `${days} day${days > 1 ? 's' : ''} ago`;
  if (hours > 0) return `${hours} hour${hours > 1 ? 's' : ''} ago`;
  if (minutes > 0) return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
  return 'Just now';
};

// Validation utilities
export const validateEmail = (email) => {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
};

export const validateRequired = (value, fieldName) => {
  if (!value || value.toString().trim() === '') {
    throw new Error(`${fieldName} is required`);
  }
};

export const validateLength = (value, min, max, fieldName) => {
  if (value.length < min || value.length > max) {
    throw new Error(`${fieldName} must be between ${min} and ${max} characters`);
  }
};

// Error handling utilities
export const formatError = (error, context = '') => {
  const errorObj = {
    message: error.message || 'Unknown error',
    type: error.type || ERROR_TYPES.INTERNAL_ERROR,
    context: context,
    timestamp: new Date().toISOString(),
    stack: error.stack || null
  };

  return errorObj;
};

export const createApiError = (message, statusCode = HTTP_STATUS.INTERNAL_SERVER_ERROR, type = ERROR_TYPES.API_ERROR) => {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.type = type;
  return error;
};

// Response formatting
export const formatResponse = (data, message = 'Success', statusCode = HTTP_STATUS.OK) => {
  return {
    success: true,
    data: data,
    message: message,
    timestamp: new Date().toISOString(),
    statusCode: statusCode
  };
};

export const formatErrorResponse = (error, statusCode = HTTP_STATUS.INTERNAL_SERVER_ERROR) => {
  return {
    success: false,
    error: {
      message: error.message || 'Internal server error',
      type: error.type || ERROR_TYPES.INTERNAL_ERROR,
      code: error.code || 'UNKNOWN_ERROR'
    },
    timestamp: new Date().toISOString(),
    statusCode: statusCode
  };
};

// Logging utilities
export const logMessage = (level, message, context = {}) => {
  const logEntry = {
    level: level,
    message: message,
    context: context,
    timestamp: new Date().toISOString(),
    source: 'FMAA-ECOSYSTEM'
  };

  // In production, send to logging service
  if (process.env.NODE_ENV === 'production') {
    // TODO: Send to logging service
  } else {
    console.log(JSON.stringify(logEntry, null, 2));
  }

  return logEntry;
};

export const logInfo = (message, context = {}) => {
  return logMessage(LOG_LEVELS.INFO, message, context);
};

export const logError = (message, context = {}) => {
  return logMessage(LOG_LEVELS.ERROR, message, context);
};

export const logWarn = (message, context = {}) => {
  return logMessage(LOG_LEVELS.WARN, message, context);
};

export const logDebug = (message, context = {}) => {
  return logMessage(LOG_LEVELS.DEBUG, message, context);
};

// Data manipulation utilities
export const deepMerge = (target, source) => {
  const result = { ...target };

  for (const key in source) {
    if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
      result[key] = deepMerge(result[key] || {}, source[key]);
    } else {
      result[key] = source[key];
    }
  }

  return result;
};

export const isEmpty = (obj) => {
  return Object.keys(obj).length === 0 && obj.constructor === Object;
};

export const omit = (obj, keys) => {
  const result = { ...obj };
  keys.forEach(key => delete result[key]);
  return result;
};

export const pick = (obj, keys) => {
  const result = {};
  keys.forEach(key => {
    if (key in obj) {
      result[key] = obj[key];
    }
  });
  return result;
};

// Array utilities
export const chunk = (array, size) => {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
};

export const unique = (array) => {
  return [...new Set(array)];
};

export const groupBy = (array, key) => {
  return array.reduce((groups, item) => {
    const value = item[key];
    if (!groups[value]) {
      groups[value] = [];
    }
    groups[value].push(item);
    return groups;
  }, {});
};

// Performance utilities
export const debounce = (func, delay) => {
  let timeoutId;
  return (...args) => {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => func.apply(null, args), delay);
  };
};

export const throttle = (func, limit) => {
  let inThrottle;
  return (...args) => {
    if (!inThrottle) {
      func.apply(null, args);
      inThrottle = true;
      setTimeout(() => inThrottle = false, limit);
    }
  };
};

// Async utilities
export const sleep = (ms) => {
  return new Promise(resolve => setTimeout(resolve, ms));
};

export const retry = async (fn, attempts = 3, delay = 1000) => {
  for (let i = 0; i < attempts; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === attempts - 1) throw error;
      await sleep(delay * Math.pow(2, i)); // Exponential backoff
    }
  }
};

export const timeout = (promise, ms) => {
  return Promise.race([
    promise,
    new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Operation timed out')), ms)
    )
  ]);
};

// String utilities
export const capitalize = (str) => {
  return str.charAt(0).toUpperCase() + str.slice(1);
};

export const camelCase = (str) => {
  return str.replace(/-([a-z])/g, (match, letter) => letter.toUpperCase());
};

export const kebabCase = (str) => {
  return str.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
};

export const truncate = (str, length, suffix = '...') => {
  if (str.length <= length) return str;
  return str.substring(0, length) + suffix;
};

// Number utilities
export const formatNumber = (num, decimals = 2) => {
  return Number(num).toFixed(decimals);
};

export const formatPercentage = (num, decimals = 1) => {
  return `${(num * 100).toFixed(decimals)}%`;
};

export const formatBytes = (bytes, decimals = 2) => {
  if (bytes === 0) return '0 Bytes';

  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(decimals)) + ' ' + sizes[i];
};

// Export all utilities
export default {
  generateId,
  formatDate,
  formatRelativeTime,
  validateEmail,
  validateRequired,
  validateLength,
  formatError,
  createApiError,
  formatResponse,
  formatErrorResponse,
  logMessage,
  logInfo,
  logError,
  logWarn,
  logDebug,
  deepMerge,
  isEmpty,
  omit,
  pick,
  chunk,
  unique,
  groupBy,
  debounce,
  throttle,
  sleep,
  retry,
  timeout,
  capitalize,
  camelCase,
  kebabCase,
  truncate,
  formatNumber,
  formatPercentage,
  formatBytes
};
