using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

checkpoint_handler := class():
    CheckpointIndex : int
    Callback : type{_(:agent, :int) : void}

    OnVolumeEntered(Agent : agent) : void =
        Callback(Agent, CheckpointIndex)

gerenciador_corrida_manual := class(creative_device):

    @editable Checkpoints : []volume_device = array{}
    @editable Pontuador : score_manager_device = score_manager_device{}
    @editable FimDeJogo : end_game_device = end_game_device{}
    @editable VoltasNecessarias : int = 3

    var StatusJogadores : [agent]int = map{}
    
    var ContagemCheckpoints : [agent][int]int = map{}

    var Handlers : []checkpoint_handler = array{}

    OnBegin<override>()<suspends> : void =
        for (Index -> Volume : Checkpoints):
            NewHandler := checkpoint_handler:
                CheckpointIndex := Index
                Callback := OnCheckpointTouched 
            
            Volume.AgentEntersEvent.Subscribe(NewHandler.OnVolumeEntered)
            set Handlers = Handlers + array{NewHandler}

    OnCheckpointTouched(Agent : agent, IndexTocado : int) : void =
        var ProximoEsperado : int = 0
        if (Atual := StatusJogadores[Agent]):
            set ProximoEsperado = Atual

        if (IndexTocado = ProximoEsperado):
            RegistrarPassagem(Agent, IndexTocado)
            ProcessarSucesso(Agent, IndexTocado)
        else:
            Print("Checkpoint Incorreto!")

    RegistrarPassagem(Agent : agent, Index : int) : void =
        var MapaDoJogador : [int]int = map{}
        if (Existente := ContagemCheckpoints[Agent]):
            set MapaDoJogador = Existente
    
        AtualNoCheckpoint := if (Val := MapaDoJogador[Index]) then Val else 0
        
        if (set MapaDoJogador[Index] = AtualNoCheckpoint + 1):
            if (set ContagemCheckpoints[Agent] = MapaDoJogador):
                Print("Checkpoint {Index + 1} visitado {AtualNoCheckpoint + 1} vezes")

    ProcessarSucesso(Agent : agent, Index : int) : void =
        Pontuador.Activate(Agent)
        
        if (Index = Checkpoints.Length - 1):
            if (Mapa := ContagemCheckpoints[Agent], VezesNoUltimo := Mapa[Index], VezesNoUltimo >= VoltasNecessarias):
                Print("Corrida Finalizada!")
                FimDeJogo.Activate(Agent)
            else:
                if (set StatusJogadores[Agent] = 0):
                    Print("Volta completada! Volte ao início.")
        else:
            if (set StatusJogadores[Agent] = Index + 1):
                Print("Siga para o próximo!")