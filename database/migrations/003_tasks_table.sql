-- Migration 003: Add tasks and deployment tracking

-- Create agent_tasks table
CREATE TABLE IF NOT EXISTS agent_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    task_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    priority INTEGER DEFAULT 1,
    input_data JSONB,
    output_data JSONB,
    error_message TEXT,
    execution_time INTEGER,
    created_by UUID REFERENCES users(id),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add trigger for tasks
CREATE TRIGGER update_agent_tasks_updated_at BEFORE UPDATE ON agent_tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for tasks
CREATE INDEX IF NOT EXISTS idx_agent_tasks_agent_id ON agent_tasks(agent_id);
CREATE INDEX IF NOT EXISTS idx_agent_tasks_tenant_id ON agent_tasks(tenant_id);
CREATE INDEX IF NOT EXISTS idx_agent_tasks_status ON agent_tasks(status);

-- Create agent_deployments table
CREATE TABLE IF NOT EXISTS agent_deployments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_id UUID REFERENCES agents(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    version VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'deployed',
    config JSONB DEFAULT '{}',
    deployed_by UUID REFERENCES users(id),
    deployed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create views
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

-- Create stored functions
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

