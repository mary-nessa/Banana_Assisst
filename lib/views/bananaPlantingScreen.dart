import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:bananaassist/utils/secure_storage.dart';

// KeepAlive wrapper to maintain tab state
class KeepAliveTab extends StatelessWidget {
  final Widget child;
  const KeepAliveTab({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class BananaPlantingScreen extends StatefulWidget {
  final String? authToken;
  const BananaPlantingScreen({Key? key, this.authToken}) : super(key: key);

  @override
  State<BananaPlantingScreen> createState() => _BananaPlantingScreenState();
}

class _BananaPlantingScreenState extends State<BananaPlantingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? userRole;
  final GlobalKey<PlantingDetailsTabState> _plantingDetailsKey = GlobalKey<PlantingDetailsTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAuth();
    print('BananaPlantingScreen initialized');
  }

  Future<void> _checkAuth() async {
    final authToken = widget.authToken ?? await SecureStorage().read('authToken');
    final storedUserRole = await SecureStorage().read('userRole');

    setState(() {
      userRole = storedUserRole;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Plantation Management',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1602777650437-1ef7bc95e6db?ixlib=rb-4.0.3&auto=format&fit=crop&w=1950&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Create Planting'),
                Tab(text: 'Active Plantings'),
                Tab(text: 'Planting Details'),
                Tab(text: 'Tasks'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            KeepAliveTab(child: CreatePlantingTab(authToken: widget.authToken)),
            KeepAliveTab(child: ActivePlantingTab(authToken: widget.authToken, tabController: _tabController, plantingDetailsKey: _plantingDetailsKey)),
            KeepAliveTab(child: PlantingDetailsTab(authToken: widget.authToken, key: _plantingDetailsKey)),
            KeepAliveTab(child: TasksTab(authToken: widget.authToken)),
          ],
        ),
      ),
    );
  }
}

// Tab 1: Create a New Planting
class CreatePlantingTab extends StatefulWidget {
  final String? authToken;
  const CreatePlantingTab({Key? key, this.authToken}) : super(key: key);

  @override
  State<CreatePlantingTab> createState() => _CreatePlantingTabState();
}

