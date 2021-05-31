# Script to massive test ports remotely with Start-Parallel module
# 
# The script receives a user-loaded host list (hostname or IP only, no headers and in column format)
# and test a specific port.
# In the current format of the script it is not possible to insert a port directly in the parallel execution function, because it does not accept
# the additional argument (it needs to be customized for this, which does not have time yet). For this reason, the port is fixed in the script code, 
# having to be manually changed, if necessary (it is identified as "# IF NECESSARY, CHANGE THE PORT HERE"
# First, it tests if the IP is responding a PING and if it is, it tests the informed port.
# At the beginning it is asked how many hosts are tested simultaneously, after the "Start-Parallel" function is imported (and removed at the end).
#
# Created By Ivan M. - https://github.com/ivanfm20/PowerShell
# Created on: 31/05/2021
# Last update on: 31/05/2021
#

# -------------------------------------------------------------------------------------------------------------
# Imports the Start-Parallel module from James O'Neill - https://www.powershellgallery.com/packages/Start-parallel/1.3.0.0
# Installation: Can be installed with the command "Install-Module -Name Start-parallel". Internet access required.

    <#
 Source: PowerShell Gallery - Microsoft
 URL: https://www.powershellgallery.com/packages/Start-parallel/1.3.0.0
 Author: James O'Neill
 
 .Synopsis
     Runs multiple instances of a command in parallel.
 .Description
     This script will allow mutliple instances of a command to run at the same time with different argumnets,
     each using its own runspace from a pool of runspaces - runspaces get their own seperate thread.
     Parts of this use the work of Ryan Witschger - http://www.get-blog.com/?p=189
     and of Boe Prox https://learn-powershell.net/2012/05/13/using-background-runspaces-instead-of-psjobs-for-better-performance/
 .PARAMETER Command
     The PowerShell Command to run multiple instances of; it must be self contained -
     instances can't share variables or functions with each other or the session which launches them.
     The command can be a cmdlet, function, EXE or .ps1 file.
 .PARAMETER ScriptBlock
     Either a PowerShell scriptblock or the path to a file which can be read and executed as a script block.
 .PARAMETER InputObject
     The InputObject contains the argument(s) for the command. This can either be single item or an array,
     and can take input from the pipeline. It must either be a string , in which case the command will be run as
     Command <string>
     Or a hash table in which case the the command will be run as
     Command -Key1 value1 -key2 value 2 ....
     Or a psObject in which case the the command will be run as
     Command -PropertyName1 value1 -PropertyName2 value 2 ....
 .PARAMETER MaxThreads
     This is the maximum number of runspaces (threads) to run at any given time. The default value is 50.
 .PARAMETER MilliSecondsDelay
      When looping waiting for commands to complete, this value introduces a delay between each check to prevent
      excessive CPU utilization. The default value is 200ms. For long runnng processes, this value can be increased.
 .PARAMETER MaxRunSeconds
      The total time that can be spent looping waiting for the commands to complete.
      This will terminate the run if all threads have not completed within 5 minutes (300 seconds) by default.
 .EXAMPLE
     $xpmachines = Get-ADComputer -LDAPFilter "(operatingsystem=Windows XP*)" | select -expand name ; Start-parallel -InputObject $xpmachines -Command "Test-Connection"
     Gets Computers in Active directory which AD thinks are Windows XP and pings them using the default settings for Test-Connection.
 .EXAMPLE
     Get-ADComputer -LDAPFilter "(operatingsystem=Windows XP*)" | select -expand name | Start-parallel -Command "Test-Connection"
     More efficient than the previous example, because threads are started before Get-ADComputer has returned all the computers
 .EXAMPLE
     Get-ADComputer -LDAPFilter "(operatingsystem=Windows XP*)" | select -expand name | Start-parallel -Scriptblock {PARAM ($a) ; Test-Connection -ComputerName $a -Count 1}
     Changes the previous example to use a script block where the default parameters for Test-Connection are specified
 .EXAMPLE
     Get-ADComputer -LDAPFilter "(operatingsystem=Windows XP*)" | foreach {@{computerName=$_.name;Count=1}} | Start-parallel -Command "Test-Connection" -MaxThreads 20 -MaxRunSeconds 120
     Develops the previous example to run test-connection with the computername and count parameters explicitly passed.
     Reduces the maximum number of threads to 20 and the maxiumum processing time to 2 minutes.
 .EXAMPLE
     1..10 | Start-Parallel -Scriptblock ${Function:\quickping}
     In this example QuickPing is a function which accepts the last octet of an IP address to ping.
     Calling it as a script block in this way avoids any problems with function being a scope where start-parallel can't access it.
