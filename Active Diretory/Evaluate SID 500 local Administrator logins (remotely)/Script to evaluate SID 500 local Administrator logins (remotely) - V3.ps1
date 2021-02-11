# This script was created to evaluate local logons with the Administrator account of SID 500.
# The script tries to access the machines, if it can access it, it identifies the SID 500 and the name of the local Administrator,
# Fetch the logon events (success only, since the failure ones do not bring the Admin SID) with this account, and write the results in a table.
#
# Created By Ivan M. - https://github.com/ivanfm20/PowerShell
# Created on: 05/02/2021
# Last update on: 10/02/2021

# -------------------------------------------------------------------------------------------------------------

# Cleaning variables
$log = $null
$LogonActivityTable = $null
$aux = $null
$i = $null
$usuario_procurado = $null
$index_number = 0
$index = $null
$TestHost = $null
$LocalAdmin = $null

# Creating the table 
$LogonActivityTable = New-Object system.Data.DataTable “Local Login activity with account ID 500”

# Creating the columns
$index = New-Object system.Data.DataColumn "Index",([string])
$id = New-Object system.Data.DataColumn "ID",([string])
$date = New-Object system.Data.DataColumn "Date",([string])
$type = New-Object system.Data.DataColumn "Type",([string])
$status = New-Object system.Data.DataColumn "Status",([string])
$user = New-Object system.Data.DataColumn "User",([string])
$Hostname = New-Object system.Data.DataColumn "Hostname",([string])
$RemoteLogonFrom = New-Object system.Data.DataColumn "RemoteLogonFrom",([string])

# Adding columns to the table
$LogonActivityTable.columns.add($index)
$LogonActivityTable.columns.add($id)
$LogonActivityTable.columns.add($date)
$LogonActivityTable.columns.add($type)
$LogonActivityTable.columns.add($status)
$LogonActivityTable.columns.add($user)
$LogonActivityTable.columns.add($Hostname)
$LogonActivityTable.columns.add($RemoteLogonFrom)

# -------------------------------------------------------------------------------------------------------------

# Function to import the file with the hosts
# Add the library to open the box to select the file, if it is not already loaded
Add-Type -AssemblyName System.Windows.Forms

# Comment to add the file and wait 3 seconds for the selection screen to appear
Write-Output "`nSelect the file with the list of machines:"
Start-Sleep -Seconds 2

# Opens the box to select the text file - Add only user names in this file, without header
$SelectedFile = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Filter = 'Arquivos de Texto (*.txt)|*.txt|CSV (*.csv)|*.csv'
}
$null = $SelectedFile.ShowDialog()

# Validates that the file with the list has been added to the script. If yes it continues, if not, it ends.
if ($SelectedFile.FileName -eq "")
    {
    Write-Output "`nNo file selected. Execution finished."
    Exit
    }

# Process for removing duplicate entries
# 1 - Import data from a file (TXT or CSV) into a CSV format table with "Host" header
# 2 - Read the imported content and export to a temporary CSV, saved in the same location as the original file, and without duplicate values (temp.csv)
# 3 - Import the temporary CSV into the data table
# 4 - Removes the exported temporary file
$TestHost = Import-Csv -Path $SelectedFile.FileName -Header Host
Get-Content $SelectedFile.FileName | Get-Unique > "$($SelectedFile.InitialDirectory)\temp.csv"
$TestHost = Import-Csv -Path "$($SelectedFile.InitialDirectory)\temp.csv" -Header Host
Remove-Item "$($SelectedFile.InitialDirectory)\temp.csv"

# -------------------------------------------------------------------------------------------------------------

# Clears the hosts counter and displays the total entries in the table
$TotalHosts = $TestHost.count
$H = $null
$HostsCount = 0

# -------------------------------------------------------------------------------------------------------------
# Set the default error action
$ErrorActionPreference = "SilentlyContinue"
# -------------------------------------------------------------------------------------------------------------

# Loads a function to test connection by RPC on remote event log
function Get-WinEventTest {
    param ($HostTest)
    try {$TestRPC = Get-WinEvent -ComputerName $HostTest -LogName Security -MaxEvents 1}
    catch [System.Diagnostics.Eventing.Reader.EventLogException]
        {
        if ($_.Exception -match "The RPC server is unavailable"){Write-Output "ConnectionError"}
        if ($_.Exception -match "The remote procedure call failed"){Write-Output "ConnectionError"}
        }
    if ($TestRPC -ne $null){Write-Output "NoError"}
    }
# -------------------------------------------------------------------------------------------------------------
 
