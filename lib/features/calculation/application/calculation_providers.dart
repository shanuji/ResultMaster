import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/calculation_engine.dart';

/// Application-wide calculation engine provider.
///
/// Workbook, marks entry, summary, final sheet, and export code should watch or
/// read this provider instead of creating feature-local calculation logic. When
/// marks or settings providers change, dependent calculated providers recompute
/// automatically through Riverpod.
final calculationEngineProvider = Provider<CalculationEngine>((ref) {
  return const CalculationEngine();
});

/// Reusable family for calculated workbook outputs.
///
/// Callers pass the current marks and settings in [CalculationInput]; Riverpod
/// invalidates the result whenever that input changes.
final calculationResultProvider = Provider.family<CalculationResult, CalculationInput>((ref, input) {
  return ref.watch(calculationEngineProvider).calculate(input);
});
