import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase client options for project green-energy-fb652.
///
/// Supply the platform app values with --dart-define when running/building.
/// These are Firebase client identifiers, not service-account credentials.
class DefaultFirebaseOptions {
  static const projectId = 'green-energy-fb652';
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return _options(
        appId: const String.fromEnvironment('FIREBASE_WEB_APP_ID'),
        authDomain: '$projectId.firebaseapp.com',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _options(
          appId: const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
        );
      case TargetPlatform.iOS:
        return _options(
          appId: const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
          bundleId: const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
        );
      case TargetPlatform.macOS:
        return _options(
          appId: const String.fromEnvironment('FIREBASE_MACOS_APP_ID'),
          bundleId: const String.fromEnvironment('FIREBASE_MACOS_BUNDLE_ID'),
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase is configured for Android, iOS, macOS, and web only.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase is not configured for Fuchsia.');
    }
  }

  static FirebaseOptions _options({
    required String appId,
    String? authDomain,
    String? bundleId,
  }) {
    final missing = <String>[
      if (_apiKey.isEmpty) 'FIREBASE_API_KEY',
      if (_senderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
      if (_storageBucket.isEmpty) 'FIREBASE_STORAGE_BUCKET',
      if (appId.isEmpty) 'the platform Firebase app ID',
      if (bundleId != null && bundleId.isEmpty) 'the iOS/macOS bundle ID',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Firebase is not configured. Missing ${missing.join(', ')}. '
        'See FIREBASE_SETUP.md.',
      );
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: appId,
      messagingSenderId: _senderId,
      projectId: projectId,
      storageBucket: _storageBucket,
      authDomain: authDomain,
      iosBundleId: bundleId,
    );
  }
}
