# Remove Third-Party Antivirus Module
# Detects and removes all major antivirus products except Windows Defender

param(
    [string]$LogFunction = "Write-Host"
)

# Define known antivirus products with their uninstall info
$AntivirusProducts = @{
    "McAfee" = @{
        DisplayNames = @("McAfee*", "*McAfee*")
        Services = @("McAfee*", "McShield", "McTaskManager", "mcagent", "mcupdmgr")
        Processes = @("mcafee*", "mc*", "McUICnt", "McPvTray")
        RemovalTool = "https://download.mcafee.com/molbin/iss-loc/SupportTools/MCPR/MCPR.exe"
    }
    "Norton" = @{
        DisplayNames = @("Norton*", "Symantec*")
        Services = @("Norton*", "N360*", "Symantec*")
        Processes = @("norton*", "n360*", "symantec*")
        RemovalTool = "https://support.norton.com/sp/static/external/tools/nrnr.exe"
    }
    "Avast" = @{
        DisplayNames = @("Avast*")
        Services = @("avast*", "aswbIDSAgent")
        Processes = @("avast*", "AvastUI")
        RemovalTool = "https://files.avast.com/iavs9x/avastclear.exe"
    }
    "AVG" = @{
        DisplayNames = @("AVG*")
        Services = @("AVG*")
        Processes = @("avg*")
        RemovalTool = "https://files.avg.com/iavs9x/avgclear.exe"
    }
    "Bitdefender" = @{
        DisplayNames = @("Bitdefender*")
        Services = @("Bitdefender*", "VSSERV", "UPDATESRV")
        Processes = @("bitdefender*", "bdagent", "bdwtxag")
        RemovalTool = "https://www.bitdefender.com/uninstall/"
    }
    "Kaspersky" = @{
        DisplayNames = @("Kaspersky*")
        Services = @("AVP*", "klnagent", "KLMS")
        Processes = @("avp*", "kaspersky*", "kav*")
        RemovalTool = "https://media.kaspersky.com/utilities/ConsumerUtilities/kavremvr.exe"
    }
    "Avira" = @{
        DisplayNames = @("Avira*")
        Services = @("Avira*", "AntiVir*")
        Processes = @("avira*", "avgnt", "avcenter")
        RemovalTool = "https://www.avira.com/en/support-download-avira-registry-cleaner"
    }
    "ESET" = @{
        DisplayNames = @("ESET*")
        Services = @("ESET*", "ekrn", "egui")
        Processes = @("eset*", "ekrn", "egui")
        RemovalTool = "https://support.eset.com/en/kb2289-uninstall-eset-manually-using-the-eset-uninstaller-tool"
    }
    "Malwarebytes" = @{
        DisplayNames = @("Malwarebytes*")
        Services = @("MBAMService", "Malwarebytes*")
        Processes = @("mbam*", "malwarebytes*")
        RemovalTool = "https://support.malwarebytes.com/hc/en-us/articles/360039023473"
    }
    "Trend Micro" = @{
        DisplayNames = @("Trend Micro*")
        Services = @("TM*", "Trend*", "ntrtscan", "tmlisten")
        Processes = @("trend*", "tm*", "pccnt*")
        RemovalTool = "https://helpcenter.trendmicro.com/en-us/article/tmka-19738"
    }
}

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

function Get-InstalledAntivirus {
    Write-NNLog "Scanning for installed antivirus products..." "INFO"
    
    $detected = @()
    
    # Method 1: Check WMI for registered antivirus products
    try {
        $wmiAV = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct -ErrorAction SilentlyContinue
        if ($wmiAV) {
            foreach ($av in $wmiAV) {
                if ($av.displayName -notlike "*Windows Defender*" -and $av.displayName -notlike "*Microsoft Defender*") {
                    $detected += @{
                        Name = $av.displayName
                        Method = "WMI"
                        Path = $av.pathToSignedProductExe
                    }
                    Write-NNLog "Found via WMI: $($av.displayName)" "WARNING"
                }
            }
        }
    } catch {
        Write-NNLog "Could not query WMI SecurityCenter2" "WARNING"
    }
    
    # Method 2: Check installed programs
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($avName in $AntivirusProducts.Keys) {
        foreach ($path in $uninstallPaths) {
            $programs = Get-ItemProperty $path -ErrorAction SilentlyContinue
            foreach ($program in $programs) {
                foreach ($pattern in $AntivirusProducts[$avName].DisplayNames) {
                    if ($program.DisplayName -like $pattern) {
                        $detected += @{
                            Name = $program.DisplayName
                            Method = "Registry"
                            UninstallString = $program.UninstallString
                            Publisher = $program.Publisher
                            AVType = $avName
                        }
                        Write-NNLog "Found in registry: $($program.DisplayName)" "WARNING"
                        break
                    }
                }
            }
        }
    }
    
    # Method 3: Check running processes
    foreach ($avName in $AntivirusProducts.Keys) {
        foreach ($processName in $AntivirusProducts[$avName].Processes) {
            $processes = Get-Process $processName -ErrorAction SilentlyContinue
            if ($processes) {
                Write-NNLog "Found $avName process running: $($processes[0].Name)" "WARNING"
                $detected += @{
                    Name = $avName
                    Method = "Process"
                    Process = $processes[0].Name
                    AVType = $avName
                }
                break
            }
        }
    }
    
    # Method 4: Check services
    foreach ($avName in $AntivirusProducts.Keys) {
        foreach ($serviceName in $AntivirusProducts[$avName].Services) {
            $services = Get-Service $serviceName -ErrorAction SilentlyContinue
            if ($services) {
                Write-NNLog "Found $avName service: $($services[0].Name)" "WARNING"
                $detected += @{
                    Name = $avName
                    Method = "Service"
                    Service = $services[0].Name
                    AVType = $avName
                }
                break
            }
        }
    }
    
    return $detected | Sort-Object -Property Name -Unique
}

