import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agent.dart';
import '../models/task.dart';

class ApiService {
  static const String baseUrl = 'https://your-vercel-app.vercel.app'; // Update this

  // Headers untuk API calls
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer YOUR_API_KEY', // Update this
  };

  // Agent Factory endpoints
  Future<List<Agent>> getAgents({
    String? type,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (type != null) queryParams['type'] = type;
    if (status != null) queryParams['status'] = status;

    final uri = Uri.parse('$baseUrl/api/agent-factory')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> agentsJson = data['data']['agents'];
      return agentsJson.map((json) => Agent.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load agents: ${response.body}');
    }
  }

  Future<Agent> createAgent({
    required String name,
    required String type,
    String? description,
    Map<String, dynamic>? config,
  }) async {
    final body = {
      'name': name,
      'type': type,
      'description': description,
      'config': config ?? {},
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/agent-factory'),
      headers: _headers,
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Agent.fromJson(data['data']);
    } else {
      throw Exception('Failed to create agent: ${response.body}');
    }
  }

  Future<Agent> updateAgent(String agentId, {
    String? name,
    String? status,
    String? description,
    Map<String, dynamic>? config,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (status != null) body['status'] = status;
    if (description != null) body['description'] = description;
    if (config != null) body['config'] = config;

    final response = await http.put(
      Uri.parse('$baseUrl/api/agent-factory/$agentId'),
      headers: _headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Agent.fromJson(data['data']);
    } else {
      throw Exception('Failed to update agent: ${response.body}');
    }
  }

  Future<void> deleteAgent(String agentId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/agent-factory/$agentId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete agent: ${response.body}');
    }
  }

  // Sentiment Agent
  Future<Map<String, dynamic>> processSentiment({
    required String agentId,
    required List<String> texts,
    bool batch = false,
  }) async {
    final body = {
      'agent_id': agentId,
      'input_data': {
        'texts': texts,
        'batch': batch,
      },
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/sentiment-agent'),
      headers: _headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to process sentiment: ${response.body}');
    }
  }

  // Recommendation Agent
  Future<Map<String, dynamic>> getRecommendations({
    required String agentId,
    required String targetItem,
    required List<String> candidates,
    double threshold = 0.7,
  }) async {
    final body = {
      'agent_id': agentId,
      'input_data': {
        'target_item': targetItem,
        'candidates': candidates,
        'threshold': threshold,
      },
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/recommendation-agent'),
      headers: _headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get recommendations: ${response.body}');
    }
  }

  // Performance Monitor
  Future<Map<String, dynamic>> getPerformanceReport({
    String? agentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (agentId != null) queryParams['agent_id'] = agentId;
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

    final uri = Uri.parse('$baseUrl/api/performance-monitor/report')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get performance report: ${response.body}');
    }
  }

  // Health checks
  Future<bool> checkAgentHealth(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint/health'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Generic API call method
  Future<Map<String, dynamic>> apiCall({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    Uri uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: _headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: _headers,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: _headers,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: _headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('API call failed: ${response.body}');
    }
  }
}

