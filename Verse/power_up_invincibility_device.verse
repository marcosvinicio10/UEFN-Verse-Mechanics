using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

power_up_invincibility_device := class(trap_base_interface):

    @editable GerenciadorPai : trap_inventory_manager = trap_inventory_manager{}
    @editable PickupVolume : volume_device = volume_device{}
    @editable PickupVisual : creative_prop = creative_prop{}
    @editable DuracaoEfeito : float = 10.0

    var PickupPos : vector3 = vector3{}

    OnBegin<override>()<suspends> : void =
        set PickupPos = PickupVolume.GetTransform().Translation
        PickupVolume.AgentEntersEvent.Subscribe(OnPlayerPickup)

    ResetarInventarioPlayer<override>(Agent : agent) : void =
        Print("O estado de invencibilidade continuará ativo até o timer expirar.")

    OnPlayerPickup(Agent : agent) : void =
        GerenciadorPai.NotificarColeta(MyID, Agent)
        GerenciadorPai.IniciarTimerInvencibilidade(Agent, DuracaoEfeito)
        
        Print("Power-up de Invencibilidade coletado!")
        PickupVisual.Hide()
        if (PickupVolume.TeleportTo[vector3{Z:= -5000.0}, IdentityRotation()]) {}
        
        spawn { RespawnPickup() }

    RespawnPickup()<suspends> : void =
        Sleep(20.0)
        if (PickupVolume.TeleportTo[PickupPos, IdentityRotation()]):
            PickupVisual.Show()
