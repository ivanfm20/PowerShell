`EN-US`
# Massive Remote Port Test with Start-Parallel module

This script was developed to remotely test port 3389 (which can be changed in the script code) in multiple simultaneous instances, using the Start-Parallel module (Author: James O'Neill - Source: https://www.powershellgallery.com /packages/Start-parallel/1.3.0.0).
When the script is executed, the Start-Parallel module is loaded and validated, and then the list of hosts on which the test will be performed is requested (it must not contain a header and must be arranged in a column). First, the number of simultaneous processes that you want to run is requested and then a ping test is performed to speed up the execution and for the hosts that respond, the test is performed on the port. For those who do not respond to the Ping, this information is added to the table.
The imported module allows the simultaneous execution of the test in several instances, which makes the query faster. Added a limiter of 50 simultaneous processes so that the execution doesn't impact the machine or the environment.

Note 1: Special thanks to the author of the Start-Parallel module, James O'Neill, who did an excellent job and deserves the credits of this script, as his work on creating the module was the most difficult!
Note 2: Running in multiple instances can trigger IDS/IPS alarms in your environment, and even cause downtime. This script should be used with caution.


`PT-BR`
# Teste remoto massivo de portas com o módulo Start-Parallel

Este script foi desenvolvido para testar remotamente a porta 3389 (que pode ser alterada no código do script) em múltiplas instâncias simultâneas, utilizando o módulo Start-Parallel (Autor: James O'Neill - Fonte: https://www.powershellgallery.com/packages/Start-parallel/1.3.0.0).
Quando o script é executado, o módulo Start-Parallel é carregado e validado, e então é solicitada a lista de hosts em que o teste será feito (não deve conter cabeçalho e deve estar disposta em coluna). Primeiramente é solicitado o número de processos simultâneos que deseja executar e então é feito um teste de ping para agilizar a execução e para os hosts que responderem, é executado o teste na porta. Para os que não responderem ao Ping, é adicionada esta informação à tabela.
O módulo importado permite a execução simultânea do teste em várias instâncias, o que deixa mais rápida a consulta. Foi adicionado um limitador de 50 processos simultâneos para a execução não impactar a máquina ou o ambiente.

Observação 1: Agradecimento especial ao autor do módulo Start-Parallel, James O'Neill, que fez um excelente trabalho e mereçe os créditos deste script, pois seu trabalho de criação do módulo foi o mais difícil!
Observação 2: A execução em múltiplas instâncias pode ativar alarmes de IDS/IPS em seu ambiente, e até mesmo causar indisponibilidade. Este script deve ser utilizado com cautela.