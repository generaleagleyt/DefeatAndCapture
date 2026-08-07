Scriptname DASN_Context extends Quest
{Tells SkyrimNet what is happening in Dark Arena's pit.

READ-ONLY. This mod edits nothing of Dark Arena's - it reads its quest aliases
and stage and exposes them as SkyrimNet decorators. Dark Arena works exactly the
same with this installed or not, and without Dark Arena the decorators simply
report nothing.

Everything is resolved by EditorID at runtime (Quest.GetQuest), so there is no
master, no hard dependency, and no FormID to go stale when Dark Arena updates.}

; Verified against Dark Arena's own scripts:
;   stage 20 - the fight is under way (aDA_Job_ArenaPlayerLooseScript watches it)
;   stage 40 - the player has lost (that script sets it on bleedout / low health)
;   Fragment_5 clears the Pitgirl alias and completes the quest
Int Property STAGE_FIGHTING = 20 AutoReadOnly
Int Property STAGE_PLAYER_LOST = 40 AutoReadOnly

Event OnInit()
    Register()
EndEvent

; A ReferenceAlias on this quest forwards OnPlayerLoadGame, but the quest script's
; OnInit fires once per save ever - so registration has to happen on every load or
; a script update would silently stop registering.
Function Register()
    SkyrimNetApi.RegisterDecorator("da_arena_stage", "DASN_Context", "da_arena_stage")
    SkyrimNetApi.RegisterDecorator("da_arena_role", "DASN_Context", "da_arena_role")
    SkyrimNetApi.RegisterDecorator("da_can_serve", "DASN_Context", "da_can_serve")
    Debug.Trace("[DASN] Dark Arena decorators registered")
EndFunction

; ---------------------------------------------------------------------------
;  THE SERVICE JOB
; ---------------------------------------------------------------------------
; Dark Arena's "serve clients" job normally works through its own dialogue: ask
; an NPC, they agree, GetClient() assigns them and starts the radiant quest.
;
; This lets an NPC agree through SkyrimNet instead - a real conversation rather
; than a menu. It hooks ONE step, the agreement, and nothing else: following,
; the bed, the scene, the payment and the counter all stay exactly as Dark Arena
; wrote them. FinishJob() already calls EvaluateWhoreJob(1) when the scene ends,
; so progress is counted by the mod itself and cannot be double-counted here.
;
; Deliberately ADDITIVE. Dark Arena's own dialogue is untouched, so if the model
; narrates agreeing without actually firing the action - which it does - the
; player just asks the normal way and nothing is stuck.

Quest Function ServiceJob() global
    ; Which of the two jobs is live. FinishJob() in Dark Arena tests stage 10 on
    ; each, so that is the condition being matched here.
    Quest q = Quest.GetQuest("aDA_Job_Whore")
    If q && q.IsRunning() && q.GetStage() == 10
        Return q
    EndIf
    q = Quest.GetQuest("aDA_SlaveJob_Whore")
    If q && q.IsRunning() && q.GetStage() == 10
        Return q
    EndIf
    Return None
EndFunction

; "yes" only when this actor could actually be taken on as a client right now.
;
; The radiant quest holds ONE client at a time and GetClient() resets it, so a
; second acceptance while a client is already assigned would silently discard the
; first - the player would be walking one NPC to a bed while the quest tracked
; another. Hence the not-running check.
String Function da_can_serve(Actor akActor) global
    If akActor == None || akActor == Game.GetPlayer()
        Return "no"
    EndIf
    If ServiceJob() == None
        Return "no"
    EndIf
    Quest radiant = Quest.GetQuest("aDA_Radiant_Whore")
    If radiant && radiant.IsRunning()
        Return "no"            ; a client is already assigned
    EndIf
    If akActor.IsDead() || akActor.IsInFaction(Game.GetFormFromFile(0x000DB1, "Skyrim.esm") as Faction)
        Return "no"            ; not the player's own people
    EndIf
    Return "yes"
EndFunction

; SkyrimNet action entry point - an NPC accepts the player's offer.
;
; This takes the FREE-FORM path rather than calling Dark Arena's GetClient().
;
; GetClient() starts the radiant quest, which then runs its own script: a follow
; package on the client, a walk to a specific bed, and dialogue at each step. That
; is a fine flow for its own menu dialogue, but it fights everything about a
; SkyrimNet playthrough - the point of talking someone round is that the scene
; happens where the conversation went, not that an NPC is handed a waypoint.
;
; So: remember who agreed, watch for a scene between them and the player, and
; credit the job when it ends. EvaluateWhoreJob(1) is the same function Dark
; Arena's own FinishJob() calls, so the counter, the notification and the
; job-complete stage at five clients are all its own logic, untouched.
Actor pendingClient
Bool sceneSeen = False
Int watchTicks = 0

