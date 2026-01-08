# ExoPlayer 2.19.1 Download Script
# This script downloads the official ExoPlayer 2.19.1 source code

$ErrorActionPreference = "Stop"

$EXOPLAYER_VERSION = "r2.19.1"
$EXOPLAYER_REPO = "https://github.com/google/ExoPlayer.git"
$TARGET_DIR = "$PSScriptRoot\..\..\exoplayer-2.19.1"
$BACKUP_DIR = "$PSScriptRoot\..\..\exoplayer-amzn-2.10.6-backup"

Write-Host "=== ExoPlayer 2.19.1 Download Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if target already exists
if (Test-Path $TARGET_DIR) {
    Write-Host "Target directory already exists: $TARGET_DIR" -ForegroundColor Yellow
    $response = Read-Host "Delete and re-download? (y/n)"
    if ($response -eq "y") {
        Remove-Item -Recurse -Force $TARGET_DIR
    } else {
        Write-Host "Aborting." -ForegroundColor Red
        exit 1
    }
}

# Clone ExoPlayer repository
Write-Host "Cloning ExoPlayer $EXOPLAYER_VERSION..." -ForegroundColor Green
git clone --depth 1 --branch $EXOPLAYER_VERSION $EXOPLAYER_REPO $TARGET_DIR

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to clone ExoPlayer repository" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "ExoPlayer $EXOPLAYER_VERSION downloaded to: $TARGET_DIR" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run 2_setup_module_structure.ps1 to configure the module" -ForegroundColor White
Write-Host "  2. Run 3_analyze_api_changes.ps1 to find breaking changes" -ForegroundColor White
