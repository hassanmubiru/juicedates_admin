// JuiceDates Admin — Firebase options (same project as the main app)
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
        return linux;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyACP9h0Ts-UZk1sw9PHYFiUJ6DchkjbDyw',
    appId: '1:408134384062:web:77b25b3a22972e42df21ef',
    messagingSenderId: '408134384062',
    projectId: 'juicedates-2ebf0',
    authDomain: 'juicedates-2ebf0.firebaseapp.com',
    storageBucket: 'juicedates-2ebf0.firebasestorage.app',
  );

  // Linux desktop uses web config (Firebase JS SDK not available on Linux,
  // but flutter-fire supports the REST API through the web options).
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyACP9h0Ts-UZk1sw9PHYFiUJ6DchkjbDyw',
    appId: '1:408134384062:web:77b25b3a22972e42df21ef',
    messagingSenderId: '408134384062',
    projectId: 'juicedates-2ebf0',
    authDomain: 'juicedates-2ebf0.firebaseapp.com',
    storageBucket: 'juicedates-2ebf0.firebasestorage.app',
  );
}
