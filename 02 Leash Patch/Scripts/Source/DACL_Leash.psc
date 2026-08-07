Scriptname DACL_Leash extends Quest
{Physically leashes the player while Defeat and Capture is holding them.

The base mod's own leash module measures distance and ENDS the captivity when
the player strays. This does the opposite and more interesting thing: it stops
them leaving at all. Straying is no longer an escape route, it is a rope.

Driven entirely by DAC's DAC_OnCapture / DAC_OnRelease mod events - no polling,
and no edits to the base mod beyond those two announcements.

REQUIRES LeashFramework (Leash.esm + its DLL). That is a hard, game-version-
locked dependency, which is exactly why this is a separate patch rather than a
module inside the base mod.}

; Leash.esm.
;   000800 Leash_body        SLOT 58
;   000804 Leash_neck        slot 45
;   000806 Leash_neck_chain  slot 45
;   0002CE Leash_neck_runic  slot 45
;
; BODY IS THE DEFAULT, and that is not a style choice. All three neck collars sit
; on slot 45, which is exactly where Devious Devices puts its collar - and DD is
; the mod most likely to be restraining the player at the same moment this fires.
; The neck rope simply refused to equip, so the leash had nothing to attach to
; and never appeared. Slot 58 is free in that combination.
Int Property COLLAR_BODY  = 0x800 AutoReadOnly
Int Property COLLAR_ROPE  = 0x804 AutoReadOnly
Int Property COLLAR_CHAIN = 0x806 AutoReadOnly
Int Property COLLAR_RUNIC = 0x2CE AutoReadOnly

GlobalVariable Property DACL_Enabled Auto
GlobalVariable Property DACL_Mode Auto
{0 = leash to the captor (they drag you), 1 = anchor to the spot you were taken.}
GlobalVariable Property DACL_MaxLength Auto
GlobalVariable Property DACL_Collar Auto
GlobalVariable Property DACL_Slack Auto
{0 rope, 1 chain, 2 runic.}

Actor PlayerRef
Armor wornCollar

Event OnInit()
    Arm()
EndEvent

Function Arm()
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf
    RegisterForModEvent("DAC_OnCapture", "OnDacCapture")
    RegisterForModEvent("DAC_OnRelease", "OnDacRelease")

    ; A scene is the one thing seen to detach a live leash: it moves the actors
    ; itself, and the rope came back worn but held by nobody. BOTH names are
    ; registered - "ostim_thread_end" is what OStim Standalone fires per thread
    ; and what our own SLKR script listens on, "ostim_end" is the older one other
    ; mods still use. Handling both costs a duplicate call at worst, and the
    ; repair is idempotent.
    RegisterForModEvent("ostim_thread_end", "OnSceneEnded")
    RegisterForModEvent("ostim_end", "OnSceneEnded")
    SkyrimNetApi.RegisterDecorator("dacl_can_leash", "DACL_Leash", "dacl_can_leash")
    SkyrimNetApi.RegisterDecorator("dacl_can_take", "DACL_Leash", "dacl_can_take")
    SkyrimNetApi.RegisterDecorator("dacl_can_anchor", "DACL_Leash", "dacl_can_anchor")
    SkyrimNetApi.RegisterDecorator("dacl_can_cut", "DACL_Leash", "dacl_can_cut")
    Debug.Trace("[DACL] Leash patch armed")
EndFunction

; ---------------------------------------------------------------------------
;  SkyrimNet: NPCs doing something with the leash, not just seeing it
; ---------------------------------------------------------------------------
; The usual worry about AI actions is mild here. Every one of these leaves the
; leash in a valid state, and a model that narrates taking the rope without
; firing the action simply leaves it where it was - nothing gets stuck, nothing
; needs undoing.

; Putting a leash ON someone who has none. The other three all assume a rope
; already exists, which left the obvious act missing: a captor deciding to collar
; the prisoner in the first place.
;
; Gated on the player actually being a captive of THIS person's group, or there
; would be nothing stopping a shopkeeper collaring you across a counter. That
; leans on Defeat and Capture's truce faction, which is fair - this is its patch.
; The master switch, readable from the GLOBAL decorator functions.
;
; Enabled() below reads the same global through the script property, but these
; four decorators are `global` - no Self, no properties - so they have to fetch
; it by FormID the way the cross-plugin lookups here already do.
;
; Every one of them consults this, which is what makes DACL_Enabled a real master
; switch rather than only an "apply on capture" toggle: with it off SkyrimNet is
; told "no" for putting, taking, anchoring and cutting, so an NPC is never even
; offered the choice. That is the point - the setting exists to stop a leash
; appearing at a moment the player did not want one, and an AI-applied leash is
; exactly that moment.
Bool Function LeashSystemOn() global
    GlobalVariable g = Game.GetFormFromFile(0x000800, "DefeatAndCapture_Leash.esp") as GlobalVariable
    Return g == None || g.GetValue() as Int == 1
