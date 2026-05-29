# Documentação Técnica: `player_data_hub`

**Módulo Central de Telemetria, Posicionamento e Persistência para Corridas (UEFN / Verse)**

O `player_data_hub` é um componente centralizado de gerenciamento de estado (*State Management*) para jogos de corrida no Unreal Editor para Fortnite. Ele processa eventos do mundo (passagem por checkpoints, coleta de itens), gerencia um banco de dados dinâmico de telemetria em tempo real, ordena o ranking geral da partida e calcula automaticamente o *gap* (intervalo) de tempo entre os perseguidores e o líder com base no histórico de setores.

---

## 1. Estruturas de Dados (Structures)

### `player_hud_data`

Representa o estado e os dados de telemetria individuais de um piloto. É a estrutura consumida pela interface gráfica (UI).

* **`NomeDoJogador`** (`string`): O nome identificador do jogador para exibição nas tabelas.
* **`ItemEquipado`** (`string`): O item/modificador que o jogador possui no momento (Ex: "Spray de Tinta").
* **`RodadaAtual`** (`int`): O número da rodada/estágio atual em que o jogador se encontra.
* **`VoltaAtual`** (`int`): A volta física que o jogador está correndo no circuito.
* **`CheckpointAtual`** (`int`): O índice do último checkpoint coletado pelo jogador.
* **`Pontuacao`** (`int`): Peso numérico absoluto gerado por fórmula matemática para critério de desempate e ordenação.
* **`TempoDoUltimoCheckpoint`** (`float`): O tempo decorrido de simulação exato (em segundos) em que o jogador alcançou o seu checkpoint atual.

### `historico_chave`

Estrutura imutável usada exclusivamente como chave composta dentro do mapa global de tempos.

* **`Piloto`** (`agent`): O agente do jogador.
* **`PontosCP`** (`int`): A pontuação gerada pelo checkpoint específico.

---

## 2. Variáveis de Estado (Banco de Dados Interno)

* **`BancoDeDados`** (`[agent]player_hud_data`): Tabela hash de persistência que vincula cada `agent` ativo ao seu respectivo `player_hud_data`.
* **`RankingCache`** (`[]agent`): Array ordenado de agentes. O índice `0` representa sempre o líder absoluto da corrida no frame atual.
* **`HistoricoTemposPorPiloto`** (`[historico_chave]float`): Histórico setorial global. Armazena o registro permanente de quando cada piloto passou por cada pontuação de checkpoint ao longo da prova inteira.

---

## 3. Métodos de Modificação (API de Entrada)

### `GarantirRegistroJogador(Agent : agent) : player_hud_data`

* **Função:** Método de segurança que verifica se o jogador já existe no banco. Se não existir, inicializa um perfil padrão para evitar erros de ponteiro nulo (`false`).
* **Retorno:** O `player_hud_data` atual ou recém-criado do agente.

### `AtualizarItem(Agent : agent, NomeItem : string) : void`

* **Função:** Atualiza o nome do item equipado pelo jogador preservando o restante de sua telemetria. Deve ser engatado em gatilhos de coleta de itens na pista.

### `AtualizarRodada(Agent : agent, NovaRodada : int) : void`

* **Função:** Atualiza a rodada atual do jogador preservando o restante de sua telemetria.

### `AtualizarProgressoCorrida(Agent : agent, NovaVolta : int, NovoCheckpoint : int) : void`

* **Função:** O coração da telemetria da pista. Deve ser chamado sempre que um piloto cruzar um checkpoint físico no mundo.
* **Lógica Interna:** 1. Calcula a nova pontuação absoluta com base na fórmula: $\text{Pontuacao} = (\text{Volta} \times 1000) + \text{Checkpoint}$.
2. Captura o tempo da engine via `GetSimulationElapsedTime()`.
3. Salva os dados no `BancoDeDados`.
4. Carimba a marca temporal do piloto para este checkpoint na struct `HistoricoTemposPorPiloto`.
5. Dispara a reordenação do grid (`AtualizarRankingInterno`).

---

## 4. Algoritmos Internos de Processamento

### `AtualizarRankingInterno() : void`

* **Função:** Coleta todos os jogadores ativos e atualiza o grid posicional ordenado usando um algoritmo *Bubble Sort*.
* **Regra de Negócio:** O ordenamento coloca no topo quem possuir a maior `Pontuacao`. Em caso de pontuações idênticas, o algoritmo preserva a estabilidade posicional prévia até que o próximo checkpoint quebre o empate. Atualiza o `RankingCache` e invoca os logs.

### `MostrarRankingNoLog() : void`

* **Função:** Exibe uma tabela de depuração formatada no log do Verse (`LogVerse`) detalhando posição, pontos, nome e tempo de todos os corredores.

---

## 5. Métodos de Integração para a UI (API de Saída para o Designer)

Estas são as funções que o designer de interface deve utilizar dentro do loop ou atualização do Canvas da UI:

### `ObterRankingGeral() : []agent`

* **Uso na UI:** Retorna a lista de pilotos perfeitamente ordenada do 1º ao último. O designer pode iterar sobre esse array usando o `Index`. A posição na tela será sempre `Index + 1`.

### `ObterDadosDoJogador(Agent : agent) : player_hud_data`

* **Uso na UI:** Fornece acesso direto à estrutura do jogador para exibir em caixas de texto o Nome, Volta Atual, Checkpoint Atual e o Item Equipado.

### `ObterDadosDeTempo(Agent : agent) : string`

* **Uso na UI:** O método mais complexo, sintetizado em uma string amigável para o usuário final.
* **Comportamentos de Retorno:**
* Retorna `"LÍDER"` caso o agente consultado seja o primeiro colocado.
* Retorna `"+X.XXs"` (Ex: `"+2.45s"`) representando o atraso real do piloto em relação ao tempo que o líder fez quando cruzou **aquele exato checkpoint**.
* Retorna `"Cola"` se o intervalo for imperceptível (menor que $0.001$).
* Retorna `"Calculando..."` ou `"Sincronizando..."` se o líder ainda não tiver alcançado aquele patamar do circuito (casos raros de estouro de volta).
