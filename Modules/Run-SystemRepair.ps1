# System Repair Module - Integrates the existing repair script

param(
    [string]$LogFunction = "Write-Host"
)

function Write-NNLog {
    param([string]$Message, [string]$Level = "INFO")
    
    if ($LogFunction -eq "Write-Log" -and (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
        & Write-Log $Message $Level
    } else {
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

Write-NNLog "Starting system repair (CHKDSK, SFC, DISM)..." "INFO"

$drive = $env:SystemDrive
$hasErrors = $false

# CHKDSK
Write-NNLog "Running CHKDSK online scan..." "INFO"
& chkdsk.exe $drive /scan /forceofflinefix
$chkdskExit = $LASTEXITCODE

if ($chkdskExit -eq 10 -or $chkdskExit -eq 50) {
    Write-NNLog "Retrying CHKDSK without performance scan..." "WARNING"
    & chkdsk.exe $drive /scan
    $chkdskExit = $LASTEXITCODE
}

if ($chkdskExit -eq 0 -or $chkdskExit -eq 1 -or $chkdskExit -eq 2) {
    Write-NNLog "CHKDSK completed successfully" "SUCCESS"
} elseif ($chkdskExit -eq 3) {
    Write-NNLog "CHKDSK requires offline repair at next reboot" "WARNING"
    $hasErrors = $true
} else {
    Write-NNLog "CHKDSK completed with warnings (code: $chkdskExit)" "WARNING"
    $hasErrors = $true
}

# SFC First Pass
Write-NNLog "Running System File Checker (First Pass)..." "INFO"
& sfc.exe /scannow
if ($LASTEXITCODE -eq 0) {
    Write-NNLog "SFC first pass completed successfully" "SUCCESS"
} else {
    Write-NNLog "SFC first pass found issues" "WARNING"
    $hasErrors = $true
}

# DISM
Write-NNLog "Running DISM Component Store Repair..." "INFO"
& DISM.exe /Online /Cleanup-Image /RestoreHealth

if ($LASTEXITCODE -eq 87) {
    Write-NNLog "RestoreHealth not supported, running CheckHealth..." "WARNING"
    & DISM.exe /Online /Cleanup-Image /CheckHealth
}

if ($LASTEXITCODE -eq 0) {
    Write-NNLog "DISM completed successfully" "SUCCESS"
} else {
    Write-NNLog "DISM completed with warnings" "WARNING"
    $hasErrors = $true
}

# SFC Second Pass
Write-NNLog "Running System File Checker (Final Pass)..." "INFO"
& sfc.exe /scannow
if ($LASTEXITCODE -eq 0) {
    Write-NNLog "SFC final pass completed successfully" "SUCCESS"
} else {
    Write-NNLog "SFC final pass completed with warnings" "WARNING"
    $hasErrors = $true
}

if ($hasErrors) {
    Write-NNLog "System repair completed with some warnings" "WARNING"
} else {
    Write-NNLog "All system repairs completed successfully" "SUCCESS"
}