#>
Function Start-Parallel {
    [CmdletBinding(DefaultParameterSetName='Command')]
    Param  (
          [parameter(Mandatory=$true,ParameterSetName="Command",HelpMessage="Enter the command to process",Position=0)]
          $Command , 
          [parameter(Mandatory=$true,ParameterSetName="Block")]
          $Scriptblock,
          $TaskDisplayName = "Tasks", 
          [Parameter(ValueFromPipeline=$true)]$InputObject,
          [int]$MaxThreads           = 50,
          [int]$MilliSecondsDelay    = 200,
          [int]$MaxRunSeconds        = 300
    )
    Begin  { #Figure out what it is we have to run: did we get -command or -scriptblock and was either a file name ?
        Write-Progress -Activity "Setting up $TaskDisplayName"  -Status "Initializing"    
        if ($PSCmdlet.ParameterSetName -eq "Command") {
            try   { $Command = Get-Command -Name  $Command  }
            catch { Throw "$command does not appear to be a valid command."}
        }
        else {  if ($Scriptblock -isnot [scriptblock] -and   (Test-Path -Path  $Scriptblock) )  {
                    $ScriptBlock      = [scriptblock]::create((Get-Item -Path  $Scriptblock).OpenText().ReadToEnd()) }
                if ($Scriptblock -isnot [scriptblock]) {Throw "Invalid Scriptblock"}          
        }
        #Prepare the pool of worker threads: note that runspaces don't inherit anything from the session they're launched from,
        #So the command / script block must be self contained.
        $taskList     = @()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
        $runspacePool.Open()
        Write-Verbose -Message ("Runspace pool opened at " + ([datetime]::Now).ToString("HH:mm:ss.ffff"))
    }
    Process{ #Usually we're going to recieve parameters via the pipeline, so the threads get set up here.
         ForEach  ($object in $InputObject)  { #setup a PowerShell pipeline ; set-up what will be run and the parameters and add it to the pool
            if    ($ScriptBlock )            { $newThread = [powershell]::Create().AddScript($ScriptBlock)  }
            else                             { $newThread = [powershell]::Create().AddCommand($Command)     } 
            if      ($object -is [Int] -or
                     $object -is [string]   ) { $newThread.AddArgument($object)             | Out-Null  }
            elseif  ($object -is [hashtable]) {
                ForEach ($key in $object.Keys){ $newThread.AddParameter($key, $object.$key) | Out-Null  }
            }
            elseif  ($object -is [psobject])  {
                Foreach ($key in (Get-Member -InputObject $object -MemberType NoteProperty).Name) {
                                                $newThread.AddParameter($key, $object.$key) | Out-Null 
                }
            }
 
            $newThread.RunspacePool = $runspacePool
            #BeginInvoke runs the thread asyncronously - i.e. it gets its turn when there is a free runspace
            $handle                 = $newThread.BeginInvoke()
            #Keep a list of tasks so we can get them back in the end{} block
            $taskList              += New-Object -TypeName psobject -Property @{"Handle"=$handle; "Thread"=$newThread;}
            Write-Progress -Activity "Setting up $TaskDisplayName"  -Status ("Created: " + $taskList.Count + " tasks" )
        }
        $taskList | Where-Object {$_.Handle.IsCompleted } | ForEach-Object {
                $_.Thread.EndInvoke($_.Handle)
                $_.Thread.Dispose()
                $_.Thread = $_.Handle = $Null
        }
    }
    End    {#We have a bunch of threads running. Keep looping round until they all complete or we hit our time out,
        Write-Verbose  -Message ("Last of $($tasklist.count) threads started: " + ([datetime]::Now).ToString("HH:mm:ss.ffff"))
        Write-Verbose  -Message ("Waiting for " + $TaskList.where({ $_.Handle.IsCompleted -eq $false}).count.tostring()  + " to complete.") 
        Write-Progress -Activity "Setting up $TaskDisplayName"  -Completed
        #We need to to know when to stop if a thread hangs. Until that time, while there are threads still going ....
        $endBy = (Get-Date).AddSeconds($MaxRunSeconds) 
        While ($TaskList.where({$_.Handle}) -and (Get-Date) -lt $endBy)  {
            $UnFinishedCount = $TaskList.where({ $_.Handle.IsCompleted -eq $false}).count
            Write-Progress -Activity "Waiting for $TaskDisplayName to complete" -Status "$UnFinishedCount tasks remaining" -PercentComplete (100 * ($TaskList.count - $UnFinishedCount)  / $TaskList.Count) 
            #For the tasks that have finished; call EndInovoke() - to receive the Output from the runspace and send it to our output.
            # and get rid of the thread
            $TaskList | Where-Object {$_.Handle.IsCompleted } | ForEach-Object {
                $_.Thread.EndInvoke($_.Handle)
                $_.Thread.Dispose()
                $_.Thread = $_.Handle = $Null
            }
            #Don't run in too tight a loop
            Start-Sleep -Milliseconds $MilliSecondsDelay        
        } 
        Write-Verbose -Message ("Wait for threads ended at " + ([datetime]::Now).ToString("HH:mm:ss.ffff"))
        Write-Verbose -Message ("Leaving " + $TaskList.where({ $_.Handle.IsCompleted -eq $false}).count + " incomplete.")
        #Clean up.
        Write-Progress -Activity "Waiting for $TaskDisplayName to complete" -Completed
        [void]$RunspacePool.Close()   
        [void]$RunspacePool.Dispose() 
        [gc]::Collect()
   } 
}

