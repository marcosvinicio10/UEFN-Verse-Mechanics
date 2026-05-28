using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters }
using { /Fortnite.com/FortPlayerUtilities }
using { /UnrealEngine.com/Temporary/SpatialMath } 

gerenciador_spawn_device := class(creative_device):

    @editable Round2Settings : round_settings_device = round_settings_device{}
    @editable Round3Settings : round_settings_device = round_settings_device{}
    @editable DataHub : player_data_hub = player_data_hub{}

    OnBegin<override>()<suspends>:void=

        Round2Settings.RoundBeginEvent.Subscribe(OnRound2Started)
        Round3Settings.RoundBeginEvent.Subscribe(OnRound3Started)

    OnRound2Started() : void = spawn{ ExecutarRespawn(2) }
    OnRound3Started() : void = spawn{ ExecutarRespawn(3) }

    ExecutarRespawn(NumeroRodada : int)<suspends>:void=
        Sleep(2.0)
        
        TodosJogadores := GetPlayspace().GetPlayers()
        for (Jogador : TodosJogadores):
            DataHub.AtualizarRodada(Jogador, NumeroRodada)
            spawn{ DetonarEResetarPlayer(Jogador) }

    DetonarEResetarPlayer(Jogador : player)<suspends>:void=
        if (FortChar := Jogador.GetFortCharacter[]):
            Transform := FortChar.GetTransform()
            
            if (FortChar.TeleportTo[Transform.Translation, Transform.Rotation]):
                #Print("Transição de Round: Veículo freado para eliminação limpa!")
            FortChar.Damage(10000.0)
            #Print("Jogador e veículo eliminados com sucesso!")
