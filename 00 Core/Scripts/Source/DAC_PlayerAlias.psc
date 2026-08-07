Scriptname DAC_PlayerAlias extends ReferenceAlias
{Arms the capture controller on EVERY game load.

WHY THIS EXISTS: a Quest script's OnInit fires only ONCE per save, ever. If the
.pex is replaced mid-playthrough - which happens constantly during development -
the new code never gets a chance to re-register its mod event, and the mod goes
silent with no error and no log line. A ReferenceAlias filled with the player
receives OnPlayerLoadGame on every single load, so arming becomes reliable and
survives script updates.

It also gives the existing-save escape hatch: stopquest + startquest re-fills
aliases, which re-fires THIS script's OnInit even though the quest script's
OnInit will never run again.}

Event OnInit()
    Arm("alias OnInit")
EndEvent

Event OnPlayerLoadGame()
    Arm("alias OnPlayerLoadGame")
EndEvent

; Standalone defeat trigger. ReferenceAlias forwards this Actor event because the
; alias points at the player. The controller ignores it unless
; UseOwnBleedoutTrigger is True, so it costs nothing while Yamete is in charge.
Event OnEnterBleedout()
    DAC_CaptureController ctrl = GetOwningQuest() as DAC_CaptureController
    If ctrl
        ctrl.OnPlayerDefeated()
    EndIf
EndEvent

; --- Optional health-percentage trigger ---------------------------------------
;
; OnHit fires for EVERY hit the player takes, several times a second in a real
; fight. A handler that runs and then decides it has nothing to do is still a
; Papyrus dispatch each time, and this feature is OFF by default - so paying that
; cost for everyone would be indefensible.
;
; So the handler lives in a STATE. In the default state the script declares no
; OnHit at all and the VM has nothing to dispatch to; the cost is genuinely zero,
; not merely small. The controller moves the alias into HealthWatch only while
; the threshold is above zero, and back out when it is not.
;
; Even inside HealthWatch the check is done HERE rather than by calling the
; controller: two native global reads and a health read, with no cross-script
; call unless the threshold has actually been crossed.
GlobalVariable Property DAC_ModEnabled Auto
GlobalVariable Property DAC_HealthTrigger Auto

Function SetHealthWatch(Bool enable)
    If enable && GetState() != "HealthWatch"
        GoToState("HealthWatch")
        Debug.Trace("[DAC] Alias: health watch ON")
    ElseIf !enable && GetState() == "HealthWatch"
        GoToState("")
        Debug.Trace("[DAC] Alias: health watch OFF")
    EndIf
EndFunction

State HealthWatch
    Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, \
        Bool abPowerAttack, Bool abSneakAttack, Bool abBashAttack, Bool abHitBlocked)

        If DAC_ModEnabled && DAC_ModEnabled.GetValue() as Int != 1
            Return
        EndIf
        Int pct = 0
        If DAC_HealthTrigger
            pct = DAC_HealthTrigger.GetValue() as Int
        EndIf
        If pct <= 0
            Return
        EndIf
        If (GetActorReference().GetAvPercentage("health") * 100.0) > (pct as Float)
            Return
        EndIf

        DAC_CaptureController ctrl = GetOwningQuest() as DAC_CaptureController
        If ctrl
            ctrl.OnPlayerDamaged()
        EndIf
    EndEvent
EndState

Function Arm(String from)
    DAC_CaptureController ctrl = GetOwningQuest() as DAC_CaptureController
    If ctrl
        ctrl.Maintenance()
        Debug.Trace("[DAC] Alias armed the controller via " + from)
    Else
        Debug.Trace("[DAC] Alias could NOT reach the controller quest (" + from + ")")
    EndIf
EndFunction
