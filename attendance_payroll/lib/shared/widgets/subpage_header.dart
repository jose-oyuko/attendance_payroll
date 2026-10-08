import 'package:attendance_payroll/core/constants/app_spacing.dart';
import 'package:attendance_payroll/core/extensions/build_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Title row for a page opened from within an area (detail, form), with a
/// back button returning to [backLocation].
class SubpageHeader extends StatelessWidget {
  const SubpageHeader({
    required this.title,
    required this.backLocation,
    super.key,
    this.actions = const <Widget>[],
  });

  final String title;
  final String backLocation;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          BackButton(
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(backLocation),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: context.textStyles.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
