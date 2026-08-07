Scriptname DAC_CaptureController extends Quest
{Capture-on-defeat controller.

On defeat, the winning NPC "captures" the player: the player is added to every
faction the captor belongs to, so the whole enemy group disengages and stays
non-hostile for as long as the player is held. Release removes exactly and only
the factions that were added.

Two triggers, selected by the DAC_TriggerMode global (see TriggerMode()):
  0 = External only  - wait for a Yamete REDUX consequence (mod event DAC_Capture)
  1 = Standalone     - fire from the player's own OnEnterBleedout
  2 = Both

Yamete is a SOFT dependency: its quest and aliases are resolved by name at
runtime, so nothing here fails to compile or load if Yamete is absent.

NOTE: this quest is Start Game Enabled, which does NOTHING without a matching
Data\SEQ\DefeatAndCapture.seq, and its QUST flags must include bit 0x10 (raw 17)
or it will not start. Both are already set up in the ESP.}

; =====================================================================
;  SETTINGS - GlobalVariables so MCM Helper and the console can drive them
;  with no script involvement. Each accessor falls back to a sane default if
;  the property is unbound (e.g. an old save made before the global existed).
; =====================================================================
GlobalVariable Property DAC_TriggerMode Auto
{0 = external/Yamete only, 1 = standalone bleedout, 2 = both.}