class _CreatePlantingTabState extends State<CreatePlantingTab> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _plotIdentifierController = TextEditingController();
  final _numberOfPlantsController = TextEditingController(text: '100');
  final _taskDescriptionController = TextEditingController();
  String _bananaVariety = 'Gonja';
  String _currentStage = 'LAND_PREPARATION';
  DateTime? _plantingDate = DateTime.now();
  DateTime? _expectedHarvestDate;
  DateTime? _taskDueDate;
  String _taskPriority = 'HIGH';
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _createPlanting() async {
    if (!_formKey.currentState!.validate()) return;

    final authToken = widget.authToken ?? await SecureStorage().read('authToken');
    if (authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to create a planting')),
      );
      Navigator.pushReplacementNamed(context, '/auth/signin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final plantingId = const Uuid().v4();
      final taskId = const Uuid().v4();
      final uri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/plantings');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final body = {
        'id': plantingId,
        'plotIdentifier': _plotIdentifierController.text,
        'plantingDate': DateFormat('yyyy-MM-dd').format(_plantingDate!),
        'expectedHarvestDate': _expectedHarvestDate != null
            ? DateFormat('yyyy-MM-dd').format(_expectedHarvestDate!)
            : null,
        'currentStage': _currentStage,
        'daysFromPlanting': 0,
        'numberOfPlants': int.parse(_numberOfPlantsController.text),
        'bananaVariety': _bananaVariety,
        'upcomingTasks': [
          {
            'id': taskId,
            'description': _taskDescriptionController.text,
            'dueDate': _taskDueDate != null
                ? DateFormat('yyyy-MM-dd').format(_taskDueDate!)
                : null,
            'status': 'PENDING',
            'priority': _taskPriority,
            'category': _currentStage,
            'plantingId': plantingId,
            'plotIdentifier': _plotIdentifierController.text,
          }
        ],
        'completedTasksCount': 0,
        'totalTasksCount': 1,
        'progressPercentage': 0.0,
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planting created successfully!')),
        );
        _plotIdentifierController.clear();
        _numberOfPlantsController.text = '100';
        _taskDescriptionController.clear();
        setState(() {
          _bananaVariety = 'Gonja';
          _currentStage = 'LAND_PREPARATION';
          _plantingDate = DateTime.now();
          _expectedHarvestDate = null;
          _taskDueDate = null;
          _taskPriority = 'HIGH';
        });
      } else {
        throw Exception('Failed to create planting: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _plotIdentifierController.dispose();
    _numberOfPlantsController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _plotIdentifierController,
              decoration: InputDecoration(
                labelText: 'Plot Identifier',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.map),
              ),
              validator: (value) =>
              value == null || value.isEmpty ? 'Please enter a plot identifier' : null,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _plantingDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  setState(() => _plantingDate = pickedDate);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _plantingDate != null
                          ? DateFormat('yyyy-MM-dd').format(_plantingDate!)
                          : 'Select Planting Date',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _expectedHarvestDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  setState(() => _expectedHarvestDate = pickedDate);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _expectedHarvestDate != null
                          ? DateFormat('yyyy-MM-dd').format(_expectedHarvestDate!)
                          : 'Select Expected Harvest Date',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numberOfPlantsController,
              decoration: InputDecoration(
                labelText: 'Number of Plants',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.local_florist),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter the number of plants';
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _bananaVariety,
              decoration: InputDecoration(
                labelText: 'Banana Variety',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.eco),
              ),
              items: ['Gonja', 'Cavendish', 'Sukali Ndizi', 'Matooke']
                  .map((variety) => DropdownMenuItem(
                value: variety,
                child: Text(variety),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() => _bananaVariety = value!);
              },
              validator: (value) => value == null ? 'Please select a banana variety' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currentStage,
              decoration: InputDecoration(
                labelText: 'Current Stage',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.trending_up),
              ),
              items: ['LAND_PREPARATION', 'PLANTING', 'GROWING', 'HARVESTING']
                  .map((stage) => DropdownMenuItem(
                value: stage,
                child: Text(stage.replaceAll('_', ' ')),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() => _currentStage = value!);
              },
              validator: (value) => value == null ? 'Please select a stage' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taskDescriptionController,
              decoration: InputDecoration(
                labelText: 'Initial Task Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.task),
              ),
              validator: (value) =>
              value == null || value.isEmpty ? 'Please enter a task description' : null,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _taskDueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  setState(() => _taskDueDate = pickedDate);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _taskDueDate != null
                          ? DateFormat('yyyy-MM-dd').format(_taskDueDate!)
                          : 'Select Task Due Date',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _taskPriority,
              decoration: InputDecoration(
                labelText: 'Task Priority',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.priority_high),
              ),
              items: ['HIGH', 'MEDIUM', 'LOW']
                  .map((priority) => DropdownMenuItem(
                value: priority,
                child: Text(priority),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() => _taskPriority = value!);
              },
              validator: (value) => value == null ? 'Please select a priority' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createPlanting,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'Create Planting',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab 2: Active Plantings
class ActivePlantingTab extends StatefulWidget {
  final String? authToken;
  final TabController tabController;
  final GlobalKey<PlantingDetailsTabState> plantingDetailsKey;
  const ActivePlantingTab({Key? key, this.authToken, required this.tabController, required this.plantingDetailsKey}) : super(key: key);

  @override
  State<ActivePlantingTab> createState() => _ActivePlantingTabState();
}

