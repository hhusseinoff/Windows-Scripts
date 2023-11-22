<#
.Synopsis
  This script grants the "Logon as a Service" right to a specified user.

.Parameter ComputerName
  Specifies the name of the computer where the user right should be granted.
  By default, it targets the local computer where the script is executed.

.Parameter Username
  Specifies the username to which the right should be granted.
  The format should be: domain\username.
  By default, it uses the user executing the script.

.Example
  .\GrantSeServiceLogonRight.ps1 -ComputerName hostname.domain.com -Username "domain\username"

  Note: This script is based on the original script from https://gist.github.com/grenade/8519655
  but has been heavily modified to include logging and error handling.

  Edit date: Oct 9th 2023

#>

param(
  [string] $ComputerName = ("{0}.{1}" -f $env:COMPUTERNAME.ToLower(), $env:USERDNSDOMAIN.ToLower()),
  [string] $Username = ("{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME)
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
$LogFolderPath = "C:\Temp\GrantLogOnAsAService"

# Create folders if they don't exist
if(!(Test-Path -Path $LogFolderPath)) {
    New-Item -ItemType Directory -Force -Path $LogFolderPath
}

# Custom logging function
function debug($message) {
    $logMessage = "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message"
    Write-Host $logMessage
    Add-Content -Path "$LogFolderPath\GrantLogOnAsAService_$(Get-Date -Format yyyy_MM_dd__HH).log" -Value $logMessage -Force
}

debug "------------------------------------------------------------------------------------------------------------------------------------------------"

debug "Script initated."

debug "Input parameters:"

debug "-----------------------------------------------"
debug "Computer Name: $computerName"
debug "Username: $username"
debug "-----------------------------------------------"

debug ""

$FilePath_importINF = Join-Path -Path $LogFolderPath -ChildPath "import.inf"
$FilePath_exportINF = Join-Path -Path $LogFolderPath -ChildPath "export.inf"
$FilePath_secedtSDB = Join-Path -Path $LogFolderPath -ChildPath "secedt.sdb"

debug "Obtaining AD SID for user $username..."

try
{
    $TargetAccSID = ((New-Object System.Security.Principal.NTAccount($username)).Translate([System.Security.Principal.SecurityIdentifier])).Value
}
catch
{
    debug "Failed to translate username $username to an AD SID."

    debug "Exiting with error code 1..."

    debug "------------------------------------------------------------------------------------------------------------------------------------------------"

    exit 1
}

debug "AD SID for $username obtained: $TargetAccSID"

debug "Exporting current local security settings to export.inf (full file path: $FilePath_exportINF)..."

try
{
    Start-Process -FilePath "secedit.exe" -ArgumentList "/export /cfg $FilePath_exportINF" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}
catch
{
    debug "FAILED to export SecEdit current config. Error: $($Error[0].Exception.Message)"

    debug "Exiting with error code 2..."

    debug "------------------------------------------------------------------------------------------------------------------------------------------------"

    exit 2
}

debug "Current local security settings exported."

debug "Capturing current list of account AD SIDs that have been granted the Log On as A Service permission..."

$Current_SIDs = (Select-String -Path $FilePath_exportINF -Pattern "SeServiceLogonRight").Line

if($null -eq $Current_SIDs)
{
    debug "-----------------------------------------------"
    
    debug "Current list is empty!"

    debug "-----------------------------------------------"
}

debug "-----------------------------------------------"

debug "List: $Current_SIDs"

debug "-----------------------------------------------"

debug "Creating an import.inf file containing the current list of SIDs and the SID of $username..."

foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsAService security template", "[Privilege Rights]", "$Current_SIDs,*$TargetAccSID"))
{
   Add-Content -Path $FilePath_importINF -Value $line -Force -Confirm:$false
}

debug "File created. It's contents are:"

debug "-----------------------------------------------"

$CheckImportFile = Get-Content -Path $FilePath_importINF -Force

debug $CheckImportFile

debug "-----------------------------------------------"

debug "Creating the edited secedt.sdb Database (full file path: $FilePath_secedtSDB)..."

try
{
    Start-Process -FilePath "secedit.exe" -ArgumentList "/import /db $FilePath_secedtSDB /cfg $FilePath_importINF" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}
catch
{
    debug "FAILED to create the edited secedt.sdb file. Error: $($Error[0].Exception.Message)"

    debug "Exiting with error code 3..."

    debug "------------------------------------------------------------------------------------------------------------------------------------------------"

    exit 3
}

debug "secedt.sdb File created."

debug "Applying changes to the actual secedt.sdb used by the System..."

try
{
    Start-Process -FilePath "secedit.exe" -ArgumentList "/configure /db $FilePath_secedtSDB" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}
catch
{
    debug "FAILED to apply the edited secedt.sdb file. Error: $($Error[0].Exception.Message)"

    debug "Exiting with error code 4..."

    debug "------------------------------------------------------------------------------------------------------------------------------------------------"

    exit 4
}

debug "secedt.sdb File applied."

debug "Issuing GPUpdate..."

Start-Process -FilePath "gpupdate.exe" -ArgumentList "/force" -NoNewWindow -Wait -ErrorAction SilentlyContinue

debug "GPUpdate issued."

debug "Script Execution finished. Exiting..."

debug "------------------------------------------------------------------------------------------------------------------------------------------------"

exit 0