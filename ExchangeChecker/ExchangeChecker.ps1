## Last Edited: June 8th, 2023
## Function: Checks for installed Exchange server and its compatibility with a prospective upgrade to Windows Server 2016.
## Function: Logs all activity and creates an actions file in C:\Temp

$scriptDirectory = $PSScriptRoot

$LogFolderPath = "C:\Temp\Exchange_Checker"

if(!(Test-Path -Path "C:\Temp")) {
    New-Item -ItemType Directory -Force -Path "C:\Temp"
}

if(!(Test-Path -Path $LogFolderPath)) {
    New-Item -ItemType Directory -Force -Path $LogFolderPath
}

function debug($message) {
    $logMessage = "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message"
    Write-Host $logMessage
    Add-Content -Path "$LogFolderPath\Exchange_Checker.log" -Value $logMessage -Force
}

debug "Script started."

# Try to get Exchange Server version
try {
    $exchangeVersion = (Get-ExchangeServer).AdminDisplayVersion
} catch {
    debug "No Exchange Server found on this system."
    debug "Script finished. No compatibility issues detected."
    return 0
}

debug "Exchange Server version: $exchangeVersion"

$compatibilityIssues = $false

# Compatibility matrix for Windows Server 2016
switch ($exchangeVersion.Major) {
    15 {
        # Exchange 2013, 2016 and 2019 have same major version number, 15.
        # Hence need to distinguish between them by Minor version number
        switch ($exchangeVersion.Minor) {
            0 { # Exchange 2013
                debug "Incompatible Exchange Server detected: Exchange 2013 SP1 is not compatible with Windows Server 2016"
                $compatibilityIssues = $true
            }
            1 { # Exchange 2016
                if ($exchangeVersion.Build -lt 3) { # CU3 and later is compatible with Windows Server 2016
                    debug "Incompatible Exchange Server detected: Exchange 2016 CU2 and earlier are not compatible with Windows Server 2016"
                    $compatibilityIssues = $true
                }
            }
            2 { # Exchange 2019
                debug "Incompatible Exchange Server detected: Exchange 2019 is not compatible with Windows Server 2016"
                $compatibilityIssues = $true
            }
        }
    }
    14 { # Exchange 2010
        debug "Incompatible Exchange Server detected: Exchange 2010 is not compatible with Windows Server 2016"
        $compatibilityIssues = $true
    }
}

if ($compatibilityIssues) {
    Add-Content -Path "$LogFolderPath\Actions.txt" -Value "Upgrade Warning: The Exchange Server version installed is not compatible with Windows Server 2016. Please upgrade Exchange Server before upgrading the OS." -Force
    debug "Script finished. Compatibility issues detected."
    return 1
} else {
    debug "Script finished. No compatibility issues detected."
    return 0
}
