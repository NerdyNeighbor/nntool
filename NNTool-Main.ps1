# Nerdy Neighbor Comprehensive System Tool
# Main GUI Application with modular functionality
# Version 1.0

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Self-elevate to Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    try {
        Start-Process PowerShell.exe -Verb RunAs -ArgumentList $arguments -WindowStyle Hidden
        exit
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Administrator privileges required!", "Error", "OK", "Error")
        exit 1
    }
}

# Load Windows Forms and Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global Variables
$script:LogPath = Join-Path $env:TEMP "NNTool_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:ReportPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "NNTool_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
$script:CurrentStep = 0
$script:TotalSteps = 6
$script:Errors = @()
$script:Warnings = @()
$script:SuccessActions = @()

# Start Logging
function Start-Logging {
    $script:LogStream = [System.IO.StreamWriter]::new($script:LogPath, $true)
    $script:LogStream.AutoFlush = $true
    Write-Log "=== Nerdy Neighbor Tool Started ===" "INFO"
    Write-Log "Computer: $env:COMPUTERNAME" "INFO"
    Write-Log "User: $env:USERNAME" "INFO"
    Write-Log "OS: $(Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption)" "INFO"
    Write-Log "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
}

# Logging Function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($script:LogStream) {
        $script:LogStream.WriteLine($logMessage)
    }
    
    # Also update GUI if exists
    if ($script:LogTextBox) {
        $script:MainForm.Invoke([Action]{
            $script:LogTextBox.AppendText("[$Level] $Message`r`n")
            $script:LogTextBox.ScrollToCaret()
        })
    }
    
    # Track errors and warnings
    switch ($Level) {
        "ERROR" { $script:Errors += $Message }
        "WARNING" { $script:Warnings += $Message }
        "SUCCESS" { $script:SuccessActions += $Message }
    }
}

# Create Main GUI
function Create-MainGUI {
    $script:MainForm = New-Object System.Windows.Forms.Form
    $script:MainForm.Text = "Nerdy Neighbor System Tool v1.0"
    $script:MainForm.Size = New-Object System.Drawing.Size(900, 700)
    $script:MainForm.StartPosition = "CenterScreen"
    $script:MainForm.FormBorderStyle = "FixedSingle"
    $script:MainForm.MaximizeBox = $false
    $script:MainForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    
    # Title Panel
    $titlePanel = New-Object System.Windows.Forms.Panel
    $titlePanel.Size = New-Object System.Drawing.Size(900, 80)
    $titlePanel.Location = New-Object System.Drawing.Point(0, 0)
    $titlePanel.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "NERDY NEIGHBOR"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 24, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.Location = New-Object System.Drawing.Point(20, 10)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 40)
    
    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = "Comprehensive System Maintenance Tool"
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::White
    $subtitleLabel.Location = New-Object System.Drawing.Point(20, 50)
    $subtitleLabel.Size = New-Object System.Drawing.Size(400, 20)
    
    $titlePanel.Controls.Add($titleLabel)
    $titlePanel.Controls.Add($subtitleLabel)
    
    # Task List Panel
    $taskPanel = New-Object System.Windows.Forms.GroupBox
    $taskPanel.Text = "Maintenance Tasks"
    $taskPanel.Size = New-Object System.Drawing.Size(420, 250)
    $taskPanel.Location = New-Object System.Drawing.Point(20, 100)
    $taskPanel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    
    # Create task checkboxes
    $script:TaskChecks = @{}
    
    $tasks = @(
        "Remove Third-Party Antivirus",
        "Malwarebytes Scan & Clean",
        "Remove Remote Access Tools",
        "Run System Repairs (SFC/DISM)",
        "Windows Updates",
        "Generate Customer Report"
    )
    
    $yPos = 25
    foreach ($task in $tasks) {
        $checkbox = New-Object System.Windows.Forms.CheckBox
        $checkbox.Text = $task
        $checkbox.Location = New-Object System.Drawing.Point(15, $yPos)
        $checkbox.Size = New-Object System.Drawing.Size(390, 25)
        $checkbox.Checked = $true
        $checkbox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $script:TaskChecks[$task] = $checkbox
        $taskPanel.Controls.Add($checkbox)
        $yPos += 35
    }
    
    # Progress Panel
    $progressPanel = New-Object System.Windows.Forms.GroupBox
    $progressPanel.Text = "Progress"
    $progressPanel.Size = New-Object System.Drawing.Size(420, 100)
    $progressPanel.Location = New-Object System.Drawing.Point(460, 100)
    $progressPanel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    
    $script:ProgressBar = New-Object System.Windows.Forms.ProgressBar
    $script:ProgressBar.Location = New-Object System.Drawing.Point(15, 30)
    $script:ProgressBar.Size = New-Object System.Drawing.Size(390, 25)
    $script:ProgressBar.Style = "Continuous"
    
    $script:StatusLabel = New-Object System.Windows.Forms.Label
    $script:StatusLabel.Text = "Ready to start..."
    $script:StatusLabel.Location = New-Object System.Drawing.Point(15, 60)
    $script:StatusLabel.Size = New-Object System.Drawing.Size(390, 25)
    $script:StatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    
    $progressPanel.Controls.Add($script:ProgressBar)
    $progressPanel.Controls.Add($script:StatusLabel)
    
    # System Info Panel
    $infoPanel = New-Object System.Windows.Forms.GroupBox
    $infoPanel.Text = "System Information"
    $infoPanel.Size = New-Object System.Drawing.Size(420, 140)
    $infoPanel.Location = New-Object System.Drawing.Point(460, 210)
    $infoPanel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $computer = Get-WmiObject -Class Win32_ComputerSystem
    
    $infoText = New-Object System.Windows.Forms.TextBox
    $infoText.Multiline = $true
    $infoText.ReadOnly = $true
    $infoText.Location = New-Object System.Drawing.Point(15, 25)
    $infoText.Size = New-Object System.Drawing.Size(390, 100)
    $infoText.Font = New-Object System.Drawing.Font("Consolas", 9)
    $infoText.Text = @"
