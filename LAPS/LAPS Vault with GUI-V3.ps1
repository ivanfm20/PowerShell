# Script with GUI to connect to remote hosts through MSTSC with LAPS password.
# 
# Created By Ivan M. - https://github.com/ivanfm20/PowerShell
# Created on: 30/01/2021
# Last update on: 02/02/2021

# Add form and all functions
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$FormSpace                       = New-Object system.Windows.Forms.Form
$FormSpace.ClientSize            = New-Object System.Drawing.Point(480,400)
$FormSpace.text                  = "LAPS Vault - MSTSC Connection"
$FormSpace.TopMost               = $false

$LBTopic                         = New-Object system.Windows.Forms.Label
$LBTopic.text                    = "Insert the machine name (managed by LAPS) to connecto through MSTSC"
$LBTopic.AutoSize                = $true
$LBTopic.width                   = 25
$LBTopic.height                  = 10
$LBTopic.location                = New-Object System.Drawing.Point(14,30)
$LBTopic.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$LBResult                        = New-Object system.Windows.Forms.Label
$LBResult.text                   = "Connection Results"
$LBResult.AutoSize               = $true
$LBResult.width                  = 25
$LBResult.height                 = 10
$LBResult.location               = New-Object System.Drawing.Point(180,100)
$LBResult.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$LBAdminName                     = New-Object system.Windows.Forms.Label
$LBAdminName.text                = "If Administrator is renamed, insert new Admin name"
$LBAdminName.AutoSize            = $true
$LBAdminName.width               = 25
$LBAdminName.height              = 10
$LBAdminName.location            = New-Object System.Drawing.Point(10,350)
$LBAdminName.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TxMachineName                   = New-Object system.Windows.Forms.TextBox
$TxMachineName.multiline         = $false
$TxMachineName.width             = 202
$TxMachineName.height            = 25
$TxMachineName.location          = New-Object System.Drawing.Point(41,60)
$TxMachineName.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TxAdminName                     = New-Object system.Windows.Forms.TextBox
$TxAdminName.multiline           = $false
$TxAdminName.width               = 202
$TxAdminName.height              = 25
$TxAdminName.location            = New-Object System.Drawing.Point(10,370)
$TxAdminName.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$BtConnect                       = New-Object system.Windows.Forms.Button
$BtConnect.text                  = "Connect by MSTSC"
$BtConnect.width                 = 135
$BtConnect.height                = 30
$BtConnect.location              = New-Object System.Drawing.Point(294,55)
$BtConnect.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TxProgress                      = New-Object System.Windows.Forms.TextBox
$TxProgress.multiline            = $true
$TxProgress.width                = 400
$TxProgress.height               = 200
$TxProgress.location             = New-Object System.Drawing.Point(41,130)
$TxProgress.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$TxProgress.Cursor               = [System.Windows.Forms.Cursors]::Arrow
$TxProgress.ReadOnly             = $True
$TxProgress.ScrollBars           = "Vertical"
$FormSpace.Controls.Add($TxProgress)

$BtExit                          = New-Object system.Windows.Forms.Button
$BtExit.text                     = "Exit"
$BtExit.width                    = 60
$BtExit.height                   = 30
$BtExit.location                 = New-Object System.Drawing.Point(370,350)
$BtExit.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)


# Function to load messages on connection results
Function Add-Message {
    Param ($Message)
    $TxProgress.AppendText("`r`n$Message")
    $TxProgress.AutoSize
    $TxProgress.Refresh()
    $TxProgress.ScrollToCaret()
    }

# Load Active Diretory PowerShell module
# ------------------------------------------------------------------------------------------------------------- 
Write-Host "Initializing LAPS Vault"
Write-Host "`nLoading ActiveDirectory.ps1 module..."

# Try to load ActiveDirectory module and validate if it's loaded. If it isn't loaded, scripts will end.

Import-Module ActiveDirectory -ErrorAction SilentlyContinue

if ((Get-Module -ListAvailable | Where-Object {$_.Name -eq "ActiveDirectory"}) -eq $null)
    {Write-Host "Active Directory module wasn't loaded. Download and install RSAT to continue. Script ended."
    Exit}

Write-Host "Active Directory module loaded.`n`n"
$TxProgress.AppendText("$((get-date).tostring("d.MM.yyyy HH.mm")) - LAPS Vault initialized.`n")
# -------------------------------------------------------------------------------------------------------------

