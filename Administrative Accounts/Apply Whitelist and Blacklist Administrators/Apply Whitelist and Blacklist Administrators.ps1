# This script was developed to configure the local Administrators group from a list of predefined accounts on the network.
# For each line of the network, validate those that have the host name or "ANY" (any computer), 
# if it is Whitelist it adds the account / group, and if it is Blacklist it removes the account / group.
# 
# Before running, set the share and file name in the $RemotePath variable
#
# Created By Ivan M. - https://github.com/ivanfm20/PowerShell
# Created on: 01/03/2021
# Last update on: 01/03/2021

# -------------------------------------------------------------------------------------------------------------

# Capture the computer name
$HostName = $env:computername
# Set the Administrators group name (if you use different language)
$Group = "Administrators"
# Configure the remote path - Change to your share and file
$RemotePath = "\\ServerName\Share\FileName.txt"

# If the path does not exist, end the script
if ((Test-Path -Path $RemotePath) -eq $false)
   {Exit}

# Imports the list of network administrators
$Admin_List = Import-Csv -Path $RemotePath
# Loads local administrators into the variable
$LocalAdminUsersAndGroups = Get-LocalGroupMember -Name $Group

# For each line in the allowed and blocked administrators file
foreach ($a in $Admin_List)
        {
        # If the name of the machine in the list is the same as that of the computer, or if the name of the list is ANY
        if (($a.Computer -eq $HostName) -or ($a.Computer -eq "ANY"))
            {
            # If the identified line is Whitelist, add the user/group to the group
            if ($a.List -eq "Whitelist")
                {
                # Enable the line below if you want to test by viewing the result
				# Write-Output "Adding the user $($a.Account)"
                Add-LocalGroupMember -Group $Group -Member $a.Account
                }
            # If the identified line is Blacklist, remove the user/group from the group
            if ($a.List -eq "Blacklist")
                {
                # Enable the line below if you want to test by viewing the result
				# Write-Output "Removing the user $($a.Account)"
                Remove-LocalGroupMember -Group $Group -Member $a.Account
                }
            }
            # If the computer is not found, write on the screen - Enable the line below if you want to test by viewing the result
            # else {Write-Output "Computer not found"}
        }