const { TaskDatabase, MetricsDatabase, LogDatabase, formatError } = require('./utils/database');
const { SentimentAnalyzer, checkApiKey, formatHuggingFaceError } = require('./utils/huggingface');
const { authenticate, enforceTenantIsolation } = require('./utils/auth');

const taskDb = new TaskDatabase();
const metricsDb = new MetricsDatabase();
const logDb = new LogDatabase();
const sentimentAnalyzer = new SentimentAnalyzer();

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
    // Check HuggingFace API key
    checkApiKey();

    if (req.method === 'GET') {
      if (req.url.includes('/health')) {
        return await healthCheck(req, res);
      } else {
        return await getAgentStatus(req, res);
      }
    }

    if (req.method === 'POST') {
      // Authentication required for POST requests
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

      return await processSentimentTask(req, res);
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Sentiment Agent Error:', error);
    return res.status(500).json({ 
      error: 'Internal server error',
      details: formatError(error)
    });
  }
}

async function processSentimentTask(req, res) {
  try {
    const { agent_id, input_data, batch_mode = false } = req.body;

    if (!agent_id || !input_data) {
      return res.status(400).json({ 
        error: 'agent_id and input_data are required' 
      });
    }

    // Create task record
    const task = await taskDb.createTask({
      tenant_id: req.tenantId,
      agent_id,
      status: 'processing',
      input_data,
      metadata: { batch_mode, started_at: new Date().toISOString() }
    });

    let result;
    const startTime = Date.now();

    try {
      if (batch_mode && Array.isArray(input_data.texts)) {
        result = await sentimentAnalyzer.analyzeBatch(input_data.texts);
      } else if (input_data.text) {
        result = await sentimentAnalyzer.analyzeSentiment(input_data.text);
      } else {
        throw new Error('Invalid input data format');
      }

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
        metric_name: 'sentiment_analysis',
        metric_value: batch_mode ? result.results.length : 1,
        processing_time: processingTime,
        success: true,
        metadata: { batch_mode }
      });

      // Log successful processing
      await logDb.insertLog({
        tenant_id: req.tenantId,
        agent_id,
        level: 'info',
        message: `Sentiment analysis completed for task ${task.id}`,
        metadata: { task_id: task.id, processing_time: processingTime }
      });

      res.json({
        success: true,
        data: {
          task_id: task.id,
          result,
          processing_time_ms: processingTime
        },
        message: 'Sentiment analysis completed successfully'
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
        metric_name: 'sentiment_analysis_error',
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
        message: `Sentiment analysis failed for task ${task.id}`,
        metadata: { task_id: task.id, error: processingError.message }
      });

      throw processingError;
    }

  } catch (error) {
    console.error('Process Sentiment Task Error:', error);
    res.status(500).json({ 
      error: 'Failed to process sentiment analysis',
      details: formatHuggingFaceError(error)
    });
  }
}

async function healthCheck(req, res) {
  try {
    // Test HuggingFace API
    const testResult = await sentimentAnalyzer.analyzeSentiment("This is a test message");

    // Test database connection
    await taskDb.getTasks({ tenant_id: 'health-check' });

    res.json({
      success: true,
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        huggingface_api: 'operational',
        database: 'operational',
        sentiment_model: 'operational'
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
        sentiment_model: 'error'
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
      from_date: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString() // Last 24 hours
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
      success_rate: recentTasks.length > 0 ? recentTasks.filter(t => t.status === 'completed').length / recentTasks.length : 0
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
