import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/agent.dart';
import '../models/task.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Real-time subscriptions
  static final Map<String, RealtimeChannel> _subscriptions = {};

  // Agent operations
  Future<List<Agent>> getAgents({
    String? type,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('agents').select('*');

      if (type != null) {
        query = query.eq('type', type);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Agent.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch agents: $e');
    }
  }

  Future<Agent> createAgent({
    required String name,
    required String type,
    String? description,
    Map<String, dynamic>? config,
  }) async {
    try {
      final response = await _client.from('agents').insert({
        'name': name,
        'type': type,
        'description': description,
        'config': config ?? {},
        'status': 'inactive',
        'tenant_id': 'default', // Update based on auth
      }).select().single();

      return Agent.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create agent: $e');
    }
  }

  Future<Agent> updateAgent(
    String agentId, {
    String? name,
    String? status,
    String? description,
    Map<String, dynamic>? config,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (status != null) updates['status'] = status;
      if (description != null) updates['description'] = description;
      if (config != null) updates['config'] = config;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('agents')
          .update(updates)
          .eq('id', agentId)
          .select()
          .single();

      return Agent.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update agent: $e');
    }
  }

  Future<void> deleteAgent(String agentId) async {
    try {
      await _client.from('agents').delete().eq('id', agentId);
    } catch (e) {
      throw Exception('Failed to delete agent: $e');
    }
  }

  // Task operations
  Future<List<AgentTask>> getTasks({
    String? agentId,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('agent_tasks').select('*');

      if (agentId != null) {
        query = query.eq('agent_id', agentId);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => AgentTask.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  Future<AgentTask> createTask({
    required String agentId,
    required Map<String, dynamic> inputData,
    String priority = 'medium',
  }) async {
    try {
      final response = await _client.from('agent_tasks').insert({
        'agent_id': agentId,
        'input_data': inputData,
        'priority': priority,
        'status': 'pending',
        'tenant_id': 'default', // Update based on auth
      }).select().single();

      return AgentTask.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  Future<AgentTask> updateTaskStatus(
    String taskId,
    String status, {
    Map<String, dynamic>? outputData,
    String? error,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (outputData != null) updates['output_data'] = outputData;
      if (error != null) updates['error'] = error;

      if (status == 'processing' && !updates.containsKey('started_at')) {
        updates['started_at'] = DateTime.now().toIso8601String();
      }

      if (status == 'completed' || status == 'failed') {
        updates['completed_at'] = DateTime.now().toIso8601String();
      }

      final response = await _client
          .from('agent_tasks')
          .update(updates)
          .eq('id', taskId)
          .select()
          .single();

      return AgentTask.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // Metrics operations
  Future<List<AgentMetrics>> getAgentMetrics({
    required String agentId,
    String? metricType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _client
          .from('agent_metrics')
          .select('*')
          .eq('agent_id', agentId);

      if (metricType != null) {
        query = query.eq('metric_type', metricType);
      }

      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }

      final response = await query
          .limit(limit)
          .order('timestamp', ascending: false);

      return (response as List)
          .map((json) => AgentMetrics.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch metrics: $e');
    }
  }

  Future<void> recordMetric({
    required String agentId,
    required String metricType,
    required double value,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('agent_metrics').insert({
        'agent_id': agentId,
        'metric_type': metricType,
        'value': value,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to record metric: $e');
    }
  }

  // Statistics
  Future<Map<String, dynamic>> getAgentStatistics() async {
    try {
      final response = await _client.rpc('get_agent_statistics');
      return response as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get agent statistics: $e');
    }
  }

  Future<TaskStatistics> getTaskStatistics({String? agentId}) async {
    try {
      var query = _client.from('agent_tasks').select('status');

      if (agentId != null) {
        query = query.eq('agent_id', agentId);
      }

      final tasks = await query;

      final totalTasks = tasks.length;
      final pendingTasks = tasks.where((t) => t['status'] == 'pending').length;
      final processingTasks = tasks.where((t) => t['status'] == 'processing').length;
      final completedTasks = tasks.where((t) => t['status'] == 'completed').length;
      final failedTasks = tasks.where((t) => t['status'] == 'failed').length;

      final successRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

      return TaskStatistics(
        totalTasks: totalTasks,
        pendingTasks: pendingTasks,
        processingTasks: processingTasks,
        completedTasks: completedTasks,
        failedTasks: failedTasks,
        averageExecutionTime: 0.0, // Calculate from actual data
        successRate: successRate,
      );
    } catch (e) {
      throw Exception('Failed to get task statistics: $e');
    }
  }

  // Real-time subscriptions
  void subscribeToAgents(Function(Map<String, dynamic>) onUpdate) {
    const channelName = 'agents-channel';

    if (_subscriptions.containsKey(channelName)) {
      _subscriptions[channelName]?.unsubscribe();
    }

    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'agents',
          callback: (payload) => onUpdate(payload.toJson()),
        )
        .subscribe();

    _subscriptions[channelName] = channel;
  }

  void subscribeToTasks(Function(Map<String, dynamic>) onUpdate) {
    const channelName = 'tasks-channel';

    if (_subscriptions.containsKey(channelName)) {
      _subscriptions[channelName]?.unsubscribe();
    }

    final channel = _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'agent_tasks',
          callback: (payload) => onUpdate(payload.toJson()),
        )
        .subscribe();

    _subscriptions[channelName] = channel;
  }

  void unsubscribeAll() {
    for (final channel in _subscriptions.values) {
      channel.unsubscribe();
    }
    _subscriptions.clear();
  }

  void unsubscribeFromChannel(String channelName) {
    if (_subscriptions.containsKey(channelName)) {
      _subscriptions[channelName]?.unsubscribe();
      _subscriptions.remove(channelName);
    }
  }

  // Authentication (if needed)
  Future<bool> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      unsubscribeAll();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;
}

