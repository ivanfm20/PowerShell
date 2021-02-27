# Script to enable the Windows firewall to evaluate the logs.
# 
# First it generates a backup of the rules, disables all rules, creates rules of inbound and
# outbound with ANY/ANY, increases the size of the log and enables the logs for the profiles.
#
# Created By Ivan M. - https://github.com/ivanfm20/PowerShell
# Last update on: 26/02/2021
#
# -------------------------------------------------------------------------------------------------------------

# Collect the Firewall status
$Firewall_Status = (Get-NetFirewallProfile | Select-Object Name,Enabled)

# If one of the three profiles is enabled, increase the log size, enables the successful and dropped packages and ends the script
foreach ($status in $Firewall_Status)
    {
    if ($status.Enabled -eq $true)
        {
        # Increases the log from 4MB to 10MB
        netsh advfirewall set allprofiles logging maxfilesize 10000

        # Enables logs of all profiles for dropped/blocked packages
        netsh advfirewall set allprofiles logging droppedconnections enable

        # Enables logs of all profiles for successful/allowed packages
        netsh advfirewall set allprofiles logging allowedconnections enable

        Exit
        }
    }

# Tests if C:\Temp folder exists to save the backup of Firewall rules
if ((Test-Path -Path "C:\Temp") -eq $false)
    {
    # If the folder does not exist, it is created
    New-Item -Path "C:\" -Name "Temp" -ItemType "Directory"
    }
    # If the folder exists, continue

# Tests if the backup file exists. If it already exists, end the script
if ((Test-Path -Path "C:\Temp\Firewall_Rules.wfw") -eq $true)
    {
    Exit
    }

# Export the rules to import in the future, if necessary
netsh advfirewall export C:\Temp\Firewall_Rules.wfw

# Commands to imports the rules and the firewall status (ON or OFF) - Use if you want to import the rules back
# netsh advfirewall import C:\Temp\firewall_rules.wfw
# Removes created rules (which are already removed when the backup is imported in the row above)
# netsh advfirewall firewall set rule name="_Allow_ANY_Inbound" new enable=no
# netsh advfirewall firewall set rule name="_Allow_ANY_Outbound" new enable=no

# Export the rules in .CSV
$Rules = (New-object –comObject HNetCfg.FwPolicy2).rules
$Rules | Export-Csv -Path C:\Temp\Firewall_Rules_CSV.csv -NoTypeInformation

# Command to disable all firewall rules
netsh advfirewall firewall set rule all new enable=no

# Increases the log from 4MB to 10MB
netsh advfirewall set allprofiles logging maxfilesize 10000

# Inbound ANY-ANY rule
netsh advfirewall firewall add rule name="_Allow_ANY_Inbound" service=any profile=any protocol=any interface=any dir=in action=allow

# Outbound ANY-ANY rule
netsh advfirewall firewall add rule name="_Allow_ANY_Outbound" service=any profile=any protocol=any interface=any dir=out action=allow

# Enables logs of all profiles for dropped / blocked packages
netsh advfirewall set allprofiles logging droppedconnections enable

# Enables logs of all profiles for successful/allowed packages
netsh advfirewall set allprofiles logging allowedconnections enable

# Enable all Firewall profiles
netsh advfirewall set allprofiles state on


# Below, some examples of rules to be applied after evaluating the logs

# Enable incoming 3389 - Allow Range
# netsh advfirewall firewall add rule name="Allow_3389_Inbound" profile=any protocol=TCP localport=3389 remoteip=10.170.0.0/24 interface=any dir=in action=allow

# Block 3389 input - Block Range - For adding more ranges, use comma and IP/mask
#netsh advfirewall firewall add rule name="Block_3389_Inbound" profile=any protocol=TCP localport=3389 remoteip=192.168.111.0/24,192.168.112.0/24 interface=any dir=in action=block

# Block 445 inbound - Any IP
#netsh advfirewall firewall add rule name="Block_445_Inbound" profile=any protocol=TCP localport=445 remoteip=any interface=any dir=in action=block

