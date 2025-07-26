const jwt = require('jsonwebtoken');
const { supabase } = require('./database');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

class AuthManager {
  constructor() {
    this.jwtSecret = JWT_SECRET;
  }

  async verifyToken(token) {
    try {
      const { data: { user }, error } = await supabase.auth.getUser(token);

      if (error) throw error;
      return user;
    } catch (error) {
      throw new Error(`Token verification failed: ${error.message}`);
    }
  }

  async getUserTenant(userId) {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('tenant_id')
        .eq('id', userId)
        .single();

      if (error) throw error;
      return data.tenant_id;
    } catch (error) {
      throw new Error(`Failed to get user tenant: ${error.message}`);
    }
  }

  async checkPermission(userId, resource, action) {
    // Simple permission check - can be extended
    try {
      const { data, error } = await supabase
        .from('users')
        .select('role')
        .eq('id', userId)
        .single();

      if (error) throw error;

      const userRole = data.role;
      return this.hasPermission(userRole, resource, action);
    } catch (error) {
      throw new Error(`Permission check failed: ${error.message}`);
    }
  }

  hasPermission(role, resource, action) {
    const permissions = {
      'admin': ['*'],
      'user': ['read', 'create'],
      'viewer': ['read']
    };

    const userPermissions = permissions[role] || [];
    return userPermissions.includes('*') || userPermissions.includes(action);
  }

  generateApiKey(userId, tenantId) {
    const payload = {
      userId,
      tenantId,
      type: 'api_key',
      issued_at: new Date().toISOString()
    };

    return jwt.sign(payload, this.jwtSecret);
  }

  verifyApiKey(apiKey) {
    try {
      const decoded = jwt.verify(apiKey, this.jwtSecret);
      return decoded;
    } catch (error) {
      throw new Error(`API key verification failed: ${error.message}`);
    }
  }
}

// Middleware for API authentication
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({ error: 'Authorization header required' });
    }

    const token = authHeader.replace('Bearer ', '');
    const authManager = new AuthManager();

    const user = await authManager.verifyToken(token);
    req.user = user;
    req.tenantId = await authManager.getUserTenant(user.id);

    next();
  } catch (error) {
    return res.status(401).json({ error: error.message });
  }
};

// Middleware for tenant isolation
const enforceTenantIsolation = (req, res, next) => {
  if (!req.tenantId) {
    return res.status(403).json({ error: 'Tenant context required' });
  }

  // Add tenant filter to all queries
  req.tenantFilter = { tenant_id: req.tenantId };
  next();
};

module.exports = {
  AuthManager,
  authenticate,
  enforceTenantIsolation
};
