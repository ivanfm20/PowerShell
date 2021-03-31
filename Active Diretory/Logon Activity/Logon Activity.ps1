# This script was developed to search log activity for a specific user, inserted in the script execution.
# It can be used to identify activity on accounts suspected of being compromised or to search the use of a particular account.
#
# Created By Ivan M. - https://github.com/ivanfm20/PowerShell
# Last update on: 30/03/2021
#

# Variables - Clear the required variables
$log = $null
$LogonActivityTable = $null
$i = $null
$l = $null
$searched_user = $null
$index_number = 0
$index = $null

# Define error action preference
$ErrorActionPreference = "SilentlyContinue"

# Creating the table
$LogonActivityTable = New-Object system.Data.DataTable “Logon Activity - Logon Query”

# Creating the columns
$id = New-Object system.Data.DataColumn "ID",([string])
$date = New-Object system.Data.DataColumn "Date",([string])
$LogonStatus= New-Object system.Data.DataColumn "LogonStatus",([string])
$type = New-Object system.Data.DataColumn "Type",([string])
$user = New-Object system.Data.DataColumn "User",([string])
$ipaddress = New-Object system.Data.DataColumn "IPAddress",([string])
$HostLocal = New-Object system.Data.DataColumn "HostLocal",([string])
$ComputerRole = New-Object system.Data.DataColumn "ComputerRole",([string])
$status = New-Object system.Data.DataColumn "Status",([string])

# Adding columns to the table
$LogonActivityTable.columns.add($id)
$LogonActivityTable.columns.add($date)
$LogonActivityTable.columns.add($LogonStatus)
$LogonActivityTable.columns.add($type)
$LogonActivityTable.columns.add($user)
$LogonActivityTable.columns.add($ipaddress)
$LogonActivityTable.columns.add($HostLocal)
$LogonActivityTable.columns.add($ComputerRole)
$LogonActivityTable.columns.add($status)

# Reads the start date, leaving it blank considers 1/1/2000
$startTmp = read-host "`nEnter the search start date (MM/DD/YYYY, default is 1/1/2000)" 
if ($startTmp.length -eq 0){$startTmp = "1/1/2000"} 
$startDate = get-date $startTmp 
 
# Reads the end date, if left blank considers the current date
$endTmp = read-host "Enter the end date of the search (MM/DD/YYYY, the default is the current date)" 
if ($endTmp.length -eq 0){$endTmp = get-date} 
$endDate = get-date $endTmp 

# Read the user name to search, and do NOT search as "*" if left blank.
$searched_user = read-host "`nEnter the requested full user, without the domain" 
# Validates if the value is blank, if it is, the execution is finished.
if ($searched_user -like $null)
{
Write-Output "`nBlank user, ending execution."
Exit
}

# Validates if the value is "*" ('\*), if it is, execution is finished.
if ($searched_user -match '\*')
{
Write-Output "`nUser with '*', ending execution."
Exit
}

# Sets the variable to the computer name
$LocalName = $env:computername

# Validates the type of computer on which you are collecting the logs
$ComputerType = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty DomainRole
if ($ComputerType -match '0'){$ComputerRole = "Standalone Workstation"}
if ($ComputerType -match '1'){$ComputerRole = "Member Workstation"}
if ($ComputerType -match '2'){$ComputerRole = "Standalone Server"}
if ($ComputerType -match '3'){$ComputerRole = "Member Server"}
if ($ComputerType -match '4|5'){$ComputerRole = "Domain Controller"}

