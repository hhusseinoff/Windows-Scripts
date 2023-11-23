## Author: hyusein.hyuseinov@zonalcontractor.co.uk
## Last Edited: June 8th, 2023
## Function: Checks for installed server roles and features and returns 1 if any role or feature that can't be upgraded in-place is found.
## Function: Logs all activity and creates an actions file in C:\Temp

$scriptDirectory = $PSScriptRoot

$LogFolderPath = "C:\Temp\ServerRole_Checker"

if(!(Test-Path -Path "C:\Temp")) {
    New-Item -ItemType Directory -Force -Path "C:\Temp"
}

if(!(Test-Path -Path $LogFolderPath)) {
    New-Item -ItemType Directory -Force -Path $LogFolderPath
}

function debug($message) {
    $logMessage = "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message"
    Write-Host $logMessage
    Add-Content -Path "$LogFolderPath\ServerRole_Checker.log" -Value $logMessage -Force
}

debug "Script started."

$nonUpgradeableRoles = @(
    'ADFS', 
    'Print-Services'
)

$incompatibleRolesOrFeatures = $false

# Separate roles and features
$installedRoles = Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Installed' -and $_.SubFeatures.Count -eq 0 }
$installedFeatures = Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Installed' -and $_.SubFeatures.Count -gt 0 }

debug "Checking installed roles..."
foreach($role in $installedRoles) {
    if($role.Name -in $nonUpgradeableRoles) {
        $incompatibleRolesOrFeatures = $true
        debug "$($role.DisplayName) role cannot be upgraded in-place. This needs to be addressed manually."
        Add-Content -Path "$LogFolderPath\Actions.txt" -Value "Upgrade Warning: $($role.DisplayName) role cannot be upgraded in-place. This needs to be addressed manually." -Force
    } else {
        debug "$($role.DisplayName) role is installed and can be upgraded in-place."
    }
}

debug "Checking installed features..."
foreach($feature in $installedFeatures) {
    if($feature.Name -in $nonUpgradeableRoles) {
        $incompatibleRolesOrFeatures = $true
        debug "$($feature.DisplayName) feature cannot be upgraded in-place. This needs to be addressed manually."
        Add-Content -Path "$LogFolderPath\Actions.txt" -Value "Upgrade Warning: $($feature.DisplayName) feature cannot be upgraded in-place. This needs to be addressed manually." -Force
    } else {
        debug "$($feature.DisplayName) feature is installed and can be upgraded in-place."
    }
}

if($incompatibleRolesOrFeatures) {
    debug "Script finished. Incompatible roles or features detected."
    return 1
} else {
    debug "Script finished. No incompatible roles or features detected."
    return 0
}
