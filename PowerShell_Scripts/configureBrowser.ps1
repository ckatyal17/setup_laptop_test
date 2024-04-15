Write-Host "################################################`nInstalling and Configuring Mozilla Firefox ESR`n################################################" -ForegroundColor Blue

# Create folder
$installDir = "C:\Amzn-New-Win-Setup\BrowserSetup"
if (-not (Test-Path $installDir -PathType Container)) {
    Write-Host "Creating folder to store browser configuration files..." -ForegroundColor Yellow
    try {
        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        Write-Host "Folder Created $installDir" -ForegroundColor Green
    } catch {
        Write-Host "Failed to create folder: $_" -ForegroundColor Red
        return
    }
}

# Check if Firefox is installed
try {

    # Check if Mozilla Firefox is installed in 32-bit registry
    $x86_check = ((Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall") | Where-Object { $_."Name" -like "*Mozilla Firefox*" }).Length -gt 0

    # Check if Mozilla Firefox is installed in 64-bit registry
    $x64_check = ((Get-ChildItem "HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") | Where-Object { $_."Name" -like "*Mozilla*" }).Length -gt 0

    # Check if Mozilla Firefox ESR is installed
    $mozilla = Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object { $_.Name -eq 'Mozilla Firefox ESR x64' }
    $mozilla32 = Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object { $_.Name -eq 'Mozilla Firefox ESR x86' }

    # Install Mozilla Firefox if not already installed
    if (($x86_check -eq $true) -or ($x64_check -eq $true)) {
        if (($mozilla32.InstallState -eq 'Installed') -or ($mozilla.InstallState -eq 'Installed')) {
            Write-Host "Firefox is installed using Software Center." -ForegroundColor Yellow
        } else {
            Write-Host "Firefox is installed but not using Software center." -ForegroundColor Yellow
        } 
    } else {
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
            Start-Sleep -Seconds 40
            Write-Host "Mozilla Firefox installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Failed to install Mozilla Firefox: $($output.ReturnValue)" -ForegroundColor Red
            return
        }
    }
} catch {
    Write-Output "An error occurred: $_"
    return
}

# Install Tampermonkey extension
$registryPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\Extensions\Install"
$tampermonkeyUrl = "https://addons.mozilla.org/firefox/downloads/file/4250678/tampermonkey-5.1.0.xpi"

if (-not (Test-Path $registryPath)) {
    Write-Host "Tampermonkey registry path not found"
    return
}

if (-not (Get-ItemProperty -Path $registryPath -Name 100 -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Tampermonkey extension..." -ForegroundColor Yellow
    try {
        New-ItemProperty -Path $registryPath -Name 100 -Value $tampermonkeyUrl -PropertyType String -Force | Out-Null
        Write-Host "Tampermonkey extension Installation Completed!" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install Tampermonkey extension: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Tampermonkey extension already installed" -ForegroundColor Yellow
}

# Download Certificates
$certificates = @(
    "https://pki.amazon.com/crt/Amazon.com%20Internal%20Root%20Certificate%20Authority.der"
    # "https://pki.amazon.com/crt/Amazon.com%20CIA%20CA%20G5%2001.der",
    # "https://pki.amazon.com/crt/Amazon.com%20CIA%20CA%20G5%2002.der"
)

foreach ($certUrl in $certificates) {
    $certName = $certUrl.Split('/')[-1] -replace '%20', ' '
    $certPath = Join-Path -Path $installDir -ChildPath $certName
    if (-not (Test-Path $certPath)) {
        Write-Host "Downloading certificate: $certName" -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $certUrl -OutFile $certPath -ErrorAction Stop
        } catch {
            Write-Host "Failed to download certificate: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Certificate already exists: $certName" -ForegroundColor Yellow
    }
}

# Install Certificates

if (Test-Path $installDir -PathType Container) {
    $certRegistryPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\Certificates\Install"
    $certName = 100
    $certFiles = Get-ChildItem -Path $installDir -File

    foreach ($certFile in $certFiles) {
        try {
            $certPath = $certFile.FullName
            $certFileName = $certFile.Name
            $certificateRegistryKey = Get-ItemProperty -Path $certRegistryPath | Where-Object { $_.PSChildName -eq $certFileName }

            if ($certificateRegistryKey) {
                Write-Host "Certificate $certFileName is installed on Mozilla Firefox." -ForegroundColor Green
            } else {
                Write-Host "Certificate $certFileName is not installed on Mozilla Firefox. Installing Cert.." -ForegroundColor Yellow
                New-ItemProperty -Path $certRegistryPath -Name $certName -Value $certPath -PropertyType String -Force | Out-Null
                $certName++
                Write-Host "Certificate Installed: $($certFileName)" -ForegroundColor Green
            }
        } catch {
            Write-Host "Failed to install certificate $(certFileName): $_" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Folder does not exist: $installDir" -ForegroundColor Red
}
