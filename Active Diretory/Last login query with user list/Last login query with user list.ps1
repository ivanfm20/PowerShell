# Script for querying last account login, from a list os users.
# The "LastLogon" attribute is registered only on the Domain Controller that the account used to log on.
# For this reason, it is necessary to collect this information from all DCs and identify the latest logon .
#
# If a list that is too large can slow down the environment, as it will query all this accounts in all ADs.
#
# This script uses a function available in the Technet gallery, which loads the function "Get-AdUsersLastLogon" (credits to "Jeremy Reeves", quoted below)
#
# Created By Ivan M. - https://github.com/ivanfm20/PowerShell
# Created on: 30/01/2021
# Last update on: 03/02/2021
#
# To identify accounts in a given group, use the commands to generate the list of users:
#
# $RecursiveQuery = Get-ADGroupMember "Domain Admins" -Recursive
# $RecursiveQuery.samaccountname> c:\temp\user_list.txt
#

<#
Function to get last logon on DCs.
Source:
Get Most Recent lastLogon for Users From Domain Controllers
https://gallery.technet.microsoft.com/scriptcenter/Get-Last-Logon-for-Users-c8e3eab2

########################################################################## 
    The purpose of this PowerShell script is to collect the last logon  
    for user accounts on each DC in the domain, evaluate, and return the 
    most recent logon value. 
 
        Author:   Jeremy Reeves 
        Modified: 02/14/2018 
        Notes:    Must have RSAT Tools if running on a workstation 
 
##########################################################################
#>

# Import the function Get-ADUsersLastLogon
# ------------------------------------------------------------------------------------------------------------- 
Write-Host "`nInitializing the script."
Write-Host "`nLoading function Get-ADUsersLastLogon..."

function Get-ADUsersLastLogon($Username="*",$FilePath=$null) { 
 
    #$FilePath = "C:\Temp\UserLastLogon-" 
 
    function Msg ($Txt="") { 
        Write-Host "$([DateTime]::Now)    $Txt" 
    } 
 
    #Cycle each DC and gather user account lastlogon attributes 
     
    $List = @() #Define Array 
    (Get-ADDomain).ReplicaDirectoryServers | Sort | % { 
 
        $DC = $_ 
        Msg "Reading informations from $DC" 
        $List += Get-ADUser -Server $_ -Filter "samaccountname -like '$Username'" -Properties LastLogon | Select SamAccountName,LastLogon,@{n='DC';e={$DC}} 
 
    } 
 
    Msg "Ordering for the latest login." 
     
    $LatestLogOn = @() #Define Array 
    $List | Group-Object -Property samaccountname | % { 
 
        $LatestLogOn += ($_.Group | Sort -prop lastlogon -Descending)[0] 
 
    } 
     
    $List.Clear() 
 
    $FileName = $FilePath

    if ($Username -eq $null) { #$Username variable was not set.    Running against all user accounts and exporting to a file. 
 
        #$FileName = "$FilePath$([DateTime]::Now.ToString("yyyyMMdd-HHmmss")).csv" 
        
        try {
            $LatestLogOn | Select SamAccountName, LastLogon, @{n='lastlogondatetime';e={[datetime]::FromFileTime($_.lastlogon)}}, DC
                # If the file path is empty, do not export. If filled, export the result.
                if ($FileName -ne $null)
                {
                $LatestLogOn | Select SamAccountName, LastLogon, @{n='lastlogondatetime';e={[datetime]::FromFileTime($_.lastlogon)}}, DC | Export-CSV -Path $FileName -NoTypeInformation -Force -Append
                Msg "Results exported in: $FileName"
                }
            } 
            catch {} 
        } 

        else { #$Username variable was set, and may refer to a single user account. 
 
        if ($LatestLogOn) 
           { 
           $LatestLogOn | Select SamAccountName, @{n='LastLogon';e={[datetime]::FromFileTime($_.lastlogon)}}, DC | FT
                # If the file path is empty, do not export. If filled, export the result.
                if ($FileName -ne $null)
                    {
                    $LatestLogOn | Select SamAccountName, @{n='LastLogon';e={[datetime]::FromFileTime($_.lastlogon)}}, DC | Export-CSV -Path $FileName -NoTypeInformation -Force -Append
                    }
           }
            else
                { Msg "$Username not found." } 
 
    } 

    $LatestLogon.Clear() 
} 

# End of function Get-ADUsersLastLogon import
# -------------------------------------------------------------------------------------------------------------

# Validates the import of Get-ADUsersLastLogon function. If it's not loaded, the script ends.

