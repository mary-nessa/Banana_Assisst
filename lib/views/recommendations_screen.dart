import 'package:flutter/material.dart';
import 'dart:ui';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  int _selectedSection = 0;
  final ScrollController _scrollController = ScrollController();

  final List<String> _sectionTitles = [
    'Garden Setup & Planting',
    'Care & Maintenance',
    'Precautions',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Banana Farming Guide',
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
                    'https://images.unsplash.com/photo-1603833665858-e61d17a86224?ixlib=rb-1.2.1&auto=format&fit=crop&w=1950&q=80',
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
          SliverPersistentHeader(
            pinned: true,
            delegate: _SectionTabsDelegate(
              sections: _sectionTitles,
              selectedIndex: _selectedSection,
              onTabSelected: (index) {
                setState(() {
                  _selectedSection = index;
                });
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  if (_selectedSection == 0) _buildGardenSetupSection(),
                  if (_selectedSection == 1) _buildMaintenanceSection(),
                  if (_selectedSection == 2) _buildPrecautionsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGardenSetupSection() {
    final steps = [
      {
        'title': 'Site Selection',
        'content':
            'Choose a well-drained area with fertile soil. The site should receive adequate sunlight and be protected from strong winds.',
        'icon': Icons.landscape,
      },
      {
        'title': 'Soil Preparation',
        'content':
            'Clear the land, remove weeds, and dig holes 60x60x60cm. Mix topsoil with organic manure.',
        'icon': Icons.grass,
      },
      {
        'title': 'Planting Material Selection',
        'content':
            'Select healthy sword suckers or tissue culture plantlets from reputable sources.',
        'icon': Icons.eco,
      },
      {
        'title': 'Spacing',
        'content':
            'Plant bananas 3x3 meters apart for optimal growth and easy maintenance.',
        'icon': Icons.grid_4x4,
      },
      {
        'title': 'Planting Process',
        'content':
            'Place the sucker in the hole, cover with soil, and ensure proper orientation. Water immediately after planting.',
        'icon': Icons.agriculture,
      },
    ];

    return _buildSteppedSection(steps, Colors.green[100]!);
  }

  Widget _buildMaintenanceSection() {
    final stages = [
      {
        'title': 'Early Stage (0-3 months)',
        'content':
            'Regular watering, weed control, and monitoring for pests. Apply first round of fertilizer after 3 months.',
        'icon': Icons.water_drop,
      },
      {
        'title': 'Vegetative Stage (3-6 months)',
        'content':
            'Remove excess suckers, maintain only 3-4 per mat. Continue weeding and apply second fertilizer dose.',
        'icon': Icons.nature_people,
      },
      {
        'title': 'Flowering Stage (6-8 months)',
        'content':
            'Support plants with props if necessary. Remove male bud after last hand formation.',
        'icon': Icons.local_florist,
      },
      {
        'title': 'Fruit Development (8-12 months)',
        'content':
            'Regular bunch management, remove old leaves, maintain cleanliness around plants.',
        'icon': Icons.spa,
      },
      {
        'title': 'Harvesting Stage',
        'content':
            'Harvest when fruits are mature but still green. Cut the pseudostem at 2ft above ground.',
        'icon': Icons.agriculture,
      },
    ];

    return _buildSteppedSection(stages, Colors.green[50]!);
  }

  Widget _buildPrecautionsSection() {
    final precautions = [
      {
        'title': 'Disease Prevention',
        'content':
            'Use clean planting materials, maintain field hygiene, and implement regular disease monitoring.',
        'icon': Icons.health_and_safety,
      },
      {
        'title': 'Pest Management',
        'content':
            'Regular monitoring for pests, use of appropriate pesticides when necessary, maintain clean surroundings.',
        'icon': Icons.bug_report,
      },
      {
        'title': 'Water Management',
        'content':
            'Avoid waterlogging, ensure proper drainage, and maintain consistent soil moisture.',
        'icon': Icons.water,
      },
      {
        'title': 'Chemical Safety',
        'content':
            'Use protective gear when applying chemicals, follow recommended dosages, and observe withdrawal periods.',
        'icon': Icons.warning,
      },
      {
        'title': 'Environmental Protection',
        'content':
            'Practice sustainable farming methods, protect soil from erosion, and maintain biodiversity.',
        'icon': Icons.eco,
      },
    ];

    return _buildSteppedSection(precautions, Colors.green[50]!);
  }

  Widget _buildSteppedSection(List<Map<String, dynamic>> items, Color bgColor) {
    return Column(
      children:
          items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: 16.0),
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
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: ExpansionTile(
                    backgroundColor: Colors.transparent,
                    collapsedBackgroundColor: Colors.transparent,
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[700]!.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green[700]!.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.green[700]!.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green[700]!.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[900]!.withOpacity(0.8),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.green[700]!.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          item['content'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.green[900]!.withOpacity(0.7),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _SectionTabsDelegate extends SliverPersistentHeaderDelegate {
  final List<String> sections;
  final int selectedIndex;
  final Function(int) onTabSelected;

  _SectionTabsDelegate({
    required this.sections,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              sections.asMap().entries.map((entry) {
                final index = entry.key;
                final title = entry.value;
                final isSelected = index == selectedIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabSelected(index),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.0),
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.green[700] : Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.green[700],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 64.0;

  @override
  double get minExtent => 64.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