EndFunction

String Function dacl_can_leash(Actor akActor) global
    If !LeashSystemOn()
        Return "no"
    EndIf
    Actor pl = Game.GetPlayer()
    If akActor == None || akActor == pl
        Return "no"
    EndIf
    If LeashFramework.IsLeashed(pl)
        Return "no"            ; already wearing one
    EndIf
    GlobalVariable cap = Game.GetFormFromFile(0x000800, "DefeatAndCapture.esp") as GlobalVariable
    If cap == None || cap.GetValue() as Int != 1
        Return "no"            ; not a prisoner, so nobody gets to do this
    EndIf
    Faction truce = Game.GetFormFromFile(0x00084D, "DefeatAndCapture.esp") as Faction
    If truce == None || akActor.GetFactionRank(truce) < 0
        Return "no"            ; not one of the people holding them
    EndIf
    Return "yes"
EndFunction

Function AI_PutLeash(Actor akActor)
    Debug.Trace("[DACL] DACL_PutLeash fired by " + akActor)
    If akActor == None || dacl_can_leash(akActor) != "yes"
        Return
    EndIf
    If ApplyLeashTo(akActor)
        Debug.Notification(akActor.GetDisplayName() + " puts a leash on you.")
    EndIf
EndFunction

; Anyone can pick up a rope the player is already wearing, as long as they are
; not the one holding it. Covers taking it from an anchor AND taking it off
; another NPC.
String Function dacl_can_take(Actor akActor) global
    If !LeashSystemOn()
        Return "no"
    EndIf
    If akActor == None || akActor == Game.GetPlayer()
        Return "no"
    EndIf
    If !LeashFramework.IsLeashed(Game.GetPlayer())
        Return "no"
    EndIf
    If LeashFramework.GetLeashHolder(Game.GetPlayer()) == akActor
        Return "no"            ; already theirs
    EndIf
    Return "yes"
EndFunction

; Only whoever is holding it can tie it off - you cannot anchor a rope that is
; not in your hand.
String Function dacl_can_anchor(Actor akActor) global
    If !LeashSystemOn()
        Return "no"
    EndIf
    If akActor == None || !LeashFramework.IsLeashed(Game.GetPlayer())
        Return "no"
    EndIf
    If LeashFramework.GetLeashHolder(Game.GetPlayer()) != akActor
        Return "no"
    EndIf
    Return "yes"
EndFunction

; Freeing the player is open to anyone who physically COULD, rather than to a
; whitelist of the holder plus allies.
;
; The old rule refused everyone else "so a passing stranger cannot undo a
; captivity" - which was guarding something it never guarded. Cutting the leash
; does not end a Defeat and Capture captivity at all: the rope comes off, the
; base mod's distance leash resumes, and the player is still a prisoner. Asking a
; passing adventurer for help is a perfectly good thing to be able to do, and
; with no self-directed escape from the rope it is one of very few ways out.
;
; So the question is only who CANNOT do it:
;   - the player (this is an NPC action)
;   - anyone on a rope themselves
;   - a fellow prisoner taken alongside the player, who is in no position to help
;
; A captor can still do it, which is simply mercy, and is the same decision as
; letting the player go.
String Function dacl_can_cut(Actor akActor) global
    ; Cutting is gated too, even though it only ever REMOVES a rope. With the
    ; system switched off the clear-leashes button below is the way out, and
    ; leaving one action live while the other three are dead would be a confusing
    ; half-off state.
    If !LeashSystemOn()
        Return "no"
    EndIf
    Actor pl = Game.GetPlayer()
    If akActor == None || akActor == pl || !LeashFramework.IsLeashed(pl)
        Return "no"
    EndIf
    If LeashFramework.IsLeashed(akActor)
        Return "no"            ; on a rope themselves
    EndIf
    If StorageUtil.FormListFind(pl, "DAC_CaptiveFollowers", akActor as Form) >= 0
        Return "no"            ; a prisoner too - DAC publishes who was taken along
    EndIf
    Return "yes"
