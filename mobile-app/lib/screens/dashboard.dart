import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/agent.dart';
import '../models/task.dart';
import '../services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Agent> _agents = [];
  List<AgentTask> _recentTasks = [];
  TaskStatistics? _taskStats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _setupRealTimeSubscriptions();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final futures = await Future.wait([
        _supabaseService.getAgents(limit: 10),
        _supabaseService.getTasks(limit: 5),
        _supabaseService.getTaskStatistics(),
      ]);

      setState(() {
        _agents = futures[0] as List<Agent>;
        _recentTasks = futures[1] as List<AgentTask>;
        _taskStats = futures[2] as TaskStatistics;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _setupRealTimeSubscriptions() {
    _supabaseService.subscribeToAgents((update) {
      _loadDashboardData();
    });

    _supabaseService.subscribeToTasks((update) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _supabaseService.unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FMAA Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildDashboardContent(),
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
            'Error loading dashboard',
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
            onPressed: _loadDashboardData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(),
          const SizedBox(height: 24),
          _buildTaskStatusChart(),
          const SizedBox(height: 24),
          _buildAgentsList(),
          const SizedBox(height: 24),
          _buildRecentTasksList(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final stats = _taskStats;
    if (stats == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Agents',
            _agents.length.toString(),
            Icons.smart_toy,
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Tasks',
            stats.totalTasks.toString(),
            Icons.task,
            Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatusChart() {
    final stats = _taskStats;
    if (stats == null || stats.totalTasks == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Task Status Distribution',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text('No tasks available'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Status Distribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: stats.completedTasks.toDouble(),
                      title: 'Completed',
                      color: Colors.green,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: stats.pendingTasks.toDouble(),
                      title: 'Pending',
                      color: Colors.orange,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: stats.processingTasks.toDouble(),
                      title: 'Processing',
                      color: Colors.blue,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: stats.failedTasks.toDouble(),
                      title: 'Failed',
                      color: Colors.red,
                      radius: 50,
                    ),
                  ],
                  centerSpaceRadius: 60,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Completed', Colors.green, stats.completedTasks),
                _buildLegendItem('Pending', Colors.orange, stats.pendingTasks),
                _buildLegendItem('Processing', Colors.blue, stats.processingTasks),
                _buildLegendItem('Failed', Colors.red, stats.failedTasks),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildAgentsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Agents',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to agents tab
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_agents.isEmpty)
              const Center(child: Text('No agents available'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _agents.take(5).length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final agent = _agents[index];
                  return ListTile(
                    leading: Icon(
                      agent.typeIcon,
                      color: agent.statusColor,
                    ),
                    title: Text(agent.name),
                    subtitle: Text(agent.typeDisplayName),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: agent.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: agent.statusColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        agent.status.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: agent.statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTasksList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Tasks',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to tasks tab
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentTasks.isEmpty)
              const Center(child: Text('No recent tasks'))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentTasks.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final task = _recentTasks[index];
                  return ListTile(
                    leading: Icon(
                      task.statusIcon,
                      color: task.statusColor,
                    ),
                    title: Text('Task ${task.id.substring(0, 8)}...'),
                    subtitle: Text(
                      'Created ${DateFormat('MMM dd, HH:mm').format(task.createdAt)}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: task.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

