# Nerdy Neighbor System Tool (NNTool)

A comprehensive Windows system maintenance and security tool with GUI interface.

## Features

- **Antivirus Removal**: Automatically detects and removes third-party antivirus software (McAfee, Norton, AVG, Bitdefender, Avast, Kaspersky, etc.)
- **Malware Scanning**: Downloads and runs Malwarebytes with rootkit detection, then auto-uninstalls
- **Remote Access Tool Detection**: Identifies and removes unauthorized remote access software (ScreenConnect, TeamViewer, AnyDesk, etc.)
- **System Repairs**: Runs CHKDSK, SFC /scannow, and DISM repairs
- **Windows Updates**: Automates Windows Update installation
- **Professional Reporting**: Generates HTML reports for customers

## Quick Start

Run this command in PowerShell as Administrator:

```powershell
iwr -useb https://raw.githubusercontent.com/NerdyNeighbor/nntool/main/NNTool-Launcher.ps1 | iex
```

## Components

- `NNTool-Main.ps1` - Main GUI application
- `NNTool-Launcher.ps1` - Web launcher for remote execution
- `Modules/Remove-Antivirus.ps1` - Antivirus removal module
- `Modules/Run-Malwarebytes.ps1` - Malwarebytes automation
- `Modules/Remove-RemoteTools.ps1` - Remote tool detection/removal
- `Modules/Run-SystemRepair.ps1` - System repair module
- `Modules/Run-WindowsUpdate.ps1` - Windows Update module

## Requirements

- Windows 10/11
- PowerShell 5.0 or higher
- Administrator privileges
- Internet connection

## License

Property of Nerdy Neighbor - Professional IT Services

## Support

For support, contact: nerdyneighboraz@gmail.com