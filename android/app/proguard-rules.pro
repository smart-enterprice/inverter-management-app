# ── Flutter / Dart ─────────────────────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ── Play Core (deferred components) — we don't use these, but Flutter
#    embedding references them, so silence the missing-class warnings ───────────
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ── Firebase Messaging ─────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── flutter_local_notifications ────────────────────────────────────────────────
-keep class com.dexterous.** { *; }
-keep class * extends android.app.Service

# ── Keep generic signatures for Gson / serialization (used by Dio JSON) ────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# ── Standard Kotlin keep rules ─────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# ── Strip debug logs in release ────────────────────────────────────────────────
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
