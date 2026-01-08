# Media3 Migration Script for SmartTube
# Migrates from ExoPlayer 2.x to AndroidX Media3
# 
# IMPORTANT: This project uses Amazon's SABR (Streaming ABR) module which
# doesn't exist in Media3. We'll need to keep it as a local module.

param(
    [switch]$DryRun = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = (Get-Item "$PSScriptRoot\..\..").FullName
$MEDIA3_VERSION = "1.2.1"  # Latest stable

Write-Host "=== Media3 Migration for SmartTube ===" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
}

# Package mappings from ExoPlayer to Media3
$PACKAGE_MAPPINGS = @{
    "com.google.android.exoplayer2.ext.cronet"             = "androidx.media3.datasource.cronet"
    "com.google.android.exoplayer2.ext.okhttp"             = "androidx.media3.datasource.okhttp"
    "com.google.android.exoplayer2.ext.leanback"           = "androidx.media3.ui.leanback"
    "com.google.android.exoplayer2.ext.mediasession"       = "androidx.media3.session"
    "com.google.android.exoplayer2.source.dash"            = "androidx.media3.exoplayer.dash"
    "com.google.android.exoplayer2.source.hls"             = "androidx.media3.exoplayer.hls"
    "com.google.android.exoplayer2.source.smoothstreaming" = "androidx.media3.exoplayer.smoothstreaming"
    "com.google.android.exoplayer2.source.rtsp"            = "androidx.media3.exoplayer.rtsp"
    "com.google.android.exoplayer2.source"                 = "androidx.media3.exoplayer.source"
    "com.google.android.exoplayer2.trackselection"         = "androidx.media3.exoplayer.trackselection"
    "com.google.android.exoplayer2.upstream"               = "androidx.media3.datasource"
    "com.google.android.exoplayer2.extractor"              = "androidx.media3.extractor"
    "com.google.android.exoplayer2.decoder"                = "androidx.media3.decoder"
    "com.google.android.exoplayer2.audio"                  = "androidx.media3.exoplayer.audio"
    "com.google.android.exoplayer2.video"                  = "androidx.media3.exoplayer.video"
    "com.google.android.exoplayer2.text"                   = "androidx.media3.common.text"
    "com.google.android.exoplayer2.ui"                     = "androidx.media3.ui"
    "com.google.android.exoplayer2.util"                   = "androidx.media3.common.util"
    "com.google.android.exoplayer2.drm"                    = "androidx.media3.exoplayer.drm"
    "com.google.android.exoplayer2.metadata"               = "androidx.media3.extractor.metadata"
    "com.google.android.exoplayer2"                        = "androidx.media3.exoplayer"
}

# IMPORTANT: Exclude SABR package from migration (Amazon-specific)
$EXCLUDE_PATTERNS = @(
    "com.google.android.exoplayer2.source.sabr"
)

# Class renames
$CLASS_RENAMES = @{
    "SimpleExoPlayer"              = "ExoPlayer"
    "ExtractorMediaSource"         = "ProgressiveMediaSource"
    "DefaultDataSourceFactory"     = "DefaultDataSource.Factory"
    "DefaultHttpDataSourceFactory" = "DefaultHttpDataSource.Factory"
    "OkHttpDataSourceFactory"      = "OkHttpDataSource.Factory"
    "CronetDataSourceFactory"      = "CronetDataSource.Factory"
}

# Dependency mappings for build.gradle
$DEPENDENCY_MAPPINGS = @{
    "com.google.android.exoplayer:exoplayer"              = "androidx.media3:media3-exoplayer:$MEDIA3_VERSION"
    "com.google.android.exoplayer:exoplayer-core"         = "androidx.media3:media3-exoplayer:$MEDIA3_VERSION"
    "com.google.android.exoplayer:exoplayer-dash"         = "androidx.media3:media3-exoplayer-dash:$MEDIA3_VERSION"
    "com.google.android.exoplayer:exoplayer-hls"          = "androidx.media3:media3-exoplayer-hls:$MEDIA3_VERSION"
    "com.google.android.exoplayer:extension-okhttp"       = "androidx.media3:media3-datasource-okhttp:$MEDIA3_VERSION"
    "com.google.android.exoplayer:extension-cronet"       = "androidx.media3:media3-datasource-cronet:$MEDIA3_VERSION"
    "com.google.android.exoplayer:extension-leanback"     = "androidx.media3:media3-ui-leanback:$MEDIA3_VERSION"
    "com.google.android.exoplayer:extension-mediasession" = "androidx.media3:media3-session:$MEDIA3_VERSION"
}

