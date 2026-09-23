# WorkManager ve Startup kütüphanelerinin silinmesini engeller
-keep class androidx.work.** { *; }
-keep class androidx.startup.** { *; }
-keep class androidx.room.** { *; }
-keep class androidx.sqlite.** { *; }
-keep class com.google.android.gms.ads.** { *; }

# Uygulamanın çökmesini engelleyecek genel kurallar
-dontwarn androidx.work.**
-dontwarn androidx.room.**
-dontwarn androidx.sqlite.**