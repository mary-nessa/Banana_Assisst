import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
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

class _BananaPlantingScreenState extends State<BananaPlantingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? userRole;
  final GlobalKey<PlantingDetailsTabState> _plantingDetailsKey =
      GlobalKey<PlantingDetailsTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAuth();
    print('BananaPlantingScreen initialized');
  }

  Future<void> _checkAuth() async {
    final authToken =
        widget.authToken ?? await SecureStorage().read('authToken');
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
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 150.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://media.gettyimages.com/id/892779264/photo/banana-tree.jpg?s=612x612&w=gi&k=20&c=gnUiqLzdAn8izLhDmNkx2ft9M1SC0v-7M_TXAImiEhE=',
                        // 'https://images.unsplash.com/photo-1602777650437-1ef7bc95e6db?ixlib=rb-4.0.3&auto=format&fit=crop&w=1950&q=80',
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
            KeepAliveTab(
              child: CreatePlantingTab(
                authToken: widget.authToken,
                tabController: _tabController,
              ),
            ),
            KeepAliveTab(
              child: ActivePlantingTab(
                authToken: widget.authToken,
                tabController: _tabController,
                plantingDetailsKey: _plantingDetailsKey,
              ),
            ),
            KeepAliveTab(
              child: PlantingDetailsTab(
                authToken: widget.authToken,
                key: _plantingDetailsKey,
              ),
            ),
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
  final TabController tabController; // Add this
  const CreatePlantingTab({
    Key? key,
    this.authToken,
    required this.tabController, // Add this
  }) : super(key: key);

  @override
  State<CreatePlantingTab> createState() => _CreatePlantingTabState();
}

