import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:bananaassist/views/auth/registration_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bananaassist/utils/secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart'; // Added import for device_info_plus

mixin ImageAnalysisMixin<T extends StatefulWidget> on State<T> {
  final ImagePicker _picker = ImagePicker();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin(); // Instantiate DeviceInfoPlugin
  XFile? _imageFile;
  bool _isLoading = false;
  String? _analysisResult;
  String? _authToken;
  int _remainingAttempts = 3;
  bool _requiresSignup = false;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
    _loadAttempts();
  }

  Future<void> _loadAuthToken() async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      setState(() => _authToken = token);
    }
  }

  Future<void> _loadAttempts() async {
    if (_authToken != null) {
      setState(() {
        _remainingAttempts = 0;
        _requiresSignup = false;
      });
      return;
    }

    int attempts = await SecureStorage.getGuestAttempts() ?? 0;
    setState(() {
      _remainingAttempts = 3 - attempts;
      _requiresSignup = attempts >= 3;
    });
  }

  bool get isLoading => _isLoading;
  String? get analysisResult => _analysisResult;
  bool get requiresSignup => _requiresSignup;
  int get remainingAttempts => _remainingAttempts;
  String? get authToken => _authToken;
  XFile? get imageFile => _imageFile;

  void setLoading(bool value) {
    setState(() => _isLoading = value);
  }

  void setAnalysisResult(String? value) {
    setState(() => _analysisResult = value);
  }

  void clearAnalysisState() {
    setState(() {
      _isLoading = false;
      _analysisResult = null;
    });
  }

  Future<void> getImage(ImageSource source) async {
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
      );

      if (image != null) {
        setState(() {
          _imageFile = image;
          _analysisResult = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper method to get Android version
  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo; // Use the instance
      return androidInfo.version.sdkInt ?? 0;
    }
    return 0;
  }

  Future<Map<String, dynamic>> createWithAuth(XFile? imageFile) async {
    if (_authToken == null) {
      throw Exception('No auth token available');
    }
    if (imageFile == null) {
      throw Exception('No image file provided');
    }

    final uri = Uri.parse('$apiEndpoint/create');
    final userId = await SecureStorage.getUserId();
    if (userId == null) {
      throw Exception('No userId available');
    }

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'imageFile',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      )
      ..fields['userId'] = userId
      ..headers['Authorization'] = 'Bearer $_authToken';

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      try {
        return jsonDecode(responseData) as Map<String, dynamic>;
      } catch (e) {
        throw Exception('Invalid JSON response: $e - Raw data: $responseData');
      }
    } else if (response.statusCode == 401) {
      setState(() => _authToken = null);
      await SecureStorage.deleteToken();
      throw Exception('Authentication required');
    } else {
      throw Exception('Upload failed with status: ${response.statusCode} - $responseData');
    }
  }

  Future<Map<String, dynamic>> analyzeWithoutAuth(XFile? imageFile) async {
    if (imageFile == null) {
      throw Exception('No image file provided');
    }

    final uri = Uri.parse('$apiEndpoint/analyze');
    final deviceId = await getDeviceId();

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'imageFile',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      )
      ..fields['deviceId'] = deviceId;

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      try {
        final result = jsonDecode(responseData) as Map<String, dynamic>;

        int attempts = await SecureStorage.getGuestAttempts() ?? 0;
        attempts += 1;
        await SecureStorage.storeGuestAttempts(attempts);
        setState(() {
          _remainingAttempts = 3 - attempts;
          _requiresSignup = attempts >= 3;
        });

        if (_requiresSignup) {
          showSignupPrompt();
          return {
            'error': 'Trial limit reached',
            'requiresSignup': true,
            'remainingAttempts': 0,
          };
        }
        return result;
      } catch (e) {
        throw Exception('Invalid JSON response: $e - Raw data: $responseData');
      }
    } else {
      throw Exception('Analyze failed with status: ${response.statusCode} - $responseData');
    }
  }

  Future<String> getDeviceId() async {
    String? deviceId = await SecureStorage.getDeviceId();
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await SecureStorage.storeDeviceId(deviceId);
    }
    return deviceId;
  }

  void showSignupPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Free Trial Ended'),
          content: const Text(
            'You have reached the limit of free attempts. Sign up to continue using all features!',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Sign Up'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegistrationScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void clearImage() {
    setState(() {
      _imageFile = null;
      _analysisResult = null;
    });
  }

  Widget buildImagePreview() {
    if (_imageFile == null) {
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
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FutureBuilder<Uint8List>(
            future: _imageFile!.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading image'));
              }
              return kIsWeb
                  ? Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
              )
                  : Image.file(
                File(_imageFile!.path),
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: clearImage,
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget buildAttemptsCounter() {
    if (_authToken != null || _requiresSignup) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: Colors.green[700]),
          const SizedBox(width: 8),
          Text(
            'Remaining free attempts: $_remainingAttempts',
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String get apiEndpoint;
}