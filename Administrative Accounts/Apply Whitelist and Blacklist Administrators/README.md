`EN-US`
# Apply Whitelist and Blacklist Administrators

This script was developed to manage the Administrators local group through a predefined list.
The script queries a list of predefined users and computers on the network and for each row adds or removes users by referring to the "List" column.
For each line, if the computer name is the same as the list or equal to "ANY" (any computer), it checks the "List" column, if it is Whitelist it adds the user/group to the group, and if it is Blacklist it removes the user/group group.

The script does not remove all accounts and then validates through the list. The script only performs the action of the accounts that are in the list. To create a white/blacklist, run the script "Collect local Administrators Members.ps1" on all hosts, process the account results and create the whitelist.

In the same folder there is a file template that can be used: 

List,Computer,Account
whitelist,HOST1,DomainName\user1			# In HOST1 add the domain user1
whitelist,ANY,administrator					# On all hosts add the Administrator account
whitelist,ANY,DomainName\HelpDesk			# On all hosts add the HelpDesk group
whitelist,HOST2,HOST2\LocalAdmin			# In HOST2 adds the LocalAdmin local account
whitelist,HOST3,HOST3\SQL_Account			# In HOST3 add the SQL_Account local account
whitelist,ANY,DomainName\Domain Admins		# On all hosts add the Domain Admins group
blacklist,HOST4,HOST4\brian					# On HOST4 removes local user Brian
blacklist,ANY,DomainName\Service_Account	# On all hosts removes the Service_Account domain account
blacklist,ANY,Guest							# On all hosts removes the Guest
#blacklist,HOST4,DomainName\User_TI			# Since the text in the "List" column is not recognized (#blacklist), it does not change

To execute the script, it is necessary to define the variable "$RemotePath", indicating the share where the list is saved. If you run the script on a computer in another language, also change the variable "$Group" for Administrators group of your language.


`PT-BR`
# Aplicar Whitelist e Blacklist de Administradores

Este script foi desenvolvido para gerenciar o grupo de Administradores locais através de uma lista predefinida.
O script consulta uma lista de usuários e computadores predefinida na rede e para cada linha adiciona ou remove os usuários consultando a coluna "List".
Para cada linha, se o nome do computador for igual ao da lista ou igual "ANY" (qualquer computador), ele checa a coluna "List", se for Whitelist adiciona o usuário/grupo ao grupo, e se for Blacklist remove o usuário/grupo do grupo.

O script não remove todas as contas e então valida pela lista. O script somente executa a ação das contas que estão na lista. Para criar uma white/blacklist, execute o script "Collect local Administrators Members.ps1" em todos os hosts, trate o resultado das contas e crie a whitelist.

Na mesma pasta está presente um modelo de arquivo que pode ser utilizado:

List,Computer,Account
whitelist,HOST1,DomainName\user1			# No HOST1 adiciona o user1 do domínio
whitelist,ANY,administrator					# Em todos os hosts adiciona a conta Administrador
whitelist,ANY,DomainName\HelpDesk			# Em todos os hosts adicionar o grupo HelpDesk
whitelist,HOST2,HOST2\LocalAdmin			# No HOST2 adiciona a conta local LocalAdmin
whitelist,HOST3,HOST3\SQL_Account			# No HOST3 adiciona a conta local SQL_Account
whitelist,ANY,DomainName\Domain Admins		# Em todos os hosts adiciona o grupo Domain Admins
blacklist,HOST4,HOST4\brian					# No HOST4 remove o usuário local Brian
blacklist,ANY,DomainName\Service_Account	# Em todos os hosts remove a conta de domínio Service_Account
blacklist,ANY,Guest							# Em todos os hosts remove o Guest
#blacklist,HOST4,DomainName\User_TI			# Como o texto da coluna "List" não é reconhecido (#blacklist), não faz alteração


Para executar o script, é necessário definir a variável "$RemotePath", indicando o compartilhamento em que a lista está salva. Caso execute o script em um computador em português, altere também a variável "$Group" para Administradores.