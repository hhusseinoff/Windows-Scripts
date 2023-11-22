$RegistryRootPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"

$StateFlagName = "StateFlags0001"

$ItemsToClear = @(
    "Active Setup Temp Folders",
    "BranchCache",
    "Downloaded Program Files",
    "Internet Cache Files",
    "Old ChkDsk Files",
    "Previous Installations",
    "Recycle Bin",
    "Service Pack Cleanup",
    "Setup Log Files",
    "System error memory dump files",
    "System error minidump files",
    "Temporary Files",
    "Temporary Setup Files",
    "Thumbnail Cache",
    "Update Cleanup",
    "Upgrade Discarded Files",
    "Windows Defender",
    "Windows Error Reporting Archive Files",
    "Windows Error Reporting Queue Files",
    "Windows Error Reporting System Archive Files",
    "Windows Error Reporting System Queue Files",
    "Windows Error Reporting Temp Files",
    "Windows ESD installation files",
    "Windows Upgrade Log Files"
)


foreach($ItemName in $ItemsToClear)
{
    $StateFlagExists = Get-ItemPropertyValue -Path "$RegistryRootPath\$ItemName" -Name $StateFlagName -ErrorAction SilentlyContinue

    if($StateFlagExists -eq $null)
    {
        New-ItemProperty -Path "$RegistryRootPath\$ItemName" -Name $StateFlagName -PropertyType DWord -Value 2 -Force -Confirm:$false -ErrorAction SilentlyContinue
    }

    if($StateFlagExists -ne 2)
    {
        Set-ItemProperty -Path "$RegistryRootPath\$ItemName" -Name $StateFlagName -Value 2 -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}

