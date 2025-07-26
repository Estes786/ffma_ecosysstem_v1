import 'package:equatable/equatable.dart';

class Agent extends Equatable {
  final String id;
  final String tenantId;
  final String name;
  final String type;
  final String status;
  final String? description;
  final Map<String, dynamic> config;
  final String? endpointUrl;
  final String? version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const Agent({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.type,
    required this.status,
    this.description,
    required this.config,
    this.endpointUrl,
    this.version,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      config: json['config'] as Map<String, dynamic>? ?? {},
      endpointUrl: json['endpoint_url'] as String?,
      version: json['version'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'type': type,
      'status': status,
      'description': description,
      'config': config,
      'endpoint_url': endpointUrl,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  Agent copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? type,
    String? status,
    String? description,
    Map<String, dynamic>? config,
    String? endpointUrl,
    String? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return Agent(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      config: config ?? this.config,
      endpointUrl: endpointUrl ?? this.endpointUrl,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tenantId,
    name,
    type,
    status,
    description,
    config,
    endpointUrl,
    version,
    createdAt,
    updatedAt,
    createdBy,
  ];

  // Helper methods
  bool get isActive => status == 'active';
  bool get isInactive => status == 'inactive';
  bool get hasError => status == 'error';

  String get typeDisplayName {
    switch (type) {
      case 'sentiment-analysis':
        return 'Sentiment Analysis';
      case 'recommendation':
        return 'Recommendation';
      case 'performance-monitor':
        return 'Performance Monitor';
      default:
        return type;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'sentiment-analysis':
        return Icons.sentiment_satisfied;
      case 'recommendation':
        return Icons.recommend;
      case 'performance-monitor':
        return Icons.monitor;
      default:
        return Icons.smart_toy;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'error':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// Agent metrics model
class AgentMetrics extends Equatable {
  final String id;
  final String agentId;
  final String metricType;
  final double value;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const AgentMetrics({
    required this.id,
    required this.agentId,
    required this.metricType,
    required this.value,
    this.metadata,
    required this.timestamp,
  });

  factory AgentMetrics.fromJson(Map<String, dynamic> json) {
    return AgentMetrics(
      id: json['id'] as String,
      agentId: json['agent_id'] as String,
      metricType: json['metric_type'] as String,
      value: (json['value'] as num).toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'metric_type': metricType,
      'value': value,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, agentId, metricType, value, metadata, timestamp];
}

