# Declare an array of server names
$serverNames = @(
    'Name1',
    'Name2',
    'Name3'
)
 # Add more server names as needed

# Initialize an empty array to store the distinguished names
$distinguishedNames = @()

# Loop through each server name
foreach ($server in $serverNames) {
    # Use Get-ADComputer to get the DistinguishedName parameter of the AD Object for the server
    $distinguishedName = (Get-ADComputer -Filter "Name -eq '$server'").DistinguishedName

    # Check if the distinguished name is not null or empty
    if (![string]::IsNullOrEmpty($distinguishedName)) {
        # Add the distinguished name to the array
        $distinguishedNames += $distinguishedName
    }
}

# Display the array of distinguished names
$distinguishedNames

Set-ADServiceAccount -Identity "gMSA_AccountName" -PrincipalsAllowedToRetrieveManagedPassword $distinguishedNames
