# This script collects NTFS permissions of all folders in a given folder selected by the user.
# During the collection the information is exported to a CSV chosen by the user.
# 
# Created in 28/05/2022
# 
# Version 1
# 

# Creating the main table
$CheckNTFSPermissions = New-Object system.Data.DataTable “Check_NTFS_Permissions”

# -------------------------------------------------------------------------------------------------------------

# Creation of columns
$FolderPath = New-Object system.Data.DataColumn "FolderPath",([string])
$FolderName = New-Object system.Data.DataColumn "FolderName",([string])
$InheritanceStatus = New-Object system.Data.DataColumn "InheritanceStatus",([string])
$AccessPermissions = New-Object system.Data.DataColumn "AccessPermissions",([string])

# -------------------------------------------------------------------------------------------------------------

# Add the columns
$CheckNTFSPermissions.columns.add($FolderPath)
$CheckNTFSPermissions.columns.add($FolderName)
$CheckNTFSPermissions.columns.add($InheritanceStatus)
$CheckNTFSPermissions.columns.add($AccessPermissions)

# -------------------------------------------------------------------------------------------------------------

# Add the library to open the box to select the file if it is not loaded
Add-Type -AssemblyName System.Windows.Forms

# Comment to add the file and wait 2 seconds for the selection screen to appear
Write-Output "`nSelect the folder you want to check for NTFS permissions:"
Start-Sleep -Seconds 2

# Open the box to select the folder
$SelectedFolder = $null
$SelectedFolder = New-Object System.Windows.Forms.FolderBrowserDialog
$null = $SelectedFolder.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))

Write-Output "Selected Folder: $($SelectedFolder.SelectedPath)"

# Validates if the file with the list has been added to the script. If yes, continue, if not, end.
if ($SelectedFolder.FileName -eq "")
    {
    Write-Output "No file selected. Execution finished."
    Exit
    }

#----------------------------------------------------------------------------------------------

# Adds the library to open the box to select the location to save the file
Add-Type -AssemblyName System.Windows.Forms

# Comment to save the file and wait 2 seconds for the selection screen to appear
Write-Output "`nSelect the path and name to save the result to a CSV file:"
Start-Sleep -Seconds 2

# Open the box to select the name and where to save the CSV
$SelectedFile = New-Object System.Windows.Forms.SaveFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Filter = 'CSV File (*.csv)|*.csv'
}
$null = $SelectedFile.ShowDialog()
Write-Output "Selected File: $($SelectedFile.FileName)"
# Validates if the file with the list has been added to the script. If yes, continue, if not, end.
if ($SelectedFile.FileName -eq "")
    {
    Write-Output "`nNo file selected. Execution finished."
    Exit
    }

#----------------------------------------------------------------------------------------------

$Directories = Get-ChildItem -Path $SelectedFolder.SelectedPath #-Recurse
$TotalDirectories = $Directories.Count

Write-Output "`nStarting the query. Identified $($TotalDirectories) folders. Please wait."

$Count = 0

foreach ($d in $Directories)
        {
        $Count = $Count + 1
        Write-Output "Querying the folder $($Count) from $($TotalDirectories)"

        # Create the variable with the full path of the folder to collect ACL
        $CheckFolders = "$($SelectedFolder.SelectedPath)\$($d)"
        $ACL = Get-Acl -Path $CheckFolders | Select-Object *

        # Create the line in table
        $row = $CheckNTFSPermissions.NewRow()
        
        $row.FolderPath = $SelectedFolder.SelectedPath
        $row.FolderName = "$($SelectedFolder.SelectedPath)\$($d)"
        $row.InheritanceStatus = $ACL.AreAccessRulesProtected
        $row.AccessPermissions = $ACL.AccessToString
		
		# Add row to table
        $CheckNTFSPermissions.Rows.Add($row)
        
        $CheckNTFSPermissions | Export-Csv -Path "$($SelectedFile.FileName)" -NoTypeInformation -Delimiter ","
        
        }


Write-Output "`nFile saved in: $($SelectedFile.FileName)"
Write-Output "`nExecution finished."
