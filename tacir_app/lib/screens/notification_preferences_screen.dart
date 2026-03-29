import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../widgets/tacir_logo.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  final String userId;
  const NotificationPreferencesScreen({super.key, required this.userId});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final ApiService _apiService = ApiService();
  bool _weekBefore = true;
  bool _dayBefore = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await _apiService.getNotificationPreferences(widget.userId);
      setState(() {
        _weekBefore = prefs['preferences']?['weekBefore'] ?? true;
        _dayBefore = prefs['preferences']?['dayBefore'] ?? true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);
    try {
      await _apiService.updateNotificationPreferences(
        widget.userId,
        _weekBefore,
        _dayBefore,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Préférences sauvegardées'),
              ],
            ),
            backgroundColor: AppColors.cardCyan,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Erreur lors de la sauvegarde'),
              ],
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SafeArea(
              child: Column(
                children: [
                  // ─── HEADER ───────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const TacirLogo(size: 36),
                        const SizedBox(width: 12),
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info banner
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.1),
                                    AppColors.secondary.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_active,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Choisissez quand recevoir vos rappels avant chaque événement',
                                      style: TextStyle(
                                        color: AppColors.textDark,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            const Text(
                              'Rappels événements',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Toggle 1 semaine
                            _buildToggleCard(
                              icon: Icons.calendar_today,
                              iconColor: AppColors.primary,
                              title: '1 semaine avant',
                              subtitle: 'Rappel 7 jours avant l\'événement',
                              value: _weekBefore,
                              onChanged: (val) =>
                                  setState(() => _weekBefore = val),
                            ),
                            const SizedBox(height: 12),

                            // Toggle 1 jour
                            _buildToggleCard(
                              icon: Icons.alarm,
                              iconColor: AppColors.secondary,
                              title: '1 jour avant',
                              subtitle: 'Rappel la veille de l\'événement',
                              value: _dayBefore,
                              onChanged: (val) =>
                                  setState(() => _dayBefore = val),
                            ),

                            const SizedBox(height: 24),

                            // Info reschedule
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardOrange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.cardOrange.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.cardOrange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Vous serez toujours notifié en cas de modification ou annulation d\'un événement.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Save button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _savePreferences,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: _saving
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'Sauvegarder',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildToggleCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? iconColor.withOpacity(0.05) : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? iconColor.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: iconColor),
        ],
      ),
    );
  }
}