Computer: $env:COMPUTERNAME
User: $env:USERNAME
OS: $($os.Caption)
Version: $($os.Version)
RAM: $([math]::Round($computer.TotalPhysicalMemory / 1GB, 2)) GB
Last Boot: $($os.ConvertToDateTime($os.LastBootUpTime))
"@
    
    $infoPanel.Controls.Add($infoText)
    
    # Log Panel
    $logPanel = New-Object System.Windows.Forms.GroupBox
    $logPanel.Text = "Activity Log"
    $logPanel.Size = New-Object System.Drawing.Size(860, 200)
    $logPanel.Location = New-Object System.Drawing.Point(20, 360)
    $logPanel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    
    $script:LogTextBox = New-Object System.Windows.Forms.TextBox
    $script:LogTextBox.Multiline = $true
    $script:LogTextBox.ScrollBars = "Vertical"
    $script:LogTextBox.ReadOnly = $true
    $script:LogTextBox.Location = New-Object System.Drawing.Point(15, 25)
    $script:LogTextBox.Size = New-Object System.Drawing.Size(830, 160)
    $script:LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 8)
    $script:LogTextBox.BackColor = [System.Drawing.Color]::Black
    $script:LogTextBox.ForeColor = [System.Drawing.Color]::Lime
    
    $logPanel.Controls.Add($script:LogTextBox)
    
    # Control Buttons
    $script:StartButton = New-Object System.Windows.Forms.Button
    $script:StartButton.Text = "START MAINTENANCE"
    $script:StartButton.Location = New-Object System.Drawing.Point(20, 580)
    $script:StartButton.Size = New-Object System.Drawing.Size(200, 40)
    $script:StartButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $script:StartButton.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
    $script:StartButton.ForeColor = [System.Drawing.Color]::White
    $script:StartButton.FlatStyle = "Flat"
    $script:StartButton.Add_Click({
        Start-Maintenance
    })
    
    $script:ReportButton = New-Object System.Windows.Forms.Button
    $script:ReportButton.Text = "VIEW REPORT"
    $script:ReportButton.Location = New-Object System.Drawing.Point(240, 580)
    $script:ReportButton.Size = New-Object System.Drawing.Size(150, 40)
    $script:ReportButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $script:ReportButton.Enabled = $false
    $script:ReportButton.Add_Click({
        if (Test-Path $script:ReportPath) {
            Start-Process $script:ReportPath
        }
    })
    
    $exitButton = New-Object System.Windows.Forms.Button
    $exitButton.Text = "EXIT"
    $exitButton.Location = New-Object System.Drawing.Point(780, 580)
    $exitButton.Size = New-Object System.Drawing.Size(100, 40)
    $exitButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $exitButton.Add_Click({
        $script:MainForm.Close()
    })
    
    # Add all controls to form
    $script:MainForm.Controls.AddRange(@(
        $titlePanel,
        $taskPanel,
        $progressPanel,
        $infoPanel,
        $logPanel,
        $script:StartButton,
        $script:ReportButton,
        $exitButton
    ))
    
    return $script:MainForm
}

