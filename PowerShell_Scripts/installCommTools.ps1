# Function to install applications with error handling
function Install-Application {
    param (
        [string]$AppName
    )

    try {
        # Check if application is already installed
        $installedApp = Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object { $_.Name -like $AppName }
        if ($installedApp) {
            Write-Output "$AppName is already installed."
            return
        }

        # Get application instance
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
            Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -MethodName Install -Arguments $Args
            Write-Output "$AppName installed successfully."
        } else {
            Write-Output "Application instance not found for $AppName."
        }
    } catch {
        Write-Output "Failed to install $AppName: $_"
    }
}

# Install Chime
Install-Application -AppName 'Amazon Chime'

# Install Slack
Install-Application -AppName 'Slack'
