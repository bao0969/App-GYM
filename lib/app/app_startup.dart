import 'package:flutter/foundation.dart';
import '../core/services/seed_service.dart';

class AppStartup {
  AppStartup._();

  static Future<void> initialize() async {
    if (!kDebugMode) {
      return;
    }

    final seedService = SeedService();
    await seedService.seedAdminIfNeeded();
    await seedService.seedSampleData();
    await seedService.migrateV1ToV2();
  }
}
