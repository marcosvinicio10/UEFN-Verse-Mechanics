using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

player_hud_data := struct:
    NomeDoJogador : string = "Piloto"     
    ItemEquipado : string = "Nenhum"
    RodadaAtual : int = 1
    VoltaAtual : int = 1
    CheckpointAtual : int = 0
    Pontuacao : int = 0  
    TempoDoUltimoCheckpoint : float = 0.0 

historico_chave := struct:
    Piloto : agent
    PontosCP : int

player_data_hub := class(creative_device):

    var BancoDeDados : [agent]player_hud_data = map{}
    var RankingCache : []agent = array{}
    
    var HistoricoTemposPorPiloto : [historico_chave]float = map{}

    OnBegin<override>()<suspends> : void =
        Print("Hub de Dados: Módulo de Corrida e Telemetria corrigido.")

    GarantirRegistroJogador(Agent : agent) : player_hud_data =
        if (DadosExistentes := BancoDeDados[Agent]):
            return DadosExistentes
        else:
            NovosDados := player_hud_data{NomeDoJogador := "Piloto"}
            if (set BancoDeDados[Agent] = NovosDados) {}
            return NovosDados

    AtualizarItem(Agent : agent, NomeItem : string) : void =
        DadosAntigos := GarantirRegistroJogador(Agent)
        NovosDados := player_hud_data{NomeDoJogador := DadosAntigos.NomeDoJogador, ItemEquipado := NomeItem, RodadaAtual := DadosAntigos.RodadaAtual, VoltaAtual := DadosAntigos.VoltaAtual, CheckpointAtual := DadosAntigos.CheckpointAtual, Pontuacao := DadosAntigos.Pontuacao, TempoDoUltimoCheckpoint := DadosAntigos.TempoDoUltimoCheckpoint}
        if (set BancoDeDados[Agent] = NovosDados) {}

    AtualizarRodada(Agent : agent, NovaRodada : int) : void =
        DadosAntigos := GarantirRegistroJogador(Agent)
        NovosDados := player_hud_data{NomeDoJogador := DadosAntigos.NomeDoJogador, ItemEquipado := DadosAntigos.ItemEquipado, RodadaAtual := NovaRodada, VoltaAtual := DadosAntigos.VoltaAtual, CheckpointAtual := DadosAntigos.CheckpointAtual, Pontuacao := DadosAntigos.Pontuacao, TempoDoUltimoCheckpoint := DadosAntigos.TempoDoUltimoCheckpoint}
        if (set BancoDeDados[Agent] = NovosDados) {}

    AtualizarProgressoCorrida(Agent : agent, NovaVolta : int, NovoCheckpoint : int) : void =
        DadosAntigos := GarantirRegistroJogador(Agent)
        NovaPontuacao := (NovaVolta * 1000) + NovoCheckpoint
        TempoAtual := GetSimulationElapsedTime()

        NovosDados := player_hud_data{NomeDoJogador := DadosAntigos.NomeDoJogador, ItemEquipado := DadosAntigos.ItemEquipado, RodadaAtual := DadosAntigos.RodadaAtual, VoltaAtual := NovaVolta, CheckpointAtual := NovoCheckpoint, Pontuacao := NovaPontuacao, TempoDoUltimoCheckpoint := TempoAtual}
        if (set BancoDeDados[Agent] = NovosDados) {}

        ChaveHistorico := historico_chave{Piloto := Agent, PontosCP := NovaPontuacao}
        if (set HistoricoTemposPorPiloto[ChaveHistorico] = TempoAtual) {}

        AtualizarRankingInterno()

    AtualizarRankingInterno() : void =
        TodosJogadores := GetPlayspace().GetPlayers()
        var ListaOrdenada : []agent = array{}
        for (Jogador : TodosJogadores):
            set ListaOrdenada = ListaOrdenada + array{Jogador}

        Tamanho := ListaOrdenada.Length
        for (I := 0..Tamanho):
            for (J := 0..(Tamanho - 2)):
                if (PlayerAtual := ListaOrdenada[J], PlayerProximo := ListaOrdenada[J + 1]):
                    PtsAtual := if (D1 := BancoDeDados[PlayerAtual]) then D1.Pontuacao else 0
                    PtsProximo := if (D2 := BancoDeDados[PlayerProximo]) then D2.Pontuacao else 0

                    if (PtsAtual < PtsProximo):
                        if (ListaComInsercao := ListaOrdenada.Insert[J, array{PlayerProximo}]):
                            if (ListaFinal := ListaComInsercao.Remove[J + 2, J + 3]):
                                set ListaOrdenada = ListaFinal

        set RankingCache = ListaOrdenada
        MostrarRankingNoLog()

    MostrarRankingNoLog() : void =
        Print("====== TELEMETRIA ======")
        for (Index -> P_Agent : RankingCache):
            if (DadosMeus := BancoDeDados[P_Agent]):
                TextoTempo := ObterDadosDeTempo(P_Agent)
                Print("#{Index + 1} | {DadosMeus.NomeDoJogador} | Pontos: {DadosMeus.Pontuacao} | Tempo: {TextoTempo}")
        Print("===========================================")
    
    ObterDadosDeTempo(Agent : agent) : string =
        if (LiderAbsoluto := RankingCache[0], DadosMeus := BancoDeDados[Agent]):
            if (Agent = LiderAbsoluto):
                return "LÍDER"
            else:
                ChaveLider := historico_chave{Piloto := LiderAbsoluto, PontosCP := DadosMeus.Pontuacao}
                if (TempoDoLiderNoMeuCP := HistoricoTemposPorPiloto[ChaveLider]):
                    Gap := DadosMeus.TempoDoUltimoCheckpoint - TempoDoLiderNoMeuCP
                    if (Gap > 0.001):
                        return "+{Gap}s"
                    else:
                        return "Cola"
                else:
                    return "Calculando..."
        return "Sincronizando..."

    ObterDadosDoJogador(Agent : agent) : player_hud_data =
        if (Dados := BancoDeDados[Agent]) then Dados else player_hud_data{}

    ObterRankingGeral() : []agent =
        return RankingCache
