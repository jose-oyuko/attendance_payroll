import 'package:flutter/material.dart';

/// Top-level areas of the administrator experience.
///
/// This enum is the single source of truth for both the router (one branch per
/// destination, in this order) and the navigation UI.
enum AdminDestination {
  dashboard(
    path: '/dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  employees(
    path: '/employees',
    label: 'Employees',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  attendance(
    path: '/attendance',
    label: 'Attendance',
    icon: Icons.access_time,
    selectedIcon: Icons.access_time_filled,
    plannedPhase: 4,
  ),
  schedules(
    path: '/schedules',
    label: 'Schedules',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
    plannedPhase: 6,
  ),
  payroll(
    path: '/payroll',
    label: 'Payroll',
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments,
    plannedPhase: 8,
  ),
  reports(
    path: '/reports',
    label: 'Reports',
    icon: Icons.assessment_outlined,
    selectedIcon: Icons.assessment,
    plannedPhase: 9,
  ),
  backup(
    path: '/backup',
    label: 'Backup',
    icon: Icons.backup_outlined,
    selectedIcon: Icons.backup,
    plannedPhase: 11,
  ),
  settings(
    path: '/settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  const AdminDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.plannedPhase,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Implementation phase in which this area is built, or `null` when the
  /// area already exists.
  final int? plannedPhase;
}