class _ActivePlantingTabState extends State<ActivePlantingTab> with AutomaticKeepAliveClientMixin {
  List<dynamic> _plantings = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchActivePlantings();
    print('ActivePlantingTab initialized');
  }

  Future<void> _fetchActivePlantings() async {
    final authToken = widget.authToken ?? await SecureStorage().read('authToken');
    if (authToken == null) {
      Navigator.pushReplacementNamed(context, '/auth/signin');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/plantings/active');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final response = await http.get(uri, headers: headers);

      print('Active plantings response status: ${response.statusCode}');
      print('Active plantings response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _plantings = jsonDecode(response.body);
          print('Active plantings fetched: $_plantings');
        });
      } else {
        throw Exception('Failed to fetch active plantings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        print('Error fetching active plantings: $e');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _trySetPlantingId(String plantingId, {int retries = 3, int delayMs = 100}) {
    if (retries <= 0) {
      print('Error: Max retries reached, could not set planting ID');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load planting details. Please try again.')),
      );
      return;
    }

    if (widget.plantingDetailsKey.currentState != null) {
      print('Setting planting ID: $plantingId');
      widget.plantingDetailsKey.currentState!.setPlantingId(plantingId);
    } else {
      print('PlantingDetailsTab state not found, retrying ($retries attempts left)...');
      Future.delayed(Duration(milliseconds: delayMs), () {
        _trySetPlantingId(plantingId, retries: retries - 1, delayMs: delayMs * 2);
      });
    }
  }

  Widget _buildPlantingCard(Map<String, dynamic> planting) {
    return GestureDetector(
      onTap: () {
        print('Navigating to PlantingDetailsTab with planting ID: ${planting['id']}');
        widget.tabController.animateTo(2);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _trySetPlantingId(planting['id']);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.2)),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  planting['plotIdentifier'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    planting['bananaVariety'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  planting['plantingDate'] != null
                      ? 'Planted: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(planting['plantingDate']))}'
                      : 'Planted: N/A',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.trending_up, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Stage: ${planting['currentStage']?.replaceAll('_', ' ') ?? 'N/A'}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.local_florist, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '${planting['numberOfPlants'] ?? 'N/A'} plants',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  planting['progressPercentage'] != null
                      ? '${(planting['progressPercentage'] * 1).toStringAsFixed(1)}%'
                      : 'N/A',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: planting['progressPercentage'] ?? .0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${planting['completedTasksCount'] ?? 'N/A'} tasks completed',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  planting['totalTasksCount'] != null && planting['completedTasksCount'] != null
                      ? '${planting['totalTasksCount'] - planting['completedTasksCount']} remaining'
                      : 'N/A remaining',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return RefreshIndicator(
      onRefresh: _fetchActivePlantings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Plantings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${_plantings.length} active',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text('Error: $_error'))
            else if (_plantings.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'No active plantings found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => widget.tabController.animateTo(0),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Planting',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._plantings.map((planting) => _buildPlantingCard(planting)).toList(),
          ],
        ),
      ),
    );
  }
}

// Tab 3: Planting Details
class PlantingDetailsTab extends StatefulWidget {
  final String? authToken;
  const PlantingDetailsTab({Key? key, this.authToken}) : super(key: key);

  @override
  PlantingDetailsTabState createState() => PlantingDetailsTabState();
}

