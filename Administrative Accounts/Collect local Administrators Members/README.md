`EN-US`
# Collect local Administrators Members

This script was developed to collect members of the Administrators group locally. The script collects users and groups, writes to a table and sends the data to a file on a network share, predefined in the script (line 26: $ RemotePath = "\\ServerName\ShareName\FileName.txt"). It is necessary to create the file on the share and grant write permission to the user/group that runs the script (Domain Computers in case of a scheduled task).

Remote execution can be done through a task scheduled by GPO, running once or more on each computer (can be once, weekly, as needed etc.). The script exports date, computer name and accounts/groups present in the Administrators group.

With this result it is possible to add the data in an Excel file and audit these accounts (model Whitelist / Blacklist).


`PT-BR`
# Coleta dos membros Administradores (local)

Este script foi desenvolvido para coletar os membros do grupo Administradores localmente. O script coleta os usuários e grupos, escreve em uma tabela e envia os dados para um arquivo em um compartilhamento de rede, predefinido no script (linha 26: $RemotePath = "\\ServerName\ShareName\FileName.txt"). É necessário criar o arquivo no compartilhamento e conceder permissão de escrita para o usuário/grupo que executar o script (Domain Computers em caso de tarefa agendada).

A execução remota pode ser feita através de tarefa agendada via GPO, executando uma vez ou mais vezes em cada computador (pode ser pontualmente, semanalmente, conforme o necessário etc.). O script exporta data, nome do computador e contas/grupos presententes no grupo Administradores.

Com esse resultado é possível adicionar os dados em um arquivo Excel e auditar estas contas (modelo Whitelist / Blacklist).