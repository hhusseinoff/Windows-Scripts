# Capture script execution directory
$scriptDirectory = $PSScriptRoot

# Create required folders if they do not exist
$TempFolderPath = 'C:\Temp'
$LogFolderPath = 'C:\Temp\LogOffUsers'

if (-not (Test-Path $TempFolderPath)) {
    debug "Creating Temp folder at $TempFolderPath..."
    New-Item -ItemType Directory -Path $TempFolderPath -Force -Confirm:$false | Out-Null
    debug "Temp folder created."
}

if (-not (Test-Path $LogFolderPath)) {
    debug "Creating LogOffUsers folder at $LogFolderPath..."
    New-Item -ItemType Directory -Path $LogFolderPath -Force -Confirm:$false | Out-Null
    debug "LogOffUsers folder created."
}

# Define debug function
function debug($message)
{
    Write-Host "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message"
    Add-Content -Path "$LogFolderPath\HandlerLog.log" -Value "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message" -Confirm:$false -Force
}

# Start of actions
debug "---------------------------------------------------------------------------------------------------------------------------"

# Initialize a variable $first
debug "Initializing variables..."
$first = 1

# Capture output of quser command
debug "Capturing output of quser command..."
$quserOutput = quser

# Check if there are no logged on users
if ($quserOutput.Count -eq 1) {
    debug "No logged on users found. Exiting script."
    debug "---------------------------------------------------------------------------------------------------------------------------"
    exit
}

# Iterate through each user session
debug "Starting to iterate through each user session..."
$quserOutput | ForEach-Object {
    # Process the first line of the input to determine the positions of each attribute
    if ($first -eq 1) {
        debug "Processing first line of output to capture attribute positions..."
        $userPos = $_.IndexOf("USERNAME")
        $sessionPos = $_.IndexOf("SESSIONNAME")
        $idPos = $_.IndexOf("ID")
        $statePos = $_.IndexOf("STATE")
        $first = 0
        debug "Attribute positions captured."
    }
    # Process subsequent lines and logoff each user
    else {
        debug "Processing line: $_"
        $user = $_.substring($userPos,$sessionPos-$userPos).Trim()
        $session = $_.substring($sessionPos,$idPos-$sessionPos).Trim()
        $id = $_.substring($idPos,$statePos-$idPos).Trim()
        # Output logoff details to the console and the log file
        $message = "Logging off user:$user session:$session id:$id"
        debug $message
        debug "Executing logoff command..."
        logoff $id
        debug "Logoff command executed."
    }
}

# End of actions
debug "---------------------------------------------------------------------------------------------------------------------------"