# Try to import the Start-Parallel module. If not, it returns the error and stops the script.
if ((Get-Command -ListImported | Where-Object {$_.Name -eq "Start-Parallel"}) -eq $null) {
    Write-Host "Parallel execution module not installed. Install the module to continue. The script will be finalized."
    Start-Sleep -Seconds 5
    Exit
    }

# -------------------------------------------------------------------------------------------------------------

# Table creation
$PortTestTable = New-Object system.Data.DataTable "Port connection test"

# Column creation
$index = New-Object system.Data.DataColumn "Index",([string])
$date = New-Object system.Data.DataColumn "Date",([string])
$FromIP = New-Object system.Data.DataColumn "FromIP",([string])
$ToIP = New-Object system.Data.DataColumn "ToIP",([string])
$Ping = New-Object system.Data.DataColumn "Ping",([string])
$Port = New-Object system.Data.DataColumn "Port",([string])
$Result = New-Object system.Data.DataColumn "Result",([string])
$Status = New-Object system.Data.DataColumn "Status",([string])

# Adding columns to the table
$PortTestTable.columns.add($index)
$PortTestTable.columns.add($date)
$PortTestTable.columns.add($FromIP)
$PortTestTable.columns.add($ToIP)
$PortTestTable.columns.add($Ping)
$PortTestTable.columns.add($Port)
$PortTestTable.columns.add($Result)
$PortTestTable.columns.add($Status)

# -------------------------------------------------------------------------------------------------------------

# Function to import the file with hosts
# Add the library to open the box to select the file if it is not loaded
Add-Type -AssemblyName System.Windows.Forms

# Informs to add the file and waits 3 seconds for the screen for selection to appear
Write-Output "`nSelect the file with the list of machines:"
Start-Sleep -Seconds 3

# Opens the box to select the text file - Add only the usernames to this file, no header
$SelectedFile = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Filter = 'Text Files (*.txt)|*.txt|CSV (*.csv)|*.csv'
}
$null = $SelectedFile.ShowDialog()