EndFunction

Function AI_TakeLeash(Actor akActor)
    Debug.Trace("[DACL] DACL_TakeLeash fired by " + akActor)
    If akActor == None || dacl_can_take(akActor) != "yes"
        Return
    EndIf
    TakeLeash(akActor)
EndFunction

Function AI_AnchorLeash(Actor akActor)
    Debug.Trace("[DACL] DACL_AnchorLeash fired by " + akActor)
    If akActor == None || dacl_can_anchor(akActor) != "yes"
        Return
    EndIf
    AnchorHere()
EndFunction

Function AI_CutLeash(Actor akActor)
    Debug.Trace("[DACL] DACL_CutLeash fired by " + akActor)
    If akActor == None || dacl_can_cut(akActor) != "yes"
        Return
    EndIf
    Unleash()
    Debug.Notification(akActor.GetDisplayName() + " frees you from the leash.")
EndFunction

Bool Function Enabled()
    Return DACL_Enabled == None || DACL_Enabled.GetValue() as Int == 1
EndFunction

Function RefreshActiveLeash()
{Push a changed length or slack onto a leash that is ALREADY attached.

 ApplyLeash takes min and max once, at attach time, so without this the MCM only
 affected the NEXT captivity - you could move the sliders while leashed, see
 nothing happen, and reasonably conclude the settings did not work.

 Both ends are updated. Max is the distance you are stopped at; min is where the
 pull stops, so slack is the one you actually feel while being dragged.

 Applied to the player and to every captive follower on a rope.}
    If !LeashFramework.IsLeashed(PlayerRef)
        Return
    EndIf
    Float mx = MaxLength()
    Float mn = MinLength()
    LeashFramework.SetMaxLeashLength(PlayerRef, mx)
    LeashFramework.SetMinLeashLength(PlayerRef, mn)

    Int n = StorageUtil.FormListCount(PlayerRef, "DACL_LeashedFollowers")
    Int i = 0
    While i < n
        Actor f = StorageUtil.FormListGet(PlayerRef, "DACL_LeashedFollowers", i) as Actor
        If f && LeashFramework.IsLeashed(f)
            LeashFramework.SetMaxLeashLength(f, mx)
            LeashFramework.SetMinLeashLength(f, mn)
        EndIf
        i += 1
    EndWhile
    Debug.Trace("[DACL] Active leash updated live: max " + mx + ", pull stops at " + mn)

    ReattachIfNeeded()
EndFunction

