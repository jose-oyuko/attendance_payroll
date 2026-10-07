import 'package:attendance_payroll/core/constants/app_constants.dart';
import 'package:attendance_payroll/shared/responsive/window_size_builder.dart';
import 'package:flutter/widgets.dart';

/// Standard page body: responsive gutters, a maximum content width and
/// optional vertical scrolling.
class PageContainer extends StatelessWidget {
  const PageContainer({required this.child, super.key, this.scrollable = true});

  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return WindowSizeBuilder(
      builder: (context, size) {
        final content = Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.all(size.pageGutter),
              child: child,
            ),
          ),
        );
        return scrollable ? SingleChildScrollView(child: content) : content;
      },
    );
  }
}