foreach ($H in $TestHost)
    {
    $HostsCount = $HostsCount + 1
    Write-Output "`nTesting the host $($HostsCount) of $($TotalHosts) hosts - $($H.Host)"
    
	# Make the connection test. If true (connection returns True) and port 49665 responds, log collection continues and the information is stored in Log_Temp.CSV
    if (Test-Connection $($H.Host) -Quiet -Count 1 -ErrorAction SilentlyContinue)
        {
        # Find out the user name for SID 500. If error continues silently
        $LocalAdmin = $null
        $LocalAdmin = Get-WmiObject -Class Win32_UserAccount -Namespace "root\cimv2" -ComputerName $H.Host -Filter "SID like 'S-1-5-%-500'" -ErrorAction SilentlyContinue
            
        if ($LocalAdmin -eq $null)
            {
            # If it was possible to access the host, but was not possible to query the Administrator's SID, write this information in the table (probably blocked by WMI firewall rule on remote host)
            # Firewall default rule: Windows Management Instrumentation (WMI-In)
			# Ref: https://docs.microsoft.com/en-us/windows/win32/wmisdk/connecting-to-wmi-remotely-starting-with-vista
            Write-Output "Host available but WMI query blocked. Check WMI rule on firewall on remote host"

            # Create the line
            $row = $LogonActivityTable.NewRow()

            # Add the data to the line.
            $row.date =  "N/A"
            $row.id =  "N/A"
            $row.type =  "Host available but WMI query blocked. Check WMI rule on firewall on remote host"
            $row.Status = "N/A"
            $row.user =  "N/A"
            $row.Hostname = $H.Host
            $row.RemoteLogonFrom = "N/A"

            # Add the row to the table
            $LogonActivityTable.Rows.Add($row)
            }
            # IF host available and WMI query returns an SID, proceeds whit the query
		    else {
            
			$AdminName = $LocalAdmin.Name
            $SIDdoLocalAdmin = $LocalAdmin.SID
            # Write the message on the screen
            Write-Host "Host accessed trough WMI. Trying to collect the SID 500 user name logs '$($AdminName)'."
            # Run the function "Get-WinEventTest", if it can connect and consult the host, generate "NoError" status
            $ResultWinEventTest = Get-WinEventTest -HostTest $H.Host
            if ($ResultWinEventTest -eq "NoError")
            {         
            
            # Validates if there are logon events with the Administrator's SID, if it has continues, if it does not, proceed to the next Else
            if ((Get-WinEvent -ComputerName $H.Host -FilterHashtable @{LogName='Security';ID='4624','4625','4776';data=$SIDdoLocalAdmin} -ErrorAction SilentlyContinue) -ne $null)
                {
                # Stores in a variable (+=) each Security event identified on the specified date, with specific events, where the user is the specified one
                # Note: Although events 4625 and 4776, both logon failure, are listed, they are not handled because the failure log does not contain the user's SID.
                $log += Get-WinEvent -ComputerName $H.Host -FilterHashtable @{LogName='Security';ID='4624','4625','4776';data=$SIDdoLocalAdmin}
                
                # Loop for each event stored in the $ log variable 
                foreach ($i in $log)
                        {    
                        $row = $LogonActivityTable.NewRow()

                        # Add the data to the line. The logon message is filtered by the user name, number 5 in the Properties item
                        $row.date =  $i.TimeCreated
                        $row.id =  $i.Id
                        $row.type =  $i.Properties[8].value
                            # If the login fails, the login number field becomes 10
                            if ($row.Type -eq "%%2313") {$row.type =  $i.Properties[10].value}
                            # Categorization of logon types
                            if ($row.Type -eq "2") {$row.type =  "Local logon (Interactive)"}
                            if ($row.Type -eq "3") {$row.type =  "Logon trough network"}
                            if ($row.Type -eq "4") {$row.type =  "Batch logon (scheduled task, for example)"}
                            if ($row.Type -eq "5") {$row.type =  "Logon as a service"}
                            if ($row.Type -eq "7") {$row.type =  "Unlock"}
                            if ($row.Type -eq "8") {$row.type =  "Logon trough network in clear text (IIS, for example)"}
                            if ($row.Type -eq "9") {$row.type =  "Network logon with new credentials (RUNAS, for example)"}
                            if ($row.Type -eq "10") {$row.type =  "Remote interactive logon (MSTSC)"}
                            if ($row.Type -eq "11") {$row.type =  "Interactive logon with cachaed credential"}
                            if ($row.Type -eq "12") {$row.type =  "Remote logon (MSTSC) with cached credential"}
                            if ($row.Type -eq "13") {$row.type =  "Unlock with cached credential"}
                
                            # If the login communicates by Kerberos, the type is not identified
                            if ($i.Id -eq "4776") {$row.Type = "Attempted logon with Kerberos"} # do host "$i.Properties[3].value""}
            
                        $row.Status = $i.KeywordsDisplayNames
                            if ($i.Id -eq "4624") {$row.Status = "Login Success"}
                            if ($i.Id -eq "4625") {$row.Status = "Login failed"}
                            # If the login communicates by Kerberos, the status is updated
                            if ($i.Id -eq "4776") {$row.Status = "Login failed - Kerberos"}  
            
                        $row.user =  $i.Properties[5].value
                            # If an ID 500 RUN is run for another user, it will be identified as 500 RUNAS for another user
                            # If the logon type is "2" and the IP is ":: 1", it is RUNAS 
                            if (($i.Properties[8].value -eq "2") -and ($i.Properties[18].value -eq "::1"))
                                {$row.user =  "$($i.Properties[5].value) - trough RUNAS with SID 500"}
                            # If the login communicates by Kerberos, the user name is updated
                            if ($i.Id -eq "4776")
                                {$row.user = $i.Properties[1].value} 

                        $row.Hostname = $i.MachineName
                        $row.RemoteLogonFrom = $i.Properties[18].value

                        $LogonActivityTable.Rows.Add($row)

                        }
                }
                
                else {
                     # IF it was possible to access the host, but there are no logs with the Administrator's SID, write this information in the table
                     Write-Output "There are no logon events with the account $($LocalAdmin.Name) on host $($H.Host)"

                     $row = $LogonActivityTable.NewRow()

                     $row.date =  "N/A"
                     $row.id =  "N/A"
                     $row.type =  "There are no logon events with the account $($LocalAdmin.Name) on host"
                     $row.Status = "N/A"
                     $row.user =  "N/A"
                     $row.Hostname = $H.Host
                     $row.RemoteLogonFrom = "N/A"

                     $LogonActivityTable.Rows.Add($row)

                     }
			}
            # ELSE for IF on $ResultWinEventTest -ne "NoError" - Means that connection was not permitted
            else {
                 # If it was not possible to access the host, could be blocked by Firewall RPC rule.
                 Write-Output "Host available by WMI but query blocked. Check RPC rule on firewall on remote host"

                 $row = $LogonActivityTable.NewRow()

                 $row.date =  "N/A"
                 $row.id =  "N/A"
                 $row.type =  "Host available by WMI but query blocked. Check Remote Event Log Management (RPC) rule on firewall on remote host"
                 $row.Status = "N/A"
                 $row.user =  "N/A"
                 $row.Hostname = $H.Host
                 $row.RemoteLogonFrom = "N/A"

                 $LogonActivityTable.Rows.Add($row)

                 }
            }
	}
    # ELSE for if test connection failed
    else {
             Write-Output "It was not possible to access the host."

             # Create the line
             $row = $LogonActivityTable.NewRow()

             # Add the data to the line.
             $row.date =  "N/A"
             $row.id =  "N/A"
             $row.type =  "Could not access the host"
             $row.Status = "N/A"
             $row.user =  "N/A"
             $row.Hostname = $H.Host
             $row.RemoteLogonFrom = "N/A"

             # Add the row to the table
             $LogonActivityTable.Rows.Add($row)

             }
}

