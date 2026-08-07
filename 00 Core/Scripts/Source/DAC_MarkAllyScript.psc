Scriptname DAC_MarkAllyScript extends ActiveMagicEffect
{Fires when the player uses the "Mark Ally" lesser power.

A power rather than a hotkey on purpose: large load orders have no spare keys,
and VR controllers have fewer still. A power costs no binding and is castable on
both. All the logic lives on the controller - this is only the delivery mechanism.}

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Quest q = Quest.GetQuest("DAC_CaptureController")
    If q
        (q as DAC_CaptureController).ToggleAllyAtCrosshair()
    Else
        Debug.Trace("[DAC] MarkAlly: controller quest not found")
    EndIf
EndEvent