# Validates if the file with the list was added to the script. If yes, continue, if not, end.
if ($SelectedFile.FileName -eq "")
    {
    Write-Output "`nNo file selected. The script will be finalized."
    Exit
    }

# -------------------------------------------------------------------------------------------------------------

# Function to remove duplicate entries
# 1 - Import data from a file (TXT or CSV) into a CSV format table with "Host" header
# 2 - Read the imported content and export to a temporary CSV, saved in the same location as the original file, and without the duplicate values (temp.csv)
# 3 - Import Temporary CSV into Data Table
# 4 - Remove the exported temporary file
$HostTest = Import-Csv -Path $SelectedFile.FileName -Header Host
Get-Content $SelectedFile.FileName | Get-Unique > "$($SelectedFile.InitialDirectory)\temp.csv"
$HostTest = Import-Csv -Path "$($SelectedFile.InitialDirectory)\temp.csv" -Header Host
Remove-Item "$($SelectedFile.InitialDirectory)\temp.csv"

# -------------------------------------------------------------------------------------------------------------

# Reads the maximum number of processes that will run concurrently. Added some rules to not overload the source host.
$Parallel_Execution = $null
# Remove-Variable $Parallel_Execution
[int]$Parallel_Execution = read-host "`nEnter how many processes you want to run concurrently. Standard and recommended value: 10. Maximum value: 50" 
if ($Parallel_Execution.length -eq "") 
    {Write-Output "`nNo number entered. Using the default value of 10."
     $Parallel_Execution = 10}
if ($Parallel_Execution -isnot [int])
    {Write-Output "`nNon-numeric value identified. Using the default value of 10."
     $Parallel_Execution = 10}
if ($Parallel_Execution -gt 50)
    {Write-Output "`nValue above 50. Using the maximum value of 50."
     $Parallel_Execution = 50}
if ($Parallel_Execution -eq 0)
    {Write-Output "`nNon-numeric value or equal to 0 (zero) identified. Using the default value of 10."
     $Parallel_Execution = 10}



# -------------------------------------------------------------------------------------------------------------

# Function disabled as it is not possible to pass a variable from outside the function.
# Read the chosen port
# $TestedPort = read-host "`nEnter the port you want to test (3389 for example)" 
# if ($TestedPort.length -eq "")
# {Write-Output "`nNo port selected. The script will be finalized."
#    Exit
# } 

# -------------------------------------------------------------------------------------------------------------

# Reset the hosts counter and display the total entries in the table
$TotalHosts = $HostTest.count
$H = $null
$HostsCount = 0

# -------------------------------------------------------------------------------------------------------------
 
# Captures the machine's local IP, other than 127.0.0.1
$IPLocal = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch "Loopback"} | Select-Object IPAddress

# -------------------------------------------------------------------------------------------------------------

# Default event for errors where the door is closed
$ErrorActionPreference = "SilentlyContinue"

Write-Output "`nTest started in $((Get-Date).tostring("dd/MM/yyyy HH:mm:ss")) - $Parallel_Execution parallel running"

Write-Output "`nStarting the Ping test in $TotalHosts hosts, please wait..."

# Function to test PING.
function Ping-Test {
    param ($HostTest)
    $a = Test-Connection $HostTest -Quiet -Count 1
    Write-Output "$($HostTest),$a"

}

$Result_Ping = Start-Parallel -InputObject $HostTest -Command Ping-Test -TaskDisplayName "Ping Test" -MaxThreads $Parallel_Execution

# Convert Array to Table
$Conversion = ConvertFrom-Csv -InputObject $Result_Ping -Header ToIP,Ping
$Conversion | Export-Csv -Path ".\Temp_Ping.csv" -NoTypeInformation
$PortTestTableResult = Import-Csv -Path ".\Temp_Ping.csv"
Remove-Item ".\Temp_Ping.csv"

# Creates the list only with the IPs that responded to the Ping. On the second line, create the variable containing only the identified hosts
$Ping_List_OK = $PortTestTableResult | Where-Object {$_.Ping -eq "True"} | Select-Object ToIp
$Ping_List_OK = $Ping_List_OK.ToIP

