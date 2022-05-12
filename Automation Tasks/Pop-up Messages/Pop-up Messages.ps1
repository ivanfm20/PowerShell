# Script to generate a popup message on the user's screen while the "explorer" process is running
#
# Created on 05/11/2022
#
# To run in background, use the command:
# powershell.exe -windowstyle hidden -file "c:\temp\Pop-up_Message.ps1"
#
# References:
# https://4sysops.com/archives/how-to-display-a-pop-up-message-box-with-powershell/
# https://ss64.com/ps/messagebox.html
# https://www.brycematheson.io/do-until-process-killed-powershell/
# Icon Options: Information, Exclamation, Question and Critical
# Ref: https://docs.microsoft.com/pt-br/dotnet/api/microsoft.visualbasic.interaction.msgbox?view=net-5.0


# Add library to popup with button
Add-Type -AssemblyName PresentationCore,PresentationFramework

# Defines the type of button displayed
$ButtonType = [System.Windows.MessageBoxButton]::Ok

# Set the title of the popup
$MessageboxTitle = “WARNING”

# Set the message (text) of the popup
$Messageboxbody = “Dear user, your equipment is irregular or vulnerable. Please urgently contact the service desk and inform that you are receiving this error message. The equipment may have restricted access until regularization. IT Support."

# Set the icon displayed in the popup
$MessageIcon = [System.Windows.MessageBoxImage]::Warning

# Below, commented, another command to run the popup, which can run in the "Do" below
#[System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

$ErrorActionPreference = "SilentlyContinue"

# Checks if the "explorer" process is running, if it is, generates the message and waits for the configured time (Start-Sleep) to check again
$ProcessRunning = @("explorer")
    Do {
       $ProcessFound = Get-Process $ProcessRunning
       If ($ProcessFound)
          {
          # If the "explorer" process is running it displays and the message
          #[System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
          
          Add-Type -AssemblyName Microsoft.VisualBasic
          [Microsoft.VisualBasic.Interaction]::MsgBox("$Messageboxbody",'OKOnly,SystemModal,Critical',"$MessageboxTitle")
          #[System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
          
          Start-Sleep -Seconds 10
          
          }
       }
       # It will display the message while the "explorer" process is running during the verification at the end of the time configured above
       Until (!$ProcessFound)