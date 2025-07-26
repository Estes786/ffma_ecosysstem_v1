const { TaskDatabase, MetricsDatabase, LogDatabase, AgentDatabase, formatError } = require('./utils/database');
const { authenticate, enforceTenantIsolation } = require('./utils/auth');

const taskDb = new TaskDatabase();
const metricsDb = new MetricsDatabase();
const logDb = new LogDatabase();
const agentDb = new AgentDatabase();

const setCorsHeaders = (res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
};

export default async function handler(req, res) {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    if (req.method === 'GET') {
      if (req.url.includes('/health')) {
        return await healthCheck(req, res);
      } else if (req.url.includes('/report')) {
        return await getMonitoringReport(req, res);
      } else {
        return await getAgentStatus(req, res);
      }
    }

    if (req.method === 'POST') {
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

      return await performMonitoring(req, res);
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Performance Monitor Error:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      details: formatError(error)
    });
  }
}

async function performMonitoring(req, res) {
  try {
    const { agent_id, monitoring_type = 'comprehensive' } = req.body;

    if (!agent_id) {
      return res.status(400).json({ 
        error: 'agent_id is required' 
      });
    }

    // Create task record
    const task = await taskDb.createTask({
      tenant_id: req.tenantId,
      agent_id,
      status: 'processing',
      input_data: { monitoring_type },
      metadata: { started_at: new Date().toISOString() }
    });

    let result;
    const startTime = Date.now();

    try {
      // Perform comprehensive monitoring
      result = await performComprehensiveMonitoring(req.tenantId, agent_id);

      const processingTime = Date.now() - startTime;

      // Update task with results
      await taskDb.updateTask(task.id, {
        status: 'completed',
        output_data: result,
        completed_at: new Date().toISOString(),
        metadata: {
          ...task.metadata,
          processing_time_ms: processingTime
        }
      });

      // Record metrics
      await metricsDb.recordMetrics({
        tenant_id: req.tenantId,
        agent_id,
        metric_name: 'performance_monitoring',
        metric_value: result.overall_health_score,
        processing_time: processingTime,
        success: true,
        metadata: { monitoring_type }
      });

      // Log successful monitoring
      await logDb.insertLog({
        tenant_id: req.tenantId,
        agent_id,
        level: 'info',
        message: `Performance monitoring completed for task ${task.id}`,
        metadata: { 
          task_id: task.id, 
          processing_time: processingTime,
          health_score: result.overall_health_score
        }
      });

      // Generate alerts if needed
      if (result.alerts && result.alerts.length > 0) {
        await generateAlerts(req.tenantId, agent_id, result.alerts);
      }

      res.json({
        success: true,
        data: {
          task_id: task.id,
          result,
          processing_time_ms: processingTime
        },
        message: 'Performance monitoring completed successfully'
      });

    } catch (processingError) {
      // Update task with error
      await taskDb.updateTask(task.id, {
        status: 'failed',
        error_message: processingError.message,
        completed_at: new Date().toISOString()
      });

      // Record failed metrics
      await metricsDb.recordMetrics({
        tenant_id: req.tenantId,
        agent_id,
        metric_name: 'performance_monitoring_error',
        metric_value: 0,
        processing_time: Date.now() - startTime,
        success: false,
        metadata: { error: processingError.message }
      });

      // Log error
      await logDb.insertLog({
        tenant_id: req.tenantId,
        agent_id,
        level: 'error',
        message: `Performance monitoring failed for task ${task.id}`,
        metadata: { task_id: task.id, error: processingError.message }
      });

      throw processingError;
    }

  } catch (error) {
    console.error('Perform Monitoring Error:', error);
    res.status(500).json({ 
      error: 'Failed to perform monitoring',
      details: formatError(error)
    });
  }
}

