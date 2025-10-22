# Install-Hooks-Simple.ps1
# Simple installation script for Claude Code repository safety hooks
# Usage: .\Install-Hooks-Simple.ps1

$ErrorActionPreference = 'Stop'

Write-Host "Installing Claude Code Repository Safety Hooks..." -ForegroundColor Cyan
Write-Host ""

# Check if we're in a git repository
if (-not (Test-Path ".git")) {
    Write-Host "ERROR: Not a git repository. Run from repository root." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Git repository detected" -ForegroundColor Green

# Check if hooks directory exists
if (-not (Test-Path ".claude\hooks")) {
    Write-Host "ERROR: .claude\hooks directory not found" -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Hooks directory found" -ForegroundColor Green

# Settings path
$settingsPath = ".claude\settings.local.json"

Write-Host "Installing to: $settingsPath" -ForegroundColor Cyan

# Create settings directory if needed
$settingsDir = Split-Path $settingsPath -Parent
if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    Write-Host "[OK] Created directory: $settingsDir" -ForegroundColor Green
}

# Load example configuration
$exampleConfigPath = ".claude\hooks\claude-settings-example.json"
if (-not (Test-Path $exampleConfigPath)) {
    Write-Host "ERROR: Example config not found: $exampleConfigPath" -ForegroundColor Red
    exit 1
}

$exampleConfig = Get-Content $exampleConfigPath -Raw | ConvertFrom-Json

# Check if settings exist
$settingsExist = Test-Path $settingsPath

if ($settingsExist) {
    Write-Host "Settings file exists. Merging with existing..." -ForegroundColor Yellow

    $currentSettings = Get-Content $settingsPath -Raw | ConvertFrom-Json

    # Merge hooks
    if (-not $currentSettings.hooks) {
        $currentSettings | Add-Member -NotePropertyName "hooks" -NotePropertyValue $exampleConfig.hooks -Force
    } else {
        if (-not $currentSettings.hooks.'tool-call-hook') {
            $currentSettings.hooks | Add-Member -NotePropertyName "tool-call-hook" -NotePropertyValue $exampleConfig.hooks.'tool-call-hook' -Force
        } else {
            Write-Host "Appending new hooks to existing configuration..." -ForegroundColor Yellow
            $currentSettings.hooks.'tool-call-hook' += $exampleConfig.hooks.'tool-call-hook'
        }
    }

    # Merge permissions
    if (-not $currentSettings.permissions) {
        $currentSettings | Add-Member -NotePropertyName "permissions" -NotePropertyValue $exampleConfig.permissions -Force
    } else {
        if (-not $currentSettings.permissions.allow) {
            $currentSettings.permissions | Add-Member -NotePropertyName "allow" -NotePropertyValue $exampleConfig.permissions.allow -Force
        } else {
            $currentSettings.permissions.allow += $exampleConfig.permissions.allow
            $currentSettings.permissions.allow = $currentSettings.permissions.allow | Select-Object -Unique
        }
    }

    $settingsToSave = $currentSettings
} else {
    Write-Host "Creating new settings file..." -ForegroundColor Cyan
    $settingsToSave = $exampleConfig
}

# Save settings
$settingsToSave | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "[OK] Settings saved to $settingsPath" -ForegroundColor Green

# Test hook executability
Write-Host ""
Write-Host "Testing hook execution..." -ForegroundColor Cyan

$testPassed = $true

try {
    $null = bash .claude/hooks/pre-commit-validation.sh 2>&1
    Write-Host "[OK] pre-commit-validation.sh is executable" -ForegroundColor Green
} catch {
    Write-Host "[WARN] pre-commit-validation.sh may not be executable" -ForegroundColor Yellow
    $testPassed = $false
}

try {
    $null = bash .claude/hooks/commit-message-validator.sh "test: Sample" 2>&1
    Write-Host "[OK] commit-message-validator.sh is executable" -ForegroundColor Green
} catch {
    Write-Host "[WARN] commit-message-validator.sh may not be executable" -ForegroundColor Yellow
    $testPassed = $false
}

try {
    $null = bash .claude/hooks/branch-protection.sh suggest-workflow 2>&1
    Write-Host "[OK] branch-protection.sh is executable" -ForegroundColor Green
} catch {
    Write-Host "[WARN] branch-protection.sh may not be executable" -ForegroundColor Yellow
    $testPassed = $false
}

if (-not $testPassed) {
    Write-Host ""
    Write-Host "NOTE: Ensure Git Bash is installed for hook execution" -ForegroundColor Yellow
    Write-Host "Download: https://git-scm.com/downloads" -ForegroundColor Yellow
}

# Display summary
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installed Hooks:" -ForegroundColor Cyan
Write-Host "  - Pre-commit validation (secrets, large files, protected branches)"
Write-Host "  - Commit message validation (Conventional Commits + Brookside BI)"
Write-Host "  - Branch protection (force push, branch deletion)"
Write-Host ""
Write-Host "Configuration: $settingsPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Restart Claude Code to apply settings"
Write-Host "  2. Test with: git add . && git commit -m 'test: Sample message'"
Write-Host "  3. Review README: .claude\hooks\README.md"
Write-Host ""
Write-Host "Repository safety hooks are ready!" -ForegroundColor Green
Write-Host ""
