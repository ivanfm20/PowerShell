`EN-US`
# Script to enable Winows Firewall - Rules ANY/ANY - Log all access

This script was created to enable the Windows Firewall and create ANY/ANY rules (allowing any source, protocol and service, for inbound and outbound) for all profiles. It also enables inbound and outbound logs and sets the size to 10mb (originally 4mb). Before making changes, it creates a backup file in C:\Temp ("C:\Temp\Firewall_Rules.wfw"), and does some validations:

- If any of the profiles is enabled, it enables and increases the size of all logs and ends.
- If the backup file already exists in the specified path, it ends (indicates that the script has already been executed on the host).
- After validations, it disables all rules (to avoid impacts when enabling profiles), creates an inbound and an outbound rule with ANY/ANY, enables the logs and only then enables the profiles.

It was developed to be applied in environments that do not use Windows Firewall (profiles disabled) or third party firewall (such as antivirus, for example), so that it is possible to log all local traffic and then be able to enable the restriction rules of more precisely and with less chance of impact.

Some corporate environments disable Firewall profiles because they have been impacted by access or applications. The script can be run on all hosts and then the result logs can be analyzed. After identifying the necessary rules, apply the restrictions in the environment and remove the created ANY/ANY rules.


`PT-BR`
# Script para habilitar o Firewall do Windows - Regras ANY/ANY - Logar os acessos (tráfego)

Este script foi criado para habilitar o Firewall do Windows e criar regras ANY/ANY (permitindo qualquer origem, protocolo e serviço, para entrada e saída) para todos os perfis. Ele também habilita os logs de entrada e saída e configura o tamanho para 10mb (originalmente 4mb). Antes de executar as alterações, ele cria um arquivo de backup no C:\Temp ("C:\Temp\Firewall_Rules.wfw"), e faz algumas validações:

- Se algum dos perfis estiver habilitado, ele habilita e aumenta o tamanho de todos os logs e finaliza.
- Se o arquivo de backup já existir no caminho especificado, finaliza (indica que o script já foi executado no host).
- Após as validações, ele desabilita todas as regras (para evitar impactos ao habilitar os perfis), cria uma regra de entrada e uma de saída com ANY/ANY, habilita os logs e só então habilita os perfis.

Ele foi desenvolvido para ser aplicado em ambientes que não utilizam o Firewall do Windows (perfis desabilitados) ou firewall de terceiros (como de antivírus, por exemplo), para então ser possível logar todo o tráfego local e então ser possível habilitar as regras de restrição de forma mais precisa e com menor chance de impato.

Alguns ambientes corporativos desabilitam os perfis do Firewall por terem sofrido impactos em acessos ou aplicações. O script pode ser executado em todos os hosts e então os logs de resultado podem ser analisados. Após a identificação das regras necessárias, aplicar as restrições no ambiente e remover as regras ANY/ANY criadas.