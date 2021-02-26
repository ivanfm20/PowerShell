# Script to collect logs with error events locally.
# This script receives a number in minutes, which is subtracted from the current date / time and collects all error logs
# (AuditFailure, Warning, Error and Critical) at this time.
# Administrative access is required on the host as some logs (such as Security, for example) depend on the privilege.
#
# Created By Ivan M. - https://github.com/ivanfm20/PowerShell
# Last update on: 26/02/2021
#
# -------------------------------------------------------------------------------------------------------------

# Clear variables
$log = $null
$LogError = $null
$startTmp = $null
$startDate = $null
$logs = $null
$Log_Errors = $null

# Creating the tables
$LogError = New-Object system.Data.DataTable “Local error logs”

# Creating the columns
$index = New-Object system.Data.DataColumn "Index",([string])
$id = New-Object system.Data.DataColumn "ID",([string])
$date = New-Object system.Data.DataColumn "Date",([string])
$Level = New-Object system.Data.DataColumn "Level",([string])
$Message = New-Object system.Data.DataColumn "Message",([string])
$IsEnabled = New-Object system.Data.DataColumn "IsEnabled",([string])
$LogName = New-Object system.Data.DataColumn "LogName",([string])
$LogFilePath = New-Object system.Data.DataColumn "LogFilePath",([string])
$RecordCount = New-Object system.Data.DataColumn "RecordCount",([string])

# Adding columns to the table
$LogError.columns.add($index)
$LogError.columns.add($id)
$LogError.columns.add($date)
$LogError.columns.add($Level)
$LogError.columns.add($Message)
$LogError.columns.add($IsEnabled)
$LogError.columns.add($LogName)
$LogError.columns.add($LogFilePath)
$LogError.columns.add($RecordCount)

# -------------------------------------------------------------------------------------------------------------

# Reads the time in minutes to retrieve logs
[int]$startTmp = read-host "`nEnter the time in minutes (which will be subtracted from the current time) that you want to search for logs. Maximum value 1440 (1 day)" 
if ($startTmp.length -eq "") 
    {Write-Output "`nNo number entered. Using the default value 5 minutes."
     $startTmp = 5}
if ($startTmp -isnot [int])
    {Write-Output "`nIdentified non-numeric value. Using the default value 5 minutes."
     $startTmp = 5}
if ($startTmp -gt 1440)
    {Write-Output "`nValue above 1440 minutes (1 day). Using the maximum value 1440 (1 day)."
     $startTmp = 1440}
if ($startTmp -eq 0)
    {Write-Output "`nNon-numeric value or equal to 0 (zero) identified. Using the default value 5 minutes."
     $startTmp = 5}

$startDate = (Get-Date) - (New-TimeSpan -Minutes $startTmp)

Write-Output "`nPeriod of error logs to be loaded: $($startTmp) minutes - From $($startDate) to $(Get-Date)"

# -------------------------------------------------------------------------------------------------------------

Write-Output "`nLoading the list of logs..."

# Loads the list of Windows logs
$logs = Get-WinEvent -ListLog *

Write-Output "`nTotal of $($logs.count) logs identified. Validating logs that contain data..."

# Clear the value of the variables and convert to an array to be able to add more items to each loop
$Temporary_Result_OK = $null
$Temporary_Result_NOOK = $null

$Temporary_Result_OK = @()
$Temporary_Result_NOOK = @()

# For each log name try to see if there are logs. If it exists, register it in the $Temporary_Result_OK . If it does not exist, register $Temporary_Result_NOOK
foreach ($l in $logs)
    {
    $result = Get-WinEvent -ListLog "$($l.logname)" -ErrorAction SilentlyContinue | Select-Object -Property LogName,IsEnabled,LogFilePath,RecordCount
    if ($result -ne $null)
        {$Temporary_Result_OK += Get-WinEvent -ListLog "$($l.logname)" -ErrorAction SilentlyContinue | Select-Object -Property LogName,IsEnabled,LogFilePath,RecordCount}
        else {$Temporary_Result_NOOK += "$($l.logname),Nao disponivel,Nao disponivel"}
    }

# -------------------------------------------------------------------------------------------------------------

# Clear the error logs variable
$Log_Errors = $null

Write-Output "`nValidating logs that contain errors..."

