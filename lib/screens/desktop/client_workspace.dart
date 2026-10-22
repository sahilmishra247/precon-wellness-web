import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../models/user_role.dart';
import '../../services/theme_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_exit_scope.dart';
import '../../widgets/desktop_shell.dart';
import '../appointments_screen.dart';
import '../client_details_screen.dart';
import '../consultation_notes_screen.dart';
import '../diet_plan_screen.dart';
import '../educational_resources_screen.dart';
import '../progress_screen.dart';
import '../workout_plan_screen.dart';
import 'client_overview.dart';

enum _Section { home, progress, diet, workout, notes, sessions, library, profile }

/// Desktop layout for clients: icon rail and a two-column home.
class ClientWorkspace extends StatefulWidget {
  final Client client;
  const ClientWorkspace({super.key, required this.client});

  @override
  State<ClientWorkspace> createState() => _ClientWorkspaceState();
}

class _ClientWorkspaceState extends State<ClientWorkspace> {
  _Section _section = _Section.home;

  // Bumped when returning home so it shows fresh numbers.
  int _homeVersion = 0;

  static const _destinations = {
    _Section.home: RailDestination(Icons.home_outlined, 'Home'),
    _Section.progress: RailDestination(Icons.show_chart_rounded, 'Progress tracking'),
    _Section.diet: RailDestination(Icons.restaurant_outlined, 'Diet plan'),
    _Section.workout: RailDestination(Icons.fitness_center_outlined, 'Workout plan'),
    _Section.notes: RailDestination(Icons.note_alt_outlined, 'Consultation notes'),
    _Section.sessions: RailDestination(Icons.calendar_month_outlined, 'Appointments'),
    _Section.library: RailDestination(Icons.menu_book_outlined, 'Educational library'),
    _Section.profile: RailDestination(Icons.person_outline_rounded, 'My profile'),
  };

  void _go(_Section s) => setState(() {
        if (s == _Section.home && _section != _Section.home) _homeVersion++;
        _section = s;
      });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = ThemeService.instance.isDark(context);
        return ConfirmExitScope(
          child: Scaffold(
            backgroundColor: AppColors.bg(isDark),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IconRail(
                  isDark: isDark,
                  selectedIndex: _Section.values.indexOf(_section),
                  onSelected: (i) => _go(_Section.values[i]),
                  destinations: [for (final s in _Section.values) _destinations[s]!],
                ),
                Expanded(child: _content(isDark)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _content(bool isDark) {
    final client = widget.client;
    switch (_section) {
      case _Section.home:
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: ClientOverview(
              key: ValueKey('home-$_homeVersion'),
              client: client,
              isDark: isDark,
              showGreeting: true,
              onOpenProgress: () => _go(_Section.progress),
              progressActionLabel: 'Log weight',
            ),
          ),
        );
      case _Section.progress:
        return PaneNavigator(key: const ValueKey('progress'), child: ProgressScreen(client: client));
      case _Section.diet:
        return PaneNavigator(key: const ValueKey('diet'), child: DietPlanScreen(client: client, readOnly: true));
      case _Section.workout:
        return PaneNavigator(key: const ValueKey('workout'), child: WorkoutPlanScreen(client: client, readOnly: true));
      case _Section.notes:
        return PaneNavigator(
          key: const ValueKey('notes'),
          child: ConsultationNotesScreen(client: client, authorName: client.fullName, readOnly: true),
        );
      case _Section.sessions:
        return PaneNavigator(
          key: const ValueKey('sessions'),
          child: AppointmentsScreen(client: client, readOnly: true),
        );
      case _Section.library:
        return const PaneNavigator(key: ValueKey('library'), child: EducationalResourcesScreen());
      case _Section.profile:
        return PaneNavigator(
          key: const ValueKey('profile'),
          child: ClientDetailsScreen(client: client, role: UserRole.client),
        );
    }
  }
}
