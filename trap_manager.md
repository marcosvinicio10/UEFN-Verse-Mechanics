# Documentação do Código: trap_manager.verse

Este arquivo estabelece a arquitetura base para o sistema de itens do jogo e define o controlador central de inventário. Ele gerencia o ciclo de descarte de armadilhas duplicadas e dita o estado transacional de invencibilidade dos pilotos na pista.

---

## Classes e Interfaces

### 1. `trap_base_interface`
Um dispositivo criativo abstrato que atua como a classe pai (*blueprint/interface*) para todos os consumíveis e armadilhas do projeto. 

* **Propriedades:**
    * `MyID : int`: O identificador numérico único atribuído a cada tipo de item (ex: `1` para Mina, `2` para Spray, `3` para Power-up). Permite ao gerenciador diferenciar quais scripts devem agir ou ser limpos.
* **Métodos:**
    * `ResetarInventarioPlayer(Agent : agent) : void`: Um método virtual/vazio padrão. Todas as subclasses (armadilhas) estendem essa função para definir suas próprias regras de descarte (como zerar munição ou sumir com hologramas).

---

### 2. `trap_inventory_manager`
O cérebro lógico e repositório central de dados para o controle de itens e buffs dos corredores.

#### Propriedades Editáveis (`@editable`)
* `TodosOsScriptsArmadilha : []trap_base_interface`: Uma lista polimórfica que armazena as referências de todos os dispositivos de armadilha e power-ups espalhados pela pista.

#### Variáveis de Estado Interno (Tabelas de Memória)
* `PlayersInvenciveis : [agent]logic`: Um mapa que associa a identidade de um `agent` a um estado lógico (`true` ou `false`). Indica em tempo real se o veículo do piloto está sob efeito de escudo protetor.

---

## Fluxo de Funções e Lógica de Execução

### `NotificarColeta(ID_Coletado : int, Agent : agent) : void`
Gerencia a regra de inventário de slot único (o jogador só pode carregar ou estar sob o efeito de uma estrutura por vez).
1. Quando qualquer item é pego, ele chama esta função passando quem pegou (`Agent`) e seu próprio código (`ID_Coletado`).
2. O script executa uma varredura através de um loop `for (Script : TodosOsScriptsArmadilha)`.
3. **Condicional de Exclusão (`Script.MyID <> ID_Coletado`):** Se o ID do item da lista for diferente do ID do item que acabou de ser coletado, o gerenciador invoca o método `.ResetarInventarioPlayer(Agent)` daquele script, forçando a limpeza de sobras ou munições antigas que o jogador possuía no inventário.

### `EstaInvencivel(Agent : agent) : logic`
Uma função de consulta rápida usada pelas armadilhas antes de aplicarem penalidades na pista.
1. Tenta extrair o valor associado ao `Agent` na tabela `PlayersInvenciveis`.
2. Se o registro existir, retorna o status lógico salvo (`true` ou `false`).
3. Se o jogador não estiver registrado na tabela (primeira corrida), o fluxo de falha do Verse é acionado e a função retorna o valor padrão `false`.

### `RemoverInvencibilidadeImediata(Agent : agent) : void`
Força a interrupção instantânea do estado de proteção do piloto.
* Aplica uma alteração direta (`set`) na tabela definindo o valor do agente como `false`. É utilizado para cancelamentos manuais ou mecânicas específicas de quebra de escudo.

### `IniciarTimerInvencibilidade(Agent : agent, Tempo : float) : void`
Disparador assíncrono para o início do buff de proteção.
* Como as funções tradicionais não podem congelar o tempo do servidor, este método utiliza a palavra-chave `spawn` para criar uma linha de execução independente na engine para rodar a rotina `TemporizadorInvencibilidade`.

### `TemporizadorInvencibilidade(Agent : agent, Tempo : float)<suspends> : void`
O cronômetro físico que sustenta o efeito de escudo por 10 segundos.
1. Altera transacionalmente o status do competidor na tabela global para `true` (`if (set PlayersInvenciveis[Agent] = true)`).
2. Congela o progresso desta linha de código através do comando `Sleep(Tempo)`, mantendo o jogador imune durante o período configurado.
3. **Janela de Verificação de Segurança:** Passado o tempo, o script executa uma leitura condicional preventiva: `if (StatusAtual := PlayersInvenciveis[Agent], StatusAtual = true)`. 
    * *Por que isso é necessário?* Se o jogador coletar outro Power-up de Invencibilidade enquanto o primeiro ainda estava ativo, o mapa de dados não deve ser limpo pelo cronômetro antigo que terminou primeiro. Ele só desliga a invencibilidade se ela ainda pertencer a este ciclo de execução.
4. Se validado com sucesso, altera o status do jogador de volta para `false`.

---