async function performComprehensiveMonitoring(tenantId, agentId) {
  const now = new Date();
  const last24Hours = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const last7Days = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  // Get agent information
  const agent = await agentDb.getAgentById(agentId);

  // Get recent tasks
  const recentTasks = await taskDb.getTasks({
    agent_id: agentId,
    tenant_id: tenantId
  });

  // Get recent metrics
  const recentMetrics = await metricsDb.getMetrics({
    agent_id: agentId,
    tenant_id: tenantId,
    from_date: last24Hours.toISOString()
  });

  // Get recent logs
  const recentLogs = await logDb.getLogs({
    agent_id: agentId,
    tenant_id: tenantId
  });

  // Calculate performance metrics
  const performance = {
    // Task performance
    total_tasks: recentTasks.length,
    completed_tasks: recentTasks.filter(t => t.status === 'completed').length,
    failed_tasks: recentTasks.filter(t => t.status === 'failed').length,
    pending_tasks: recentTasks.filter(t => t.status === 'pending').length,
    processing_tasks: recentTasks.filter(t => t.status === 'processing').length,

    // Success rate
    success_rate: recentTasks.length > 0 ? 
      recentTasks.filter(t => t.status === 'completed').length / recentTasks.length : 0,

    // Processing time metrics
    average_processing_time: recentMetrics.reduce((acc, m) => acc + m.processing_time, 0) / recentMetrics.length || 0,

    // Error analysis
    error_rate: recentTasks.length > 0 ? 
      recentTasks.filter(t => t.status === 'failed').length / recentTasks.length : 0,

    // Recent activity
    tasks_last_24h: recentTasks.filter(t => new Date(t.created_at) > last24Hours).length,
    tasks_last_7d: recentTasks.filter(t => new Date(t.created_at) > last7Days).length,

    // Log analysis
    error_logs: recentLogs.filter(l => l.level === 'error').length,
    warning_logs: recentLogs.filter(l => l.level === 'warning').length,
    info_logs: recentLogs.filter(l => l.level === 'info').length
  };

  // Calculate health score (0-100)
  let healthScore = 100;

  // Deduct points for high error rate
  if (performance.error_rate > 0.1) healthScore -= 20;
  if (performance.error_rate > 0.2) healthScore -= 30;

  // Deduct points for slow processing
  if (performance.average_processing_time > 5000) healthScore -= 15;
  if (performance.average_processing_time > 10000) healthScore -= 25;

  // Deduct points for inactivity
  if (performance.tasks_last_24h === 0) healthScore -= 10;

  // Deduct points for error logs
  if (performance.error_logs > 5) healthScore -= 15;

  // Generate alerts
  const alerts = [];

  if (performance.error_rate > 0.2) {
    alerts.push({
      type: 'error_rate',
      severity: 'high',
      message: `High error rate detected: ${(performance.error_rate * 100).toFixed(1)}%`,
      threshold: 20,
      current_value: performance.error_rate * 100
    });
  }

  if (performance.average_processing_time > 10000) {
    alerts.push({
      type: 'processing_time',
      severity: 'medium',
      message: `Slow processing time: ${performance.average_processing_time}ms`,
      threshold: 10000,
      current_value: performance.average_processing_time
    });
  }

  if (performance.tasks_last_24h === 0) {
    alerts.push({
      type: 'inactivity',
      severity: 'low',
      message: 'No tasks processed in the last 24 hours',
      threshold: 1,
      current_value: 0
    });
  }

  return {
    agent_info: {
      id: agent.id,
      name: agent.name,
      type: agent.type,
      status: agent.status,
      version: agent.version
    },
    performance_metrics: performance,
    overall_health_score: Math.max(0, healthScore),
    health_status: healthScore >= 80 ? 'healthy' : healthScore >= 60 ? 'warning' : 'critical',
    alerts,
    recommendations: generateRecommendations(performance, healthScore),
    monitoring_timestamp: now.toISOString()
  };
}

function generateRecommendations(performance, healthScore) {
  const recommendations = [];

  if (performance.error_rate > 0.1) {
    recommendations.push('Review error logs and fix recurring issues');
  }

  if (performance.average_processing_time > 5000) {
    recommendations.push('Optimize processing algorithms or increase resources');
  }

  if (performance.tasks_last_24h === 0) {
    recommendations.push('Check agent configuration and input sources');
  }

  if (healthScore < 60) {
    recommendations.push('Consider agent restart or reconfiguration');
  }

  return recommendations;
}

async function generateAlerts(tenantId, agentId, alerts) {
  for (const alert of alerts) {
    await logDb.insertLog({
      tenant_id: tenantId,
      agent_id: agentId,
      level: alert.severity === 'high' ? 'error' : 'warning',
      message: `ALERT: ${alert.message}`,
      metadata: { alert_type: alert.type, alert_data: alert }
    });
  }
}

