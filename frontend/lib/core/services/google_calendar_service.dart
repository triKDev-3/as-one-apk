import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleCalendarService {
  /// Connexion Google via le projet Firebase de l'app (google-services.json).
  /// Pas de clientId web forcé → évite ApiException 10 (DEVELOPER_ERROR).
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      calendar.CalendarApi.calendarEventsScope,
    ],
  );

  /// Synchronise les affectations vers Google Agenda.
  Future<void> syncPlanningToCalendar(
    List<Map<String, dynamic>> assignments,
  ) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Connexion Google annulée');
      }

      final client = await _googleSignIn.authenticatedClient();
      if (client == null) {
        throw Exception('Impossible d\'obtenir le client authentifié Google');
      }

      final calendarApi = calendar.CalendarApi(client);
      const calendarId = 'primary';

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc();

      final events = await calendarApi.events.list(
        calendarId,
        timeMin: startOfDay,
        privateExtendedProperty: ['source=as_one_app'],
      );

      if (events.items != null) {
        for (final event in events.items!) {
          if (event.id != null) {
            await calendarApi.events.delete(calendarId, event.id!);
          }
        }
      }

      for (final assignment in assignments) {
        final status = assignment['status'] as String? ?? '';
        if (status != 'CONFIRMED' &&
            status != 'LOCKED' &&
            status != 'PENDING_CONFIRMATION' &&
            status != 'ACTIVE') {
          continue;
        }

        final site = assignment['site'] as Map<String, dynamic>? ?? {};
        final startDateStr = assignment['startDate'] as String?;
        final endDateStr = assignment['endDate'] as String?;
        if (startDateStr == null) continue;

        final startDate = DateTime.parse(startDateStr);
        final endDate = endDateStr != null
            ? DateTime.parse(endDateStr)
            : startDate.add(const Duration(days: 1));

        final event = calendar.Event(
          summary: 'AS ONE: ${site['name'] ?? 'Chantier'}',
          description:
              'Affecté sur le chantier ${site['name'] ?? ''}\nAdresse: ${site['address'] ?? ''}',
          start: calendar.EventDateTime(date: startDate, timeZone: 'UTC'),
          end: calendar.EventDateTime(date: endDate, timeZone: 'UTC'),
          extendedProperties: calendar.EventExtendedProperties(
            private: {'source': 'as_one_app'},
          ),
        );

        await calendarApi.events.insert(event, calendarId);
      }
    } on PlatformException catch (e) {
      debugPrint('Google Calendar PlatformException: $e');
      if (e.code == 'sign_in_failed' ||
          (e.message ?? '').contains('ApiException: 10')) {
        throw Exception(
          'Google Agenda non configuré sur cet appareil (erreur 10). '
          'Le marquage d\'indisponibilité fonctionne sans Google.',
        );
      }
      throw Exception('Erreur Google : ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('Error syncing to Google Calendar: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
