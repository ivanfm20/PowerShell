`EN-US`
# Script for message generation via Pop-up through scheduled task.

This script was developed to generate a pop-up with a message every 10 seconds (if OK is clicked) to alert the user of a problem. It runs while "Explorer" is running.
For distribution, a GPO can be used that adds a scheduled task for immediate execution. To make the script run in the background, you can use the command: powershell.exe -windowstyle hidden -file "c:\temp\Pop-up_Message.ps1"


`PT-BR`
# Script para geração de mensagem via Pop-up mediante tarefa agendada.

Este script foi desenvolvido para que seja gerado um pop-up com uma mensagem de tem 10 em 10 segundos (caso clicado em OK) para alertar o usuário de algum problema. Ele é executado enquanto o "Explorer" estiver em execução.
Para a distribuição, pode ser utilizada uma GPO que adicione uma tarefa agendada para execução imediata. Para que o script rode em background, é possível utilizar o comando: powershell.exe -windowstyle hidden -file "c:\temp\Pop-up_Message.ps1"
