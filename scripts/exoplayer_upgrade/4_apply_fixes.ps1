# ExoPlayer Automatic Fix Script
# This script attempts to apply common fixes for ExoPlayer 2.10.6 -> 2.19.1 migration

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = "$PSScriptRoot\..\..\"
$COMMON_SRC = "$PROJECT_ROOT\common\src\main\java"
$SMARTTUBETV_SRC = "$PROJECT_ROOT\smarttubetv\src\main\java"

Write-Host "=== ExoPlayer Automatic Fix Script ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: This script will modify source files!" -ForegroundColor Red
Write-Host "Make sure you have committed your changes to git first." -ForegroundColor Yellow
Write-Host ""
$response = Read-Host "Continue? (y/n)"
if ($response -ne "y") {
    Write-Host "Aborting." -ForegroundColor Red
    exit 0
}

# Define replacements (simple text replacements)
$replacements = @(
    @{ Find = "DefaultDataSourceFactory"; Replace = "DefaultDataSource.Factory"; Description = "Data source factory" }
    @{ Find = "DefaultHttpDataSourceFactory"; Replace = "DefaultHttpDataSource.Factory"; Description = "HTTP data source factory" }
    @{ Find = "import com.google.android.exoplayer2.SimpleExoPlayer;"; Replace = "import com.google.android.exoplayer2.ExoPlayer;"; Description = "SimpleExoPlayer import" }
)

$fixedFiles = 0
$totalFixes = 0

foreach ($srcDir in @($COMMON_SRC, $SMARTTUBETV_SRC)) {
    Write-Host "Processing: $srcDir" -ForegroundColor Green
    
    $javaFiles = Get-ChildItem -Path $srcDir -Filter "*.java" -Recurse -ErrorAction SilentlyContinue
    
    foreach ($file in $javaFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        
        $originalContent = $content
        $fileChanged = $false
        
        foreach ($replacement in $replacements) {
            if ($content -match [regex]::Escape($replacement.Find)) {
                $content = $content -replace [regex]::Escape($replacement.Find), $replacement.Replace
                Write-Host "  Fixed: $($file.Name) - $($replacement.Description)" -ForegroundColor Cyan
                $fileChanged = $true
                $totalFixes++
            }
        }
        
        if ($fileChanged) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            $fixedFiles++
        }
    }
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "Automatic fixes applied:" -ForegroundColor Green
Write-Host "  Files modified: $fixedFiles" -ForegroundColor Cyan
Write-Host "  Total fixes: $totalFixes" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: Many changes require manual review!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Major manual changes needed:" -ForegroundColor Red
Write-Host "  1. SimpleExoPlayer usage -> ExoPlayer.Builder pattern" -ForegroundColor White
Write-Host "  2. Track selector parameter builders" -ForegroundColor White
Write-Host "  3. Media source factory patterns" -ForegroundColor White
Write-Host "  4. ConcatenatingMediaSource -> setMediaItems()" -ForegroundColor White
Write-Host ""
Write-Host "Run 'gradlew :common:compileStbetaDebugJavaWithJavac' to see remaining errors." -ForegroundColor Yellow
