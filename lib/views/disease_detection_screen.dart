import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({Key? key}) : super(key: key);

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _webImage;
  File? _imageFile;
  bool _isLoading = false;
  String? _analysisResult;
  String? _diseaseLevel;

  // Simulated disease database (unchanged)
  final List<Map<String, dynamic>> _diseaseDatabase = [
    {
      'name': 'Healthy',
      'description': 'The plant shows no signs of disease',
      'treatment': 'No treatment needed. Maintain good cultivation practices.',
      'confidenceRange': [85, 100],
      'level': 'None'
    },
    {
      'name': 'Black Sigatoka',
      'description': 'Dark leaf spots with yellow halos, starting on older leaves',
      'treatment': 'Apply systemic fungicides. Remove severely infected leaves.',
      'confidenceRange': [70, 95],
      'levels': [
        {'name': 'Early', 'treatment': 'Apply fungicide every 2-3 weeks'},
        {'name': 'Moderate', 'treatment': 'Increase fungicide frequency to weekly'},
        {'name': 'Severe', 'treatment': 'Remove infected leaves and apply intensive fungicide treatment'},
      ]
    },
    {
      'name': 'Yellow Sigatoka',
      'description': 'Yellow-brown leaf spots, smaller than Black Sigatoka',
      'treatment': 'Fungicide application. Improve air circulation.',
      'confidenceRange': [70, 90],
      'levels': [
        {'name': 'Early', 'treatment': 'Apply contact fungicides'},
        {'name': 'Moderate', 'treatment': 'Combine systemic and contact fungicides'},
        {'name': 'Severe', 'treatment': 'Remove infected leaves and apply intensive treatment'},
      ]
    },
    {
      'name': 'Panama Disease',
      'description': 'Yellowing of older leaves, wilting, vascular discoloration',
      'treatment': 'No cure. Remove infected plants. Use resistant varieties.',
      'confidenceRange': [80, 95],
      'levels': [
        {'name': 'Early', 'treatment': 'Isolate plant and monitor closely'},
        {'name': 'Advanced', 'treatment': 'Remove plant and disinfect soil'},
        {'name': 'Severe', 'treatment': 'Complete field quarantine and replant with resistant varieties'},
      ]
    }
    // ... (same as original)
  ];

  Future<void> _requestCameraPermission() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required')),
          );
          return;
        }
      }
    }
    _getImageFromCamera();
  }

  Future<void> _getImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        _processPickedFile(pickedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image from camera: $e')),
      );
    }
  }

  Future<void> _getImageFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _processPickedFile(pickedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image from gallery: $e')),
      );
    }
  }

  Future<void> _processPickedFile(XFile pickedFile) async {
    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _webImage = bytes;
        _imageFile = null;
        _analysisResult = null;
        _diseaseLevel = null;
      });
    } else {
      setState(() {
        _imageFile = File(pickedFile.path);
        _webImage = null;
        _analysisResult = null;
        _diseaseLevel = null;
      });
    }
  }

  void _analyzeImage() {
    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _analysisResult = null;
      _diseaseLevel = null;
    });

    Future.delayed(const Duration(seconds: 2), () {
      final random = DateTime.now().millisecond % _diseaseDatabase.length;
      final disease = _diseaseDatabase[random];
      final confidence = _randomInRange(disease['confidenceRange'][0], disease['confidenceRange'][1]);

      String levelInfo = '';
      if (disease['name'] != 'Healthy') {
        final levels = disease['levels'];
        final level = levels[DateTime.now().second % levels.length];
        _diseaseLevel = level['name'];
        levelInfo = '\nDisease Level: ${level['name']}\nLevel-specific Treatment: ${level['treatment']}';
      }

      setState(() {
        _isLoading = false;
        _analysisResult = '${disease['name']} (Confidence: $confidence%)\n\n'
            'Description: ${disease['description']}\n'
            '$levelInfo\n\n'
            'Recommended Treatment:\n${disease['treatment']}';
      });
    });
  }

  int _randomInRange(int min, int max) {
    final random = DateTime.now().millisecond;
    return min + (random % (max - min + 1));
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
      _webImage = null;
      _analysisResult = null;
      _diseaseLevel = null;
    });
  }

  Widget _buildImagePreview() {
    if (_imageFile == null && _webImage == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 50, color: Colors.green),
          const SizedBox(height: 8),
          const Text(
            'Upload an image',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        kIsWeb
            ? Image.memory(_webImage!, fit: BoxFit.cover)
            : Image.file(_imageFile!, fit: BoxFit.cover),
        Positioned(
          top: 5,
          right: 5,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: _clearImage,
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
          ),
        ),
      ],
    );
  }

  Color _getDiseaseColor(String? diseaseName) {
    if (diseaseName == null) return Colors.grey;
    switch (diseaseName) {
      case 'Healthy':
        return Colors.green;
      case 'Black Sigatoka':
        return Colors.orange[800]!;
      case 'Yellow Sigatoka':
        return Colors.amber[800]!;
      case 'Panama Disease':
        return Colors.red[800]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banana Leaf Disease Detection'),
        centerTitle: true,
        backgroundColor: Colors.green,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Reduced padding
            child: Column(
              children: [
                // Image Upload Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Text(
                          'Upload Banana Leaf Image',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.25, // Dynamic height (25% of screen)
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: _buildImagePreview(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _requestCameraPermission,
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Camera'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  textStyle: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _getImageFromGallery,
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Gallery'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  textStyle: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _analyzeImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            'Analyze Image',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Results Section
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diagnosis Results',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildResultsContent(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_analysisResult != null) ...[
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 40,
                        color: _getDiseaseColor(_analysisResult!.split(' ')[0]),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Diagnosis',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _analysisResult!,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  if (_diseaseLevel != null) ...[
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        _diseaseLevel!,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: _getDiseaseColor(_analysisResult!.split(' ')[0]),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Disease Info',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_analysisResult!.contains('Black Sigatoka')) ...[
                    const Text('• Caused by fungus Mycosphaerella fijiensis', style: TextStyle(fontSize: 12)),
                    const Text('• Spread by wind and rain', style: TextStyle(fontSize: 12)),
                    const Text('• Affects photosynthesis', style: TextStyle(fontSize: 12)),
                  ] else if (_analysisResult!.contains('Yellow Sigatoka')) ...[
                    const Text('• Caused by Mycosphaerella musicola', style: TextStyle(fontSize: 12)),
                    const Text('• Less severe than Black Sigatoka', style: TextStyle(fontSize: 12)),
                    const Text('• Prefers cooler temperatures', style: TextStyle(fontSize: 12)),
                  ] else if (_analysisResult!.contains('Panama Disease')) ...[
                    const Text('• Caused by Fusarium oxysporum', style: TextStyle(fontSize: 12)),
                    const Text('• Soil-borne, spreads via roots', style: TextStyle(fontSize: 12)),
                    const Text('• Persists in soil for decades', style: TextStyle(fontSize: 12)),
                  ] else if (_analysisResult!.contains('Healthy')) ...[
                    const Text('• No disease detected', style: TextStyle(fontSize: 12)),
                    const Text('• Maintain good practices', style: TextStyle(fontSize: 12)),
                    const Text('• Monitor regularly', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ] else
          const Text(
            'Upload an image to diagnose',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Tips',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Use good lighting', style: TextStyle(fontSize: 12)),
                Text('• Focus on affected leaves', style: TextStyle(fontSize: 12)),
                Text('• Avoid shadows', style: TextStyle(fontSize: 12)),
                Text('• Capture both sides if possible', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}