# Function to install Visual Studio Code.
function Install-Application {
    param (
        [string]$AppName
    )

    try {
        # Check if application is already installed
        $registryPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        $vsCodeKey = Get-ItemProperty -Path "$registryPath\*" | Where-Object { $_.DisplayName -eq "Microsoft Visual Studio Code" }
        $installedApp = Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object { $_.Name -like $AppName }

        if (($installedApp.InstallState -eq 'Installed') -or $vsCodeKey) {
            Write-Host "$AppName is already installed." -ForegroundColor Yellow
            return
        } else{
            # Attempt to get application instance
            Write-Host "Installing $AppName..." -ForegroundColor Blue
            $app = Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object { $_.Name -like $AppName }

            # Check if application instance is retrieved
            if ($app) {
                $Args = @{
                    EnforcePreference = [UINT32]0
                    Id = "$($app.id)"
                    IsMachineTarget = $app.IsMachineTarget
                    IsRebootIfNeeded = $False
                    Priority = 'High'
                    Revision = "$($app.Revision)" 
                }
            
                # Attempt to install application
                $output = Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -MethodName Install -Arguments $Args
                if ($output.ReturnValue -eq 0) {
                    Start-Sleep -Seconds 60
                    Write-Host "$AppName installed successfully." -ForegroundColor Green
                # Refresh environment variables to load VSCode
                try {
                    [System.Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files\Microsoft VS Code\bin", "Machine")
                }
                catch {
                    Write-Host "Error occurred while setting environment variable: $_" -ForegroundColor Red
                    exit 1
                }
                # Install required VSCode extensions
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
                    Write-Host "Failed to install $AppName : $($output.ReturnValue)" -ForegroundColor Red
                    return
                }
            } else {
                Write-Output "Application instance not found for $AppName."
            }
        }
    } catch {
        Write-Output "Failed to install $AppName : $_"
    }
}

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

# Install Visual Studio Code
Install-Application -AppName 'Visual Studio Code'




    