GlobalVariable Property DAC_StripItems Auto
{1 = the captor takes the player's gear on capture.}

GlobalVariable Property DAC_ShowDebug Auto
{1 = message boxes on capture/release.}

GlobalVariable Property DAC_DebugPolling Auto
{1 = poll for a console-forced capture:  set DAC_Captured to 1}

GlobalVariable Property DAC_SearchRadiusGV Auto
{Radius in units for the captor cell-scan. 0 = the whole cell.}

GlobalVariable Property DAC_ManageBleedout Auto
{1 = this mod keeps the player ESSENTIAL so a killing blow drops them into
 bleedout instead of killing them, then stands them back up after capture.
 Turn OFF if another defeat framework already owns bleedout (Yamete, Death
 Alternative, ...) - two mods managing it will fight.}

GlobalVariable Property DAC_RecoverHealth Auto
{Health restored when standing the player back up out of bleedout.}

GlobalVariable Property DAC_LeashEnabled Auto
{OPTIONAL, default OFF. 1 = getting far enough from your captor breaks the
 capture. Gives players without an AI framework an actual escape mechanic.}

GlobalVariable Property DAC_LeashDistance Auto
{Units you may stray from the captor before the capture breaks. A warning is
 given at three quarters of this.}

GlobalVariable Property DAC_RestraintsEnabled Auto
{OPTIONAL, default OFF. 1 = the captor binds you in Devious Devices restraints
 and keeps the key. Ignored if Devious Devices is not installed.}

GlobalVariable Property DAC_HumanoidOnly Auto

GlobalVariable Property DAC_ManageAllies Auto
{One-shot MCM switch: open the ally list so one can be dropped by name.}

GlobalVariable Property DAC_SellOnTimeout Auto
{OPTIONAL, default OFF. 1 = when the release timer runs out you are sold to
 Simple Slavery instead of let go. Ignored if Simple Slavery is not installed.}

Message Property DAC_ConfirmBox Auto
{The Allow/Deny box. Optional - a missing message never blocks a capture.}

GlobalVariable Property DAC_ReleaseAfterHours Auto
{OPTIONAL. Game-hours after which the captor loses interest and lets you go.
 0 = never - captivity lasts until something else ends it.}


GlobalVariable Property DAC_AdoptKidnap Auto
{OPTIONAL, default OFF. 1 = when SL Kidnapped Redux finishes with you, take over
 instead of letting it end. Requires DefeatAndCapture_SLKR.esp and SLKR's own
 "sold into slavery" chance set to 0. Ignored if SLKR is not installed.}

GlobalVariable Property DAC_ReturnGear Auto
{One-shot switch: set to 1 to hand back everything recorded as taken, then it
 clears itself. Recovery tool, not a normal release step.}

GlobalVariable Property DAC_KeepFriends Auto
{OPTIONAL, default OFF. 1 = a mercy release leaves the truce in place, so the
 people who held you stay friendly. Escaping never keeps it - you ran.}

Faction Property DAC_TruceFaction Auto
{Ally to itself. Player + everyone present while captive. Cleared on release
 unless DAC_KeepFriends is on. Per-REFERENCE, so it pacifies only who is here.}

Faction Property DAC_AllyFaction Auto
{Ally to itself. Personal, permanent allies - never cleared by release. This is
 what lets one defector stay friendly while their group turns hostile again.}

Spell Property DAC_MarkAllyPower Auto
{Lesser power. Look at someone and cast to make them a permanent ally; cast
 again on the same person to drop them.}

GlobalVariable Property DAC_MarkAllyOn Auto
{OPTIONAL, default ON. 1 = grant the Mark Ally power. Turn off to keep the
 powers list clean if you never use it.}

GlobalVariable Property DAC_ClearAllies Auto
{One-shot switch: set to 1 to forget every ally, then it clears itself.}

GlobalVariable Property DAC_ReleaseHeld Auto
{One-shot switch: set to 1 to free every persist slot, then it clears itself.
 Held NPCs become ordinary again and may be cleaned up on the next cell reset.}

GlobalVariable Property DAC_ModEnabled Auto
{Master switch, default ON. 0 = this mod does nothing at all: no capture from any
 route, no Essential management, and an active captivity is released.}

GlobalVariable Property DAC_HealthTrigger Auto
{OPTIONAL, default 0 = off. Health percentage at or below which a hit triggers a
 capture. Independent of bleedout, and catches the blow that would have killed
 outright rather than dropping the player into bleedout at all.}

GlobalVariable Property DAC_FollowerMode Auto
{0 = followers keep fighting (whoever downs them takes them), 1 = pacified with
 you, 2 = captured with you. A surrender always brings them in regardless.}

GlobalVariable Property DAC_AllyReturnsGear Auto
{OPTIONAL, default ON. 1 = an NPC who becomes your ally hands back anything they
 personally took from you. Only their own haul - other captors keep theirs.}

GlobalVariable Property DAC_Suppressed Auto
{API for other mods. 1 = stand down entirely: no capture, no bleedout recovery.
 Set it directly, or send the DAC_Suppress mod event with numArg 1/0. For any mod
 running a scripted fight whose outcome it watches for itself.}

GlobalVariable Property DAC_SurrenderKey Auto
{OPTIONAL, default 0 = unbound. DirectX scancode of the surrender hotkey. Press it
 to give up a fight and be captured on the spot. Needs nothing else installed.}

; =====================================================================
;  STATE / WIRING
; =====================================================================
GlobalVariable Property DAC_Captured Auto
{0 = free, 1 = captured. Readable by dialogue conditions, other mods and
 SkyrimNet. Also the console release:  set DAC_Captured to 0}

FormList Property DAC_FactionBlacklist Auto
{Factions that must never be joined. May be left empty.}

Actor Property PlayerRef Auto
Float Property CheckInterval = 5.0 Auto
{Seconds between watchdog / poll ticks.}

Spell Property DAC_CaptorAbility Auto
{Marker ability applied to the captor while they hold the player. SkyrimNet prompt
 templates test for it with has_magic_effect(actorUUID, "DAC_CaptorEffect") - far
 more reliable than comparing display names, since many NPCs share one.}

Actor Property Captor Auto Hidden
Bool bCaptured = False
Int iTruceTick = 0      ; throttles the truce re-scan; see OnUpdate
Int iTruceAge = 0       ; ticks since this captivity began

; RESOLUTION-PHASE re-entrancy. BeginCapture already refuses a second capture by
; testing bCaptured - but bCaptured is not set until the END of BeginCapture, and
; the road to it runs FreezeRoom -> ResolveCaptor -> AskToBeCaptured. That is two
; cell scans and a BLOCKING UI prompt, seconds of wall clock during which OnHit
; keeps firing, each hit starting another complete flow.
;
; Measured, not theorised. From a test log, one surrender:
;   - the confirm prompt appeared SIX times (two captors, four prompts on one)
;   - the leash moved from the first captor to the second as flows finished
;   - inside ONE second, one ScanNearby returned 11 actors and another returned
;     None, because the flows were racing each other through the same cache
;
; That last one matters: a race corrupts ANY enumeration method equally, which is
; why this is fixed before anything is done about the scan itself.
Bool bCaptureInFlight = False
Float fCaptureInFlightAt = 0.0

; ---------------------------------------------------------------------
; STATE EXPOSED TO SKYRIMNET
; Read from prompt templates with:
;   {% set s = get_script_property("DAC_CaptureController", "dac_capturecontroller", "CaptureState") %}
; These are plain properties because get_script_property reads properties, not
; script variables or globals.
; ---------------------------------------------------------------------
Int Property CaptureState Auto Hidden
{0 = free, 1 = captured.}

String Property CaptorName Auto Hidden
{Display name of the current captor, or "" when free.}

; =====================================================================
;  SETTING ACCESSORS
; =====================================================================
Int Function TriggerMode()
    If DAC_TriggerMode == None
        Return 1
    EndIf
    Return DAC_TriggerMode.GetValue() as Int
EndFunction

Bool Function StripOn()
    If DAC_StripItems == None
        Return True
    EndIf
    Return DAC_StripItems.GetValue() as Int == 1
EndFunction

Bool Function ShowPopups()
    If DAC_ShowDebug == None
        Return True
    EndIf
    Return DAC_ShowDebug.GetValue() as Int == 1
EndFunction

; Master switch. When off this mod does NOTHING: no capture from any route, no
; Essential management, and an active captivity is ended so nobody is left stuck
; mid-hold by flipping a menu option.
;
; The point is to let someone run a different defeat mod for a while without
; uninstalling this one - defeat mods all own the same moment, and two of them
; fighting over it is worse than either alone.
Bool Function ModEnabled()
    If DAC_ModEnabled == None
        Return True
    EndIf
    Return DAC_ModEnabled.GetValue() as Int == 1
EndFunction

; Health percentage that triggers a capture, 0 = off (bleedout only).
Int Function HealthTriggerPct()
    If DAC_HealthTrigger == None
        Return 0
    EndIf
    Return DAC_HealthTrigger.GetValue() as Int
EndFunction

; 0 = followers keep fighting, 1 = pacified with you, 2 = captured with you.
Int Function FollowerMode()
    If DAC_FollowerMode == None
        Return 0
    EndIf
    Return DAC_FollowerMode.GetValue() as Int
EndFunction

; Set for the duration of a surrender so followers are always brought in, then
; cleared. Giving up as a group is an explicit choice and overrides the mode.
Bool bSurrenderGroup = False

Bool Function FollowersJoin()
    Return bSurrenderGroup || FollowerMode() >= 1
EndFunction

Bool Function KeepFriendsOn()
    If DAC_KeepFriends == None
        Return False
    EndIf
    Return DAC_KeepFriends.GetValue() as Int == 1
EndFunction

Bool Function PollingOn()
    If DAC_DebugPolling == None
        Return True
    EndIf
    Return DAC_DebugPolling.GetValue() as Int == 1
EndFunction

Float Function Radius()
{Search radius in game units. ZERO MEANS "THE WHOLE CELL" and is translated here.

 This used to be handed straight to MiscUtil.ScanCellNPCs, which understood 0 as
 "no distance limit" itself. That native is gone: every caller is now an inline
 cell walk testing `a.GetDistance(PlayerRef) <= r`, and against r = 0 that is
 false for every actor in the game - the setting's documented "0 = whole cell"
 would have quietly pacified NOBODY.

 Translating it once here, rather than special-casing five walks, keeps the one
 rule in the one place. The substitute is a distance no cell spans, so it behaves
 as "unbounded" without needing a separate code path.}
    If DAC_SearchRadiusGV == None
        Return 3000.0
    EndIf
    Float r = DAC_SearchRadiusGV.GetValue()
    If r <= 0.0
        Return 1000000.0
    EndIf
    Return r
EndFunction

; Deliberately folded into the master switch. Keeping the player Essential is the
; most invasive thing this mod does to a character, so "disabled" has to mean it
; too - otherwise a user who switched to another defeat mod would still find they
; could not die, and would have no idea which mod was doing it.
Bool Function BleedoutManaged()
    If !ModEnabled()
        Return False
    EndIf
    Return BleedoutManagedRaw()
EndFunction

Bool Function BleedoutManagedRaw()
    If DAC_ManageBleedout == None
        Return False
    EndIf
    Return DAC_ManageBleedout.GetValue() as Int == 1
EndFunction

Float Function RecoverHealth()
    If DAC_RecoverHealth == None
        Return 50.0
    EndIf
    Return DAC_RecoverHealth.GetValue()
EndFunction

Bool Function LeashOn()
    If DAC_LeashEnabled == None
        Return False
    EndIf
    Return DAC_LeashEnabled.GetValue() as Int == 1
EndFunction

Float Function LeashLimit()
    If DAC_LeashDistance == None
        Return 2500.0
    EndIf
    Return DAC_LeashDistance.GetValue()
EndFunction

Bool Function RestraintsOn()
    If DAC_RestraintsEnabled == None
        Return False
    EndIf
    Return DAC_RestraintsEnabled.GetValue() as Int == 1
EndFunction

Float Function ReleaseHours()
    If DAC_ReleaseAfterHours == None
        Return 0.0
    EndIf
    Return DAC_ReleaseAfterHours.GetValue()
EndFunction


Bool Function AdoptKidnapOn()
    If DAC_AdoptKidnap == None
        Return False
    EndIf
    Return DAC_AdoptKidnap.GetValue() as Int == 1
EndFunction

; =====================================================================
;  MODULE: SL KIDNAPPED REDUX HANDOFF  (optional, default off)
; =====================================================================
; SLKR ambushes the player, drops them in a random dungeon, runs its scenes, and
; then RESOLVES: either sells them to Simple Slavery or teleports them home
; (SLKR_PlayerAlias_Script.psc:402 Outcome()). Neither leaves anything to play.
;
; Its stage global runs 1 = ambush, 2 = held/scenes, 3 = resolved. Outcome()
; WAITS for every scene to finish before setting 3, so adopting at 3 leaves
; SLKR's own content completely intact - we only replace what happens after.
;
; Needs two things besides this toggle:
;   - DefeatAndCapture_SLKR.esp, whose copy of SLKR's script skips the
;     PlayerRef.MoveTo(Origin) teleport while this toggle is on
;   - SLKR's own "sold into slavery" chance set to 0 in ITS MCM. NOT optional:
;     SLKR rolls slavery BEFORE the teleport it replaces, and publishes stage 3
;     before the roll either way - so any non-zero chance both steals the outcome
;     AND leaves this adoption firing into a Simple Slavery handover.
Bool bKidnapHandled = False

Bool Function CheckKidnapAdoption()
    If !AdoptKidnapOn()
        Return False
    EndIf

    ; Via SLKRStage(), which reads the patch's own mirror. This used to resolve
    ; 0x000414 out of SL_Kidnapped_Redux.esp directly - the compacted FormID, so
    ; on a stock SLKR it returned None and the takeover silently never fired.
    ; Same bug as SLKRStage() had; this second copy was missed the first time.
    Int slkr = SLKRStage()
    If slkr == 0
        Return False        ; patch absent, so there is nothing to take over from
    EndIf

    If slkr != 3
        bKidnapHandled = False      ; re-arm for the next kidnapping
        Return False
    EndIf

    If bKidnapHandled
        Return False
    EndIf

    Debug.Trace("[DAC] SL Kidnapped Redux resolved (stage 3) - taking over the captivity")
    TryCapture("kidnap handoff")

    ; Only burn the one-shot if it actually WORKED.
    ;
    ; This used to be set before TryCapture. From a real log: the takeover fired,
    ; MiscUtil.ScanCellNPCs returned None, ResolveCaptor aborted - and because the
    ; flag was already spent, the handoff was gone for good. SLKR had finished, so
    ; the room was hostile again, and nothing was left to capture the player. What
    ; eventually rescued it was an unrelated bleedout two seconds later, by which
    ; time they had been beaten down twice.
    ;
    ; Left unset, the watchdog simply tries again on its next tick.
    If bCaptured
        bKidnapHandled = True
    Else
        Debug.Trace("[DAC] Handoff did not take - leaving it armed to retry next tick")
    EndIf
    Return bCaptured
EndFunction

; =====================================================================
;  MODULE: ESCAPE ROUTES  (all optional)
; =====================================================================
; Without an AI framework, captivity otherwise only ends when the captor dies.
; These give the player something to actually do about it.
;
; Captured game-time, so "the captor loses interest" can be measured.
Float fCaptureTime = 0.0

; Returns True if the timer ran out and the player was released.
Bool Function CheckReleaseTimer()
    Float hours = ReleaseHours()
    If hours <= 0.0 || fCaptureTime <= 0.0
        Return False
    EndIf

    Float elapsed = (Utility.GetCurrentGameTime() - fCaptureTime) * 24.0
    If elapsed < hours
        Return False
    EndIf

    ; The timer running out does not have to mean freedom.
    ;
    ; A captor who has held you for a day and lost interest has two obvious
    ; options, and letting you walk is only one of them. Selling you on is the
    ; other, and it turns the timer from "wait it out and win" into a deadline:
    ; escape before it expires, or be handed to whoever pays.
    If SellOnTimeout() && Game.GetModByName("SimpleSlavery.esp") != 255
        Debug.Trace("[DAC] Timer expired after " + elapsed + " game hours - selling to Simple Slavery")
        Debug.Notification(Captor.GetDisplayName() + " is done with you, and sells you on.")
        SellToSimpleSlavery()
        Return True
    EndIf

    Debug.Trace("[DAC] Captor lost interest after " + elapsed + " game hours")
    Debug.Notification(Captor.GetDisplayName() + " has lost interest in you.")
    ReleasePlayer()          ; a normal release - you get the key back
    Return True
EndFunction

Bool Function SellOnTimeout()
    Return DAC_SellOnTimeout && DAC_SellOnTimeout.GetValue() as Int == 1
EndFunction

; Hand the player to Simple Slavery's auction.
;
; ORDER MATTERS. Our captivity is torn down FIRST, then the event is sent:
;   - Simple Slavery teleports the player to its auction. Ending a captivity
;     afterwards would fire a release, a truce teardown and a leash removal on a
;     player who is no longer anywhere near the people involved.
;   - Its auction raises dhlp-Suspend, which stands this mod down. If we were
;     still mid-teardown when that lands, part of the teardown would be skipped.
;
; Handed over CLEAN, not as an escape.
;
; The instinct was the opposite - you were sold, not freed, so keep the ropes on
; and let the captor keep the loot. That is better fiction and worse play:
;
;   - Simple Slavery MOVES the player, typically to Riften. Gear left on a captor
;     in whatever hold the capture happened in is then a cross-map errand to
;     recover, against an NPC who may not even persist.
;   - Simple Slavery STRIPS AND STORES the player itself, through its own system,
;     and clears existing restraints so its outcomes start from a known state.
;     Anything we leave on is removed a moment later anyway.
;
; So everything is handed back FIRST and the captivity ends as a normal release.
; The player is then Simple Slavery's problem, in the state it expects to receive
; them - and their belongings are somewhere its own storage can account for
; instead of on a bandit two holds away.
Function SellToSimpleSlavery()
    ; Every robber, not just the current captor - this is the last moment anyone
    ; involved is reliably nearby, and the player is about to be teleported.
    ReturnTakenItems()
    bEscaped = False
    ReleasePlayer()
    SendModEvent("SSLV Entry")
    Debug.Trace("[DAC] Sent 'SSLV Entry' - Simple Slavery has the player now")
EndFunction

; =====================================================================
;  MODULE: DEVIOUS DEVICES RESTRAINTS  (optional, default off)
; =====================================================================
; The captor binds the player and KEEPS THE KEY. That single detail is what
; turns the escape routes into real choices:
;   - beat the captor and take the key
;   - pickpocket it
;   - run (the leash) and stay bound, then struggle out the DD way
;
; Which is why release and ESCAPE differ: mercy unlocks you, fleeing does not.
;
; Soft dependency throughout - resolved by FormID at runtime via
; GetFormFromFile, so DD never becomes a master of our plugin and the mod loads
; fine without it.
; NO DEPENDENCY ON zadLibs. `zadLibs.LockDevice()` is itself just AddItem +
; EquipItemEx (zadLibs.psc:388-401) - Devious Devices' own OnEquipped handler
; does all the real work. Compiling against zadLibs would drag in the entire
; SexLab + DD MCM script tree (~3000 errors' worth of transitive dependencies)
; and make DD a hard requirement, for no benefit. Everything here is
; vanilla/SKSE, guarded by GetModByName.
;
; COMPOSES WITH SkyrimNet UDNG (SkyrimNetUDNG.esp): that mod gives the AI ~24
; lock/unlock actions and full DD prompt awareness. Because we go through DD's
; normal equip path, anything we lock is visible to UDNG's prompts and can be
; removed by its actions - so an AI captor can free you. This module is the
; NON-AI path; SkyrimNet users may prefer to leave it off and let UDNG decide.
Bool Function DDPresent()
    Return Game.GetModByName("Devious Devices - Assets.esm") != 255
EndFunction

Form Function DDKey()
    Return Game.GetFormFromFile(0x01775F, "Devious Devices - Integration.esm")
EndFunction

; SLOT 45 ARBITRATION with the leash patch.
;
; Both mods want the player's neck: our DD collar (zad_cuffsLeatherCollar) and the
; leash patch's three neck options all sit on slot 45. Restraints go on FIRST -
; ApplyRestraints runs inside BeginCapture, the leash only reacts to the
; DAC_OnCapture event we send afterwards - so DD always won the race and the leash
; quietly fell back to its body rope. That is why its setting warns you to pick
; the body rope under Devious Devices: it was documenting a defeat.
;
; So ask first instead. If the leash patch is installed, switched on, AND the
; player has actually chosen a neck collar, we leave the neck alone and let it
; have the slot. Arms and legs still lock, so you are still bound and the captor
; still holds the key - you simply wear their collar instead of ours, which is
; the one the player asked for.
;
; Only when a NECK option is chosen. On the default body rope there is no
; conflict, and dropping a restraint to avoid a collision that will not happen
; would just be losing a device for nothing.
;
; GetFormFromFile rather than GetModByName ON PURPOSE: these plugins are
; ESL-flagged, and GetModByName does not report a light plugin's presence
; reliably. A null form is an unambiguous "not installed".
Bool Function LeashWantsTheNeck()
    GlobalVariable en = Game.GetFormFromFile(0x000800, "DefeatAndCapture_Leash.esp") as GlobalVariable
    If en == None || en.GetValue() as Int != 1
        Return False              ; not installed, or the leash master switch is off
    EndIf
    GlobalVariable col = Game.GetFormFromFile(0x000803, "DefeatAndCapture_Leash.esp") as GlobalVariable
    Return col != None && col.GetValue() as Int != 0    ; 0 = body rope, no clash
EndFunction

Function ApplyRestraints(Actor who)
    If !RestraintsOn()
        Return
    EndIf
    If !DDPresent()
        Debug.Trace("[DAC] Restraints requested but Devious Devices is not installed - skipped")
        Return
    EndIf

    StorageUtil.FormListClear(PlayerRef, "DAC_LockedDevices")

    Int locked = 0
    locked += LockOne(0x01BD26)   ; zad_cuffsLeatherArms
    locked += LockOne(0x01BD23)   ; zad_cuffsLeatherLegs
    If LeashWantsTheNeck()
        Debug.Trace("[DAC] Collar SKIPPED - the leash patch is set to a neck collar and needs slot 45")
    Else
        locked += LockOne(0x01BD28)   ; zad_cuffsLeatherCollar
    EndIf

    If locked > 0
        ; The captor keeps the key. This is the whole point - it is what makes
        ; "beat them", "pickpocket them" and "run and stay bound" real choices.
        Form k = DDKey()
        If k
            who.AddItem(k, 1, true)
            StorageUtil.SetIntValue(who, "DAC_HasKey", 1)
        EndIf
        Debug.Trace("[DAC] Restraints locked: " + locked + "; captor holds the key")
        Debug.Notification("You have been bound. " + who.GetDisplayName() + " keeps the key.")
    EndIf
EndFunction

Int Function LockOne(Int fid)
    Armor dev = Game.GetFormFromFile(fid, "Devious Devices - Assets.esm") as Armor
    If dev == None
        Return 0
    EndIf
    If PlayerRef.GetItemCount(dev as Form) <= 0
        PlayerRef.AddItem(dev as Form, 1, true)
    EndIf
    PlayerRef.EquipItemEx(dev as Form, 0, false, true)
    StorageUtil.FormListAdd(PlayerRef, "DAC_LockedDevices", dev as Form, false)
    Return 1
EndFunction

; Mercy release HANDS THE KEY OVER rather than magically unlocking - the player
; still has to use it, and Devious Devices' own flow takes it from there.
; Escaping does NOT call this: you stay bound and the captor keeps the key.
Function HandOverKey(Actor who)
    If !DDPresent() || who == None
        Return
    EndIf
    If StorageUtil.GetIntValue(who, "DAC_HasKey") != 1
        Return
    EndIf

    Form k = DDKey()
    If k && who.GetItemCount(k) > 0
        who.RemoveItem(k, 1, true, PlayerRef)
        Debug.Notification("You are handed the key to your restraints.")
    EndIf
    StorageUtil.SetIntValue(who, "DAC_HasKey", 0)
    Debug.Trace("[DAC] Key handed to the player on release")
EndFunction

; =====================================================================
;  MODULE: LEASH  (optional, default off)
; =====================================================================
; Straying far enough from the captor breaks the hold. Because release removes
; the borrowed factions, the group turns hostile again on its own - so this is
; simultaneously the escape route and its consequence, with no extra machinery.
;
; Returns True if the leash snapped and the player was released.
Bool bLeashWarned = False
; Set when the release is an ESCAPE rather than the captor letting go, so the
; narration to SkyrimNet says the right thing.
Bool bEscaped = False

Bool Function CheckLeash()
    If !LeashOn() || Captor == None
        bLeashWarned = False
        Return False
    EndIf

    ; A PHYSICAL leash wins over this one. LeashFramework stops the player leaving
    ; at all; this module ends the captivity when they get too far. Run both and
    ; they fight: the rope hauls the player back at its own length, and a moment
    ; later this decides they escaped and turns the room hostile - so being
    ; dragged back to your captor sets you free, which is nonsense.
    ;
    ; Resolved by faction rather than by calling LeashFramework, so the base mod
    ; keeps no dependency on it: lf_leashed is a plain faction and the lookup
    ; simply yields None when Leash.esm is absent.
    Faction lf = Game.GetFormFromFile(0x000D6A, "Leash.esm") as Faction
    If lf && PlayerRef.GetFactionRank(lf) >= 0
        bLeashWarned = False
        Return False
    EndIf

    Float limit = LeashLimit()
    If limit <= 0.0
        Return False
    EndIf

    Float d = PlayerRef.GetDistance(Captor)

    If d > limit
        Debug.Trace("[DAC] Leash SNAPPED at " + d + " (limit " + limit + ")")
        Debug.Notification("You slip away from " + Captor.GetDisplayName() + ".")
        bLeashWarned = False
        bEscaped = True          ; changes what gets narrated to SkyrimNet
        ReleasePlayer()
        Return True
    EndIf

    ; Warn once per excursion, so it does not spam every tick.
    If d > limit * 0.75
        If !bLeashWarned
            bLeashWarned = True
            Debug.Notification("You are straying too far from your captor...")
        EndIf
    Else
        bLeashWarned = False
    EndIf

    Return False
EndFunction

; =====================================================================
;  MODULE: BLEEDOUT MANAGEMENT
; =====================================================================
; The player has NO bleedout state in vanilla - a killing blow just kills them.
; Marking the player's base as essential is what makes the engine drop them into
; bleedout instead, which is what OnEnterBleedout needs in order to ever fire.
;
; This is a big, global change (the player becomes unkillable), so it is opt-in
; and kept in sync every tick: flip the MCM toggle off and the next poll restores
; the normal state. bEssentialApplied tracks whether WE set it, so we never clear
; an essential flag some other mod owns.
Bool bEssentialApplied = False

Function SyncEssential()
    Bool want = BleedoutManaged()
    If want == bEssentialApplied
        Return
    EndIf

    ActorBase pb = PlayerRef.GetActorBase()
    If pb == None
        Debug.Trace("[DAC] Could not read the player's ActorBase - bleedout not managed")
        Return
    EndIf

    pb.SetEssential(want)
    bEssentialApplied = want
    Debug.Trace("[DAC] Player essential set to " + want + " (bleedout management)")
EndFunction

; Stand the player back up after a defeat.
;
; A defeated player's health is DEEPLY NEGATIVE (-86 observed, Yamete has logged
; -280). Restoring a flat amount just moves them from -86 to -36: still bleeding
; out, never standing up, and other death mods (Respawn) will collect them within
; seconds. So cancel the deficit FIRST, then add the target on top - the same
; thing Yamete does in YamMain.RestoreHealth.
Function RecoverFromBleedout()
    Float cur = PlayerRef.GetActorValue("Health")
    Float target = RecoverHealth()

    If cur >= target
        PlayerRef.SetNoBleedoutRecovery(false)
        Return
    EndIf

    Float amount = target - cur      ; cur may be negative, which widens this correctly

    PlayerRef.SetNoBleedoutRecovery(false)
    PlayerRef.RestoreActorValue("Health", amount)

    Debug.Trace("[DAC] Bleedout recovery: health was " + cur + ", restored " + amount + " -> target " + target)
EndFunction

; =====================================================================
;  MODULE: NSFW SCENE - REMOVED
; =====================================================================
; StartScene() lived here: it waited out the get-up animation and then called
; OThread.QuickStart(captor, player) to run an OStim scene after a capture.
;
; Removed deliberately, not because it was broken. It was a test feature from
; the earliest version and it was never this mod's job - OStimNet,
; SkyrimNet_Sexlab and the other scene frameworks already decide when a scene
; happens and pick something far better suited than a hardcoded QuickStart. A
; defeat mod firing its own scene competes with them for the same moment.
;
; Removed with it: the DAC_NSFWScene and DAC_SceneDelay globals, their MCM
; controls and settings keys, SceneOn(), SceneDelay(), and the mod's only use of
; OStim - so OStim is no longer referenced anywhere and no longer belongs in the
; compile import path.
;
; The crash guard it carried is worth remembering if anything ever starts a scene
; from a defeat again: OStim builds its thread from the actors' CURRENT animation
; state, and a player still getting up from bleedout produces a thread with a null
; actor which OStim then dereferences - OStim.dll Thread.cpp:181,
; getActorAlignment, EXCEPTION_ACCESS_VIOLATION with rcx = 0. RestoreActorValue
; only STARTS the get-up; you have to wait for it to land.

; =====================================================================
;  MODULE: SKYRIMNET
; =====================================================================
; Two separate jobs:
;   - LIVE STATE  -> the CaptureState / CaptorName properties above, read by the
;     prompt submodule via get_script_property. That is what makes an NPC aware
;     right now, and needs no registration at all.
;   - MEMORY      -> RegisterEvent below, so the capture enters their history
;     instead of only being true while it is happening.
; Soft dependency: nothing is called unless SkyrimNet.esp is present.
Bool Function SkyrimNetPresent()
    Return Game.GetModByName("SkyrimNet.esp") != 255
EndFunction

; How the captivity STARTED is remembered, not just that it happened.
;
; This used to hardcode "overpowered them in combat" for every route - so a
; player who deliberately threw down their weapon was remembered by the whole
; room as having been beaten in a fight. The AI then reasoned from an event that
; never occurred, and the player's actual choice was erased from the record.
;
; Yielding and losing are different stories and they lead somewhere different:
; one is a negotiation the player opened, the other is a defeat.
Function NarrateCapture(Actor who)
    If !SkyrimNetPresent()
        Return
    EndIf
    String pname = PlayerRef.GetDisplayName()
    String cname = who.GetDisplayName()
    String source = StorageUtil.GetStringValue(PlayerRef, "DAC_CaptureSource")
    String story = ""

    If source == "surrender"
        story = pname + " surrendered to " + cname + " - stopped fighting, gave themselves up, and " \
              + "asked to be taken rather than killed. " + cname + " accepted and " + pname \
              + " is now their prisoner. This was " + pname + "'s own choice, not a defeat."
    ElseIf source == "kidnap handoff" || source == "external consequence"
        story = cname + " and their people took " + pname + " prisoner. " + pname \
              + " is now " + cname + "'s captive."
    Else
        story = cname + " overpowered " + pname + " in combat and took them captive rather than " \
              + "killing them. " + pname + " is now " + cname + "'s prisoner."
    EndIf

    SkyrimNetApi.RegisterEvent("dac_capture", story, who, PlayerRef)
    Debug.Trace("[DAC] SkyrimNet: capture event registered (" + source + ")")
EndFunction

; The player broke away rather than being let go. This one uses BOTH channels:
;   RegisterShortLivedEvent - scene context, so NPCs reacting in the next 30s
;     actually know an escape just happened instead of just finding the player
;     hostile for no apparent reason.
;   RegisterEvent           - long-term memory.
Function NarrateEscape(Actor who)
    If !SkyrimNetPresent()
        Return
    EndIf
    String pname = PlayerRef.GetDisplayName()
    String cname = who.GetDisplayName()
    String content = pname + " has slipped away from " + cname + " and escaped captivity. " + \
        pname + " was " + cname + "'s prisoner and has just broken free and fled. " + \
        cname + "'s people are hunting them again."

    SkyrimNetApi.RegisterShortLivedEvent("dac_escape_" + pname, "dac_escape", content, \
        "{\"info\":\"" + content + "\"}", 30000, PlayerRef, who)
    SkyrimNetApi.RegisterEvent("dac_escape", content, PlayerRef, who)
    Debug.Trace("[DAC] SkyrimNet: escape narrated to nearby NPCs")
EndFunction

Function NarrateRelease(Actor who)
    If !SkyrimNetPresent()
        Return
    EndIf
    String pname = PlayerRef.GetDisplayName()
    String cname = who.GetDisplayName()
    SkyrimNetApi.RegisterEvent("dac_release", \
        cname + " let " + pname + " go. " + pname + " is no longer a prisoner.", who, PlayerRef)
    Debug.Trace("[DAC] SkyrimNet: release event registered")
EndFunction

; =====================================================================
;  SL KIDNAPPED REDUX - STAGE AWARENESS
; =====================================================================
; 1 = IDLE (also the value the plugin ships and what DefaultVariables() resets
; to), 2 = player held, 3 = resolved. SLKR never writes 0, so 0 is used here as
; the "SLKR is absent" answer and callers need no separate installed-check.
; Do not read 1 as activity - see the note in TryCapture().
; Is ANOTHER captivity mod currently holding the player? If so we must not start a
; capture on top of it - the other mod is mid-sequence, and taking the player out
; from under it strands whatever it was going to do next.
;
; Every check resolves its form at runtime and yields None when that mod is absent,
; so this costs one failed lookup on a load order without them and nothing else.
; Is some OTHER mod running a scripted scene that owns the player's defeat right
; now? Distinct from ExternalCaptivityHold(), which is about captivity - this is
; about a fight whose outcome another quest is watching for.
;
; The case that prompted it: Dark Arena's pit fights. Its player alias listens on
; the SAME two events this mod does - OnHit with health <= 10, and
; OnEnterBleedout - then calls SetNoBleedoutRecovery(True) to keep the player
; down and advances its quest. Three separate collisions: we would capture the
; player mid-match, our RecoverFromBleedout would stand them straight back up
; against its SetNoBleedoutRecovery, and the health trigger would fire before its
; own threshold.
;
; Quests are resolved by EditorID at runtime, so a load order without Dark Arena
; simply gets None and pays three failed lookups. None of them are
; start-game-enabled, so IsRunning() means a job really is in progress - no need
; to track stage numbers, which would break on any update.
;
; DAC_Suppressed is the general escape hatch: any mod can set it, or send the
; DAC_Suppress mod event, and this mod stands down without needing to know
; anything about them. Add to this list only when a mod cannot do that.
; The DHLP suspend protocol. Simple Slavery raises this for its whole auction -
; the player is on a platform being sold, and a capture landing there (an AI
; deciding to take them, or a mis-hit surrender key) would strand the auction
; with no outcome. Other mods use the same pair, so honouring the convention
; covers all of them instead of hardcoding one plugin's quest stages.
;
; A suspend whose Resume never arrives would disable this mod silently and
; permanently, so it lapses on its own after an hour of real time. That is far
; longer than any auction and short enough to be recoverable without a console.
Bool bDhlpSuspended = False
Float fDhlpSuspendedAt = 0.0

Event OnDhlpSuspend(String eventName, String strArg, Float numArg, Form sender)
    bDhlpSuspended = True
    fDhlpSuspendedAt = Utility.GetCurrentRealTime()
    Debug.Trace("[DAC] dhlp-Suspend received - standing down until Resume")
EndEvent

Event OnDhlpResume(String eventName, String strArg, Float numArg, Form sender)
    bDhlpSuspended = False
    Debug.Trace("[DAC] dhlp-Resume received - active again")
EndEvent

Bool Function SceneOwnedElsewhere()
    If DAC_Suppressed && DAC_Suppressed.GetValue() as Int == 1
        Return True
    EndIf

    If bDhlpSuspended
        If (Utility.GetCurrentRealTime() - fDhlpSuspendedAt) > 3600.0
            bDhlpSuspended = False
            Debug.Trace("[DAC] dhlp-Suspend expired without a Resume - resuming on our own")
        Else
            Return True
        EndIf
    EndIf

    ; Dark Arena: while the player owes it AND is standing in it.
    ;
    ; The debt alone was the first attempt and was too broad - an unpaid debt
    ; would have switched this mod off everywhere in Skyrim, for as long as it
    ; went unpaid, which is indistinguishable from the mod being broken. Someone
    ; who leaves the arena with a debt (walked out, fast travelled, was teleported
    ; by another mod) should still be capturable by the bandits they then meet.
    ;
    ; Requiring BOTH keeps the protection where the arc actually is: you cannot be
    ; carried off mid-arena by an unrelated fight, and nothing follows you out.
    GlobalVariable dept = Game.GetFormFromFile(0x030CB7, "zDarkArena.esp") as GlobalVariable
    If dept && dept.GetValue() > 0
        Location arena = Game.GetFormFromFile(0x0040C2, "zDarkArena.esp") as Location
        Location here = PlayerRef.GetCurrentLocation()
        If arena && here && (here == arena || here.IsChild(arena))
            Return True
        EndIf
    EndIf

    Quest q = Quest.GetQuest("aDA_Job_Arena")
    If q && q.IsRunning()
        Return True
    EndIf
    q = Quest.GetQuest("aDA_SlaveJob_Pit")
    If q && q.IsRunning()
        Return True
    EndIf
    q = Quest.GetQuest("aDA_JobPrivate_Pit")
    If q && q.IsRunning()
        Return True
    EndIf

    Return False
EndFunction

Event OnSuppressEvent(String eventName, String strArg, Float numArg, Form sender)
    If DAC_Suppressed == None
        Return
    EndIf
    DAC_Suppressed.SetValue(numArg)
    Debug.Trace("[DAC] Suppression set to " + (numArg as Int) + " by mod event")
EndEvent

Bool Function ExternalCaptivityHold()
    If SceneOwnedElsewhere()
        Debug.Trace("[DAC] Standing down - another mod is running a scene that owns this fight")
        Return True
    EndIf

    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf

    ; Captive Player / Captive Followers. The player carries _ddRestrainedFaction
    ; for the whole time they are held - ResetRestrainedStatus() gives rank 1,
    ; ClearRestrainedState() takes it away at the end. The record lives in
    ; CaptiveFollowers.esp, NOT CaptivePlayer.esp: the property name appears in
    ; Captive Player's scripts but the faction belongs to its master.
    ;
    ; GetFactionRank, not IsInFaction - RemoveFromFaction only writes rank -1 and
    ; leaves the entry behind, which IsInFaction keeps reading as membership.
    Faction ddRestrained = Game.GetFormFromFile(0x000A9A, "CaptiveFollowers.esp") as Faction
    If ddRestrained && PlayerRef.GetFactionRank(ddRestrained) >= 0
        Return True
    EndIf

    ; SL Kidnapped Redux, mid-abduction. Stage 1 is idle - see the note in
    ; TryCapture() before touching this.
    If SLKRStage() == 2
        Return True
    EndIf

    Return False
EndFunction

Int Function SLKRStage()
    ; Read the companion patch's MIRROR, not SL Kidnapped Redux's own global.
    ;
    ; This used to hardcode 0x000414 in SL_Kidnapped_Redux.esp. That FormID is not
    ; stable across installs: ESLifier compaction renumbers it (the stock plugin
    ; has it at 0x31E1). Against any copy numbered differently from the one this
    ; was built against, the lookup returned None, this returned 0, and the mod
    ; quietly concluded SLKR was not installed - disabling the takeover, the
    ; surrender handoff and the reset, with nothing in the log to say so.
    ;
    ; 0x834 lives in DefeatAndCapture_SLKR.esp, which we ship, so it cannot move.
    ; The patch's copy of SLKR's script publishes every stage change to it.
    ;
    ; Returns 0 when the patch is absent. That is correct rather than merely safe:
    ; every behaviour gated on this needs the patch anyway.
    GlobalVariable g = Game.GetFormFromFile(0x834, "DefeatAndCapture_SLKR.esp") as GlobalVariable
    If g == None
        Return 0
    EndIf
    Return g.GetValue() as Int
EndFunction

; =====================================================================
;  SURRENDER  (works standalone - no defeat framework, no SkyrimNet)
; =====================================================================
Int Function SurrenderKeyCode()
    If DAC_SurrenderKey == None
        Return 0
    EndIf
    Return DAC_SurrenderKey.GetValue() as Int
EndFunction

Int iBoundSurrenderKey = -1

; Called from Arm(), so the binding refreshes on every game load AND whenever the
; MCM closes. RegisterForKey persists in the save, hence the rebind-only-on-change
; check rather than re-registering blindly.
Function RefreshSurrenderKey()
    Int want = SurrenderKeyCode()
    If want == iBoundSurrenderKey
        Return
    EndIf
    If iBoundSurrenderKey > 0
        UnregisterForKey(iBoundSurrenderKey)
    EndIf
    iBoundSurrenderKey = want
    If want > 0
        RegisterForKey(want)
        Debug.Trace("[DAC] Surrender hotkey bound to scancode " + want)
    Else
        Debug.Trace("[DAC] Surrender hotkey unbound")
    EndIf
EndFunction

Event OnKeyDown(Int keyCode)
    If keyCode != iBoundSurrenderKey || Utility.IsInMenuMode()
        Return
    EndIf
    Surrender()
EndEvent

; The MCM lives inside the Journal Menu, so closing the journal is the cheapest
; reliable moment to pick up a rebind - event-driven, no polling, and it works
; even with the debug poll switched off. (DAC_MCM.psc cannot host this: MCM
; Helper ships no MCM_ConfigBase source, so that script can never be recompiled.)
Event OnMenuClose(String menuName)
    If menuName == "Journal Menu"
        RefreshSurrenderKey()

        ; The MCM switch is a one-shot: act on it and clear it. Checked here
        ; rather than on a poll because closing the journal is exactly when an
        ; MCM change lands, and it costs nothing the rest of the time.
        If DAC_ReturnGear && DAC_ReturnGear.GetValue() as Int == 1
            DAC_ReturnGear.SetValue(0)
            ReturnTakenItems()
        EndIf

        ; MCM Helper has already written its own store by now; pull it into the
        ; globals so the change takes effect immediately. Last in the handler -
        ; see PullSettings for why.
        PullSettings()

        If DAC_ClearAllies && DAC_ClearAllies.GetValue() as Int == 1
            DAC_ClearAllies.SetValue(0)
            ClearAllAllies()
        EndIf

        If DAC_ReleaseHeld && DAC_ReleaseHeld.GetValue() as Int == 1
            DAC_ReleaseHeld.SetValue(0)
            Debug.Notification("[DAC] Released " + ClearAllPersisted() + " held reference(s).")
        EndIf

        If DAC_ManageAllies && DAC_ManageAllies.GetValue() as Int == 1
            DAC_ManageAllies.SetValue(0)
            ShowAllyList()
        EndIf

        RefreshMarkAllyPower()
        RefreshHealthWatch()
    EndIf
EndEvent

; Put the player alias into its OnHit state only while the health trigger is
; actually wanted. Off, the alias declares no OnHit and the VM dispatches
; nothing on every hit the player takes - which is the whole point.
Function RefreshHealthWatch()
    DAC_PlayerAlias pa = (Self as Quest).GetAliasByName("PlayerAlias") as DAC_PlayerAlias
    If pa
        pa.SetHealthWatch(ModEnabled() && HealthTriggerPct() > 0)
    EndIf
EndFunction

; Grant or take away the Mark Ally power to match the MCM switch. This is NOT tied
; to being captive - allies are made and unmade long after a captivity ends.
Function RefreshMarkAllyPower()
    If DAC_MarkAllyPower == None || PlayerRef == None
        Return
    EndIf
    Bool want = (DAC_MarkAllyOn == None) || (DAC_MarkAllyOn.GetValue() as Int == 1)
    Bool has = PlayerRef.HasSpell(DAC_MarkAllyPower)
    If want && !has
        PlayerRef.AddSpell(DAC_MarkAllyPower, false)
        Debug.Trace("[DAC] Mark Ally power granted")
    ElseIf !want && has
        PlayerRef.RemoveSpell(DAC_MarkAllyPower)
        Debug.Trace("[DAC] Mark Ally power removed")
    EndIf
EndFunction

; Give up. The whole point is that this needs nothing else installed - it is the
; non-SkyrimNet way to reach the same captivity an AI captor would impose.
; If SL Kidnapped Redux happens to be mid-ambush we hand off to it instead: its
; abduction is the better outcome, and our own capture would bind to an ambusher
; SLKR is about to delete.
Function Surrender()
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf
    If bCaptured
        Debug.Notification("You are already a prisoner.")
        Return
    EndIf

    Int slkr = SLKRStage()
    If slkr == 2
        Debug.Notification("You are already being held.")
        Return
    EndIf

    ; Offer the surrender to SL Kidnapped Redux FIRST, but do not assume it wants
    ; it. Only SLKR's own script can tell whether an ambush window is open - that
    ; lives in a script-local KidnappedStatus - and the shared stage global reads
    ; 1 both while idle AND during an ambush, so it cannot be used to decide.
    ;
    ; This used to test slkr == 1 and hand off unconditionally. Because 1 is
    ; SLKR's IDLE value, EVERY press took that branch and returned, which is why
    ; the hotkey printed "You stop resisting." and then did nothing at all.
    ;
    ; So: ask, then watch for the answer. The patch's DAC_OnSurrender converts the
    ; ambush and publishes stage 2 at once; if no ambush is running it is a no-op,
    ; and with no patch installed nothing is listening. Either way we fall through
    ; to our own capture after a short wait.
    If slkr != 0
        SendModEvent("DAC_SLKR_Surrender")
        ; Half a second, not one and a half. The patch's DAC_DoAbduction now
        ; publishes stage 2 as its SECOND line, so if SLKR is going to take the
        ; surrender it has already said so by now - and every tick spent waiting
        ; is a tick the player stands there being hit after throwing down their
        ; weapon, which is the worst possible moment for a pause.
        Int waited = 0
        While SLKRStage() != 2 && waited < 2
            Utility.Wait(0.25)
            waited += 1
        EndWhile
        If SLKRStage() == 2
            Debug.Trace("[DAC] Surrender taken by SLKR - ambush converted to an abduction")
            Debug.Notification("You stop resisting.")
            Return
        EndIf
    EndIf

    Debug.Trace("[DAC] === SURRENDER (hotkey) ===")
    Debug.Notification("You throw down your weapon and surrender.")
    If BleedoutManaged()
        RecoverFromBleedout()
    EndIf

    ; Surrendering is a group act. Whatever the follower mode says, your people
    ; put their weapons down with you - otherwise you yield and your companion
    ; carries on swinging, which reads as broken rather than as a choice.
    bSurrenderGroup = True
    TryCapture("surrender")
    bSurrenderGroup = False
EndFunction

; =====================================================================
;  LIFECYCLE
; =====================================================================
Event OnInit()
    Arm("OnInit")
EndEvent

Function Arm(String from)
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf
    RegisterForModEvent("DAC_Capture", "OnCaptureEvent")
    RegisterForModEvent("DAC_Suppress", "OnSuppressEvent")
    RegisterForModEvent("dhlp-Suspend", "OnDhlpSuspend")
    RegisterForModEvent("dhlp-Resume", "OnDhlpResume")
    RegisterForMenu("Journal Menu")
    RefreshSurrenderKey()
    RefreshMarkAllyPower()
    RefreshHealthWatch()
    SyncEssential()
    ; NOTE: the SkyrimNet ACTIONS are no longer registered from Papyrus. They are
    ; declared in SKSE\Plugins\SkyrimNet\config\actions\dac_*.yaml, which is the
    ; format the rest of the ecosystem uses - it carries questEditorId, parameter
    ; mapping, priority and declarative eligibility, and is editable in the WebUI.
    Debug.Trace("[DAC] Controller armed via " + from + "; trigger mode = " + TriggerMode())
    If ShowPopups()
        Debug.Notification("[DAC] Capture controller armed (mode " + TriggerMode() + ").")
    EndIf
    If (PollingOn() || AdoptKidnapOn()) && !bCaptured
        RegisterForSingleUpdate(CheckInterval)
    EndIf
EndFunction

Function Maintenance()
    Arm("Maintenance")
    PullSettings()
EndFunction

; =====================================================================
;  SETTINGS THAT SURVIVE A NEW GAME
; =====================================================================
; GlobalVariables live in the SAVE, so a new character resets every setting.
;
; Every MCM control now binds to an MCM Helper ModSetting instead of straight to
; a global, which means MCM Helper persists them itself to
;   Data/MCM/Settings/DefeatAndCapture.ini
; - outside any save, and in the exact place the "capture your settings into a
; my-settings mod" workflow expects to find them. That file IS the settings
; loader; there is nothing bespoke to learn and nothing of ours to ship.
;
; The globals remain the RUNTIME source of truth - every read in this script,
; every dialogue condition another mod writes, and the console all still work
; against them. This pulls the stored values into them:
;
;   on load          Maintenance()
;   on journal close OnMenuClose - the MCM lives inside the journal
;
; Only a PULL exists. MCM Helper writes the store when the user moves a control,
; so pushing back would be us fighting the thing that owns the file.
;
; NOTE this makes the MCM authoritative: a console "set DAC_X to 1" now lasts
; until the next journal close, where it is overwritten by the stored value.

String Function ModName() global
    Return "DefeatAndCapture"
EndFunction

Function PullBool(GlobalVariable g, String sId)
    If g
        g.SetValue(MCM.GetModSettingBool(ModName(), sId) as Int)
    EndIf
EndFunction

Function PullInt(GlobalVariable g, String sId)
    If g
        g.SetValue(MCM.GetModSettingInt(ModName(), sId))
    EndIf
EndFunction

Function PullFloat(GlobalVariable g, String sId)
    If g
        g.SetValue(MCM.GetModSettingFloat(ModName(), sId))
    EndIf
EndFunction

; Isolated in its own function, and called LAST by both callers, on purpose: if
; MCM Helper is absent then MCM.pex is absent too, and a call into a missing
; script aborts the function it is in. Kept here, that costs the settings pull
; and nothing else - the mod still runs on its plugin defaults, which is exactly
; the documented no-MCM behaviour.
Function PullSettings()
    If !MCM.IsInstalled()
        Debug.Trace("[DAC] MCM Helper not installed - running on plugin defaults")
        Return
    EndIf
    PullBool(DAC_ModEnabled,         "bModEnabled:General")
    PullInt(DAC_TriggerMode,         "iTriggerMode:General")
    PullFloat(DAC_HealthTrigger,     "fHealthTrigger:General")
    PullBool(DAC_ManageBleedout,     "bManageBleedout:General")
    PullFloat(DAC_RecoverHealth,     "fRecoverHealth:General")
    PullFloat(DAC_SearchRadiusGV,    "fSearchRadius:General")
    PullBool(DAC_HumanoidOnly,       "bHumanoidOnly:General")
    PullBool(DAC_SellOnTimeout,      "bSellOnTimeout:Experimental")
    ; DAC_ManageAllies is a one-shot button, not a preference - deliberately not
    ; pulled, exactly like DAC_ClearAllies and DAC_ReturnGear.
    PullBool(DAC_StripItems,         "bStripItems:General")
    PullBool(DAC_LeashEnabled,       "bLeashEnabled:General")
    PullFloat(DAC_LeashDistance,     "fLeashDistance:General")
    PullFloat(DAC_ReleaseAfterHours, "fReleaseAfterHours:General")
    PullInt(DAC_SurrenderKey,        "iSurrenderKey:General")
    PullBool(DAC_KeepFriends,        "bKeepFriends:General")
    PullBool(DAC_MarkAllyOn,         "bMarkAllyOn:General")
    PullBool(DAC_AllyReturnsGear,    "bAllyReturnsGear:General")
    PullInt(DAC_FollowerMode,        "iFollowerMode:General")
    PullBool(DAC_RestraintsEnabled,  "bRestraints:Adult")
    PullBool(DAC_AdoptKidnap,        "bAdoptKidnap:Compat")
    PullBool(DAC_ShowDebug,          "bShowDebug:Compat")

    ; Arm() ran its refreshers BEFORE this, off the pre-pull values - which is
    ; the price of keeping the pull after it rather than before. Re-run the four
    ; that read a setting. Cheap, and it makes the ordering safe in both
    ; directions: if this function never gets here, Arm has already set the mod
    ; up on its plugin defaults.
    RefreshSurrenderKey()
    RefreshMarkAllyPower()
    RefreshHealthWatch()
    SyncEssential()
    Debug.Trace("[DAC] Settings pulled from MCM Helper")
EndFunction

; =====================================================================
;  TRIGGERS
; =====================================================================
; Yamete's FireConsequence() with an EMPTY "09_EventParam" calls
; Form.SendModEvent, and the engine appends the sender - so the handler
; receives FOUR arguments. A three-parameter handler throws an arg-count
; error and silently never runs.
Event OnCaptureEvent(String eventName, String strArg, Float numArg, Form sender)
    Debug.Trace("[DAC] === DAC_Capture event RECEIVED === arg='" + strArg + "'")
    If TriggerMode() == 1
        Debug.Trace("[DAC] Ignored - standalone mode does not take external triggers")
        Return
    EndIf

    ; strArg == "handover" means the OTHER captivity mod is deliberately giving the
    ; player up and expects us to take them RIGHT NOW, while it still nominally
    ; holds them. That must bypass ExternalCaptivityHold(), which exists to stop an
    ; unrelated trigger landing mid-captivity.
    ;
    ; These two guards collided head-on: the companion patches capture BEFORE
    ; tearing down (so the captors are never briefly hostile), which means the
    ; player is still in the other mod's factions at that exact moment - exactly
    ; what the hold check refuses on. The handover was received and then declined
    ; by its own side.
    ;
    ; Senders that pass nothing (Yamete, console, anything generic) keep the guard.
    TryCapture("external consequence", strArg == "handover")
EndEvent

; Called by DAC_PlayerAlias on every hit the player takes.
;
; Bleedout is the default trigger, but it only exists if something keeps the
; player alive to reach it. A health threshold catches the case bleedout cannot:
; a blow that would take the player from healthy to dead outright, where there is
; no bleedout to enter. It also matches what most defeat mods offer, so people
; arrive expecting the setting.
;
; Off (0) by default - bleedout alone is the cleaner behaviour when it works, and
; a threshold that fires during an ordinary fight is intrusive.
Function OnPlayerDamaged()
    If !ModEnabled() || bCaptured
        Return
    EndIf
    ; Same gate as bleedout: in external-only mode this mod does not decide when
    ; a defeat happens, it waits to be told.
    If TriggerMode() == 0
        Return
    EndIf

    Int pct = HealthTriggerPct()
    If pct <= 0
        Return
    EndIf
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf
    If (PlayerRef.GetAvPercentage("health") * 100.0) > (pct as Float)
        Return
    EndIf

    ; Same reasoning as bleedout - and this one matters more, because Dark Arena's
    ; own trigger is health <= 10 on the very same event. Ours must not get there
    ; first and rob its quest of the loss it was waiting for.
    If SceneOwnedElsewhere()
        Debug.Trace("[DAC] Health trigger ignored - another mod owns this fight")
        Return
    EndIf

    Debug.Trace("[DAC] === health fell below " + pct + "% - capture trigger ===")
    If BleedoutManaged()
        RecoverFromBleedout()
    EndIf
    TryCapture("health threshold")
EndFunction

; Called by DAC_PlayerAlias when the player enters bleedout.
Function OnPlayerDefeated()
    If TriggerMode() == 0
        Return
    EndIf
    ; Checked BEFORE RecoverFromBleedout, not just before the capture. Standing
    ; the player up is itself the interference: Dark Arena has just called
    ; SetNoBleedoutRecovery(True) to hold them down for its own scene.
    If SceneOwnedElsewhere()
        Debug.Trace("[DAC] Bleedout ignored - another mod owns this fight")
        Return
    EndIf

    Debug.Trace("[DAC] === player entered BLEEDOUT (standalone trigger) ===")

    ; SURVIVE FIRST, capture second. Other death mods (Respawn - Soulslike Edition
    ; is active here) act on a downed player within a few seconds, and resolving a
    ; captor involves a cell scan. Get health positive before anything slower runs,
    ; or the player is dead before the capture lands.
    If BleedoutManaged()
        RecoverFromBleedout()
    EndIf

    TryCapture("own bleedout")
EndFunction

; =====================================================================
;  PUBLIC API - for SkyrimNet actions and other mods
; =====================================================================
; Capture the player with a KNOWN captor, skipping resolution entirely.
; This is the good path: when the AI decides an NPC takes the player prisoner,
; it hands us that exact actor, which beats any proximity guess.
; Same wrapper as TryCapture, and it needs it for the same reason: SkyrimNet can
; fire DAC_TakeCaptive more than once, and two NPCs can each decide to take the
; player in the same moment. The log that prompted this had a leash that moved
; between captors as the flows finished out of order.
Function CaptureBy(Actor who)
    If CaptureInFlight()
        Debug.Trace("[DAC] CaptureBy ignored - a capture is already being resolved")
        Return
    EndIf
    bCaptureInFlight = True
    fCaptureInFlightAt = Utility.GetCurrentRealTime()
    CaptureByBody(who)
    bCaptureInFlight = False
EndFunction

Function CaptureByBody(Actor who)
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf
    If !ModEnabled()
        Debug.Trace("[DAC] CaptureBy ignored - mod is switched off in the MCM")
        Return
    EndIf
    If bCaptured
        Debug.Trace("[DAC] CaptureBy ignored - already captured")
        Return
    EndIf
    If who == None || who == PlayerRef || who.IsDead()
        Debug.Trace("[DAC] CaptureBy refused - invalid captor")
        Return
    EndIf

    ; DELIBERATELY NOT GATED ON IsUsableCaptor - this was tried and reverted.
    ;
    ; The reasoning that put it here: a spriggan (0002C79E) took the player captive
    ; via the SkyrimNet action, and TryCapture would never have allowed it, so the
    ; AI path looked like a hole in the humanoid rule.
    ;
    ; Why that is wrong. IsHumanoid rejects ActorTypeCreature, ActorTypeUndead and
    ; ActorTypeFalmer - and in this modlist spriggans, dryads, draugr and Falmer
    ; are HUMAN NPCS wearing creature appearances, kept that way for the combat
    ; animations. They pass ActorTypeNPC and usually keep the creature tag too, so
    ; the check would have refused captures by most of the enemies actually being
    ; played against. It would have read as "the mod randomly stopped working".
    ;
    ; The deeper point: the humanoid filter exists because ResolveCaptor PICKS a
    ; captor by proximity and must not hand the role to whichever wolf stood
    ; nearest. Here the actor VOLUNTEERED - SkyrimNet drives NPCs that reason and
    ; choose, and an actor that chose to take a prisoner is demonstrating the
    ; capability the filter was trying to infer. Picking needs the filter; being
    ; volunteered does not.
    ;
    ; If a real animal ever does fire this, fix it in the action's YAML
    ; eligibility, not here.

    ; CaptureBy() deliberately skips TryCapture()'s captor resolution - the AI
    ; hands us the exact actor - but it must NOT skip the cross-mod guard. It did,
    ; and an NPC choosing DAC_TakeCaptive in the middle of a Captive Player
    ; captivity captured the player on top of it: Captive Player's sequence stopped
    ; dead, its scenes never resumed, and the player was left unbound.
    If ExternalCaptivityHold()
        Debug.Trace("[DAC] CaptureBy refused - another captivity mod is holding the player")
        Return
    EndIf

    ; The player may or may not be down when the AI decides this (a surrender
    ; mid-fight is not a bleedout), so recovery is best-effort.
    If BleedoutManaged()
        RecoverFromBleedout()
    EndIf

    ; ASK FIRST, if the player asked to be asked.
    ;
    ; This path used to skip the prompt entirely, so "Confirm captures" silently
    ; did not apply to AI captures - the case that needs it MOST. A proximity
    ; capture happens because the player lost a fight they chose; a SkyrimNet
    ; capture can happen because an NPC decided to, in the middle of a quest, and
    ; the prompt is the player's only way to protect that progress.
    ;
    ; Placed last, immediately before BeginCapture, for the same reason as in
    ; TryCapture: the captor is known so the question can name them, and nothing
    ; has been applied yet - no truce, no stripping, no restraints.
    ;
    ; No FreeRoomAfterDeny() on the Deny branch, unlike TryCapture, and that is
    ; deliberate: this path never called FreezeRoom, so there is no pacified room
    ; to hand back. Calling it here would shove a StartCombat into a fight that was
    ; never stopped.
    If ConfirmCaptureOn()
        If !AskToBeCaptured(who, "SkyrimNet")
            Debug.Trace("[DAC] CaptureBy DENIED by the player at the confirmation prompt")
            Return
        EndIf
    EndIf

    Debug.Trace("[DAC] CaptureBy: external trigger, captor = " + who)
    BeginCapture(who)
EndFunction

Bool Function IsCaptured()
    Return bCaptured
EndFunction

Actor Function GetCaptor()
    Return Captor
EndFunction

; ---------------------------------------------------------------------
; SkyrimNet ACTION entry points.
;
; These are INSTANCE functions on this quest script, because SkyrimNet's YAML
; action format binds an action to questEditorId + scriptName + function, and
; passes the triggering NPC via parameterMapping (type: speaker).
; See SKSE\Plugins\SkyrimNet\config\actions\dac_*.yaml.
; ---------------------------------------------------------------------
Function AI_TakeCaptive(Actor akCaptor)
    Debug.Trace("[DAC] SkyrimNet action DAC_TakeCaptive fired by " + akCaptor)
    CaptureBy(akCaptor)
EndFunction

Function AI_ReleaseCaptive(Actor akCaptor)
    Debug.Trace("[DAC] SkyrimNet action DAC_ReleaseCaptive fired by " + akCaptor)
    ; Only the real captor may release - the YAML eligibility already restricts
    ; this to whoever carries the captor marker, but guard anyway.
    If akCaptor == Captor || akCaptor == None
        ; ReleasePlayer clears Captor, so grab them first.
        Actor who = Captor
        If who == None
            who = akCaptor
        EndIf
        ReleasePlayer()
        GiveBackOnRelease(who)
    Else
        Debug.Trace("[DAC] Release refused - " + akCaptor + " is not the captor")
    EndIf
EndFunction

; A DELIBERATE release hands your things back.
;
; This is not the ally rule and does not need one: the ally path is for someone
; who changed sides, this is for a captor who decided to let you go - talked
; round, paid, bored, or promised something. Keeping your gear afterwards would
; make "I release you" mean "I keep your armour", which is not what the model
; chose or what the player was negotiating for.
;
; Only THEIR haul, exactly as the ally rule works. A second captor still holding
; part of your inventory keeps it - one person letting you go says nothing about
; the rest. Deliberately NOT applied to the release TIMER or the watchdog: a
; captor who wandered off or died never decided anything.
Function GiveBackOnRelease(Actor who)
    If who == None
        Return
    EndIf
    Int got = ReturnItemsFrom(who)
    If got > 0
        Debug.Notification(who.GetDisplayName() + " returns your belongings.")
        Debug.Trace("[DAC] Release: " + who + " handed back " + got + " stack(s)")
        If SkyrimNetPresent()
            SkyrimNetApi.RegisterEvent("dac_release", \
                who.GetDisplayName() + " gave " + PlayerRef.GetDisplayName() \
                + " back the belongings taken from them when letting them go.", \
                who, PlayerRef)
        EndIf
    EndIf
EndFunction

; Shared entry point for every trigger.
; =====================================================================
;  WHAT KIND OF CAPTURE IS THIS
; =====================================================================
; "source" used to be a debug string and nothing else. It has to mean something,
; because the rules genuinely differ:
;
;   DEFEAT  (bleedout, health threshold) - somebody beat the player. There must
;           have BEEN a fight, and the winner of that fight is the natural captor.
;   YIELD   (surrender hotkey) - the player chose this. No fight is required; you
;           can walk into a camp and give up.
;   HANDOFF (AI decision, another mod, SLKR/Captive Player) - the caller already
;           knows who and why. Do not second-guess it.
; Folded into "Show message boxes" rather than owning a switch of its own. Both
; are the same thing - the mod telling you what it is about to do and letting you
; look at it - and two toggles for one intent is one too many.
Bool Function ConfirmCaptureOn()
    Return ShowPopups()
EndFunction

Bool Function UIExtPresent()
    Return Game.GetModByName("UIExtensions.esp") != 255
EndFunction

; "X is trying to capture you - Allow / Deny."
;
; When a capture fires from somewhere unexpected, this names the actor and the
; route BEFORE anything is applied, turning "why did the innkeeper take me
; prisoner" into a question answerable on the spot.
;
; Two implementations, because the good one is optional:
;
;   UIExtensions present - a UIListMenu, whose entries are ordinary strings, so
;     the captor's NAME and the reason sit in the menu itself.
;   Otherwise - a plain MESG box. Message.Show() takes FLOAT arguments only, so
;     a MESG can never be told a name; the notification carries it instead.
;
; Neither is required. With no UIExtensions AND no message record, the capture
; simply proceeds - a missing optional never blocks the mod.
Bool Function AskToBeCaptured(Actor who, String source)
    String line = who.GetDisplayName() + " is trying to capture you."

    If UIExtPresent()
        UIListMenu menu = UIExtensions.GetMenu("UIListMenu", true) as UIListMenu
        If menu
            menu.AddEntryItem(line)
            menu.AddEntryItem("Allow")
            menu.AddEntryItem("Deny")
            menu.OpenMenu()
            Int pick = menu.GetResultInt()
            If pick == 2
                Debug.Notification(who.GetDisplayName() + " does not take you.")
                Return False
            EndIf
            Return True             ; header, Allow, or dismissed = allow
        EndIf
    EndIf

    Debug.Notification(line)
    If DAC_ConfirmBox == None
        Return True
    EndIf
    If DAC_ConfirmBox.Show() == 0
        Return True
    EndIf
    Debug.Notification(who.GetDisplayName() + " does not take you.")
    Return False
EndFunction

; Drop an ally by NAME, off a live list - no hunting for the body, no casting at
; anything. This is what the "cast Mark Ally at the corpse" route could never do:
; reach an ally you cannot physically get to.
;
; Needs UIExtensions for the list itself. Without it the button says so rather
; than doing nothing, because a silent no-op is the worst possible answer.
Function ShowAllyList()
    If !UIExtPresent()
        Debug.MessageBox("[DAC] The ally list needs UIExtensions.\n\n" \
            + "Without it, drop an ally by casting Mark Ally at them.")
        Return
    EndIf
    Int n = StorageUtil.FormListCount(PlayerRef, "DAC_Allies")
    If n == 0
        Debug.Notification("You have no allies.")
        Return
    EndIf
    UIListMenu menu = UIExtensions.GetMenu("UIListMenu", true) as UIListMenu
    If menu == None
        Return
    EndIf
    menu.AddEntryItem("Drop which ally? (" + n + " held)")
    Int i = 0
    While i < n
        Actor a = StorageUtil.FormListGet(PlayerRef, "DAC_Allies", i) as Actor
        If a
            String label = a.GetDisplayName()
            If a.IsDead()
                label = label + "  (dead)"
            EndIf
            menu.AddEntryItem(label)
        Else
            menu.AddEntryItem("(a lost reference)")
        EndIf
        i += 1
    EndWhile

    menu.OpenMenu()
    Int pick = menu.GetResultInt()
    ; Entry 0 is the header, so the list starts at 1. -1 is "dismissed".
    If pick < 1
        Return
    EndIf
    Actor chosen = StorageUtil.FormListGet(PlayerRef, "DAC_Allies", pick - 1) as Actor
    If chosen == None
        StorageUtil.FormListRemove(PlayerRef, "DAC_Allies", None, true)
        Debug.Notification("A lost reference was cleared.")
        Return
    EndIf
    ToggleAlly(chosen)
EndFunction

; FreezeRoom stopped everyone's combat to buy time for the capture. If the
; player says no, that calm is a lie - nobody agreed to anything - so hand the
; fight back rather than leaving a room of pacified enemies standing about.
Function FreeRoomAfterDeny()
    StorageUtil.UnsetIntValue(PlayerRef, "DAC_GroupDecided")
    StorageUtil.UnsetIntValue(PlayerRef, "DAC_GroupTruce")
    ; Inline walk - an Actor[] returned from a function is None on this setup.
    Cell c = PlayerRef.GetParentCell()
    If c == None
        Return
    EndIf
    Int[] types = new Int[3]
    types[0] = 43
    types[1] = 44
    types[2] = 62
    Float r = Radius()
    Int ti = 0
    While ti < 3
        Int ftype = types[ti]
        Int total = c.GetNumRefs(ftype)
        Int i = 0
        While i < total
            Actor a = c.GetNthRef(i, ftype) as Actor
            If a && a != PlayerRef && !a.IsDead() && a.GetDistance(PlayerRef) <= r \
                && a.GetFactionRank(DAC_TruceFaction) < 0
                a.StartCombat(PlayerRef)
            EndIf
            i += 1
        EndWhile
        ti += 1
    EndWhile
EndFunction

Bool Function IsDefeatSource(String source)
    Return source == "own bleedout" || source == "health threshold"
EndFunction

; Who was the player actually fighting? Read at the MOMENT of defeat, before any
; of the slow work, because combat state evaporates the instant they stand up.
;
; This is the fix for "fell off a cliff, landed next to a farmer, farmer took me
; prisoner". Falling damage has no attacker and starts no combat, so a defeat
; with no combat behind it is not a defeat by anybody - and is refused.
;
; GetCombatTarget rather than tracking every OnHit: the alias comments already
; explain why an always-on OnHit is not worth its cost, and the combat target is
; the same answer for free.
Actor Function FightOpponent()
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf
    Actor foe = PlayerRef.GetCombatTarget()
    If IsUsableCaptor(foe)
        Return foe
    EndIf
    Return None
EndFunction

Bool Function CaptureInFlight()
{True while a capture is being RESOLVED (scan, captor pick, confirm prompt).

 The staleness escape hatch is not optional. Papyrus has no try/finally: if the
 wrapper below is ever killed outright - a VM stack reset, a save loaded with the
 flag set - the flag would stay true and the mod would refuse every capture for
 the rest of the game, which is a far worse failure than the duplicate prompts
 this exists to stop. 60s is generous enough for a player to sit on the prompt
 and short enough that a stuck flag heals itself.}
    If !bCaptureInFlight
        Return False
    EndIf
    If (Utility.GetCurrentRealTime() - fCaptureInFlightAt) > 60.0
        Debug.Trace("[DAC] capture-in-flight flag was stale (>60s) - clearing it")
        bCaptureInFlight = False
        Return False
    EndIf
    Return True
EndFunction

; Wrapper, so the flag is set and cleared in ONE place. The body below keeps its
; dozen early Returns untouched - clearing the flag at each of them by hand is
; exactly the kind of bookkeeping that rots the first time someone adds a
; thirteenth. An error inside the body aborts the BODY and returns here, so the
; clear still runs.
Function TryCapture(String source, Bool ignoreExternalHold = false)
    If CaptureInFlight()
        Debug.Trace("[DAC] " + source + ": ignored, a capture is already being resolved")
        Return
    EndIf
    bCaptureInFlight = True
    fCaptureInFlightAt = Utility.GetCurrentRealTime()
    TryCaptureBody(source, ignoreExternalHold)
    bCaptureInFlight = False
EndFunction

Function TryCaptureBody(String source, Bool ignoreExternalHold = false)
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf

    ; Sample the fight FIRST - ResolveCaptor and ApplyTruce take seconds, and by
    ; the time they finish the player is standing and out of combat.
    Actor opponent = None
    If IsDefeatSource(source)
        opponent = FightOpponent()
        If opponent == None && !PlayerRef.IsInCombat()
            Debug.Trace("[DAC] " + source + ": ignored - the player was not fighting anyone. " \
                + "A fall, a trap or a stray spell is not a defeat by somebody.")
            Return
        EndIf
    EndIf
    StorageUtil.SetFormValue(PlayerRef, "DAC_Opponent", opponent as Form)
    StorageUtil.SetStringValue(PlayerRef, "DAC_CaptureSource", source)

    If !ModEnabled()
        Debug.Trace("[DAC] " + source + ": ignored, mod is switched off in the MCM")
        Return
    EndIf

    If bCaptured
        Debug.Trace("[DAC] " + source + ": ignored, player is already captured")
        Return
    EndIf

    ; Stand down only while SL Kidnapped Redux is actually holding the player
    ; (stage 2). Capturing then is actively harmful: the ambushers are
    ; FakeAmbushActors that SLKR calls Delete() on right after the teleport, so
    ; the captor stops existing and our own watchdog cancels the capture a moment
    ; later. CheckKidnapAdoption() takes over at stage 3, where the handoff was
    ; designed to happen.
    ;
    ; STAGE 1 IS NOT AN ABDUCTION - it is SLKR's IDLE value, and the value the
    ; plugin SHIPS the global with. Deferring on it (as this did) refused every
    ; external trigger, every surrender and every bleedout capture for the whole
    ; game on any load order containing SLKR, whether or not it had ever run.
    ; Only the stage-3 kidnap handoff still worked, which is exactly why the SLKR
    ; takeover tested fine while the surrender hotkey appeared to do nothing.
    ;
    ; Verified against SLKR_PlayerAlias_Script.psc - the ONLY three writes are
    ; SetValue(1) in DefaultVariables() (reset), SetValue(2) once an ambusher
    ; lands a hit, SetValue(3) on resolve. There is no 0. The ambush window
    ; itself is held in a script-LOCAL KidnappedStatus that nothing outside SLKR
    ; can read, so it cannot be guarded on from here.
    If ignoreExternalHold
        Debug.Trace("[DAC] " + source + ": handover - taking the player from the mod that held them")
    ElseIf ExternalCaptivityHold()
        Debug.Trace("[DAC] " + source + ": deferred - another captivity mod is holding the player")
        Return
    EndIf

    ; STOP THE FIGHT FIRST. Everything below this line takes Papyrus time we do
    ; not control, and the player spends all of it being hit. See THE HOSTILE GAP.
    FreezeRoom()

    Actor who = ResolveCaptor()

    ; Ask first, if the player wants to be asked. Placed HERE on purpose: the
    ; captor is known, so the question can name them, and nothing has been
    ; applied yet - no truce, no stripping, no restraints - so "Deny" costs a
    ; cell scan and leaves no state behind to unwind.
    If who != None && ConfirmCaptureOn()
        If !AskToBeCaptured(who, source)
            Debug.Trace("[DAC] " + source + ": DENIED by the player at the confirmation prompt")
            FreeRoomAfterDeny()
            Return
        EndIf
    EndIf

    If who == None
        Debug.Trace("[DAC] " + source + ": ABORTED - no captor could be resolved")
        If ShowPopups()
            Debug.MessageBox("[DAC] Capture fired, but no captor could be resolved. See Papyrus log.")
        EndIf
        Return
    EndIf

    BeginCapture(who)
EndFunction

; =====================================================================
;  CAPTOR RESOLUTION
; =====================================================================
; =====================================================================
;  THE HOSTILE GAP
; =====================================================================
; From a real log, an SL Kidnapped Redux handoff:
;
;   01:02:06  SLKR resolved (stage 3) - taking over
;   01:02:08  player entered BLEEDOUT          <- still being attacked
;   01:02:09  cell scan done, captor picked
;   01:02:11  Truce: added 9 actor(s)          <- room finally stands down
;   01:02:14  CAPTURE COMPLETE
;
; FIVE SECONDS of the whole room beating on a player the mod has already decided
; is a prisoner. Long enough to be defeated twice over, which is exactly what
; happened.
;
; The cause is not one slow step. It is that capture ran TWO sequential
; MiscUtil.ScanCellNPCs passes - one in ResolveCaptor to pick the captor, another
; in ApplyTruce to pacify - and pacification was the second of them. Under a real
; fight Papyrus is time-sliced, so each pass costs seconds however cheap it looks.
;
; Two fixes, both here:
;   1. StopCombat FIRST, before anything is resolved. Nothing about ending a
;      fight requires knowing who the captor is.
;   2. Scan ONCE and share it. The captor pick and the truce walk the same actors.


; GRAVEYARD - three actor sources tried here and removed, all for one reason.
;
;   MiscUtil.ScanCellNPCs          PapyrusUtil   -> None
;   PapyrusUtil.ActorArray         PapyrusUtil   -> None
;   PapyrusUtil.MergeActorArray    PapyrusUtil   -> None
;   PapyrusUtil.RemoveDupeActor    PapyrusUtil   -> None
;   PO3_SKSEFunctions.GetCombatTargets            po3 -> None
;   PO3_SKSEFunctions.GetActorsByProcessingLevel  po3 -> None
;
; Six functions, two independent SKSE plugins, one shared property: they all
; return Actor[]. Everything else from the same plugins works - GetNumRefs (Int),
; GetNthRef (single ref), the whole of StorageUtil - so this is not "PapyrusUtil
; is broken" and not "po3 is missing". It is Actor[] returns specifically.
;
; Each removal was chased separately and each looked like its own bug, which cost
; most of a day. The rule that falls out: NEVER take an actor list from a native.
; Build it in Papyrus with `new Actor[N]` and a count - see CellActors().
;
; po3 is consequently no longer used by this mod at all.
Function FreezeRoom()
{Pull everyone out of combat immediately, before the slow work.

 Also decides the truce mode here, and this is the ONLY place it can honestly be
 decided: ApplyTruce reads it off the captor's hostility, but by then we have
 already stopped their combat, and the log above shows the consequence - a captor
 picked as NEAREST HOSTILE arriving at ApplyTruce reading "friendly captor".

 Sampling before pacifying is the whole point, so the answer is recorded now and
 ApplyTruce is told not to second-guess it.}
    ; Inline walk, same reason as ApplyTruce: an Actor[] returned across a function
    ; boundary comes back None here, so this used to bail on line 2 and the whole
    ; "stop the fight FIRST" net never ran even once.
    Cell c = PlayerRef.GetParentCell()
    If c == None
        Return
    EndIf
    Int[] types = new Int[3]
    types[0] = 43
    types[1] = 44
    types[2] = 62
    Float r = Radius()
    Int stopped = 0
    Bool anyHostile = false

    Int ti = 0
    While ti < 3
        Int ftype = types[ti]
        Int total = c.GetNumRefs(ftype)
        Int i = 0
        While i < total
            Actor a = c.GetNthRef(i, ftype) as Actor
            If a && a != PlayerRef && !a.IsDead() && a.GetDistance(PlayerRef) <= r \
                && a.IsHostileToActor(PlayerRef)
                anyHostile = true
                a.StopCombat()
                a.StopCombatAlarm()
                a.EvaluatePackage()
                stopped += 1
            EndIf
            i += 1
        EndWhile
        ti += 1
    EndWhile
    If StorageUtil.FormListCount(PlayerRef, "DAC_TruceMembers") == 0
        Int grp = 0
        If anyHostile
            grp = 1
        EndIf
        StorageUtil.SetIntValue(PlayerRef, "DAC_GroupTruce", grp)
        StorageUtil.SetIntValue(PlayerRef, "DAC_GroupDecided", 1)
        Debug.Trace("[DAC] Truce mode decided BEFORE pacifying: " + grp + " (1 = the room was hostile)")
    EndIf
    Debug.Trace("[DAC] Room frozen: " + stopped + " actor(s) out of combat before the captor was resolved")
EndFunction

Actor Function ResolveCaptor()
    ; FIRST: whoever the player was actually fighting, sampled at the moment of
    ; defeat by TryCapture. Proximity is a guess; this is the answer. It stops a
    ; bystander who happened to be standing closer than the actual winner from
    ; being handed the prisoner.
    Actor opponent = StorageUtil.GetFormValue(PlayerRef, "DAC_Opponent") as Actor
    If IsUsableCaptor(opponent)
        Debug.Trace("[DAC] Captor from THE FIGHT (player's combat target): " + opponent)
        Return opponent
    EndIf

    ; Yamete's Resolution aliases are NOT populated when a consequence fires -
    ; kept only because it costs nothing if that ever changes.
    Quest resQ = Quest.GetQuest("Yam_Resolution")
    If resQ
        Actor a = AliasActor(resQ, "LeadVictoire")
        If IsUsableCaptor(a)
            Debug.Trace("[DAC] Captor from LeadVictoire: " + a)
            Return a
        EndIf
        Int i = 0
        While i < 10
            a = AliasActor(resQ, "Victoire" + i)
            If IsUsableCaptor(a)
                Debug.Trace("[DAC] Captor from Victoire" + i + ": " + a)
                Return a
            EndIf
            i += 1
        EndWhile
    EndIf

    ; Inline walk, two passes over it. PickNearest(nearby, ...) is gone with the
    ; array it took: on this setup an Actor[] handed across a function boundary is
    ; None, so this whole tail used to abort at "Cell scan returned nothing" and
    ; the surrender path could never resolve a captor at all.
    Cell c = PlayerRef.GetParentCell()
    If c == None
        Debug.Trace("[DAC] ResolveCaptor: player has no parent cell")
        Return None
    EndIf

    Actor best = None
    Float bestDist = 0.0
    Float r = Radius()
    Int[] types = new Int[3]
    types[0] = 43
    types[1] = 44
    types[2] = 62

    ; pass 0 requires hostility; pass 1 drops it, because after a defeat the
    ; winners have usually been calmed already and "hostile" then matches nobody.
    Int pass = 0
    While pass < 2 && best == None
        Bool requireHostile = (pass == 0)
        Int ti = 0
        While ti < 3
            Int ftype = types[ti]
            Int total = c.GetNumRefs(ftype)
            Int i = 0
            While i < total
                Actor a = c.GetNthRef(i, ftype) as Actor
                If a && IsUsableCaptor(a) && a.GetDistance(PlayerRef) <= r \
                    && (!requireHostile || a.IsHostileToActor(PlayerRef))
                    Float d = a.GetDistance(PlayerRef)
                    If best == None || d < bestDist
                        best = a
                        bestDist = d
                    EndIf
                EndIf
                i += 1
            EndWhile
            ti += 1
        EndWhile
        If best
            Debug.Trace("[DAC] Captor from NEAREST (requireHostile=" + requireHostile \
                + "): " + best)
        EndIf
        pass += 1
    EndWhile

    If best == None
        Debug.Trace("[DAC] ResolveCaptor: cell walk found no usable captor")
    EndIf
    Return best
EndFunction

Actor Function AliasActor(Quest q, String aliasName)
    ReferenceAlias ra = q.GetAliasByName(aliasName) as ReferenceAlias
    If ra
        Return ra.GetReference() as Actor
    EndIf
    Return None
EndFunction

Bool Function IsUsableCaptor(Actor a)
    If a == None || a == PlayerRef || a.IsDead() || a.IsPlayerTeammate()
        Return False
    EndIf
    Return IsHumanoid(a)
EndFunction

Bool Function IsHumanoid(Actor a)
{A captor strips you, carries your gear, hands you a key and holds a leash.
 A wolf does none of that, and Skyrim will happily hand us one as the winner of
 the fight. ActorTypeNPC is the game's own marker for the person-shaped behaviour
 graph - it covers men, mer, beast races, draugr, Falmer and vampires, and leaves
 out animals, spiders, chaurus, dragons, atronachs and automatons.

 The two extra exclusions are for modded races that carry ActorTypeNPC on top of a
 creature tag to borrow humanoid animations; those are still not people.}
    If DAC_HumanoidOnly == None || DAC_HumanoidOnly.GetValue() as Int == 0
        Return True
    EndIf
    If !a.HasKeywordString("ActorTypeNPC")
        Return False
    EndIf
    If a.HasKeywordString("ActorTypeAnimal") || a.HasKeywordString("ActorTypeCreature")
        Return False
    EndIf

    ; Draugr and Falmer pass ActorTypeNPC - they use the humanoid rig - but they
    ; are not people who take prisoners, strip them, hold a key and negotiate. A
    ; draugr guarding a crypt for four thousand years has no use for a captive.
    ;
    ; Part of the humanoid test rather than a setting of its own: "only people can
    ; take you captive" already promises people, and a draugr is not one. Turning
    ; the humanoid filter off lets them back in along with the wolves.
    If a.HasKeywordString("ActorTypeUndead") || a.HasKeywordString("ActorTypeFalmer")
        Return False
    EndIf
    Return True
EndFunction

; =====================================================================
;  CAPTURE
; =====================================================================
Function BeginCapture(Actor who)
    ; Re-entrancy guard: set the flag FIRST so a second poll/event landing in the
    ; same tick cannot start a second capture (which would double-strip and
    ; overwrite the recorded faction list, leaking factions on release).
    If bCaptured
        Debug.Trace("[DAC] BeginCapture ignored - already captured")
        Return
    EndIf
    bCaptured = True
    ; SET THE GLOBAL IN THE SAME BREATH AS THE FLAG. It is also set further down,
    ; harmlessly, but by then the truce has been applied and a cell scan has run -
    ; seconds of Papyrus time.
    ;
    ; The watchdog treats "bCaptured true, DAC_Captured zero" as the player having
    ; cleared the global by console, and releases. So a tick landing inside that
    ; window tore the capture down WHILE BeginCapture was still building it: the
    ; log showed "Global cleared externally - releasing" and "RELEASED" arriving
    ; between the captor being chosen and CAPTURE COMPLETE. The player was then
    ; free again mid-fight and promptly captured by the next attacker, which is
    ; why the leash appeared to jump from one captor to another.
    DAC_Captured.SetValue(1)
    Captor = who
    iTruceAge = 0
    iTruceTick = 0

    ; 1. Factions first - this is what makes the whole group stand down.
    Int joined = ApplyTruce(who)

    ; 2. Back on your feet, if we are the ones managing bleedout.
    If BleedoutManaged()
        RecoverFromBleedout()
    EndIf

    ; 3. Optional gear transfer.
    If StripOn()
        StripPlayer(who)
    EndIf

    ; 3b. Optional restraints - AFTER the strip, or they would be taken too.
    ApplyRestraints(who)

    ; 3c. Escape routes.
    fCaptureTime = Utility.GetCurrentGameTime()

    DAC_Captured.SetValue(1)
    StorageUtil.SetIntValue(PlayerRef, "DAC_Captured", 1)
    StorageUtil.SetFormValue(PlayerRef, "DAC_Captor", who as Form)
    StorageUtil.SetIntValue(who, "DAC_IsCaptor", 1)

    ; State + marker for SkyrimNet.
    CaptureState = 1
    CaptorName = who.GetDisplayName()
    If DAC_CaptorAbility
        who.AddSpell(DAC_CaptorAbility, false)
    EndIf
    NarrateCapture(who)

    PlayerRef.StopCombat()
    PlayerRef.StopCombatAlarm()
    who.StopCombat()
    who.EvaluatePackage()

    ; Public API. Anything that wants to react to a capture can listen for this
    ; instead of polling DAC_Captured - the companion leash patch does, and so
    ; can any third party. The captor is on the player as StorageUtil form
    ; "DAC_Captor" by this point, which is how a listener finds out who.
    SendModEvent("DAC_OnCapture")

    Debug.Trace("[DAC] CAPTURE COMPLETE; captor = " + who + "; actors pacified = " + joined)
    ; The corner notification is the normal player-facing feedback and always
    ; shows. The message box is debug-only noise on top of it.
    Debug.Notification("You have been captured by " + who.GetDisplayName() + ".")
    If ShowPopups()
        ; Says what it now MEANS. This used to read "Joined N of their factions",
        ; left over from when capture borrowed the captor's own factions. After
        ; the switch to a truce faction the number counts ACTORS put under the
        ; truce, and the old wording made it look like the replaced mechanism was
        ; still running.
        Debug.MessageBox("[DAC] Captured by " + who.GetDisplayName() + "\n" \
            + joined + " actor(s) now under truce.\n\nTo free yourself:  set DAC_Captured to 0")
    EndIf

    RegisterForSingleUpdate(CheckInterval)
EndFunction

; "Keep fighting" needs an ending, and this is it.
;
; Mode 0 leaves your companion at war with the people holding you, which is the
; right drama - but the fight had no resolution. They were beaten, stood back up,
; charged in again, and were beaten again, forever, around a captivity that had
; already settled. Nobody wins and nothing concludes.
;
; So: fight on, but LOSING now means something. A follower who goes down while
; you are held is taken prisoner too, exactly as you were. That is what would
; happen to anyone else who lost that fight, and it ends the loop the only way
; that respects what mode 0 is for.
;
; Only while the player is captive, and only in mode 0 - the other two modes
; already decided the follower's fate at capture time.
Int Function CaptureDownedFollowers()
    If !bCaptured || FollowerMode() != 0 || DAC_TruceFaction == None
        Return 0
    EndIf
    ; Inline walk - an Actor[] returned from a function is None on this setup.
    Cell c = PlayerRef.GetParentCell()
    If c == None
        Return 0
    EndIf
    Int[] types = new Int[3]
    types[0] = 43
    types[1] = 44
    types[2] = 62
    Float r = Radius()
    Int taken = 0
    Int ti = 0
    While ti < 3
        Int ftype = types[ti]
        Int total = c.GetNumRefs(ftype)
        Int i = 0
        While i < total
            Actor a = c.GetNthRef(i, ftype) as Actor
            If a && a != PlayerRef && a.GetDistance(PlayerRef) <= r \
                && a.IsPlayerTeammate() && !a.IsDead() \
            && a.IsBleedingOut() && a.GetFactionRank(DAC_TruceFaction) < 0
            a.AddToFaction(DAC_TruceFaction)
            StorageUtil.FormListAdd(PlayerRef, "DAC_TruceMembers", a as Form, false)
            StorageUtil.FormListAdd(PlayerRef, "DAC_CaptiveFollowers", a as Form, false)
            StorageUtil.SetIntValue(a, "DAC_IsCaptive", 1)
            a.StopCombat()
            a.StopCombatAlarm()
            a.EvaluatePackage()
            taken += 1
            Debug.Notification(a.GetDisplayName() + " is beaten and taken prisoner as well.")
            Debug.Trace("[DAC] Downed follower captured: " + a)
            If SkyrimNetPresent()
                SkyrimNetApi.RegisterEvent("dac_capture", \
                    a.GetDisplayName() + " fought on after " + PlayerRef.GetDisplayName() \
                    + " was taken, was beaten down, and has now been made a prisoner too.", \
                    a, PlayerRef)
            EndIf
            EndIf
            i += 1
        EndWhile
        ti += 1
    EndWhile
    Return taken
EndFunction

; The heart of it: inherit the captor's factions so the entire group - including
; anyone who wanders in later - reads the player as one of their own. Every
; faction actually added is recorded so release can undo exactly this set.
; Pacify the captor's whole group by putting the player AND every nearby actor
; into ONE faction of ours that is Ally to itself.
;
; This replaces borrowing the captor's own factions, which had a real defect:
; joining BanditFaction to placate one bandit made EVERY bandit in Skyrim read
; the player as a friend. A lone highwayman pacified the whole hold. Membership
; here is per-REFERENCE, so only the actors actually present are affected.
;
; It also makes "they stayed friendly afterwards" possible: ending the truce is
; a choice, not a consequence of release.
;
; Newcomers: borrowing the captor's factions covered anyone who wandered in later
; for free. This does not, so ApplyTruce() is re-run on every watchdog tick while
; captured - already-tagged actors are skipped by the rank check.
Int Function ApplyTruce(Actor who)
    If DAC_TruceFaction == None
        Debug.Trace("[DAC] No truce faction - falling back to borrowing captor factions")
        Return JoinCaptorFactions(who)
    EndIf

    If PlayerRef.GetFactionRank(DAC_TruceFaction) < 0
        PlayerRef.AddToFaction(DAC_TruceFaction)
    EndIf

    ; Decide ONCE, on the first call of a captivity, whether this is a "group"
    ; truce or a lone one - and decide it from the CAPTOR, not per bystander.
    ;
    ; Per-bystander hostility looked right and is not: SeverActions' yield and
    ; ceasefire system strips hostile factions and zeroes aggression, so a bandit
    ; who has yielded reports IsHostileToActor == false while very much still
    ; being one of the people holding you. Filtering on that would leave their
    ; whole group outside the truce, and the moment the ceasefire broke they
    ; would all turn on a stripped, unarmed player at once.
    ;
    ; The captor's own status is the reliable signal, and it has to be sampled
    ; before they are pacified - after the first call the captor is in the truce
    ; and no longer reads as hostile, which would silently flip the mode.
    ; FreezeRoom already decided this, from a sample taken BEFORE anyone was
    ; pacified - which is the only honest moment. Only fall back to reading it off
    ; the captor when nothing decided it (a capture that never went through
    ; TryCapture, e.g. CaptureBy from another mod).
    If StorageUtil.GetIntValue(PlayerRef, "DAC_GroupDecided") != 1 && StorageUtil.FormListCount(PlayerRef, "DAC_TruceMembers") == 0
        Int grp = 0
        If who && who.IsHostileToActor(PlayerRef)
            grp = 1
        EndIf
        StorageUtil.SetIntValue(PlayerRef, "DAC_GroupTruce", grp)
        StorageUtil.SetIntValue(PlayerRef, "DAC_GroupDecided", 1)
        Debug.Trace("[DAC] Truce mode: " + grp + " (1 = enemy captor, pacify the room; 0 = friendly captor, pacify only threats)")
    EndIf
    Bool groupTruce = StorageUtil.GetIntValue(PlayerRef, "DAC_GroupTruce") == 1

    Int added = 0
    If who && who.GetFactionRank(DAC_TruceFaction) < 0
        who.AddToFaction(DAC_TruceFaction)
        StorageUtil.FormListAdd(PlayerRef, "DAC_TruceMembers", who as Form, false)
        who.StopCombat()
        who.StopCombatAlarm()
        added += 1
    EndIf

    ; THE WALK IS INLINE, and that is the whole fix.
    ;
    ; ScanNearby() used to hand back an Actor[] here. It cannot: on this setup,
    ; RETURNING an Actor[] ACROSS A FUNCTION BOUNDARY yields None. That was proven
    ; with a pure-Papyrus function which traced "3 actor(s) in radius" one line
    ; above its own `Return out` and still delivered None to its caller - no native
    ; involved. It is why `nearby` was empty in every single test, and why the
    ; truce has never held anyone but the captor, who arrives as an ARGUMENT rather
    ; than through an array.
    ;
    ; So no array crosses a boundary any more. The cell is walked right here and
    ; each actor is dealt with where it is found. "Scan once and share it" was an
    ; optimisation resting on an assumption that is false on this load order.
    Cell c = PlayerRef.GetParentCell()
    If c
        Int[] types = new Int[3]
        types[0] = 43       ; kNPC              - SD+
        types[1] = 44       ; kLeveledCharacter - SD+
        types[2] = 62       ; kCharacter (ACHR) - SL Defeat
        Float r = Radius()
        Int seen = 0

        Int ti = 0
        While ti < 3
            Int ftype = types[ti]
            Int total = c.GetNumRefs(ftype)
            Int i = 0
            While i < total
                Actor a = c.GetNthRef(i, ftype) as Actor
            ; Followers are handled by FollowerMode, not excluded outright:
            ;   0  keep fighting - the captors stay hostile to them, so whoever
            ;      puts them down takes them, exactly as it would any other fight
            ;   1  pacified with you - they stand down too, as a bystander
            ;   2  captured with you - pacified AND recorded as a fellow prisoner
            ;
            ; Mode 0 is the old behaviour and stays the default, but it needs an
            ; ending: left alone the captors and the follower grind on forever,
            ; downed and recovering, around a captivity that has already resolved.
            ;
            ; A surrender always brings them in whatever the mode - giving up as a
            ; group is an explicit choice, and leaving your companion swinging
            ; after you have thrown down your weapon reads as a bug.
            ;
            ; Anyone not actually hostile. The truce exists to STOP hostility, so
            ; tagging someone who was never going to attack buys nothing and
            ; costs a faction override in the save. It matters because a captor
            ; does not have to be an enemy: a citizen can take the player
            ; prisoner, and without this filter every shopkeeper and guard within
            ; the search radius would be swept in - then promoted to permanent
            ; allies and filling all 16 persist slots if the player has "captors
            ; stay friendly" switched on.
            ;
            ; With an enemy captor, take the whole room: their people are on
            ; their side whether or not each one currently reads as hostile.
            ; With a friendly captor, take only actual threats.
                Bool takeThem = False
                If a && a != PlayerRef && !a.IsDead() && a.GetDistance(PlayerRef) <= r \
                    && a.GetFactionRank(DAC_TruceFaction) < 0
                    seen += 1
                    If a.IsPlayerTeammate()
                        takeThem = FollowersJoin()
                    Else
                        ; THIRD PARTIES STAY OUT OF IT.
                        ;
                        ; "Hostile to the captor" is the whole test. A capture is
                        ; one side winning, not the world agreeing to stop: if the
                        ; player is a Stormcloak beaten by an Imperial, the
                        ; Imperials stand down (not hostile to their own man) and
                        ; the Stormcloaks fight on (hostile to him). Before this,
                        ; a truce froze everyone in the cell - in testing it
                        ; pacified a pack of wolves that had been fighting the
                        ; captors, which reads as the world pausing for you.
                        ;
                        ; Accepted consequence: a third party hostile to the
                        ; player keeps attacking a captive who cannot fight back.
                        ; That is deliberate and it resolves itself - the captors
                        ; win and things carry on, or they lose and the player is
                        ; loose in a fight they can run from. Captivity keeps the
                        ; player Essential, so it cannot end in death.
                        ;
                        ; Making them drop the PLAYER but keep fighting the captors
                        ; would need per-pair relationship ranks and would not hold
                        ; on an aggressive actor. Not worth it for the case it buys.
                        takeThem = (groupTruce || a.IsHostileToActor(PlayerRef)) \
                            && !(who != None && a.IsHostileToActor(who))
                    EndIf
                EndIf

                If takeThem
                    a.AddToFaction(DAC_TruceFaction)
                    StorageUtil.FormListAdd(PlayerRef, "DAC_TruceMembers", a as Form, false)
                    a.StopCombat()
                    a.StopCombatAlarm()
                    ; Every one of the six defeat mods surveyed calls this straight
                    ; after changing combat state - it makes the AI re-read the
                    ; faction change now instead of finishing its current decision.
                    a.EvaluatePackage()

                    ; Mode 2 only: they are not just neutral, they are a prisoner as
                    ; well. Recorded so the release can undo it and so a SkyrimNet
                    ; prompt can tell "standing there" apart from "held too".
                    If a.IsPlayerTeammate() && FollowerMode() == 2
                        StorageUtil.FormListAdd(PlayerRef, "DAC_CaptiveFollowers", a as Form, false)
                        StorageUtil.SetIntValue(a, "DAC_IsCaptive", 1)
                        Debug.Trace("[DAC] Follower taken captive alongside the player: " + a)
                    EndIf

                    added += 1
                EndIf
                i += 1
            EndWhile
            ti += 1
        EndWhile
        ; The count that matters. `seen` is how many candidates the walk found;
        ; `added` is how many the filter accepted. If these ever diverge sharply
        ; the filter is the suspect, not the walk - which is exactly the confusion
        ; that cost a day when only one number was logged.
        Debug.Trace("[DAC] truce walk: " + seen + " candidate(s) in radius, " + added + " taken")
    EndIf

    If added > 0
        Debug.Trace("[DAC] Truce: added " + added + " actor(s); " \
            + StorageUtil.FormListCount(PlayerRef, "DAC_TruceMembers") + " total")
    EndIf
    Return added
EndFunction

; Undo the truce. Anyone who is also in DAC_AllyFaction is deliberately LEFT in
; it - that faction is separate and permanent, which is what lets a single
; defector stay friendly while the rest of the group turns on the player again.
; calmly = this was a MERCY release, so nobody should swing the moment the truce
; faction comes off.
;
; Removing the faction only restores their ORIGINAL disposition - and if they were
; mid-fight when you were taken, that disposition is "attacking". So a captor who
; deliberately let you go would immediately try to kill you again, which reads as
; the release not having worked.
;
; It matters more with a mod like SeverActions, where most enemies are not
; aggressive by default: the natural resting state there IS neutral, and this
; simply lets them return to it instead of resuming a fight the release ended.
; StopCombat is not a relationship change - they can still be provoked again.
;
; An ESCAPE deliberately passes false. You ran; they have every reason to chase.
Int Function EndTruce(Bool calmly = false)
    If DAC_TruceFaction == None
        Return 0
    EndIf

    Int n = StorageUtil.FormListCount(PlayerRef, "DAC_TruceMembers")
    Int removed = 0
    Int i = 0
    While i < n
        Actor a = StorageUtil.FormListGet(PlayerRef, "DAC_TruceMembers", i) as Actor
        If a && a.GetFactionRank(DAC_TruceFaction) >= 0
            a.RemoveFromFaction(DAC_TruceFaction)
            If calmly && !a.IsDead()
                a.StopCombat()
                a.StopCombatAlarm()
            EndIf
            a.EvaluatePackage()
            removed += 1
        EndIf
        i += 1
    EndWhile
    StorageUtil.FormListClear(PlayerRef, "DAC_TruceMembers")

    ; Followers taken captive alongside the player stop being captive when the
    ; player does. Their truce membership was already cleared in the loop above.
    Int fc = StorageUtil.FormListCount(PlayerRef, "DAC_CaptiveFollowers")
    Int fi = 0
    While fi < fc
        Actor f = StorageUtil.FormListGet(PlayerRef, "DAC_CaptiveFollowers", fi) as Actor
        If f
            StorageUtil.SetIntValue(f, "DAC_IsCaptive", 0)
        EndIf
        fi += 1
    EndWhile
    StorageUtil.FormListClear(PlayerRef, "DAC_CaptiveFollowers")

    PlayerRef.RemoveFromFaction(DAC_TruceFaction)

    Debug.Trace("[DAC] Truce ended; released " + removed + " actor(s) of " + n \
        + "; freed " + fc + " captive follower(s)")
    Return removed
EndFunction

; =====================================================================
;  KEEPING NPCs ALIVE
; =====================================================================
; Most enemies in Skyrim are generic actors spawned from leveled lists. Their
; references are deleted when the cell resets - typically ten in-game days, or
; thirty once the dungeon is cleared. An ally you made would simply cease to
; exist, and with them everything SkyrimNet remembered about the pair of you.
;
; The fix is a quest alias, NOT a clone. PlaceActorAtMe mints a dynamic 0xFF...
; reference: a NEW SkyrimNet UUID, so every memory is lost, inventory and
; appearance are not carried over, and the copy sits in the save forever. An
; alias holds the SAME reference - same UUID, same memories, same gear - and a
; reference held by a running quest's alias is persistent and exempt from
; cell-reset cleanup. This is how follower frameworks keep arbitrary NPCs alive.
;
; Sixteen slots. Each held actor costs save space and keeps simulating, so this
; is deliberately finite rather than "persist the whole dungeon".
Int Property PERSIST_SLOTS = 16 AutoReadOnly

Quest Property DAC_PersistQuest Auto
{Holds references in aliases so generic NPCs are never cleaned up.}

ReferenceAlias Function PersistSlot(Int i)
    If DAC_PersistQuest == None
        Return None
    EndIf
    String n = "DAC_Persist"
    If i < 10
        n += "0"
    EndIf
    Return DAC_PersistQuest.GetAliasByName(n + i) as ReferenceAlias
EndFunction

; Returns True if the actor is now held (including if it already was).
; Give back the slots of allies who have died.
;
; Holding a corpse was originally deliberate - a held body survives a cell reset,
; so loot on it stays recoverable. That reasoning does not survive contact with
; the mod as it now stands: an ally who took something from you HANDS IT BACK the
; moment they change sides, so an ally is not carrying your things in the first
; place. What is left is a slot held for a body, and no reliable way to release
; it - the only lever is casting Mark Ally AT the corpse, which is impossible if
; it fell somewhere you cannot reach. The escape hatch was "Forget all allies",
; which throws away every living ally to reclaim one dead one.
;
; So this runs on the watchdog, always: dead allies are dropped, living ones
; untouched. There is deliberately no setting - holding a corpse has no upside
; left, so the only thing an off switch could buy you is the stuck slot.
Int Function FreeDeadAllySlots()
    Int n = StorageUtil.FormListCount(PlayerRef, "DAC_Allies")
    Int freed = 0
    Int i = n - 1
    ; Backwards: removing from the list as we go would shift everything after it.
    While i >= 0
        Actor a = StorageUtil.FormListGet(PlayerRef, "DAC_Allies", i) as Actor
        If a == None || a.IsDead()
            If a
                If a.GetFactionRank(DAC_AllyFaction) >= 0
                    a.RemoveFromFaction(DAC_AllyFaction)
                EndIf
                UnpersistActor(a)
                Debug.Notification(a.GetDisplayName() + " has died. Their slot is free.")
            EndIf
            StorageUtil.FormListRemove(PlayerRef, "DAC_Allies", a as Form, true)
            freed += 1
        EndIf
        i -= 1
    EndWhile
    If freed > 0
        Debug.Trace("[DAC] Freed " + freed + " ally slot(s) held by the dead")
    EndIf
    Return freed
EndFunction

Bool Function PersistActor(Actor a)
    If a == None || DAC_PersistQuest == None
        Return False
    EndIf

    Int i = 0
    Int free = -1
    While i < PERSIST_SLOTS
        ReferenceAlias ra = PersistSlot(i)
        If ra
            ObjectReference held = ra.GetReference()
            If held == (a as ObjectReference)
                Return True                 ; already held
            ElseIf held == None && free < 0
                free = i                    ; remember the first empty slot
            EndIf
        EndIf
        i += 1
    EndWhile

    If free < 0
        Debug.Trace("[DAC] No free persist slot - " + a + " may still be cleaned up")
        Debug.Notification("[DAC] No room to hold another one - forget an ally first.")
        Return False
    EndIf

    PersistSlot(free).ForceRefTo(a as ObjectReference)
    Debug.Trace("[DAC] Holding " + a + " in persist slot " + free)
    Return True
EndFunction

Function UnpersistActor(Actor a)
    If a == None || DAC_PersistQuest == None
        Return
    EndIf
    Int i = 0
    While i < PERSIST_SLOTS
        ReferenceAlias ra = PersistSlot(i)
        If ra && ra.GetReference() == (a as ObjectReference)
            ra.Clear()
            Debug.Trace("[DAC] Released persist slot " + i + " (" + a + ")")
            Return
        EndIf
        i += 1
    EndWhile
EndFunction

Int Function ClearAllPersisted()
    Int cleared = 0
    Int i = 0
    While i < PERSIST_SLOTS
        ReferenceAlias ra = PersistSlot(i)
        If ra && ra.GetReference()
            ra.Clear()
            cleared += 1
        EndIf
        i += 1
    EndWhile
    Debug.Trace("[DAC] Released " + cleared + " held reference(s)")
    Return cleared
EndFunction

Int Function PersistedCount()
    Int n = 0
    Int i = 0
    While i < PERSIST_SLOTS
        ReferenceAlias ra = PersistSlot(i)
        If ra && ra.GetReference()
            n += 1
        EndIf
        i += 1
    EndWhile
    Return n
EndFunction

; =====================================================================
;  PERSONAL ALLIES
; =====================================================================
; Separate from the truce on purpose. The truce is the captivity and ends with
; it; an ally is a person, and outlives it. Keeping them apart is what allows the
; case this was built for: talk one of your captors round, escape the rest, and
; keep that one friendly while their former group hunts you.
;
; It also matters to the AI. is_in_faction() is a boolean, so ranks within one
; faction would be invisible to SkyrimNet - two factions let a prompt tell
; "one of the people holding me" apart from "the one who changed sides".
;
; Marked by the player, not decided by the model: an NPC can narrate using an
; action it never actually fired, and this is not a thing to lose to that.
Function ToggleAllyAtCrosshair()
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf
    If DAC_AllyFaction == None
        Debug.Notification("[DAC] Ally faction missing - is the plugin loaded?")
        Return
    EndIf

    Actor a = Game.GetCurrentCrosshairRef() as Actor
    If a == None
        Debug.Notification("Look at someone first.")
        Return
    EndIf
    ToggleAlly(a)
EndFunction

; Split out of ToggleAllyAtCrosshair so the ally LIST can reach the same logic
; with an actor it was handed, instead of one the player is looking at. Aiming is
; a fine way to pick someone standing in front of you and a useless one for a
; body at the bottom of a ravine.
Function ToggleAlly(Actor a)
    If a == None || a == PlayerRef
        Return
    EndIf
    If DAC_AllyFaction == None
        Debug.Notification("[DAC] Ally faction missing - is the plugin loaded?")
        Return
    EndIf

    ; The death check guards ADDING only - a corpse cannot become a new ally.
    ; Removing a dead one is allowed, and with "Dead allies free their slot" on
    ; it happens by itself; this is the manual route for anyone who turned that
    ; off and wants to release a particular body.
    If a.IsDead() && a.GetFactionRank(DAC_AllyFaction) < 0
        Debug.Notification("They are past caring.")
        Return
    EndIf

    If a.GetFactionRank(DAC_AllyFaction) >= 0
        a.RemoveFromFaction(DAC_AllyFaction)
        a.EvaluatePackage()
        StorageUtil.FormListRemove(PlayerRef, "DAC_Allies", a as Form, true)
        ; Stop holding them: they are ordinary again and may be cleaned up
        ; normally. Holding a reference nobody cares about is pure save weight.
        UnpersistActor(a)
        If a.IsDead()
            Debug.Notification(a.GetDisplayName() + " is left to rest. Slot freed.")
        Else
            Debug.Notification(a.GetDisplayName() + " is no longer your ally.")
        EndIf
        Debug.Trace("[DAC] Ally removed: " + a)
        NarrateAllyChange(a, False)
        Return
    EndIf

    ; The player must be in it too, or the Ally-to-self relation has nothing to
    ; pair them with.
    If PlayerRef.GetFactionRank(DAC_AllyFaction) < 0
        PlayerRef.AddToFaction(DAC_AllyFaction)
    EndIf

    a.AddToFaction(DAC_AllyFaction)
    a.StopCombat()
    a.StopCombatAlarm()
    a.EvaluatePackage()
    StorageUtil.FormListAdd(PlayerRef, "DAC_Allies", a as Form, false)

    ; Hold the reference so a generic NPC is not swept away on the next cell
    ; reset. Without this an ally made in a bandit camp is gone in ten in-game
    ; days, taking everything SkyrimNet knew about them with it.
    Bool held = PersistActor(a)
    If !held
        Debug.Trace("[DAC] " + a + " is an ally but NOT held - no free slot")
    EndIf

    Debug.Notification(a.GetDisplayName() + " will stand with you.")
    GiveBackAsAlly(a)
    Debug.Trace("[DAC] Ally added: " + a + "; total " + StorageUtil.FormListCount(PlayerRef, "DAC_Allies"))
    NarrateAllyChange(a, True)
EndFunction

; Move everyone currently under truce into the permanent ally faction, and clear
; the truce. Used when a mercy release is set to keep the captors friendly.
;
; Everything ends up in ONE place - the ally list - so the Mark Ally power and
; "Forget all allies" can manage former captors exactly like anyone else. Without
; that, kept captors would be friendly forever with no way to undo it.
Int Function PromoteTruceToAllies()
    If DAC_AllyFaction == None || DAC_TruceFaction == None
        Return 0
    EndIf

    If PlayerRef.GetFactionRank(DAC_AllyFaction) < 0
        PlayerRef.AddToFaction(DAC_AllyFaction)
    EndIf

    Int n = StorageUtil.FormListCount(PlayerRef, "DAC_TruceMembers")
    Int promoted = 0
    Int i = 0
    While i < n
        Actor a = StorageUtil.FormListGet(PlayerRef, "DAC_TruceMembers", i) as Actor
        If a && !a.IsDead()
            If a.GetFactionRank(DAC_AllyFaction) < 0
                a.AddToFaction(DAC_AllyFaction)
                StorageUtil.FormListAdd(PlayerRef, "DAC_Allies", a as Form, false)
                ; Same reasoning as marking one by hand - a kept captor is no
                ; use if the game deletes them a week later. Slots run out
                ; quietly; PersistActor already says so in the log.
                PersistActor(a)
                promoted += 1
            EndIf
            a.RemoveFromFaction(DAC_TruceFaction)
            a.EvaluatePackage()
        EndIf
        i += 1
    EndWhile

    StorageUtil.FormListClear(PlayerRef, "DAC_TruceMembers")
    PlayerRef.RemoveFromFaction(DAC_TruceFaction)
    Return promoted
EndFunction

; SkyrimNet action entry point - an NPC decides to change sides.
;
; The YAML restricts this to someone currently in the truce faction while the
; player is captive, so it cannot be reached by a follower or a passer-by. The
; guards below repeat that check anyway: eligibility is evaluated against a
; snapshot, and this creates a permanent relationship, so it is worth being sure
; at the moment it actually fires.
Function AI_BecomeAlly(Actor akActor)
    Debug.Trace("[DAC] SkyrimNet action DAC_BecomeAlly fired by " + akActor)
    If akActor == None || DAC_AllyFaction == None || DAC_TruceFaction == None
        Return
    EndIf
    If akActor.GetFactionRank(DAC_TruceFaction) < 0
        Debug.Trace("[DAC] BecomeAlly refused - " + akActor + " is not one of the captors")
        Return
    EndIf
    If akActor.GetFactionRank(DAC_AllyFaction) >= 0
        Return      ; already switched
    EndIf

    If PlayerRef.GetFactionRank(DAC_AllyFaction) < 0
        PlayerRef.AddToFaction(DAC_AllyFaction)
    EndIf
    akActor.AddToFaction(DAC_AllyFaction)
    akActor.StopCombat()
    akActor.StopCombatAlarm()
    akActor.EvaluatePackage()
    StorageUtil.FormListAdd(PlayerRef, "DAC_Allies", akActor as Form, false)
    PersistActor(akActor)

    Debug.Notification(akActor.GetDisplayName() + " has turned against their own.")
    Debug.Trace("[DAC] Ally added by AI decision: " + akActor)
    NarrateAllyChange(akActor, True)
    GiveBackAsAlly(akActor)
EndFunction

; Someone who has just taken your side has no reason to keep your things. If this
; new ally is holding a haul they took from you, they hand it back.
;
; Only THEIR haul - another captor still holding your gear keeps it, which is
; right: one person changing sides says nothing about the rest.
;
; Silent when they never robbed you, which is most allies.
Function GiveBackAsAlly(Actor a)
    If a == None || !ReturnGearOnAllyOn()
        Return
    EndIf
    Int got = ReturnItemsFrom(a)
    If got > 0
        Debug.Notification(a.GetDisplayName() + " hands back what they took from you.")
        Debug.Trace("[DAC] Ally " + a + " returned " + got + " stack(s)")
        If SkyrimNetPresent()
            SkyrimNetApi.RegisterEvent("dac_ally", \
                a.GetDisplayName() + " gave " + PlayerRef.GetDisplayName() + " back the belongings taken from them.", \
                a, PlayerRef)
        EndIf
    EndIf
EndFunction

Bool Function ReturnGearOnAllyOn()
    If DAC_AllyReturnsGear == None
        Return True
    EndIf
    Return DAC_AllyReturnsGear.GetValue() as Int == 1
EndFunction

; Drop every ally at once. For the MCM, and for digging out of a bad state.
Int Function ClearAllAllies()
    If DAC_AllyFaction == None
        Return 0
    EndIf
    Int n = StorageUtil.FormListCount(PlayerRef, "DAC_Allies")
    Int cleared = 0
    Int i = 0
    While i < n
        Actor a = StorageUtil.FormListGet(PlayerRef, "DAC_Allies", i) as Actor
        If a && a.GetFactionRank(DAC_AllyFaction) >= 0
            a.RemoveFromFaction(DAC_AllyFaction)
            a.EvaluatePackage()
            cleared += 1
        EndIf
        i += 1
    EndWhile
    StorageUtil.FormListClear(PlayerRef, "DAC_Allies")
    PlayerRef.RemoveFromFaction(DAC_AllyFaction)

    ; Free every slot outright rather than one per ally - if the two lists ever
    ; drifted apart, per-ally clearing would strand references nobody can reach.
    ClearAllPersisted()
    Debug.Trace("[DAC] Cleared " + cleared + " ally/allies of " + n)
    Debug.Notification("[DAC] Forgot " + cleared + " ally/allies.")
    Return cleared
EndFunction

Function NarrateAllyChange(Actor who, Bool becameAlly)
    If !SkyrimNetPresent() || who == None
        Return
    EndIf
    String pname = PlayerRef.GetDisplayName()
    String cname = who.GetDisplayName()
    String content
    If becameAlly
        content = cname + " has thrown in with " + pname + ". Whatever side they were on before, " \
            + "they are on " + pname + "'s side now, and the people they used to answer to will not forget it."
    Else
        content = cname + " and " + pname + " are no longer allies. Whatever understanding they had is over."
    EndIf
    SkyrimNetApi.RegisterEvent("dac_ally", content, who, PlayerRef)
    Debug.Trace("[DAC] SkyrimNet: ally change registered for " + who)
EndFunction

Int Function JoinCaptorFactions(Actor who)
    StorageUtil.FormListClear(PlayerRef, "DAC_JoinedFactions")

    Faction[] theirs = who.GetFactions(-128, 127)
    If theirs == None
        Debug.Trace("[DAC] Captor reported no factions")
        Return 0
    EndIf

    Int i = 0
    Int added = 0
    While i < theirs.Length
        Faction f = theirs[i]
        ; Use GetFactionRank, NOT IsInFaction. Papyrus RemoveFromFaction only
        ; writes rank -1 into the actor's faction overrides; the entry stays and
        ; IsInFaction keeps reading it as membership. Guarding on IsInFaction
        ; therefore SKIPS re-adding on a second capture by the same group, and
        ; the rank -1 residue does not pacify anyone - so combat would not stop
        ; the second time. GetFactionRank returns -1 for both "never joined" and
        ; "removed residue", which is exactly the set we want to (re)add.
        If f && PlayerRef.GetFactionRank(f) < 0 && IsJoinable(f)
            PlayerRef.AddToFaction(f)
            StorageUtil.FormListAdd(PlayerRef, "DAC_JoinedFactions", f as Form, false)
            added += 1
        EndIf
        i += 1
    EndWhile

    Debug.Trace("[DAC] Joined " + added + " of " + theirs.Length + " captor factions")
    Return added
EndFunction

Bool Function IsJoinable(Faction f)
    If DAC_FactionBlacklist && DAC_FactionBlacklist.HasForm(f as Form)
        Return false
    EndIf

    ; Framework bookkeeping factions - joining these does nothing useful and can
    ; confuse the mods that own them.
    String n = (f as Form).GetName()
    If StringUtil.Find(n, "SexLab") != -1
        Return false
    ElseIf StringUtil.Find(n, "SOS") != -1
        Return false
    ElseIf StringUtil.Find(n, "Schlongified") != -1
        Return false
    ElseIf StringUtil.Find(n, "Dialogue Disable") != -1
        Return false
    ElseIf StringUtil.Find(n, "zbf") != -1
        Return false
    ElseIf StringUtil.Find(n, "Yam") != -1
        Return false
    ElseIf StringUtil.Find(n, "SeverActions") != -1
        Return false
    EndIf

    Return true
EndFunction

Function StripPlayer(Actor who)
    ; Record what is about to be taken, so it CAN be given back. RemoveAllItems
    ; reports nothing about what it moved, so the inventory has to be walked
    ; first - GetNumItems/GetNthForm are SKSE, which is already a hard
    ; requirement. Quest items are enumerated too but never actually taken; the
    ; restore skips anything the captor does not hold, so they cost nothing.
    ;
    ; The manifest is stored ON THE CAPTOR, not on the player, and every captor
    ; who has ever robbed you is remembered in DAC_Robbers.
    ;
    ; Storing it on the player was wrong and lost things: being captured a second
    ; time - which happens constantly while walking back to recover your gear -
    ; overwrote the first captor's manifest with a nearly empty one, because you
    ; had already been stripped. The first haul then existed in the world with
    ; nothing recording who held it.
    StorageUtil.FormListClear(who, "DAC_TakenForms")
    StorageUtil.IntListClear(who, "DAC_TakenCounts")

    Int n = PlayerRef.GetNumItems()
    Int i = 0
    While i < n
        Form f = PlayerRef.GetNthForm(i)
        If f
            Int c = PlayerRef.GetItemCount(f)
            If c > 0
                StorageUtil.FormListAdd(who, "DAC_TakenForms", f, false)
                StorageUtil.IntListAdd(who, "DAC_TakenCounts", c, false)
            EndIf
        EndIf
        i += 1
    EndWhile

    ; false = do not add twice. A captor who robs you again just overwrites their
    ; own manifest above.
    StorageUtil.FormListAdd(PlayerRef, "DAC_Robbers", who as Form, false)
    Debug.Trace("[DAC] Recorded " + StorageUtil.FormListCount(who, "DAC_TakenForms") \
        + " item stack(s) on " + who + "; " + StorageUtil.FormListCount(PlayerRef, "DAC_Robbers") + " robber(s) tracked")

    ; Quest items are deliberately kept - taking them can dead-end quests.
    PlayerRef.RemoveAllItems(who as ObjectReference, false, false)
EndFunction

; Give back exactly what was taken, from whoever is holding it. Deliberately NOT
; wired into release: losing your gear is the point of being robbed, and every
; release route is meant to leave it with the captor. This is the escape hatch
; for when that goes wrong - a captor who wandered off, died somewhere
; unreachable, or a capture that ended in a way the mod did not foresee.
;
; Driven by a global so it works from the MCM and from the console with
; `set DAC_ReturnGear to 1`, matching how everything else here is controlled.
; Hand back what ONE actor took, and forget them. Returns how many stacks moved.
Int Function ReturnItemsFrom(Actor holder)
    If holder == None
        Return 0
    EndIf
    Int n = StorageUtil.FormListCount(holder, "DAC_TakenForms")
    If n == 0
        Return 0
    EndIf

    Int returned = 0
    Int i = 0
    While i < n
        Form f = StorageUtil.FormListGet(holder, "DAC_TakenForms", i) as Form
        Int want = StorageUtil.IntListGet(holder, "DAC_TakenCounts", i)
        If f && want > 0
            Int have = holder.GetItemCount(f)
            If have > 0
                If have < want
                    want = have          ; they spent, dropped or equipped some
                EndIf
                holder.RemoveItem(f, want, true, PlayerRef)
                returned += 1
            EndIf
        EndIf
        i += 1
    EndWhile

    StorageUtil.FormListClear(holder, "DAC_TakenForms")
    StorageUtil.IntListClear(holder, "DAC_TakenCounts")
    StorageUtil.FormListRemove(PlayerRef, "DAC_Robbers", holder as Form, true)

    Debug.Trace("[DAC] Recovered " + returned + " of " + n + " stack(s) from " + holder)
    Return returned
EndFunction

; Every captor who ever robbed you, not just the most recent one. Being taken a
; second time on the way to recover your gear is the normal case, not an edge
; case, and each captor still holds their own haul.
Function ReturnTakenItems()
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf

    Int robbers = StorageUtil.FormListCount(PlayerRef, "DAC_Robbers")
    If robbers == 0
        Debug.Notification("[DAC] Nothing recorded as taken.")
        Return
    EndIf

    Int returned = 0
    Int emptied = 0
    ; Backwards: ReturnItemsFrom removes each entry from the list as it goes.
    Int i = robbers - 1
    While i >= 0
        Actor a = StorageUtil.FormListGet(PlayerRef, "DAC_Robbers", i) as Actor
        If a
            Int got = ReturnItemsFrom(a)
            returned += got
            If got > 0
                emptied += 1
            EndIf
        Else
            ; Reference is gone - cleaned up, or never resolved. Drop it.
            StorageUtil.FormListRemove(PlayerRef, "DAC_Robbers", None, true)
        EndIf
        i -= 1
    EndWhile

    Debug.Trace("[DAC] Recovered " + returned + " stack(s) from " + emptied + " of " + robbers + " robber(s)")
    Debug.Notification("[DAC] Recovered " + returned + " item stack(s) from " + emptied + " captor(s).")
EndFunction

; =====================================================================
;  RELEASE
; =====================================================================
; In-game routes:
;   - kill the captor (the watchdog frees you within CheckInterval seconds)
;   - console:  set DAC_Captured to 0
; Skyrim's console has NO command to call a Papyrus function (`cgf` is Fallout 4),
; hence the global-variable route.
Function ReleasePlayer()
    If !bCaptured
        Return
    EndIf

    ; Tell SL Kidnapped Redux we are finished, if it is installed and involved.
    ; SLKR leaves its own KidnappedStatus at 2 after an abduction and only clears
    ; it from OnUpdateGameTime, 2 + SLKR_Timeout_Global GAME-HOURS later. Until
    ; then its OnAmbushed loop rejects every new ambush - including SLKR's own
    ; force-trigger, which silently does nothing. Nothing about our release told
    ; it otherwise, so escaping a kidnapping used to lock out kidnappings for
    ; hours. Handled by DAC_OnReset in the patch's copy of SLKR's script; the
    ; event is simply unheard when the patch is not installed.
    If SLKRStage() != 0
        SendModEvent("DAC_SLKR_Reset")
        Debug.Trace("[DAC] Sent DAC_SLKR_Reset - clearing SLKR's kidnap state")
    EndIf

    UnregisterForUpdate()
    ; Borrowed captor factions always come back - they were never ours to keep.
    Int removed = RestoreFactions()

    ; The truce is a choice. Keeping it PROMOTES everyone to permanent allies
    ; rather than simply not ending it.
    ;
    ; Leaving them in the truce faction was wrong: DAC_TruceMembers would not be
    ; cleared, so the next captivity would append a second group to the same
    ; list, and ending THAT truce would strip the people from the first one -
    ; silently un-friending captors the player had deliberately kept. Promoting
    ; moves them to the ally faction, which nothing but the player ever clears,
    ; and leaves the truce list empty for the next captivity.
    If KeepFriendsOn() && !bEscaped
        Int promoted = PromoteTruceToAllies()
        Debug.Trace("[DAC] Truce kept - promoted " + promoted + " former captor(s) to allies")
        If promoted > 0
            Debug.Notification("They still consider you one of their own.")
        EndIf
    Else
        removed += EndTruce(!bEscaped)
    EndIf

    If Captor
        StorageUtil.SetIntValue(Captor, "DAC_IsCaptor", 0)
        If DAC_CaptorAbility
            Captor.RemoveSpell(DAC_CaptorAbility)
        EndIf
        If bEscaped
            ; Fled, not freed - the bindings stay on and the captor keeps the key.
            NarrateEscape(Captor)
        Else
            HandOverKey(Captor)
            NarrateRelease(Captor)
        EndIf
    EndIf
    ; Remembered before the flag is cleared, so DAC_OnRelease further down can
    ; still tell listeners which kind of ending this was.
    Bool bEscapedAtRelease = bEscaped
    bEscaped = False

    ; A physical rope survives everything above - it is not a faction, a spell or
    ; an item. Freeing someone while they are still tied to a post is not being
    ; freed. Mercy only: fleeing leaves the rope on, same as the restraints.
    If !bEscapedAtRelease
        ReleaseAnyLeash()
    EndIf

    CaptureState = 0
    CaptorName = ""

    DAC_Captured.SetValue(0)
    StorageUtil.SetIntValue(PlayerRef, "DAC_Captured", 0)
    StorageUtil.UnsetFormValue(PlayerRef, "DAC_Captor")

    Captor = None
    bCaptured = False
    bLeashWarned = False
    fCaptureTime = 0.0

    ; Paired with DAC_OnCapture. numArg is 1 when this was an ESCAPE rather than
    ; a mercy release, so a listener can treat the two differently - a leash, for
    ; instance, should come off when you are freed and stay on when you bolt.
    Float wasEscape = 0.0
    If bEscapedAtRelease
        wasEscape = 1.0
    EndIf
    SendModEvent("DAC_OnRelease", "", wasEscape)

    Debug.Trace("[DAC] RELEASED; " + removed + " actor(s) taken out of the truce")
    Debug.Notification("You are free.")
    If ShowPopups()
        Debug.MessageBox("[DAC] Released. " + removed + " actor(s) are no longer under truce.")
    EndIf

    If PollingOn()
        RegisterForSingleUpdate(CheckInterval)
    EndIf
EndFunction

; =====================================================================
;  OPTIONAL: cut a physical leash on release
; =====================================================================
; LeashFramework leashes are not factions, spells or items, so nothing else in
; ReleasePlayer touches them. Letting someone go while they are still roped to a
; post is not letting them go.
;
; NEITHER mod is required. Two gates, in this order:
;
;   1. Leash.esm absent      -> nothing to cut, return before any native call.
;   2. Our leash patch present -> IT owns the rope. Do nothing. The patch decides
;      that an ESCAPE keeps the leash on, and duplicating the work here would
;      quietly overrule that.
;
; So this only fires for a leash from LeashFramework (ours or ANY other mod's)
; on a load order that has no leash patch to handle it.
Function ReleaseAnyLeash()
    If Game.GetModByName("Leash.esm") == 255
        Return
    EndIf
    If Game.GetModByName("DefeatAndCapture_Leash.esp") != 255
        Return
    EndIf
    CutLeashNative()
EndFunction

; The native call lives alone on purpose. If Leash.esm is somehow present while
; LeashFramework.pex is not, calling into a missing script aborts the function it
; sits in - here that costs this one line and nothing else in the release.
Function CutLeashNative()
    If LeashFramework.IsLeashed(PlayerRef)
        LeashFramework.UnleashAll(PlayerRef)
        Debug.Trace("[DAC] Cut a physical leash on release (no leash patch installed to do it)")
    EndIf
EndFunction

; Remove ONLY the factions this mod added, read back from the recorded list.
; Never iterate the player's live factions here - that would strip memberships
; the player legitimately owns.
Int Function RestoreFactions()
    Int n = StorageUtil.FormListCount(PlayerRef, "DAC_JoinedFactions")
    Int i = 0
    While i < n
        Faction f = StorageUtil.FormListGet(PlayerRef, "DAC_JoinedFactions", i) as Faction
        If f
            PlayerRef.RemoveFromFaction(f)
        EndIf
        i += 1
    EndWhile
    StorageUtil.FormListClear(PlayerRef, "DAC_JoinedFactions")
    Return n
EndFunction

; Callable by other mods / SkyrimNet:
;   (Quest.GetQuest("DAC_CaptureController") as DAC_CaptureController).ReleasePlayer()
Function Release() global
    Quest q = Quest.GetQuest("DAC_CaptureController")
    If q
        (q as DAC_CaptureController).ReleasePlayer()
    Else
        Debug.Trace("[DAC] Release: controller quest not found")
    EndIf
EndFunction

; =====================================================================
;  WATCHDOG / TEST POLL
; =====================================================================
Event OnUpdate()
    ; Keep the essential flag in step with the MCM toggle.
    SyncEssential()

    If bCaptured
        ; Switched off mid-captivity. Let the player go rather than leaving them
        ; held by a mod that is no longer meant to be doing anything.
        If !ModEnabled()
            Debug.Trace("[DAC] Mod switched off while captured - releasing")
            ReleasePlayer()
            Return
        EndIf

        ; Console override: the player zeroed the global by hand.
        If DAC_Captured.GetValue() as Int == 0
            Debug.Trace("[DAC] Global cleared externally - releasing")
            DAC_Captured.SetValue(1)   ; let ReleasePlayer do the full teardown
            ReleasePlayer()
            Return
        EndIf

        If Captor == None || Captor.IsDead()
            Debug.Trace("[DAC] Captor is gone - releasing player")
            ReleasePlayer()
            Return
        EndIf

        ; Re-tag anyone who has arrived since the last tick. Borrowing the
        ; captor's factions covered latecomers for free; a per-reference truce
        ; does not, so it has to be maintained.
        ;
        ; THROTTLED. ApplyTruce does a MiscUtil.ScanCellNPCs, which is by far the
        ; most expensive thing this mod does regularly - and people do not walk
        ; into a room every five seconds. Every third tick (~15s at the default
        ; interval) catches newcomers soon enough while cutting the scan rate to a
        ; third. The watchdog checks that DO need to be prompt - captor dead,
        ; leash, release timer - still run every tick.
        ; Every tick for the first half-minute, then every third.
        ;
        ; A flat 15-second re-scan was too slow at the only time it matters. A
        ; second draugr that was not in the opening cell scan carried on
        ; attacking, and the fight is decided long before the next sweep. Once
        ; things have settled, newcomers are rare and the throttle is right.
        iTruceTick += 1
        iTruceAge += 1
        If iTruceAge <= 6 || iTruceTick >= 3
            iTruceTick = 0
            ApplyTruce(Captor)
        EndIf

        ; A companion who fought on and lost is taken as well. Every tick, not
        ; throttled with the truce re-scan: bleedout is a short window and
        ; missing it puts them back on their feet for another round.
        CaptureDownedFollowers()

        ; Optional escape routes. Each returns True if it already released us.
        If CheckReleaseTimer()
            Return
        EndIf
        If CheckLeash()
            Return
        EndIf

        RegisterForSingleUpdate(CheckInterval)
        Return
    EndIf

    ; Housekeeping while free: an ally who died stops costing a slot. Only runs
    ; outside captivity, where a tick has nothing more urgent to do.
    FreeDeadAllySlots()

    ; Optional: take over when SL Kidnapped Redux finishes with the player.
    If CheckKidnapAdoption()
        Return
    EndIf

    ; Test mode: watch for a console-forced capture.
    If PollingOn()
        If DAC_Captured.GetValue() as Int == 1
            Debug.Trace("[DAC] FORCED capture requested via console")
            Actor who = ResolveCaptor()
            If who
                BeginCapture(who)
            Else
                Debug.Trace("[DAC] Forced capture found no usable actor nearby")
                DAC_Captured.SetValue(0)
                If ShowPopups()
                    Debug.MessageBox("[DAC] Forced capture: no usable actor within range. Stand near an NPC and try again.")
                EndIf
                RegisterForSingleUpdate(CheckInterval)
            EndIf
            Return
        EndIf
    EndIf

    ; Keep polling while EITHER optional watcher wants it.
    If PollingOn() || AdoptKidnapOn()
        RegisterForSingleUpdate(CheckInterval)
    EndIf
EndEvent
