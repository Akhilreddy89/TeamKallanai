import '../models/location_data.dart';
import '../models/user_input.dart';
import 'dart:math' as math;

class RainwaterController {
  static Map<String, dynamic> calculateRainwaterHarvesting(
    UserInput userInput,
  ) {
    final locationData = locationDataMap[userInput.location]!;

    // Step 1: User Input (already available)
    final double roofAreaSqM =
        userInput.area * 0.092903; // Convert sq ft to sq m
    final double openSpaceAreaSqM =
        userInput.openSpaceArea * 0.092903; // Convert sq ft to sq m
    final int dwellers = userInput.people;
    final double costBudget = 50000; // Default budget in INR

    // Step 2: Auto Data Fetch (from locationData)
    final int annualRainfall = locationData.annualRainfall;
    final String groundwaterDepth = locationData.groundwaterDepth;
    final String soilType = locationData.soilType;
    final double infiltrationRate = _getInfiltrationRate(soilType);
    final Map<String, dynamic> subsidies = _getSubsidies(userInput.location);

    // Step 3: Calculate Harvestable Water
    final double harvestableWaterLiters = roofAreaSqM * annualRainfall * 0.8;

    // Step 4: Estimate Household Water Demand
    final double annualDemandLiters =
        dwellers * 135 * 365; // 135L per capita per day

    // Step 5: Feasibility Decision
    final Map<String, dynamic> feasibilityDecision = _determineFeasibility(
      harvestableWaterLiters: harvestableWaterLiters,
      annualDemandLiters: annualDemandLiters,
      groundwaterDepth: groundwaterDepth,
      openSpaceAvailable: openSpaceAreaSqM > 0,
    );

    // Step 6: Tank Sizing
    final Map<String, dynamic> tankSizing = _calculateTankSizing(
      harvestableWaterLiters: harvestableWaterLiters,
      annualDemandLiters: annualDemandLiters,
    );

    // Step 7: AR Sizing
    final Map<String, dynamic> arSizing = _calculateARSizing(
      excessWater: harvestableWaterLiters - annualDemandLiters,
      infiltrationRate: infiltrationRate,
      aquiferDepth: _parseGroundwaterDepth(groundwaterDepth),
      openSpaceArea: openSpaceAreaSqM,
    );

    // Step 8: ROI & Cost-Benefit
    final Map<String, dynamic> costBenefit = _calculateCostBenefit(
      harvestableWater: harvestableWaterLiters,
      systemType: feasibilityDecision['systemType'],
      tankSizing: tankSizing,
      arSizing: arSizing,
      location: userInput.location,
    );

    // Step 9: Personalization
    final Map<String, dynamic> personalization = _getPersonalization(
      location: userInput.location,
      systemType: feasibilityDecision['systemType'],
      subsidies: subsidies,
    );

    return {
      'locationData': locationData,
      'userInputs': {
        'roofAreaSqM': roofAreaSqM,
        'openSpaceAreaSqM': openSpaceAreaSqM,
        'dwellers': dwellers,
        'costBudget': costBudget,
      },
      'calculations': {
        'harvestableWaterLiters': harvestableWaterLiters,
        'annualDemandLiters': annualDemandLiters,
        'excessWater': harvestableWaterLiters - annualDemandLiters,
      },
      'feasibilityDecision': feasibilityDecision,
      'tankSizing': tankSizing,
      'arSizing': arSizing,
      'costBenefit': costBenefit,
      'personalization': personalization,
      'subsidies': subsidies,
    };
  }

  static double _getInfiltrationRate(String soilType) {
    switch (soilType.toLowerCase()) {
      case 'clay':
        return 0.5; // cm/hr
      case 'silty clay':
        return 1.0;
      case 'clay loam':
        return 1.5;
      case 'silt loam':
        return 2.0;
      case 'loam':
        return 2.5;
      case 'sandy loam':
        return 3.0;
      case 'sandy':
        return 5.0;
      case 'gravelly':
        return 10.0;
      default:
        return 2.0; // Default to loam
    }
  }

  static Map<String, dynamic> _getSubsidies(String location) {
    // Static database of subsidies by state
    final Map<String, Map<String, dynamic>> stateSubsidies = {
      'Telangana': {
        'rtrwh': {
          'percentage': 50,
          'maxAmount': 25000,
          'scheme': 'Mission Kakatiya',
        },
        'ar': {
          'percentage': 60,
          'maxAmount': 50000,
          'scheme': 'Groundwater Recharge',
        },
      },
      'Andhra Pradesh': {
        'rtrwh': {
          'percentage': 40,
          'maxAmount': 20000,
          'scheme': 'Neeru-Chettu',
        },
        'ar': {
          'percentage': 50,
          'maxAmount': 40000,
          'scheme': 'Water Conservation',
        },
      },
    };

    // Determine state from location (simplified)
    String state = 'Telangana'; // Default
    if (location.contains('Hyderabad') || location.contains('Secunderabad')) {
      state = 'Telangana';
    }

    return stateSubsidies[state] ?? {};
  }

