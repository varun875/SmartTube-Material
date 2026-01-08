# ExoPlayer 2.19.1 Migration Guide

This directory contains PowerShell scripts to help migrate from ExoPlayer 2.10.6 to 2.19.1.

## Quick Start

```powershell
cd scripts\exoplayer_upgrade
.\migrate_exoplayer.ps1
```

## Scripts

| Script | Description |
|--------|-------------|
| `migrate_exoplayer.ps1` | Main menu script - start here |
| `1_download_exoplayer.ps1` | Downloads ExoPlayer 2.19.1 source from GitHub |
| `2_setup_module_structure.ps1` | Sets up the module to match existing project structure |
| `3_analyze_api_changes.ps1` | Analyzes codebase for breaking API changes |
| `4_apply_fixes.ps1` | Applies automatic fixes for simple API changes |

## Migration Complexity

⚠️ **This is a COMPLEX migration** because:

1. **9 major versions apart** (2.10 → 2.19)
2. **API Breaking Changes** including:
   - `SimpleExoPlayer` → `ExoPlayer.Builder`
   - Data source factory patterns changed
   - Track selection API redesigned
   - Playlist handling completely different
   - Many class renames and package moves

3. **Custom Amazon modifications** in the 2.10.6 fork may not apply to 2.19.1

## Estimated Effort

- **Automatic fixes**: ~10% of changes
- **Manual code changes**: ~90% of changes
- **Testing**: Significant (playback, track selection, buffering, etc.)

## Alternative Approach

Instead of upgrading the local ExoPlayer source, consider:

1. **Use Maven dependency** (if Amazon-specific features aren't critical):
   ```gradle
   implementation 'com.google.android.exoplayer:exoplayer:2.19.1'
   ```

2. **Stay on 2.10.6** with Cronet enabled (already done) - this provides the major performance benefits without migration risk.

## Key API Changes

### SimpleExoPlayer → ExoPlayer.Builder

```java
// OLD (2.10.6)
SimpleExoPlayer player = new SimpleExoPlayer.Builder(context)
    .setTrackSelector(trackSelector)
    .build();

// NEW (2.19.1)
ExoPlayer player = new ExoPlayer.Builder(context)
    .setTrackSelector(trackSelector)
    .build();
```

### Data Source Factories

```java
// OLD
new DefaultDataSourceFactory(context, userAgent);

// NEW
new DefaultDataSource.Factory(context);
```

### Playlist (ConcatenatingMediaSource)

```java
// OLD
ConcatenatingMediaSource playlist = new ConcatenatingMediaSource();
playlist.addMediaSource(source1);
player.prepare(playlist);

// NEW
List<MediaItem> items = Arrays.asList(item1, item2);
player.setMediaItems(items);
player.prepare();
```
