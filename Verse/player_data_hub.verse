using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

player_hud_data := struct:
    ItemEquipado : string = "Nenhum"
    RodadaAtual : int = 1
    VoltaAtual : int = 1
    CheckpointAtual : int = 0

player_data_hub := class(creative_device):

    var BancoDeDados : [agent]player_hud_data = map{}

    OnBegin<override>()<suspends> : void =
        Print("Hub de Dados: Módulo de Corrida e Rodadas acoplado.")

    AtualizarItem(Agent : agent, NomeItem : string) : void =
        if (DadosAntigos := BancoDeDados[Agent]):
            NovosDados := player_hud_data{
                ItemEquipado := NomeItem,
                RodadaAtual := DadosAntigos.RodadaAtual,
                VoltaAtual := DadosAntigos.VoltaAtual,
                CheckpointAtual := DadosAntigos.CheckpointAtual
            }
            if (set BancoDeDados[Agent] = NovosDados) {}
        else:
            NovosDados := player_hud_data{ItemEquipado := NomeItem}
            if (set BancoDeDados[Agent] = NovosDados) {}
        Print("Hub Atualizado: Player possui {NomeItem}")


    AtualizarRodada(Agent : agent, NovaRodada : int) : void =
        if (DadosAntigos := BancoDeDados[Agent]):
            NovosDados := player_hud_data{
                ItemEquipado := DadosAntigos.ItemEquipado,
                RodadaAtual := NovaRodada,
                VoltaAtual := DadosAntigos.VoltaAtual,
                CheckpointAtual := DadosAntigos.CheckpointAtual
            }
            if (set BancoDeDados[Agent] = NovosDados) {}
        else:
            NovosDados := player_hud_data{RodadaAtual := NovaRodada}
            if (set BancoDeDados[Agent] = NovosDados) {}
        Print("Hub Atualizado: Player está na Rodada {NovaRodada}")


    AtualizarProgressoCorrida(Agent : agent, NovaVolta : int, NovoCheckpoint : int) : void =
        if (DadosAntigos := BancoDeDados[Agent]):
            NovosDados := player_hud_data{
                ItemEquipado := DadosAntigos.ItemEquipado,
                RodadaAtual := DadosAntigos.RodadaAtual,
                VoltaAtual := NovaVolta,
                CheckpointAtual := NovoCheckpoint
            }
            if (set BancoDeDados[Agent] = NovosDados) {}
        else:
            NovosDados := player_hud_data{VoltaAtual := NovaVolta, CheckpointAtual := NovoCheckpoint}
            if (set BancoDeDados[Agent] = NovosDados) {}
        Print("Hub Atualizado: Volta {NovaVolta} | Checkpoint {NovoCheckpoint}")
