# ExoPlayer 2.19.1 Module Setup Script
# This script sets up the module structure to match the existing project

$ErrorActionPreference = "Stop"

$PROJECT_ROOT = "$PSScriptRoot\..\..\"
$EXOPLAYER_DIR = "$PROJECT_ROOT\exoplayer-2.19.1"
$OLD_EXOPLAYER_DIR = "$PROJECT_ROOT\exoplayer-amzn-2.10.6"

Write-Host "=== ExoPlayer 2.19.1 Module Setup ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $EXOPLAYER_DIR)) {
    Write-Host "ExoPlayer 2.19.1 not found. Run 1_download_exoplayer.ps1 first." -ForegroundColor Red
    exit 1
}

# Copy constants.gradle from old ExoPlayer (contains SDK version configs)
Write-Host "Copying constants.gradle..." -ForegroundColor Green
$oldConstants = Get-Content "$OLD_EXOPLAYER_DIR\constants.gradle" -Raw

# Update version in constants
$newConstants = $oldConstants -replace "releaseVersion = '2\.10\.6'", "releaseVersion = '2.19.1'"
$newConstants = $newConstants -replace "releaseVersionCode = 2010006", "releaseVersionCode = 2019001"

Set-Content -Path "$EXOPLAYER_DIR\constants.gradle" -Value $newConstants

# Copy core_settings.gradle (module configuration)
Write-Host "Copying core_settings.gradle..." -ForegroundColor Green
Copy-Item "$OLD_EXOPLAYER_DIR\core_settings.gradle" "$EXOPLAYER_DIR\core_settings.gradle" -Force

Write-Host ""
Write-Host "Module structure setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Manual steps required:" -ForegroundColor Yellow
Write-Host "  1. Update settings.gradle to point to exoplayer-2.19.1" -ForegroundColor White
Write-Host "  2. Run 3_analyze_api_changes.ps1 to find breaking changes" -ForegroundColor White