# Button to connect MSTSC using LAPS password
    $BtConnect.Add_Click(
        {
        # Load function to connect through MSTSC
        # Credits: Jaap Brasser - http://www.jaapbrasser.com
        # Availabe in: https://gallery.technet.microsoft.com/Connect-Mstsc-Open-RDP-2064b10b
        Function Connect-Mstsc {
<#   
.SYNOPSIS   
Function to connect an RDP session without the password prompt
    
.DESCRIPTION 
This function provides the functionality to start an RDP session without having to type in the password
	
.PARAMETER ComputerName
This can be a single computername or an array of computers to which RDP session will be opened

.PARAMETER User
The user name that will be used to authenticate

.PARAMETER Password
The password that will be used to authenticate

.PARAMETER Credential
The PowerShell credential object that will be used to authenticate against the remote system

.PARAMETER Admin
Sets the /admin switch on the mstsc command: Connects you to the session for administering a server

.PARAMETER MultiMon
Sets the /multimon switch on the mstsc command: Configures the Remote Desktop Services session monitor layout to be identical to the current client-side configuration 

.PARAMETER FullScreen
Sets the /f switch on the mstsc command: Starts Remote Desktop in full-screen mode

.PARAMETER Public
Sets the /public switch on the mstsc command: Runs Remote Desktop in public mode

.PARAMETER Width
Sets the /w:<width> parameter on the mstsc command: Specifies the width of the Remote Desktop window

.PARAMETER Height
Sets the /h:<height> parameter on the mstsc command: Specifies the height of the Remote Desktop window

.NOTES   
Name:        Connect-Mstsc
Author:      Jaap Brasser
DateUpdated: 2016-10-28
Version:     1.2.5
Blog:        http://www.jaapbrasser.com

.LINK
http://www.jaapbrasser.com

.EXAMPLE   
. .\Connect-Mstsc.ps1
    
Description 
-----------     
This command dot sources the script to ensure the Connect-Mstsc function is available in your current PowerShell session

.EXAMPLE   
Connect-Mstsc -ComputerName server01 -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force)

Description 
-----------     
A remote desktop session to server01 will be created using the credentials of contoso\jaapbrasser

.EXAMPLE   
Connect-Mstsc server01,server02 contoso\jaapbrasser (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force)

Description 
-----------     
Two RDP sessions to server01 and server02 will be created using the credentials of contoso\jaapbrasser

.EXAMPLE   
server01,server02 | Connect-Mstsc -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) -Width 1280 -Height 720

Description 
-----------     
Two RDP sessions to server01 and server02 will be created using the credentials of contoso\jaapbrasser and both session will be at a resolution of 1280x720.

.EXAMPLE   
server01,server02 | Connect-Mstsc -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) -Wait

Description 
-----------     
RDP sessions to server01 will be created, once the mstsc process is closed the session next session is opened to server02. Using the credentials of contoso\jaapbrasser and both session will be at a resolution of 1280x720.

.EXAMPLE   
Connect-Mstsc -ComputerName server01:3389 -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) -Admin -MultiMon

Description 
-----------     
A RDP session to server01 at port 3389 will be created using the credentials of contoso\jaapbrasser and the /admin and /multimon switches will be set for mstsc

.EXAMPLE   
Connect-Mstsc -ComputerName server01:3389 -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) -Public

Description 
-----------     
A RDP session to server01 at port 3389 will be created using the credentials of contoso\jaapbrasser and the /public switches will be set for mstsc

.EXAMPLE
Connect-Mstsc -ComputerName 192.168.1.10 -Credential $Cred

Description 
-----------     
A RDP session to the system at 192.168.1.10 will be created using the credentials stored in the $cred variable.

.EXAMPLE   
Get-AzureVM | Get-AzureEndPoint -Name 'Remote Desktop' | ForEach-Object { Connect-Mstsc -ComputerName ($_.Vip,$_.Port -join ':') -User contoso\jaapbrasser -Password (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) }

Description 
-----------     
A RDP session is started for each Azure Virtual Machine with the user contoso\jaapbrasser and password supersecretpw

.EXAMPLE
PowerShell.exe -Command "& {. .\Connect-Mstsc.ps1; Connect-Mstsc server01 contoso\jaapbrasser (ConvertTo-SecureString 'supersecretpw' -AsPlainText -Force) -Admin}"

