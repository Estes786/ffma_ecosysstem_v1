const { createClient } = require('@supabase/supabase-js');
const { v4: uuidv4 } = require('uuid');

// Initialize Supabase clients
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

class AgentDatabase {
  constructor() {
    this.client = supabase;
    this.adminClient = supabaseAdmin;
  }

  async createAgent(agentData) {
    const { data, error } = await this.client
      .from('agents')
      .insert([{
        id: uuidv4(),
        ...agentData,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }])
      .select();

    if (error) throw error;
    return data[0];
  }

  async getAgents(filters = {}) {
    let query = this.client.from('agents').select('*');

    if (filters.tenant_id) {
      query = query.eq('tenant_id', filters.tenant_id);
    }
    if (filters.status) {
      query = query.eq('status', filters.status);
    }
    if (filters.type) {
      query = query.eq('type', filters.type);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data;
  }

  async updateAgent(id, updates) {
    const { data, error } = await this.client
      .from('agents')
      .update({
        ...updates,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select();

    if (error) throw error;
    return data[0];
  }

  async deleteAgent(id) {
    const { error } = await this.client
      .from('agents')
      .delete()
      .eq('id', id);

    if (error) throw error;
    return true;
  }

  async getAgentById(id) {
    const { data, error } = await this.client
      .from('agents')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data;
  }
}

class TaskDatabase {
  constructor() {
    this.client = supabase;
  }

  async createTask(taskData) {
    const { data, error } = await this.client
      .from('agent_tasks')
      .insert([{
        id: uuidv4(),
        ...taskData,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }])
      .select();

    if (error) throw error;
    return data[0];
  }

  async getTasks(filters = {}) {
    let query = this.client.from('agent_tasks').select('*');

    if (filters.agent_id) {
      query = query.eq('agent_id', filters.agent_id);
    }
    if (filters.status) {
      query = query.eq('status', filters.status);
    }
    if (filters.tenant_id) {
      query = query.eq('tenant_id', filters.tenant_id);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data;
  }

  async updateTask(id, updates) {
    const { data, error } = await this.client
      .from('agent_tasks')
      .update({
        ...updates,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select();

    if (error) throw error;
    return data[0];
  }

  async getTaskById(id) {
    const { data, error } = await this.client
      .from('agent_tasks')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    return data;
  }
}

class MetricsDatabase {
  constructor() {
    this.client = supabase;
  }

  async recordMetrics(metricsData) {
    const { data, error } = await this.client
      .from('agent_metrics')
      .insert([{
        id: uuidv4(),
        ...metricsData,
        created_at: new Date().toISOString()
      }])
      .select();

    if (error) throw error;
    return data[0];
  }

  async getMetrics(filters = {}) {
    let query = this.client.from('agent_metrics').select('*');

    if (filters.agent_id) {
      query = query.eq('agent_id', filters.agent_id);
    }
    if (filters.tenant_id) {
      query = query.eq('tenant_id', filters.tenant_id);
    }
    if (filters.from_date) {
      query = query.gte('created_at', filters.from_date);
    }
    if (filters.to_date) {
      query = query.lte('created_at', filters.to_date);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data;
  }
}

class LogDatabase {
  constructor() {
    this.client = supabase;
  }

  async insertLog(logData) {
    const { data, error } = await this.client
      .from('agent_logs')
      .insert([{
        id: uuidv4(),
        ...logData,
        created_at: new Date().toISOString()
      }])
      .select();

    if (error) throw error;
    return data[0];
  }

  async getLogs(filters = {}) {
    let query = this.client.from('agent_logs').select('*');

    if (filters.agent_id) {
      query = query.eq('agent_id', filters.agent_id);
    }
    if (filters.level) {
      query = query.eq('level', filters.level);
    }
    if (filters.tenant_id) {
      query = query.eq('tenant_id', filters.tenant_id);
    }

    const { data, error } = await query.order('created_at', { ascending: false });
    if (error) throw error;
    return data;
  }
}

class RealtimeDatabase {
  constructor() {
    this.client = supabase;
    this.subscriptions = new Map();
  }

  subscribeToAgents(callback) {
    const channel = this.client
      .channel('agents')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'agents' }, callback)
      .subscribe();

    this.subscriptions.set('agents', channel);
    return channel;
  }

  subscribeToTasks(callback) {
    const channel = this.client
      .channel('agent_tasks')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'agent_tasks' }, callback)
      .subscribe();

    this.subscriptions.set('agent_tasks', channel);
    return channel;
  }

  unsubscribe(channelName) {
    const channel = this.subscriptions.get(channelName);
    if (channel) {
      this.client.removeChannel(channel);
      this.subscriptions.delete(channelName);
    }
  }

  unsubscribeAll() {
    this.subscriptions.forEach((channel) => {
      this.client.removeChannel(channel);
    });
    this.subscriptions.clear();
  }
}

// Utility functions
const generateId = () => uuidv4();

const formatError = (error) => {
  return {
    message: error.message,
    code: error.code,
    details: error.details,
    timestamp: new Date().toISOString()
  };
};

module.exports = {
  AgentDatabase,
  TaskDatabase,
  MetricsDatabase,
  LogDatabase,
  RealtimeDatabase,
  generateId,
  formatError,
  supabase,
  supabaseAdmin
};
