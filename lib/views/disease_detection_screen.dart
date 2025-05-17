import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bananaassist/mixins/image_analysis_mixin.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({Key? key}) : super(key: key);

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen>
    with ImageAnalysisMixin {
  String? _diseaseLevel;

  @override
  String get apiEndpoint => '${dotenv.env['BACKEND_URL']}/api/diagnoses';

  // In DiseaseDetectionScreen class
// Update the _analyzeImage method:

  Future<void> _analyzeImage() async {
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image first')),
      );
      return;
    }

    setLoading(true);
    setAnalysisResult(null);
    setState(() => _diseaseLevel = null);

    try {
      final analysisResult = authToken != null
          ? await createWithAuth(imageFile)
          : await analyzeWithoutAuth(imageFile);

      setLoading(false);

      // Safely handle secondaryFindings
      dynamic secondaryFindings = analysisResult['secondaryFindings'];
      if (secondaryFindings is! Map<String, dynamic>) {
        secondaryFindings = {'severity': 'N/A', 'affectedArea': 'N/A'};
      }
      final severity = (secondaryFindings as Map<String, dynamic>?)?['severity'] as String? ?? 'N/A';
      final affectedArea = (secondaryFindings as Map<String, dynamic>?)?['affectedArea'] as String? ?? 'N/A';

      setState(() => _diseaseLevel = severity);

      setAnalysisResult(
        '''
Disease Name: ${analysisResult['diseaseName'] ?? 'Unknown'}
Confidence Level: ${analysisResult['confidenceLevel'] ?? 'N/A'}%
Processing Time: ${analysisResult['processingTime'] ?? 'N/A'}ms
Severity: $severity
Affected Area: $affectedArea
''',
      );
    } catch (e) {
      setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getDiseaseColor(String? diseaseName) {
    if (diseaseName == null) return Colors.grey;
    switch (diseaseName.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'high':
      case 'critical':
        return Colors.red[800]!;
      case 'moderate':
        return Colors.orange[800]!;
      case 'low':
      case 'mild':
        return Colors.amber[800]!;
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
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
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
                          'Upload Banana Leaf Image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
                          child: buildImagePreview(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => getImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt, size: 18),
                                label: const Text('Camera'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  textStyle: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => getImage(ImageSource.gallery),
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Gallery'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  textStyle: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: isLoading ? null : _analyzeImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : const Text(
                            'Analyze Image',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
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
                          'Diagnosis Results',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        buildAttemptsCounter(),
                        if (analysisResult != null) ...[
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
                                        color: _getDiseaseColor(_diseaseLevel),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Diagnosis Results',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    analysisResult!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
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
                                  'Tips for Better Results',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '• Use clear, well-lit images',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '• Focus on affected areas',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '• Include both sides of leaves',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '• Avoid shadows and glare',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
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
}