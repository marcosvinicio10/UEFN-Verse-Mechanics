# Documentação Técnica: StreetRacingCity (Verse / UEFN)

Este documento centraliza e especifica o funcionamento de todos os sistemas e dispositivos desenvolvidos em Verse para o ecossistema de corrida, controle de rounds e gerenciamento de itens/armadilhas do mapa.

---

## 1. Sistema de Corrida e Checkpoints

Responsável por validar o progresso dos corredores ao longo do trajeto de forma estritamente sequencial, monitorando as voltas e determinando as condições de vitória.

### `checkpoint_handler`
* **Tipo:** Classe Auxiliar Pura (`class`).
* **Propósito:** Atua como um intermediário leve para associar um dispositivo de volume (`volume_device`) a um índice numérico e encapsular o evento de colisão.
* **Mecânica:** Quando um agente entra no volume correspondente, a classe executa uma função de retorno (*callback*) repassando a identidade do agente e o número do checkpoint atingido.

### `gerenciador_corrida_manual`
* **Tipo:** Dispositivo Criativo (`creative_device`).
* **Propósito:** O núcleo regulador da corrida. Controla o progresso de voltas individuais de cada competidor.
* **Mecânicas Principais:**
  * **Validação Sequencial:** Garante que o jogador só pontue se tocar no checkpoint esperado (ex: se o jogador registrou o checkpoint 2, tocar no 4 imprimirá "Checkpoint Incorreto!").
  * **Contador de Passagens:** Registra quantas vezes cada checkpoint individual foi visitado por jogador para estruturar o controle de progresso.
  * **Controle de Voltas e Vitória:** Ao cruzar o último checkpoint da lista, verifica se o jogador atingiu o número estipulado em `VoltasNecessarias`. Se sim, ativa o dispositivo de fim de jogo (`end_game_device`); se não, reseta o status para 0 para iniciar a próxima volta.

---

## 2. Sistema Base de Itens e Armadilhas (Arquitetura)

Para viabilizar uma dinâmica onde coletar um item descarta o anterior e gerencia status globais em paralelo (como invencibilidade), o projeto utiliza uma arquitetura centralizada baseada em herança.

### `trap_base_interface`
* **Tipo:** Classe Base Modular (`class(creative_device)`).
* **Propósito:** A fundação para qualquer armadilha ou power-up inserido no mapa. Obriga todas as subclasses a possuírem um identificador único (`MyID`) e um método padrão de descarte (`ResetarInventarioPlayer`).

### `trap_inventory_manager`
* **Tipo:** Gerenciador Central (`creative_device`).
* **Propósito:** O controlador global que coordena os inventários lógicos e o estado de imunidade dos jogadores.
* **Mecânicas Principais:**
  * **Limpeza de Inventário (`NotificarColeta`):** Sempre que um competidor coleta um novo item, esta função percorre a lista de todas as armadilhas cadastradas e aciona o descarte automático (`ResetarInventarioPlayer`) dos scripts que não correspondem ao ID coletado.
  * **Tabela de Imunidade (`PlayersInvenciveis`):** Controla um mapa lógico (`[agent]logic`) indicando quem está protegido contra ações externas.
  * **Temporizador Assíncrono (`<suspends>`):** Executa uma contagem regressiva paralela. Ativa o estado de imunidade, aguarda o tempo determinado e o desliga de forma segura após o término da contagem, validando o estado atual com segurança.

---

## 3. Dispositivos de Itens, Armadilhas e Buffs

Implementações práticas das ferramentas de pista que herdam as regras da `trap_base_interface` e interagem com o `trap_inventory_manager`.

### `power_up_invincibility_device`
* **Propósito:** Garante imunidade total contra o efeito de armadilhas na pista por um tempo configurável.
* **Funcionamento:** Ao ser coletado, esconde seus elementos visuais/colisores e aciona o cronômetro de invencibilidade no Gerenciador Pai. 
* **Regra de Descarte:** Sua função `ResetarInventarioPlayer` é intencionalmente configurada para permitir que o efeito de imunidade continue rodando no gerenciador central mesmo se loops paralelos de limpeza de inventário forem acionados.

### `trap_spray_system` (Spray de Tinta)
* **Propósito:** Uma armadilha de utilidade usada para prejudicar a visibilidade dos oponentes.
* **Funcionamento:** Ao coletar o item e pressionar o botão de ativação, o script calcula o vetor traseiro do carro com base no posicionamento do jogador e teleporta o volume e o visual da armadilha para o local.
* **Efeito:** Se outro veículo entrar no volume, o script checa o estado de invencibilidade do alvo no Gerenciador Pai. Caso o alvo não esteja imune, exibe um aviso HUD de tinta na tela dele e limpa a armadilha do mapa.

### `trap_system_device` (Mina Terrestre / Freio)
* **Propósito:** Uma armadilha física implantada na pista para desacelerar veículos rivais.
* **Funcionamento:** Uma vez coletada, pode ser posicionada na pista pressionando o botão correspondente. Ela possui um atraso programado de $1.0$ segundo para armar o volume de dano, permitindo que quem a largou saia da área de efeito.
* **Efeito:** Ao colidir com um oponente, executa um teletransporte instantâneo no próprio eixo do veículo para simular uma frenagem brusca de impacto e move os componentes da mina para baixo do mapa.

---

## 4. Gerenciador de Transição de Rodadas

Controla o fluxo técnico e a integridade do início de novos rounds na partida.

### `gerenciador_spawn_device`
* **Tipo:** Dispositivo Criativo (`creative_device`).
* **Propósito:** Garante que todos os competidores e seus respectivos veículos sofram um reset limpo na transição para as rodadas seguintes (Rounds 2 e 3).
* **Funcionamento:** Ele se inscreve nos eventos de início de rodada dos dispositivos `round_settings_device`. Assim que a nova rodada inicia, ele aguarda um intervalo de segurança de $2.0$ segundos, localiza todos os jogadores conectados, anula o momento dos veículos via teletransporte instantâneo e aplica dano massivo para forçar um respawn idêntico e sincronizado para todos nas posições corretas de largada.

---
