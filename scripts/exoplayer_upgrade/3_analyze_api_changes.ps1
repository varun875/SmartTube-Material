# ExoPlayer API Changes Analysis Script
# This script analyzes the codebase for ExoPlayer API usage that may need updates

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = "$PSScriptRoot\..\..\"
$COMMON_SRC = "$PROJECT_ROOT\common\src\main\java"
$SMARTTUBETV_SRC = "$PROJECT_ROOT\smarttubetv\src\main\java"
$OUTPUT_FILE = "$PSScriptRoot\api_changes_report.txt"

Write-Host "=== ExoPlayer API Changes Analysis ===" -ForegroundColor Cyan
Write-Host ""

# Known breaking changes between ExoPlayer 2.10.x and 2.19.x
$breakingPatterns = @(
    @{ Pattern = "SimpleExoPlayer"; Replacement = "ExoPlayer.Builder"; Description = "SimpleExoPlayer is deprecated, use ExoPlayer.Builder" }
    @{ Pattern = "DefaultTrackSelector\.Parameters"; Replacement = "TrackSelectionParameters"; Description = "Track selection API changed" }
    @{ Pattern = "ProgressiveMediaSource\.Factory"; Replacement = ""; Description = "Media source factory API changed" }
    @{ Pattern = "DashMediaSource\.Factory"; Replacement = ""; Description = "DASH source factory API changed" }
    @{ Pattern = "HlsMediaSource\.Factory"; Replacement = ""; Description = "HLS source factory API changed" }
    @{ Pattern = "ExtractorsFactory"; Replacement = ""; Description = "Extractors API may have changed" }
    @{ Pattern = "DefaultDataSourceFactory"; Replacement = "DefaultDataSource.Factory"; Description = "Data source factory renamed" }
    @{ Pattern = "DefaultHttpDataSourceFactory"; Replacement = "DefaultHttpDataSource.Factory"; Description = "HTTP data source factory renamed" }
    @{ Pattern = "\.setTrackSelector"; Replacement = ""; Description = "Track selector API changed" }
    @{ Pattern = "MediaSourceFactory"; Replacement = ""; Description = "Media source factory pattern changed" }
    @{ Pattern = "ConcatenatingMediaSource"; Replacement = ""; Description = "Playlist API changed significantly" }
    @{ Pattern = "ClippingMediaSource"; Replacement = ""; Description = "Clipping API may have changed" }
    @{ Pattern = "LoopingMediaSource"; Replacement = ""; Description = "Looping handled differently in 2.19" }
    @{ Pattern = "\.prepare\("; Replacement = ""; Description = "Prepare API changed" }
    @{ Pattern = "PlayerMessage"; Replacement = ""; Description = "Player messaging API changed" }
    @{ Pattern = "Timeline\.Window"; Replacement = ""; Description = "Timeline API may have changed" }
    @{ Pattern = "Format\."; Replacement = ""; Description = "Format class API may have changed" }
)

$report = @()
$report += "ExoPlayer 2.10.6 -> 2.19.1 Migration Report"
$report += "Generated: $(Get-Date)"
$report += "=" * 60
$report += ""

foreach ($srcDir in @($COMMON_SRC, $SMARTTUBETV_SRC)) {
    Write-Host "Scanning: $srcDir" -ForegroundColor Green
    
    $javaFiles = Get-ChildItem -Path $srcDir -Filter "*.java" -Recurse -ErrorAction SilentlyContinue
    
    foreach ($file in $javaFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        $fileIssues = @()
        
        foreach ($pattern in $breakingPatterns) {
            if ($content -match $pattern.Pattern) {
                $matches = [regex]::Matches($content, $pattern.Pattern)
                $fileIssues += "  - $($pattern.Description) (found $($matches.Count) occurrences)"
            }
        }
        
        if ($fileIssues.Count -gt 0) {
            $relativePath = $file.FullName.Replace($PROJECT_ROOT, "")
            $report += "FILE: $relativePath"
            $report += $fileIssues
            $report += ""
        }
    }
}

# Summary
$report += "=" * 60
$report += "SUMMARY OF MAJOR CHANGES REQUIRED:"
$report += ""
$report += "1. SimpleExoPlayer -> ExoPlayer.Builder"
$report += "   The SimpleExoPlayer class is deprecated. Use ExoPlayer.Builder instead."
$report += ""
$report += "2. Data Source Factories"
$report += "   - DefaultDataSourceFactory -> DefaultDataSource.Factory"
$report += "   - DefaultHttpDataSourceFactory -> DefaultHttpDataSource.Factory"
$report += ""
$report += "3. Track Selection"
$report += "   - DefaultTrackSelector.Parameters has new builder pattern"
$report += "   - TrackSelectionParameters is the new preferred class"
$report += ""
$report += "4. Media Sources"
$report += "   - ConcatenatingMediaSource is deprecated for playlists"
$report += "   - Use player.setMediaItems() for playlists"
$report += ""
$report += "5. Prepare API"
$report += "   - player.prepare(mediaSource) -> player.setMediaSource(source); player.prepare()"
$report += ""

$report | Out-File -FilePath $OUTPUT_FILE -Encoding UTF8

Write-Host ""
Write-Host "Analysis complete! Report saved to:" -ForegroundColor Green
Write-Host "  $OUTPUT_FILE" -ForegroundColor Cyan
Write-Host ""
Write-Host "Review the report and run 4_apply_fixes.ps1 to attempt automatic fixes." -ForegroundColor Yellow
