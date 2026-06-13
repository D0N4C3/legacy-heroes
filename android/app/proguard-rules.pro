# App-specific release shrinking rules.
#
# Flutter plugins, Firebase, Google Play services, and AndroidX ship their own
# consumer ProGuard rules. Keep this file intentionally small so R8 can remove
# as much unused code as possible.

# Keep native entry points referenced from platform code.
-keep class com.qewiygames.lovegotchi.MainActivity { *; }

# Keep Flutter local notification receivers declared directly in AndroidManifest.
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }

# Keep Firebase Messaging service classes discovered from manifest metadata.
-keep class io.flutter.plugins.firebase.messaging.** { *; }

# Keep generated plugin registration. R8 can still shrink unused plugin internals.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