class PlantingDetailsTabState extends State<PlantingDetailsTab> with AutomaticKeepAliveClientMixin {
  String? _plantingId;
  Map<String, dynamic>? _plantingDetails;
  List<dynamic>? _tasks;
  Map<String, dynamic>? _progress;
  bool _isLoading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('PlantingDetailsTab initialized');
  }

  void setPlantingId(String id) {
    print('setPlantingId called with ID: $id');
    setState(() {
      _plantingId = id;
      _plantingDetails = null;
      _tasks = null;
      _progress = null;
    });
    _fetchPlantingData();
  }

  String _formatLargeNumber(int? number) {
    if (number == null) return 'N/A';
    if (number < 1000) return number.toString();
    if (number < 1000000) return '${(number / 1000).toStringAsFixed(2)}K';
    if (number < 1000000000) return '${(number / 1000000).toStringAsFixed(2)}M';
    return '${(number / 1000000000).toStringAsFixed(2)}B';
  }

  Future<void> _fetchPlantingData() async {
    if (_plantingId == null) {
      print('No planting ID set, skipping fetch');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authToken = widget.authToken ?? await SecureStorage().read('authToken');
      if (authToken == null) {
        throw Exception('No auth token available');
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      // Fetch planting details
      final detailsUri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/plantings/$_plantingId');
      print('Fetching planting details from: $detailsUri');
      final detailsResponse = await http.get(detailsUri, headers: headers);
      print('Planting details response status: ${detailsResponse.statusCode}');
      print('Planting details response body: ${detailsResponse.body}');

      if (detailsResponse.statusCode == 200) {
        _plantingDetails = jsonDecode(detailsResponse.body);
      } else {
        throw Exception('Failed to fetch planting details: ${detailsResponse.statusCode} - ${detailsResponse.body}');
      }

      // Fetch tasks
      final tasksUri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/plantings/$_plantingId/tasks');
      print('Fetching tasks from: $tasksUri');
      final tasksResponse = await http.get(tasksUri, headers: headers);
      print('Tasks response status: ${tasksResponse.statusCode}');
      print('Tasks response body: ${tasksResponse.body}');

      if (tasksResponse.statusCode == 200) {
        _tasks = jsonDecode(tasksResponse.body);
      } else {
        throw Exception('Failed to fetch tasks: ${tasksResponse.statusCode} - ${tasksResponse.body}');
      }

      // Fetch progress
      final progressUri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/plantings/$_plantingId/progress');
      print('Fetching progress from: $progressUri');
      final progressResponse = await http.get(progressUri, headers: headers);
      print('Progress response status: ${progressResponse.statusCode}');
      print('Progress response body: ${progressResponse.body}');

      if (progressResponse.statusCode == 200) {
        _progress = jsonDecode(progressResponse.body);
      } else {
        throw Exception('Failed to fetch progress: ${progressResponse.statusCode} - ${progressResponse.body}');
      }

      setState(() {});
    } catch (e) {
      setState(() {
        _error = e.toString();
        print('Error fetching planting data: $e');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return RefreshIndicator(
      onRefresh: _fetchPlantingData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_plantingId == null)
              const Center(child: Text('Select a planting from Active Plantings tab.'))
            else if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
                Center(child: Text('Error: $_error'))
              else if (_plantingDetails == null || _tasks == null || _progress == null)
                  const Center(child: Text('No data available. Tap a planting to load details.'))
                else
                  ...[
                    _buildSectionCard(
                      'Planting Details',
                      [
                        {'label': 'ID', 'value': _plantingDetails!['id'] ?? 'N/A'},
                        {'label': 'Plot', 'value': _plantingDetails!['plotIdentifier'] ?? 'N/A'},
                        {'label': 'Variety', 'value': _plantingDetails!['bananaVariety'] ?? 'N/A'},
                        {
                          'label': 'Plants',
                          'value': _formatLargeNumber(_plantingDetails!['numberOfPlants'] as int?)
                        },
                        {'label': 'Planting Date', 'value': _plantingDetails!['plantingDate'] ?? 'N/A'},
                        {
                          'label': 'Expected Harvest',
                          'value': _plantingDetails!['expectedHarvestDate'] ?? 'N/A'
                        },
                        {
                          'label': 'Current Stage',
                          'value': _plantingDetails!['currentStage']?.replaceAll('_', ' ') ?? 'N/A'
                        },
                        {
                          'label': 'Days from Planting',
                          'value': _formatLargeNumber(_plantingDetails!['daysFromPlanting'] as int?)
                        },
                      ],
                      Icons.local_florist,
                    ),
                    const SizedBox(height: 16),
                    _buildTasksSection('Tasks', _tasks!, false),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      'Progress',
                      [
                        {
                          'label': 'Completed Tasks',
                          'value': _formatLargeNumber(_progress!['completedTasksCount'] as int?)
                        },
                        {
                          'label': 'Total Tasks',
                          'value': _formatLargeNumber(_progress!['totalTasksCount'] as int?)
                        },
                        {
                          'label': 'Progress',
                          'value': _progress!['progressPercentage'] != null
                              ? '${(_progress!['progressPercentage'] * 100).toStringAsFixed(1)}%'
                              : 'N/A'
                        },
                      ],
                      Icons.trending_up,
                    ),
                  ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Map<String, String>> items, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[700]!.withOpacity(0.3), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[700]!.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green[700]!.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green[900]!.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.green[700]!.withOpacity(0.1), width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                      .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['label']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Flexible(
                          child: Text(
                            item['value']!,
                            style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSection(String title, List<dynamic> tasks, bool showCompleteButton) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[700]!.withOpacity(0.3), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[700]!.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green[700]!.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.task_alt, color: Colors.white, size: 20),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green[900]!.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.green[700]!.withOpacity(0.1), width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tasks.isEmpty
                      ? [const Text('No tasks available', style: TextStyle(fontSize: 14, color: Colors.grey))]
                      : tasks
                      .map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${task['description'] ?? 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID: ${task['id'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                              Text(
                                'Due: ${task['dueDate'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                              Text(
                                'Status: ${task['status'] ?? 'N/A'}',
                                style: TextStyle(
                                  color: task['status'] == 'PENDING' ? Colors.orange[700] : Colors.green[700],
                                ),
                              ),
                              Text(
                                'Priority: ${task['priority'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                              Text(
                                'Category: ${task['category'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                              Text(
                                'Planting ID: ${task['plantingId'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                              Text(
                                'Plot: ${task['plotIdentifier'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tab 4: Tasks
class TasksTab extends StatefulWidget {
  final String? authToken;
  const TasksTab({Key? key, this.authToken}) : super(key: key);

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> with AutomaticKeepAliveClientMixin {
  List<dynamic> _upcomingTasks = [];
  List<dynamic> _todayTasks = [];
  List<dynamic> _overdueTasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    print('TasksTab initialized');
  }

  Future<void> _fetchTasks() async {
    final authToken = widget.authToken ?? await SecureStorage().read('authToken');
    if (authToken == null) {
      Navigator.pushReplacementNamed(context, '/auth/signin');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      // Fetch upcoming tasks
      final upcomingUri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/tasks/upcoming');
      print('Fetching upcoming tasks from: $upcomingUri');
      final upcomingResponse = await http.get(upcomingUri, headers: headers);
      print('Upcoming tasks response status: ${upcomingResponse.statusCode}');
      print('Upcoming tasks response body: ${upcomingResponse.body}');

      if (upcomingResponse.statusCode == 200) {
        _upcomingTasks = jsonDecode(upcomingResponse.body);
        print('Upcoming tasks fetched: $_upcomingTasks');
      } else {
        throw Exception('Failed to fetch upcoming tasks: ${upcomingResponse.statusCode} - ${upcomingResponse.body}');
      }

      // Fetch today's tasks
      final todayUri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/tasks/today');
      print('Fetching today\'s tasks from: $todayUri');
      final todayResponse = await http.get(todayUri, headers: headers);
      print('Today tasks response status: ${todayResponse.statusCode}');
      print('Today tasks response body: ${todayResponse.body}');

      if (todayResponse.statusCode == 200) {
        _todayTasks = jsonDecode(todayResponse.body);
        print('Today tasks fetched: $_todayTasks');
      } else {
        throw Exception('Failed to fetch today\'s tasks: ${todayResponse.statusCode} - ${todayResponse.body}');
      }

      // Fetch overdue tasks
      final overdueUri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/tasks/overdue');
      print('Fetching overdue tasks from: $overdueUri');
      final overdueResponse = await http.get(overdueUri, headers: headers);
      print('Overdue tasks response status: ${overdueResponse.statusCode}');
      print('Overdue tasks response body: ${overdueResponse.body}');

      if (overdueResponse.statusCode == 200) {
        _overdueTasks = jsonDecode(overdueResponse.body);
        print('Overdue tasks fetched: $_overdueTasks');
      } else {
        throw Exception('Failed to fetch overdue tasks: ${overdueResponse.statusCode} - ${overdueResponse.body}');
      }

      setState(() {});
    } catch (e) {
      setState(() {
        _error = e.toString();
        print('Error fetching tasks: $e');
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeTask(String taskId) async {
    try {
      final authToken = widget.authToken ?? await SecureStorage().read('authToken');
      if (authToken == null) {
        throw Exception('No auth token available');
      }

      final uri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/tasks/$taskId/complete');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      print('Completing task with ID: $taskId');
      final response = await http.post(uri, headers: headers);
      print('Task completion response status: ${response.statusCode}');
      print('Task completion response body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task completed successfully!')),
        );
        await _fetchTasks(); // Refresh all tasks
      } else {
        throw Exception('Failed to complete task: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing task: $e')),
      );
      print('Error completing task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return RefreshIndicator(
      onRefresh: _fetchTasks,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasks',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text('Error: $_error'))
            else if (_upcomingTasks.isEmpty && _todayTasks.isEmpty && _overdueTasks.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_alt, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'No tasks found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...[
                  if (_overdueTasks.isNotEmpty)
                    _buildTasksSection('Overdue Tasks', _overdueTasks, true),
                  const SizedBox(height: 16),
                  if (_todayTasks.isNotEmpty)
                    _buildTasksSection('Today\'s Tasks', _todayTasks, true),
                  const SizedBox(height: 16),
                  if (_upcomingTasks.isNotEmpty)
                    _buildTasksSection('Upcoming Tasks', _upcomingTasks, true),
                ],
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection(String title, List<dynamic> tasks, bool showCompleteButton) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[700]!.withOpacity(0.3), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[700]!.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green[700]!.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.task_alt, color: Colors.white, size: 20),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green[900]!.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.green[700]!.withOpacity(0.1), width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tasks
                      .map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${task['description'] ?? 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ID: ${task['id'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                              Text(
                                'Due: ${task['dueDate'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                              Text(
                                'Status: ${task['status'] ?? 'N/A'}',
                                style: TextStyle(
                                  color: task['status'] == 'PENDING' ? Colors.orange[700] : Colors.green[700],
                                ),
                              ),
                              Text(
                                'Priority: ${task['priority'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                              Text(
                                'Category: ${task['category'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                              Text(
                                'Planting ID: ${task['plantingId'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                              Text(
                                'Plot: ${task['plotIdentifier'] ?? 'N/A'}',
                                style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                              ),
                              if (showCompleteButton && task['status'] == 'PENDING') ...[
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => _completeTask(task['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text(
                                    'Mark as Complete',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}