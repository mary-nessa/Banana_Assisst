import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bananaassist/utils/secure_storage.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;
  String _category = 'GENERAL';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _authToken;

  // Category icons mapping to match web version
  final Map<String, IconData> _categoryIcons = {
    'GENERAL': Icons.thumb_up,
    'DISEASE_DETECTION': Icons.bug_report,
    'VARIETY_IDENTIFICATION':
        Icons.local_florist, // Replaced Icons.leaf with Icons.local_florist
    'CHATBOT': Icons.smart_toy,
  };

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    _authToken = await SecureStorage.getToken();
    setState(() {});
  }

  Future<bool> _submitFeedback({
    required int rating,
    required String comment,
    required String category,
  }) async {
    try {
      final url = '${dotenv.env['BACKEND_URL']}/api/feedback';
      final headers = {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };
      final body = jsonEncode({
        'rating': rating,
        'comment': comment,
        'category': category,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _successMessage = 'Feedback submitted successfully!';
          _errorMessage = null;
          _rating = 0;
          _commentController.clear();
          _category = 'GENERAL';
        });
        return true;
      } else if (response.statusCode == 401) {
        // Redirect to sign-in if unauthorized
        Navigator.pushReplacementNamed(context, '/auth/signin');
        return false;
      } else if (response.statusCode == 400) {
        setState(() {
          _errorMessage = 'Invalid input';
          _successMessage = null;
        });
        return false;
      } else {
        setState(() {
          _errorMessage = 'Failed to submit feedback';
          _successMessage = null;
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error submitting feedback: ${e.toString()}';
        _successMessage = null;
      });
      return false;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600, // Limit maximum width for larger screens
              ),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.message,
                            color: Colors.green[600],
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Share Your Feedback',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We value your input to help us improve',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 24),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[800],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Success Message
                      if (_successMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(color: Colors.green[200]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[800],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_errorMessage != null || _successMessage != null)
                        const SizedBox(height: 16),

                      // Rating
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[500], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Rating',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Rating stars with overflow handling
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rating = index + 1;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      _rating > index
                                          ? Colors.amber[100]
                                          : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    if (_rating > index)
                                      BoxShadow(
                                        color: Colors.grey[300]!,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.star,
                                  color:
                                      _rating > index
                                          ? Colors.amber[600]
                                          : Colors.grey[400],
                                  size: isSmallScreen ? 28 : 32,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _rating == 0
                            ? 'Select a rating'
                            : _rating == 1
                            ? 'Poor'
                            : _rating == 2
                            ? 'Fair'
                            : _rating == 3
                            ? 'Good'
                            : _rating == 4
                            ? 'Very Good'
                            : 'Excellent',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              _categoryIcons[_category],
                              color: Colors.grey[600],
                              size: 20,
                            ),
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'GENERAL',
                            child: Text('General Feedback'),
                          ),
                          DropdownMenuItem(
                            value: 'DISEASE_DETECTION',
                            child: Text('Disease Detection'),
                          ),
                          DropdownMenuItem(
                            value: 'VARIETY_IDENTIFICATION',
                            child: Text('Variety Identification'),
                          ),
                          DropdownMenuItem(
                            value: 'CHATBOT',
                            child: Text('Chatbot'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _category = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Comment
                      Row(
                        children: [
                          Icon(
                            Icons.message,
                            color: Colors.blue[500],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Feedback',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _commentController,
                        maxLines: isSmallScreen ? 4 : 6,
                        minLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Tell us what you think... What worked well? What can we improve?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button with improved layout
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: _isLoading || _rating == 0 ? 0 : 4,
                            backgroundColor:
                                _isLoading || _rating == 0
                                    ? Colors.grey[400]
                                    : Colors.green[600],
                            foregroundColor: Colors.white,
                            shadowColor: Colors.grey[400],
                          ),
                          onPressed:
                              _isLoading || _rating == 0
                                  ? null
                                  : () async {
                                    setState(() {
                                      _isLoading = true;
                                      _errorMessage = null;
                                      _successMessage = null;
                                    });

                                    await _submitFeedback(
                                      rating: _rating,
                                      comment: _commentController.text,
                                      category: _category,
                                    );

                                    setState(() {
                                      _isLoading = false;
                                    });
                                  },
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Submit Feedback',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
  }
}
