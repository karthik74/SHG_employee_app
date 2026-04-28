# =============================================================================
# ProGuard / R8 rules for SHG Employee App (NavaJyothi)
# -----------------------------------------------------------------------------
# These rules are applied on top of `proguard-android-optimize.txt` (the default
# Android optimization rules shipped with the Android Gradle plugin). Keep
# rules conservative: it is far better to leave a few unused classes in the
# release APK than to ship a build that crashes on first launch because R8
# stripped a class loaded via reflection from a Flutter plugin.
# =============================================================================


# -----------------------------------------------------------------------------
# Flutter embedding
# -----------------------------------------------------------------------------
# The Flutter engine and embedding load these packages by name (reflection /
# JNI), so we keep the entire surface. The `dontwarn` line silences warnings
# about optional embedding APIs that are referenced but may be absent depending
# on the embedding version (v1 vs v2).
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**


# -----------------------------------------------------------------------------
# Native methods (JNI)
# -----------------------------------------------------------------------------
# Any class with a `native` method must keep that method's name and signature,
# otherwise the JNI lookup at runtime will fail with UnsatisfiedLinkError.
-keepclasseswithmembernames class * {
    native <methods>;
}


# -----------------------------------------------------------------------------
# Reflection / Serialization metadata
# -----------------------------------------------------------------------------
# Generic type info, annotations, enclosing-method info, and inner-class info
# are needed by Gson-style JSON parsers, kotlinx.serialization, and several
# Flutter plugins that introspect classes at runtime.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes SourceFile,LineNumberTable
-keepattributes Exceptions


# -----------------------------------------------------------------------------
# Kotlin / kotlinx
# -----------------------------------------------------------------------------
# Kotlin metadata is required for reflection on data classes and sealed
# hierarchies. Coroutines internals reference some classes only via reflection.
-keep class kotlin.Metadata { *; }
-keep class kotlin.reflect.** { *; }
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
-dontwarn kotlinx.**
-dontwarn kotlin.**


# -----------------------------------------------------------------------------
# AndroidX Print framework (used by `printing` plugin)
# -----------------------------------------------------------------------------
# The `printing` plugin invokes androidx.print classes via the Android print
# manager. They must survive shrinking even though no Dart-side code references
# them directly.
-keep class androidx.print.** { *; }
-dontwarn androidx.print.**


# -----------------------------------------------------------------------------
# pdf / printing plugins
# -----------------------------------------------------------------------------
# The Dart `pdf` package uses some platform classes for font / image decoding
# on Android. Keep the printing plugin's Java side fully.
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**


# -----------------------------------------------------------------------------
# image_picker
# -----------------------------------------------------------------------------
# image_picker_android uses FileProvider + reflection on result intents.
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class androidx.core.content.FileProvider { *; }
-dontwarn io.flutter.plugins.imagepicker.**


# -----------------------------------------------------------------------------
# url_launcher
# -----------------------------------------------------------------------------
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**


# -----------------------------------------------------------------------------
# shared_preferences / package_info_plus / connectivity_plus
# -----------------------------------------------------------------------------
# These plugins are mostly thin JNI shims, but keep their entry points to be
# safe — none of them are large enough that keeping them costs meaningful APK
# size.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.**


# -----------------------------------------------------------------------------
# flutter_secure_storage
# -----------------------------------------------------------------------------
# The Android impl wraps EncryptedSharedPreferences (AndroidX Security crypto),
# which uses Tink internally. Tink relies heavily on reflection.
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**
-dontwarn com.it_nomads.fluttersecurestorage.**


# -----------------------------------------------------------------------------
# flutter_dotenv
# -----------------------------------------------------------------------------
# flutter_dotenv is pure Dart with no Android-side classes, but the .env file
# is bundled as a Flutter asset. No ProGuard rules required, listed here for
# documentation only.


# -----------------------------------------------------------------------------
# OkHttp / http (only relevant if a transitive plugin pulls OkHttp in)
# -----------------------------------------------------------------------------
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**


# -----------------------------------------------------------------------------
# Gson (defensive — included in case any transitive dep uses it)
# -----------------------------------------------------------------------------
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**


# -----------------------------------------------------------------------------
# Suppress noisy warnings from optional Java EE / desugaring classes
# -----------------------------------------------------------------------------
-dontwarn java.lang.invoke.**
-dontwarn javax.lang.model.**
