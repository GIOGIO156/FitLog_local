import 'package:fitlog_local/core/constants/app_constants.dart';
import 'package:fitlog_local/domain/models/user_profile.dart';
import 'package:fitlog_local/domain/services/macro_target_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = MacroTargetCalculator();

  group('MacroTargetCalculator.calculateByGramPerKg', () {
    test('male 80kg 2 sessions uses cut MVP default table', () {
      final targets = calculator.calculateByGramPerKg(
        profile: _profile(sexForFormula: 'male', trainingFrequencyPerWeek: 2),
      );

      expect(targets.proteinTargetG, closeTo(112, 0.001));
      expect(targets.carbsTargetG, closeTo(120, 0.001));
      expect(targets.fatTargetG, closeTo(64, 0.001));
    });

    test('male 80kg 5 sessions uses cut MVP default table', () {
      final targets = calculator.calculateByGramPerKg(
        profile: _profile(sexForFormula: 'male', trainingFrequencyPerWeek: 5),
      );

      expect(targets.proteinTargetG, closeTo(144, 0.001));
      expect(targets.carbsTargetG, closeTo(176, 0.001));
      expect(targets.fatTargetG, closeTo(80, 0.001));
    });

    test('female 80kg 2 sessions uses cut MVP default table', () {
      final targets = calculator.calculateByGramPerKg(
        profile: _profile(sexForFormula: 'female', trainingFrequencyPerWeek: 2),
      );

      expect(targets.proteinTargetG, closeTo(112, 0.001));
      expect(targets.carbsTargetG, closeTo(112, 0.001));
      expect(targets.fatTargetG, closeTo(80, 0.001));
    });

    test('female 80kg 5 sessions uses cut MVP default table', () {
      final targets = calculator.calculateByGramPerKg(
        profile: _profile(sexForFormula: 'female', trainingFrequencyPerWeek: 5),
      );

      expect(targets.proteinTargetG, closeTo(144, 0.001));
      expect(targets.carbsTargetG, closeTo(152, 0.001));
      expect(targets.fatTargetG, closeTo(96, 0.001));
    });

    test('prefer_not_to_say averages male and female coefficients', () {
      final targets = calculator.calculateByGramPerKg(
        profile: _profile(
          sexForFormula: 'prefer_not_to_say',
          trainingFrequencyPerWeek: 5,
        ),
      );

      expect(targets.proteinTargetG, closeTo(144, 0.001));
      expect(targets.carbsTargetG, closeTo(164, 0.001));
      expect(targets.fatTargetG, closeTo(88, 0.001));
      expect(targets.macroEnergyEquivalentKcal, closeTo(2024, 0.001));
    });
  });

  group('MacroTargetCalculator.calculateByEnergyRatio', () {
    test('still converts target intake kcal by macro ratios', () {
      final targets = calculator.calculateByEnergyRatio(
        profile: _profile(
          proteinRatioPercent: 30,
          carbsRatioPercent: 40,
          fatRatioPercent: 30,
        ),
        targetIntakeKcal: 2000,
      );

      expect(targets.proteinTargetG, closeTo(150, 0.001));
      expect(targets.carbsTargetG, closeTo(200, 0.001));
      expect(targets.fatTargetG, closeTo(2000 * 0.3 / 9, 0.001));
      expect(targets.macroEnergyEquivalentKcal, closeTo(2000, 0.001));
    });
  });
}

UserProfile _profile({
  String sexForFormula = 'male',
  int trainingFrequencyPerWeek = AppConstants.defaultTrainingFrequencyPerWeek,
  double proteinRatioPercent = AppConstants.defaultProteinRatioPercent,
  double carbsRatioPercent = AppConstants.defaultCarbsRatioPercent,
  double fatRatioPercent = AppConstants.defaultFatRatioPercent,
}) {
  return UserProfile(
    age: 30,
    heightCm: 175,
    weightKg: 80,
    sexForFormula: sexForFormula,
    activityLevel: 'very_active',
    dailyEnergyGoalType: 'deficit',
    dailyEnergyGoalKcal: 700,
    proteinRatioPercent: proteinRatioPercent,
    carbsRatioPercent: carbsRatioPercent,
    fatRatioPercent: fatRatioPercent,
    dietCalculationMode: AppConstants.dietCalculationModeGramPerKg,
    trainingFrequencyPerWeek: trainingFrequencyPerWeek,
    macroSelfCheckPeriodDays: AppConstants.defaultMacroSelfCheckPeriodDays,
    macroSelfCheckEnabled: true,
  );
}
