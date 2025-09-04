# Windows Update Module
# Installs all available Windows updates

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

Write-NNLog "Starting Windows Update process..." "INFO"

# Check if PSWindowsUpdate module is available
if (!(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Write-NNLog "Installing PSWindowsUpdate module..." "INFO"
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue | Out-Null
        Install-Module -Name PSWindowsUpdate -Force -AllowClobber -ErrorAction Stop
        Import-Module PSWindowsUpdate -Force
        Write-NNLog "PSWindowsUpdate module installed successfully" "SUCCESS"
    } catch {
        Write-NNLog "Could not install PSWindowsUpdate, using Windows Update COM object..." "WARNING"
        
        # Fallback to COM object method
        try {
            $UpdateSession = New-Object -ComObject Microsoft.Update.Session
            $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
            
            Write-NNLog "Searching for updates..." "INFO"
            $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
            
            if ($SearchResult.Updates.Count -eq 0) {
                Write-NNLog "No updates available" "SUCCESS"
            } else {
                Write-NNLog "Found $($SearchResult.Updates.Count) update(s)" "INFO"
                
                $UpdatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
                foreach ($Update in $SearchResult.Updates) {
                    $UpdatesToDownload.Add($Update) | Out-Null
                    Write-NNLog "  - $($Update.Title)" "INFO"
                }
                
                Write-NNLog "Downloading updates..." "INFO"
                $Downloader = $UpdateSession.CreateUpdateDownloader()
                $Downloader.Updates = $UpdatesToDownload
                $DownloadResult = $Downloader.Download()
                
                Write-NNLog "Installing updates..." "INFO"
                $Installer = $UpdateSession.CreateUpdateInstaller()
                $Installer.Updates = $UpdatesToDownload
                $InstallResult = $Installer.Install()
                
                if ($InstallResult.ResultCode -eq 2) {
                    Write-NNLog "Updates installed successfully" "SUCCESS"
                    if ($InstallResult.RebootRequired) {
                        Write-NNLog "Reboot required to complete updates" "WARNING"
                    }
                } else {
                    Write-NNLog "Some updates may have failed" "WARNING"
                }
            }
        } catch {
            Write-NNLog "Error using Windows Update COM: $_" "ERROR"
        }
    }
} else {
    # Use PSWindowsUpdate module
    try {
        Import-Module PSWindowsUpdate -Force
        
        Write-NNLog "Checking for updates..." "INFO"
        $updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot
        
        if ($updates.Count -eq 0) {
            Write-NNLog "No updates available" "SUCCESS"
        } else {
            Write-NNLog "Found $($updates.Count) update(s)" "INFO"
            foreach ($update in $updates) {
                Write-NNLog "  - $($update.Title)" "INFO"
            }
            
            Write-NNLog "Installing updates..." "INFO"
            Install-WindowsUpdate -AcceptAll -IgnoreReboot -ForceInstall | Out-Null
            
            Write-NNLog "Updates installed successfully" "SUCCESS"
            
            # Check if reboot is required
            if (Get-WURebootStatus -Silent) {
                Write-NNLog "Reboot required to complete updates" "WARNING"
            }
        }
    } catch {
        Write-NNLog "Error installing updates: $_" "ERROR"
    }
}

Write-NNLog "Windows Update process complete" "INFO"