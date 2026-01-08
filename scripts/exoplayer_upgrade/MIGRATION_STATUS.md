# ExoPlayer 2.19.1 Migration - Current Status
Updated: 2026-01-08 22:30

## Summary
This migration from ExoPlayer 2.10.6 (Amazon fork) to 2.19.1 is **~50% complete**.

## What's Done ✅
1. Downloaded ExoPlayer 2.19.1 source
2. Configured module settings with namespace support for AGP 8.x
3. Copied SABR module from old fork
4. Updated ExoPlayerController.java for new API:
   - Player.Listener interface
   - New track/error/state callback signatures
5. Updated ExoMediaSourceFactory.java:
   - Updated data source factories
   - Updated media source creation with MediaItem

## Remaining Issues (100 errors)

### High Priority
1. **SABR module** needs to compile first (dependency/API issues)
2. **CaptionStyleCompat** - import path changed to `com.google.android.exoplayer2.ui.CaptionStyleCompat`
3. **DashManifestParser2** - custom class needs porting from old fork
4. **TrackSelectorManager** - uses deprecated track selection APIs

### Medium Priority
5. **VolumeBooster** - AudioListener → AnalyticsListener
6. **SubtitleManager** - TextOutput API changed
7. **TrackErrorFixer** - MediaSourceEventListener interface changed

## Files Modified
- settings.gradle
- exoplayer-2.19.1/core_settings.gradle
- exoplayer-2.19.1/constants.gradle
- exoplayer-2.19.1/common_library_config.gradle
- exoplayer-2.19.1/publish.gradle
- exoplayer-2.19.1/library/sabr/build.gradle
- common/build.gradle
- common/.../ExoPlayerController.java
- common/.../ExoMediaSourceFactory.java

## To Continue the Migration

### Option 1: Complete with more sessions
Run `.\gradlew :common:compileStbetaDebugJavaWithJavac` and fix remaining errors file by file.

### Option 2: Revert to stable
```powershell
# In settings.gradle, change:
gradle.ext.exoplayerRoot = new File(rootDir, './exoplayer-amzn-2.10.6')

# Restore ExoPlayerController.java and ExoMediaSourceFactory.java from git:
git checkout common/src/main/java/com/liskovsoft/smartyoutubetv2/common/exoplayer/controller/ExoPlayerController.java
git checkout common/src/main/java/com/liskovsoft/smartyoutubetv2/common/exoplayer/ExoMediaSourceFactory.java
```

## Recommendation
Due to the complexity (SABR module, 100+ API changes, custom parsers), consider:
1. Staying on ExoPlayer 2.10.6 + Cronet (already working, major perf benefit)
2. Migrating to Media3 instead (Google's modern replacement with migration scripts)