async function getMonitoringReport(req, res) {
  try {
    const { tenantId } = req.query;

    if (!tenantId) {
      return res.status(400).json({ error: 'tenantId parameter is required' });
    }

    // Get all agents for tenant
    const agents = await agentDb.getAgents({ tenant_id: tenantId });

    // Get system-wide metrics
    const systemMetrics = await metricsDb.getMetrics({
      tenant_id: tenantId,
      from_date: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
    });

    const report = {
      tenant_id: tenantId,
      agents_count: agents.length,
      active_agents: agents.filter(a => a.status === 'active').length,
      system_health: calculateSystemHealth(systemMetrics),
      top_performing_agents: getTopPerformingAgents(systemMetrics, agents),
      performance_trends: calculatePerformanceTrends(systemMetrics),
      generated_at: new Date().toISOString()
    };

    res.json({
      success: true,
      data: report,
      message: 'Monitoring report generated successfully'
    });
  } catch (error) {
    console.error('Get Monitoring Report Error:', error);
    res.status(500).json({ 
      error: 'Failed to generate monitoring report',
      details: formatError(error)
    });
  }
}

function calculateSystemHealth(metrics) {
  const successfulMetrics = metrics.filter(m => m.success);
  const totalMetrics = metrics.length;

  return {
    overall_success_rate: totalMetrics > 0 ? successfulMetrics.length / totalMetrics : 0,
    average_processing_time: metrics.reduce((acc, m) => acc + m.processing_time, 0) / totalMetrics || 0,
    total_operations: totalMetrics,
    successful_operations: successfulMetrics.length,
    failed_operations: totalMetrics - successfulMetrics.length
  };
}

function getTopPerformingAgents(metrics, agents) {
  const agentStats = {};

  metrics.forEach(metric => {
    if (!agentStats[metric.agent_id]) {
      agentStats[metric.agent_id] = {
        agent_id: metric.agent_id,
        total_operations: 0,
        successful_operations: 0,
        total_processing_time: 0
      };
    }

    agentStats[metric.agent_id].total_operations++;
    if (metric.success) {
      agentStats[metric.agent_id].successful_operations++;
    }
    agentStats[metric.agent_id].total_processing_time += metric.processing_time;
  });

  return Object.values(agentStats)
    .map(stat => ({
      ...stat,
      success_rate: stat.successful_operations / stat.total_operations,
      average_processing_time: stat.total_processing_time / stat.total_operations,
      agent_name: agents.find(a => a.id === stat.agent_id)?.name || 'Unknown'
    }))
    .sort((a, b) => b.success_rate - a.success_rate)
    .slice(0, 5);
}

function calculatePerformanceTrends(metrics) {
  // Simple trend calculation - can be enhanced
  const hourlyMetrics = {};

  metrics.forEach(metric => {
    const hour = new Date(metric.created_at).getHours();
    if (!hourlyMetrics[hour]) {
      hourlyMetrics[hour] = { total: 0, successful: 0 };
    }
    hourlyMetrics[hour].total++;
    if (metric.success) {
      hourlyMetrics[hour].successful++;
    }
  });

  return Object.entries(hourlyMetrics).map(([hour, stats]) => ({
    hour: parseInt(hour),
    success_rate: stats.successful / stats.total,
    total_operations: stats.total
  }));
}

async function healthCheck(req, res) {
  try {
    // Test database connections
    await taskDb.getTasks({ tenant_id: 'health-check' });
    await metricsDb.getMetrics({ tenant_id: 'health-check' });

    res.json({
      success: true,
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        database: 'operational',
        monitoring_system: 'operational'
      }
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message,
      services: {
        database: error.message.includes('database') ? 'error' : 'operational',
        monitoring_system: 'error'
      }
    });
  }
}

async function getAgentStatus(req, res) {
  try {
    const { agentId } = req.query;

    if (!agentId) {
      return res.status(400).json({ error: 'agentId parameter is required' });
    }

    // Get detailed monitoring report for specific agent
    const monitoringResult = await performComprehensiveMonitoring('default', agentId);

    res.json({
      success: true,
      data: monitoringResult,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Get Agent Status Error:', error);
    res.status(500).json({ 
      error: 'Failed to get agent status',
      details: formatError(error)
    });
  }
}
