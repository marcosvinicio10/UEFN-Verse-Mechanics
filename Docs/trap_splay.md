# Documentação do Código: trap_spray_system.verse

Este arquivo especifica o comportamento da armadilha **Spray de Tinta** no mapa **StreetRacingCity**. O item funciona como uma ferramenta tática arremessável: o jogador o coleta, aciona um gatilho de comando para soltá-lo atrás do veículo e, se um oponente colidir com ele, tem a visão obstruída por uma mensagem de interface (HUD), a menos que esteja sob o efeito do Power-up de Invencibilidade.

---

## Estrutura da Classe

### `trap_spray_system`
Subclasse que estende a classe base `trap_base_interface`, integrando-se nativamente ao ecossistema de inventário polimórfico do jogo.

#### Propriedades Editáveis (`@editable`)
* `GerenciadorPai : trap_inventory_manager`: Link para o controlador global de status e tabelas de dados.
* `PickupVolume : volume_device`: Área de colisão na pista que monitora a coleta do item.
* `PickupVisual : creative_prop`: Representação tridimensional/holograma do item flutuando no ponto de coleta.
* `TrapArmadaVisual : creative_prop`: O modelo visual da poça/fumaça de tinta que aparece no asfalto após o lançamento.
* `TrapArmadaVolume : volume_device`: O volume de colisão real que aguarda a passagem de uma vítima sobre a armadilha plantada.
* `MeuBotaoGatilho : input_trigger_device`: O botão de comando configurado no UEFN para escutar o clique do teclado/controle do piloto.
* `HUD_SprayTinta : hud_message_device`: Dispositivo de interface nativo encarregado de projetar a textura ou texto de cegueira na tela do oponente afetado.

#### Variáveis de Estado Interno
* `PickupPos : vector3`: Guarda as coordenadas tridimensionais originais da base de coleta para o cálculo de recarga.
* `TemItem : [agent]logic`: Um mapa local que atua como o inventário lógico interno deste script, salvando `true` se o `agent` possuir o Spray pronto para uso.

---

## Fluxo de Funções e Lógica de Execução

### `OnBegin<override>()<suspends> : void`
Inicializa as escutas de eventos e limpa o mapa no início da rodada.
1. Salva a localização inicial do ponto de coleta em `PickupPos`.
2. Inscreve funções para escutar três eventos críticos: entrada na coleta (`OnPlayerPickup`), colisão com a armadilha na pista (`OnPlayerHitTrap`) e clique no botão de ação (`OnPlayerPressButton`).
3. Oculta o visual da armadilha (`TrapArmadaVisual.Hide()`) e esconde seu volume colisor enviando-o preventivamente para o limbo do mapa (`Z := -5000.0`).

### `ResetarInventarioPlayer<override>(Agent : agent) : void`
Método de descarte acionado externamente pelo `GerenciadorPai`.
* Zera o inventário lógico do piloto alterando seu valor em `TemItem` para `false`, simulando a perda do Spray caso ele pegue outra armadilha na pista.

### `OnPlayerPickup(Agent : agent) : void`
1. Aciona o `GerenciadorPai.NotificarColeta(MyID, Agent)` para forçar a limpeza de outros itens que o jogador estivesse guardando.
2. Atualiza a tabela local `TemItem[Agent] = true`.
3. Move o volume de coleta e o holograma para baixo do mapa e inicia a contagem paralela de recarga (`spawn { RespawnPickup() }`).

### `OnPlayerPressButton(Agent : agent) : void`
1. Verifica se o mapa `TemItem` para o agente é `true`.
2. Se sim, consome imediatamente o item definindo o valor para `false` (impedindo disparos repetidos com a mesma carga).
3. Cria uma thread separada via `spawn` para projetar a armadilha fisicamente na pista através da rotina `LancarSpray(Agent)`.

### `LancarSpray(Agent : agent)<suspends> : void`
Aplica álgebra vetorial espacial para materializar o item com precisão posicional.
1. Obtém a localização (`PlayerPos`) e a rotação angular do veículo (`PlayerRot`).
2. **Cálculo Direcional:** A linha `ForwardDir := PlayerRot.RotateVector(vector3{X:=1.0, Y:=0.0, Z:=0.0})` extrai o vetor unitário que aponta exatamente para a frente do carro.
3. **Posicionamento Traseiro:** Multiplica o vetor por `-400.0` e soma à posição atual (`SpawnPos := PlayerPos + (ForwardDir * -400.0)`). Isso faz com que o Spray seja dropado exatamente **atrás** do carro em movimento, impedindo que quem arremessou colida com a própria armadilha.
4. Move o visual para a coordenada calculada, aguarda um breve instante de armação física (`Sleep(0.3)`) e posiciona o volume colisor real `TrapArmadaVolume` no mesmo local.

### `RespawnPickup()<suspends> : void`
1. Suspende a execução por 20 segundos (`Sleep(20.0)`).
2. Devolve o volume de coleta e o holograma para a coordenada `PickupPos`, reativando o ponto de interesse para os jogadores na pista.

### `OnPlayerHitTrap(Agent : agent) : void`
O gatilho de consequência da armadilha.
1. Faz uma chamada externa consultando `GerenciadorPai.EstaInvencivel(Agent)`.
2. **Corta-Circuito de Proteção:** Se o retorno for `true`, o script ignora todas as linhas seguintes executando um `return`. Nenhuma punição é aplicada e o log imprime `"Splash cancelado! O jogador está imune."`.
3. Caso contrário, exibe o efeito visual na tela do piloto afetado (`HUD_SprayTinta.Show(Agent)`), esconde a armadilha da pista e a envia de volta para o limbo (`Z := -5000.0`) para que ela não seja ativada múltiplas vezes pelo mesmo carro.

---