# Main maintenance function
function Start-Maintenance {
    $script:StartButton.Enabled = $false
    $script:CurrentStep = 0
    
    # Create background job for maintenance tasks
    $script:MaintenanceJob = [System.ComponentModel.BackgroundWorker]::new()
    $script:MaintenanceJob.WorkerReportsProgress = $true
    
    $script:MaintenanceJob.Add_DoWork({
        try {
            # Task 1: Remove Third-Party Antivirus
            if ($script:TaskChecks["Remove Third-Party Antivirus"].Checked) {
                Update-Progress "Removing third-party antivirus..." 10
                & "$PSScriptRoot\Modules\Remove-Antivirus.ps1"
            }
            
            # Task 2: Malwarebytes Scan
            if ($script:TaskChecks["Malwarebytes Scan & Clean"].Checked) {
                Update-Progress "Running Malwarebytes scan..." 25
                & "$PSScriptRoot\Modules\Run-Malwarebytes.ps1"
            }
            
            # Task 3: Remove Remote Access Tools
            if ($script:TaskChecks["Remove Remote Access Tools"].Checked) {
                Update-Progress "Checking for remote access tools..." 40
                & "$PSScriptRoot\Modules\Remove-RemoteTools.ps1"
            }
            
            # Task 4: System Repairs
            if ($script:TaskChecks["Run System Repairs (SFC/DISM)"].Checked) {
                Update-Progress "Running system repairs..." 55
                & "$PSScriptRoot\Modules\Run-SystemRepair.ps1"
            }
            
            # Task 5: Windows Updates
            if ($script:TaskChecks["Windows Updates"].Checked) {
                Update-Progress "Installing Windows updates..." 70
                & "$PSScriptRoot\Modules\Run-WindowsUpdate.ps1"
            }
            
            # Task 6: Generate Report
            if ($script:TaskChecks["Generate Customer Report"].Checked) {
                Update-Progress "Generating report..." 90
                Generate-Report
            }
            
            Update-Progress "Maintenance complete!" 100
            Write-Log "All tasks completed successfully" "SUCCESS"
        }
        catch {
            Write-Log "Error during maintenance: $_" "ERROR"
        }
    })
    
    $script:MaintenanceJob.Add_ProgressChanged({
        param($sender, $e)
        $script:ProgressBar.Value = $e.ProgressPercentage
    })
    
    $script:MaintenanceJob.Add_RunWorkerCompleted({
        $script:StartButton.Enabled = $true
        $script:ReportButton.Enabled = $true
        [System.Windows.Forms.MessageBox]::Show("Maintenance completed! Check the report for details.", "Complete", "OK", "Information")
    })
    
    $script:MaintenanceJob.RunWorkerAsync()
}

# Update progress helper
function Update-Progress {
    param(
        [string]$Status,
        [int]$Percentage
    )
    
    $script:MainForm.Invoke([Action]{
        $script:StatusLabel.Text = $Status
        $script:ProgressBar.Value = $Percentage
    })
    
    Write-Log $Status "INFO"
}

