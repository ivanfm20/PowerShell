`EN-US`
# Script to identify logon activity

This script was developed to search log activity for a specific user, inserted in the script execution. It can be used to identify activity on accounts suspected of being compromised or to assess the use of a particular account.

The script evaluates logs 4624 (Login Success) and 4625 (Login Fail) for member computers and 4624, 4625, 4769 (Kerberos Authentication) and 4771 (Kerberos Authentication) for Domain Controllers. These two additional events are collected on the DCs as some authentication failure events may not appear with event 4625 on the DC.

When executed, it asks for a start and end date for searching the logs, allowing you to restrict the search scope as needed. After execution, the result is generated in the Grid and exported in a .CSV file on the user's desktop.

Initially the script was developed to collect the logs remotely, but this model was taking a long time to generate the results, which I understood until now, to be a problem for the execution. For this reason, it must be run locally on all Domain Controllers and then on the member computers identified in the "IP Logon" column. After execution, the script "Logon Activity - Unify logs" was used, which allows the logs to be unified to generate a chronological view of the logon events.

Important points for execution:
- Run as an administrator so that you can consult the security logs
- Run on all DCs and then on all hosts identified in the "IP Logon" column
- Logon auditing must be enabled (Category: Logon / Logoff / Subcategory: Logon - Success and Failure) on all hosts
- It is important that the hosts have the system time synchronized with the DCs, to avoid mismatch of information


`PT-BR`
# Script para identificar a atividade de logon

Este script foi desenvolvido para pesquisar a atividade de log de um determinado usuário, inserido na execução do script. Ele pode ser usado para identificar atividades em contas suspeitas de estarem comprometidas ou para avaliar o uso de uma conta específica.

O script avalia os logs 4624 (sucesso de logon) e 4625 (falha de logon) para computadores membros e 4624, 4625, 4769 (autenticação Kerberos) e 4771 (autenticação Kerberos) para Controladores de Domínio. Esses dois eventos adicionais são coletados nos DCs, pois alguns eventos de falha de autenticação podem não aparecer com o evento 4625 no DC.

Quando executado, ele pede uma data de início e fim para a pesquisa dos logs, permitindo que você restrinja o escopo da pesquisa conforme necessário. Após a execução, o resultado é gerado no Grid e exportado em um arquivo .CSV na área de trabalho do usuário.

Inicialmente o script foi desenvolvido para coletar os logs remotamente, mas esse modelo estava demorando muito para gerar os resultados, o que eu entendi até agora, ser um problema para a execução. Por esse motivo, ele deve ser executado localmente em todos os controladores de domínio e, em seguida, nos computadores membros identificados na coluna "Logon IP". Após a execução, utilize o script “Logon Activity - Unify logs”, que permite unificar os logs para gerar uma visão cronológica dos eventos de logon.

Pontos importantes para execução:
- Execute como administrador para que possa consultar os logs de segurança
- Executar em todos os DCs e, em seguida, em todos os hosts identificados na coluna "IP Logon"
- A auditoria de logon deve estar habilitada (Categoria: Logon/Logoff / Subcategoria: Logon - Sucesso e Falha) em todos os hosts
- É importante que os hosts tenham o horário do sistema sincronizado com os DCs, para evitar incompatibilidade de informações