function Remove-AntivirusProduct {
    param(
        [hashtable]$AVInfo
    )
    
    Write-NNLog "Attempting to remove: $($AVInfo.Name)" "INFO"
    
    $removed = $false
    
    # Try uninstall string first
    if ($AVInfo.UninstallString) {
        Write-NNLog "Using uninstall string..." "INFO"
        try {
            if ($AVInfo.UninstallString -like "MsiExec.exe*") {
                # Extract the GUID and run msiexec with silent parameters
                $guid = [regex]::Match($AVInfo.UninstallString, '\{[A-F0-9\-]+\}').Value
                if ($guid) {
                    Start-Process -FilePath "msiexec.exe" -ArgumentList "/x", $guid, "/qn", "/norestart", "REBOOT=ReallySuppress" -Wait -NoNewWindow
                    $removed = $true
                }
            } else {
                # Try to run the uninstaller with common silent parameters
                $uninstallPath = $AVInfo.UninstallString -replace '"', ''
                if (Test-Path $uninstallPath) {
                    Start-Process -FilePath $uninstallPath -ArgumentList "/S", "/SILENT", "/VERYSILENT", "/quiet", "/qn" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                    $removed = $true
                }
            }
        } catch {
            Write-NNLog "Failed to run uninstaller: $_" "ERROR"
        }
    }
    
    # Stop and disable services
    if ($AVInfo.AVType -and $AntivirusProducts.ContainsKey($AVInfo.AVType)) {
        foreach ($serviceName in $AntivirusProducts[$AVInfo.AVType].Services) {
            $services = Get-Service $serviceName -ErrorAction SilentlyContinue
            foreach ($service in $services) {
                Write-NNLog "Stopping service: $($service.Name)" "INFO"
                try {
                    Stop-Service -Name $service.Name -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $service.Name -StartupType Disabled -ErrorAction SilentlyContinue
                    
                    # Try to delete the service
                    & sc.exe delete $service.Name 2>$null
                } catch {
                    Write-NNLog "Could not stop/disable service: $($service.Name)" "WARNING"
                }
            }
        }
        
        # Kill processes
        foreach ($processName in $AntivirusProducts[$AVInfo.AVType].Processes) {
            $processes = Get-Process $processName -ErrorAction SilentlyContinue
            foreach ($process in $processes) {
                Write-NNLog "Terminating process: $($process.Name)" "INFO"
                try {
                    Stop-Process -Name $process.Name -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-NNLog "Could not terminate process: $($process.Name)" "WARNING"
                }
            }
        }
    }
    
    # Download and run removal tool if standard uninstall failed
    if (-not $removed -and $AVInfo.AVType) {
        $removalTool = $AntivirusProducts[$AVInfo.AVType].RemovalTool
        if ($removalTool) {
            Write-NNLog "Downloading removal tool for $($AVInfo.AVType)..." "INFO"
            try {
                $toolPath = Join-Path $env:TEMP "$($AVInfo.AVType)_Remover.exe"
                Invoke-WebRequest -Uri $removalTool -OutFile $toolPath -UseBasicParsing
                
                if (Test-Path $toolPath) {
                    Write-NNLog "Running removal tool..." "INFO"
                    Start-Process -FilePath $toolPath -ArgumentList "/SILENT", "/S", "/quiet" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                    Remove-Item $toolPath -Force -ErrorAction SilentlyContinue
                    $removed = $true
                }
            } catch {
                Write-NNLog "Could not download/run removal tool: $_" "WARNING"
            }
        }
    }
    
    return $removed
}

# Main execution
Write-NNLog "Starting third-party antivirus removal..." "INFO"

$detectedAV = Get-InstalledAntivirus

if ($detectedAV.Count -eq 0) {
    Write-NNLog "No third-party antivirus products detected" "SUCCESS"
} else {
    Write-NNLog "Found $($detectedAV.Count) antivirus product(s) to remove" "WARNING"
    
    foreach ($av in $detectedAV) {
        $success = Remove-AntivirusProduct -AVInfo $av
        
        if ($success) {
            Write-NNLog "Successfully removed: $($av.Name)" "SUCCESS"
        } else {
            Write-NNLog "May require manual removal or reboot: $($av.Name)" "WARNING"
        }
    }
    
    Write-NNLog "Antivirus removal complete. A reboot is recommended." "INFO"
}

# Enable Windows Defender if it was disabled
Write-NNLog "Ensuring Windows Defender is enabled..." "INFO"
try {
    Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
    Start-Service WinDefend -ErrorAction SilentlyContinue
    Write-NNLog "Windows Defender is active" "SUCCESS"
} catch {
    Write-NNLog "Could not verify Windows Defender status" "WARNING"
}