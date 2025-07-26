import 'package:equatable/equatable.dart';

class AgentTask extends Equatable {
  final String id;
  final String agentId;
  final String tenantId;
  final String status;
  final String priority;
  final Map<String, dynamic> inputData;
  final Map<String, dynamic>? outputData;
  final String? error;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const AgentTask({
    required this.id,
    required this.agentId,
    required this.tenantId,
    required this.status,
    required this.priority,
    required this.inputData,
    this.outputData,
    this.error,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory AgentTask.fromJson(Map<String, dynamic> json) {
    return AgentTask(
      id: json['id'] as String,
      agentId: json['agent_id'] as String,
      tenantId: json['tenant_id'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      inputData: json['input_data'] as Map<String, dynamic>,
      outputData: json['output_data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'tenant_id': tenantId,
      'status': status,
      'priority': priority,
      'input_data': inputData,
      'output_data': outputData,
      'error': error,
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  AgentTask copyWith({
    String? id,
    String? agentId,
    String? tenantId,
    String? status,
    String? priority,
    Map<String, dynamic>? inputData,
    Map<String, dynamic>? outputData,
    String? error,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return AgentTask(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      tenantId: tenantId ?? this.tenantId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      inputData: inputData ?? this.inputData,
      outputData: outputData ?? this.outputData,
      error: error ?? this.error,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
    id,
    agentId,
    tenantId,
    status,
    priority,
    inputData,
    outputData,
    error,
    startedAt,
    completedAt,
    createdAt,
    updatedAt,
    createdBy,
  ];

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';

  Duration? get executionTime {
    if (startedAt != null && completedAt != null) {
      return completedAt!.difference(startedAt!);
    }
    return null;
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Critical';
      default:
        return priority;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

// Task statistics model
class TaskStatistics extends Equatable {
  final int totalTasks;
  final int pendingTasks;
  final int processingTasks;
  final int completedTasks;
  final int failedTasks;
  final double averageExecutionTime;
  final double successRate;

  const TaskStatistics({
    required this.totalTasks,
    required this.pendingTasks,
    required this.processingTasks,
    required this.completedTasks,
    required this.failedTasks,
    required this.averageExecutionTime,
    required this.successRate,
  });

  factory TaskStatistics.fromJson(Map<String, dynamic> json) {
    return TaskStatistics(
      totalTasks: json['total_tasks'] as int,
      pendingTasks: json['pending_tasks'] as int,
      processingTasks: json['processing_tasks'] as int,
      completedTasks: json['completed_tasks'] as int,
      failedTasks: json['failed_tasks'] as int,
      averageExecutionTime: (json['average_execution_time'] as num).toDouble(),
      successRate: (json['success_rate'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    totalTasks,
    pendingTasks,
    processingTasks,
    completedTasks,
    failedTasks,
    averageExecutionTime,
    successRate,
  ];
}

