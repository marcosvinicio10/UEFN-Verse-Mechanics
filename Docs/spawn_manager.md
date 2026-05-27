# Documentação do Código: spawn_manager.verse

Este arquivo define o comportamento do gerenciador de ressurgimento (*spawn*) do mapa. Sua função principal é coordenar as transições de rodadas (Rounds 2 e 3), forçando a eliminação sincronizada e o reset de todos os corredores para que seus veículos reapareçam alinhados corretamente nos grids de largada nativos do Fortnite.

---

## Estrutura da Classe

### `gerenciador_spawn_device`
Um dispositivo criativo (`creative_device`) focado no gerenciamento do fluxo do ciclo de vida da partida e manipulação direta da integridade física (`FortCharacter`) dos avatares dos jogadores.

#### Propriedades Editáveis (`@editable`)
* `Round2Settings : round_settings_device`: Dispositivo de configurações nativo do Fortnite configurado para ditar e monitorar as regras específicas do segundo round.
* `Round3Settings : round_settings_device`: Dispositivo de configurações configurado para monitorar e ditar as regras do terceiro e último round.

---

## Fluxo de Funções e Lógica de Execução

### `OnBegin<override>()<suspends> : void`
Inicializa a escuta de eventos assim que o servidor do mapa cria a instância do dispositivo no início da partida.
1. Vincula o evento `.RoundBeginEvent` do dispositivo `Round2Settings` à função manipuladora `ForcarRenascerUsuarios`.
2. Vincula o mesmo evento `.RoundBeginEvent` do dispositivo `Round3Settings` à função `ForcarRenascerUsuarios`.
3. **Comportamento Nativo:** O Round 1 é ignorado por este script, pois os jogadores já realizam o spawn inicial nativo correto nas posições de largada padrão do mapa.

### `ForcarRenascerUsuarios() : void`
Funciona como uma ponte de despacho imediata quando o sinal de novo round é recebido.
* Como as funções de resposta de eventos nativos do UEFN não aceitam chamadas que suspendem o tempo (`<suspends>`), este método utiliza a palavra-chave `spawn` para abrir uma thread assíncrona e chamar a rotina `ExecutarRespawn()`.

### `ExecutarRespawn()<suspends> : void`
Centraliza a lógica de busca e varredura de jogadores presentes na sessão.
1. **Janela de Segurança:** Executa um comando `Sleep(2.0)`, aguardando dois segundos. Esse intervalo é crítico para garantir que a engine carregue completamente as dependências físicas dos veículos de todos os jogadores no novo round antes de aplicar os comandos de eliminação.
2. Captura a lista de todos os usuários conectados no servidor utilizando o método global `GetPlayspace().GetPlayers()`.
3. Intera por toda a array usando uma estrutura `for (Jogador : TodosJogadores)`.
4. Dispara de forma assíncrona (`spawn`) a função de reset `DetonarEResetarPlayer` para cada competidor individualmente, garantindo que o processamento de um jogador não atrase ou bloqueie o do outro.

### `DetonarEResetarPlayer(Jogador : player)<suspends> : void`
Executa o procedimento físico de parada e eliminação segura para forçar o respawn.
1. Tenta extrair a interface de personagem do jogador através do bloco de atribuição condicional `if (FortChar := Jogador.GetFortCharacter[])`.
2. **O Truque do Freio Técnico:** Captura o posicionamento atual (`Transform`) do personagem e força um comando instantâneo `FortChar.TeleportTo[...]` para as suas próprias coordenadas. 
    * *Por que isso é feito?* Em mapas de corrida de alta velocidade (*StreetRacingCity*), se o veículo iniciar o round em movimento ou com forças físicas aplicadas da rodada anterior, aplicar dano direto pode gerar colisões caóticas e bugs visuais na carcaça do carro. O teletransporte zera o vetor de velocidade vetorial (momento linear) do veículo instantaneamente.
3. **Eliminação Limpa:** Aplica um valor massivo de dano através de `FortChar.Damage(10000.0)`. Como o valor excede a vida máxima permitida pelo jogo, o piloto e o carro associado são eliminados instantaneamente, ativando as regras do dispositivo de spawn do Fortnite para reposicioná-los do zero no grid inicial da corrida.

---
