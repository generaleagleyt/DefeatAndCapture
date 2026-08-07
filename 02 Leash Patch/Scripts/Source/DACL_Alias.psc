Scriptname DACL_Alias extends ReferenceAlias
{Re-arms the leash patch on every game load.

A Quest script's OnInit fires once per save, ever. Replace the .pex and the new
code never registers its mod events or its decorators - silently, with no error.
A ReferenceAlias holding the player gets OnPlayerLoadGame every load, so both
survive a script update and an existing save.}

Event OnInit()
    Arm()
EndEvent

Event OnPlayerLoadGame()
    Arm()
EndEvent

Function Arm()
    DACL_Leash q = GetOwningQuest() as DACL_Leash
    If q
        q.Arm()
    Else
        Debug.Trace("[DACL] Alias could not reach the leash quest")
    EndIf
EndFunction