# -------------------------------------------------------------------------------------------------------------

# Process to remove duplicate entries (hostname and IP cases from the same machine) and sort the table by Date and then Hostname
# 1 - Export the table data to a CSV
# 2 - Read the exported CSV and export a new temporary CSV without duplicate values. "Select-Object -Unique" is needed to consider "case insensitive". Sort sorts the data
# 3 - Import the temporary CSV into the data table
# 4 - Removes the first exported file
# 5 - Removes the second exported file
$LogonActivityTable | Export-Csv -Path ".\Remove_Duplicates.csv" -NoTypeInformation
Get-Content ".\Remove_Duplicates.csv" | Select-Object -Unique | Sort Date,Hostname | Get-Unique > ".\Without_Duplicates.csv"
$LogonActivityTable = Import-Csv -Path '.\Without_Duplicates.csv'
Remove-Item ".\Remove_Duplicates.csv"
Remove-Item ".\Without_Duplicates.csv"

# -------------------------------------------------------------------------------------------------------------

# Add an Index number to each entry, to make further manipulation easier. The value is added after removing duplicates
$index_number = 0
$row.Index = 0
foreach ($row in $LogonActivityTable)
	{
    $index_number = $index_number + 1
    $row.Index = $index_number
	}

# -------------------------------------------------------------------------------------------------------------

# Result output
# Grid View output
$LogonActivityTable | Out-GridView -Title "Local Login activity with account ID 500 in $(Get-Date)"

# Option to save to CSV - Displays the file path if saved. The "` n "adds an ENTER to the line
$output = read-host "`nDo you want to save the result in a .CSV file? Type Y for Yes, or any other key to finish."
if ($output -match "Y")
	{ 
	$LogonActivityTable | Export-Csv -Path "$($SelectedFile.InitialDirectory)\Local Login activity with account ID 500 in $((get-date).tostring("d.MM.yyyy HH.mm")).csv" -NoTypeInformation -Delimiter ","
	$FileName = "$($SelectedFile.InitialDirectory)\Local Login activity with account ID 500 in $((get-date).tostring("d.MM.yyyy HH.mm")).csv"
	Write-Output "`nFile saved in: $($FileName)"
	Write-Output "`nExecution finished."
	}
# If not saved, end execution
if ($output -notmatch "Y")
	{Write-Output "`nExecution finished."}