Function AI_AcceptClient(Actor akActor)
    Debug.Trace("[DASN] DarkArena_AcceptService fired by " + akActor)
    If akActor == None || da_can_serve(akActor) != "yes"
        Debug.Trace("[DASN] Refused - not a valid client right now")
        Return
    EndIf

    pendingClient = akActor
    sceneSeen = False
    watchTicks = 0
    Debug.Notification(akActor.GetDisplayName() + " agrees. Take them somewhere.")
    Debug.Trace("[DASN] Client accepted: " + akActor + " - watching for a scene")
    RegisterForSingleUpdate(4.0)
EndFunction

; Watches for a scene involving BOTH the player and the client, then credits the
; job once it ends.
;
; Polling rather than OStim's thread events on purpose: the end event carries
; JSON metadata, not a participant list, and there is no supported way to ask
; which thread an actor is in. IsInOstim on two known actors answers the only
; question that matters, and this poll runs solely while a client is pending -
; a short, player-created window, not a background loop.
Event OnUpdate()
    If pendingClient == None
        Return
    EndIf

    watchTicks += 1
    ; ~10 minutes. If nothing has happened by then the player moved on, and a
    ; pending client left forever would block the next acceptance.
    If watchTicks > 150
        Debug.Trace("[DASN] Client " + pendingClient + " timed out, forgetting them")
        pendingClient = None
        Return
    EndIf

    Bool clientBusy = OActor.IsInOstim(pendingClient)
    If !sceneSeen
        If clientBusy && OActor.IsInOstim(Game.GetPlayer())
            sceneSeen = True
            Debug.Trace("[DASN] Scene with the client has started")
        EndIf
    ElseIf !clientBusy
        CreditService()
        Return
    EndIf

    RegisterForSingleUpdate(4.0)
EndEvent

Function CreditService()
    Actor who = pendingClient
    pendingClient = None
    sceneSeen = False

    Quest job = ServiceJob()
    If job == None
        Debug.Trace("[DASN] Scene finished but the job is no longer running - nothing credited")
        Return
    EndIf

    If job == Quest.GetQuest("aDA_Job_Whore")
        (job as aDA_Job_WhoreScript).EvaluateWhoreJob(1)
    Else
        (job as aDA_SlaveJob_WhoreScript).EvaluateWhoreJob(1)
    EndIf

    Debug.Trace("[DASN] Credited one client (" + who + ")")
    Debug.Notification("Client satisfied.")
EndFunction

; ---------------------------------------------------------------------------
; Decorators. Both are Global and take an Actor, which is how SkyrimNet calls
; them from a template with a UUID.
; ---------------------------------------------------------------------------

Quest Function ArenaQuest() global
    Return Quest.GetQuest("aDA_Job_Arena")
EndFunction

Actor Function AliasActor(Quest q, String name) global
    If q == None
        Return None
    EndIf
    ReferenceAlias ra = q.GetAliasByName(name) as ReferenceAlias
    If ra == None
        Return None
    EndIf
    Return ra.GetReference() as Actor
EndFunction

; "" when no pit fight is running - which is almost always, so the prompt can
; bail on one cheap check.
String Function da_arena_stage(Actor akActor) global
    Quest q = ArenaQuest()
    If q == None || !q.IsRunning()
        Return ""
    EndIf
    Int s = q.GetStage()
    If s == 20
        Return "fighting"
    ElseIf s >= 40
        Return "lost"
    ElseIf s > 20
        Return "over"
    EndIf
    Return "arranged"
EndFunction

; Who is this actor, relative to the fight?
;
; Read from the ALIAS, not from a fixed NPC - pit fights are repeatable and the
; opponent changes every time. Whoever is in the Pitgirl alias right now is the
; opponent right now.
String Function da_arena_role(Actor akActor) global
    If akActor == None
        Return ""
    EndIf
    Quest q = ArenaQuest()
    If q == None || !q.IsRunning()
        Return ""
    EndIf

    If akActor == AliasActor(q, "Pitgirl")
        Return "opponent"
    EndIf
    If akActor == AliasActor(q, "Lisskit") || akActor == AliasActor(q, "Uvelori")
        Return "staff"
    EndIf
    Return "crowd"
EndFunction
