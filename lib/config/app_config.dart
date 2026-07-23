// lib/config/app_config.dart
// ⚠️  API keys are loaded from --dart-define at build time.
// Never commit real key values here.
//
// Build command:
//   flutter build apk --dart-define=GOOGLE_CALENDAR_API_KEY=your_key_here
//   flutter build web --dart-define=GOOGLE_CALENDAR_API_KEY=your_key_here

class AppConfig {
  // Google Calendar API key — injected at build time via --dart-define
  // Falls back to empty string in dev (Calendar features will be disabled)
  static const String googleCalendarApiKey =
      String.fromEnvironment('GOOGLE_CALENDAR_API_KEY', defaultValue: '');

  // Google Calendar ID
  // Set via --dart-define=GOOGLE_CALENDAR_ID=your_calendar_id
  static const String calendarId =
      String.fromEnvironment('GOOGLE_CALENDAR_ID', defaultValue: '');

  // How many days ahead to fetch
  static const int appointmentLookaheadDays = 30;
}
