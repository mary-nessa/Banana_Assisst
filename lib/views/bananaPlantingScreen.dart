import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bananaassist/utils/secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:http/io_client.dart';

class BananaPlantingScreen extends StatefulWidget {
  final String? authToken; // Added authToken parameter
  const BananaPlantingScreen({Key? key, this.authToken}) : super(key: key);

  @override
  State<BananaPlantingScreen> createState() => _BananaPlantingScreenState();
}

class _BananaPlantingScreenState extends State<BananaPlantingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Banana Planting Guide',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1591955506264-3f5a6834570a?ixlib=rb-1.2.1&auto=format&fit=crop&w=1950&q=80',
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
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            CreatePlantingTab(authToken: widget.authToken),
            ActivePlantingTab(authToken: widget.authToken), // Corrected typo from previous response
            PlantingDetailsTab(authToken: widget.authToken),
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

class _CreatePlantingTabState extends State<CreatePlantingTab> {
  final _formKey = GlobalKey<FormState>();
  final _plotIdentifierController = TextEditingController();
  final _numberOfPlantsController = TextEditingController();
  final _bananaVarietyController = TextEditingController();
  DateTime? _plantingDate;
  bool _isLoading = false;

  Future<void> _createPlanting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);
      final client = IOClient(httpClient);

      final uri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/plantings');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (widget.authToken != null) 'Authorization': 'Bearer ${widget.authToken}',
      };

      final body = {
        'plotIdentifier': _plotIdentifierController.text,
        'plantingDate': _plantingDate != null
            ? DateFormat('yyyy-MM-dd').format(_plantingDate!)
            : DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'numberOfPlants': int.parse(_numberOfPlantsController.text),
        'bananaVariety': _bananaVarietyController.text,
      };

      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planting created successfully!')),
        );
        _plotIdentifierController.clear();
        _numberOfPlantsController.clear();
        _bananaVarietyController.clear();
        setState(() => _plantingDate = null);
      } else {
        throw Exception('Failed to create planting: ${response.statusCode}');
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
    _bananaVarietyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              ),
              validator: (value) =>
              value == null || value.isEmpty ? 'Please enter a plot identifier' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numberOfPlantsController,
              decoration: InputDecoration(
                labelText: 'Number of Plants',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            TextFormField(
              controller: _bananaVarietyController,
              decoration: InputDecoration(
                labelText: 'Banana Variety',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) =>
              value == null || value.isEmpty ? 'Please enter a banana variety' : null,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _createPlanting,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Create Planting',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tab 2: Active Plantings
class ActivePlantingTab extends StatefulWidget { // Corrected typo from previous response
  final String? authToken;
  const ActivePlantingTab({Key? key, this.authToken}) : super(key: key);

  @override
  State<ActivePlantingTab> createState() => _ActivePlantingTabState();
}

class _ActivePlantingTabState extends State<ActivePlantingTab> {
  List<dynamic> _plantings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchActivePlantings();
  }

  Future<void> _fetchActivePlantings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);
      final client = IOClient(httpClient);

      final uri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/plantings/active');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (widget.authToken != null) 'Authorization': 'Bearer ${widget.authToken}',
      };

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          _plantings = jsonDecode(response.body);
        });
      } else {
        throw Exception('Failed to fetch active plantings: ${response.statusCode}');
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
    return RefreshIndicator(
      onRefresh: _fetchActivePlantings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text('Error: $_error'))
            else if (_plantings.isEmpty)
                const Center(child: Text('No active plantings found.'))
              else
                ..._plantings.map((planting) => _buildPlantingCard(planting)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantingCard(Map<String, dynamic> planting) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green[700]!.withOpacity(0.3),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ListTile(
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
              child: const Icon(
                Icons.local_florist,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              'Plot: ${planting['plotIdentifier']}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green[900]!.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              'Variety: ${planting['bananaVariety']} | Plants: ${planting['numberOfPlants']}',
              style: TextStyle(
                color: Colors.green[900]!.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            onTap: () {
              _BananaPlantingScreenState? parentState = context.findAncestorStateOfType<_BananaPlantingScreenState>();
              parentState?._tabController.animateTo(2);
              PlantingDetailsTabState? detailsState = context.findAncestorWidgetOfExactType<PlantingDetailsTab>()?.createState() as PlantingDetailsTabState?;
              detailsState?.setPlantingId(planting['id']);
            },
          ),
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

class PlantingDetailsTabState extends State<PlantingDetailsTab> {
  String? _plantingId;
  Map<String, dynamic>? _plantingDetails;
  List<dynamic>? _tasks;
  Map<String, dynamic>? _progress;
  bool _isLoading = false;
  String? _error;

  void setPlantingId(String id) {
    setState(() {
      _plantingId = id;
    });
    _fetchPlantingDetails();
    _fetchTasks();
    _fetchProgress();
  }

  Future<void> _fetchPlantingDetails() async {
    if (_plantingId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);
      final client = IOClient(httpClient);

      final uri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/plantings/$_plantingId');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (widget.authToken != null) 'Authorization': 'Bearer ${widget.authToken}',
      };

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          _plantingDetails = jsonDecode(response.body);
        });
      } else {
        throw Exception('Failed to fetch planting details: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTasks() async {
    if (_plantingId == null) return;

    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);
      final client = IOClient(httpClient);

      final uri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/plantings/$_plantingId/tasks');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (widget.authToken != null) 'Authorization': 'Bearer ${widget.authToken}',
      };

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          _tasks = jsonDecode(response.body);
        });
      } else {
        throw Exception('Failed to fetch tasks: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _fetchProgress() async {
    if (_plantingId == null) return;

    try {
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);
      final client = IOClient(httpClient);

      final uri = Uri.parse('${dotenv.env['BACKEND_URL']}/api/plantings/$_plantingId/progress');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (widget.authToken != null) 'Authorization': 'Bearer ${widget.authToken}',
      };

      final response = await client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          _progress = jsonDecode(response.body);
        });
      } else {
        throw Exception('Failed to fetch progress: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchPlantingDetails();
        await _fetchTasks();
        await _fetchProgress();
      },
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
              else if (_plantingDetails == null)
                  const Center(child: Text('No details available.'))
                else ...[
                    _buildSectionCard(
                      'Planting Details',
                      [
                        {'label': 'Plot', 'value': _plantingDetails!['plotIdentifier']},
                        {'label': 'Variety', 'value': _plantingDetails!['bananaVariety']},
                        {'label': 'Plants', 'value': _plantingDetails!['numberOfPlants'].toString()},
                        {'label': 'Planting Date', 'value': _plantingDetails!['plantingDate']},
                        {'label': 'Expected Harvest', 'value': _plantingDetails!['expectedHarvestDate']},
                        {'label': 'Current Stage', 'value': _plantingDetails!['currentStage']},
                      ],
                      Icons.local_florist,
                    ),
                    const SizedBox(height: 16),
                    if (_progress != null)
                      _buildSectionCard(
                        'Progress',
                        [
                          {'label': 'Days from Planting', 'value': _progress!['daysFromPlanting'].toString()},
                          {'label': 'Completed Tasks', 'value': '${_progress!['completedTasksCount']}/${_progress!['totalTasksCount']}'},
                          {'label': 'Progress', 'value': '${(_progress!['progressPercentage'] * 100).toStringAsFixed(1)}%'},
                        ],
                        Icons.bar_chart,
                      ),
                    const SizedBox(height: 16),
                    if (_tasks != null && _tasks!.isNotEmpty)
                      _buildTasksSection(),
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
        border: Border.all(
          color: Colors.green[700]!.withOpacity(0.3),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
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
                  border: Border(
                    top: BorderSide(
                      color: Colors.green[700]!.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['label']!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          item['value']!,
                          style: TextStyle(color: Colors.green[900]!.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green[700]!.withOpacity(0.3),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
              child: const Icon(
                Icons.task_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              'Tasks',
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
                  border: Border(
                    top: BorderSide(
                      color: Colors.green[700]!.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _tasks!.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${task['description']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due: ${task['dueDate']}',
                                style: TextStyle(
                                  color: Colors.green[900]!.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Status: ${task['status']}',
                                style: TextStyle(
                                  color: task['status'] == 'PENDING'
                                      ? Colors.orange[700]
                                      : Colors.green[700],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Priority: ${task['priority']}',
                                style: TextStyle(
                                  color: Colors.green[900]!.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}