import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/agent.dart';
import '../models/task.dart';
import '../services/supabase_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();

  List<AgentTask> _tasks = [];
  List<Agent> _agents = [];
  bool _loading = true;
  String? _error;
  String? _selectedAgentFilter;
  String? _selectedStatusFilter;

  late TabController _tabController;

  final List<String> _taskStatuses = [
    'pending',
    'processing',
    'completed',
    'failed',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    _setupRealTimeSubscription();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final futures = await Future.wait([
        _supabaseService.getTasks(
          agentId: _selectedAgentFilter,
          status: _selectedStatusFilter,
          limit: 100,
        ),
        _supabaseService.getAgents(limit: 100),
      ]);

      setState(() {
        _tasks = futures[0] as List<AgentTask>;
        _agents = futures[1] as List<Agent>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _setupRealTimeSubscription() {
    _supabaseService.subscribeToTasks((update) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _supabaseService.unsubscribeFromChannel('tasks-channel');
    super.dispose();
  }

  List<AgentTask> _getTasksByStatus(String status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'Pending (${_getTasksByStatus('pending').length})',
              icon: const Icon(Icons.schedule, size: 16),
            ),
            Tab(
              text: 'Processing (${_getTasksByStatus('processing').length})',
              icon: const Icon(Icons.sync, size: 16),
            ),
            Tab(
              text: 'Completed (${_getTasksByStatus('completed').length})',
              icon: const Icon(Icons.check_circle, size: 16),
            ),
            Tab(
              text: 'Failed (${_getTasksByStatus('failed').length})',
              icon: const Icon(Icons.error, size: 16),
            ),
            Tab(
              text: 'All (${_tasks.length})',
              icon: const Icon(Icons.list, size: 16),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTasksList(_getTasksByStatus('pending')),
                      _buildTasksList(_getTasksByStatus('processing')),
                      _buildTasksList(_getTasksByStatus('completed')),
                      _buildTasksList(_getTasksByStatus('failed')),
                      _buildTasksList(_tasks),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading tasks',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<AgentTask> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new task to get started',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final agent = _agents.firstWhere(
          (a) => a.id == task.agentId,
          orElse: () => Agent(
            id: task.agentId,
            tenantId: task.tenantId,
            name: 'Unknown Agent',
            type: 'unknown',
            status: 'unknown',
            config: {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: task.statusColor.withOpacity(0.1),
              child: Icon(
                task.statusIcon,
                color: task.statusColor,
                size: 20,
              ),
            ),
            title: Text(
              'Task ${task.id.substring(0, 8)}...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Agent: ${agent.name}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: task.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: task.statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        task.statusDisplayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: task.statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: task.priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: task.priorityColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        task.priorityDisplayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: task.priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${DateFormat('MMM dd, HH:mm').format(task.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleTaskAction(task, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                if (task.isPending)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel),
                        SizedBox(width: 8),
                        Text('Cancel'),
                      ],
                    ),
                  ),
                if (task.isFailed)
                  const PopupMenuItem(
                    value: 'retry',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Retry'),
                      ],
                    ),
                  ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskDetail('Task ID', task.id),
                    _buildTaskDetail('Agent', agent.name),
                    _buildTaskDetail('Status', task.statusDisplayName),
                    _buildTaskDetail('Priority', task.priorityDisplayName),
                    _buildTaskDetail(
                      'Created',
                      DateFormat('MMM dd, yyyy HH:mm:ss').format(task.createdAt),
                    ),
                    if (task.startedAt != null)
                      _buildTaskDetail(
                        'Started',
                        DateFormat('MMM dd, yyyy HH:mm:ss').format(task.startedAt!),
                      ),
                    if (task.completedAt != null)
                      _buildTaskDetail(
                        'Completed',
                        DateFormat('MMM dd, yyyy HH:mm:ss').format(task.completedAt!),
                      ),
                    if (task.executionTime != null)
                      _buildTaskDetail(
                        'Execution Time',
                        '${task.executionTime!.inMilliseconds}ms',
                      ),
                    if (task.error != null)
                      _buildTaskDetail('Error', task.error!, isError: true),
                    const SizedBox(height: 16),
                    Text(
                      'Input Data:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatJson(task.inputData),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ),
                    if (task.outputData != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Output Data:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatJson(task.outputData!),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskDetail(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isError
                  ? TextStyle(color: Theme.of(context).colorScheme.error)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Tasks'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String?>(
              value: _selectedAgentFilter,
              decoration: const InputDecoration(
                labelText: 'Agent',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Agents')),
                ..._agents.map(
                  (agent) => DropdownMenuItem(
                    value: agent.id,
                    child: Text(agent.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAgentFilter = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _selectedStatusFilter,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Statuses')),
                ..._taskStatuses.map(
                  (status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatusFilter = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedAgentFilter = null;
                _selectedStatusFilter = null;
              });
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadData();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog() {
    if (_agents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No agents available. Create an agent first.')),
      );
      return;
    }

    String selectedAgentId = _agents.first.id;
    String selectedPriority = 'medium';
    final inputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedAgentId,
                decoration: const InputDecoration(
                  labelText: 'Agent',
                  border: OutlineInputBorder(),
                ),
                items: _agents.map(
                  (agent) => DropdownMenuItem(
                    value: agent.id,
                    child: Text('${agent.name} (${agent.typeDisplayName})'),
                  ),
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedAgentId = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: ['low', 'medium', 'high', 'critical'].map(
                  (priority) => DropdownMenuItem(
                    value: priority,
                    child: Text(priority.toUpperCase()),
                  ),
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedPriority = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: inputController,
                decoration: const InputDecoration(
                  labelText: 'Input Data (JSON format)',
                  border: OutlineInputBorder(),
                  hintText: '{"text": "Hello World"}',
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (inputController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter input data')),
                );
                return;
              }

              try {
                // Parse JSON input
                final inputData = jsonDecode(inputController.text.trim()) as Map<String, dynamic>;

                await _supabaseService.createTask(
                  agentId: selectedAgentId,
                  inputData: inputData,
                  priority: selectedPriority,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task created successfully')),
                );
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating task: $e')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _handleTaskAction(AgentTask task, String action) async {
    switch (action) {
      case 'view':
        _showTaskDetails(task);
        break;
      case 'cancel':
        await _updateTaskStatus(task, 'cancelled');
        break;
      case 'retry':
        // Create a new task with the same input data
        try {
          await _supabaseService.createTask(
            agentId: task.agentId,
            inputData: task.inputData,
            priority: task.priority,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task retried successfully')),
          );
          _loadData();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error retrying task: $e')),
          );
        }
        break;
    }
  }

  void _showTaskDetails(AgentTask task) {
    final agent = _agents.firstWhere(
      (a) => a.id == task.agentId,
      orElse: () => Agent(
        id: task.agentId,
        tenantId: task.tenantId,
        name: 'Unknown Agent',
        type: 'unknown',
        status: 'unknown',
        config: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Task ${task.id.substring(0, 8)}...'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTaskDetail('Agent', agent.name),
              _buildTaskDetail('Status', task.statusDisplayName),
              _buildTaskDetail('Priority', task.priorityDisplayName),
              _buildTaskDetail(
                'Created',
                DateFormat('MMM dd, yyyy HH:mm:ss').format(task.createdAt),
              ),
              if (task.startedAt != null)
                _buildTaskDetail(
                  'Started',
                  DateFormat('MMM dd, yyyy HH:mm:ss').format(task.startedAt!),
                ),
              if (task.completedAt != null)
                _buildTaskDetail(
                  'Completed',
                  DateFormat('MMM dd, yyyy HH:mm:ss').format(task.completedAt!),
                ),
              if (task.executionTime != null)
                _buildTaskDetail(
                  'Execution Time',
                  '${task.executionTime!.inMilliseconds}ms',
                ),
              if (task.error != null)
                _buildTaskDetail('Error', task.error!, isError: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTaskStatus(AgentTask task, String status) async {
    try {
      await _supabaseService.updateTaskStatus(task.id, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task $status')),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating task: $e')),
      );
    }
  }
}

