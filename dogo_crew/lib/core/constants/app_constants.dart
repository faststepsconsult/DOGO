class AppConstants {
  static const String supabaseUrl =
      'https://kpgrzrnmjwhusuyikjwa.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_J1WdK0U45xqpE1YfF-FxEw_N6DPUeWh';

  // Commission & Rates
  static const double driverShare = 0.7; // 70% to driver
  static const double dogoShare = 0.3; // 30% to DOGO

  // External Driver Clearance & Registration Website URL
  // The user will provide the final production URL.
  static const String driverOnboardingUrl = 'https://dogo.app/driver-clearing';

  static const Map<String, int> ratePerKm = {
    'taxi': 250,
    'keke': 150,
    'bike': 200,
  };

  static const Map<String, String> serviceLabels = {
    'taxi': 'Taxi',
    'keke': 'Keke',
    'bike': 'Bike dispatch',
  };

  static const Map<String, String> statusLabels = {
    'pending': 'Waiting',
    'accepted': 'Accepted',
    'en_route': 'On the way',
    'picked_up': 'Picked up',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
  };

  static const Map<String, String> paymentLabels = {
    'unpaid': 'Awaiting payment',
    'paid': 'Paid',
    'refunded': 'Refunded',
  };

  static const Map<String, String> verifyLabels = {
    'pending': 'Under review',
    'approved': 'Verified',
    'rejected': 'Not approved',
  };

  static const Map<String, Map<String, String>> nextStatus = {
    'accepted': {
      'to': 'en_route',
      'label': 'Start driving to pickup',
    },
    'en_route': {
      'to': 'picked_up',
      'label': 'Customer picked up',
    },
    'picked_up': {
      'to': 'completed',
      'label': 'Complete trip',
    },
  };
}
