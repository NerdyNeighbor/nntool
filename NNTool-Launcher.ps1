# Nerdy Neighbor Tool Web Launcher
# This script downloads and runs the NNTool suite
# Usage: iwr -useb https://nntool.nerdyneighbor.net | iex

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Check for admin
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host "     ADMINISTRATOR RIGHTS REQUIRED" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run PowerShell as Administrator and try again:" -ForegroundColor Yellow
    Write-Host "iwr -useb https://nntool.nerdyneighbor.net | iex" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "     NERDY NEIGHBOR SYSTEM TOOL" -ForegroundColor Cyan
Write-Host "      Professional IT Services" -ForegroundColor DarkCyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Preparing to download components..." -ForegroundColor Yellow

# Create temp directory for NNTool
$nnToolPath = Join-Path $env:TEMP "NNTool_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $nnToolPath -Force | Out-Null
Set-Location $nnToolPath

Write-Host "Download location: $nnToolPath" -ForegroundColor Gray
Write-Host ""

# GitHub repository info (update with your actual repo)
$baseUrl = "https://raw.githubusercontent.com/YOUR_GITHUB_USERNAME/nntool/main"

# Alternative: Use your own server
# $baseUrl = "https://tools.nerdyneighbor.net/nntool"

# Download all components
$files = @(
    @{Name = "NNTool-Main.ps1"; Path = "NNTool-Main.ps1"},
    @{Name = "Remove-Antivirus.ps1"; Path = "Modules/Remove-Antivirus.ps1"},
    @{Name = "Run-Malwarebytes.ps1"; Path = "Modules/Run-Malwarebytes.ps1"},
    @{Name = "Remove-RemoteTools.ps1"; Path = "Modules/Remove-RemoteTools.ps1"},
    @{Name = "Run-SystemRepair.ps1"; Path = "Modules/Run-SystemRepair.ps1"},
    @{Name = "Run-WindowsUpdate.ps1"; Path = "Modules/Run-WindowsUpdate.ps1"}
)

# Create Modules directory
New-Item -ItemType Directory -Path (Join-Path $nnToolPath "Modules") -Force | Out-Null

$downloadErrors = @()

foreach ($file in $files) {
    Write-Host "Downloading $($file.Name)..." -ForegroundColor Gray -NoNewline
    
    try {
        $url = "$baseUrl/$($file.Path)"
        $destination = Join-Path $nnToolPath $file.Path
        
        Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing -ErrorAction Stop
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        Write-Host " [FAILED]" -ForegroundColor Red
        $downloadErrors += $file.Name
    }
}

if ($downloadErrors.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed to download some components:" -ForegroundColor Red
    foreach ($error in $downloadErrors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Using fallback embedded version..." -ForegroundColor Yellow
    
    # Fallback: Embed a simplified version
    $fallbackScript = @'
# Simplified NNTool for direct execution
Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = "Nerdy Neighbor Quick Tool"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.Text = "Select maintenance tasks:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Size = New-Object System.Drawing.Size(460, 20)

$listBox = New-Object System.Windows.Forms.CheckedListBox
$listBox.Location = New-Object System.Drawing.Point(20, 50)
$listBox.Size = New-Object System.Drawing.Size(460, 200)

$tasks = @(
    "Remove Third-Party Antivirus",
    "Check for Remote Access Tools",
    "Run System Repairs (SFC/DISM)",
    "Run CHKDSK",
    "Check Windows Updates"
)

foreach ($task in $tasks) {
    $listBox.Items.Add($task, $true) | Out-Null
}

$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = "Run Selected Tasks"
$runButton.Location = New-Object System.Drawing.Point(20, 270)
$runButton.Size = New-Object System.Drawing.Size(150, 30)
$runButton.Add_Click({
    $form.Hide()
    
    Write-Host "`n=== Starting Maintenance Tasks ===" -ForegroundColor Cyan
    
    foreach ($i in 0..($listBox.Items.Count - 1)) {
        if ($listBox.GetItemChecked($i)) {
            $task = $listBox.Items[$i]
            Write-Host "`nRunning: $task" -ForegroundColor Yellow
            
            switch ($task) {
                "Remove Third-Party Antivirus" {
                    # Basic AV removal
                    Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct | 
                        Where-Object {$_.displayName -notlike "*Windows Defender*"} | 
                        ForEach-Object { Write-Host "Found: $($_.displayName) - Manual removal required" -ForegroundColor Yellow }
                }
                "Check for Remote Access Tools" {
                    # Check for common remote tools
                    @("TeamViewer", "AnyDesk", "ScreenConnect", "LogMeIn") | ForEach-Object {
                        $proc = Get-Process "*$_*" -ErrorAction SilentlyContinue
                        if ($proc) { 
                            Write-Host "WARNING: Found $_" -ForegroundColor Red 
                            $proc | Stop-Process -Force
                        }
                    }
                }
                "Run System Repairs (SFC/DISM)" {
                    Write-Host "Running SFC..." -ForegroundColor Gray
                    sfc /scannow
                    Write-Host "Running DISM..." -ForegroundColor Gray
                    DISM /Online /Cleanup-Image /RestoreHealth
                }
                "Run CHKDSK" {
                    chkdsk $env:SystemDrive /scan
                }
                "Check Windows Updates" {
                    Write-Host "Opening Windows Update..." -ForegroundColor Gray
                    Start-Process "ms-settings:windowsupdate"
                }
            }
        }
    }
    
    Write-Host "`n=== Maintenance Complete ===" -ForegroundColor Green
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $form.Close()
})

$form.Controls.AddRange(@($label, $listBox, $runButton))
$form.ShowDialog() | Out-Null
'@
    
    # Save and run the fallback script
    $fallbackPath = Join-Path $nnToolPath "NNTool-Fallback.ps1"
    $fallbackScript | Out-File -FilePath $fallbackPath -Encoding UTF8
    
    Write-Host "Starting fallback tool..." -ForegroundColor Yellow
    & $fallbackPath
    
} else {
    Write-Host ""
    Write-Host "All components downloaded successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Starting Nerdy Neighbor Tool..." -ForegroundColor Cyan
    
    # Run the main tool
    & (Join-Path $nnToolPath "NNTool-Main.ps1")
}

# Cleanup on exit (optional)
# Remove-Item $nnToolPath -Recurse -Force -ErrorAction SilentlyContinue