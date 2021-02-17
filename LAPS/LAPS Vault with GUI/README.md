**EN-US**
# LAPS Vault with GUI

This script was developed for administrators who want to use the local Administrator account to connect by Terminal Services on the machines, in an environment with passwords managed by Microsoft LAPS.

Using a connection with the local administrator credential (with a random password between machines), it is possible to reduce side attacks of the pass-the-hash type, because if this credential is compromised, access will be restricted only to the host where this user and password configured.

For execution it is necessary to run PowerShell as an Administrator to then execute the script. It is also necessary the Active Directory module of PowerShell, which if not available on the machine can be added as "Features on Demand" on newer versions, or installed with RSAT (https://www.microsoft.com/**EN-US**/download/details.aspx?id=45520).

The recommendation is that the script be run from a secure network host (something like a PAW or hop server/jump server) with source and destination access restrictions and extra security measures.


**PT-BR**
# Cofre de senhas LAPS com interface gráfica

Este script foi desenvolvido para administradores que desejam utilizar a conta de Administrador local para se conectar por Terminal Services nas máquinas, em um ambiente com senhas gerenciadas pela Microsoft LAPS.

Usando uma conexão com a credencial de administrador local (com senha aleatória entre as máquinas), é possível reduzir os ataques laterais do tipo pass-the-hash, pois se essa credencial for comprometida, o acesso ficará restrito apenas ao host onde este usuário e senha está configurado.

Para execução, é necessário executar o PowerShell como administrador para então executar o script. Também é necessário o módulo Active Directory do PowerShell, que se não estiver disponível na máquina pode ser adicionado como "Features on Demand" em versões mais recentes, ou instalado com RSAT (https://www.microsoft.com/**EN-US**/download/details.aspx?id=45520).

A recomendação é que o script seja executado a partir de um host de rede seguro (algo como um PAW ou servidor de salto) com restrições de acesso de origem e destino e medidas de segurança extras.