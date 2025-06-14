// lib/screens/realtime_tasks_screen.dart
// This screen displays assigned tasks for workers and provides a task assignment interface for managers.

import 'package:flutter/material.dart'; // Required for Flutter UI components
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Utility for showing Snackbars
import 'package:line_survey_pro/models/task.dart'; // Import the Task model
import 'package:line_survey_pro/models/user_profile.dart'; // Import the UserProfile model

import 'package:line_survey_pro/services/auth_service.dart'; // Service for authentication and user profiles
import 'package:line_survey_pro/services/task_service.dart'; // Service for task management

class RealTimeTasksScreen extends StatefulWidget {
  // Changed to StatefulWidget
  const RealTimeTasksScreen({super.key});

  @override
  State<RealTimeTasksScreen> createState() => _RealTimeTasksScreenState();
}

class _RealTimeTasksScreenState extends State<RealTimeTasksScreen> {
  UserProfile? _currentUser;
  List<Task> _assignedTasks = [];
  bool _isLoading = true;

  // Create instances of your services
  final AuthService _authService =
      AuthService(); // Correctly instantiate AuthService
  final TaskService _taskService =
      TaskService(); // Correctly instantiate TaskService

  @override
  void initState() {
    super.initState();
    _loadUserDataAndTasks(); // Load data when the screen initializes
  }

  Future<void> _loadUserDataAndTasks() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });
    try {
      _currentUser =
          await _authService.getCurrentUserProfile(); // Fetch user profile
      if (_currentUser != null) {
        if (_currentUser!.role == 'Worker') {
          _assignedTasks = await _taskService
              .getTasksForUser(_currentUser!.id); // Fetch tasks for worker
        } else if (_currentUser!.role == 'Manager') {
          _assignedTasks =
              await _taskService.getAllTasks(); // Fetch all tasks for manager
        } else {
          // Handle cases where role is null or unrecognized (e.g., show a message)
          _assignedTasks = [];
          if (mounted) {
            SnackBarUtils.showSnackBar(
                context, 'User role not recognized or assigned.',
                isError: true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error loading data: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  void _assignNewTask() {
    // This will eventually navigate to a screen where managers can assign tasks
    if (mounted) {
      SnackBarUtils.showSnackBar(
          context, 'Navigating to Task Assignment (not yet implemented)...');
      // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => AssignTaskScreen()));
    }
  }

  void _updateTaskStatus(Task task, String newStatus) async {
    setState(() {
      _isLoading = true; // Show loading while updating
    });
    try {
      await _taskService.updateTaskStatus(
          task.id, newStatus); // Update task status in Firestore
      await _loadUserDataAndTasks(); // Refresh the list of tasks
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Task status updated!');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
            context, 'Error updating task: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator()); // Show loading indicator
    }

    if (_currentUser == null) {
      return Center(
        child: Text(
          'Please log in to view tasks.', // Message if no user is logged in
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Welcome, ${_currentUser!.displayName ?? _currentUser!.email} (${_currentUser!.role ?? 'Unassigned'})!', // Display user info and role
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: colorScheme.primary),
            textAlign: TextAlign.center,
          ),
        ),
        if (_currentUser!.role ==
            'Manager') // Show 'Assign New Task' button only for Managers
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _assignNewTask,
              icon: const Icon(Icons.add_task),
              label: const Text('Assign New Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          _currentUser!.role == 'Worker'
              ? 'Your Assigned Tasks:'
              : 'All Tasks:', // Dynamic section title
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _assignedTasks.isEmpty
              ? Center(
                  child: Text(
                    _currentUser!.role == 'Worker'
                        ? 'No tasks assigned to you yet.' // Message for Worker
                        : 'No tasks available.', // Message for Manager
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  itemCount: _assignedTasks.length,
                  itemBuilder: (context, index) {
                    final task = _assignedTasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 3,
                      child: ListTile(
                        title: Text(
                            'Line: ${task.lineName} - Towers: ${task.targetTowerRange}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Due: ${task.dueDate.toLocal().toString().split(' ')[0]}'),
                            Text('Status: ${task.status}'),
                            if (_currentUser!.role == 'Manager')
                              Text(
                                  'Assigned to: ${task.assignedToUserName ?? 'N/A'}'), // Display worker for managers
                          ],
                        ),
                        trailing: _currentUser!.role == 'Worker' &&
                                task.status !=
                                    'Completed' // Show check button if worker and not completed
                            ? IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green),
                                onPressed: () => _updateTaskStatus(
                                    task, 'Completed'), // Mark task completed
                                tooltip: 'Mark as Completed',
                              )
                            : null,
                        onTap: () {
                          // Handle tapping on a task for more details or to start surveying
                          SnackBarUtils.showSnackBar(
                              context, 'Task Tapped: ${task.lineName}');
                          // Example: Navigate to a Task-specific survey screen:
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => TaskLineDetailScreen(task: task)));
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
