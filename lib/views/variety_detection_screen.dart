import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bananaassist/mixins/image_analysis_mixin.dart';

class VarietyDetectionScreen extends StatefulWidget {
  const VarietyDetectionScreen({Key? key}) : super(key: key);

  @override
  State<VarietyDetectionScreen> createState() => _VarietyDetectionScreenState();
}

class _VarietyDetectionScreenState extends State<VarietyDetectionScreen>
    with ImageAnalysisMixin {
  String? _maturityLevel;

  @override
  String get apiEndpoint => '${dotenv.env['BACKEND_URL']}/api/varieties';

  // In VarietyDetectionScreen class
// Update the _analyzeImage method:

  Future<void> _analyzeImage() async {
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setLoading(true);
    setAnalysisResult(null);
    setState(() => _maturityLevel = null);

    try {
      final analysisResult = authToken != null
          ? await createWithAuth(imageFile)
          : await analyzeWithoutAuth(imageFile);

      setLoading(false);
      if (analysisResult.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(analysisResult['error']),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Safely handle secondaryFindings
      dynamic secondaryFindings = analysisResult['secondaryFindings'];
      if (secondaryFindings is! Map<String, dynamic>) {
        secondaryFindings = {'maturity': 'N/A', 'characteristics': ['N/A']};
      }
      final maturity = (secondaryFindings as Map<String, dynamic>?)?['maturity'] as String? ?? 'N/A';
      final characteristicsList = (secondaryFindings as Map<String, dynamic>?)?['characteristics'] as List<dynamic>? ?? ['N/A'];
      final characteristics = characteristicsList.isNotEmpty ? characteristicsList.join(', ') : 'N/A';

      setState(() => _maturityLevel = maturity);

      setAnalysisResult(
        '''
Variety Name: ${analysisResult['varietyName'] ?? 'Unknown'}
Confidence Level: ${analysisResult['confidenceLevel'] ?? 'N/A'}%
Processing Time: ${analysisResult['processingTime'] ?? 'N/A'}ms
Maturity: $maturity
Characteristics: $characteristics
${authToken == null ? 'Remaining Attempts: ${analysisResult['remainingAttempts'] ?? 'N/A'}\n' : ''}
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

  Color _getMaturityColor(String? maturity) {
    if (maturity == null) return Colors.grey;
    switch (maturity.toLowerCase()) {
      case 'ripe':
        return Colors.green;
      case 'overripe':
        return Colors.red[800]!;
      case 'unripe':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
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
                          'Upload Banana Image',
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
                                  foregroundColor: Colors.green[800],
                                  side: BorderSide(color: Colors.green[300]!),
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
                                  foregroundColor: Colors.green[800],
                                  side: BorderSide(color: Colors.green[300]!),
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
                            backgroundColor: Colors.green[700],
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                              : const Text(
                            'Identify Variety',
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
                          'Variety Results',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        buildAttemptsCounter(),
                        if (analysisResult != null) ...[
                          const SizedBox(height: 8),
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
                                        color: _getMaturityColor(_maturityLevel),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Variety Results',
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
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                  '• Show the entire banana',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '• Include both skin and flesh if possible',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '• Avoid blurry or dark photos',
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