Write-Output "`nPing test completed."

# -------------------------------------------------------------------------------------------------------------

# Function to test the PORT - It is not possible to specify a variable from outside the function to be used inside it. For this reason, the port is fixed in code.
# If necessary to test another port, change the entry below (and additional texts in the script sequence).

Write-Output "`nStarting the Port test on $($Ping_List_OK.count) hosts, please wait..."

function Port-Test {
    param ($Ping_List_OK)
    # IF NECESSARY, CHANGE THE PORT HERE										  
    $b = New-Object Net.Sockets.TcpClient $Ping_List_OK, 3389
    if ($b.Connected -eq $true)
        {Write-Output "$($Ping_List_OK),$($b.Connected)"}
        else {Write-Output "$($Ping_List_OK),False"}

}

# Run the test function that is captured by the variable
$Result_Port = Start-Parallel -InputObject $Ping_List_OK -Command Port-Test -TaskDisplayName "Port Test" -MaxThreads $Parallel_Execution

Write-Output "`nPort Test completed."

# -------------------------------------------------------------------------------------------------------------

# Convert Array to PING Result Table - Add header to file list
$Conversion = ConvertFrom-Csv -InputObject $Result_Ping -Header ToIP,Ping
$Conversion | Export-Csv -Path ".\Temp_Ping.csv" -NoTypeInformation
$Result_Ping_Table = Import-Csv -Path ".\Temp_Ping.csv"
Remove-Item ".\Temp_Ping.csv"

# -------------------------------------------------------------------------------------------------------------

# For each host in the list, add the Ping result information. For the port, add "N/A", to be replaced in the second block.
foreach ($l in $Result_Ping_Table)
    {if ($l.Ping -eq "True")
        {
        # Creates the row in the table
        $row = $PortTestTable.NewRow()
        $row.date = Get-Date
        $row.FromIP = $IPLocal.IPAddress.GetValue(1)
        $row.ToIP = $l.ToIP
        $row.Ping = "Ping OK"
        $Row.Port = "3389"
        $row.Result = "N/A"
        $row.Status = "N/A"
        # Add row to table
        $PortTestTable.Rows.Add($row)
        }
        else {
             # Creates the row in the table
             $row = $PortTestTable.NewRow()
             $row.date = Get-Date
             $row.FromIP = $IPLocal.IPAddress.GetValue(1)
             $row.ToIP = $l.ToIP
             $row.Ping = "Ping NO OK"
             $Row.Port = "3389"
             $row.Result = "No Ping reply"
             $row.Status = "No Ping reply"
             # Add row to table
             $PortTestTable.Rows.Add($row)
             }
    }

Write-Output "`nTest completed in $((Get-Date).tostring("dd/MM/yyyy HH:mm:ss")) - $Parallel_Execution parallel runs"

# -------------------------------------------------------------------------------------------------------------

# Removes the Start-Parallel function added at the beginning of the script
Write-Output "`nRemoving the Start-Parallel module added at the beginning of the script..."

Remove-Item Function:Start-Parallel

if ((Get-Command -ListImported | Where-Object {$_.Name -eq "Start-Parallel"}) -eq $null) {
    Write-Host "Stat-Parallel module successfully removed."
    Start-Sleep -Seconds 5
    }
    Else {Write-Host "The Start-Parallel Module has not been successfully removed. Restart PowerShell so that it is completely removed."}

# -------------------------------------------------------------------------------------------------------------

# Convert Array to Port Result Table - Add the header to the file list
$Conversion = ConvertFrom-Csv -InputObject $Result_Port -Header ToIP,Port
$Conversion | Export-Csv -Path ".\Temp_Ping.csv" -NoTypeInformation
$Result_Port_Table = Import-Csv -Path ".\Temp_Ping.csv"
Remove-Item ".\Temp_Ping.csv"

# -------------------------------------------------------------------------------------------------------------

