const { TaskDatabase, MetricsDatabase, LogDatabase, formatError } = require('./utils/database');
const { RecommendationEngine, checkApiKey, formatHuggingFaceError } = require('./utils/huggingface');
const { authenticate, enforceTenantIsolation } = require('./utils/auth');

const taskDb = new TaskDatabase();
const metricsDb = new MetricsDatabase();
const logDb = new LogDatabase();
const recommendationEngine = new RecommendationEngine();

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
    checkApiKey();

    if (req.method === 'GET') {
      if (req.url.includes('/health')) {
        return await healthCheck(req, res);
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

      return await processRecommendationTask(req, res);
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Recommendation Agent Error:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      details: formatError(error)
    });
  }
}

async function processRecommendationTask(req, res) {
  try {
    const { agent_id, input_data } = req.body;

    if (!agent_id || !input_data) {
      return res.status(400).json({ 
        error: 'agent_id and input_data are required' 
      });
    }

    if (!input_data.query || !input_data.items) {
      return res.status(400).json({ 
        error: 'query and items are required in input_data' 
      });
    }

    // Create task record
    const task = await taskDb.createTask({
      tenant_id: req.tenantId,
      agent_id,
      status: 'processing',
      input_data,
      metadata: { started_at: new Date().toISOString() }
    });

    let result;
    const startTime = Date.now();

    try {
      const { query, items, threshold = 0.7 } = input_data;

      // Find similar items
      const similarItems = await recommendationEngine.findSimilarItems(query, items, threshold);

      // Enhance recommendations
      const enhancedRecommendations = await recommendationEngine.enhanceRecommendations(similarItems.recommendations);

      result = {
        ...similarItems,
        enhanced: enhancedRecommendations
      };

      const processingTime = Date.now() - startTime;

      // Update task with results
      await taskDb.updateTask(task.id, {
        status: 'completed',
        output_data: result,
        completed_at: new Date().toISOString(),
        metadata: {
          ...task.metadata,
          processing_time_ms: processingTime,
          recommendations_count: result.recommendations.length
        }
      });

      // Record metrics
      await metricsDb.recordMetrics({
        tenant_id: req.tenantId,
        agent_id,
        metric_name: 'recommendation_generation',
        metric_value: result.recommendations.length,
        processing_time: processingTime,
        success: true,
        metadata: { 
          query_length: query.length,
          items_count: items.length,
          threshold
        }
      });

      // Log successful processing
      await logDb.insertLog({
        tenant_id: req.tenantId,
        agent_id,
        level: 'info',
        message: `Recommendation generation completed for task ${task.id}`,
        metadata: { 
          task_id: task.id, 
          processing_time: processingTime,
          recommendations_count: result.recommendations.length
        }
      });

      res.json({
        success: true,
        data: {
          task_id: task.id,
          result,
          processing_time_ms: processingTime
        },
        message: 'Recommendation generation completed successfully'
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
        metric_name: 'recommendation_generation_error',
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
        message: `Recommendation generation failed for task ${task.id}`,
        metadata: { task_id: task.id, error: processingError.message }
      });

      throw processingError;
    }

  } catch (error) {
    console.error('Process Recommendation Task Error:', error);
    res.status(500).json({ 
      error: 'Failed to process recommendation generation',
      details: formatHuggingFaceError(error)
    });
  }
}

async function healthCheck(req, res) {
  try {
    // Test recommendation engine
    const testResult = await recommendationEngine.findSimilarItems(
      "test query", 
      [{ text: "test item 1" }, { text: "test item 2" }], 
      0.5
    );

    // Test database connection
    await taskDb.getTasks({ tenant_id: 'health-check' });

    res.json({
      success: true,
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        huggingface_api: 'operational',
        database: 'operational',
        recommendation_engine: 'operational'
      },
      test_result: testResult
    });
  } catch (error) {
    res.status(503).json({
      success: false,
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message,
      services: {
        huggingface_api: error.message.includes('HuggingFace') ? 'error' : 'operational',
        database: error.message.includes('database') ? 'error' : 'operational',
        recommendation_engine: 'error'
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

    // Get recent metrics
    const recentMetrics = await metricsDb.getMetrics({
      agent_id: agentId,
      from_date: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
    });

    // Get recent tasks
    const recentTasks = await taskDb.getTasks({
      agent_id: agentId
    });

    const stats = {
      total_tasks: recentTasks.length,
      completed_tasks: recentTasks.filter(t => t.status === 'completed').length,
      failed_tasks: recentTasks.filter(t => t.status === 'failed').length,
      average_processing_time: recentMetrics.reduce((acc, m) => acc + m.processing_time, 0) / recentMetrics.length || 0,
      success_rate: recentTasks.length > 0 ? recentTasks.filter(t => t.status === 'completed').length / recentTasks.length : 0,
      total_recommendations: recentMetrics.reduce((acc, m) => acc + m.metric_value, 0)
    };

    res.json({
      success: true,
      data: {
        agent_id: agentId,
        status: 'operational',
        statistics: stats,
        recent_metrics: recentMetrics.slice(0, 10),
        recent_tasks: recentTasks.slice(0, 5)
      },
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
