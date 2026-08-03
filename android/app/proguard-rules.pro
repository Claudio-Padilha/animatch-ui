# Flutter's deferred-components loader references Play Core split-install
# classes that aren't on the classpath unless dynamic feature delivery is
# used. R8 fails the build with "Missing classes" for these unless silenced.
# See: https://developer.android.com/guide/playcore#playcore-and-r8
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Add plugin-specific -keep rules here if the release verification pass
# (see docs/production-review.md, C-1) finds R8 breaking a native plugin
# bridge (Firebase, Auth0, Google Maps, etc).