class _CreatePlantingTabState extends State<CreatePlantingTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _plotIdentifierController = TextEditingController();
  final _numberOfPlantsController = TextEditingController(text: '100');
  String _bananaVariety = 'Gonja';
  DateTime? _plantingDate = DateTime.now();
  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _createPlanting() async {
    if (!_formKey.currentState!.validate()) return;

    final authToken =
        widget.authToken ?? await SecureStorage().read('authToken');
    if (authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to create a planting'),
        ),
      );
      Navigator.pushReplacementNamed(context, '/auth/signin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/plantings');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final body = {
        'plotIdentifier': _plotIdentifierController.text,
        'plantingDate': DateFormat('yyyy-MM-dd').format(_plantingDate!),
        'numberOfPlants': int.parse(_numberOfPlantsController.text),
        'bananaVariety': _bananaVariety,
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      print('Create planting response status: ${response.statusCode}');
      print('Create planting response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planting created successfully!')),
        );
        _plotIdentifierController.clear();
        _numberOfPlantsController.text = '100';
        setState(() {
          _bananaVariety = 'Gonja';
          _plantingDate = DateTime.now();
        });
        // Navigate to Active Plantings tab
        widget.tabController.animateTo(1);
      } else {
        throw Exception(
          'Failed to create planting: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _plotIdentifierController.dispose();
    _numberOfPlantsController.dispose();
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
              validator:
                  (value) =>
                      value == null || value.isEmpty
                          ? 'Please enter a plot identifier'
                          : null,
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
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
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
                if (value == null || value.isEmpty)
                  return 'Please enter the number of plants';
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
              items:
                  ['Gonja', 'Cavendish', 'Sukali Ndizi', 'Matooke']
                      .map(
                        (variety) => DropdownMenuItem(
                          value: variety,
                          child: Text(variety),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() => _bananaVariety = value!);
              },
              validator:
                  (value) =>
                      value == null ? 'Please select a banana variety' : null,
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
              child:
                  _isLoading
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
  const ActivePlantingTab({
    Key? key,
    this.authToken,
    required this.tabController,
    required this.plantingDetailsKey,
  }) : super(key: key);

  @override
  State<ActivePlantingTab> createState() => _ActivePlantingTabState();
}

class _ActivePlantingTabState extends State<ActivePlantingTab>
    with AutomaticKeepAliveClientMixin {
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
    final authToken =
        widget.authToken ?? await SecureStorage().read('authToken');
    if (authToken == null) {
      Navigator.pushReplacementNamed(context, '/auth/signin');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(
        '${dotenv.env['BACKEND_URL']}/api/plantings/active',
      );
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
        throw Exception(
          'Failed to fetch active plantings: ${response.statusCode} - ${response.body}',
        );
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

  void _trySetPlantingId(
    String plantingId, {
    int retries = 3,
    int delayMs = 100,
  }) {
    if (retries <= 0) {
      print('Error: Max retries reached, could not set planting ID');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load planting details. Please try again.'),
        ),
      );
      return;
    }

    if (widget.plantingDetailsKey.currentState != null) {
      print('Setting planting ID: $plantingId');
      widget.plantingDetailsKey.currentState!.setPlantingId(plantingId);
    } else {
      print(
        'PlantingDetailsTab state not found, retrying ($retries attempts left)...',
      );
      Future.delayed(Duration(milliseconds: delayMs), () {
        _trySetPlantingId(
          plantingId,
          retries: retries - 1,
          delayMs: delayMs * 2,
        );
      });
    }
  }

  Widget _buildPlantingCard(Map<String, dynamic> planting) {
    return GestureDetector(
      onTap: () {
        print(
          'Navigating to PlantingDetailsTab with planting ID: ${planting['id']}',
        );
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
                  planting['totalTasksCount'] != null &&
                          planting['completedTasksCount'] != null
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
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
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
              ..._plantings
                  .map((planting) => _buildPlantingCard(planting))
                  .toList(),
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

class PlantingDetailsTabState extends State<PlantingDetailsTab>
    with AutomaticKeepAliveClientMixin {
  String? _plantingId;
  Map<String, dynamic>? _plantingDetails;
  List<dynamic>? _tasks;
  Map<String, dynamic>? _progress;
  bool _isLoading = false;
  String? _error;

  final List<String> _stages = [
    'LAND_PREPARATION',
    'PLANTING',
    'VEGETATIVE_GROWTH',
    'FLOWERING',
    'FRUIT_DEVELOPMENT',
    'HARVEST',
    'POST_HARVEST',
  ];

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
      final authToken =
          widget.authToken ?? await SecureStorage().read('authToken');
      if (authToken == null) {
        throw Exception('No auth token available');
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      // Fetch planting details
      final detailsUri = Uri.parse(
        '${dotenv.env['BACKEND_URL']}/api/plantings/$_plantingId',
      );
      print('Fetching planting details from: $detailsUri');
      final detailsResponse = await http.get(detailsUri, headers: headers);
      print('Planting details response status: ${detailsResponse.statusCode}');
      print('Planting details response body: ${detailsResponse.body}');

      if (detailsResponse.statusCode == 200) {
        _plantingDetails = jsonDecode(detailsResponse.body);
      } else {
        throw Exception(
          'Failed to fetch planting details: ${detailsResponse.statusCode} - ${detailsResponse.body}',
        );
      }

      // Fetch tasks
      final tasksUri = Uri.parse(
        '${dotenv.env['BACKEND_URL']}/api/plantings/$_plantingId/tasks',
      );
      print('Fetching tasks from: $tasksUri');
      final tasksResponse = await http.get(tasksUri, headers: headers);
      print('Tasks response status: ${tasksResponse.statusCode}');
      print('Tasks response body: ${tasksResponse.body}');

      if (tasksResponse.statusCode == 200) {
        _tasks = jsonDecode(tasksResponse.body);
      } else {
        throw Exception(
          'Failed to fetch tasks: ${tasksResponse.statusCode} - ${tasksResponse.body}',
        );
      }

      // Fetch progress
      final progressUri = Uri.parse(
        '${dotenv.env['BACKEND_URL']}/api/plantings/$_plantingId/progress',
      );
      print('Fetching progress from: $progressUri');
      final progressResponse = await http.get(progressUri, headers: headers);
      print('Progress response status: ${progressResponse.statusCode}');
      print('Progress response body: ${progressResponse.body}');

      if (progressResponse.statusCode == 200) {
        _progress = jsonDecode(progressResponse.body);
      } else {
        throw Exception(
          'Failed to fetch progress: ${progressResponse.statusCode} - ${progressResponse.body}',
        );
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

  Future<void> _completeTask(String taskId) async {
    try {
      final authToken =
          widget.authToken ?? await SecureStorage().read('authToken');
      if (authToken == null) {
        throw Exception('No auth token available');
      }

      final uri = Uri.parse(
        '${dotenv.env['BACKEND_URL']}/api/tasks/$taskId/complete',
      );
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

      final response = await http.post(uri, headers: headers);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task completed successfully!')),
        );
        await _fetchPlantingData(); // Refresh the data
      } else {
        throw Exception(
          'Failed to complete task: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error completing task: $e')));
    }
  }

  Widget _buildStagesView() {
    final currentStage = _plantingDetails?['currentStage'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stages',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_stages.length, (index) {
          final stage = _stages[index];
          final isCurrentStage = stage == currentStage;
          final isPastStage = _stages.indexOf(currentStage ?? '') > index;
          final hasReachedStage = isCurrentStage || isPastStage;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color:
                    isCurrentStage
                        ? Colors.green
                        : Colors.grey.withOpacity(0.3),
                width: isCurrentStage ? 2 : 1,
              ),
            ),
            child: ExpansionTile(
              initiallyExpanded: isCurrentStage,
              title: Row(
                children: [
                  Icon(
                    isPastStage
                        ? Icons.check_circle
                        : (isCurrentStage
                            ? Icons.play_circle
                            : Icons.circle_outlined),
                    color:
                        isPastStage
                            ? Colors.green
                            : (isCurrentStage ? Colors.orange : Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stage.replaceAll('_', ' '),
                    style: TextStyle(
                      fontWeight:
                          isCurrentStage ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentStage ? Colors.green : Colors.black87,
                    ),
                  ),
                ],
              ),
              children: [
                if (!hasReachedStage)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'This stage has not been reached yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else if (isCurrentStage && _tasks != null)
                  // Show all tasks as they are already filtered by the backend for the current stage
                  ..._tasks!.map((task) => _buildTaskItem(task)).toList()
                else if (isPastStage)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'This stage has been completed.',
                      style: TextStyle(color: Colors.green),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    final isCompleted = task['status'] == 'COMPLETED';
    return ListTile(
      leading: Icon(
        isCompleted ? Icons.check_circle : Icons.pending,
        color: isCompleted ? Colors.green : Colors.orange,
      ),
      title: Text(
        task['description'] ?? 'No description',
        style: TextStyle(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: isCompleted ? Colors.grey : Colors.black87,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Due: ${task['dueDate'] ?? 'No due date'}'),
          Text('Priority: ${task['priority'] ?? 'No priority'}'),
        ],
      ),
      trailing:
          !isCompleted
              ? ElevatedButton(
                onPressed: () => _completeTask(task['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Complete',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : null,
    );
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
              const Center(
                child: Text('Select a planting from Active Plantings tab.'),
              )
            else if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text('Error: $_error'))
            else if (_plantingDetails == null || _tasks == null)
              const Center(
                child: Text(
                  'No data available. Tap a planting to load details.',
                ),
              )
            else ...[
              // Basic planting information
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plot: ${_plantingDetails!['plotIdentifier']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Variety: ${_plantingDetails!['bananaVariety']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Plants: ${_formatLargeNumber(_plantingDetails!['numberOfPlants'] as int?)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Planted: ${_plantingDetails!['plantingDate'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (_plantingDetails!['expectedHarvestDate'] != null)
                        Text(
                          'Expected Harvest: ${_plantingDetails!['expectedHarvestDate']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Progress information
              if (_progress != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: ${(_progress!['progressPercentage'] * 1).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_progress!['completedTasksCount']} / ${_progress!['totalTasksCount']} tasks',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress!['progressPercentage'] ?? 0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 24),
              ],
              // Stages view
              _buildStagesView(),
            ],
          ],
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

class _TasksTabState extends State<TasksTab>
    with AutomaticKeepAliveClientMixin {
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
  }

  Future<void> _fetchTasks() async {
    final authToken =
        widget.authToken ?? await SecureStorage().read('authToken');
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

      final upcomingUri = Uri.parse(
        '${dotenv.env['BACKEND_URL']}/api/tasks/upcoming',
      );
      final todayUri = Uri.parse(
        '${dotenv.env['BACKEND_URL']}/api/tasks/today',
      );
      final overdueUri = Uri.parse(
        '${dotenv.env['BACKEND_URL']}/api/tasks/overdue',
      );

      final responses = await Future.wait([
        http.get(upcomingUri, headers: headers),
        http.get(todayUri, headers: headers),
        http.get(overdueUri, headers: headers),
      ]);

      if (responses.every((response) => response.statusCode == 200)) {
        setState(() {
          _upcomingTasks = jsonDecode(responses[0].body);
          _todayTasks = jsonDecode(responses[1].body);
          _overdueTasks = jsonDecode(responses[2].body);
        });
      } else {
        throw Exception('Failed to fetch tasks');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
            else if (_upcomingTasks.isEmpty &&
                _todayTasks.isEmpty &&
                _overdueTasks.isEmpty)
              const Center(
                child: Text(
                  'No tasks available',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else ...[
              if (_overdueTasks.isNotEmpty)
                _buildTaskList('Overdue Tasks', _overdueTasks),
              if (_todayTasks.isNotEmpty)
                _buildTaskList('Today\'s Tasks', _todayTasks),
              if (_upcomingTasks.isNotEmpty)
                _buildTaskList('Upcoming Tasks', _upcomingTasks),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(String title, List<dynamic> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        ...tasks
            .map(
              (task) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(task['description'] ?? 'No description'),
                  subtitle: Text(
                    'Due: ${task['dueDate'] ?? 'No due date'}\n'
                    'Priority: ${task['priority'] ?? 'No priority'}',
                  ),
                  trailing: Text(
                    task['status'] ?? 'PENDING',
                    style: TextStyle(
                      color:
                          task['status'] == 'COMPLETED'
                              ? Colors.green
                              : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
        const SizedBox(height: 16),
      ],
    );
  }
}
