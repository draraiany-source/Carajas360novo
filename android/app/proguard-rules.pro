# ServiçoConecta — regras de ProGuard/R8 para build de release
# Necessário porque minifyEnabled/shrinkResources estão ativados
# em build.gradle (obrigatório para reduzir o tamanho do AAB/APK
# publicado nas lojas).

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase (Auth, Firestore, Storage, Messaging usam reflection)
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# Modelos de dados serializados via Map (evita ofuscar nomes de
# campos que são lidos por reflection indireta em alguns plugins)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Evita warnings de bibliotecas que usam recursos não presentes no runtime Android
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Play Core / Feature Delivery (Flutter deferred components + R8)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