# For each log with results as enabled, data from the specified time are collected and added to the table
foreach ($r in $Temporary_Result_OK)
    {
    if ($r.IsEnabled -eq "True")
        {
        $Log_Name = $r.LogName
        $Log_Errors = Get-WinEvent -FilterHashtable @{LogName=$Log_Name; StartTime=$startdate} -ErrorAction SilentlyContinue | `
        Where-Object {($_.LevelDisplayName -eq "Warning") -or ($_.LevelDisplayName -eq "Critical") -or ($_.LevelDisplayName -eq "Error") -or ($_.KeyWords -eq "0x8010000000000000")}
        
        foreach ($l in $Log_Errors)
            {
            # Create the line
            $row = $LogError.NewRow()

            $row.Date = $l.TimeCreated
            $row.ID = $l.Id
            $row.Level = $l.LevelDisplayName
            $row.Message = $l.Message
            $row.IsEnabled = "Enabled"
            $row.LogName = $r.LogName
            $row.LogFilePath = $r.LogFilePath
            $row.RecordCount = $r.RecordCount
        
            # Add the row to the table
            $LogError.Rows.Add($row)
            }
        }
    # If the log is disabled, register the information
    else {
         $row = $LogError.NewRow()

         $row.Date = "N/A"
         $row.ID = "N/A"
         $row.Level = "N/A"
         $row.Message = "No messages - Log disabled"
         $row.IsEnabled = "Disabled"
         $row.LogName = $r.LogName
         $row.LogFilePath = $r.LogFilePath
         $row.RecordCount = $r.RecordCount
        
         $LogError.Rows.Add($row)
         }
    }

$Total_Error_Logs = ($LogError | Select-Object ID | Where-Object ID -ne "N/A").count
$Total_Error_Logs_Disabled = ($LogError | Select-Object IsEnabled | Where-Object IsEnabled -eq "Disabled").count
$Total_Error_Logs_WithoutErros = ($logs.count) - ($Total_Error_Logs + $Total_Error_Logs_Disabled)

Write-Output "`nTotal identified logs: $($logs.count)"
Write-Output "Total logs identified containing error events: $($Total_Error_Logs)"
Write-Output "Total logs that are disabled: $($Total_Error_Logs_Disabled)"
Write-Output "Total logs without error events: $($Total_Error_Logs_WithoutErros)"

# -------------------------------------------------------------------------------------------------------------

# Adds an Index number to facilitate file organization
$index_number = 0
$row.Index = 0

foreach ($row in $LogError)
        {
        $index_number = $index_number + 1
        $row.Index = $index_number
        }

# -------------------------------------------------------------------------------------------------------------
            
# Output by Grid View
$LogError | Sort-Object -Property Date | Out-GridView -Title "Result of the evaluation of local error logs (AuditFailure, Warning, Error e Critical)"

# Option to save to CSV - Displays the file path if saved.
$output = read-host "`nDo you want to save the result in a .CSV file? Type Y for Yes, or any other key to finish."
if ($output -match "Y")
    { 
    $FilePath = "c:\Users\$($env:USERNAME)\Desktop"
    $LogError | Sort-Object -Property Date | Export-Csv -Path "$($FilePath)\Evaluation of local error logs in $((get-date).tostring("MM.dd.yyyy HH.mm")).CSV" -NoTypeInformation -Delimiter ","
    $FileName = "$($FilePath)\Evaluation of local error logs in $((get-date).tostring("MM.dd.yyyy HH.mm")).CSV"
    Write-Output "`nFile saved in: $($FileName)"
    Write-Output "`nExecution finished."
    }
# If not saved, execution ends
if ($output -notmatch "Y")
    {
    Write-Output "`nExecution finished."
    }

<# Keyword and level references
$Keywords = @{
    AuditFailure     = 4503599627370496 - By Where-Object, the number is 0x8010000000000000 
    AuditSuccess     = 9007199254740992
    CorrelationHint2 = 18014398509481984
    EventLogClassic  = 36028797018963968
    Sqm              = 2251799813685248
    WdiDiagnostic    = 1125899906842624
    WdiContext       = 562949953421312
    ResponseTime     = 281474976710656
    None             = 0
}

$Levels = @{
    Verbose       = 5
    Informational = 4
    Warning       = 3
    Error         = 2
    Critical      = 1
    LogAlways     = 0
}
#>