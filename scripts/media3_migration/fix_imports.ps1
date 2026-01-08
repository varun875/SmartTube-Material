# Media3 Advanced Package Migration Script
# Handles complex import patterns for Media3

param(
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"
$PROJECT_ROOT = (Get-Item "$PSScriptRoot\..\..").FullName
$COMMON_SRC = "$PROJECT_ROOT\common\src\main\java"
$SMARTTUBE_SRC = "$PROJECT_ROOT\smarttubetv\src\main\java"

Write-Host "=== Media3 Advanced Migration ===" -ForegroundColor Cyan

# More specific import replacements
$IMPORT_FIXES = @(
    # C constant
    @{ Old = 'import androidx.media3.exoplayer.C;'; New = 'import androidx.media3.common.C;' },
    @{ Old = 'import com.google.android.exoplayer2.C;'; New = 'import androidx.media3.common.C;' },
    
    # Format
    @{ Old = 'import androidx.media3.exoplayer.Format;'; New = 'import androidx.media3.common.Format;' },
    @{ Old = 'import com.google.android.exoplayer2.Format;'; New = 'import androidx.media3.common.Format;' },
    
    # Player
    @{ Old = 'import androidx.media3.exoplayer.Player;'; New = 'import androidx.media3.common.Player;' },
    @{ Old = 'import com.google.android.exoplayer2.Player;'; New = 'import androidx.media3.common.Player;' },
    
    # PlaybackParameters
    @{ Old = 'import androidx.media3.exoplayer.PlaybackParameters;'; New = 'import androidx.media3.common.PlaybackParameters;' },
    
    # MimeTypes
    @{ Old = 'import androidx.media3.exoplayer.util.MimeTypes;'; New = 'import androidx.media3.common.MimeTypes;' },
    @{ Old = 'import com.google.android.exoplayer2.util.MimeTypes;'; New = 'import androidx.media3.common.MimeTypes;' },
    
    # CaptionStyleCompat
    @{ Old = 'import com.google.android.exoplayer2.ui.CaptionStyleCompat;'; New = 'import androidx.media3.ui.CaptionStyleCompat;' },
    
    # TrackGroup
    @{ Old = 'import androidx.media3.exoplayer.source.TrackGroup;'; New = 'import androidx.media3.common.TrackGroup;' },
    @{ Old = 'import com.google.android.exoplayer2.source.TrackGroup;'; New = 'import androidx.media3.common.TrackGroup;' },
    
    # TrackGroupArray - removed in Media3, use Tracks instead
    @{ Old = 'import androidx.media3.exoplayer.source.TrackGroupArray;'; New = '// TrackGroupArray removed in Media3, use Tracks' },
    
    # TrackSelectionArray - removed
    @{ Old = 'import androidx.media3.exoplayer.trackselection.TrackSelectionArray;'; New = '// TrackSelectionArray removed in Media3' },
    
    # ExoPlaybackException -> PlaybackException
    @{ Old = 'import androidx.media3.exoplayer.ExoPlaybackException;'; New = 'import androidx.media3.common.PlaybackException;' },
    @{ Old = 'import com.google.android.exoplayer2.ExoPlaybackException;'; New = 'import androidx.media3.common.PlaybackException;' },
    
    # AudioListener -> Player.Listener
    @{ Old = 'import androidx.media3.exoplayer.audio.AudioListener;'; New = '// AudioListener merged into Player.Listener' },
    
    # DefaultMediaSourceEventListener -> MediaSourceEventListener
    @{ Old = 'import androidx.media3.exoplayer.source.DefaultMediaSourceEventListener;'; New = 'import androidx.media3.exoplayer.source.MediaSourceEventListener;' },
    
    # DRM
    @{ Old = 'import androidx.media3.exoplayer.drm.FrameworkMediaCrypto;'; New = '// FrameworkMediaCrypto removed in Media3' }
)

# Find all Java files
$files = Get-ChildItem -Path $COMMON_SRC, $SMARTTUBE_SRC -Include "*.java" -Recurse -ErrorAction SilentlyContinue

Write-Host "Processing $($files.Count) files..." -ForegroundColor Cyan

$changes = 0
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) { continue }
    
    $original = $content
    
    foreach ($fix in $IMPORT_FIXES) {
        if ($content.Contains($fix.Old)) {
            $content = $content.Replace($fix.Old, $fix.New)
            $changes++
        }
    }
    
    if ($content -ne $original -and -not $DryRun) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "  Fixed: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Applied $changes import fixes" -ForegroundColor Green