# Generate HTML Report
function Generate-Report {
    Write-Log "Generating customer report..." "INFO"
    
    # Build task list HTML separately to avoid encoding issues
    $taskListHtml = ""
    foreach ($task in $script:SuccessActions) {
        $taskListHtml += "<li>&#10004; $task</li>`n"
    }
    
    # Build warnings HTML
    $warningsHtml = ""
    if ($script:Warnings.Count -gt 0) {
        $warningsHtml = "<div class=`"section`"><h2>Warnings</h2><ul>"
        foreach ($warning in $script:Warnings) {
            $warningsHtml += "<li class=`"warning`">&#9888; $warning</li>"
        }
        $warningsHtml += "</ul></div>"
    }
    
    # Build errors HTML  
    $errorsHtml = ""
    if ($script:Errors.Count -gt 0) {
        $errorsHtml = "<div class=`"section`"><h2>Errors Encountered</h2><ul>"
        foreach ($error in $script:Errors) {
            $errorsHtml += "<li class=`"error`">&#10006; $error</li>"
        }
        $errorsHtml += "</ul></div>"
    }
    
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $uptime = (Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $ram = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $summaryText = if ($script:Errors.Count -eq 0) { "All tasks were successful." } else { "Some issues were encountered - please review the errors above." }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Nerdy Neighbor System Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .header { background: #007ACC; color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        .header h1 { margin: 0; font-size: 32px; }
        .header p { margin: 10px 0 0 0; opacity: 0.9; }
        .section { background: white; padding: 25px; border-radius: 10px; margin-bottom: 20px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .section h2 { color: #007ACC; border-bottom: 2px solid #007ACC; padding-bottom: 10px; }
        .info-grid { display: grid; grid-template-columns: 200px 1fr; gap: 10px; }
        .info-label { font-weight: bold; color: #555; }
        .success { color: #4CAF50; font-weight: bold; }
        .warning { color: #FF9800; font-weight: bold; }
        .error { color: #F44336; font-weight: bold; }
        .task-list { list-style: none; padding: 0; }
        .task-list li { padding: 10px; margin: 5px 0; background: #f9f9f9; border-left: 4px solid #4CAF50; }
        .summary-box { background: #E3F2FD; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .footer { text-align: center; color: #666; margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; }
        @media print { body { margin: 20px; } .header { background: white; color: black; border: 2px solid #007ACC; } }
    </style>
</head>
<body>
    <div class="header">
        <h1>NERDY NEIGHBOR</h1>
        <p>System Maintenance Report</p>
        <p style="margin-top: 15px;">Generated: $(Get-Date -Format 'MMMM dd, yyyy - hh:mm tt')</p>
    </div>
    
    <div class="section">
        <h2>System Information</h2>
        <div class="info-grid">
            <div class="info-label">Computer Name:</div>
            <div>$env:COMPUTERNAME</div>
            <div class="info-label">Username:</div>
            <div>$env:USERNAME</div>
            <div class="info-label">Operating System:</div>
            <div>$($os.Caption)</div>
            <div class="info-label">System Uptime:</div>
            <div>$($uptime.Days) days, $($uptime.Hours) hours</div>
            <div class="info-label">Total RAM:</div>
            <div>$ram GB</div>
        </div>
    </div>
    
    <div class="section">
        <h2>Maintenance Tasks Completed</h2>
        <ul class="task-list">
            $taskListHtml
        </ul>
    </div>
    
    $warningsHtml
    $errorsHtml
    
    <div class="summary-box">
        <h3>Summary</h3>
        <p>The system maintenance has been completed. $summaryText</p>
        <p><strong>Recommendations:</strong></p>
        <ul>
            <li>Restart the computer to ensure all changes take effect</li>
            <li>Run Windows Update to check for any remaining updates</li>
            <li>Schedule regular maintenance checks every 3 months</li>
        </ul>
    </div>
    
    <div class="footer">
        <p>Nerdy Neighbor - Professional IT Services</p>
        <p>Log file location: $script:LogPath</p>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $script:ReportPath -Encoding UTF8
    Write-Log "Report generated: $script:ReportPath" "SUCCESS"
}

# Main execution
Start-Logging
$form = Create-MainGUI
$form.ShowDialog() | Out-Null

# Cleanup
if ($script:LogStream) {
    $script:LogStream.Close()
    $script:LogStream.Dispose()
}