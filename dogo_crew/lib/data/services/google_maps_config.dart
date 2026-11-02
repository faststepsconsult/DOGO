/// Centralized configuration for Google Maps Platform in DOGO.
///
/// To enable full native Google Maps rendering and Google Places search:
/// 1. Create an API key in Google Cloud Console: https://console.cloud.google.com/
/// 2. Enable the following 4 APIs:
///    - Maps SDK for Android
///    - Places API (New) / Places API
///    - Directions API
///    - Geocoding API
/// 3. Provide your key below in [apiKey] AND in:
///    `dogo_crew/android/app/src/main/AndroidManifest.xml`
///    under `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY" />`
class GoogleMapsConfig {
  /// Paste your Google Cloud Platform API Key here.
  /// Example: 'AIzaSyD...'
  static String apiKey = '';

  /// If true, forces Google Maps SDK rendering even if apiKey string is empty in Dart
  /// (e.g. when configured directly via AndroidManifest.xml).
  static bool forceGoogleMaps = false;

  /// Checks if a valid non-placeholder API key has been configured.
  static bool get hasValidKey =>
      apiKey.trim().isNotEmpty &&
      !apiKey.contains('Placeholder') &&
      !apiKey.contains('YOUR_GOOGLE_MAPS_API_KEY');

  /// Determines whether to render native Google Maps SDK or fallback to OSM tiles.
  /// When no valid key is detected, DOGO automatically falls back to OSM dark mode
  /// so the screen is NEVER blank beige.
  static bool get shouldUseGoogleMaps => hasValidKey || forceGoogleMaps;
}
