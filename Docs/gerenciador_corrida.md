# Documentação do Código: gerenciador_corrida.verse

Este arquivo é responsável por gerenciar a lógica de progressão da corrida no mapa **StreetRacingCity**, garantindo a validação de caminhos por meio de checkpoints sequenciais, contagem de voltas e acionamento dos gatilhos de vitória.

---

## Classes e Estruturas

### 1. `checkpoint_handler`
Uma classe auxiliar de escopo lógico puro (não-dispositivo) projetada para contornar limitações nativas de assinaturas de eventos no Verse, permitindo injetar parâmetros contextuais nos gatilhos de escuta.

*   **Propriedades:**
    *   `CheckpointIndex : int`: O índice numérico que identifica a qual posição da pista este handler pertence.
    *   `Callback : type{_(:agent, :int) : void}`: Um ponteiro de função (*delegate*) que aponta de volta para o método de validação do gerenciador principal.
*   **Métodos:**
    *   `OnVolumeEntered(Agent : agent) : void`: Disparado quando um veículo entra no volume de colisão. Repassa o `Agent` e o `CheckpointIndex` para a função de callback.

---

### 2. `gerenciador_corrida_manual`
O dispositivo criativo principal (`creative_device`) que controla os estados dos jogadores e dita as regras da corrida.

#### Propriedades Editáveis (`@editable`)
*   `Checkpoints : []volume_device`: Lista ordenada contendo os volumes de colisão colocados na pista. A ordem dos elementos nesta array define o circuito correto da corrida.
*   `Pontuador : score_manager_device`: Dispositivo do Fortnite usado para conceder pontuação ao jogador ao validar a passagem por um checkpoint.
*   *   `FimDeJogo : end_game_device`: Dispositivo responsável por encerrar a partida e declarar o vencedor assim que todas as voltas forem validadas.
*   `VoltasNecessarias : int`: Define o limite total de voltas (Padrão: `3`) que um competidor precisa completar para finalizar a corrida.

#### Variáveis de Estado Interno (Persistência em Memória)
*   `StatusJogadores : [agent]int`: Um mapa/dicionário que armazena qual o **próximo** índice de checkpoint esperado para cada `agent`.
*   `ContagemCheckpoints : [agent][int]int`: Um mapa aninhado que rastreia o histórico do corredor. Armazena: `[Identidade do Jogador][Índice do Checkpoint] -> Quantidade de Vezes Visitado`.
*   `Handlers : []checkpoint_handler`: Array dinâmica que armazena as instâncias dos manipuladores criados no início do jogo para evitar que sejam limpos pelo coletor de lixo da engine.

---

## Fluxo de Funções e Lógica de Execução

### `OnBegin<override>()<suspends> : void`
Inicializa o ciclo de vida do dispositivo assim que o jogo ou a rodada começa.
1. Utiliza uma estrutura de repetição `for` baseada em chaves (`Index -> Volume`) para iterar sobre a array de `Checkpoints`.
2. Instancia um novo `checkpoint_handler` para cada volume, associando seu respectivo índice e definindo a função `OnCheckpointTouched` como o callback de retorno.
3. Inscreve o método `OnVolumeEntered` do handler ao evento nativo `.AgentEntersEvent` do dispositivo de volume.
4. Adiciona o handler à array global `Handlers`.

### `OnCheckpointTouched(Agent : agent, IndexTocado : int) : void`
O ponto de entrada de validação do circuito.
1. Verifica qual o checkpoint esperado para o agente consultando a tabela `StatusJogadores`. Caso o jogador não possua registro inicial, o valor assume `0` (Linha de largada / primeiro checkpoint).
2. Compara se o `IndexTocado` é igual ao `ProximoEsperado`.
    *   **Se sim:** Executa a gravação dos dados em `RegistrarPassagem` e processa o avanço em `ProcessarSucesso`.
    *   **Se não:** Imprime `"Checkpoint Incorreto!"` no diário de log e ignora o gatilho, impedindo que o jogador pule etapas ou corra no sentido inverso.

### `RegistrarPassagem(Agent : agent, Index : int) : void`
Atualiza o banco de dados interno de telemetria da corrida.
1. Extrai o mapa de checkpoints do jogador corrente ou inicializa um mapa vazio se for a primeira passagem.
2. Faz uma leitura condicional de quantas vezes o jogador passou por aquele índice específico. Se nunca passou, define o valor base como `0`.
3. Incrementa o contador em `+1`, atualiza o mapa local e faz o salvamento transacional (*set*) de volta à tabela global `ContagemCheckpoints`.

### `ProcessarSucesso(Agent : agent, Index : int) : void`
Gerencia as consequências positivas de uma passagem limpa e válida.
1. Ativa o dispositivo `Pontuador` para computar os pontos do agente.
2. **Condicional de Linha de Chegada (`Index = Checkpoints.Length - 1`):**
    *   Se o índice tocado for o último da pista, o script verifica na `ContagemCheckpoints` quantas vezes o jogador validou esse ponto final.
    *   Se o total de passagens for igual ou superior a `VoltasNecessarias`, a corrida é dada por encerrada e o dispositivo `FimDeJogo` é ativado.
    *   Caso contrário, o script entende que apenas mais uma volta foi completada. O status do jogador retorna para `0` na tabela `StatusJogadores` para permitir que ele recomece o circuito.
3. **Condicional de Pista:**
    *   Se não for o último checkpoint, o status do jogador em `StatusJogadores` é atualizado para `Index + 1`, liberando a validação do próximo colisor da sequência.

---
