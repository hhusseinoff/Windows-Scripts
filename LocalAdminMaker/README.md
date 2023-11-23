# LocalAdminMaker

A pair of scripts designed to make end users, local admin on the desktops they're assigned to.

The actual assigning of desktops to users is covered by a separate project / script and involves Citrix: [Link:UserAssignmentMulti](https://github.com/hhusseinoff/UserAssignmentMulti)


[**SAC_ADUserAdminMarker.ps1**](https://github.com/hhusseinoff/LocalAdminMaker/blob/main/SAC_ADUserAdminMarker.ps1)

Uses an Input.txt file and works in two phases to

1a. Pull all members of an AD group
1b. Output their AD User SIDs an P1 output file

2a. Pull data on all machines from a given citrix Delivery group
2b. Pull AD data for every machine from the delivery group
2c. Add the User SIDs to the Description Field of the computer objects in AD for each machine for which data was retrieved from a given delivery group
  2c1. Each User SID for a given machine, separated by a comma ","

[**LocalAdminMultiAssignmentScript.ps1**](https://github.com/hhusseinoff/LocalAdminMaker/blob/main/LocalAdminMultiAssignmentScript.ps1)

>**Warning**
>Intended to be run as a GPO on User logon or machine startup

1. Takes the AD User SIDs from the Description field of the AD Computer object for the executing machine
2. Translates those AD User SIDs to the format "DomainName\User" (Works with users hosted on an external domain as well, as long as trust relationship exists)
3. Adds the translated Users to the Local Administrators Group on the executing machine
