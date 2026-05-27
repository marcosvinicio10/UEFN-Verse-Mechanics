# Documentação do Código: power_up_invincibility_device.verse

Este arquivo define o comportamento do item consumível de Invencibilidade no mapa. Ele herda a estrutura da classe base de armadilhas para interagir com o sistema de inventário modular, garantindo que o jogador fique imune a penalidades na pista por um tempo determinado.

---

## Estrutura da Classe

### `power_up_invincibility_device`
Subclasse que estende a classe base `trap_base_interface`. Embora funcione como um bônus positivo (*buff*), ela utiliza a mesma assinatura das armadilhas para ser reconhecida pelo sistema de descarte centralizado.

#### Propriedades Editáveis (`@editable`)
*   `GerenciadorPai : trap_inventory_manager`: Referência direta ao coordenador global de inventários e status do mapa.
*   `PickupVolume : volume_device`: O volume invisível que detecta a colisão do veículo para coletar o item.
*   `PickupVisual : creative_prop`: O modelo 3D/holograma flutuante que representa o item visualmente na pista.
*   `DuracaoEfeito : float`: O tempo em segundos (Padrão: `10.0`) que o jogador permanecerá imune após coletar o dispositivo.

#### Variáveis de Estado Interno
*   `PickupPos : vector3`: Armazena as coordenadas tridimensionais originais ($X, Y, Z$) do item capturadas na inicialização, servindo como a âncora fixa para o momento de ressurgimento (*respawn*).

---

## Fluxo de Funções e Lógica de Execução

### `OnBegin<override>()<suspends> : void`
Inicializa o ciclo de vida do item quando a partida começa.
1. Captura a localização atual do `PickupVolume` através do método `.GetTransform().Translation` e salva o vetor em `PickupPos`.
2. Inscreve a função `OnPlayerPickup` ao evento `.AgentEntersEvent` do volume para escutar quando um corredor passar pelo local.

### `ResetarInventarioPlayer<override>(Agent : agent) : void`
Este método sobrescreve (*override*) a função obrigatória da interface base de armadilhas.
*   **A Nuance Técnica:** Diferente das armadilhas comuns (que zeram a munição ou removem o item ao receberem ordem de descarte), esta função foi projetada para **ficar vazia**. 
*   **Objetivo:** Quando o `GerenciadorPai` avisa que o jogador coletou um item novo e manda limpar o inventário antigo, o Power-up ignora o comando. Isso garante que a imunidade concedida persista ativa nos bastidores até o cronômetro expirar naturalmente, impedindo que pegar outra coisa cancele o escudo protetor.

### `OnPlayerPickup(Agent : agent) : void`
Gerencia os eventos imediatos após a colisão do jogador com o item.
1. Comunica ao `GerenciadorPai` que este item foi pego através de `NotificarColeta(MyID, Agent)`, disparando a limpeza de outras armadilhas que o jogador estivesse carregando.
2. Invoca o método `IniciarTimerInvencibilidade(Agent, DuracaoEfeito)` do gerenciador global para ativar a contagem regressiva da imunidade na tabela central de dados.
3. **Ocultação e Retirada:** Esconde o modelo geométrico com `.Hide()` e teleporta o volume colisor para baixo do mapa (`Z:= -5000.0`) para desativar novas coletas consecutivas instantâneas.
4. Utiliza a palavra-chave `spawn` para iniciar a rotina assíncrona `RespawnPickup` sem bloquear a execução do código principal.

### `RespawnPickup()<suspends> : void`
Controla o tempo de recarga do item na pista.
1. Coloca a execução em espera com `Sleep(20.0)`, determinando que o item ficará indisponível por 20 segundos.
2. Passado o tempo, teleporta o volume colisor de volta para as coordenadas originais salvas em `PickupPos`.
3. Se o teletransporte for bem-sucedido, executa `.Show()` no `PickupVisual`, tornando o Power-up disponível para o próximo corredor.

---
