import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'notification_preferences_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  List<dynamic> _selectedEvents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final creathons = await _apiService.getEvents();
      final trainings = await _apiService.getTrainings();
      print('📅 Créathons: ${creathons.length}');
      print('📅 Trainings: ${trainings.length}');
      print(
        '📅 Premier créathon: ${creathons.isNotEmpty ? creathons[0] : "vide"}',
      );
      print(
        '📅 Premier training: ${trainings.isNotEmpty ? trainings[0] : "vide"}',
      );

      // Ajouter le type à chaque événement
      final allEvents = [
        ...creathons.map((e) => {...e, 'type': 'creathon'}),
        ...trainings.map((e) => {...e, 'type': e['type'] ?? 'formation'}),
      ];

      final Map<DateTime, List<dynamic>> eventMap = {};

      for (final event in allEvents) {
        // Créathons utilisent dates.startDate, trainings utilisent startDate
        final rawDate = event['dates']?['startDate'] ?? event['startDate'];
        if (rawDate == null) continue;

        final startDate = DateTime.parse(rawDate).toLocal();
        final day = DateTime(startDate.year, startDate.month, startDate.day);
        eventMap[day] = [...(eventMap[day] ?? []), event];
      }

      setState(() {
        _events = eventMap;
        _loading = false;
      });
    } catch (e) {
      print('❌ Erreur calendrier: $e');
      setState(() => _loading = false);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Color _getEventColor(String? type) {
    switch (type) {
      case 'creathon':
        return const Color(0xFF1E40AF);
      case 'formation':
        return const Color(0xFF16A34A);
      case 'bootcamp':
        return const Color(0xFFD97706);
      case 'mentorat':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF1E40AF);
    }
  }

  String _getEventTypeLabel(String? type) {
    switch (type) {
      case 'creathon':
        return 'Créathon';
      case 'formation':
        return 'Formation';
      case 'bootcamp':
        return 'Bootcamp';
      case 'mentorat':
        return 'Mentorat';
      default:
        return 'Événement';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        title: const Text(
          'Calendrier Tacir',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    NotificationPreferencesScreen(userId: auth.userId ?? ''),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar
                Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime(2024),
                    lastDay: DateTime(2027),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    calendarStyle: CalendarStyle(
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFF1E40AF),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF1E40AF),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF1E40AF).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _selectedEvents = _getEventsForDay(selectedDay);
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                ),

                // Events list
                Expanded(
                  child: _selectedEvents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedDay == null
                                    ? 'Sélectionnez un jour'
                                    : 'Aucun événement ce jour',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _selectedEvents.length,
                          itemBuilder: (context, index) {
                            final event = _selectedEvents[index];
                            final type = event['type'] as String?;
                            final color = _getEventColor(type);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border(
                                  left: BorderSide(color: color, width: 4),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                title: Text(
                                  event['title'] ?? 'Sans titre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _getEventTypeLabel(type),
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (event['location'] != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            event['location']['city'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
