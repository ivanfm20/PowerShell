# This script was developed to collect members of the local Administrators group locally, write to a table and update a file from the network.
# It is necessary to adjust the "$ RemotePath" variables with their network share and file name where the administrators will be saved
# (it is necessary to create the file because the script only updates the file).
#
# Created By Ivan M. - https://github.com/ivanfm20/PowerShell
# Created on: 24/02/2021
# Last update on: 24/02/2021

# -------------------------------------------------------------------------------------------------------------


# Creating the tables
$LocalList = New-Object system.Data.DataTable “Local Administrators List”

# Creating the columns
$Date = New-Object system.Data.DataColumn "Date",([string])
$HostName = New-Object system.Data.DataColumn "HostName",([string])
$AdminNames = New-Object system.Data.DataColumn "AdminNames",([string])

# Adding columns to the table
$LocalList.columns.add($Date)
$LocalList.columns.add($HostName)
$LocalList.columns.add($AdminNames)

# Capture the computer name
$HostName = $env:computername
# Configure the remote path - Change to your share and file
$RemotePath = "\\ServerName\ShareName\FileName.txt"

$ErrorActionPreference = "SilentlyContinue"

# Clear variables and reset the counter
$LocalAdminUsersAndGroups = $null
$i = 0

# An error "1789" can be generated if it is not possible to resolve the group's SID, which can be caused if the machine is out of contact with the DC.
# For this reason the test waits to try to collect again.
# Tries to collect the Administrators group. If you can't, wait 5 minutes to try again. The count indicates the attempt for 4 hours.

do {
    # Try to collect the group
    $LocalAdminUsersAndGroups = Get-LocalGroupMember -Name "Administrators"
        # If the variable is empty, waits 5 minutes and adds 1 to the counter
        if (!$LocalAdminUsersAndGroups)
            {Start-Sleep -Seconds 300}
            # As long as the counter is less than 48 (4 hours), it keeps trying to collect
        if ($i -ge "48") {break}
    $i = $i+1
   # As long as the variable is empty, keep trying 
   } while ($LocalAdminUsersAndGroups -eq $null)


# For each collected administrator (user or group), write in the table
foreach ($l in $LocalAdminUsersAndGroups)
        {
        # Create the table, add the content and add the row to the table.
        $row = $LocalList.NewRow()
        $row.Date = (Get-Date).ToString("MM.dd.yyyy")
        $row.HostName = $HostName
        $row.AdminNames = $l.Name
        $LocalList.Rows.Add($row)
        }


# Reset the counter again
$i = 0
# Test if remote path is available
while ((Test-Path -Path $RemotePath) -ne $true)
        {# If the path is not available, try every 5 minutes.
         Start-Sleep -Seconds 300
            # As long as the counter is less than 48 (4 hours), it keeps trying to access the path
            if ($i -ge "48") {break}
         $i = $i+1
        }


# When the remote path is available, add the result to the remote file (-Append)
$LocalList | Export-Csv -Path $RemotePath -Append -NoTypeInformation
