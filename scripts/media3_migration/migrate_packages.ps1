# Media3 Package Migration Script
# Replaces ExoPlayer imports with Media3 equivalents

param(
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"
$PROJECT_ROOT = (Get-Item "$PSScriptRoot\..\..").FullName
$COMMON_SRC = "$PROJECT_ROOT\common\src\main\java"
$SMARTTUBE_SRC = "$PROJECT_ROOT\smarttubetv\src\main\java"

Write-Host "=== Media3 Package Migration ===" -ForegroundColor Cyan
Write-Host "Project: $PROJECT_ROOT" -ForegroundColor Green

if ($DryRun) {
    Write-Host "DRY RUN MODE" -ForegroundColor Yellow
}

# Core package mappings (order matters - more specific patterns first)
$REPLACEMENTS = @(
    # Extensions/Datasources
    @{ Old = 'com.google.android.exoplayer2.ext.cronet'; New = 'androidx.media3.datasource.cronet' },
    @{ Old = 'com.google.android.exoplayer2.ext.okhttp'; New = 'androidx.media3.datasource.okhttp' },
    @{ Old = 'com.google.android.exoplayer2.ext.leanback'; New = 'androidx.media3.ui.leanback' },
    @{ Old = 'com.google.android.exoplayer2.ext.mediasession'; New = 'androidx.media3.session' },
    
    # Source formats
    @{ Old = 'com.google.android.exoplayer2.source.dash'; New = 'androidx.media3.exoplayer.dash' },
    @{ Old = 'com.google.android.exoplayer2.source.hls'; New = 'androidx.media3.exoplayer.hls' },
    @{ Old = 'com.google.android.exoplayer2.source.smoothstreaming'; New = 'androidx.media3.exoplayer.smoothstreaming' },
    @{ Old = 'com.google.android.exoplayer2.source.rtsp'; New = 'androidx.media3.exoplayer.rtsp' },
    @{ Old = 'com.google.android.exoplayer2.source'; New = 'androidx.media3.exoplayer.source' },
    
    # Upstream (datasource)  
    @{ Old = 'com.google.android.exoplayer2.upstream'; New = 'androidx.media3.datasource' },
    
    # Track selection
    @{ Old = 'com.google.android.exoplayer2.trackselection'; New = 'androidx.media3.exoplayer.trackselection' },
    
    # Audio/Video
    @{ Old = 'com.google.android.exoplayer2.audio'; New = 'androidx.media3.exoplayer.audio' },
    @{ Old = 'com.google.android.exoplayer2.video'; New = 'androidx.media3.exoplayer.video' },
    
    # Other modules
    @{ Old = 'com.google.android.exoplayer2.extractor'; New = 'androidx.media3.extractor' },
    @{ Old = 'com.google.android.exoplayer2.decoder'; New = 'androidx.media3.decoder' },
    @{ Old = 'com.google.android.exoplayer2.drm'; New = 'androidx.media3.exoplayer.drm' },
    @{ Old = 'com.google.android.exoplayer2.metadata'; New = 'androidx.media3.extractor.metadata' },
    @{ Old = 'com.google.android.exoplayer2.text'; New = 'androidx.media3.common.text' },
    @{ Old = 'com.google.android.exoplayer2.ui'; New = 'androidx.media3.ui' },
    @{ Old = 'com.google.android.exoplayer2.util'; New = 'androidx.media3.common.util' },
    
    # Base exoplayer package (must be last!)
    @{ Old = 'com.google.android.exoplayer2'; New = 'androidx.media3.exoplayer' }
)

# Class renames
$CLASS_RENAMES = @(
    @{ Old = 'SimpleExoPlayer'; New = 'ExoPlayer' },
    @{ Old = 'ExoPlayerFactory'; New = 'ExoPlayer.Builder' },
    @{ Old = 'DefaultMediaSourceEventListener'; New = 'MediaSourceEventListener' },
    @{ Old = 'ExtractorMediaSource'; New = 'ProgressiveMediaSource' },
    @{ Old = 'DefaultDataSourceFactory'; New = 'DefaultDataSource.Factory' },
    @{ Old = 'DefaultHttpDataSourceFactory'; New = 'DefaultHttpDataSource.Factory' },
    @{ Old = 'OkHttpDataSourceFactory'; New = 'OkHttpDataSource.Factory' },
    @{ Old = 'CronetDataSourceFactory'; New = 'CronetDataSource.Factory' },
    @{ Old = 'FrameworkMediaCrypto'; New = 'ExoMediaDrm' },
    @{ Old = 'AudioListener'; New = 'Player.Listener' },
    @{ Old = 'Player.EventListener'; New = 'Player.Listener' }
)

# Find all Java files
$files = Get-ChildItem -Path $COMMON_SRC, $SMARTTUBE_SRC -Include "*.java" -Recurse -ErrorAction SilentlyContinue

Write-Host "Found $($files.Count) Java files" -ForegroundColor Cyan

$totalChanges = 0
$modifiedFiles = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $original = $content
    $fileChanges = 0
    
    # Apply package replacements
    foreach ($r in $REPLACEMENTS) {
        $pattern = [regex]::Escape($r.Old)
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $r.New
            $fileChanges++
        }
    }
    
    # Apply class renames
    foreach ($r in $CLASS_RENAMES) {
        $pattern = "\b$($r.Old)\b"
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $r.New
            $fileChanges++
        }
    }
    
    if ($content -ne $original) {
        $modifiedFiles++
        $totalChanges += $fileChanges
        Write-Host "  $($file.Name) - $fileChanges changes" -ForegroundColor Green
        
        if (-not $DryRun) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
        }
    }
}

Write-Host ""
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "Migration Complete!" -ForegroundColor Green
Write-Host "  Files modified: $modifiedFiles" -ForegroundColor White
Write-Host "  Total changes: $totalChanges" -ForegroundColor White
Write-Host ""
Write-Host "Next: Run gradle build to check for remaining issues" -ForegroundColor Yellow
