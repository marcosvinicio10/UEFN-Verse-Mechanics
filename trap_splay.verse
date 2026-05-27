using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }

trap_spray_system := class(trap_base_interface): 
    @editable GerenciadorPai : trap_inventory_manager = trap_inventory_manager{}
    @editable PickupVolume : volume_device = volume_device{}
    @editable PickupVisual : creative_prop = creative_prop{}
    @editable TrapArmadaVisual : creative_prop = creative_prop{}
    @editable TrapArmadaVolume : volume_device = volume_device{}
    @editable MeuBotaoGatilho : input_trigger_device = input_trigger_device{}
    @editable HUD_SprayTinta : hud_message_device = hud_message_device{}

    var PickupPos : vector3 = vector3{}
    var TemItem : [agent]logic = map{} 

    OnBegin<override>()<suspends> : void =
        set PickupPos = PickupVolume.GetTransform().Translation
        PickupVolume.AgentEntersEvent.Subscribe(OnPlayerPickup)
        TrapArmadaVolume.AgentEntersEvent.Subscribe(OnPlayerHitTrap)
        MeuBotaoGatilho.PressedEvent.Subscribe(OnPlayerPressButton)
        TrapArmadaVisual.Hide()
        if (TrapArmadaVolume.TeleportTo[vector3{Z:= -5000.0}, IdentityRotation()]) {}

    ResetarInventarioPlayer<override>(Agent : agent) : void =
        if (set TemItem[Agent] = false) {}
        Print("Spray de Tinta descartado do inventário.")

    OnPlayerPickup(Agent : agent) : void =
        GerenciadorPai.NotificarColeta(MyID, Agent)
        if (set TemItem[Agent] = true):
            Print("Spray de Tinta coletado! Aperte o botão para usar.")
            PickupVisual.Hide()
            if (PickupVolume.TeleportTo[vector3{Z:= -5000.0}, IdentityRotation()]) {}
            spawn { RespawnPickup() }

    OnPlayerPressButton(Agent : agent) : void =
        if (TemItem[Agent] = true):
            if (set TemItem[Agent] = false) {}
            Print("Lançando Spray de Tinta manualmente!")
            spawn { LancarSpray(Agent) }

    LancarSpray(Agent : agent)<suspends> : void =
        if (FortChar := Agent.GetFortCharacter[]):
            PlayerPos := FortChar.GetTransform().Translation
            PlayerRot := FortChar.GetTransform().Rotation
            ForwardDir := PlayerRot.RotateVector(vector3{X:=1.0, Y:=0.0, Z:=0.0})
            SpawnPos := PlayerPos + (ForwardDir * -400.0)
            if (TrapArmadaVisual.TeleportTo[SpawnPos, IdentityRotation()]):
                TrapArmadaVisual.Show()
                Sleep(0.3)
                if (TrapArmadaVolume.TeleportTo[SpawnPos, IdentityRotation()]) {}

    RespawnPickup()<suspends> : void =
        Sleep(20.0)
        if (PickupVolume.TeleportTo[PickupPos, IdentityRotation()]):
            PickupVisual.Show()

    OnPlayerHitTrap(Agent : agent) : void =
        StatusInvencivel : logic = GerenciadorPai.EstaInvencivel(Agent)
        if (StatusInvencivel = true):
            Print("Splash cancelado! O jogador está imune.")
            return
        Print("SPLASH! Tinta na tela.")
        HUD_SprayTinta.Show(Agent)
        TrapArmadaVisual.Hide()
        if (TrapArmadaVolume.TeleportTo[vector3{Z := -5000.0}, IdentityRotation()]) {}