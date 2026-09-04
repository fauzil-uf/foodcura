import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/constants/app_constants.dart';
import 'package:foodcura/services/app_update_service.dart';

void main() {
  group('AppUpdateService Tests', () {
    test('AppConstants matches v2.3.1 version definitions', () {
      expect(AppConstants.appVersion, equals('2.3.1'));
      expect(AppConstants.appBuildNumber, equals('13'));
      expect(AppConstants.appVersionDisplay, equals('v2.3.1'));
    });

    test('AppUpdateService defines core update notice functionality', () {
      expect(AppUpdateService.showUpdateNoticeModal, isNotNull);
      expect(AppUpdateService.checkAndShowWhatsNew, isNotNull);
    });
  });
}
