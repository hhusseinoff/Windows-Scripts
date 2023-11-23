## Author: hyusein.hyuseinov@zonalcontractor.co.uk
## Last Edited: June 5th, 2023
## Function: Checks for installed SQL Server products (including Express, Standard, and LocalDB) and SSMS.
## Function: Returns 1 if any SQL server products are detected that are not compatible with Server 2016
## Function: Logs all activity at C:\Temp

# Capture the directory that the script executes from:
$scriptDirectory = $PSScriptRoot

# Define log folder path
$LogFolderPath = "C:\Temp\SQL_Checker"

# Create folders if they don't exist
if(!(Test-Path -Path "C:\Temp")) {
    New-Item -ItemType Directory -Force -Path "C:\Temp"
}

if(!(Test-Path -Path $LogFolderPath)) {
    New-Item -ItemType Directory -Force -Path $LogFolderPath
}

# Custom logging function
function debug($message) {
    $logMessage = "$(Get-Date -Format yyyy-MM-dd--HH-mm-ss) $message"
    Write-Host $logMessage
    Add-Content -Path "$LogFolderPath\SQL_Checker.log" -Value $logMessage -Force
}

debug "Script started."

debug "Checking SQL Server instances..."
$instances = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL' 2>$null
if ($instances) {
    debug "$($instances.PSChildName.count) SQL Server instance(s) found."
} else {
    debug "No Installed SQL Server instances found."
}

$compatibilityIssues = $false
foreach ($instance in $instances.PSChildName) {
    $instanceVersionKey = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$instance\Setup").Version
    $instanceVersion = $instanceVersionKey.Split(".")[0]
    debug "Found SQL Server instance: $instance, Version: $instanceVersion"

    # Compare version to compatibility matrix
    if ($instanceVersion -lt 11) {
        debug "Incompatible SQL Server instance detected: $instance, Version: $instanceVersion"
        $compatibilityIssues = $true
    }
}

# If no instances found via registry, try sqlcmd
if (-not $instances) {
    debug "No SQL Server instances found in registry. Checking via sqlcmd..."
    try {
        # Execute sqlcmd and capture its exit code
        $output = & sqlcmd -S .\MSSQLSERVER -E -Q "SELECT SERVERPROPERTY('productversion')" -ErrorAction Ignore
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0 -and $output) {
            $instanceVersion = $output.Split(".")[0]
            debug "Found SQL Server instance MSSQLSERVER via sqlcmd, Version: $instanceVersion"

            # Compare version to compatibility matrix
            if ($instanceVersion -lt 11) {
                debug "Incompatible SQL Server instance detected: MSSQLSERVER, Version: $instanceVersion"
                $compatibilityIssues = $true
            }
        } else {
            debug "Error executing sqlcmd or no output returned."
        }
    } catch {
        debug "Error executing sqlcmd: $_"
    }
}



debug "Checking SQL Server LocalDB..."
$localDBVersions = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server Local DB\Installed Versions' | Select-Object -Property PSChildName
if ($localDBVersions) {
    foreach ($localDBVersion in $localDBVersions.PSChildName) {
        debug "Found SQL Server LocalDB, Version: $localDBVersion"
        if ($localDBVersion.Split(".")[0] -lt 11) {
            debug "Incompatible SQL Server LocalDB detected: Version: $localDBVersion"
            $compatibilityIssues = $true
        } else {
            debug "Compatible SQL Server LocalDB detected: Version: $localDBVersion"
        }
    }
} else {
    debug "No SQL Server LocalDB found."
}


debug "Checking SQL Server Management Studio (SSMS)..."
$SSMSVersions = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' |
                Get-ItemProperty | Where-Object { $_.DisplayName -like "Microsoft SQL Server Management Studio*" }

if ($SSMSVersions) {
    foreach ($SSMSVersion in $SSMSVersions) {
        debug "Found SSMS, Version: $($SSMSVersion.DisplayVersion)"
        if ($SSMSVersion.DisplayVersion.Split(".")[0] -lt 18) {
            debug "Older SSMS detected: Version: $($SSMSVersion.DisplayVersion). Upgrade advised but not critical for OS upgrade."
        } else {
            debug "Compatible SSMS detected: Version: $($SSMSVersion.DisplayVersion)"
        }
    }
} else {
    debug "No SSMS found."
}



if ($compatibilityIssues) {
    debug "Script finished. Compatibility issues detected."

    # Create a separate log file for suggested actions
    $actionLogPath = "$LogFolderPath\SQL_Checker_Actions.log"
    if ($instances.PSChildName -and $instanceVersion -lt 13) {
        $actionMessage = "Detected incompatible SQL Server instance: $instance, Version: $instanceVersion. Suggested action: Please upgrade to a compatible version."
        Add-Content -Path $actionLogPath -Value $actionMessage -Force
    }
    foreach ($localDBVersion in $localDBVersions.PSChildName) {
        if ($localDBVersion.Split(".")[0] -lt 13) {
            $actionMessage = "Detected incompatible SQL Server LocalDB, Version: $localDBVersion. Suggested action: Please upgrade to a compatible version."
            Add-Content -Path $actionLogPath -Value $actionMessage -Force
        }
    }
    return 1
} else {
    debug "Script finished. No compatibility issues detected."
    return 0
}
