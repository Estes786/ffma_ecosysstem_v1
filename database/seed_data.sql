-- FMAA Seed Data
-- Sample data untuk testing dan development

-- Seed tenants
INSERT INTO tenants (id, name, domain, status, settings) VALUES
('550e8400-e29b-41d4-a716-446655440001', 'Demo Company', 'demo.example.com', 'active', '{"theme": "dark", "timezone": "UTC"}'),
('550e8400-e29b-41d4-a716-446655440002', 'Test Organization', 'test.example.com', 'active', '{"theme": "light", "timezone": "America/New_York"}')
ON CONFLICT (id) DO NOTHING;

-- Seed users
INSERT INTO users (id, tenant_id, email, name, role, status, metadata) VALUES
('660e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'admin@demo.com', 'Demo Admin', 'admin', 'active', '{"department": "IT"}'),
('660e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'user@demo.com', 'Demo User', 'user', 'active', '{"department": "Marketing"}'),
('660e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440002', 'admin@test.com', 'Test Admin', 'admin', 'active', '{"department": "Development"}')
ON CONFLICT (email) DO NOTHING;

-- Seed agents
INSERT INTO agents (id, tenant_id, name, type, status, version, config, endpoint_url, description, created_by) VALUES
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'Sentiment Analyzer Pro', 'sentiment', 'active', '1.0.0', 
 '{"model": "cardiffnlp/twitter-roberta-base-sentiment", "batch_size": 32, "confidence_threshold": 0.8}', 
 'https://your-app.vercel.app/api/sentiment-agent', 'Advanced sentiment analysis using RoBERTa model', '660e8400-e29b-41d4-a716-446655440001'),

('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'Smart Recommender', 'recommendation', 'active', '1.0.0',
 '{"model": "sentence-transformers/all-MiniLM-L6-v2", "similarity_threshold": 0.7, "max_recommendations": 10}',
 'https://your-app.vercel.app/api/recommendation-agent', 'AI-powered recommendation system using embeddings', '660e8400-e29b-41d4-a716-446655440001'),

('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'Performance Monitor', 'performance', 'active', '1.0.0',
 '{"check_interval": 300, "alert_threshold": 0.9, "metrics_retention_days": 30}',
 'https://your-app.vercel.app/api/performance-monitor', 'Real-time system performance monitoring', '660e8400-e29b-41d4-a716-446655440001'),

('770e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440002', 'Test Sentiment Agent', 'sentiment', 'inactive', '0.9.0',
 '{"model": "cardiffnlp/twitter-roberta-base-sentiment", "batch_size": 16}',
 'https://your-app.vercel.app/api/sentiment-agent', 'Test sentiment analysis agent', '660e8400-e29b-41d4-a716-446655440003')
ON CONFLICT (id) DO NOTHING;

-- Seed agent tasks
INSERT INTO agent_tasks (id, agent_id, tenant_id, task_type, status, priority, input_data, output_data, execution_time, created_by) VALUES
('880e8400-e29b-41d4-a716-446655440001', '770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 
 'sentiment_analysis', 'completed', 1, 
 '{"text": "I love this new feature! It works perfectly."}', 
 '{"sentiment": "POSITIVE", "confidence": 0.95, "score": 0.8542}', 
 1250, '660e8400-e29b-41d4-a716-446655440001'),

('880e8400-e29b-41d4-a716-446655440002', '770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001',
 'recommendation', 'completed', 1,
 '{"user_preferences": ["technology", "AI", "software"], "context": "product_recommendation"}',
 '{"recommendations": [{"item": "AI Development Course", "confidence": 0.92}, {"item": "Machine Learning Toolkit", "confidence": 0.87}]}',
 2100, '660e8400-e29b-41d4-a716-446655440002'),

('880e8400-e29b-41d4-a716-446655440003', '770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001',
 'performance_check', 'completed', 2,
 '{"targets": ["api/agent-factory", "api/sentiment-agent"], "metrics": ["response_time", "cpu_usage"]}',
 '{"results": [{"endpoint": "api/agent-factory", "response_time": 89, "cpu_usage": 12.5}, {"endpoint": "api/sentiment-agent", "response_time": 156, "cpu_usage": 23.1}]}',
 3200, '660e8400-e29b-41d4-a716-446655440001'),

('880e8400-e29b-41d4-a716-446655440004', '770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001',
 'sentiment_analysis', 'pending', 1,
 '{"text": "This product is okay, nothing special but does the job."}',
 NULL, NULL, '660e8400-e29b-41d4-a716-446655440002')
ON CONFLICT (id) DO NOTHING;

-- Seed agent metrics
INSERT INTO agent_metrics (agent_id, tenant_id, metric_type, value, unit, metadata) VALUES
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'success_rate', 95.5, 'percent', '{"period": "24h"}'),
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'avg_response_time', 1250, 'milliseconds', '{"period": "24h"}'),
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'total_requests', 1247, 'count', '{"period": "24h"}'),

('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'success_rate', 92.3, 'percent', '{"period": "24h"}'),
('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'avg_response_time', 2100, 'milliseconds', '{"period": "24h"}'),
('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'total_requests', 892, 'count', '{"period": "24h"}'),

('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'success_rate', 98.7, 'percent', '{"period": "24h"}'),
('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'avg_response_time', 3200, 'milliseconds', '{"period": "24h"}'),
('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'total_requests', 156, 'count', '{"period": "24h"}');

-- Seed agent logs
INSERT INTO agent_logs (agent_id, tenant_id, level, message, context) VALUES
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'info', 'Agent started successfully', '{"startup_time": 1234}'),
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 'info', 'Processing sentiment analysis request', '{"task_id": "880e8400-e29b-41d4-a716-446655440001"}'),
('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 'warn', 'High response time detected', '{"response_time": 2500, "threshold": 2000}'),
('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', 'info', 'Performance monitoring cycle completed', '{"checked_endpoints": 15, "alerts": 0}');

-- Seed agent deployments
INSERT INTO agent_deployments (agent_id, tenant_id, version, status, config, deployed_by) VALUES
('770e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', '1.0.0', 'deployed', '{"environment": "production"}', '660e8400-e29b-41d4-a716-446655440001'),
('770e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', '1.0.0', 'deployed', '{"environment": "production"}', '660e8400-e29b-41d4-a716-446655440001'),
('770e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440001', '1.0.0', 'deployed', '{"environment": "production"}', '660e8400-e29b-41d4-a716-446655440001'),
('770e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440002', '0.9.0', 'deployed', '{"environment": "testing"}', '660e8400-e29b-41d4-a716-446655440003');

