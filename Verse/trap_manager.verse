using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

trap_base_interface := class(creative_device):
    @editable MyID : int = 0
    ResetarInventarioPlayer(Agent : agent) : void = {}

trap_inventory_manager := class(creative_device):
    @editable TodosOsScriptsArmadilha : []trap_base_interface = array{}
    @editable DataHub : player_data_hub = player_data_hub{}

    var PlayersInvenciveis : [agent]logic = map{}

    NotificarColeta(ID_Coletado : int, Agent : agent) : void =
        NomeDoItem := if (ID_Coletado = 1) then "Mina Terrestre"
                    else if (ID_Coletado = 2) then "Spray de Tinta"
                    else if (ID_Coletado = 3) then "Invencibilidade"
                    else "Nenhum"
        DataHub.AtualizarItem(Agent, NomeDoItem)

        for (Script : TodosOsScriptsArmadilha):
            if (Script.MyID <> ID_Coletado):
                Script.ResetarInventarioPlayer(Agent)

    EstaInvencivel(Agent : agent) : logic =
        if (Status := PlayersInvenciveis[Agent]):
            return Status
        return false

    IniciarTimerInvencibilidade(Agent : agent, Tempo : float) : void =
        #Print("Timer iniciado")
        Print("-")