  static Map<String, dynamic> _determineFeasibility({
    required double harvestableWaterLiters,
    required double annualDemandLiters,
    required String groundwaterDepth,
    required bool openSpaceAvailable,
  }) {
    bool harvestableMeetsDemand = harvestableWaterLiters >= annualDemandLiters;
    bool groundwaterFalling = _isGroundwaterFalling(groundwaterDepth);
    bool openSpaceExists = openSpaceAvailable;

    String systemType;
    String feasibility;
    String reasoning;

    if (harvestableMeetsDemand && (groundwaterFalling || openSpaceExists)) {
      systemType = 'Hybrid (Tank + AR)';
      feasibility = 'Highly Feasible';
      reasoning = 'Sufficient water available and groundwater recharge needed';
    } else if (harvestableMeetsDemand) {
      systemType = 'Storage Tank (RTRWH)';
      feasibility = 'Feasible';
      reasoning = 'Sufficient water available for storage';
    } else if (groundwaterFalling || openSpaceExists) {
      systemType = 'Artificial Recharge (AR)';
      feasibility = 'Moderately Feasible';
      reasoning = 'Limited water but recharge infrastructure possible';
    } else {
      systemType = 'Basic Collection';
      feasibility = 'Limited Feasibility';
      reasoning = 'Limited water availability and space constraints';
    }

    return {
      'systemType': systemType,
      'feasibility': feasibility,
      'reasoning': reasoning,
      'harvestableMeetsDemand': harvestableMeetsDemand,
      'groundwaterFalling': groundwaterFalling,
      'openSpaceAvailable': openSpaceExists,
    };
  }

  static bool _isGroundwaterFalling(String groundwaterDepth) {
    if (groundwaterDepth.contains('>') || groundwaterDepth.contains('~')) {
      final double depth =
          double.tryParse(
            groundwaterDepth.replaceAll('>', '').replaceAll('~', '').trim(),
          ) ??
          10.0;
      return depth > 15; // Consider falling if >15m
    }
    return false;
  }

  static Map<String, dynamic> _calculateTankSizing({
    required double harvestableWaterLiters,
    required double annualDemandLiters,
  }) {
    final double monthlyDemand = annualDemandLiters / 12;
    final double recommendedStorage = monthlyDemand * 2.5; // 2.5 months storage
    final double actualStorage =
        harvestableWaterLiters < recommendedStorage
            ? harvestableWaterLiters
            : recommendedStorage;

    return {
      'volumeLiters': actualStorage,
      'volumeCubicMeters': actualStorage / 1000,
      'dimensions': _getTankDimensions(actualStorage / 1000),
      'storageMonths': actualStorage / monthlyDemand,
      'recommendation':
          'Storage for ${(actualStorage / monthlyDemand).toStringAsFixed(1)} months',
    };
  }

  static Map<String, dynamic> _getTankDimensions(double volumeCubicMeters) {
    // Calculate optimal tank dimensions
    final double height = 2.5; // Standard height
    final double area = volumeCubicMeters / height;
    final double side = math.sqrt(area);

    return {'length': side, 'width': side, 'height': height, 'area': area};
  }

  static Map<String, dynamic> _calculateARSizing({
    required double excessWater,
    required double infiltrationRate,
    required double aquiferDepth,
    required double openSpaceArea,
  }) {
    if (excessWater <= 0) {
      return {
        'required': false,
        'reason': 'No excess water available for recharge',
      };
    }

    final Map<String, dynamic> structures = {};

    // Recharge Pit for small excess
    if (excessWater <= 50000) {
      structures['rechargePit'] = {
        'type': 'Recharge Pit',
        'dimensions': '1-2m diameter × 2-3m depth',
        'volume': 3.14, // π × r² × h
        'description': 'Circular pit for small-scale recharge',
      };
    }

    // Recharge Trench for medium excess
    if (excessWater > 50000 && openSpaceArea > 10) {
      final double trenchLength = excessWater / (1000 * infiltrationRate * 0.5);
      structures['rechargeTrench'] = {
        'type': 'Recharge Trench',
        'dimensions':
            '0.5-1m wide × 1.5m deep × ${trenchLength.toStringAsFixed(1)}m long',
        'volume': 0.75 * trenchLength,
        'description': 'Linear trench for efficient recharge',
      };
    }

    // Recharge Shaft for deep aquifer
    if (aquiferDepth > 10) {
      structures['rechargeShaft'] = {
        'type': 'Recharge Shaft',
        'dimensions': '30-100cm diameter × 10-15m depth',
        'volume': 0.785, // π × r² × h
        'description': 'Deep shaft for aquifer recharge',
      };
    }

    return {
      'required': true,
      'structures': structures,
      'totalVolume': structures.values.fold(
        0.0,
        (sum, structure) => sum + (structure['volume'] as double),
      ),
      'infiltrationRate': infiltrationRate,
    };
  }

