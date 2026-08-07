Scriptname DACL_MCM extends MCM_ConfigBase
{Registers the "Defeat and Capture - Leash" MCM.

Deliberately a SECOND script on DACL_LeashQuest rather than a quest of its own.
SkyUI finds config menus by scanning the load order for quests carrying a script
that extends SKI_ConfigBase, and a quest may carry several scripts - so this
needs no new record and, more importantly, no change to the .seq, which is
written against a local master index and is easy to invalidate.

Settings are MCM Helper ModSettings, stored in
  Data/MCM/Settings/DefeatAndCapture_Leash.ini
outside the save. The plugin's GlobalVariables stay the runtime source of truth,
because DACL_Leash reads them; these pull the stored values in on every load and
whenever the menu closes.}

Event OnGameReload()
    parent.OnGameReload()
    PullSettings()
EndEvent

Event OnConfigClose()
    parent.OnConfigClose()
    PullSettings()
EndEvent

Function PullBool(Int fid, String sId)
    GlobalVariable g = Game.GetFormFromFile(fid, "DefeatAndCapture_Leash.esp") as GlobalVariable
    If g
        g.SetValue(MCM.GetModSettingBool("DefeatAndCapture_Leash", sId) as Int)
    EndIf
EndFunction

Function PullInt(Int fid, String sId)
    GlobalVariable g = Game.GetFormFromFile(fid, "DefeatAndCapture_Leash.esp") as GlobalVariable
    If g
        g.SetValue(MCM.GetModSettingInt("DefeatAndCapture_Leash", sId))
    EndIf
EndFunction

Function PullFloat(Int fid, String sId)
    GlobalVariable g = Game.GetFormFromFile(fid, "DefeatAndCapture_Leash.esp") as GlobalVariable
    If g
        g.SetValue(MCM.GetModSettingFloat("DefeatAndCapture_Leash", sId))
    EndIf
EndFunction

Function PullSettings()
    If !MCM.IsInstalled()
        Return
    EndIf
    PullBool(0x800,  "bEnabled:General")
    PullInt(0x801,   "iMode:General")
    PullFloat(0x802, "fMaxLength:General")
    PullInt(0x803,   "iCollar:General")
    PullFloat(0x805, "fSlack:General")
    Debug.Trace("[DACL] Settings pulled from MCM Helper")

    ; Both scripts sit on the same quest, so this reaches the other one directly.
    ; Without it, length and slack only took effect on the NEXT captivity.
    DACL_Leash q = (Self as Quest) as DACL_Leash
    If q
        q.RefreshActiveLeash()
    EndIf

    ; ONE-SHOT: cut every rope now, then clear itself.
    ;
    ; A GlobalValue control rather than a ModSetting, the same as the base mod's
    ; "Get back your stuff" and "Clear persistent allies" - the MCM writes the
    ; global directly and the script consumes it, so nothing is stored to be
    ; re-applied on the next load.
    ;
    ; This exists because an AI captor can decide to leash the player at a moment
    ; the player would rather it did not, and there was no way to undo that
    ; without ending the captivity. Unleash() is the same teardown a release uses:
    ; it drops the player's rope and the followers' ropes and removes the worn
    ; collar. It leaves the CAPTIVITY alone - you are still a prisoner, just not
    ; roped.
    ;
    ; Deliberately AFTER RefreshActiveLeash: refreshing a leash we are about to
    ; remove is wasted work, and doing it in this order means a player who flips
    ; both the master switch and this button in one visit gets the expected result.
    GlobalVariable clr = Game.GetFormFromFile(0x806, "DefeatAndCapture_Leash.esp") as GlobalVariable
    If clr && clr.GetValue() as Int == 1
        clr.SetValue(0)
        If q
            q.Unleash()
            Debug.Notification("Every leash has been removed.")
            Debug.Trace("[DACL] Clear-leashes requested from the MCM - Unleash() run")
        EndIf
    EndIf
EndFunction