# For each port test result host, if it is the same as the ToIP list in the table, add the Port test information.
# Each host ($p) in $PortTestTable that does not have "Ping NOT OK" in the Ping field, a new foreach to compare the IP of $p to the IP of $t ($Result_Port_Table)
# If the IP is the same, read the port test result and fill in the columns (from $p, which is the final table, $PortTestTable)
foreach ($p in $PortTestTable)
    {
    if ($p.Ping -ne "Ping NO OK")
        {
        foreach ($t in $Result_Port_Table)
            {if ($p.ToIP -eq $t.ToIP)
                {if ($t.Port -eq "True")
                    {
                    $p.Result = "Port 3389 Open"
                    $p.Status = "OPEN"
                    }
                if ($t.Port -eq "False")
                    {
                    $p.Result = "Port 3389 Closed"
                    $p.Status = "CLOSED"
                    }
                }
            }
        }
    }

# -------------------------------------------------------------------------------------------------------------

# Process to remove duplicate entries (hostname and IP cases from the same machine) and sort the table by Date and then Hostname
# 1 - Export the table data to a CSV
# 2 - Read exported CSV and export new temporary CSV without duplicate values. Required the "Select-Object -Unique" to consider "case insensitive". Sort sorts the data
# 3 - Import Temporary CSV into Data Table
# 4 - Removes the first exported file
# 5 - Remove the second exported file
$PortTestTable | Export-Csv -Path ".\Remove_Duplicated.csv" -NoTypeInformation
Get-Content ".\Remove_Duplicated.csv" | Select-Object -Unique | Sort Date,Hostname | Get-Unique > ".\No_Duplicated.csv"
$PortTestTable = Import-Csv -Path '.\No_Duplicated.csv'
Remove-Item ".\Remove_Duplicated.csv"
Remove-Item ".\No_Duplicated.csv"

# -------------------------------------------------------------------------------------------------------------

# Adds an Index number to each entry to make later manipulation easier. Value is added after removing duplicates
$index_number = 0
$row.Index = 0
foreach ($row in $PortTestTable)
	{
    $index_number = $index_number + 1
    $row.Index = $index_number
	}

# -------------------------------------------------------------------------------------------------------------

# Output of result
# Output via Grid View - Handling result columns
$PortTestTable | Select @{Name="Index";Expression={$_.Index}},
                        @{Name="Date";Expression={$_.Date}},
                        @{Name="Test from";Expression={$_.FromIP}},
                        @{Name="Ping on";Expression={$_.ToIP}},
                        @{Name="Ping status";Expression={$_.Ping}},
                        @{Name="Port";Expression={$_.Port}},
                        @{Name="Result";Expression={$_.Result}},
                        @{Name="Status";Expression={$_.Status}} | Out-GridView -Title "Port 3389 tested on $((Get-Date).tostring("dd/MM/yyyy HH:mm")) - $($TotalHosts) hosts"

# Option to save to CSV - Displays the file path if saved. The "`n" adds an ENTER to the line
$output = read-host "`nDo you want to save the result in a .CSV file? Type Y for Yes, or any other key to finish."
if ($output -match "Y")
	{ 
	$PortTestTable | Select @{Name="Index";Expression={$_.Index}},
					        @{Name="Date";Expression={$_.Date}},
					        @{Name="Test from";Expression={$_.FromIP}},
					        @{Name="Ping on";Expression={$_.ToIP}},
					        @{Name="Ping status";Expression={$_.Ping}},
					        @{Name="Port";Expression={$_.Port}},
					        @{Name="Result";Expression={$_.Result}},
					        @{Name="Status";Expression={$_.Status}} | Export-Csv -Path "$($SelectedFile.InitialDirectory)\Port 3389 tested on $((Get-Date).tostring("d.MM.yyyy HH.mm")) - $($TotalHosts) hosts.csv" -NoTypeInformation -Delimiter ","

	$SavedFileName = "$($SelectedFile.InitialDirectory)\Port 3389 tested on $((Get-Date).tostring("dd.MM.yyyy HH.mm")) - $($TotalHosts) hosts.csv"
	Write-Output "`nFile saved in: $($SavedFileName)"
	Write-Output "`nExecution completed."
	}
# If not saved, ends execution.
if ($output -notmatch "Y")
	{
	Write-Output "`nExecution completed."
	}

