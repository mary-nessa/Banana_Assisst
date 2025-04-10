import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VarietyDetectionScreen extends StatefulWidget {
  const VarietyDetectionScreen({Key? key}) : super(key: key);

  @override
  State<VarietyDetectionScreen> createState() => _VarietyDetectionScreenState();
}

class _VarietyDetectionScreenState extends State<VarietyDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  dynamic _imageFile;
  bool _isLoading = false;
  String? _imageUrl;
  String? _analysisResult;
  String? _varietyImage;

  // Banana variety database
  final List<Map<String, dynamic>> _varietyDatabase = [
    {
      'name': 'Cavendish',
      'description': 'The most common commercial banana variety worldwide',
      'characteristics': '• Medium-sized fruits\n• Thick, yellow skin when ripe\n• Sweet and creamy flavor',
      'origin': 'Southeast Asia',
      'confidenceRange': [85, 95],
      'image': 'assets/cavendish.png'
    },
    {
      'name': 'Plantain',
      'description': 'Starchy cooking banana, usually eaten cooked',
      'characteristics': '• Larger than dessert bananas\n• Thick skin\n• Firm, starchy flesh',
      'origin': 'Tropical Africa',
      'confidenceRange': [80, 90],
      'image': 'assets/plantain.png'
    },
    {
      'name': 'Red Banana',
      'description': 'Sweet variety with reddish-purple skin',
      'characteristics': '• Reddish-purple skin\n• Creamy pinkish flesh\n• Sweeter than Cavendish',
      'origin': 'South Asia',
      'confidenceRange': [75, 85],
      'image': 'assets/red_banana.png'
    },
    {
      'name': 'Lady Finger',
      'description': 'Small, sweet banana variety',
      'characteristics': '• Small and slender\n• Thin skin\n• Very sweet flavor',
      'origin': 'Australia',
      'confidenceRange': [80, 90],
      'image': 'assets/lady_finger.png'
    },
    {
      'name': 'Blue Java',
      'description': 'Known as "ice cream banana" for its texture and flavor',
      'characteristics': '• Blue-green skin when unripe\n• Silvery-blue when ripe\n• Vanilla-like flavor',
      'origin': 'Southeast Asia',
      'confidenceRange': [70, 85],
      'image': 'assets/blue_java.png'
    }
  ];

  // API base URL (replace with your actual API URL)
  static const String _baseUrl = 'https://your-api.com';
  // Hardcoded userId (replace with dynamic value if available)
  static const String _userId = 'user123';

  Future<File?> _compressImage(File imageFile) async {
    try {
      img.Image? image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) return null;

      img.Image resizedImage = img.copyResize(image, width: 800);
      final directory = await getTemporaryDirectory();
      final String fileName = path.basename(imageFile.path);
      final File compressedFile = File('${directory.path}/$fileName');

      await compressedFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 70));
      return compressedFile;
    } catch (e) {
      print('Image compression error: $e');
      return null;
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission denied')),
          );
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          if (kIsWeb) {
            _imageUrl = image.path;
            _imageFile = image; // Store XFile for web
            _analysisResult = null;
            _varietyImage = null;
          } else {
            File imageFile = File(image.path);
            _compressImage(imageFile).then((compressedFile) {
              if (compressedFile != null) {
                setState(() {
                  _imageFile = compressedFile;
                  _imageUrl = null;
                  _analysisResult = null;
                  _varietyImage = null;
                });
              }
            });
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submitImage() async {
    if (_imageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _analysisResult = null;
      _varietyImage = null;
    });

    try {
      // Step 1: Upload image to /api/varieties/create
      String? imageId;
      if (kIsWeb) {
        final bytes = await (_imageFile as XFile).readAsBytes();
        imageId = await _uploadImage(bytes, _userId);
      } else {
        imageId = await _uploadImage(await _imageFile.readAsBytes(), _userId);
      }

      if (imageId == null) throw Exception('Image upload failed: No imageId returned');

      // Step 2: Analyze image with /api/varieties/analyze
      final analysisResult = await _analyzeImage(imageId);

      // Find the variety in the database based on API result
      final variety = _varietyDatabase.firstWhere(
            (v) => v['name'] == analysisResult['result'],
        orElse: () {
          print('Warning: Variety "${analysisResult['result']}" not found in database');
          return {
            'name': analysisResult['result'],
            'description': 'Variety not in local database',
            'characteristics': '• Contact support for more info',
            'origin': 'Unknown',
            'image': null,
          };
        },
      );

      setState(() {
        _isLoading = false;
        _varietyImage = variety['image'];
        _analysisResult = 'Variety: ${variety['name']} (Confidence: ${analysisResult['confidenceLevel']}%)\n\n'
            'Origin: ${variety['origin']}\n\n'
            'Description: ${variety['description']}\n\n'
            'Characteristics:\n${variety['characteristics']}\n\n'
            'Processing Time: ${analysisResult['processingTime']}ms\n'
            'Remaining Attempts: ${analysisResult['remainingAttempts']}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _uploadImage(List<int> imageBytes, String userId) async {
    final uri = Uri.parse('$_baseUrl/api/varieties/create');
    final request = http.MultipartRequest('POST', uri)
      ..fields['userId'] = userId // Add userId as a field
      ..files.add(http.MultipartFile.fromBytes('imageFile', imageBytes, filename: 'banana.jpg'));

    final response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = await response.stream.bytesToString();
      try {
        final json = jsonDecode(responseData);
        return json['imageId'] ?? json['id']; // Fallback to 'id' if 'imageId' is missing
      } catch (e) {
        throw Exception('Invalid JSON response from create: $e');
      }
    } else {
      throw Exception('Upload failed with status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> _analyzeImage(String imageId) async {
    final uri = Uri.parse('$_baseUrl/api/varieties/analyze');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'imageId': imageId}),
    );

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body);
        return {
          'result': json['result'] ?? 'Unknown',
          'confidenceLevel': json['confidenceLevel'] ?? 0.0,
          'processingTime': json['processingTime'] ?? 0,
          'secondaryFindings': json['secondaryFindings'] ?? '{}',
          'remainingAttempts': json['remainingAttempts'] ?? 0,
          'requiresSignup': json['requiresSignup'] ?? false,
        };
      } catch (e) {
        throw Exception('Invalid JSON response from analyze: $e');
      }
    } else {
      throw Exception('Analysis failed with status: ${response.statusCode}');
    }
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
      _imageUrl = null;
      _analysisResult = null;
      _varietyImage = null;
    });
  }

  Widget _buildImagePreview() {
    if (_imageFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network((_imageFile as XFile).path, fit: BoxFit.cover)
                : Image.file(_imageFile, fit: BoxFit.cover),
          ),
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
    } else if (_imageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _imageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text('Error loading image'));
              },
            ),
          ),
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
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera_back, size: 50, color: Colors.green),
          const SizedBox(height: 8),
          const Text(
            'Upload an image',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banana Variety Identification'),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        elevation: 0,
        titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Text(
                          'Upload Banana Image',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.25,
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
                                onPressed: () => _getImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Camera'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green[800],
                                  side: BorderSide(color: Colors.green[300]!),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  textStyle: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _getImage(ImageSource.gallery),
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Gallery'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green[800],
                                  side: BorderSide(color: Colors.green[300]!),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  textStyle: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            'Identify Variety',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Variety Results',
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
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Identification',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_varietyImage != null)
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: AssetImage(_varietyImage!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _analysisResult!,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
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
                children: const [
                  Text(
                    'Growing Tips',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Use well-draining soil', style: TextStyle(fontSize: 12)),
                  Text('• Full sun exposure', style: TextStyle(fontSize: 12)),
                  Text('• Regular watering', style: TextStyle(fontSize: 12)),
                  Text('• Protect from wind', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ] else
          const Text(
            'Upload an image to identify',
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
                Text('• Use clear images', style: TextStyle(fontSize: 12)),
                Text('• Show entire fruit/leaf', style: TextStyle(fontSize: 12)),
                Text('• Avoid blurry shots', style: TextStyle(fontSize: 12)),
                Text('• Highlight variety traits', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}