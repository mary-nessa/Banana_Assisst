import 'package:flutter/material.dart';
import 'dart:ui';

class PesticidesScreen extends StatelessWidget {
  const PesticidesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Disease Control Guide',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1591955506264-3f5a6834570a?ixlib=rb-1.2.1&auto=format&fit=crop&w=1950&q=80',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildDiseaseCard(
                  'Banana Bacterial Wilt (BBW)',
                  'A bacterial disease causing premature ripening and wilting of plants.',
                  [
                    {
                      'name': 'Copper Oxychloride',
                      'dosage': '50-60g/20L of water',
                      'frequency': 'Apply every 14 days when symptoms appear'
                    },
                    {
                      'name': 'Agricultural Streptomycin',
                      'dosage': '20g/20L of water',
                      'frequency': 'Weekly application until symptoms subside'
                    }
                  ],
                  Icons.coronavirus_outlined,
                ),
                _buildDiseaseCard(
                  'Black Sigatoka',
                  'A fungal disease causing dark leaf spots and reduced yields.',
                  [
                    {
                      'name': 'Mancozeb',
                      'dosage': '40-50g/20L of water',
                      'frequency': 'Apply every 14 days preventively'
                    },
                    {
                      'name': 'Propiconazole',
                      'dosage': '20ml/20L of water',
                      'frequency': 'Apply every 21 days during wet seasons'
                    }
                  ],
                  Icons.spa_outlined,
                ),
                _buildDiseaseCard(
                  'Panama Disease',
                  'A soil-borne fungal disease affecting the root system.',
                  [
                    {
                      'name': 'Carbendazim',
                      'dosage': '30ml/20L of water',
                      'frequency': 'Soil drench every 3 months'
                    },
                    {
                      'name': 'Benomyl',
                      'dosage': '25g/20L of water',
                      'frequency': 'Apply as soil treatment quarterly'
                    }
                  ],
                  Icons.landslide_outlined,
                ),
                _buildDiseaseCard(
                  'Banana Weevil Borer',
                  'Common pest that attacks the corm and pseudostem.',
                  [
                    {
                      'name': 'Chlorpyrifos',
                      'dosage': '40ml/20L of water',
                      'frequency': 'Apply around base every 3 months'
                    },
                    {
                      'name': 'Imidacloprid',
                      'dosage': '20ml/20L of water',
                      'frequency': 'Soil application every 4 months'
                    }
                  ],
                  Icons.bug_report_outlined,
                ),
                const SizedBox(height: 16),
                _buildSafetyNote(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(String title, String description, List<Map<String, String>> treatments, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green[700]!.withOpacity(0.3),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[700]!.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green[700]!.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green[900]!.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              description,
              style: TextStyle(
                color: Colors.green[900]!.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.green[700]!.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended Treatments:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...treatments.map((treatment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ${treatment['name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dosage: ${treatment['dosage']}',
                                  style: TextStyle(
                                    color: Colors.green[900]!.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Frequency: ${treatment['frequency']}',
                                  style: TextStyle(
                                    color: Colors.green[900]!.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange[50],
        border: Border.all(
          color: Colors.orange[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[700],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Safety First!',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Always wear protective gear when handling pesticides. Read and follow the manufacturer\'s instructions carefully. Keep pesticides away from children and store in a cool, dry place.',
            style: TextStyle(
              color: Colors.orange[900],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