Description
-----------
An remote desktop session to server01 will be created using the credentials of contoso\jaapbrasser connecting to the administrative session, this example can be used when scheduling tasks or for batch files.
#>
    [cmdletbinding(SupportsShouldProcess,DefaultParametersetName='UserPassword')]
    param (
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [Alias('CN')]
            [string[]]     $ComputerName,
        [Parameter(ParameterSetName='UserPassword',Mandatory=$true,Position=1)]
        [Alias('U')] 
            [string]       $User,
        [Parameter(ParameterSetName='UserPassword',Mandatory=$true,Position=2)]
        [Alias('P')] 
            [string]       $Password,
        [Parameter(ParameterSetName='Credential',Mandatory=$true,Position=1)]
        [Alias('C')]
            [PSCredential] $Credential,
        [Alias('A')]
            [switch]       $Admin,
        [Alias('MM')]
            [switch]       $MultiMon,
        [Alias('F')]
            [switch]       $FullScreen,
        [Alias('Pu')]
            [switch]       $Public,
        [Alias('W')]
            [int]          $Width,
        [Alias('H')]
            [int]          $Height,
        [Alias('WT')]
            [switch]       $Wait
    )

    begin {
        [string]$MstscArguments = ''
        switch ($true) {
            {$Admin}      {$MstscArguments += '/admin '}
            {$MultiMon}   {$MstscArguments += '/multimon '}
            {$FullScreen} {$MstscArguments += '/f '}
            {$Public}     {$MstscArguments += '/public '}
            {$Width}      {$MstscArguments += "/w:$Width "}
            {$Height}     {$MstscArguments += "/h:$Height "}
        }

        if ($Credential) {
            $User     = $Credential.UserName
            $Password = $Credential.GetNetworkCredential().Password
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $Process = New-Object System.Diagnostics.Process
            
            # Remove the port number for CmdKey otherwise credentials are not entered correctly
            if ($Computer.Contains(':')) {
                $ComputerCmdkey = ($Computer -split ':')[0]
            } else {
                $ComputerCmdkey = $Computer
            }

            $ProcessInfo.FileName    = "$($env:SystemRoot)\system32\cmdkey.exe"
            $ProcessInfo.Arguments   = "/generic:TERMSRV/$ComputerCmdkey /user:$User /pass:$($Password)"
            $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $Process.StartInfo = $ProcessInfo
            if ($PSCmdlet.ShouldProcess($ComputerCmdkey,'Adding credentials to store')) {
                [void]$Process.Start()
            }

            $ProcessInfo.FileName    = "$($env:SystemRoot)\system32\mstsc.exe"
            $ProcessInfo.Arguments   = "$MstscArguments /v $Computer"
            $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
            $Process.StartInfo       = $ProcessInfo
            if ($PSCmdlet.ShouldProcess($Computer,'Connecting mstsc')) {
                [void]$Process.Start()
                if ($Wait) {
                    $null = $Process.WaitForExit()
                }       
            }
        }
    }
}
        
        # Clean variable, add variable for date/time and test connection to host
        $HostNetTest = $null
        $DateTime = $((get-date).tostring("d.MM.yyyy HH.mm"))
        Add-Message -Message "$($DateTime) - Testing '$($TxMachineName.Text)' 3389 port..."
        $HostNetTest = Test-NetConnection -ComputerName "$($TxMachineName.Text)" -Port 3389 -InformationLevel Quiet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        # Check if host is with 3389 port open
        if ($HostNetTest -eq $true)
            {
            # Query LAPS password
            $PassLAPS = Get-ADComputer -Filter "Name -like '$($TxMachineName.Text)'" -Properties Name,ms-Mcs-AdmPwd
            # Check if password is on object atribute
            if ($PassLAPS.'ms-Mcs-AdmPwd' -ne $null)
                {
                # Check if field administrator name is filled
                if ($TxAdminName.Text.Length -ne "0")
                    {Connect-Mstsc -ComputerName $TxMachineName.Text -User "$($TxMachineName.Text)\$($TxAdminName.Text)" -Password $($PassLAPS.'ms-Mcs-AdmPwd')
                    Add-Message -Message "$($DateTime) - Connecting to: '$($TxMachineName.Text)' with '$($TxAdminName.Text)' admin`n"
                    }
                    # If field administrator name is not filled, try the connection with default name
                    else {Connect-Mstsc -ComputerName $TxMachineName.Text -User "$($TxMachineName.Text)\Administrator" -Password $($PassLAPS.'ms-Mcs-AdmPwd')
                          Add-Message -Message "$($DateTime) - Connecting to: '$($TxMachineName.Text)' with 'Administrator' `n"
                         }
                }
                else {Add-Message -Message "`n$($DateTime) - Password for host '$($TxMachineName.Text)' not found on AD object.`n"}
            }
            else {Add-Message -Message "`n$($DateTime) - Host '$($TxMachineName.Text)' not found or 3389 port is closed.`n"}
        }
        )


#Button to close the form
    $BtExit.Add_Click(
        {$FormSpace.Close()}
        )

# Add range for form with all elements
$FormSpace.controls.AddRange(@($LBTopic,$LBResult,$LBAdminName,$TxMachineName,$TxAdminName,$BtConnect,$TxProgress,$BtExit))

# Show the form
$FormSpace.showdialog()
