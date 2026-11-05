import 'package:flutter_test/flutter_test.dart';
import 'package:dogo_crew/data/services/notification_service.dart';

void main() {
  group('DogoNotificationService Tests', () {
    test('Notification service constants and channels are configured properly', () {
      expect(DogoNotificationService.rideNotificationId, 8888);
      expect(DogoNotificationService.arrivalNotificationId, 9999);
      expect(DogoNotificationService.channelId, 'dogo_ride_dispatch_channel_v1');
      expect(DogoNotificationService.channelName, 'DOGO Incoming Ride Requests');
      expect(DogoNotificationService.channelDesc, contains('heads-up alerts for online captains'));
    });

    test('DogoNotificationService is a singleton', () {
      final s1 = DogoNotificationService.instance;
      final s2 = DogoNotificationService.instance;
      expect(identical(s1, s2), isTrue);
    });
  });
}

