# This script unifies the login information generated with the "Login Activity" script.
# In this way, it is possible to identify the sequence of logins performed on the hosts.
# 
# Created By Ivan M. - https://github.com/ivanfm20/PowerShell
# Last update on: 16/02/2021
#

# Variables - Clear the required variables and set the default file header
$SelectedFiles = $null
$LogonTable = $null
$TempImportTable = $null
$TempHeader = $null
$HeaderDefault = "ID,Date,LogonStatus,Type,User,IPAddress,HostLocal,ComputerRole,Status"

# -------------------------------------------------------------------------------------------------------------

Write-Output "`nSelect the generated log files with the 'Logon Activity' script.`n"
Start-Sleep -Seconds 2
Add-Type -AssemblyName System.Windows.Forms
$SelectedFiles = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = [Environment]::GetFolderPath('Desktop')
    Multiselect = $true
    Filter = 'CSV Files (*.csv)|*.csv'}
$null = $SelectedFiles.ShowDialog()
# Validates that the file with the list has been added to the script. If yes it continues, if not, it ends.
if ($SelectedFiles.FileName -eq "")
    {
    Write-Output "`nNo file selected. Execution finished."
    Exit
    }
# -------------------------------------------------------------------------------------------------------------

Write-Output "Total of $($SelectedFiles.FileNames.count) selected files. Starting validation.`n"
$FilesCount = 0

foreach ($f in $SelectedFiles.FileNames)
    {
    # Checks whether the header of the imported file is the same as the standard generated in the other script
    $TempImportTable = Import-Csv -Path $f 
    $TempHeader = $TempImportTable[0].psobject.Properties.name -join ","
    if ($TempHeader -eq $HeaderDefault)
        {
        $LogonTable += $TempImportTable
        Write-Output "File '$($f)' successfully imported."
        $FilesCount = $FilesCount + 1
        }
        else {Write-Output "File header '$($f)' nonstandard. File not imported."}
    }

Write-Host "`nImported $($FilesCount) of $($SelectedFiles.FileNames.count) selected files."

<#
# -------------------------------------------------------------------------------------------------------------
# Process for removing duplicate entries
# 1 - Export the table data to a CSV
# 2 - Read the exported CSV and export a new temporary CSV without duplicate values. "Select-Object -Unique" is needed to consider "case insensitive".
# 3 - Import the temporary CSV into the data table, sorting by date
# 4 - Removes the first exported file
# 5 - Removes the second exported file
#>

$LogonTable | Export-Csv -Path ".\Logon Activity - Local Host.csv" -NoTypeInformation
Get-Content ".\Logon Activity - Local Host.csv" | Select-Object -Unique | Get-Unique > ".\No_Duplicates.csv"
$LogonTable = Import-Csv -Path ".\No_Duplicates.csv" | Sort-Object Date -Descending
Remove-Item ".\Logon Activity - Local Host.csv"
Remove-Item ".\No_Duplicates.csv"
# -------------------------------------------------------------------------------------------------------------

# Result output - Output by Grid View (with adjustment of column names) and CSV Export used in the other script
$LogonTable | Select @{Name="ID";Expression={$_.ID}},
                     @{Name="Date / Hour";Expression={$_.Date}},
                     @{Name="Logon Status";Expression={$_.LogonStatus}},
                     @{Name="Type";Expression={$_.Type}},
                     @{Name="Username";Expression={$_.User}},
                     @{Name="IP Logon";Expression={$_.IPAddress}}, 
                     @{Name="Local host";Expression={$_.HostLocal}},
                     @{Name="Computer type";Expression={$_.ComputerRole}},
                     @{Name="Status";Expression={$_.Status}} | Sort-Object "Date / Hour" | Out-GridView -Title "Logon Activity unified on $(Get-Date)"


$FilePath = "c:\Users\$($env:USERNAME)\Desktop"
$LogonTable | Export-Csv -Path "$($FilePath)\Logon Activity unified on $((get-date).tostring("dd.MM.yyyy HH.mm")).csv" -NoTypeInformation -Delimiter ","
$FileName = "$($FilePath)\Logon Activity unified on $((get-date).tostring("dd.MM.yyyy HH.mm")).csv"
Write-Output "`nFile saved in: $($FileName)"
Write-Output "`nExecution finished."

