$serverNames = @("Name1", "Name2", "Name3")

$serverNamesUS = @("Name1", "Name2", "Name3")

$result = foreach($name in $serverNames)
{
    $scriptBlock = {
        $reg = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion" | Select-Object ProductName, ReleaseId, InstallationType, CurrentMajorVersionNumber,CurrentMinorVersionNumber,CurrentBuild
        return $reg
    }

    $remoteReg = Invoke-Command -ComputerName $name -ScriptBlock $scriptBlock
    New-Object -TypeName PSObject -Property @{
        ServerName = $name
        ProductName = $remoteReg.ProductName
        ReleaseId = $remoteReg.ReleaseId
        InstallationType = $remoteReg.InstallationType
        CurrentMajorVersionNumber = $remoteReg.CurrentMajorVersionNumber
        CurrentMinorVersionNumber = $remoteReg.CurrentMinorVersionNumber
        CurrentBuild = $remoteReg.CurrentBuild
    }
}

$resultUK = foreach($name in $serverNamesUS)
{
    $scriptBlock = {
        $reg = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion" | Select-Object ProductName, ReleaseId, InstallationType, CurrentMajorVersionNumber,CurrentMinorVersionNumber,CurrentBuild
        return $reg
    }

    $remoteReg = Invoke-Command -ComputerName $name -ScriptBlock $scriptBlock
    New-Object -TypeName PSObject -Property @{
        ServerName = $name
        ProductName = $remoteReg.ProductName
        ReleaseId = $remoteReg.ReleaseId
        InstallationType = $remoteReg.InstallationType
        CurrentMajorVersionNumber = $remoteReg.CurrentMajorVersionNumber
        CurrentMinorVersionNumber = $remoteReg.CurrentMinorVersionNumber
        CurrentBuild = $remoteReg.CurrentBuild
    }
}

$resultUK | Format-Table -AutoSize

$resultUS | Format-Table -AutoSize
