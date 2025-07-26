const { AgentDatabase, LogDatabase, generateId, formatError } = require('./utils/database');
const { authenticate, enforceTenantIsolation } = require('./utils/auth');

const agentDb = new AgentDatabase();
const logDb = new LogDatabase();

// Default configurations for different agent types
const DEFAULT_CONFIGS = {
  sentiment: {
    model: 'cardiffnlp/twitter-roberta-base-sentiment-latest',
    batch_size: 10,
    confidence_threshold: 0.7
  },
  recommendation: {
    model: 'sentence-transformers/all-MiniLM-L6-v2',
    similarity_threshold: 0.7,
    max_recommendations: 10
  },
  performance: {
    check_interval: 300, // 5 minutes
    alert_threshold: 0.8,
    metrics_retention: 30 // days
  }
};

// CORS headers
const setCorsHeaders = (res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
};

export default async function handler(req, res) {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    // Authentication middleware
    await new Promise((resolve, reject) => {
      authenticate(req, res, (error) => {
        if (error) reject(error);
        else resolve();
      });
    });

    await new Promise((resolve, reject) => {
      enforceTenantIsolation(req, res, (error) => {
        if (error) reject(error);
        else resolve();
      });
    });

    switch (req.method) {
      case 'POST':
        return await createAgent(req, res);
      case 'GET':
        return await listAgents(req, res);
      case 'PUT':
        return await updateAgent(req, res);
      case 'DELETE':
        return await deleteAgent(req, res);
      default:
        return res.status(405).json({ error: 'Method not allowed' });
    }
  } catch (error) {
    console.error('Agent Factory Error:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      details: formatError(error)
    });
  }
}

async function createAgent(req, res) {
  try {
    const { name, type, description, config = {} } = req.body;

    if (!name || !type) {
      return res.status(400).json({ 
        error: 'Name and type are required' 
      });
    }

    // Validate agent type
    if (!['sentiment', 'recommendation', 'performance'].includes(type)) {
      return res.status(400).json({ 
        error: 'Invalid agent type. Must be: sentiment, recommendation, or performance' 
      });
    }

    // Merge with default config
    const mergedConfig = {
      ...DEFAULT_CONFIGS[type],
      ...config
    };

    const agentData = {
      tenant_id: req.tenantId,
      name,
      type,
      description: description || `${type} analysis agent`,
      status: 'inactive',
      version: '1.0.0',
      endpoint_url: `/api/${type}-agent`,
      config: mergedConfig,
      created_by: req.user.id
    };

    const agent = await agentDb.createAgent(agentData);

    // Log agent creation
    await logDb.insertLog({
      tenant_id: req.tenantId,
      agent_id: agent.id,
      level: 'info',
      message: `Agent created: ${name}`,
      metadata: { type, config: mergedConfig }
    });

    res.status(201).json({
      success: true,
      data: agent,
      message: 'Agent created successfully'
    });
  } catch (error) {
    console.error('Create Agent Error:', error);
    res.status(500).json({ 
      error: 'Failed to create agent',
      details: formatError(error)
    });
  }
}

async function listAgents(req, res) {
  try {
    const { status, type, page = 1, limit = 10 } = req.query;

    const filters = {
      tenant_id: req.tenantId
    };

    if (status) filters.status = status;
    if (type) filters.type = type;

    const agents = await agentDb.getAgents(filters);

    // Calculate pagination
    const startIndex = (parseInt(page) - 1) * parseInt(limit);
    const endIndex = startIndex + parseInt(limit);
    const paginatedAgents = agents.slice(startIndex, endIndex);

    // Get statistics
    const stats = {
      total: agents.length,
      active: agents.filter(a => a.status === 'active').length,
      inactive: agents.filter(a => a.status === 'inactive').length,
      by_type: {
        sentiment: agents.filter(a => a.type === 'sentiment').length,
        recommendation: agents.filter(a => a.type === 'recommendation').length,
        performance: agents.filter(a => a.type === 'performance').length
      }
    };

    res.json({
      success: true,
      data: paginatedAgents,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: agents.length,
        pages: Math.ceil(agents.length / parseInt(limit))
      },
      statistics: stats
    });
  } catch (error) {
    console.error('List Agents Error:', error);
    res.status(500).json({ 
      error: 'Failed to list agents',
      details: formatError(error)
    });
  }
}

async function updateAgent(req, res) {
  try {
    const { id } = req.query;
    const updates = req.body;

    if (!id) {
      return res.status(400).json({ error: 'Agent ID is required' });
    }

    // Get existing agent to verify ownership
    const existingAgent = await agentDb.getAgentById(id);
    if (existingAgent.tenant_id !== req.tenantId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const updatedAgent = await agentDb.updateAgent(id, updates);

    // Log agent update
    await logDb.insertLog({
      tenant_id: req.tenantId,
      agent_id: id,
      level: 'info',
      message: `Agent updated: ${updatedAgent.name}`,
      metadata: { updates }
    });

    res.json({
      success: true,
      data: updatedAgent,
      message: 'Agent updated successfully'
    });
  } catch (error) {
    console.error('Update Agent Error:', error);
    res.status(500).json({ 
      error: 'Failed to update agent',
      details: formatError(error)
    });
  }
}

async function deleteAgent(req, res) {
  try {
    const { id } = req.query;

    if (!id) {
      return res.status(400).json({ error: 'Agent ID is required' });
    }

    // Get existing agent to verify ownership
    const existingAgent = await agentDb.getAgentById(id);
    if (existingAgent.tenant_id !== req.tenantId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await agentDb.deleteAgent(id);

    // Log agent deletion
    await logDb.insertLog({
      tenant_id: req.tenantId,
      agent_id: id,
      level: 'info',
      message: `Agent deleted: ${existingAgent.name}`,
      metadata: { deleted_agent: existingAgent }
    });

    res.json({
      success: true,
      message: 'Agent deleted successfully'
    });
  } catch (error) {
    console.error('Delete Agent Error:', error);
    res.status(500).json({ 
      error: 'Failed to delete agent',
      details: formatError(error)
    });
  }
}
