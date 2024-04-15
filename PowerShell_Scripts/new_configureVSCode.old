 <#
.SYNOPSIS
    Checks if Visual Studio Code (VSCode) is installed and installs it if not.

.DESCRIPTION
    This script checks if Visual Studio Code (VSCode) is installed on the system. If it's not installed, it downloads and installs VSCode.
    It also installs specific extensions for VSCode.

.NOTES
    - Ensure to install Daily Midway Setup from software center.
    - Ensure that you have appropriate permissions to install software on the system.
    - This script assumes that PowerShell 5.1 or later is being used.

.LINK
    Script Source: https://github.com/your-username/your-repo

#>


## Function to install VSCode extensions
function Install-VSCodeExtensions {
    param (
        [string[]]$extensions
    )

    try {
        foreach ($extension in $extensions) {
            & $codeExePath --install-extension $extension --force
        }
        Write-Host "Extensions installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Error occurred while installing extensions: $_" -ForegroundColor Red
    }
}

$codeExePath = "C:\Program Files\Microsoft VS Code\bin\code.cmd"

## Check if VSCode is installed
$vsCodeInstalled = $null

try {
    $vsCodeVersion = code --version
    if ($vsCodeVersion -eq $null) {
        $vsCodeInstalled = $false
    } else {
        $vsCodeInstalled = $true
    }
}
catch {
    Write-Host "Error occurred while checking VSCode installation: $_" -ForegroundColor Red
    $vsCodeInstalled = $false
}

## Install VSCode if not already installed
if (-not $vsCodeInstalled) {
    Write-Host "VS Code is not installed. Installing VS Code..." -ForegroundColor Blue

    ## Create installation directory
    $installDir = "C:\Amzn-New-Win-Setup\Installer"
    try {
        New-Item -ItemType "directory" -Path $installDir -Force | Out-Null
    }
    catch {
        Write-Host "Error occurred while creating installation directory: $_" -ForegroundColor Red
        exit 1
    }

    ## Install NuGet provider if not already installed
    try {
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue -Force)) {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        }
    }
    catch {
        Write-Host "Error occurred while installing NuGet provider: $_" -ForegroundColor Red
        exit 1
    }

    ## Download and run VSCode installation script
    $vsCodeInstallScript = "https://raw.githubusercontent.com/PowerShell/vscode-powershell/master/scripts/Install-VSCode.ps1"
    try {
        Invoke-WebRequest -Uri $vsCodeInstallScript -OutFile "C:\Amzn-New-Win-Setup\Installer\Install-VSCode.ps1"
        C:\Amzn-New-Win-Setup\Installer\Install-VSCode.ps1
    }
    catch {
        Write-Host "Error occurred while installing VSCode: $_" -ForegroundColor Red
        exit 1
    }

    ## Refresh environment variables to load VSCode
    try {
        [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Microsoft VS Code\bin", "Machine")
    }
    catch {
        Write-Host "Error occurred while setting environment variable: $_" -ForegroundColor Red
        exit 1
    }

    

    ## Install required VSCode extensions
    $requiredExtensions = @(
        "amazonwebservices.aws-toolkit-vscode",
        "docsmsft.docs-yaml",
        "ms-vscode.powershell",
        "ms-vscode-remote.remote-containers",
        "ms-vscode-remote.remote-ssh",
        "ms-vscode-remote.remote-ssh-edit",
        "ms-vscode-remote.vscode-remote-extensionpack"
    )
    Install-VSCodeExtensions -extensions $requiredExtensions
} else {
    Write-Host "VS Code is already installed. Skipping VS Code Installation..." -ForegroundColor Yellow
}
 
