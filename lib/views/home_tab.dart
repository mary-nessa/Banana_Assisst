import 'package:flutter/material.dart';
import 'dart:ui';
import 'disease_detection_screen.dart';
import 'feedback_screen.dart';
import 'variety_detection_screen.dart';
import 'bananaPlantingScreen.dart'; // Ensure this points to the updated file
import 'recommendations_screen.dart';
import 'package:bananaassist/utils/secure_storage.dart';

class HomeTab extends StatefulWidget {
  final String? userName;
  final VoidCallback? onLogout;

  const HomeTab({Key? key, this.userName, this.onLogout}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<bool> _isHovered = List.generate(4, (_) => false);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    if (widget.userName != null) {
      return await SecureStorage.getToken(); // Adjust this logic
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FeedbackScreen()),
          );
        },
        backgroundColor: Colors.purple[700],
        child: const Icon(Icons.feedback, color: Colors.white),
        tooltip: 'Share Feedback',
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundPatternPainter(
                color: Colors.green[700]!.withOpacity(0.03),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildFeatureGrid(context),
                    const SizedBox(height: 20),
                    _buildAppHighlights(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green[700]!.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green[700]!.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green[700]!.withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.eco, size: 28, color: Colors.green[700]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.green[700]!,
                              Colors.green[500]!,
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'BANANA ASSIST',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.userName != null
                              ? 'Welcome back, ${widget.userName}!'
                              : 'Welcome!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildFeatureStatus(),
            ],
          ),
        ),
        Positioned(
          right: -10,
          top: -10,
          child: CustomPaint(
            painter: LeafPatternPainter(color: Colors.green[100]!),
            size: const Size(60, 60),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureStatus() {
    return Row(
      children: [
        _buildStatusIndicator(
          icon: Icons.check_circle_outline,
          label: 'AI Ready',
          color: Colors.green[700]!,
        ),
        const SizedBox(width: 16),
        _buildStatusIndicator(
          icon: Icons.speed_outlined,
          label: 'Fast Analysis',
          color: Colors.orange[700]!,
        ),
      ],
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {
        'icon': Icons.medical_services,
        'title': 'Disease Detection',
        'screen': const DiseaseDetectionScreen(),
        'gradient': [Colors.red[400]!, Colors.red[700]!],
      },
      {
        'icon': Icons.nature,
        'title': 'Variety Identify',
        'screen': const VarietyDetectionScreen(),
        'gradient': [Colors.green[400]!, Colors.green[700]!],
      },
      {
        'icon': Icons.local_florist,
        'title': 'Banana Planting',
        'screen': FutureBuilder<String?>(
          future: _getAuthToken(),
          builder: (context, snapshot) {
            return BananaPlantingScreen(
              key: UniqueKey(),
              authToken: snapshot.data,
            );
          },
        ),
        'gradient': [Colors.orange[400]!, Colors.orange[700]!],
      },
      {
        'icon': Icons.thumb_up,
        'title': 'Recommendations',
        'screen': const RecommendationsScreen(),
        'gradient': [Colors.blue[400]!, Colors.blue[700]!],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double delay = index * 0.2;
            final double animationValue = (_controller.value - delay).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, (1 - animationValue) * 50),
              child: Opacity(
                opacity: animationValue,
                child: _buildFeatureCard(
                  context,
                  icon: features[index]['icon'] as IconData,
                  title: features[index]['title'] as String,
                  gradientColors: features[index]['gradient'] as List<Color>,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => features[index]['screen'] is Widget
                            ? features[index]['screen'] as Widget
                            : (features[index]['screen'] as FutureBuilder<String?>).builder(context, AsyncSnapshot<String?>.withData(ConnectionState.done, null)),
                      ),
                    );
                  },
                  index: index,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required List<Color> gradientColors,
        required VoidCallback onTap,
        required int index,
      }) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered[index] = true),
      onExit: (_) => setState(() => _isHovered[index] = false),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween<double>(begin: 0, end: _isHovered[index] ? 1 : 0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1 + (value * 0.02),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: gradientColors[1].withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[1].withOpacity(0.1),
                    offset: Offset(0, 2 + (value * 2)),
                    blurRadius: 4 + (value * 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      if (_isHovered[index])
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: gradientColors[1].withOpacity(0.3),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 200),
                              tween: Tween<double>(
                                begin: 0,
                                end: _isHovered[index] ? 1 : 0,
                              ),
                              builder: (context, value, child) {
                                return Transform.rotate(
                                  angle: value * 0.1,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: gradientColors[1].withOpacity(0.2),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: gradientColors[1].withOpacity(value * 0.1),
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 24,
                                      color: Color.lerp(
                                        gradientColors[1],
                                        Colors.white,
                                        value * 0.5,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to explore',
                              style: TextStyle(
                                fontSize: 10,
                                color: gradientColors[1].withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppHighlights() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[700]!.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: Colors.green[700], size: 16),
              const SizedBox(width: 8),
              Text(
                'Powered by Advanced AI',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange[700]!.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '15+',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Varieties',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[700]!.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Text(
                      '99%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Accuracy',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BackgroundPatternPainter extends CustomPainter {
  final Color color;

  BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(BackgroundPatternPainter oldDelegate) => false;
}

class LeafPatternPainter extends CustomPainter {
  final Color color;

  LeafPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.5,
        size.width * 0.8,
        size.height * 0.2,
      )
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.4,
        size.width * 0.3,
        size.height * 0.7,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(LeafPatternPainter oldDelegate) => false;
}