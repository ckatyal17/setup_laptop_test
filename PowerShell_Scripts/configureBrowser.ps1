# Create folder
$installDir = "C:\Amzn-New-Win-Setup\BrowserSetup"
if (-not (Test-Path $installDir -PathType Container)) {
    Write-Host "Creating folder to store browser configuration files..."
    try {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    } catch {
        Write-Host "Failed to create folder: $_"
        return
    }
}

# Check if Firefox is installed
try {
    Write-Output "Checking if Firefox is installed..."

    # Check if Mozilla Firefox is installed in 32-bit registry
    $x86_check = ((Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall") | Where-Object { $_."Name" -like "*Mozilla Firefox*" }).Length -gt 0

    # Check if Mozilla Firefox is installed in 64-bit registry
    $x64_check = ((Get-ChildItem "HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") | Where-Object { $_."Name" -like "*Mozilla*" }).Length -gt 0

    # Check if Mozilla Firefox ESR is installed
    $mozilla = Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object { $_.Name -eq 'Mozilla Firefox ESR' }
    $mozilla32 = Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object { $_.Name -eq 'Mozilla Firefox ESR 32-bit' }

    # Install Mozilla Firefox if not already installed
    if (($x86_check -eq $true) -or ($x64_check -eq $true)) {
        if (($mozilla32.InstallState -eq 'Installed') -or ($mozilla.InstallState -eq 'Installed')) {
            Write-Output "Firefox is installed using Software Center"
        } else {
            Write-Output "Firefox is installed but not using Software center" 
        } 
    } else {
        Write-Output "##################################`nInstalling Mozilla Firefox ESR`n##################################"
        $firefox = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object { $_.Name -eq 'Mozilla Firefox ESR x64' })
        $Args = @{
            EnforcePreference = [UINT32] 0
            Id = "$($firefox.id)"
            IsMachineTarget = $firefox.IsMachineTarget
            IsRebootIfNeeded = $false
            Priority = 'High'
            Revision = "$($firefox.Revision)" 
        }

        $output = Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -MethodName Install -Arguments $Args
        if ($output.ReturnValue -eq 0) {
            Write-Output "Mozilla Firefox installed successfully"
        } else {
            Write-Host "Failed to install Mozilla Firefox: $($output.ReturnValue)"
            return
        }
    }
} catch {
    Write-Output "An error occurred: $_"
    return
}


# Download Certificates
$certificates = @(
    "https://pki.amazon.com/crt/Amazon.com%20Internal%20Root%20Certificate%20Authority.der",
    "https://pki.amazon.com/crt/Amazon.com%20CIA%20CA%20G5%2001.der",
    "https://pki.amazon.com/crt/Amazon.com%20CIA%20CA%20G5%2002.der"
)

foreach ($certUrl in $certificates) {
    $certName = $certUrl.Split('/')[-1]
    $certPath = Join-Path -Path $installDir -ChildPath $certName
    if (-not (Test-Path $certPath)) {
        Write-Host "Downloading certificate: $certName"
        try {
            Invoke-WebRequest -Uri $certUrl -OutFile $certPath -ErrorAction Stop
        } catch {
            Write-Host "Failed to download certificate: $_"
        }
    } else {
        Write-Host "Certificate already exists: $certName"
    }
}

# Install Tampermonkey extension
$registryPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\Extensions\Install"
$tampermonkeyUrl = "https://addons.mozilla.org/firefox/downloads/file/4250678/tampermonkey-5.1.0.xpi"

if (-not (Test-Path $registryPath)) {
    Write-Host "Tampermonkey registry path not found"
    return
}

if (-not (Get-ItemProperty -Path $registryPath -Name 100 -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Tampermonkey extension..."
    try {
        New-ItemProperty -Path $registryPath -Name 100 -Value $tampermonkeyUrl -PropertyType String -Force | Out-Null
    } catch {
        Write-Host "Failed to install Tampermonkey extension: $_"
    }
} else {
    Write-Host "Tampermonkey extension already installed"
}

# Install Certificates
if (Test-Path $installDir -PathType Container) {
    Write-Host "Installing certificates..."
    $certRegistryPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\Certificates\Install"
    $certName = 100
    $certFiles = Get-ChildItem -Path $installDir -File

    foreach ($certFile in $certFiles) {
        $certPath = $certFile.Name
        try {
            New-ItemProperty -Path $certRegistryPath -Name $certName -Value $certPath -PropertyType String -Force | Out-Null
            $certName++
        } catch {
            Write-Host "Failed to install certificate $($certFile.Name): $_"
        }
    }
} else {
    Write-Host "Folder does not exist: $installDir"
}
