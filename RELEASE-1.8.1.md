# SHAMS 1.8.1 — Play package correction

Play Console requires com.shams.play for the owner's existing app. The release applicationId is now com.shams.play, versionCode 19, versionName 1.8.1. Java namespace remains app.shams.mobile; it is internal and independent of the published application ID.

Dua image provider authority uses the applicationId and runtime getPackageName() so image sharing and wallpaper remain consistent. Signing key is unchanged. Server readiness supports either known package, but verification remains bound to the exact PLAY_PACKAGE_NAME environment value; set this to com.shams.play for this listing. Billing is still disabled until the real store configuration is completed.

This Play package is a different installed Android application from the older sideload app.shams.mobile package. It cannot update that package in place or automatically inherit its local data. Keep the old installation until any desired account backup/restore is completed. Existing SHAMS 1.8 web and legacy APK links remain available.

Upload SHAMS-1.8.1-play.aab, not the old SHAMS-1.8.0.aab. The Play app's signing certificate must also match the Console App integrity configuration.

Reference: https://developer.android.com/build/configure-app-module
