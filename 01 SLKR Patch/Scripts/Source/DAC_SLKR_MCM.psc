Scriptname DAC_SLKR_MCM extends MCM_ConfigBase
{Registers the "Defeat and Capture - SLKR" MCM.

MCM Helper resolves a menu's config folder from the plugin that DEFINES the quest
carrying this script (FormUtil::GetModName -> sourceFiles.front(), stem). This quest
is defined in DefeatAndCapture_SLKR.esp, so the menu reads
MCM/Config/DefeatAndCapture_SLKR/config.json and is completely separate from the base
mod's menu. That is why the SLKR settings can live here instead of cluttering the base
mod for players who do not run SL Kidnapped Redux.

Like the base mod's shim this carries no setting plumbing: every control binds straight
to a GlobalVariable via "sourceType": "GlobalValue".}

Event OnConfigInit()
    parent.OnConfigInit()
    Debug.Trace("[DAC] SLKR MCM initialised")
EndEvent

; =====================================================================
;  SETTINGS THAT SURVIVE A NEW GAME
; =====================================================================
; Every control binds to an MCM Helper ModSetting, so MCM Helper persists them to
;   Data/MCM/Settings/DefeatAndCapture_SLKR.ini
; outside the save - the file a "my settings" mod captures to preconfigure this.
;
; The plugin's GlobalVariables stay the RUNTIME source of truth, because that is
; what the patch scripts actually read. These pull the stored values into them on
; every load and whenever the menu closes.
;
; This script can host it directly: MCM_ConfigBase inherits OnGameReload from
; SKI_QuestBase, so no separate player alias is needed here.

Event OnGameReload()
    parent.OnGameReload()
    PullSettings()
EndEvent

Event OnConfigClose()
    parent.OnConfigClose()
    PullSettings()
EndEvent

Function PullBool(Int fid, String sId)
    GlobalVariable g = Game.GetFormFromFile(fid, "DefeatAndCapture_SLKR.esp") as GlobalVariable
    If g
        g.SetValue(MCM.GetModSettingBool("DefeatAndCapture_SLKR", sId) as Int)
    EndIf
EndFunction

Function PullInt(Int fid, String sId)
    GlobalVariable g = Game.GetFormFromFile(fid, "DefeatAndCapture_SLKR.esp") as GlobalVariable
    If g
        g.SetValue(MCM.GetModSettingInt("DefeatAndCapture_SLKR", sId))
    EndIf
EndFunction

Function PullFloat(Int fid, String sId)
    GlobalVariable g = Game.GetFormFromFile(fid, "DefeatAndCapture_SLKR.esp") as GlobalVariable
    If g
        g.SetValue(MCM.GetModSettingFloat("DefeatAndCapture_SLKR", sId))
    EndIf
EndFunction

Function PullSettings()
    If !MCM.IsInstalled()
        Return
    EndIf
    PullBool(0x800, "bSkipScenes:Scenes")
    PullBool(0x801, "bPlayerOnlyScenes:Scenes")
    PullBool(0x835, "bDDMaleFilter:Scenes")
    PullFloat(0x836, "fDDMax:Scenes")
    PullBool(0x802, "bAtronachFlame:Creatures")
    PullBool(0x803, "bAtronachFrost:Creatures")
    PullBool(0x804, "bAtronachStorm:Creatures")
    PullBool(0x805, "bBear:Creatures")
    PullBool(0x807, "bBoar:Creatures")
    PullBool(0x806, "bBoarMount:Creatures")
    PullBool(0x808, "bCanineDog:Creatures")
    PullBool(0x80A, "bChaurus:Creatures")
    PullBool(0x809, "bChaurusFlyer:Creatures")
    PullBool(0x80B, "bChaurusReaper:Creatures")
    PullBool(0x80C, "bChicken:Creatures")
    PullBool(0x80D, "bCow:Creatures")
    PullBool(0x80E, "bDeer:Creatures")
    PullBool(0x810, "bDragon:Creatures")
    PullBool(0x80F, "bDragonPriest:Creatures")
    PullBool(0x811, "bDraugr:Creatures")
    PullBool(0x812, "bDwarvenBallista:Creatures")
    PullBool(0x813, "bDwarvenCenturion:Creatures")
    PullBool(0x814, "bDwarvenSphere:Creatures")
    PullBool(0x830, "bDwarvenSpider:Creatures")
    PullBool(0x815, "bFalmer:Creatures")
    PullBool(0x816, "bFox:Creatures")
    PullBool(0x817, "bGargoyle:Creatures")
    PullBool(0x818, "bGiant:Creatures")
    PullBool(0x819, "bGoat:Creatures")
    PullBool(0x81A, "bHagraven:Creatures")
    PullBool(0x81B, "bHorker:Creatures")
    PullBool(0x81C, "bHorse:Creatures")
    PullBool(0x81D, "bIceWraith:Creatures")
    PullBool(0x81E, "bLurker:Creatures")
    PullBool(0x81F, "bMammoth:Creatures")
    PullBool(0x820, "bNetch:Creatures")
    PullBool(0x821, "bRabbit:Creatures")
    PullBool(0x822, "bRiekling:Creatures")
    PullBool(0x823, "bSabreCat:Creatures")
    PullBool(0x824, "bScrib:Creatures")
    PullBool(0x825, "bSeeker:Creatures")
    PullBool(0x826, "bSkeever:Creatures")
    PullBool(0x827, "bSlaughterfish:Creatures")
    PullBool(0x82A, "bSpider:Creatures")
    PullBool(0x828, "bSpiderGiant:Creatures")
    PullBool(0x829, "bSpiderLarge:Creatures")
    PullBool(0x82B, "bSpriggan:Creatures")
    PullBool(0x82C, "bTroll:Creatures")
    PullBool(0x82D, "bVampireLord:Creatures")
    PullBool(0x82E, "bWerewolf:Creatures")
    PullBool(0x831, "bWisp:Creatures")
    PullBool(0x82F, "bWispmother:Creatures")
    Debug.Trace("[DAC] DefeatAndCapture_SLKR settings pulled from MCM Helper")
EndFunction
