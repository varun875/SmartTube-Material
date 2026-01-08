# ExoPlayer 2.10.6 -> 2.19.1 Comprehensive Fix Script
# This script applies all necessary fixes for the API migration

param(
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = "$PSScriptRoot\..\..\..\"
$COMMON_SRC = "$PROJECT_ROOT\common\src\main\java"
$SMARTTUBETV_SRC = "$PROJECT_ROOT\smarttubetv\src\main\java"

Write-Host "=== ExoPlayer 2.19.1 Comprehensive Fix Script ===" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN MODE - No files will be modified" -ForegroundColor Yellow
}

# Define all replacements
$replacements = @(
    # Interface rename
    @{ Find = "implements Player.EventListener"; Replace = "implements Player.Listener" }
    @{ Find = "Player.EventListener"; Replace = "Player.Listener" }
    
    # SimpleExoPlayer (still works in 2.19 but deprecated)
    # @{ Find = "SimpleExoPlayer"; Replace = "ExoPlayer" }
    
    # Data source factories
    @{ Find = "DefaultDataSourceFactory"; Replace = "DefaultDataSource.Factory" }
    @{ Find = "DefaultHttpDataSourceFactory"; Replace = "DefaultHttpDataSource.Factory" }
    @{ Find = "new DefaultDataSource.Factory("; Replace = "new DefaultDataSource.Factory(" }
    
    # Discontinuity reason
    @{ Find = "DISCONTINUITY_REASON_PERIOD_TRANSITION"; Replace = "DISCONTINUITY_REASON_AUTO_TRANSITION" }
    
    # stop() method
    @{ Find = ".stop(true)"; Replace = ".stop()" }
    
    # Audio listener methods
    @{ Find = "removeAudioListener"; Replace = "removeAnalyticsListener" }
    @{ Find = "addAudioListener"; Replace = "addAnalyticsListener" }
    
    # FrameworkMediaCrypto removed - use DrmSessionManager without generics
    @{ Find = "DrmSessionManager<FrameworkMediaCrypto>"; Replace = "DrmSessionManager" }
    @{ Find = "import com.google.android.exoplayer2.drm.FrameworkMediaCrypto;"; Replace = "// Removed: FrameworkMediaCrypto no longer exists in ExoPlayer 2.19" }
    
    # CaptionStyleCompat moved to ui package
    @{ Find = "import com.google.android.exoplayer2.ui.CaptionStyleCompat;"; Replace = "import com.google.android.exoplayer2.ui.CaptionStyleCompat;" }
    
    # ExoPlaybackException TYPE_OUT_OF_MEMORY removed
    @{ Find = "ExoPlaybackException.TYPE_OUT_OF_MEMORY"; Replace = "ExoPlaybackException.TYPE_UNEXPECTED" }
    
    # TextOutput onCues method signature changed
    # Need manual fix as it requires structural changes
    
    # Cue constructor changed - needs Builder
    # Need manual fix
    
    # TrackSelector parameter methods
    @{ Find = ".setTunnelingAudioSessionId("; Replace = ".setTunnelingEnabled(true).setPreferredAudioLanguage(" }
)

$totalFiles = 0
$totalChanges = 0

foreach ($srcDir in @($COMMON_SRC, $SMARTTUBETV_SRC)) {
    Write-Host "Scanning: $srcDir" -ForegroundColor Green
    
    $javaFiles = Get-ChildItem -Path $srcDir -Filter "*.java" -Recurse -ErrorAction SilentlyContinue
    
    foreach ($file in $javaFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        $originalContent = $content
        $fileChanges = 0
        
        foreach ($replacement in $replacements) {
            $count = ([regex]::Matches($content, [regex]::Escape($replacement.Find))).Count
            if ($count -gt 0) {
                if (-not $DryRun) {
                    $content = $content -replace [regex]::Escape($replacement.Find), $replacement.Replace
                }
                $fileChanges += $count
                Write-Host "  $($file.Name): '$($replacement.Find)' -> '$($replacement.Replace)' ($count)" -ForegroundColor Cyan
            }
        }
        
        if ($fileChanges -gt 0) {
            if (-not $DryRun) {
                Set-Content -Path $file.FullName -Value $content -NoNewline
            }
            $totalFiles++
            $totalChanges += $fileChanges
        }
    }
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "Summary:" -ForegroundColor Green
Write-Host "  Files modified: $totalFiles" -ForegroundColor Cyan
Write-Host "  Total replacements: $totalChanges" -ForegroundColor Cyan
Write-Host ""
Write-Host "Additional manual fixes required:" -ForegroundColor Yellow
Write-Host "  1. TextOutput.onCues(List<Cue>) -> onCues(CueGroup)" -ForegroundColor White
Write-Host "  2. new Cue(text) -> new Cue.Builder().setText(text).build()" -ForegroundColor White
Write-Host "  3. Update TrackSelector tunneling to new API" -ForegroundColor White
Write-Host "  4. VolumeBooster AudioListener -> AnalyticsListener" -ForegroundColor White
Write-Host "  5. MediaSource.createMediaSource(Uri) -> createMediaSource(MediaItem.fromUri(uri))" -ForegroundColor White
