## Last Edited: June 14th, 2023
## Function: Uninstalls all browsers except for Microsoft Edge. Removes Internet Explorer using DISM.

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('True','False')]
    [string]$AllowIERemoval,

    [Parameter(Mandatory=$true)]
    [ValidateSet('True','False')]
    [string]$ChangeFileAssociations
)

# Capture script execution directory
$scriptDirectory = $PSScriptRoot

# Create required folders if they do not exist
$TempFolderPath = 'C:\Temp'
$LogFolderPath = 'C:\Temp\BrowserCleanup'

$IE_RemovalLogPath = "$LogFolderPath\IE_DISM_Uninstall.log"

$FileAssocLogPath = "$LogFolderPath\FileAssociationsChange_DISM.log"

$FileAssocXML = "$scriptDirectory\FileAssociations.xml"

if (-not (Test-Path $TempFolderPath)) {
    New-Item -ItemType Directory -Path $TempFolderPath -Force -Confirm:$false | Out-Null
}

if (-not (Test-Path $LogFolderPath)) {
    New-Item -ItemType Directory -Path $LogFolderPath -Force -Confirm:$false | Out-Null
}

# Declare the list of browser keywords
$browserKeywords = @('Chrome', 'Firefox', 'Opera')

# Declare the registry paths
$registryPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
)

function debug($message)
{
    Write-Host "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message"
    Add-Content -Path "$LogFolderPath\HandlerLog.log" -Value "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message" -Confirm:$false -Force
}

debug "Starting browser cleanup..."

# Loop over each registry path
foreach ($registryPath in $registryPaths) {
    debug "Scanning $registryPath..."
    
    # Get all subkeys
    $subkeys = Get-ChildItem $registryPath

    # Loop over each subkey
    foreach ($subkey in $subkeys) {
        # Get the 'DisplayName' property
        $displayName = Get-ItemProperty -Path $subkey.PSPath -Name 'DisplayName' -ErrorAction SilentlyContinue

        # Continue if 'DisplayName' exists and it's not for 'Microsoft Edge'
        if ($displayName -and $displayName.DisplayName -notlike '*Microsoft Edge*') {
            debug "Checking application: $($displayName.DisplayName)..."
            
            # Loop over each browser keyword
            foreach ($keyword in $browserKeywords) {
                # Continue if 'DisplayName' contains the keyword
                if ($displayName.DisplayName -like "*$keyword*") {
                    debug "Matching browser found: $($displayName.DisplayName)"
                    
                    # Fetch UninstallString
                    $uninstallString = (Get-ItemProperty -Path "$registryPath\$($subkey.PSChildName)" -Name 'UninstallString' -ErrorAction SilentlyContinue).UninstallString
                    
                    # If it's Chrome, add the "--force-uninstall" flag
                    if ($keyword -eq 'Chrome') {
                        $uninstallString += ' --force-uninstall'
                    }
                    
                    # If it's Firefox and doesn't contain "/S", add it
                    if ($keyword -eq 'Firefox' -and $uninstallString -notlike '*/S*') {
                        $uninstallString += ' /S'
                    }
                    
                    # Execute UninstallString
                    if ($uninstallString) {
                        debug "Executing uninstall command: $uninstallString"
                        $processResult = Start-Process cmd.exe -ArgumentList "/c $uninstallString" -Wait -PassThru
                        debug "Uninstall command completed. Exit code: $($processResult.ExitCode)"
                    } else {
                        debug "No uninstall command found."
                    }
                }
            }
        }
    }
}

# Check the AllowIERemoval parameter
if ($AllowIERemoval -eq "True") {
    
    debug "Uninstalling Internet Explorer is allowed. Preparing removal command line..."
    
    $IE_RemovalLine = "DISM.exe /Online /LogPath:$IE_RemovalLogPath /LogLevel:4 /Disable-Feature /FeatureName:Internet-Explorer-Optional-amd64 /NoRestart /quiet"

    debug "Prepared IE Removal commandline: $IE_RemovalLine"
    
    debug "Uninstalling Internet Explorer using DISM..."

    # Uninstall Internet Explorer using DISM
    $processResult = Start-Process cmd.exe -ArgumentList $IE_RemovalLine -Wait -PassThru

    debug "DISM command completed. Exit code: $($processResult.ExitCode)"
}
else
{
    debug "Skipping Internet Explorer removal..."
}

# Check the ChangeFileAssociations parameter
if ($ChangeFileAssociations -eq "True") {
    
    debug "Changing file associations is allowed. Preparing command line..."
    
    $FileAssociationsCMD = "DISM.exe /Online /Logpath:$FileAssocLogPath /LogLevel:4 /Import-DefaultAppAssociations:$FileAssocXML /NoRestart /quiet"

    debug "Prepared File Associations Import Command line: $FileAssociationsCMD"

    debug "Checking if the File Associations XML is avaialable..."

    $FileAssocXMLCheck = Test-Path -Path $FileAssocXML -PathType Leaf
    

    if($false -eq $FileAssocXMLCheck)
    {
        debug "File associations XML is not available at $scriptDirectory"

        debug "Prepared command line will not be executed. Script exiting..."

        exit 0
    }

    debug "Check passed."

    debug "Changing file associations..."

    $processResult = Start-Process cmd.exe -ArgumentList $FileAssociationsCMD -Wait -PassThru


}
else
{
    debug "Skipping changing of file associations..."
}

