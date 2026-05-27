# Documentação do Código: trap_system.verse

Este arquivo especifica o comportamento da armadilha **Mina Terrestre / Sistema de Freio** no mapa **StreetRacingCity**. O dispositivo funciona como uma armadilha tática de solo: o jogador faz a coleta, planta o objeto diretamente sob sua posição atual e, após um breve período de armação, qualquer veículo adversário que passar pelo local sofrerá uma frenagem abrupta simulada por forças de teletransporte.

---

## Estrutura da Classe

### `trap_system_device`
Subclasse que estende a classe base `trap_base_interface`, herdando os parâmetros obrigatórios para se integrar ao gerenciador central de inventário do jogo.

#### Propriedades Editáveis (`@editable`)
* `GerenciadorPai : trap_inventory_manager`: Referência ao coordenador de status global e tabelas de dados do servidor.
* `PickupVolume : volume_device`: Volume de colisão responsável por detectar quando um veículo passa para coletar a mina.
* `PickupVisual : creative_prop`: O modelo 3D/holograma flutuante do item no ponto de coleta da pista.
* `TrapMinaVisual : creative_prop`: O modelo geométrico tridimensional da mina física de chão.
* `TrapMinaVolume : volume_device`: O volume de colisão invisível que detecta quando um oponente ativou a mina plantada.
* `MeuBotaoEspaco : input_trigger_device`: Gatilho de entrada configurado no UEFN para escutar o comando do teclado (Barra de Espaço) ou botão equivalente no controle.

#### Variáveis de Estado Interno
* `PickupPos : vector3`: Vetor tridimensional que memoriza o ponto geográfico original do spawner do item.
* `PlayerArsenal : [agent]int`: Um mapa/dicionário interno que atua como o gerenciador de munição local. Salva a quantidade de cargas disponíveis (munição máxima: `1`) para cada `agent`.

---

## Fluxo de Funções e Lógica de Execução

### `OnBegin<override>()<suspends> : void`
Prepara o ciclo de vida e limpa a pista na inicialização da rodada.
1. Salva a localização inicial do dispositivo em `PickupPos`.
2. Inscreve métodos ouvintes para três eventos: entrada na área de coleta (`OnPlayerPickup`), ativação da armadilha colocada (`OnPlayerHitTrap`) e uso do botão de comando (`OnPlayerPressSpace`).
3. Teleporta preventivamente os componentes da mina (`TrapMinaVolume` e `TrapMinaVisual`) para o limbo geométrico do mapa (`Z := -5000.0`), garantindo que não haja colisões acidentais na pista antes do uso.

### `ResetarInventarioPlayer<override>(Agent : agent) : void`
Método de descarte invocado externamente pelo `GerenciadorPai`.
* Zera instantaneamente a contagem de munição em `PlayerArsenal[Agent] = 0` para desarmar o inventário do piloto caso ele pegue um item diferente.

### `OnPlayerPickup(Agent : agent) : void`
Regula as condições de coleta da armadilha.
1. **Verificação Preventiva:** Checa se o piloto possui o buff de invencibilidade ativo. Nota: No código fornecido, há um log indicando "Splash cancelado", herdado da lógica de proteção.
2. Dispara o alerta `GerenciadorPai.NotificarColeta(MyID, Agent)` para limpar armas antigas do usuário.
3. Define `PlayerArsenal[Agent] = 1`, ocultando o visual de coleta e mandando o colisor temporariamente para o limbo enquanto inicia a rotina paralela de respawn do item (`spawn { RespawnPickup() }`).

### `OnPlayerPressSpace(Agent : agent) : void`
Escuta o comando de ativação do piloto.
1. Utiliza a atribuição condicional para checar se a munição (`Ammo`) do agente é maior que 0.
2. Se positivo, reduz imediatamente a munição para `0` para evitar o spam de múltiplas minas simultâneas e inicia de forma assíncrona o método de posicionamento físico `PlaceTrap(Agent)`.

### `PlaceTrap(Agent : agent)<suspends> : void`
A lógica de implantação com tempo de armação segura.
1. Extrai as coordenadas exatas do veículo do jogador (`PlayerPos`).
2. Teleporta o visual da mina (`TrapMinaVisual`) para a pista exatamente embaixo do carro e o torna visível (`.Show()`).
3. **O Atraso de Segurança (`Sleep(1.0)`):** O script congela a execução por exatamente $1.0$ segundo **antes** de trazer o volume de colisão (`TrapMinaVolume`) para a pista. Esse atraso é vital para mecânicas de corrida: ele dá tempo para que o próprio piloto que soltou a mina se afaste do local, impedindo que ele sofra a penalidade do seu próprio item.

### `RespawnPickup()<suspends> : void`
* Aguarda a janela padrão de recarga de 20 segundos (`Sleep(20.0)`) e devolve os colisores e visuais para a coordenada de origem salva em `PickupPos`.

### `OnPlayerHitTrap(Agent : agent) : void`
Aplica a consequência física do impacto na vítima.
1. Obtém o `FortCharacter` do veículo que invadiu o volume.
2. **Simulação de Frenagem Forçada:** Executa a linha `FortChar.TeleportTo[Transform.Translation, Transform.Rotation]`. Ao teleportar o veículo para as suas exatas coordenadas atuais em tempo real, a Unreal Engine limpa instantaneamente toda a aceleração, inércia e velocidade vetorial acumuladas pela física do carro. O veículo para de forma abrupta ($0\text{ km/h}$).
3. Esconde os elementos da mina e os despacha de volta para baixo do mapa (`Z := -5000.0`) para evitar loops de colisão no mesmo competidor.

---