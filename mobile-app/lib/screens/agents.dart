import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/agent.dart';
import '../services/supabase_service.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Agent> _agents = [];
  bool _loading = true;
  String? _error;
  String? _selectedTypeFilter;
  String? _selectedStatusFilter;

  final List<String> _agentTypes = [
    'sentiment-analysis',
    'recommendation',
    'performance-monitor',
  ];

  final List<String> _agentStatuses = [
    'active',
    'inactive',
    'pending',
    'error',
  ];

  @override
  void initState() {
    super.initState();
    _loadAgents();
    _setupRealTimeSubscription();
  }

  Future<void> _loadAgents() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final agents = await _supabaseService.getAgents(
        type: _selectedTypeFilter,
        status: _selectedStatusFilter,
        limit: 100,
      );

      setState(() {
        _agents = agents;
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
    _supabaseService.subscribeToAgents((update) {
      _loadAgents();
    });
  }

  @override
  void dispose() {
    _supabaseService.unsubscribeFromChannel('agents-channel');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAgents,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAgents,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorWidget()
                : _buildAgentsList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAgentDialog,
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
            'Error loading agents',
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
            onPressed: _loadAgents,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsList() {
    if (_agents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No agents found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first agent to get started',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showCreateAgentDialog,
              child: const Text('Create Agent'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _agents.length,
      itemBuilder: (context, index) {
        final agent = _agents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: agent.statusColor.withOpacity(0.1),
              child: Icon(
                agent.typeIcon,
                color: agent.statusColor,
              ),
            ),
            title: Text(
              agent.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agent.typeDisplayName),
                const SizedBox(height: 4),
                Text(
                  'Created ${DateFormat('MMM dd, yyyy').format(agent.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
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
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAgentAction(agent, value),
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
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: agent.isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(agent.isActive ? Icons.pause : Icons.play_arrow),
                          const SizedBox(width: 8),
                          Text(agent.isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () => _showAgentDetails(agent),
          ),
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Agents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String?>(
              value: _selectedTypeFilter,
              decoration: const InputDecoration(
                labelText: 'Agent Type',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Types')),
                ..._agentTypes.map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTypeFilter = value;
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
                ..._agentStatuses.map(
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
                _selectedTypeFilter = null;
                _selectedStatusFilter = null;
              });
              Navigator.pop(context);
              _loadAgents();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAgents();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showCreateAgentDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = _agentTypes.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Agent'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Agent Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Agent Type',
                  border: OutlineInputBorder(),
                ),
                items: _agentTypes.map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ),
                ).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter agent name')),
                );
                return;
              }

              try {
                await _supabaseService.createAgent(
                  name: nameController.text.trim(),
                  type: selectedType,
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Agent created successfully')),
                );
                _loadAgents();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating agent: $e')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _handleAgentAction(Agent agent, String action) async {
    switch (action) {
      case 'view':
        _showAgentDetails(agent);
        break;
      case 'edit':
        _showEditAgentDialog(agent);
        break;
      case 'activate':
        await _updateAgentStatus(agent, 'active');
        break;
      case 'deactivate':
        await _updateAgentStatus(agent, 'inactive');
        break;
      case 'delete':
        _showDeleteAgentDialog(agent);
        break;
    }
  }

  void _showAgentDetails(Agent agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(agent.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', agent.typeDisplayName),
              _buildDetailRow('Status', agent.status),
              _buildDetailRow('Version', agent.version ?? 'N/A'),
              _buildDetailRow('Created', DateFormat('MMM dd, yyyy HH:mm').format(agent.createdAt)),
              _buildDetailRow('Updated', DateFormat('MMM dd, yyyy HH:mm').format(agent.updatedAt)),
              if (agent.description != null)
                _buildDetailRow('Description', agent.description!),
              if (agent.endpointUrl != null)
                _buildDetailRow('Endpoint', agent.endpointUrl!),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditAgentDialog(Agent agent) {
    final nameController = TextEditingController(text: agent.name);
    final descriptionController = TextEditingController(text: agent.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Agent'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Agent Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
              try {
                await _supabaseService.updateAgent(
                  agent.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Agent updated successfully')),
                );
                _loadAgents();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating agent: $e')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAgentStatus(Agent agent, String status) async {
    try {
      await _supabaseService.updateAgent(agent.id, status: status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agent ${status == 'active' ? 'activated' : 'deactivated'}')),
      );
      _loadAgents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating agent: $e')),
      );
    }
  }

  void _showDeleteAgentDialog(Agent agent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Agent'),
        content: Text('Are you sure you want to delete "${agent.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              try {
                await _supabaseService.deleteAgent(agent.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Agent deleted successfully')),
                );
                _loadAgents();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting agent: $e')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