Write-Host "Project root: $PROJECT_ROOT" -ForegroundColor Green
Write-Host ""

# Check for SABR module - this needs special handling
$hasSabr = Test-Path "$PROJECT_ROOT\exoplayer-amzn-2.10.6\library\sabr"
if ($hasSabr) {
    Write-Host "NOTICE: SABR module detected (Amazon-specific streaming)" -ForegroundColor Yellow
    Write-Host "SABR imports will be preserved as they're not part of Media3" -ForegroundColor Yellow
    Write-Host ""
}

# Find all Java/Kotlin files to migrate
$files = Get-ChildItem -Path "$PROJECT_ROOT\common\src" -Include "*.java", "*.kt" -Recurse -ErrorAction SilentlyContinue
$files += Get-ChildItem -Path "$PROJECT_ROOT\smarttubetv\src" -Include "*.java", "*.kt" -Recurse -ErrorAction SilentlyContinue

Write-Host "Found $($files.Count) source files to analyze" -ForegroundColor Cyan

$totalReplacements = 0
$modifiedFiles = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $originalContent = $content
    $fileChanges = 0

    # Skip SABR-specific imports
    $skipFile = $false
    foreach ($exclude in $EXCLUDE_PATTERNS) {
        if ($content -match [regex]::Escape($exclude)) {
            Write-Host "  Skipping (contains SABR): $($file.Name)" -ForegroundColor DarkYellow
            # Don't skip, but preserve SABR lines
            break
        }
    }

    # Apply package mappings (but not for SABR)
    foreach ($old in $PACKAGE_MAPPINGS.Keys) {
        $new = $PACKAGE_MAPPINGS[$old]
        $pattern = [regex]::Escape($old)
        
        # Skip if it's a SABR import  
        if ($content -match "import.*sabr") {
            # Only replace non-SABR imports
            $lines = $content -split "`n"
            $newLines = @()
            foreach ($line in $lines) {
                if ($line -match "sabr") {
                    $newLines += $line
                }
                else {
                    $newLines += ($line -replace $pattern, $new)
                }
            }
            $content = $newLines -join "`n"
        }
        else {
            $matches = [regex]::Matches($content, $pattern)
            if ($matches.Count -gt 0) {
                $content = $content -replace $pattern, $new
                $fileChanges += $matches.Count
            }
        }
    }

    # Apply class renames
    foreach ($old in $CLASS_RENAMES.Keys) {
        $new = $CLASS_RENAMES[$old]
        $pattern = "\b$old\b"
        $matches = [regex]::Matches($content, $pattern)
        if ($matches.Count -gt 0) {
            $content = $content -replace $pattern, $new
            $fileChanges += $matches.Count
        }
    }

    if ($content -ne $originalContent) {
        if (-not $DryRun) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
        }
        Write-Host "  Modified: $($file.Name) ($fileChanges changes)" -ForegroundColor Green
        $modifiedFiles++
        $totalReplacements += $fileChanges
    }
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Migration Summary:" -ForegroundColor Cyan
Write-Host "  Files modified: $modifiedFiles" -ForegroundColor Green
Write-Host "  Total replacements: $totalReplacements" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "  1. Update build.gradle files to use Media3 dependencies" -ForegroundColor White
Write-Host "  2. Compile and fix any remaining API issues" -ForegroundColor White
Write-Host "  3. SABR module will need separate handling" -ForegroundColor White