Function ReattachIfNeeded()
{Make the rope match the "Attached to" setting, and repair one that came loose.

 Two jobs, same test:

 1. MANUAL RE-ANCHOR. Switch "Attached to" in the MCM and the live rope moves -
    which is also the only way to exercise the anchored mode without waiting for
    an AI to choose dacl_anchorleash. Set it to "The spot you were taken", close
    the menu, and walk: if the rope holds you to the floor rather than to a
    person, anchoring works.

 2. SELF-HEAL. Reported after an OStim scene: the leash was still worn but
    "hanging down, not attached to anything". A holderless leash in captor mode
    is not a state we ever ask for, and it also means nobody is in lf_leasher -
    which is exactly why the bandits afterwards had no idea they were holding it.
    Re-attaching restores both the rope and the AI's knowledge of it.}
    If !LeashFramework.IsLeashed(PlayerRef)
        Return
    EndIf
    Bool wantAnchor = DACL_Mode && DACL_Mode.GetValue() as Int == 1
    Actor holder = LeashFramework.GetLeashHolder(PlayerRef)

    If wantAnchor
        If holder
            AnchorHere()
            Debug.Trace("[DACL] Re-anchored to this spot (setting says anchored, a hand was holding it)")
        EndIf
        Return
    EndIf

    If holder == None
        Actor captor = StorageUtil.GetFormValue(PlayerRef, "DAC_Captor") as Actor
        If captor && !captor.IsDead()
            TakeLeash(captor)
            Debug.Trace("[DACL] Leash had no holder - re-attached to " + captor)
        Else
            Debug.Trace("[DACL] Leash has no holder and no captor to give it to - left anchored")
        EndIf
    EndIf
EndFunction

Float Function MaxLength()
    If DACL_MaxLength == None
        Return 400.0
    EndIf
    Return DACL_MaxLength.GetValue()
EndFunction

; The distance at which pulling STOPS. This was 0, which is why the player was
; dragged all the way into their captor and walked on the spot against them: with
; no minimum, the leash keeps hauling until the gap is nothing.
;
; At 60% of the maximum there is real slack - you can circle, back off and stand
; where you like inside that radius, and the rope only takes over near the end.
Float Function MinLength()
    Float pct = 60.0
    If DACL_Slack
        pct = DACL_Slack.GetValue()
    EndIf
    ; Clamped: at 100 the rope never pulls at all, at 0 it drags you into your
    ; captor - which was the original bug. Neither is a setting worth allowing.
    If pct < 10.0
        pct = 10.0
    ElseIf pct > 95.0
        pct = 95.0
    EndIf
    Return MaxLength() * (pct / 100.0)
EndFunction

Armor Function CollarItem()
    Int id = COLLAR_BODY            ; 0 = body rope, slot 58, safe alongside DD
    If DACL_Collar
        Int pick = DACL_Collar.GetValue() as Int
        If pick == 1
            id = COLLAR_ROPE
        ElseIf pick == 2
            id = COLLAR_CHAIN
        ElseIf pick == 3
            id = COLLAR_RUNIC
        EndIf
    EndIf
    Return Game.GetFormFromFile(id, "Leash.esm") as Armor
EndFunction

; Did the collar actually go on? EquipItem is silent when the slot is already
; taken, which is how the first version failed: the item was in the inventory,
; nothing was worn, and the leash had no bones to attach to.
Bool Function CollarIsWorn(Armor a)
    If a == None
        Return False
    EndIf
    Return PlayerRef.IsEquipped(a)
EndFunction

Event OnDacCapture(String eventName, String strArg, Float numArg, Form sender)
    If !Enabled()
        Return
    EndIf
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf

    Armor collar = CollarItem()
    If collar == None
        Debug.Trace("[DACL] LeashFramework not found - is Leash.esm enabled?")
        Return
    EndIf

    ; The leash attaches to bones on the collar mesh, so it has to be worn before
    ; the leash is applied - there is nothing to attach to otherwise.
    PlayerRef.AddItem(collar, 1, true)
    PlayerRef.EquipItem(collar, true, true)
    wornCollar = collar
    Utility.Wait(0.5)          ; let the 3D attach before asking for its bones

    ; If the chosen collar could not go on - almost always a slot fight with
    ; Devious Devices - fall back to the body rope on slot 58 rather than
    ; applying a leash to nothing and leaving an invisible mess behind.
    If !CollarIsWorn(collar)
        Debug.Trace("[DACL] Collar " + collar + " would not equip (slot taken) - trying the body rope")
        PlayerRef.RemoveItem(collar, 1, true)
        collar = Game.GetFormFromFile(COLLAR_BODY, "Leash.esm") as Armor
        If collar
            PlayerRef.AddItem(collar, 1, true)
            PlayerRef.EquipItem(collar, true, true)
            wornCollar = collar
            Utility.Wait(0.5)
        EndIf
        If !CollarIsWorn(collar)
            Debug.Trace("[DACL] No collar could be equipped - giving up on the leash")
            Debug.Notification("[DACL] Nowhere to attach a leash - a collar slot is occupied.")
            Unleash()
            Return
        EndIf
    EndIf

    Actor captor = StorageUtil.GetFormValue(PlayerRef, "DAC_Captor") as Actor
    Bool ok = False

    If DACL_Mode && DACL_Mode.GetValue() as Int == 1
        ; Anchored to the spot. Holderless, so the player is tied to where they
        ; were taken rather than to a person - the captor can walk off and the
        ; rope still holds.
        ok = LeashFramework.ApplyLeashAtPosition(PlayerRef, PlayerRef.GetParentCell(), \
            PlayerRef.GetPositionX(), PlayerRef.GetPositionY(), PlayerRef.GetPositionZ(), \
            "NPC", "Leash1_", MinLength(), MaxLength(), true)
        Debug.Trace("[DACL] Anchored leash applied: " + ok)
    ElseIf captor
        ok = LeashFramework.ApplyLeash(captor, PlayerRef, "NPC", "Leash1_", MinLength(), MaxLength(), true)
        Debug.Trace("[DACL] Leash to captor " + captor + " applied: " + ok)
    EndIf

    If ok
        Debug.Notification("You are leashed.")
        LeashCaptiveFollowers(captor)
    Else
        ; Do not leave a collar on for a leash that never attached.
        Debug.Trace("[DACL] Leash refused - removing the collar again")
        Unleash()
    EndIf
EndEvent

; numArg 1 = the player escaped rather than being released.
Event OnDacRelease(String eventName, String strArg, Float numArg, Form sender)
    If numArg == 1.0 && KeepOnEscape()
        ; Fled, not freed. The rope stays on and the anchor with it - the same
        ; reasoning the base mod uses for restraints and keys.
        Debug.Trace("[DACL] Escaped - leash left in place")
        Debug.Notification("You are still leashed.")
        Return
    EndIf
    Unleash()
EndEvent

Bool Function KeepOnEscape()
    Return True
EndFunction

; An adult scene moves the actors about and can leave the rope worn but held by
; nobody - reported as "after the scene it was just hanging down from the player".
;
; Only fires when the player is ALREADY leashed, so a scene with nothing to do
; with a captivity costs one faction check and returns.
;
; The wait matters: OStim repositions actors as it tears the scene down, and
; judging the leash mid-teardown would either re-attach against a captor who is
; still being moved, or read a holder that is about to vanish. Waiting lets the
; scene finish being over before we decide anything is wrong with it.
Event OnSceneEnded(String eventName, String strArg, Float numArg, Form sender)
    If !LeashFramework.IsLeashed(PlayerRef)
        Return
    EndIf
    Utility.Wait(2.0)
    If !LeashFramework.IsLeashed(PlayerRef)
        Return                  ; released or cut during the wait
    EndIf
    If LeashFramework.GetLeashHolder(PlayerRef) == None
        Debug.Trace("[DACL] Scene ended and the leash had lost its holder - repairing")
    EndIf
    ReattachIfNeeded()
EndEvent

; A companion taken prisoner alongside the player gets a rope of their own.
;
; The base mod publishes them on the player as StorageUtil form list
; "DAC_CaptiveFollowers", filled only when the follower mode is "Captured with
; you" - so this is silent in the other two modes with no extra setting needed.
;
; They are leashed to the same captor rather than to the player: they are a
; prisoner, not luggage.
Function LeashCaptiveFollowers(Actor captor)
    If captor == None || PlayerRef == None
        Return
    EndIf
    Int n = StorageUtil.FormListCount(PlayerRef, "DAC_CaptiveFollowers")
    Int i = 0
    Int done = 0
    While i < n
        Actor f = StorageUtil.FormListGet(PlayerRef, "DAC_CaptiveFollowers", i) as Actor
        If f && !f.IsDead()
            Armor c = Game.GetFormFromFile(COLLAR_BODY, "Leash.esm") as Armor
            If c
                f.AddItem(c, 1, true)
                f.EquipItem(c, true, true)
                Utility.Wait(0.3)
                If LeashFramework.ApplyLeash(captor, f, "NPC", "Leash1_", MinLength(), MaxLength(), true)
                    done += 1
                    ; Remember them OURSELVES - see UnleashFollowers for why we
                    ; cannot rely on the base mod's list still existing.
                    StorageUtil.FormListAdd(PlayerRef, "DACL_LeashedFollowers", f as Form, false)
                Else
                    f.RemoveItem(c, 1, true)
                EndIf
            EndIf
        EndIf
        i += 1
    EndWhile
    If done > 0
        Debug.Trace("[DACL] Leashed " + done + " captive follower(s) to " + captor)
        Debug.Notification(done + " of your people are leashed too.")
    EndIf
EndFunction

Function UnleashFollowers()
{Free every follower WE leashed.

 This used to read DAC's own DAC_CaptiveFollowers list, and that quietly did
 nothing. In ReleasePlayer, EndTruce() CLEARS that list about forty lines before
 DAC_OnRelease is sent - so by the time this handler runs the list is empty, the
 loop body never executes, and a captive follower stays roped to a captor who has
 already let the player go. Reported as "ended captivity from the MCM, follower
 stayed captured and leashed".

 Keeping our own list removes the dependency on another mod's cleanup ORDER,
 which is not something its author owes us and could change again. DAC's list is
 still consulted as a fallback for a leash applied before this existed.}
    If PlayerRef == None
        Return
    EndIf
    Armor c = Game.GetFormFromFile(COLLAR_BODY, "Leash.esm") as Armor
    Int freed = 0

    Int n = StorageUtil.FormListCount(PlayerRef, "DACL_LeashedFollowers")
    Int i = 0
    While i < n
        Actor f = StorageUtil.FormListGet(PlayerRef, "DACL_LeashedFollowers", i) as Actor
        If f
            LeashFramework.UnleashAll(f)
            If c
                f.UnequipItem(c, true, true)
                f.RemoveItem(c, 1, true)
            EndIf
            freed += 1
        EndIf
        i += 1
    EndWhile
    StorageUtil.FormListClear(PlayerRef, "DACL_LeashedFollowers")

    ; Fallback: anything DAC still lists that we somehow missed.
    n = StorageUtil.FormListCount(PlayerRef, "DAC_CaptiveFollowers")
    i = 0
    While i < n
        Actor f = StorageUtil.FormListGet(PlayerRef, "DAC_CaptiveFollowers", i) as Actor
        If f && LeashFramework.IsLeashed(f)
            LeashFramework.UnleashAll(f)
            If c
                f.UnequipItem(c, true, true)
                f.RemoveItem(c, 1, true)
            EndIf
            freed += 1
        EndIf
        i += 1
    EndWhile
    If freed > 0
        Debug.Trace("[DACL] Unleashed " + freed + " captive follower(s)")
    EndIf
EndFunction

; Collar the player and attach a leash to a given holder. Shared by the capture
; hook and the NPC action, so both get the same fallback behaviour and neither
; can leave a collar on for a leash that never attached.
Bool Function ApplyLeashTo(Actor holder)
    If holder == None || PlayerRef == None
        Return False
    EndIf
    Armor collar = CollarItem()
    If collar == None
        Return False
    EndIf
    PlayerRef.AddItem(collar, 1, true)
    PlayerRef.EquipItem(collar, true, true)
    wornCollar = collar
    Utility.Wait(0.5)

    If !CollarIsWorn(collar)
        PlayerRef.RemoveItem(collar, 1, true)
        collar = Game.GetFormFromFile(COLLAR_BODY, "Leash.esm") as Armor
        If collar
            PlayerRef.AddItem(collar, 1, true)
            PlayerRef.EquipItem(collar, true, true)
            wornCollar = collar
            Utility.Wait(0.5)
        EndIf
        If !CollarIsWorn(collar)
            Unleash()
            Return False
        EndIf
    EndIf

    If LeashFramework.ApplyLeash(holder, PlayerRef, "NPC", "Leash1_", MinLength(), MaxLength(), true)
        Return True
    EndIf
    Unleash()
    Return False
EndFunction

Function Unleash()
    UnleashFollowers()
    If PlayerRef == None
        PlayerRef = Game.GetPlayer()
    EndIf
    LeashFramework.UnleashAll(PlayerRef)
    If wornCollar
        PlayerRef.UnequipItem(wornCollar, true, true)
        PlayerRef.RemoveItem(wornCollar, 1, true)
        wornCollar = None
    EndIf
    Debug.Trace("[DACL] Unleashed")
EndFunction

; --- For later: swapping the leash while it is on --------------------------
; LeashFramework allows this at any time - DisconnectLeash then a fresh Apply -
; so an NPC tying the player to a post, walking away, and later taking the rope
; back is entirely possible. Both halves are exposed here so an action or a
; power can drive them.
Function AnchorHere()
    LeashFramework.DisconnectLeash(LeashFramework.GetLeashHolder(PlayerRef), PlayerRef)
    LeashFramework.ApplyLeashAtPosition(PlayerRef, PlayerRef.GetParentCell(), \
        PlayerRef.GetPositionX(), PlayerRef.GetPositionY(), PlayerRef.GetPositionZ(), \
        "NPC", "Leash1_", MinLength(), MaxLength(), true)
    Debug.Notification("You are tied off here.")
EndFunction

Function TakeLeash(Actor who)
    If who == None
        Return
    EndIf
    LeashFramework.DisconnectLeash(None, PlayerRef)
    LeashFramework.ApplyLeash(who, PlayerRef, "NPC", "Leash1_", MinLength(), MaxLength(), true)
    Debug.Notification(who.GetDisplayName() + " takes your leash.")
EndFunction
