import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleCalendarService {
  // Use the Client ID provided by the user.
  static const _clientId = '794433686695-fse56bv5q8heiln4pgpqso41ok90m6ph.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _clientId,
    scopes: [
      calendar.CalendarApi.calendarEventsScope,
    ],
  );

  /// Synchronizes a list of assignments to Google Calendar
  Future<void> syncPlanningToCalendar(List<Map<String, dynamic>> assignments) async {
    try {
      // Prompt user to log in or use existing session
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Connexion Google annulée');
      }

      // Obtain authenticated client
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) {
        throw Exception('Impossible d\'obtenir le client authentifié');
      }

      final calendarApi = calendar.CalendarApi(client);
      
      // Target calendar is primary
      const calendarId = 'primary';

      // To avoid duplicates, we can fetch future events and check if we already added them, 
      // or simply clear AS ONE events. A robust approach is adding a specific extendedProperty 
      // to events so we know they come from AS ONE, and then we can clear them and re-insert.
      
      // Step 1: Find existing AS ONE events from today onwards
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toUtc();
      
      final events = await calendarApi.events.list(
        calendarId,
        timeMin: startOfDay,
        privateExtendedProperty: ['source=as_one_app'],
      );
      
      // Step 2: Delete them
      if (events.items != null) {
        for (var event in events.items!) {
          if (event.id != null) {
            await calendarApi.events.delete(calendarId, event.id!);
          }
        }
      }
      
      // Step 3: Insert new ones
      for (var assignment in assignments) {
        final status = assignment['status'] as String? ?? '';
        // Skip if not active or pending
        if (status != 'CONFIRMED' && status != 'LOCKED' && status != 'PENDING_CONFIRMATION' && status != 'ACTIVE') continue;

        final site = assignment['site'] as Map<String, dynamic>? ?? {};
        final startDateStr = assignment['startDate'] as String?;
        final endDateStr = assignment['endDate'] as String?;
        
        if (startDateStr == null) continue;
        
        final startDate = DateTime.parse(startDateStr);
        final endDate = endDateStr != null ? DateTime.parse(endDateStr) : startDate.add(const Duration(days: 1));

        final event = calendar.Event(
          summary: 'AS ONE: ${site['name'] ?? "Chantier"}',
          description: 'Affecté sur le chantier ${site['name'] ?? ""}\nAdresse: ${site['address'] ?? ""}',
          start: calendar.EventDateTime(
            date: startDate,
            timeZone: 'UTC', // Ensure timezones are handled appropriately
          ),
          end: calendar.EventDateTime(
            date: endDate,
            timeZone: 'UTC',
          ),
          extendedProperties: calendar.EventExtendedProperties(
            private: {'source': 'as_one_app'},
          ),
        );

        await calendarApi.events.insert(event, calendarId);
      }
    } catch (e) {
      debugPrint('Error syncing to Google Calendar: $e');
      rethrow;
    }
  }

  /// Disconnect from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
