import 'package:flutter/material.dart';
import 'disease_detection_screen.dart';
import 'variety_detection_screen.dart';
import 'pesticides_screen.dart';
import 'recommendations_screen.dart';

class HomeTab extends StatelessWidget {
  final String? userName;
  final VoidCallback? onLogout;

  const HomeTab({Key? key, this.userName, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header (optional)
                _buildHeader(),

                const SizedBox(height: 30),

                // Disease Detection
                _buildFeatureCard(
                  context,
                  icon: Icons.medical_services,
                  title: 'Disease Detection',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiseaseDetectionScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Variety Identification
                _buildFeatureCard(
                  context,
                  icon: Icons.nature,
                  title: 'Variety Identification',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VarietyDetectionScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Pesticides & Recommendations side by side
                Row(
                  children: [
                    // Pesticides
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        icon: Icons.bug_report,
                        title: 'Pesticides',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PesticidesScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Recommendations
                    Expanded(
                      child: _buildFeatureCard(
                        context,
                        icon: Icons.thumb_up,
                        title: 'Recommendations',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecommendationsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Logout Button (optional)
                if (onLogout != null) ...[
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: onLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.logout),
                        SizedBox(width: 10),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Example header: add your own branding or remove entirely if not needed
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Uncomment or customize these lines if you want a header
              // Text(
              //   'BANANA ASSIST',
              //   style: TextStyle(
              //     fontSize: 32,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.green[800],
              //   ),
              // ),
              // const SizedBox(height: 10),
              // Text(
              //   userName != null ? 'Welcome, $userName!' : 'Welcome!',
              //   style: TextStyle(
              //     fontSize: 20,
              //     color: Colors.green[800],
              //     fontWeight: FontWeight.w300,
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return Container(
      // Use available width from parent (especially in a Row)
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 0), // Adjust if needed
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(width: 20),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                    overflow: TextOverflow.ellipsis,
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
