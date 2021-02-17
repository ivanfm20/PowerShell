**EN-US**
# Script to evaluate SID 500 Local Administrator logins (remotely)

This script was developed to remotely query (via Get-WinEvent) logons with the local SID 500 account.

The objective is to evaluate the use of this account to find out if there are systemic dependencies (or even misuse of the local account) for the implementation of LAPS (or for blocks on this account, such as the "Deny network access" privilege)

This script initially asks for a list of the machines, tries to access them, identifies the name of the SID 500 account and evaluates the successful logins of this account (only the successful logins because the failure ones do not bring the SID information) and displays the results in a table, in addition to granting the option to generate a CSV file with the results.

This script evaluates the initial connection to query the Administrator account name by WMI and also evaluates the connection by RPC to connect to the Event Viewer remotely with "Get-WinEvent".

Some considerations about running the script:
- Access to the remote host queries all logs with IDs 4624, 4625 and 4776, and this can bring a large result. As the result is displayed on the Grid, it may be slow to load all items.
- Remote hosts are accessed by WMI to query the administrator user's SID and by RPC to connect to the Event Viewer, for this reason, they may be slow at the time of this connection attempt when access is denied.
- It is recommended to run initially on a small number of machines (10, for example) to evaluate performance, before running on a larger number.


**PT-BR**
# Script para avaliar logins de administrador local SID 500 (remotamente)

Este script foi desenvolvido para consultar remotamente (via Get-WinEvent) logons com a conta local de SID 500.

O objetivo é avaliar o uso desta conta para saber se existem dependências sistêmicas (ou mesmo uso indevido da conta local) para a implementação de LAPS (ou para bloqueios nesta conta, como o privilégio "Negar acesso via rede")

Este script pede inicialmente uma lista das máquinas, tenta acessá-las, identifica o nome da conta SID 500 e avalia os logins bem-sucedidos dessa conta (apenas os logins bem-sucedidos porque os que falharam não trazem as informações do SID) e exibe os resultados em uma tabela, além de permitir a opção de gerar um arquivo CSV com os resultados.

Este script avalia a conexão inicial para consultar o nome da conta do Administrador por WMI e também avalia a conexão por RPC para se conectar ao Visualizador de Eventos remotamente com "Get-WinEvent".

Algumas considerações sobre a execução do script:
- O acesso ao host remoto consulta todos os logs com IDs 4624, 4625 e 4776, e isso pode trazer um grande resultado. Como o resultado é exibido no Grid, pode ser lento para carregar todos os itens.
- Os hosts remotos são acessados ​​por WMI para consultar o SID do usuário administrador e por RPC para se conectar ao Event Viewer, por este motivo, eles podem ser lentos no momento desta tentativa de conexão quando o acesso é negado.
- Recomenda-se executar inicialmente em um pequeno número de máquinas (10, por exemplo) para avaliar o desempenho, antes de executar em um número maior.