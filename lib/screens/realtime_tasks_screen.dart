// lib/screens/realtime_tasks_screen.dart
// This screen displays assigned tasks for workers and provides a task assignment interface for managers.

import 'package:flutter/material.dart'; // Required for Flutter UI components
import 'package:line_survey_pro/utils/snackbar_utils.dart'; // Utility for showing Snackbars
import 'package:line_survey_pro/models/task.dart'; // Import the Task model
import 'package:line_survey_pro/models/user_profile.dart'; // Import the UserProfile model

import 'package:line_survey_pro/services/auth_service.dart'; // Service for authentication and user profiles
import 'package:line_survey_pro/services/task_service.dart'; // Service for task management
import 'package:line_survey_pro/screens/assign_task_screen.dart'; // NEW: Import AssignTaskScreen

class RealTimeTasksScreen extends StatefulWidget {
  const RealTimeTasksScreen({super.key});

  @override
  State<RealTimeTasksScreen> createState() => _RealTimeTasksScreenState();
}

class _RealTimeTasksScreenState extends State<RealTimeTasksScreen> {
  UserProfile? _currentUser;
  List<Task> _assignedTasks = [];
  bool _isLoading = true;

  // Create instances of your services
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _loadUserDataAndTasks(); // Load data when the screen initializes
  }

  // Refresh tasks when the screen is re-focused (e.g., after returning from AssignTaskScreen)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is a common pattern to refresh data when a screen comes into view again.
    // However, be mindful of over-fetching. You might want to debounce or use a change notifier.
    // For now, _loadUserDataAndTasks is safe because _isLoading prevents redundant fetches.
    // But if you're using Streams for real-time updates, didChangeDependencies might not be needed.
    // For this case, it's fine for ensuring tasks update after creation.
    // We already call it in initState, so if this is part of a TabBarView, it might not re-run.
    // Let's add a listener for future screen focus.
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

  void _assignNewTask() async {
    // Made async to await navigation
    if (mounted) {
      // Navigate to the AssignTaskScreen
      final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AssignTaskScreen()),
      );
      // After returning from AssignTaskScreen, refresh tasks
      if (result == true) {
        // Assuming AssignTaskScreen returns true on successful assignment
        _loadUserDataAndTasks();
      }
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

    // Display appropriate content based on user role
    if (_currentUser!.role == null ||
        (_currentUser!.role != 'Worker' && _currentUser!.role != 'Manager')) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: colorScheme.error),
              const SizedBox(height: 20),
              Text(
                'Your account role is not assigned or recognized.',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Please ensure your role is correctly assigned by an administrator in the Firebase Console.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Welcome, ${_currentUser!.displayName ?? _currentUser!.email} (${_currentUser!.role})!', // Display user info and role
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