if ((Get-Command -ListImported | Where-Object {$_.Name -eq "Get-ADUsersLastLogon"}) -eq $null) {
    Write-Host "Function Get-ADUsersLastLogon not loaded. Run only the function snippet to assess the problem. The script will end."
    Start-Sleep -Seconds 5
    Exit
    }

Write-Host "Function Get-ADUsersLastLogon loaded.`n"

# -------------------------------------------------------------------------------------------------------------

# Attempts to import the Active Directory module and then validates that it was imported successfully. If it doesn't work, the script is terminated.

Write-Host "Importing Active Directory module..."

Import-Module ActiveDirectory -ErrorAction SilentlyContinue

if ((Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}) -eq $null) {
    Write-Host "Active Directory module not installed. Install the module to continue. The script will end."
    Exit
    }

Write-Host "Active Directory module imported."
# -------------------------------------------------------------------------------------------------------------

# Reset the variables
$FilePath = $null
$FileName = $null
$UserName = $null

# -------------------------------------------------------------------------------------------------------------

# Function to import the file with the user names
# Adds a library to open the box to select the file, if it is not already loaded
Add-Type -AssemblyName System.Windows.Forms

# Comment to add the file and wait 3 seconds for the selection screen to appear
Write-Output "`nSelect the file with the list of users:"
Start-Sleep -Seconds 2

# Opens the box to select the text file - Add only user names in this file, without header
$UserList = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Filter = 'Text Files (*.txt)|*.txt|CSV (*.csv)|*.csv'
}
$null = $UserList.ShowDialog()

# Validates that the file with the list has been added to the script. If yes it continues, if not, it ends.
if ($UserList.FileName -eq "")
    {
    Write-Output "`nNo file selected. Execution finished."
    Exit
    }

Write-Host "User list selected."

# -------------------------------------------------------------------------------------------------------------

# Function to remove duplicate entries
# 1 - Import data from a file (TXT or CSV) into a CSV format table with the "Users" header
# 2 - Read the imported content and export to a temporary CSV, saved in the same location as the original file, and without duplicate values (temp.csv)
# 3 - Import the temporary CSV into the data table
# 4 - Removes the exported temporary file
$UserTest = Import-Csv -Path $UserList.FileName -Header Users
Get-Content $UserList.FileName | Select-Object -Unique > "$($UserList.InitialDirectory)\temp.csv"
$UserTest = Import-Csv -Path "$($UserList.InitialDirectory)\temp.csv" -Header Users
Remove-Item "$($UserList.InitialDirectory)\temp.csv"
# -------------------------------------------------------------------------------------------------------------

# Reset the user counter and display the total entries in the table
$TotalUsers = $UserTest.count
$U = $null
$CountUsers = 0

if ($UserTest.Count -eq "0")
    {Write-Host "`nUser list empty. Please add a list of 1 or more users."
    Exit}

# -------------------------------------------------------------------------------------------------------------

# Prompts you for the path to save the file.
# Add the library to open the box to select the location to save the file
Add-Type -AssemblyName System.Windows.Forms

# Comment to save the file and wait 2 seconds for the selection screen to appear
Write-Output "`nSelect the path to save the result file (CSV):"
Start-Sleep -Seconds 2

# Opens the box to select the name and where CSV will be saved
$SelectedFile = New-Object System.Windows.Forms.SaveFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Filter = 'Arquivos CSV (*.csv)|*.csv'
}
$empty_var = $SelectedFile.ShowDialog()

# Validates that the file with the list has been added to the script. If yes it continues, if not, it ends.
if ($SelectedFile.FileName -eq "")
    {
    Write-Output "No directory selected. Execution finished."
    Exit
    }

# If the file exists, delete it to be able to write a new one and use the "-Append" of the Export-CSV function
if (Test-Path $SelectedFile.FileNames)
    {Remove-Item "$($SelectedFile.FileNames)"}

$FilePath = $SelectedFile.FileName

#----------------------------------------------------------------------------------------------
Write-Host "File path selected"

Write-Host "`nIdentified $($TotalUsers) users on the list. Starting the query...`n"

foreach ($U in $UserTest)
    {
    $CountUsers = $CountUsers + 1
    Write-Output "`nRunning the query on the user $($CountUsers) of $($TotalUsers)"
    Get-ADUsersLastLogon -Username $U.users -FilePath $FilePath
    }


Write-Output "`nThe identified users have been saved to: $($FilePath)"
    
Write-Output "`nExecution finished."