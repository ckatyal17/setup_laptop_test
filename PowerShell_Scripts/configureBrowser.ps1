$installDir = "C:\Amzn-New-Win-Setup\BrowserSetup"

New-Item -ItemType "directory" -Path $installDir

## Check if Firefox is Installed - If not then install firefox else do nothing:

$x86_check = ((Get-ChildItem "HKLM:Software\Microsoft\Windows\CurrentVersion\Uninstall") | Where-Object { $_."Name" -like "*Mozilla Firefox*" } ).Length -gt 0
$x64_check = ((Get-ChildItem "HKLM:Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall") | Where-Object { $_."Name" -like "*Mozilla*" } ).Length -gt 0
$mozilla = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object {$_.Name -eq 'Mozilla Firefox ESR'})
$mozilla32 = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object {$_.Name -eq 'Mozilla Firefox ESR 32-bit'})

if (($x86_check -eq $true) -or ($x64_check -eq $true)) {
    if(($mozilla32.InstallState -eq 'Installed') -or ($mozilla.InstallState -eq 'Installed')){
            Write-Host "Firefox is installed using Software Center"
    }else{
        Write-Host "Firefox is installed but not using Software center" 
    } 
}else {
    Write-Host "##################################`nInstalling Mozilla firefox ESR`n##################################"
    $firefox = (Get-CimInstance -ClassName CCM_Application -Namespace "root\ccm\clientSDK" | Where-Object {$_.Name -eq 'Mozilla Firefox ESR 32-bit'})
    $Args = @{EnforcePreference = [UINT32] 0
    Id = "$($firefox.id)"
    IsMachineTarget = $firefox.IsMachineTarget
    IsRebootIfNeeded = $False
    Priority = 'High'
    Revision = "$($firefox.Revision)" }

    $output = Invoke-CimMethod -Namespace "root\ccm\clientSDK" -ClassName CCM_Application -MethodName Install -Arguments $Args
    if ($output.ReturnValue -eq 0){
        Write-Host "Mozilla Firefox installed successfully"
    }else {$output}
}

########################################################
# Download Certificates

Invoke-WebRequest -Uri "https://pki.amazon.com/crt/Amazon.com%20Internal%20Root%20Certificate%20Authority.der" -OutFile "$($installDir)\Amazon.com Internal Root Certificate Authority.der"
Invoke-WebRequest -Uri "https://pki.amazon.com/crt/Amazon.com%20CIA%20CA%20G5%2001.der" -OutFile "$($installDir)\Amazon.com CIA CA G5 01.der"
Invoke-WebRequest -Uri "https://pki.amazon.com/crt/Amazon.com%20CIA%20CA%20G5%2002.der" -OutFile "$($installDir)\Amazon.com CIA CA G5 02.der"

########################################################
# Install Tampermonkey
$registryPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\Extensions\Install"

$Name = "100"

$Value = "https://addons.mozilla.org/firefox/downloads/file/3768983/tampermonkey-4.13.6136-an+fx.xpi"

New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force | Out-Null

########################################################
Install Certificates
$certRegistryPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox\Certificates\Install"

$certName = "100"

$cert = "$($installDir)\Amazon.com Internal Root Certificate Authority.der"

$certName1 = "101"

$cert1 = "$($installDir)\Amazon.com InfoSec CA G3.der"

$certName2 = "102"

$cert2 = "$($installDir)\Amazon.com InfoSec CA G4 ACM1.der"

$certName3 = "103"

$cert3 = "$($installDir)\Amazon.com InfoSec CA G4 ACM2.der"

$certName4 = "104"

$cert4 = "$($installDir)\CIA-CRT-G3-01.ant.amazon.com_Amazon.com CIA CA G3 01.der"

$certName5 = "105"

$cert5 = "$($installDir)\CIA-CRT-G3-02.ant.amazon.com_Amazon.com CIA CA G3 02.der"

New-ItemProperty -Path $certRegistryPath -Name $certName -Value $cert -PropertyType String -Force | Out-Null
New-ItemProperty -Path $certRegistryPath -Name $certName1 -Value $cert1 -PropertyType String -Force | Out-Null
New-ItemProperty -Path $certRegistryPath -Name $certName2 -Value $cert2 -PropertyType String -Force | Out-Null
New-ItemProperty -Path $certRegistryPath -Name $certName3 -Value $cert3 -PropertyType String -Force | Out-Null
New-ItemProperty -Path $certRegistryPath -Name $certName4 -Value $cert4 -PropertyType String -Force | Out-Null
New-ItemProperty -Path $certRegistryPath -Name $certName5 -Value $cert5 -PropertyType String -Force | Out-Null