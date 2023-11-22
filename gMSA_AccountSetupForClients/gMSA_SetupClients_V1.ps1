<#
.SYNOPSIS
This script manages the permissions for a given Group Managed Service Account (gMSA) in Active Directory.
It ensures that the executing machine has the necessary permissions to retrieve the managed password for the gMSA.

.DESCRIPTION
The script performs the following actions:

Determines the script's directory and sets up logging in the "C:\Temp\gMSA_Setup" directory.
Retrieves the Active Directory object for the specified gMSA.
Captures the current list of principals allowed to retrieve the managed password for the gMSA.
Retrieves the Active Directory object for the executing machine.
Adds the executing machine's distinguished name to the list of principals allowed to retrieve the managed password.
Applies the updated list of principals to the gMSA in Active Directory.
Verifies that the changes were applied successfully.

.PARAMETER gMSA_AccountName
The name of the Group Managed Service Account (gMSA) for which permissions are being managed.

.EXAMPLE
.\ScriptName.ps1 -gMSA_AccountName "MygMSA"

This will manage permissions for the gMSA named "MygMSA".

.NOTES
File Name : gMSA_SetupClients_V1.ps1
Prerequisite : Must run under an account that has the necessary permissions to make changes to the specified gMSA Account
Prerequisite : ActiveDirectory Powershell module must be installed
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$gMSA_AccountName
)

# Capture script directory
$ScriptDir = $PSScriptRoot

# Define log folder root
$LogFolderRoot = "C:\Temp"

# Create folders if they don't exist
if(!(Test-Path -Path $LogFolderRoot)) {
    New-Item -ItemType Directory -Force -Path $LogFolderRoot
}

# Define log folder path
$LogFolderPath = "C:\Temp\gMSA_Setup"

# Create folders if they don't exist
if(!(Test-Path -Path $LogFolderPath)) {
    New-Item -ItemType Directory -Force -Path $LogFolderPath
}

# Custom logging function
function debug($message) {
    $logMessage = "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message"
    Write-Host $logMessage
    Add-Content -Path "$LogFolderPath\gMSA_Setup_$(Get-Date -Format yyyy_MM_dd__HH).log" -Value $logMessage -Force
}

debug "------------------------------------------------------------------------------------------------------------------------------------------------"

debug "Script initated."

$ExecUserContext = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

debug "Running as $ExecUserContext"

debug "Attempting to retrieve AD Object for gMSA account $gMSA_AccountName..."

try
{
    $gMSA_ADObj = Get-ADServiceAccount -Identity $gMSA_AccountName -Properties *
}
catch
{
    debug "FAILED to retrieve account. Error: $_.Exception.Message"

    debug "Exiting script with error code 1..."

    exit 1
}

debug "Successfully retrieved AD Object for gMSA account $gMSA_AccountName"

debug "Retrieving string array value for Property PrincipalsAllowedToRetrieveManagedPassword..."

$PrincipalsAllowedToRetrievePassword_CurrentValue = $gMSA_ADObj.PrincipalsAllowedToRetrieveManagedPassword.Value

debug "Current value(s):"

debug " "

foreach($string in $PrincipalsAllowedToRetrievePassword_CurrentValue)
{
    debug $string
}

debug " "

debug "Attempting to retrieve the AD Computer object for the executing machine $env:COMPUTERNAME..."

try
{
    $AD_ComputerObj = Get-ADComputer -Identity $env:COMPUTERNAME
}
catch
{
    debug "FAILED to retrieve computer object. Error: $_.Exception.Message"

    debug "Exiting script with error code 2..."

    exit 2
}

debug "Computer object for $env:COMPUTERNAME successfully retrieved."

debug "Capturing Distinguished name..."

$AD_ComputerObj_DistinguishedName = $AD_ComputerObj.DistinguishedName

debug "Distinguished name: $AD_ComputerObj_DistinguishedName"

debug "Adding distinguished name to PrincipalsAllowedToRetrieveManagedPassword string array..."

$PrincipalsAllowedToRetrievePassword_UpdatedValue = $PrincipalsAllowedToRetrievePassword_CurrentValue + $AD_ComputerObj_DistinguishedName

debug "Updated PrincipalsAllowedToRetrieveManagedPassword string array:"

debug " "

foreach($string in $PrincipalsAllowedToRetrievePassword_UpdatedValue)
{
    debug $string
}

debug " "

debug "Applying changes to $gMSA_AccountName object..."

try
{
    $gMSA_ADObj_Updated = Set-ADServiceAccount -Identity $gMSA_AccountName -PrincipalsAllowedToRetrieveManagedPassword $PrincipalsAllowedToRetrievePassword_UpdatedValue -PassThru -Confirm:$false
}
catch
{
    debug "FAILED to apply changes. Error: $_.Exception.Message"

    debug "Exiting script with error code 3..."

    exit 3
}

debug "Successfully applied changes to AD Object for gMSA account $gMSA_AccountName"

debug "Verifying changes..."

try
{
    $gMSA_ADObj = Get-ADServiceAccount -Identity $gMSA_AccountName -Properties *
}
catch
{
    debug "FAILED to retrieve account for verification purposes. Error: $_.Exception.Message"

    debug "Exiting script with error code 4..."

    exit 4
}

debug "Retrieving string array value for Property PrincipalsAllowedToRetrieveManagedPassword..."

$PrincipalsAllowedToRetrievePassword_CurrentValue = $gMSA_ADObj.PrincipalsAllowedToRetrieveManagedPassword.Value

debug "Current value(s):"

debug " "

foreach($string in $PrincipalsAllowedToRetrievePassword_CurrentValue)
{
    debug $string
}

debug " "

debug "Script Execution finished. Exiting..."

exit 0