using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

trap_base_interface := class(creative_device):
    @editable MyID : int = 0
    ResetarInventarioPlayer(Agent : agent) : void = {}

trap_inventory_manager := class(creative_device):
    @editable TodosOsScriptsArmadilha : []trap_base_interface = array{}

    var PlayersInvenciveis : [agent]logic = map{}

    NotificarColeta(ID_Coletado : int, Agent : agent) : void =
        Print("Limpando inventários antigos (Exceto ID: {ID_Coletado})")
        for (Script : TodosOsScriptsArmadilha):
            if (Script.MyID <> ID_Coletado):
                Script.ResetarInventarioPlayer(Agent)

    EstaInvencivel(Agent : agent) : logic =
        if (Status := PlayersInvenciveis[Agent]):
            return Status
        return false

    RemoverInvencibilidadeImediata(Agent : agent) : void =
        if (set PlayersInvenciveis[Agent] = false) {}

    IniciarTimerInvencibilidade(Agent : agent, Tempo : float) : void =
        spawn { TemporizadorInvencibilidade(Agent, Tempo) }

    TemporizadorInvencibilidade(Agent : agent, Tempo : float)<suspends> : void =
        if (set PlayersInvenciveis[Agent] = true):
            Print("Player INVENCÍVEL contra armadilhas ativado!")
            Sleep(Tempo)
            if (StatusAtual := PlayersInvenciveis[Agent], StatusAtual = true):
                if (set PlayersInvenciveis[Agent] = false):
                    Print("A invencibilidade expirou.")