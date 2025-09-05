# Comprehensive Debug Script - Tests all modules directly with detailed output
# This bypasses the GUI completely to see what's really happening

param(
    [switch]$SkipDownload
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  NERDY NEIGHBOR DEBUG MODE" -ForegroundColor Cyan
Write-Host "  Testing All Modules Directly" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Create debug directory
$debugPath = Join-Path $env:TEMP "NNTool_Debug_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$logFile = Join-Path $debugPath "debug_output.log"

New-Item -ItemType Directory -Path $debugPath -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $debugPath "Modules") -Force | Out-Null

# Start transcript to capture everything
Start-Transcript -Path $logFile -Force

Write-Host "Debug directory: $debugPath" -ForegroundColor Yellow
Write-Host "Log file: $logFile" -ForegroundColor Yellow
Write-Host ""

if (-not $SkipDownload) {
    # Download fresh modules
    Write-Host "=== DOWNLOADING FRESH MODULES ===" -ForegroundColor Cyan
    
    $files = @(
        @{Name = "Remove-Antivirus.ps1"; Path = "Modules/Remove-Antivirus.ps1"},
        @{Name = "Run-Malwarebytes.ps1"; Path = "Modules/Run-Malwarebytes.ps1"},
        @{Name = "Remove-RemoteTools.ps1"; Path = "Modules/Remove-RemoteTools.ps1"},
        @{Name = "Run-SystemRepair.ps1"; Path = "Modules/Run-SystemRepair.ps1"},
        @{Name = "Run-WindowsUpdate.ps1"; Path = "Modules/Run-WindowsUpdate.ps1"}
    )
    
    $baseUrl = "https://raw.githubusercontent.com/NerdyNeighbor/nntool/main"
    
    foreach ($file in $files) {
        Write-Host "Downloading $($file.Name)..." -NoNewline
        
        $url = "$baseUrl/$($file.Path)"
        $dest = Join-Path $debugPath $file.Path
        
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("Cache-Control", "no-cache")
            $webClient.DownloadFile($url, $dest)
            
            if (Test-Path $dest) {
                $size = (Get-Item $dest).Length
                Write-Host " OK ($size bytes)" -ForegroundColor Green
                
                # Check for known issues in downloaded files
                $content = Get-Content $dest -Raw
                if ($file.Name -eq "Run-Malwarebytes.ps1") {
                    if ($content -like "*exit 1*") {
                        Write-Host "  WARNING: Contains 'exit 1' bug!" -ForegroundColor Red
                    }
                    if ($content -like "*ArgumentList*@()*") {
                        Write-Host "  WARNING: Contains empty ArgumentList bug!" -ForegroundColor Red
                    }
                }
            }
        } catch {
            Write-Host " FAILED: $_" -ForegroundColor Red
        }
    }
    Write-Host ""
}

Set-Location $debugPath

# Test each module
Write-Host "=== TESTING MODULES ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Antivirus Detection
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "[TEST 1] ANTIVIRUS DETECTION MODULE" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor DarkGray
try {
    $avModule = Join-Path $debugPath "Modules\Remove-Antivirus.ps1"
    if (Test-Path $avModule) {
        Write-Host "Running Remove-Antivirus.ps1..." -ForegroundColor Gray
        & $avModule
        Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Gray
    } else {
        Write-Host "Module not found: $avModule" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Malwarebytes
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "[TEST 2] MALWAREBYTES MODULE (Main Focus)" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor DarkGray

# First check if Malwarebytes is installed
Write-Host "Checking Malwarebytes installation..." -ForegroundColor Cyan
$mbamReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*Malwarebytes*" }

if ($mbamReg) {
    Write-Host "✓ Found in registry: $($mbamReg.DisplayName)" -ForegroundColor Green
    Write-Host "  Version: $($mbamReg.DisplayVersion)" -ForegroundColor Gray
    Write-Host "  Install Location: $($mbamReg.InstallLocation)" -ForegroundColor Gray
} else {
    Write-Host "✗ Not found in registry" -ForegroundColor Red
}

# Check for executables
Write-Host "Checking for Malwarebytes executables..." -ForegroundColor Cyan
$mbamPaths = @(
    "${env:ProgramFiles}\Malwarebytes\Anti-Malware\mbam.exe",
    "${env:ProgramFiles(x86)}\Malwarebytes\Anti-Malware\mbam.exe"
)

foreach ($path in $mbamPaths) {
    if (Test-Path $path) {
        Write-Host "✓ Found executable: $path" -ForegroundColor Green
        $fileInfo = Get-Item $path
        Write-Host "  File version: $($fileInfo.VersionInfo.FileVersion)" -ForegroundColor Gray
        Write-Host "  File size: $($fileInfo.Length) bytes" -ForegroundColor Gray
    } else {
        Write-Host "✗ Not found: $path" -ForegroundColor Gray
    }
}

# Now run the module
Write-Host ""
Write-Host "Running Malwarebytes module..." -ForegroundColor Cyan
Write-Host "Expected behavior: Should launch Malwarebytes GUI and monitor scan" -ForegroundColor Gray

try {
    $mbamModule = Join-Path $debugPath "Modules\Run-Malwarebytes.ps1"
    if (Test-Path $mbamModule) {
        # Check the module content first
        Write-Host "Module file: $mbamModule" -ForegroundColor Gray
        $moduleContent = Get-Content $mbamModule -Raw
        
        # Check for known bugs
        Write-Host "Module checks:" -ForegroundColor Gray
        if ($moduleContent -like "*exit 1*") {
            Write-Host "  ✗ BUG FOUND: Contains 'exit 1' - will terminate early!" -ForegroundColor Red
            $exitLine = ($moduleContent -split "`n" | Select-String "exit 1" | Select-Object -First 1)
            Write-Host "    Line: $exitLine" -ForegroundColor Red
        } else {
            Write-Host "  ✓ No 'exit 1' found" -ForegroundColor Green
        }
        
        if ($moduleContent -like "*ArgumentList*@()*") {
            Write-Host "  ✗ BUG FOUND: Empty ArgumentList array!" -ForegroundColor Red
        } else {
            Write-Host "  ✓ ArgumentList issue not found" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "=== MODULE OUTPUT START ===" -ForegroundColor Magenta
        
        # Run with error capture
        $Error.Clear()
        & $mbamModule
        
        Write-Host "=== MODULE OUTPUT END ===" -ForegroundColor Magenta
        Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Gray
        
        if ($Error.Count -gt 0) {
            Write-Host "Errors occurred:" -ForegroundColor Red
            foreach ($err in $Error) {
                Write-Host "  $err" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Module not found: $mbamModule" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Remote Tools Detection  
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "[TEST 3] REMOTE TOOLS DETECTION" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor DarkGray
try {
    $rtModule = Join-Path $debugPath "Modules\Remove-RemoteTools.ps1"
    if (Test-Path $rtModule) {
        Write-Host "Running Remove-RemoteTools.ps1..." -ForegroundColor Gray
        & $rtModule
        Write-Host "Exit code: $LASTEXITCODE" -ForegroundColor Gray
    } else {
        Write-Host "Module not found: $rtModule" -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  DEBUG COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

Stop-Transcript

Write-Host ""
Write-Host "Debug output saved to:" -ForegroundColor Green
Write-Host $logFile -ForegroundColor Yellow
Write-Host ""
Write-Host "Please share the contents of this log file!" -ForegroundColor Cyan
Write-Host ""

# Open the log file
Write-Host "Opening log file..." -ForegroundColor Gray
notepad.exe $logFile

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")