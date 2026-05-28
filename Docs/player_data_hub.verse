# Documentação do Código: player_data_hub.verse

Este arquivo define o comportamento do repositório central de dados da partida. Ele funciona como uma "Fonte Única da Verdade" (*Single Source of Truth*), centralizando as informações de telemetria da corrida, controle de rounds e inventário de armadilhas em um único mapa de dados unificado para que a equipe de UI possa consumi-los com segurança.

---

## Estrutura da Classe

### `player_hud_data`
Estrutura de dados (*struct*) que empacota as 4 informações essenciais necessárias para renderização e controle de interface de cada piloto individualmente.

#### Propriedades
* `ItemEquipado : string`: O nome legível do item ou armadilha atualmente no inventário do jogador. (Padrão: `"Nenhum"`).
* `RodadaAtual : int`: O número do round que está sendo disputado. (Padrão: `1`).
* `VoltaAtual : int`: A volta em que o competidor se encontra na pista. (Padrão: `1`).
* `CheckpointAtual : int`: O último checkpoint válido cruzado pelo piloto. (Padrão: `0`).

### `player_data_hub`
Classe principal que estende `creative_device`. Gerencia a persistência temporária na memória do servidor e expõe os métodos de escrita (*setters*) para a atualização do estado dos jogadores.

#### Variáveis de Estado Interno
* `BancoDeDados : [agent]player_hud_data`: Um mapa mutável (`map`) que associa o agente (`agent`) do jogador diretamente à sua respectiva struct de dados da interface.

---

## Fluxo de Funções e Lógica de Execução

### `OnBegin<override>()<suspends> : void`
Inicializa o ciclo de vida do dispositivo assim que o servidor do mapa inicia.
1. Emite uma mensagem de depuração no log confirmando que o Hub central foi acoplado com sucesso.

### `AtualizarItem(Agent : agent, NomeItem : string) : void`
Modifica o registro do inventário de armadilhas do jogador. Chamado por qualquer uma das instâncias clonadas do `trap_inventory_manager`.
1. **Atualização Condicional:** Tenta extrair o histórico em `DadosAntigos`. Se o jogador já existir no mapa, gera uma nova struct atualizando apenas o `ItemEquipado` e preservando intactas as variáveis de corrida anteriores (`RodadaAtual`, `VoltaAtual`, `CheckpointAtual`).
2. **Fallback de Cadastro:** Caso o jogador ainda não possua um registro criado (início da partida), inicializa a struct injetando o item e assumindo os valores padrão para o resto.
3. Imprime no console a mensagem: `"Hub Atualizado: Player possui {NomeItem}"`.

### `AtualizarRodada(Agent : agent, NovaRodada : int) : void`
Atualiza o indicador de progresso de rounds do servidor. Chamado pelo `gerenciador_spawn_device` durante as transições de pista e fim de round.
1. Intercepta o perfil do jogador e gera uma cópia de sua struct modificando apenas a propriedade `RodadaAtual`. As demais informações de inventário e corrida do round anterior são mantidas até que os respectivos gerentes as resetem.
2. Atualiza o dicionário global `BancoDeDados`.
3. Imprime no console a mensagem: `"Hub Atualizado: Player está na Rodada {NovaRodada}"`.

### `AtualizarProgressoCorrida(Agent : agent, NovaVolta : int, NovoCheckpoint : int) : void`
Gerencia o avanço físico e a telemetria do veículo na pista. Chamado de dentro da função `ProcessarSucesso` de cada um dos 3 gerenciadores de corrida manuais.
1. Sobrescreve simultaneamente as variáveis `VoltaAtual` e `CheckpointAtual` associadas ao agente do piloto, mantendo preservados o round e o item atual no inventário.
2. Salva o novo estado de dados dentro do mapa principal.
3. Imprime no console a mensagem: `"Hub Atualizado: Volta {NovaVolta} | Checkpoint {NovoCheckpoint}"`.

---
