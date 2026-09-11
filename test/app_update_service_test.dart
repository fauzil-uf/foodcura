import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/constants/app_constants.dart';
import 'package:foodcura/services/app_update_service.dart';

void main() {
  group('AppUpdateService Tests', () {
    test('AppConstants matches v2.3.5 version definitions', () {
      expect(AppConstants.appVersion, equals('2.3.5'));
      expect(AppConstants.appBuildNumber, equals('14'));
      expect(AppConstants.appVersionDisplay, equals('v2.3.5'));
    });

    test('AppUpdateService defines core update notice functionality', () {
      expect(AppUpdateService.showUpdateNoticeModal, isNotNull);
      expect(AppUpdateService.checkAndShowWhatsNew, isNotNull);
    });
  });
}
