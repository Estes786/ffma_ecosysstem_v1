-- FMAA Database Schema
-- PostgreSQL/Supabase Database untuk Federated Micro-Agents Architecture

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable Row Level Security


-- ========================================
-- CORE TABLES
-- ========================================

-- 1. Tenants Table (Multi-tenancy support)
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255) UNIQUE,
    status VARCHAR(50) DEFAULT 'active',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Users Table (User management)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    status VARCHAR(50) DEFAULT 'active',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Agents Table (Agent registry)
CREATE TABLE IF NOT EXISTS agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100) NOT NULL, -- 'sentiment', 'recommendation', 'performance'
    status VARCHAR(50) DEFAULT 'inactive', -- 'active', 'inactive', 'error'
    version VARCHAR(50) DEFAULT '1.0.0',
    config JSONB DEFAULT '{}',
    endpoint_url VARCHAR(500),
    description TEXT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Agent Tasks Table (Task management)
CREATE TABLE IF NOT EXISTS agent_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    task_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    priority INTEGER DEFAULT 1,
    input_data JSONB,
    output_data JSONB,
    error_message TEXT,
    execution_time INTEGER, -- in milliseconds
    created_by UUID REFERENCES users(id),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Agent Metrics Table (Performance data)
CREATE TABLE IF NOT EXISTS agent_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    metric_type VARCHAR(100) NOT NULL,
    value DECIMAL(10,2),
    unit VARCHAR(50),
    metadata JSONB DEFAULT '{}',
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Agent Logs Table (System logging)
CREATE TABLE IF NOT EXISTS agent_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    level VARCHAR(20) NOT NULL, -- 'info', 'warn', 'error', 'debug'
    message TEXT NOT NULL,
    context JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Agent Deployments Table (Deployment tracking)
CREATE TABLE IF NOT EXISTS agent_deployments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    version VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'deployed', -- 'deployed', 'rolling_back', 'failed'
    config JSONB DEFAULT '{}',
    deployed_by UUID REFERENCES users(id),
    deployed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- TRIGGERS FOR UPDATED_AT
-- ========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tenants_updated_at BEFORE UPDATE ON tenants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_agents_updated_at BEFORE UPDATE ON agents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_agent_tasks_updated_at BEFORE UPDATE ON agent_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================

CREATE INDEX IF NOT EXISTS idx_users_tenant_id ON users(tenant_id);
CREATE INDEX IF NOT EXISTS idx_agents_tenant_id ON agents(tenant_id);
CREATE INDEX IF NOT EXISTS idx_agents_type ON agents(type);
CREATE INDEX IF NOT EXISTS idx_agents_status ON agents(status);
CREATE INDEX IF NOT EXISTS idx_agent_tasks_agent_id ON agent_tasks(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_tasks_tenant_id ON agent_tasks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_agent_tasks_status ON agent_tasks(status);
CREATE INDEX IF NOT EXISTS idx_agent_metrics_agent_id ON agent_metrics(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_logs_agent_id ON agent_logs(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_logs_level ON agent_logs(level);

-- ========================================
-- ROW LEVEL SECURITY POLICIES
-- ========================================

-- Enable RLS on all tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_deployments ENABLE ROW LEVEL SECURITY;

-- Tenant isolation policies
CREATE POLICY "Users can access their own tenant data" ON tenants
    FOR ALL USING (auth.jwt() ->> 'tenant_id' = id::text);

CREATE POLICY "Users can access their own tenant users" ON users
    FOR ALL USING (auth.jwt() ->> 'tenant_id' = tenant_id::text);

CREATE POLICY "Users can access their own tenant agents" ON agents
    FOR ALL USING (auth.jwt() ->> 'tenant_id' = tenant_id::text);

CREATE POLICY "Users can access their own tenant tasks" ON agent_tasks
    FOR ALL USING (auth.jwt() ->> 'tenant_id' = tenant_id::text);

CREATE POLICY "Users can access their own tenant metrics" ON agent_metrics
    FOR ALL USING (auth.jwt() ->> 'tenant_id' = tenant_id::text);

CREATE POLICY "Users can access their own tenant logs" ON agent_logs
    FOR ALL USING (auth.jwt() ->> 'tenant_id' = tenant_id::text);

CREATE POLICY "Users can access their own tenant deployments" ON agent_deployments
    FOR ALL USING (auth.jwt() ->> 'tenant_id' = tenant_id::text);

-- ========================================
-- VIEWS FOR COMMON QUERIES
-- ========================================

-- Agent status overview
CREATE OR REPLACE VIEW agent_status_overview AS
SELECT 
    t.name as tenant_name,
    a.type as agent_type,
    COUNT(*) as total_agents,
    COUNT(CASE WHEN a.status = 'active' THEN 1 END) as active_agents,
    COUNT(CASE WHEN a.status = 'inactive' THEN 1 END) as inactive_agents,
    COUNT(CASE WHEN a.status = 'error' THEN 1 END) as error_agents
FROM agents a
JOIN tenants t ON a.tenant_id = t.id
GROUP BY t.name, a.type;

-- Task statistics
CREATE OR REPLACE VIEW task_statistics AS
SELECT 
    a.name as agent_name,
    a.type as agent_type,
    COUNT(*) as total_tasks,
    COUNT(CASE WHEN at.status = 'completed' THEN 1 END) as completed_tasks,
    COUNT(CASE WHEN at.status = 'failed' THEN 1 END) as failed_tasks,
    COUNT(CASE WHEN at.status = 'pending' THEN 1 END) as pending_tasks,
    AVG(at.execution_time) as avg_execution_time
FROM agent_tasks at
JOIN agents a ON at.agent_id = a.id
GROUP BY a.id, a.name, a.type;

-- ========================================
-- STORED FUNCTIONS
-- ========================================

-- Function to get agent health
CREATE OR REPLACE FUNCTION get_agent_health(agent_uuid UUID)
RETURNS TABLE (
    agent_id UUID,
    agent_name VARCHAR,
    status VARCHAR,
    total_tasks BIGINT,
    success_rate DECIMAL,
    avg_execution_time DECIMAL,
    last_activity TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.name,
        a.status,
        COUNT(at.id) as total_tasks,
        (COUNT(CASE WHEN at.status = 'completed' THEN 1 END) * 100.0 / NULLIF(COUNT(at.id), 0)) as success_rate,
        AVG(at.execution_time) as avg_execution_time,
        MAX(at.updated_at) as last_activity
    FROM agents a
    LEFT JOIN agent_tasks at ON a.id = at.agent_id
    WHERE a.id = agent_uuid
    GROUP BY a.id, a.name, a.status;
END;
$$ LANGUAGE plpgsql;

-- Function to cleanup old logs
CREATE OR REPLACE FUNCTION cleanup_old_logs(days_to_keep INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM agent_logs 
    WHERE created_at < NOW() - INTERVAL '%s days' * days_to_keep;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