Write-Host "`nCollecting local data from $($LocalName) - User '$($searched_user)'. "`tStart: "$startDate "`tEnd: "$endDate "
 
    # Attempts to collect events 4624 and 4625 for the informed user, in the configured date range
    if ((Get-WinEvent -FilterHashtable @{LogName='Security';StartTime=$startDate;EndTime=$endDate;ID='4624','4625';data=$searched_user} -ErrorAction SilentlyContinue `
     |  Where-Object {$_.Properties[5].value -like "*$searched_user*" -and $_.Properties[5].value -notlike "*$*"}) -eq $null)
        { 
        # If there are no logs with the specified criteria, write it in the table
        Write-Output "There are no logs with the criteria specified on the host $($LocalName)"

        # Creates the line
        $row = $LogonActivityTable.NewRow()

        # Adds data to the line
        $row.date = "N/A"
        $row.id = "N/A"
        $row.type = "There are no logs with the criteria specified on this host"
        $row.user = $searched_user
        $row.IPAddress = "N/A"
        $row.HostLocal = $LocalName
        $row.LogonStatus = "N/A"
        $row.ComputerRole = $ComputerRole
        $row.Status = "N/A"

        # Adds the row to the table
        $LogonActivityTable.Rows.Add($row)
        }
    
        else {

        $log += Get-WinEvent -FilterHashtable @{LogName='Security';StartTime=$startDate;EndTime=$endDate;ID='4624','4625';data=$searched_user}`
           | Where-Object {$_.Properties[5].value -like "*$searched_user" -and $_.Properties[5].value -notlike "*$*"}

        # Loop for each event stored in the variable $log 
        foreach ($i in $log)
        {    
        $row = $LogonActivityTable.NewRow()

        $row.date = (($i.TimeCreated).tostring("MM/dd/yyyy HH:mm:ss"))
        $row.id = $i.Id
        $row.type = $i.Properties[8].value
            # If the login fails, the login number field becomes 10
            if ($row.Type -eq "%%2313") {$row.type = $i.Properties[10].value}
            if ($row.Type -eq "%%2304") {$row.type = $i.Properties[10].value}
            # Categorization of logon types
            if ($row.Type -eq "2") {$row.type = "Local logon (interactive)"}
            if ($row.Type -eq "3") {$row.type = "Network logon"}
            if ($row.Type -eq "4") {$row.type = "Batch logon (scheduled task, for example)"}
            if ($row.Type -eq "5") {$row.type = "Service logon"}
            if ($row.Type -eq "7") {$row.type = "Unlock"}
            if ($row.Type -eq "8") {$row.type = "Network logon with clear text (IIS, for example)"}
            if ($row.Type -eq "9") {$row.type = "Network logon with new credentials. (RUNAS, for example) - Assess possible PtH"}
            if ($row.Type -eq "10") {$row.type = "Remote interactive logon (MSTSC)"}
            if ($row.Type -eq "11") {$row.type = "Interactive login with cached credentials"}
            if ($row.Type -eq "12") {$row.type = "Remote interactive logon (MSTSC) with cached credentials"}
            if ($row.Type -eq "13") {$row.type = "Unlock with cached credentials"}
                
            if ($i.Id -eq "4624") {$row.LogonStatus = "Login Success"}
            if ($i.Id -eq "4625") {$row.LogonStatus = "Login failed"}
            
        $row.user = $i.Properties[5].value
        
        # If a RUNAS is performed for another user: If the logon type is "2" and the IP is ":: 1", it is RUNAS 
        if (($i.Properties[8].value -eq "2") -and ($i.Properties[18].value -eq "::1")) {$row.user = "$($i.Properties[5].value) - by RUNAS"}
        
        # If the event changes, the position of the IP changes as well. Below the adaptation of the IP field
        if ($i.Id -eq "4624") {$row.ipaddress = $i.Properties[18].value}
        if ($i.Id -eq "4625") {$row.ipaddress = $i.Properties[19].value}
                    
        $row.HostLocal = $i.MachineName
        $row.ComputerRole = $ComputerRole
        if ($ComputerRole -eq "Domain Controller"){$row.Status = "See the log at the login source"}
        if ($ComputerRole -ne "Domain Controller"){$row.Status = "Original logon event"}
        
        $LogonActivityTable.Rows.Add($row)
        }
    }

    # If it is a Domain Controller, try to collect logs 4771 and 4769
    if ($ComputerRole -eq "Domain Controller")
    {
    
    # Resets the log variable to try to collect Kerberos authentication failure events, which may not generate 4625 failure event
    $log = $null
    $log += Get-WinEvent -FilterHashtable @{LogName='Security';StartTime=$startDate;EndTime=$endDate;ID='4771','4769'}`
       | Where-Object {$_.Properties[0].value -like "*$searched_user*" -and $_.Properties[5].value -notlike "*$*"}

    foreach ($l in $log)
        {
        $row = $LogonActivityTable.NewRow()

        $row.date = (($l.TimeCreated).tostring("MM/dd/yyyy HH:mm:ss"))
        $row.id = $l.Id
        
        if ($l.KeywordsDisplayNames -eq "Audit Success")
        {$row.Type = "Authentication success"
         $row.LogonStatus = "Kerberos authentication success"}
        
        if ($l.KeywordsDisplayNames -eq "Audit Failure")
        {$row.Type = "Authentication failure"
         $row.LogonStatus = "Kerberos authentication failed"}

        $row.user = $l.Properties[0].value
        # Removes the text that is generated in the IP field
        $row.IPAddress = ($l.Properties[6].value).Replace("::ffff:","")
        $row.HostLocal = $l.MachineName
        $row.ComputerRole = $ComputerRole
        $row.Status = "See the log at the login source"
                
        $LogonActivityTable.Rows.Add($row)
        }
    }
      
<#
# -------------------------------------------------------------------------------------------------------------
# Process for removing duplicate entries
# 1 - Export the table data to a CSV
# 2 - Read the exported CSV and export a new temporary CSV without duplicate values. "Select-Object -Unique" is needed to consider "case insensitive".
# 3 - Import the temporary CSV into the data table, sorting by date
# 4 - Removes the first exported file
# 5 - Removes the second exported file
#>
$LogonActivityTable | Export-Csv -Path ".\Logon Activity - Local Host.csv" -NoTypeInformation
Get-Content ".\Logon Activity - Local Host.csv" | Select-Object -Unique | Get-Unique > ".\No_Duplicates.csv"
$LogonActivityTable = Import-Csv -Path ".\No_Duplicates.csv" | Sort-Object Date -Descending
Remove-Item ".\Logon Activity - Local Host.csv"
Remove-Item ".\No_Duplicates.csv"


# -------------------------------------------------------------------------------------------------------------
# Result output - Output by Grid View (with adjustment of column names) and CSV Export used in the other script
$LogonActivityTable | Select @{Name="ID";Expression={$_.ID}},
                             @{Name="Date / Hour";Expression={$_.Date}},
                             @{Name="Logon Status";Expression={$_.LogonStatus}},
                             @{Name="Type";Expression={$_.Type}},
                             @{Name="Username";Expression={$_.User}},
                             @{Name="IP Logon";Expression={$_.IPAddress}}, 
                             @{Name="Local host";Expression={$_.HostLocal}},
                             @{Name="Computer type";Expression={$_.ComputerRole}},
                             @{Name="Status";Expression={$_.Status}} | Out-GridView -Title "Logon activity on $($LocalName) in $(Get-Date)"


$FilePath = "c:\Users\$($env:USERNAME)\Desktop"
$LogonActivityTable | Export-Csv -Path "$($FilePath)\Logon activity on $($LocalName) in $((get-date).tostring("dd.MM.yyyy HH.mm")).csv" -NoTypeInformation -Delimiter ","
$FileName = "$($FilePath)\Logon activity on $($LocalName) in $((get-date).tostring("dd.MM.yyyy HH.mm")).csv"
Write-Output "`nFile saved in: $($FileName)"
Write-Output "`nExecution finished."