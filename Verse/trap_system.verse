using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }

trap_system_device := class(trap_base_interface):

    @editable GerenciadorPai : trap_inventory_manager = trap_inventory_manager{}
    @editable PickupVolume : volume_device = volume_device{}
    @editable PickupVisual : creative_prop = creative_prop{}
    @editable TrapMinaVisual : creative_prop = creative_prop{}
    @editable TrapMinaVolume : volume_device = volume_device{}
    @editable MeuBotaoEspaco : input_trigger_device = input_trigger_device{}

    var PickupPos : vector3 = vector3{}
    var PlayerArsenal : [agent]int = map{}

    OnBegin<override>()<suspends> : void =
        set PickupPos = PickupVolume.GetTransform().Translation
        PickupVolume.AgentEntersEvent.Subscribe(OnPlayerPickup)
        TrapMinaVolume.AgentEntersEvent.Subscribe(OnPlayerHitTrap)
        MeuBotaoEspaco.PressedEvent.Subscribe(OnPlayerPressSpace)
        #TrapMinaVisual.Hide()
        if (TrapMinaVolume.TeleportTo[vector3{Z:= -5000.0}, IdentityRotation()]) {}
        if (TrapMinaVisual.TeleportTo[vector3{Z:= -5000.0}, IdentityRotation()]) {}
    

    ResetarInventarioPlayer<override>(Agent : agent) : void =
        if (set PlayerArsenal[Agent] = 0) {}
        #Print("Mina descartada: Player pegou outra armadilha!")


    OnPlayerPressSpace(Agent : agent) : void =
        if (Ammo := PlayerArsenal[Agent], Ammo > 0):
            if (set PlayerArsenal[Agent] = 0):
                GerenciadorPai.DataHub.AtualizarItem(Agent, "Nenhum")
                spawn { PlaceTrap(Agent) }

    OnPlayerPickup(Agent : agent) : void =
        StatusInvencivel : logic = GerenciadorPai.EstaInvencivel(Agent)
        if (StatusInvencivel = true):
            #Print("Splash cancelado! O jogador está imune.")
            return
        GerenciadorPai.NotificarColeta(MyID, Agent)
        if (set PlayerArsenal[Agent] = 1):
            #Print("Armadilha coletada! Movendo visual para longe.")
            PickupVisual.Hide()
            if (PickupVisual.TeleportTo[vector3{Z:= -5000.0}, IdentityRotation()]):
                #Print("Visual enviado para o limbo.")
            if (PickupVolume.TeleportTo[vector3{Z:= -5000.0}, IdentityRotation()]):
                #Print("Volume de coleta desativado.")
            
            spawn { RespawnPickup() }

    PlaceTrap(Agent : agent)<suspends> : void =
        if (FortChar := Agent.GetFortCharacter[]):
            PlayerPos := FortChar.GetTransform().Translation

            if (TrapMinaVisual.TeleportTo[PlayerPos, IdentityRotation()]):
                TrapMinaVisual.Show()
                
                Sleep(1.0) 
                if (TrapMinaVolume.TeleportTo[PlayerPos, IdentityRotation()]) {}
                if (TrapMinaVisual.TeleportTo[PlayerPos, IdentityRotation()]) {}

    RespawnPickup()<suspends> : void =
        Sleep(20.0)
        if (PickupVolume.TeleportTo[PickupPos, IdentityRotation()]):
            if (PickupVisual.TeleportTo[PickupPos, IdentityRotation()]):
                PickupVisual.Show()

    OnPlayerHitTrap(Agent : agent) : void =
        StatusInvencivel : logic = GerenciadorPai.EstaInvencivel(Agent)
        if (StatusInvencivel = true):
           # Print("Mina cancelado! O jogador está imune.")
            return
        if (FortChar := Agent.GetFortCharacter[]):
            Transform := FortChar.GetTransform()
            if (FortChar.TeleportTo[Transform.Translation, Transform.Rotation]):
                #Print("Impacto detectado: Veículo freado!")
            TrapMinaVisual.Hide() 
            if (TrapMinaVolume.TeleportTo[vector3{Z := -5000.0}, IdentityRotation()]):
                #Print("Mina removida da pista.")
            if (TrapMinaVisual.TeleportTo[vector3{Z := -5000.0}, IdentityRotation()]):
                #Print("Visual da mina removido da pista.")
