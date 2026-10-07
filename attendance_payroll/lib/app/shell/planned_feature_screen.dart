import 'package:attendance_payroll/app/router/admin_destination.dart';
import 'package:attendance_payroll/shared/widgets/empty_state.dart';
import 'package:flutter/widgets.dart';

/// Explicit boundary for an area that is not built yet. It states which phase
/// delivers the area instead of pretending the feature exists.
class PlannedFeatureScreen extends StatelessWidget {
  const PlannedFeatureScreen({required this.destination, super.key});

  final AdminDestination destination;

  @override
  Widget build(BuildContext context) {
    final phase = destination.plannedPhase;
    return EmptyState(
      icon: destination.icon,
      title: '${destination.label} is not available yet',
      message: phase == null
          ? 'This area has not been built yet.'
          : 'This area is built in Phase $phase.',
    );
  }
}
