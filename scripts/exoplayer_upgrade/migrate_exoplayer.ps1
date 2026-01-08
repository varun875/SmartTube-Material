# ExoPlayer Full Migration Script
# This is the main script that orchestrates the entire upgrade process

$ErrorActionPreference = "Stop"

$SCRIPTS_DIR = $PSScriptRoot
$PROJECT_ROOT = "$PSScriptRoot\..\..\"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " ExoPlayer 2.10.6 -> 2.19.1 Migration " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This migration involves the following steps:" -ForegroundColor White
Write-Host ""
Write-Host "Step 1: Download ExoPlayer 2.19.1 source code" -ForegroundColor Yellow
Write-Host "Step 2: Set up module structure" -ForegroundColor Yellow
Write-Host "Step 3: Analyze API changes in your codebase" -ForegroundColor Yellow
Write-Host "Step 4: Apply automatic fixes (where possible)" -ForegroundColor Yellow
Write-Host "Step 5: Manual fixes (requires developer)" -ForegroundColor Yellow
Write-Host ""

Write-Host "Current status:" -ForegroundColor Cyan
Write-Host "  Project root: $PROJECT_ROOT" -ForegroundColor White

$exo219Exists = Test-Path "$PROJECT_ROOT\exoplayer-2.19.1"
$exo210Exists = Test-Path "$PROJECT_ROOT\exoplayer-amzn-2.10.6"

Write-Host "  ExoPlayer 2.19.1: $(if($exo219Exists){'Downloaded'}else{'Not downloaded'})" -ForegroundColor $(if ($exo219Exists) { 'Green' }else { 'Red' })
Write-Host "  ExoPlayer 2.10.6: $(if($exo210Exists){'Present'}else{'Missing'})" -ForegroundColor $(if ($exo210Exists) { 'Green' }else { 'Red' })
Write-Host ""

Write-Host "Select an option:" -ForegroundColor Cyan
Write-Host "  1. Download ExoPlayer 2.19.1" -ForegroundColor White
Write-Host "  2. Set up module structure" -ForegroundColor White
Write-Host "  3. Analyze API changes" -ForegroundColor White
Write-Host "  4. Apply automatic fixes" -ForegroundColor White
Write-Host "  5. Run all steps (1-4)" -ForegroundColor White
Write-Host "  6. Update settings.gradle to use ExoPlayer 2.19.1" -ForegroundColor White
Write-Host "  7. Revert to ExoPlayer 2.10.6" -ForegroundColor White
Write-Host "  0. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter choice (0-7)"

switch ($choice) {
    "1" {
        & "$SCRIPTS_DIR\1_download_exoplayer.ps1"
    }
    "2" {
        & "$SCRIPTS_DIR\2_setup_module_structure.ps1"
    }
    "3" {
        & "$SCRIPTS_DIR\3_analyze_api_changes.ps1"
    }
    "4" {
        & "$SCRIPTS_DIR\4_apply_fixes.ps1"
    }
    "5" {
        Write-Host "Running all steps..." -ForegroundColor Green
        & "$SCRIPTS_DIR\1_download_exoplayer.ps1"
        if ($LASTEXITCODE -eq 0) { & "$SCRIPTS_DIR\2_setup_module_structure.ps1" }
        if ($LASTEXITCODE -eq 0) { & "$SCRIPTS_DIR\3_analyze_api_changes.ps1" }
        if ($LASTEXITCODE -eq 0) { & "$SCRIPTS_DIR\4_apply_fixes.ps1" }
    }
    "6" {
        Write-Host "Updating settings.gradle to use ExoPlayer 2.19.1..." -ForegroundColor Green
        $settingsPath = "$PROJECT_ROOT\settings.gradle"
        $content = Get-Content $settingsPath -Raw
        $content = $content -replace "exoplayer-amzn-2\.10\.6", "exoplayer-2.19.1"
        Set-Content -Path $settingsPath -Value $content
        Write-Host "Updated! Now run: .\gradlew.bat clean :smarttubetv:assembleStbetaDebug" -ForegroundColor Green
    }
    "7" {
        Write-Host "Reverting to ExoPlayer 2.10.6..." -ForegroundColor Yellow
        $settingsPath = "$PROJECT_ROOT\settings.gradle"
        $content = Get-Content $settingsPath -Raw
        $content = $content -replace "exoplayer-2\.19\.1", "exoplayer-amzn-2.10.6"
        Set-Content -Path $settingsPath -Value $content
        Write-Host "Reverted!" -ForegroundColor Green
    }
    "0" {
        Write-Host "Exiting." -ForegroundColor White
        exit 0
    }
    default {
        Write-Host "Invalid choice." -ForegroundColor Red
    }
}
