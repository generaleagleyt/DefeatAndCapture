Scriptname DASN_Alias extends ReferenceAlias
{Re-registers the decorators on every game load.

A Quest script's OnInit fires ONCE per save, ever. Replace the .pex during
development - or ship an update to an existing save - and the new code never
registers anything, with no error and no log line. A ReferenceAlias filled with
the player gets OnPlayerLoadGame every single load, so registration survives
both.}

Event OnInit()
    Arm()
EndEvent

Event OnPlayerLoadGame()
    Arm()
EndEvent

Function Arm()
    DASN_Context ctx = GetOwningQuest() as DASN_Context
    If ctx
        ctx.Register()
    Else
        Debug.Trace("[DASN] Alias could not reach the context quest")
    EndIf
EndFunction