  static Map<String, dynamic> _calculateCostBenefit({
    required double harvestableWater,
    required String systemType,
    required Map<String, dynamic> tankSizing,
    required Map<String, dynamic> arSizing,
    required String location,
  }) {
    // Standard cost rates (INR)
    final Map<String, double> costRates = {
      'tankPerLiter': 2.0,
      'pipingPerMeter': 150.0,
      'filter': 5000.0,
      'arPerCubicMeter': 3000.0,
    };

    // Calculate system costs
    double tankCost = tankSizing['volumeLiters'] * costRates['tankPerLiter']!;
    double pipingCost =
        50.0 * costRates['pipingPerMeter']!; // Assume 50m piping
    double filterCost = costRates['filter']!;
    double arCost = 0.0;

    if (arSizing['required']) {
      arCost = arSizing['totalVolume'] * costRates['arPerCubicMeter']!;
    }

    double totalSystemCost = tankCost + pipingCost + filterCost + arCost;

    // Calculate annual benefits
    double waterTariff = 15.0; // INR per 1000L (local water tariff)
    double annualWaterSaved = harvestableWater * (waterTariff / 1000);
    double annualCostSaved = annualWaterSaved;

    // Calculate ROI
    double roi = (annualCostSaved / totalSystemCost) * 100;
    double paybackPeriod = totalSystemCost / annualCostSaved;

    return {
      'costs': {
        'tank': tankCost,
        'piping': pipingCost,
        'filter': filterCost,
        'ar': arCost,
        'total': totalSystemCost,
      },
      'benefits': {
        'annualWaterSaved': annualWaterSaved,
        'annualCostSaved': annualCostSaved,
        'waterTariff': waterTariff,
      },
      'roi': {
        'percentage': roi,
        'paybackPeriod': paybackPeriod,
        'recommendation': _getROIRecommendation(roi),
      },
    };
  }

  static String _getROIRecommendation(double roi) {
    if (roi > 50) return 'Excellent investment';
    if (roi > 30) return 'Good investment';
    if (roi > 15) return 'Moderate investment';
    return 'Consider alternatives';
  }

  static Map<String, dynamic> _getPersonalization({
    required String location,
    required String systemType,
    required Map<String, dynamic> subsidies,
  }) {
    return {
      'waterSavingTips': [
        'Fix leaky faucets and pipes',
        'Use water-efficient fixtures',
        'Collect and reuse greywater',
        'Install rainwater harvesting system',
        'Practice water-conscious gardening',
      ],
      'maintenanceSchedule': {
        'monthly': ['Check for leaks', 'Clean filters'],
        'quarterly': ['Inspect tank condition', 'Test water quality'],
        'annually': ['Deep clean tank', 'Service pump if applicable'],
      },
      'localInsights': {
        'rainfallPattern': 'Monsoon season (June-September)',
        'bestInstallationTime': 'Pre-monsoon (March-May)',
        'localRegulations': 'Check with local municipality',
      },
    };
  }

  static double _parseGroundwaterDepth(String depthText) {
    if (depthText.contains('>')) {
      return double.tryParse(depthText.replaceAll('>', '').trim()) ?? 25.0;
    } else if (depthText.contains('~')) {
      return double.tryParse(depthText.replaceAll('~', '').trim()) ?? 10.0;
    } else if (depthText.contains('to')) {
      final parts = depthText.split('to');
      final double minDepth = double.tryParse(parts[0].trim()) ?? 5.0;
      final double maxDepth = double.tryParse(parts[1].trim()) ?? 10.0;
      return (minDepth + maxDepth) / 2;
    } else {
      return double.tryParse(depthText) ?? 10.0;
    }
  }

  static List<String> getLocations() {
    return locationDataMap.keys.toList();
  }

  static List<String> getHouseTypes() {
    return ['Independent House', 'Apartment'];
  }
}
