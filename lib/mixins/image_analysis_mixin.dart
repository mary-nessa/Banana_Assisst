import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:bananaassist/views/auth/registration_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bananaassist/utils/secure_storage.dart';

mixin ImageAnalysisMixin<T extends StatefulWidget> on State<T> {
  final ImagePicker _picker = ImagePicker();
  dynamic _imageFile;
  bool _isLoading = false;
  String? _analysisResult;
  String? _authToken;
  int _remainingAttempts = 3;
  bool _requiresSignup = false;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      setState(() => _authToken = token);
    }
  }

  // Getter methods
  bool get isLoading => _isLoading;
  String? get analysisResult => _analysisResult;
  bool get requiresSignup => _requiresSignup;
  int get remainingAttempts => _remainingAttempts;
  String? get authToken => _authToken;
  dynamic get imageFile => _imageFile;

  // State management methods
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

  Future<Map<String, dynamic>> createWithAuth(XFile imageFile) async {
    if (_authToken == null) {
      throw Exception('No auth token available');
    }
    final uri = Uri.parse('$apiEndpoint/create');
    final userId = await SecureStorage.getUserId();
    if (userId == null) {
      throw Exception('No userId available');
    }

    final request =
        http.MultipartRequest('POST', uri)
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
        return jsonDecode(responseData);
      } catch (e) {
        throw Exception('Invalid JSON response: $e');
      }
    } else if (response.statusCode == 401) {
      setState(() => _authToken = null);
      await SecureStorage.deleteToken();
      throw Exception('Authentication required');
    } else {
      throw Exception('Upload failed with status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> analyzeWithoutAuth(XFile imageFile) async {
    final uri = Uri.parse('$apiEndpoint/analyze');
    final deviceId = await getDeviceId();

    var request =
        http.MultipartRequest('POST', uri)
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
        final json = jsonDecode(responseData);
        final requiresSignup = json['requiresSignup'] ?? false;
        final remainingAttempts = json['remainingAttempts'] ?? 0;

        setState(() {
          _remainingAttempts = remainingAttempts;
          _requiresSignup = requiresSignup;
        });

        if (requiresSignup) {
          showSignupPrompt();
        }

        return json;
      } catch (e) {
        throw Exception('Invalid JSON response: $e');
      }
    } else {
      throw Exception('Analysis failed with status: ${response.statusCode}');
    }
  }

  Future<String> getDeviceId() async {
    return 'device-${DateTime.now().millisecondsSinceEpoch}';
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
          child:
              kIsWeb
                  ? Image.network((_imageFile as XFile).path, fit: BoxFit.cover)
                  : Image.file(
                    File((_imageFile as XFile).path),
                    fit: BoxFit.cover,
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
    if (_requiresSignup) return const SizedBox.shrink();

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

  // Abstract method to be implemented by child classes
  String get apiEndpoint;
}
