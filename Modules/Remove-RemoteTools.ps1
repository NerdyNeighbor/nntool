# Remote Access Tool Detection and Removal Module
# Detects and removes unauthorized remote access software

param(
    [string]$LogFunction = "Write-Host"
)

# Define known remote access tools commonly used by scammers
$RemoteAccessTools = @{
    "ScreenConnect" = @{
        ProcessNames = @("screenconnect*", "connectwisecontrol*", "sc*.exe")
        ServiceNames = @("ScreenConnect*", "ConnectWise*")
        Paths = @(
            "$env:ProgramFiles\ScreenConnect*",
            "$env:ProgramFiles(x86)\ScreenConnect*",
            "$env:ProgramData\ScreenConnect*",
            "$env:TEMP\ScreenConnect*",
            "$env:LocalAppData\Apps\*ScreenConnect*"
        )
        RegistryKeys = @(
            "HKLM:\SOFTWARE\ScreenConnect",
            "HKCU:\SOFTWARE\ScreenConnect"
        )
    }
    "TeamViewer" = @{
        ProcessNames = @("TeamViewer*", "tv_w32*", "tv_x64*")
        ServiceNames = @("TeamViewer*")
        Paths = @(
            "$env:ProgramFiles\TeamViewer*",
            "$env:ProgramFiles(x86)\TeamViewer*",
            "$env:TEMP\TeamViewer*"
        )
        RegistryKeys = @(
            "HKLM:\SOFTWARE\TeamViewer",
            "HKCU:\SOFTWARE\TeamViewer"
        )
    }
    "AnyDesk" = @{
        ProcessNames = @("AnyDesk*")
        ServiceNames = @("AnyDesk*")
        Paths = @(
            "$env:ProgramFiles\AnyDesk*",
            "$env:ProgramFiles(x86)\AnyDesk*",
            "$env:ProgramData\AnyDesk*",
            "$env:LocalAppData\AnyDesk*"
        )
        RegistryKeys = @(
            "HKLM:\SOFTWARE\AnyDesk",
            "HKCU:\SOFTWARE\AnyDesk"
        )
    }
    "LogMeIn" = @{
        ProcessNames = @("LogMeIn*", "LMI*")
        ServiceNames = @("LogMeIn*", "LMI*")
        Paths = @(
            "$env:ProgramFiles\LogMeIn*",
            "$env:ProgramFiles(x86)\LogMeIn*"
        )
        RegistryKeys = @(
            "HKLM:\SOFTWARE\LogMeIn",
            "HKCU:\SOFTWARE\LogMeIn"
        )
    }
    "RemotePC" = @{
        ProcessNames = @("RemotePC*", "RPCService*")
        ServiceNames = @("RemotePC*")
        Paths = @(
            "$env:ProgramFiles\RemotePC*",
            "$env:ProgramFiles(x86)\RemotePC*"
        )
        RegistryKeys = @()
    }
    "Splashtop" = @{
        ProcessNames = @("Splashtop*", "SRService*")
        ServiceNames = @("Splashtop*")
        Paths = @(
            "$env:ProgramFiles\Splashtop*",
            "$env:ProgramFiles(x86)\Splashtop*"
        )
        RegistryKeys = @()
    }
    "Chrome Remote Desktop" = @{
        ProcessNames = @("remoting_host*", "chrome_remote*")
        ServiceNames = @("chromoting", "Chrome Remote Desktop*")
        Paths = @(
            "$env:ProgramFiles\Google\Chrome Remote Desktop*",
            "$env:LocalAppData\Google\Chrome Remote Desktop*"
        )
        RegistryKeys = @()
    }
    "GoToMyPC" = @{
        ProcessNames = @("g2*", "GoToMyPC*")
        ServiceNames = @("GoToMyPC*")
        Paths = @(
            "$env:ProgramFiles\Citrix\GoToMyPC*",
            "$env:ProgramFiles(x86)\Citrix\GoToMyPC*"
        )
        RegistryKeys = @()
    }
    "UltraViewer" = @{
        ProcessNames = @("UltraViewer*")
        ServiceNames = @()
        Paths = @(
            "$env:ProgramFiles\UltraViewer*",
            "$env:TEMP\UltraViewer*",
            "$env:LocalAppData\UltraViewer*"
        )
        RegistryKeys = @()
    }
    "Supremo" = @{
        ProcessNames = @("Supremo*")
        ServiceNames = @("Supremo*")
        Paths = @(
            "$env:ProgramFiles\Supremo*",
            "$env:LocalAppData\Supremo*"
        )
        RegistryKeys = @()
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

function Get-RunningRemoteTools {
    Write-NNLog "Scanning for running remote access tools..." "INFO"
    
    $detected = @()
    
    # Check running processes
    foreach ($tool in $RemoteAccessTools.Keys) {
        foreach ($processPattern in $RemoteAccessTools[$tool].ProcessNames) {
            $processes = Get-Process $processPattern -ErrorAction SilentlyContinue
            
            foreach ($process in $processes) {
                $processPath = try { $process.Path } catch { $null }
                
                $detected += @{
                    Tool = $tool
                    Type = "Process"
                    Name = $process.Name
                    PID = $process.Id
                    Path = $processPath
                }
                
                Write-NNLog "Found process: $($process.Name) (PID: $($process.Id))" "WARNING"
                
                # Check if process is from temp or suspicious location
                if ($processPath) {
                    if ($processPath -like "*\Temp\*" -or 
                        $processPath -like "*\AppData\Local\Temp\*" -or
                        $processPath -like "*\Downloads\*") {
                        Write-NNLog "SUSPICIOUS: Process running from temporary location!" "ERROR"
                    }
                }
            }
        }
    }
    
    # Check Windows services
    foreach ($tool in $RemoteAccessTools.Keys) {
        foreach ($servicePattern in $RemoteAccessTools[$tool].ServiceNames) {
            if ($servicePattern) {
                $services = Get-Service $servicePattern -ErrorAction SilentlyContinue
                
                foreach ($service in $services) {
                    $servicePath = try { 
                        (Get-WmiObject Win32_Service -Filter "Name='$($service.Name)'").PathName 
                    } catch { $null }
                    
                    $detected += @{
                        Tool = $tool
                        Type = "Service"
                        Name = $service.Name
                        Status = $service.Status
                        Path = $servicePath
                    }
                    
                    Write-NNLog "Found service: $($service.Name) (Status: $($service.Status))" "WARNING"
                }
            }
        }
    }
    
    # Check for installations in common paths
    foreach ($tool in $RemoteAccessTools.Keys) {
        foreach ($pathPattern in $RemoteAccessTools[$tool].Paths) {
            $paths = Get-ChildItem -Path $pathPattern -ErrorAction SilentlyContinue
            
            foreach ($path in $paths) {
                if (Test-Path $path.FullName) {
                    $detected += @{
                        Tool = $tool
                        Type = "Installation"
                        Path = $path.FullName
                    }
                    
                    Write-NNLog "Found installation: $($path.FullName)" "WARNING"
                }
            }
        }
    }
    
    # Check registry for persistence
    foreach ($tool in $RemoteAccessTools.Keys) {
        foreach ($regKey in $RemoteAccessTools[$tool].RegistryKeys) {
            if (Test-Path $regKey) {
                $detected += @{
                    Tool = $tool
                    Type = "Registry"
                    Path = $regKey
                }
                
                Write-NNLog "Found registry key: $regKey" "WARNING"
            }
        }
    }
    
    # Check startup locations for unknown remote tools
    $startupPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    )
    
    foreach ($path in $startupPaths) {
        if (Test-Path $path) {
            $entries = Get-ItemProperty $path -ErrorAction SilentlyContinue
            
            $suspiciousKeywords = @("remote", "viewer", "connect", "control", "access", "support", "assist")
            
            foreach ($property in $entries.PSObject.Properties) {
                if ($property.Name -notmatch "^PS") {
                    foreach ($keyword in $suspiciousKeywords) {
                        if ($property.Value -like "*$keyword*" -or $property.Name -like "*$keyword*") {
                            $detected += @{
                                Tool = "Unknown/Suspicious"
                                Type = "Startup"
                                Name = $property.Name
                                Path = $property.Value
                                Location = $path
                            }
                            
                            Write-NNLog "Found suspicious startup entry: $($property.Name)" "WARNING"
                            break
                        }
                    }
                }
            }
        }
    }
    
    return $detected
}

function Remove-RemoteTool {
    param(
        [hashtable]$ToolInfo
    )
    
    Write-NNLog "Removing: $($ToolInfo.Tool) - Type: $($ToolInfo.Type)" "INFO"
    
    $removed = $false
    
    switch ($ToolInfo.Type) {
        "Process" {
            try {
                Stop-Process -Id $ToolInfo.PID -Force -ErrorAction Stop
                Write-NNLog "Terminated process: $($ToolInfo.Name)" "SUCCESS"
                
                # Delete the executable if in temp location
                if ($ToolInfo.Path -and (Test-Path $ToolInfo.Path)) {
                    if ($ToolInfo.Path -like "*\Temp\*" -or $ToolInfo.Path -like "*\Downloads\*") {
                        Remove-Item $ToolInfo.Path -Force -ErrorAction SilentlyContinue
                        Write-NNLog "Deleted executable: $($ToolInfo.Path)" "SUCCESS"
                    }
                }
                
                $removed = $true
            } catch {
                Write-NNLog "Failed to terminate process: $_" "ERROR"
            }
        }
        
        "Service" {
            try {
                Stop-Service -Name $ToolInfo.Name -Force -ErrorAction SilentlyContinue
                Set-Service -Name $ToolInfo.Name -StartupType Disabled -ErrorAction SilentlyContinue
                
                # Delete the service
                & sc.exe delete $ToolInfo.Name 2>$null
                
                Write-NNLog "Removed service: $($ToolInfo.Name)" "SUCCESS"
                
                # Delete service executable if found
                if ($ToolInfo.Path) {
                    $exePath = ($ToolInfo.Path -split '"')[1]
                    if ($exePath -and (Test-Path $exePath)) {
                        Remove-Item $exePath -Force -ErrorAction SilentlyContinue
                        Write-NNLog "Deleted service file: $exePath" "SUCCESS"
                    }
                }
                
                $removed = $true
            } catch {
                Write-NNLog "Failed to remove service: $_" "ERROR"
            }
        }
        
        "Installation" {
            try {
                # First try to uninstall via registry
                $uninstalled = $false
                $uninstallKeys = @(
                    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
                )
                
                foreach ($key in $uninstallKeys) {
                    $programs = Get-ItemProperty $key -ErrorAction SilentlyContinue | 
                        Where-Object { $_.DisplayName -like "*$($ToolInfo.Tool)*" }
                    
                    foreach ($program in $programs) {
                        if ($program.UninstallString) {
                            Write-NNLog "Running uninstaller for $($program.DisplayName)" "INFO"
                            
                            if ($program.UninstallString -like "MsiExec.exe*") {
                                $guid = [regex]::Match($program.UninstallString, '\{[A-F0-9\-]+\}').Value
                                Start-Process -FilePath "msiexec.exe" -ArgumentList "/x", $guid, "/qn" -Wait -NoNewWindow
                            } else {
                                Start-Process -FilePath $program.UninstallString -ArgumentList "/S", "/SILENT" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                            }
                            
                            $uninstalled = $true
                            break
                        }
                    }
                }
                
                # Force delete the folder
                if (Test-Path $ToolInfo.Path) {
                    Remove-Item $ToolInfo.Path -Recurse -Force -ErrorAction SilentlyContinue
                    Write-NNLog "Deleted installation folder: $($ToolInfo.Path)" "SUCCESS"
                }
                
                $removed = $true
            } catch {
                Write-NNLog "Failed to remove installation: $_" "ERROR"
            }
        }
        
        "Registry" {
            try {
                Remove-Item $ToolInfo.Path -Recurse -Force -ErrorAction Stop
                Write-NNLog "Removed registry key: $($ToolInfo.Path)" "SUCCESS"
                $removed = $true
            } catch {
                Write-NNLog "Failed to remove registry key: $_" "ERROR"
            }
        }
        
        "Startup" {
            try {
                Remove-ItemProperty -Path $ToolInfo.Location -Name $ToolInfo.Name -Force -ErrorAction Stop
                Write-NNLog "Removed startup entry: $($ToolInfo.Name)" "SUCCESS"
                $removed = $true
            } catch {
                Write-NNLog "Failed to remove startup entry: $_" "ERROR"
            }
        }
    }
    
    return $removed
}

# Main execution
Write-NNLog "Starting remote access tool detection and removal..." "INFO"

$detectedTools = Get-RunningRemoteTools

if ($detectedTools.Count -eq 0) {
    Write-NNLog "No remote access tools detected" "SUCCESS"
} else {
    Write-NNLog "Found $($detectedTools.Count) remote access tool instance(s)" "WARNING"
    
    # Group by tool for summary
    $toolSummary = $detectedTools | Group-Object -Property Tool
    
    Write-NNLog "Summary of detected tools:" "INFO"
    foreach ($group in $toolSummary) {
        Write-NNLog "  - $($group.Name): $($group.Count) instance(s)" "WARNING"
    }
    
    # Remove each detected instance
    foreach ($tool in $detectedTools) {
        $success = Remove-RemoteTool -ToolInfo $tool
        
        if ($success) {
            Write-NNLog "Successfully removed: $($tool.Tool) ($($tool.Type))" "SUCCESS"
        } else {
            Write-NNLog "May require manual removal: $($tool.Tool) ($($tool.Type))" "WARNING"
        }
    }
    
    Write-NNLog "Remote access tool removal complete" "INFO"
}

# Final verification scan
Write-NNLog "Running verification scan..." "INFO"
$remainingTools = Get-RunningRemoteTools

if ($remainingTools.Count -gt 0) {
    Write-NNLog "WARNING: Some remote tools may still be present. Manual review recommended." "WARNING"
} else {
    Write-NNLog "Verification complete: System is clean" "SUCCESS"
}