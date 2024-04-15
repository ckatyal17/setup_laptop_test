# Function to install Slack and Chime.
function Install-Application {
    param (
        [string]$AppName
    )

    try {
        # Check if application is already installed
        Write-Host "##################################`nInstalling $AppName`n##################################" -ForegroundColor Blue
        $installedApp = Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object { $_.Name -like $AppName }
        if ($installedApp.InstallState -eq 'Installed') {
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
                    Start-Sleep -Seconds 45
                    Write-Host "$AppName installed successfully." -ForegroundColor Green
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

# Install Chime
Install-Application -AppName 'Amazon Chime 5'

# Install Slack
Install-Application -AppName 'Slack'
