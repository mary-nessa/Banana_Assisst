import 'package:flutter/material.dart';
import 'package:bananaassist/views/auth/login_screen.dart';
import 'home_screen.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1B5E20),
              const Color(0xFFFBC02D),
            ], // Deep green to Ugandan yellow
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: BackgroundPainter())),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildWelcomeSection(),
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildHowItWorksCard(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildModernButton(
                    text: 'Explore',
                    color: const Color(0xFFB71C1C),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    },
                  ),
                  _buildModernButton(
                    text: 'Sign In',
                    color: Colors.white,
                    textColor: const Color(0xFF1B5E20),
                    isOutlined: true,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Colors.white, Color(0xFFFBC02D)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Center(
              child: Icon(Icons.eco, size: 90, color: const Color(0xFF1B5E20)),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Banana_Assist',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  blurRadius: 15,
                  color: Colors.black38,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Grow healthy bananas(Matooke) in Uganda',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  'How It Works',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFeatureBullet(
              'Scan your matooke for Bacterial Wilt or Black Sigatoka',
            ),
            _buildFeatureBullet(
              'Learn about varieties like Mbidde, Ndizi, and Gonja',
            ),
            _buildFeatureBullet('Get alerts for disease risks in your area'),
            _buildFeatureBullet(
              'Find best practices for Ugandan soils and weather',
            ),
            _buildFeatureBullet('Connect with local extension officers'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: const Color(0xFFFBC02D), size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.95),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton({
    required String text,
    required Color color,
    Color textColor = Colors.white,
    bool isOutlined = false,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient:
              isOutlined
                  ? null
                  : LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          color: isOutlined ? Colors.transparent : null,
          border: isOutlined ? Border.all(color: color, width: 2) : null,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isOutlined ? color : textColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Subtle banana bunch pattern
    paint.color = Colors.white.withOpacity(0.1);
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.3),
      size.width * 0.25,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      size.width * 0.2,
      paint,
    );

    // Matooke leaf-inspired shape
    final Paint leafPaint =
        Paint()
          ..color = const Color(0xFF1B5E20).withOpacity(0.3)
          ..style = PaintingStyle.fill;

    final Path leafPath =
        Path()
          ..moveTo(size.width * 0.15, size.height * 0.75)
          ..quadraticBezierTo(
            size.width * 0.25,
            size.height * 0.55,
            size.width * 0.4,
            size.height * 0.65,
          )
          ..quadraticBezierTo(
            size.width * 0.3,
            size.height * 0.8,
            size.width * 0.15,
            size.height * 0.75,
          );
    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
