// INSTRUCTIONS: Update these values with your Firebase web credentials from Firebase Console
// Project: jeokissan-quality-manual
// 
// To get these values:
// 1. Go to Firebase Console: https://console.firebase.google.com/
// 2. Select "jeokissan-quality-manual" project
// 3. Go to Project Settings (gear icon)
// 4. Click "Your apps" 
// 5. Select or create a Web app
// 6. Copy the firebaseConfig values below

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } else if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    } else {
      return web; // Fallback for other platforms
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAVx2lWFUWUDAePzj7PqEZc0QZAgHM_oPc",
    authDomain: "jeokissan-quality-manual.firebaseapp.com",
    projectId: "jeokissan-quality-manual",
    storageBucket: "jeokissan-quality-manual.firebasestorage.app",
    messagingSenderId: "265598791082",
    appId: "1:265598791082:web:2bf0aeb5646c6c44274fd3",
    measurementId: "G-899MSMM3LE",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyCErX3Wil1s9CrIjoBQqluQeOVuImSMOH8",
    appId: "1:265598791082:android:52322549d24c689e274fd3",
    messagingSenderId: "265598791082",
    projectId: "jeokissan-quality-manual",
    storageBucket: "jeokissan-quality-manual.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyAQAyn6zO8trF1SlcifT9Dp9Nv-A9U-5jE",
    appId: "1:265598791082:ios:14ba96f8edee6b55274fd3",
    messagingSenderId: "265598791082",
    projectId: "jeokissan-quality-manual",
    storageBucket: "jeokissan-quality-manual.firebasestorage.app",
  );
}
