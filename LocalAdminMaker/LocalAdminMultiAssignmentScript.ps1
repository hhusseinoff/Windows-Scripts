Start-Transcript -Path "C:\Windows\AVC\Logging\COMP_LocalAdminAssignmentScript_DedC_UAT.txt"

$UserSID_Input = Get-ADComputer $env:COMPUTERNAME -Properties Description | Select-Object -ExpandProperty Description

$UserSID_Array = $UserSID_Input.Split(",")

:MainLoop foreach($UserSID in $UserSID_Array)
{
    if($UserSID -like "S-1-5-21-xxxxxxxxxx-xxxxxxxx-xxxxxxxxxxxx-*")
    {
        # "something1 Domain User"
        
        $UserDOM = "something1"   
    }

    elseif($UserSID -like "S-1-5-21-xxxxxxxxxx-xxxxxxxx-xxxxxxxxxxxx-*")
    {
        # "something2 Domain User"

        $UserDOM = "something2"
    }
    else
    {
        Write-Host "SID $UserSID incompatible with the hardcoded external domains reference..."

        Write-Host "Attempting to create a System.Security.Principal.SecurityIdentifier Object based on the user SID..."

        try
        {
            $SID_Object = New-Object System.Security.Principal.SecurityIdentifier($UserSID)
        }
        catch
        {
            Write-Host "Failed to Construct an AD SID Object for an External User."

            Write-Host "Skipping to the next SID..."

            continue MainLoop
        }

        Write-Host "System.Security.Principal.SecurityIdentifier Object created for $UserSID_Input"

        Write-Host "Attempting to translate the User SID..."

        try
        {
            $TranslatedUserObject = $SID_Object.Translate([System.Security.Principal.NTAccount])
        }
        catch
        {
            Write-Host "Failed to Translate a User SID $UserSID"

            Write-Host "Skipping to the next SID..."

            continue MainLoop
        }

        $ResolvedUser = $TranslatedUserObject.Value

        Write-Host "User resolved: $ResolvedUser"

        Write-Host "Adding to the local administrators group..."

        Add-LocalGroupMember -Group "Administrators" -Member $ResolvedUser

        Write-Host $ResolvedUser "added to local administrators group"

        continue MainLoop
    }

    $UserSAM = Get-ADUser -Identity $UserSID -Server $UserDOM | Select-Object -ExpandProperty SamAccountName

    Add-LocalGroupMember -Group "Administrators" -Member $UserDOM\$UserSAM

    Write-Host $UserDOM\$UserSAM "added to local administrators group"

    continue MainLoop
}