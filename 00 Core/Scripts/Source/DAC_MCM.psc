Scriptname DAC_MCM extends MCM_ConfigBase
{Registers the "Capture Defeat" MCM.

MCM Helper builds the entire menu from MCM/Config/DefeatAndCapture/config.json, and
every control there binds straight to a GlobalVariable ("sourceType": "GlobalValue"),
so MCM Helper reads and writes those globals itself. This script therefore carries no
setting plumbing at all.

It must exist anyway: SkyUI discovers config menus by scanning the load order for
QUESTS whose script extends SKI_ConfigBase (MCM_ConfigBase does). Without a running
quest carrying such a script the menu never appears in the MCM list no matter how
correct the JSON is - which is exactly why a config-only mod does not show up.}

Event OnConfigInit()
    parent.OnConfigInit()
    Debug.Trace("[DAC] MCM initialised")
EndEvent

Event OnConfigOpen()
    parent.OnConfigOpen()
    Debug.Trace("[DAC] MCM opened")
EndEvent
