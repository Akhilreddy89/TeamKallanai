import 'package:flutter/material.dart';
import '../controllers/rainwater_controller.dart';
import '../models/user_input.dart';
import 'dart:math' as math;

class OutputPage extends StatefulWidget {
  final UserInput userInput;

  const OutputPage({super.key, required this.userInput});

  @override
  State<OutputPage> createState() => _OutputPageState();
}

class _OutputPageState extends State<OutputPage> with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedWaterRipple() {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(100, 100),
          painter: WaterRipplePainter(_rippleController.value),
        );
      },
    );
  }

  Widget _buildWaterMeterIndicator(double percentage, {Color? accent}) {
    final Color base = accent ?? Colors.blue.shade600;
    final Color track = base.withOpacity(0.15);
    final Color valueColor = base;

    return Container(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 170,
            height: 170,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 12,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation<Color>(valueColor),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water_drop, color: base, size: 30),
              Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: base,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledMeter(double percentage, String label, {Color? accent}) {
    final Color base = accent ?? Colors.blue.shade800;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWaterMeterIndicator(percentage, accent: base),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: base,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({
    required String title,
    required Widget content,
    required IconData icon,
    Color? accentColor,
  }) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 50),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(25),
                shadowColor: (accentColor ?? Colors.blue).withOpacity(0.3),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
                    ),
                    border: Border.all(
                      color: (accentColor ?? Colors.blue).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (accentColor ?? Colors.blue).withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                icon,
                                color: accentColor ?? Colors.blue.shade600,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        content,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.blue.shade600),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFeasibilityColor(String feasibility) {
    switch (feasibility) {
      case 'Highly Feasible':
        return Colors.green.shade600;
      case 'Feasible':
        return Colors.blue.shade600;
      default:
        return Colors.orange.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = RainwaterController.calculateRainwaterHarvesting(
      widget.userInput,
    );
    final locationData = results['locationData'];
    final userInputs = results['userInputs'];
    final calculations = results['calculations'];
    final feasibilityDecision = results['feasibilityDecision'];
    final tankSizing = results['tankSizing'];
    final arSizing = results['arSizing'];
    final costBenefit = results['costBenefit'];
    final personalization = results['personalization'];
    final subsidies = results['subsidies'];

    // Calculate efficiency percentage for visualization
    final double efficiencyPercentage = math.min(
      (calculations['harvestableWaterLiters'] /
              calculations['annualDemandLiters']) *
          100,
      100,
    );

    // Feasibility scores
    final double rtrwhScore = efficiencyPercentage;
    final double arScore =
        (() {
          final bool required = (arSizing['required'] == true);
          final double infiltration =
              (arSizing['infiltrationRate'] is num)
                  ? (arSizing['infiltrationRate'] as num).toDouble()
                  : 2.0;
          final bool openSpace =
              (feasibilityDecision['openSpaceAvailable'] == true);
          final bool groundwaterFalling =
              (feasibilityDecision['groundwaterFalling'] == true);
          double score = required ? 60.0 : 30.0;
          score += (math.min(infiltration, 10.0) / 10.0) * 20.0;
          if (openSpace) score += 10.0;
          if (groundwaterFalling) score += 10.0;
          return math.max(0.0, math.min(score, 100.0));
        })();

    // Display feasibility/system type based on scores
    final Map<String, String> displayFeasibility =
        (() {
          if (rtrwhScore >= 75 && arScore >= 75) {
            return {
              'systemType': 'Hybrid (Tank + AR)',
              'feasibility': 'Highly Feasible',
            };
          }
          if (rtrwhScore >= arScore) {
            return {
              'systemType': 'Storage Tank (RTRWH)',
              'feasibility':
                  rtrwhScore >= 75 ? 'Feasible' : 'Moderately Feasible',
            };
          } else {
            return {
              'systemType': 'Artificial Recharge (AR)',
              'feasibility': arScore >= 75 ? 'Feasible' : 'Moderately Feasible',
            };
          }
        })();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.cyan.shade50,
              Colors.blue.shade50,
              Colors.teal.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Animated Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.cyan.shade500],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              children: [
                                _buildAnimatedWaterRipple(),
                                const SizedBox(height: 8),
                                const Text(
                                  'Rainwater Analysis Report',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Sustainable water solutions await',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Summary Card with Water Meter
                      _buildGlassCard(
                        title: 'Report for ${widget.userInput.name}',
                        icon: Icons.person,
                        accentColor: Colors.indigo.shade600,
                        content: Column(
                          children: [
                            const SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLabeledMeter(
                                  rtrwhScore,
                                  'RTRWH',
                                  accent: Colors.indigo,
                                ),
                                const SizedBox(width: 20),
                                _buildLabeledMeter(
                                  arScore,
                                  'AR',
                                  accent: Colors.teal,
                                ),
                              ],
                            ),

                            const SizedBox(height: 50),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Analysis for a ${widget.userInput.houseType.toLowerCase()} in ${widget.userInput.location}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${userInputs['dwellers']} people • '
                                        '${userInputs['roofAreaSqM'].toStringAsFixed(1)} sq m roof • '
                                        '${userInputs['openSpaceAreaSqM'].toStringAsFixed(1)} sq m open space',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Feasibility Decision Card
                      _buildGlassCard(
                        title: 'Feasibility Assessment',
                        icon: Icons.check_circle_outline,
                        accentColor: _getFeasibilityColor(
                          displayFeasibility['feasibility']!,
                        ),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getFeasibilityColor(
                                  displayFeasibility['feasibility']!,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getFeasibilityColor(
                                    displayFeasibility['feasibility']!,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    displayFeasibility['feasibility'] ==
                                            'Highly Feasible'
                                        ? Icons.sentiment_very_satisfied
                                        : displayFeasibility['feasibility'] ==
                                            'Feasible'
                                        ? Icons.sentiment_satisfied
                                        : Icons.sentiment_neutral,
                                    color: _getFeasibilityColor(
                                      displayFeasibility['feasibility']!,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Status: ${displayFeasibility['feasibility']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getFeasibilityColor(
                                        displayFeasibility['feasibility']!,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'System Type: ${displayFeasibility['systemType']}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              feasibilityDecision['reasoning'],
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Water Calculations Card
                      _buildGlassCard(
                        title: 'Water Calculations',
                        icon: Icons.opacity,
                        accentColor: Colors.cyan.shade600,
                        content: Column(
                          children: [
                            _buildDataRow(
                              'Roof Area',
                              '${userInputs['roofAreaSqM'].toStringAsFixed(1)} sq m',
                              icon: Icons.roofing,
                            ),
                            _buildDataRow(
                              'Annual Rainfall',
                              '${locationData.annualRainfall} mm',
                              icon: Icons.cloud_queue,
                            ),
                            _buildDataRow(
                              'Harvestable Water',
                              '${calculations['harvestableWaterLiters'].toStringAsFixed(0)} liters/year',
                              icon: Icons.water_drop,
                            ),
                            _buildDataRow(
                              'Annual Demand',
                              '${calculations['annualDemandLiters'].toStringAsFixed(0)} liters/year',
                              icon: Icons.people,
                            ),
                            _buildDataRow(
                              'Excess Water',
                              '${calculations['excessWater'].toStringAsFixed(0)} liters/year',
                              icon: Icons.trending_up,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.cyan.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.cyan.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.cyan.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Formula: Roof Area × Rainfall × Runoff Coefficient (0.8)',
                                      style: TextStyle(
                                        color: Colors.cyan.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tank Sizing Card
                      _buildGlassCard(
                        title: 'Storage Tank Design',
                        icon: Icons.storage,
                        accentColor: Colors.blue.shade600,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDataRow(
                              'Recommended Volume',
                              '${tankSizing['volumeLiters'].toStringAsFixed(0)} liters',
                              icon: Icons.volume_up,
                            ),
                            _buildDataRow(
                              'Storage Duration',
                              tankSizing['recommendation'],
                              icon: Icons.schedule,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tank Dimensions:',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                children: [
                                  _buildDataRow(
                                    'Length × Width',
                                    '${tankSizing['dimensions']['length'].toStringAsFixed(1)}m × ${tankSizing['dimensions']['width'].toStringAsFixed(1)}m',
                                    icon: Icons.aspect_ratio,
                                  ),
                                  _buildDataRow(
                                    'Height',
                                    '${tankSizing['dimensions']['height'].toStringAsFixed(1)}m',
                                    icon: Icons.height,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // AR Sizing Card
                      if (arSizing['required'])
                        _buildGlassCard(
                          title: 'Artificial Recharge Design',
                          icon: Icons.architecture,
                          accentColor: Colors.green.shade600,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Infiltration Rate: ${arSizing['infiltrationRate']} cm/hr',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Recommended Structures:',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...arSizing['structures'].entries.map((entry) {
                                final dynamic structure = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        structure['type'],
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        structure['dimensions'],
                                        style: TextStyle(
                                          color: Colors.green.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        structure['description'],
                                        style: TextStyle(
                                          color: Colors.green.shade600,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),

                      // Cost-Benefit Analysis Card
                      _buildGlassCard(
                        title: 'Cost-Benefit Analysis',
                        icon: Icons.analytics,
                        accentColor: Colors.orange.shade600,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Costs:',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDataRow(
                              'Storage Tank',
                              '₹${costBenefit['costs']['tank'].toStringAsFixed(0)}',
                              icon: Icons.storage,
                            ),
                            _buildDataRow(
                              'Piping & Filter',
                              '₹${(costBenefit['costs']['piping'] + costBenefit['costs']['filter']).toStringAsFixed(0)}',
                              icon: Icons.plumbing,
                            ),
                            if (arSizing['required'])
                              _buildDataRow(
                                'AR Structures',
                                '₹${costBenefit['costs']['ar'].toStringAsFixed(0)}',
                                icon: Icons.construction,
                              ),
                            _buildDataRow(
                              'Total Cost',
                              '₹${costBenefit['costs']['total'].toStringAsFixed(0)}',
                              icon: Icons.account_balance_wallet,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Annual Benefits:',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildDataRow(
                              'Water Saved',
                              '₹${costBenefit['benefits']['annualCostSaved'].toStringAsFixed(0)}',
                              icon: Icons.savings,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      // Subsidies Card
                      if (subsidies.isNotEmpty)
                        _buildGlassCard(
                          title: 'Government Subsidies',
                          icon: Icons.monetization_on,
                          accentColor: Colors.green.shade600,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...subsidies.entries.map((entry) {
                                final String schemeType = entry.key;
                                final Map<String, dynamic> scheme = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${schemeType.toUpperCase()} Scheme',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDataRow(
                                        'Scheme Name',
                                        scheme['scheme'],
                                        icon: Icons.verified,
                                      ),
                                      _buildDataRow(
                                        'Subsidy',
                                        '${scheme['percentage']}% (Max: ₹${scheme['maxAmount']})',
                                        icon: Icons.percent,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),

                      // Personalization Card
                      _buildGlassCard(
                        title: 'Personalized Insights',
                        icon: Icons.lightbulb_outline,
                        accentColor: Colors.purple.shade600,
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Water Saving Tips:',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...List<String>.from(
                              personalization['waterSavingTips'],
                            ).map(
                              (tip) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.purple.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.purple.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: TextStyle(
                                          color: Colors.purple.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Local Insights:',
                              style: TextStyle(
                                color: Colors.purple.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.purple.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Rainfall Pattern
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.cloud,
                                        size: 20,
                                        color: Colors.purple.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Rainfall Pattern:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.purple.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              personalization['localInsights']['rainfallPattern'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.purple.shade600,
                                              ),
                                              overflow: TextOverflow.visible,
                                              softWrap: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Best Installation Time
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 20,
                                        color: Colors.purple.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Best Installation:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.purple.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              personalization['localInsights']['bestInstallationTime'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.purple.shade600,
                                              ),
                                              overflow: TextOverflow.visible,
                                              softWrap: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Local Regulations
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info,
                                        size: 20,
                                        color: Colors.purple.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Local Regulations:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.purple.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              personalization['localInsights']['localRegulations'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.purple.shade600,
                                              ),
                                              overflow: TextOverflow.visible,
                                              softWrap: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Spacing
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Water Ripple Animation
class WaterRipplePainter extends CustomPainter {
  final double animationValue;

  WaterRipplePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Create multiple ripples
    for (int i = 0; i < 3; i++) {
      final rippleRadius = maxRadius * ((animationValue + i * 0.3) % 1.0);
      final opacity = (1.0 - (animationValue + i * 0.3) % 1.0) * 0.6;

      final paint =
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

      canvas.drawCircle(center, rippleRadius, paint);
    }

    // Draw center drop
    final dropPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 4, dropPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
