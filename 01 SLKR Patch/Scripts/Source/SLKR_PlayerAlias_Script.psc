Scriptname SLKR_PlayerAlias_Script extends ReferenceAlias  

import StorageUtil

int CurrentVersion

Actor property PlayerRef auto
Actor[] Rapists
Actor[] CreatureRapists
Actor[] Victims
Actor[] AmbushActors
Actor[] FakeAmbushActors

Quest property SLKR_FindFriendlies_Quest auto
Quest property SLKR_Approach_Quest auto
Quest property SLKR_Revenge_Quest auto
Quest property SLKR_FindFollowers_Quest auto
Quest property SLKR_FindRapists_Quest auto
Quest property SLKR_Rescue_Quest auto
Quest[] property FindKidnappersQuest auto

GlobalVariable Property GameHour auto
GlobalVariable Property SLKR_BeastialityKidnapper_Global auto
GlobalVariable Property SLKR_BestialityChance_Global auto
GlobalVariable Property SLKR_SexHappening_Global auto
GlobalVariable Property SLKR_ForceGreeted_Global auto
GlobalVariable Property SLKR_Abandoned_Global auto
GlobalVariable property SLKR_Stage_Global Auto
GlobalVariable property SLKR_Timeout_Global auto
GlobalVariable property SLKR_TimeoutFailed_Global auto
GlobalVariable property SLKR_Modon_Global auto
GlobalVariable property SLKR_VictimGender_Global Auto
GlobalVariable property SLKR_Threesome_Global auto
GlobalVariable property SLKR_RescuerChance_Global auto
GlobalVariable property SLKR_MNC_Global auto
GlobalVariable property SLKR_WalledCities auto
GlobalVariable property SLKR_NonWalledCities auto
GlobalVariable property SLKR_Towns auto
GlobalVariable property SLKR_Base auto
GlobalVariable property SLKR_Night auto
GlobalVariable property SLKR_PerFriendly auto
GlobalVariable property SLKR_AvoidDialogue_Global auto
GlobalVariable property SLKR_AvoidCombat_Global auto
GlobalVariable property SLKR_AvoidSex_Global auto
GlobalVariable property SLKR_AvoidScene_Global auto
GlobalVariable property SLKR_AvoidSwimming_Global auto
GlobalVariable property SLKR_AvoidWerewolf_Global auto
GlobalVariable property SLKR_AvoidRevenge_Global auto
GlobalVariable property SLKR_AvoidRescue_Global auto
GlobalVariable property SLKR_AvoidNaked_Global auto
GlobalVariable property SLKR_MultiStamina_Global auto
GlobalVariable property SLKR_MultiMagicka_Global auto
GlobalVariable property SLKR_Slavery_Global auto
GlobalVariable property SLKR_DDOn_Global auto
GlobalVariable property SLKR_NightLater_Global auto
GlobalVariable property SLKR_NightEarlier_Global auto
GlobalVariable[] property SLKR_Chances auto
GlobalVariable property SLKR_SecAvoidHit auto
GlobalVariable property SLKR_AggThreesome auto


osexintegrationmain property SexLab auto

ReferenceAlias property Approacher auto
ReferenceAlias property VictimApproached auto
ReferenceAlias property VictimPerversed auto
ReferenceAlias property Rescuer auto
ReferenceAlias property Origin auto
ReferenceAlias[] property RapistsRA auto
ReferenceAlias[] property VictimsRA auto
ReferenceAlias[] property SLKR_Followers auto
ReferenceAlias[] property Nearby auto

Message property SLKR_Ambushed_Message auto
Message property SLKR_Dodged_Message auto
Message property SLKR_Kidnapped_Message auto
Message property SLKR_Exhaustion_Message auto

ObjectReference[] property AbandonedHouses auto

Race[] property SexLabCreatures auto
Race[] property MNCCreatures auto
Race property WerewolfBeastRace auto

Armor[] ItemsReturned
Armor[] DDIArmors

Idle property KnockDown auto

ImageSpaceModifier property KnockDownISM auto

Location[] property WalledCities auto
Location[] property NonWalledCities auto
Location[] property Towns auto

String[] property PerversionComments auto

Book property SpellTome auto

Faction property MagicCharmFaction auto

int RapistsIndex
int CreatureRapistsIndex
int VictimsIndex
int Rescued = 0
Int TotalChances = 0
int CodeChosen
int Discount = 0
int WalledKidnap = 0
int CreatureTotalChances = 0
Int Count
Int Night = 0
int[] PerversionRounds
int ExhaustionRound
int[] IndividualRounds
Int KidnappedStatus


Function CheckUpdate()
	If !CurrentVersion || CurrentVersion < 410 ; PUT CURRENT VERSION HERE
		Quest SLKR_PlayerAlias_Quest = GetOwningQuest()
		SLKR_PlayerAlias_Quest.Stop()
		SLKR_PlayerAlias_Quest.Start()
	Else
		RegisterForModEvent("SLKR_Ambushed", "OnAmbushed")
		RegisterForModEvent("SLKR_Ambushed_EvenInterior", "OnAmbushed_EvenInterior")
		RegisterForModEvent("SLKR_Ambushed_NoCondition", "OnAmbushed_NoCondition")	
		RegisterForModEvent("ostim_thread_end","ostimthreadend")
		RegisterForModEvent("DAC_SLKR_Surrender", "DAC_OnSurrender")
		RegisterForModEvent("DAC_SLKR_Reset", "DAC_OnReset")
	Endif
EndFunction


Function SetUpDD()

; DEVIOUS DEVICES INTEGRATION
	DDIArmors = New Armor[13]
	Int DDChance = Utility.RandomInt(0,99)

	If DDChance < 20
		DDIArmors[0] = Game.GetFormFromFile(0x0602B073, "Devious Devices - Integration.esm") As Armor
	Elseif DDChance < 40
		DDIArmors[0] = Game.GetFormFromFile(0x0602B075, "Devious Devices - Integration.esm") As Armor
	Elseif DDChance < 60
		DDIArmors[0] = Game.GetFormFromFile(0x0602B076, "Devious Devices - Integration.esm") As Armor
	Elseif DDChance < 80
		DDIArmors[0] = Game.GetFormFromFile(0x06034253, "Devious Devices - Integration.esm") As Armor
	Else
		DDIArmors[0] = Game.GetFormFromFile(0x06034255, "Devious Devices - Integration.esm") As Armor
	Endif

	DDChance = Utility.RandomInt(0,99)

	If DDChance < 33
		DDIArmors[1] = Game.GetFormFromFile(0x06032745, "Devious Devices - Integration.esm") As Armor
	Elseif DDChance < 66
		DDIArmors[1] = Game.GetFormFromFile(0x06017759, "Devious Devices - Integration.esm") As Armor
	Else
		DDIArmors[1] = Game.GetFormFromFile(0x0604DBEF, "Devious Devices - Integration.esm") As Armor
	Endif

	DDChance = Utility.RandomInt(0,99)

	IF DDChance < 50
		DDIArmors[2] = Game.GetFormFromFile(0x06028A5A, "Devious Devices - Integration.esm") As Armor
	Else
		DDIArmors[2] = Game.GetFormFromFile(0x0604F18C, "Devious Devices - Integration.esm") As Armor
	Endif

	DDChance = Utility.RandomInt(0,99)

	IF DDChance < 25
		DDIArmors[3] = Game.GetFormFromFile(0x06033CED, "Devious Devices - Integration.esm") As Armor
	Elseif DDChance < 50
		DDIArmors[3] = Game.GetFormFromFile(0x06031704, "Devious Devices - Integration.esm") As Armor
	Elseif DDChance < 75
		DDIArmors[3] = Game.GetFormFromFile(0x06031C69, "Devious Devices - Integration.esm") As Armor
	Else
		DDIArmors[3] = Game.GetFormFromFile(0x06031C6B, "Devious Devices - Integration.esm") As Armor
	Endif			
	
	DDChance = Utility.RandomInt(0,99)
	
	IF DDChance < 33
		DDIArmors[4] = Game.GetFormFromFile(0x0600EB5D, "Devious Devices - Integration.esm") As Armor
	Elseif DDChance < 66
		DDIArmors[4] = Game.GetFormFromFile(0x06009A7B, "Devious Devices - Integration.esm") As Armor	
	Else
		DDIArmors[4] = Game.GetFormFromFile(0x06032741, "Devious Devices - Integration.esm") As Armor	
	Endif

	DDIArmors[5] = Game.GetFormFromFile(0x06047566, "Devious Devices - Integration.esm") As Armor
	DDIArmors[6] = Game.GetFormFromFile(0x060409A2, "Devious Devices - Integration.esm") As Armor

	DDChance = Utility.RandomInt(0,99)

	IF DDChance < 50
		DDIArmors[7] = Game.GetFormFromFile(0x06032743, "Devious Devices - Integration.esm") As Armor		
	Else
		DDIArmors[7] = Game.GetFormFromFile(0x0601775D, "Devious Devices - Integration.esm") As Armor	
	Endif

	DDIArmors[8] = Game.GetFormFromFile(0x06031C6F, "Devious Devices - Integration.esm") As Armor
	DDIArmors[9] = Game.GetFormFromFile(0x0601775A, "Devious Devices - Integration.esm") As Armor

	DDChance = Utility.RandomInt(0,99)

	If DDChance < 25
		DDIArmors[10] = Game.GetFormFromFile(0x06033CEE, "Devious Devices - Integration.esm") As Armor
	Elseif DDChance < 50
		DDIArmors[10] = Game.GetFormFromFile(0x06031703, "Devious Devices - Integration.esm") As Armor
	Elseif DDChance < 75
		DDIArmors[10] = Game.GetFormFromFile(0x06031C68, "Devious Devices - Integration.esm") As Armor
	Else
		DDIArmors[10] = Game.GetFormFromFile(0x006031C6C, "Devious Devices - Integration.esm") As Armor
	Endif

	DDIArmors[11] = Game.GetFormFromFile(0x0604DBF0, "Devious Devices - Integration.esm") As Armor	

	DDChance = Utility.RandomInt(0,99)

	If DDChance < 33
		DDIArmors[12] = Game.GetFormFromFile(0x06032744, "Devious Devices - Integration.esm") As Armor	
	Elseif DDChance < 66
		DDIArmors[12] = Game.GetFormFromFile(0x0601775B, "Devious Devices - Integration.esm") As Armor	
	Else
		DDIArmors[12] = Game.GetFormFromFile(0x0604DBEC, "Devious Devices - Integration.esm") As Armor	
	Endif
	
EndFunction


Function AmbushStart(Actor[] akActors)
	Int currentElement = 0
	
	FakeAmbushActors = new Actor[3]
	While currentElement < 3
	Actor Ambusher = akActors[currentElement]
	If Ambusher
		Actor FakeAmbusher = PlayerREF.PlaceActorAtMe(Ambusher.GetBaseObject() as ActorBase, 1)
		;Ambusher.MoveTo(PlayerRef)
		FakeAmbushActors[currentElement] = FakeAmbusher
		FakeAmbusher.StartCombat(PlayerRef)
		; --- MOC: tag the ambusher ------------------------------------------
		; These are throwaway copies made with PlaceActorAtMe and deleted right
		; after the teleport, so nothing else can identify them. The tag lets
		; SkyrimNet tell an abductor apart from an ordinary attacker and know the
		; goal is to take the player alive.
		Faction DAC_AmbusherFaction = Game.GetFormFromFile(0x832, "DefeatAndCapture_SLKR.esp") as Faction
		If DAC_AmbusherFaction
			FakeAmbusher.AddToFaction(DAC_AmbusherFaction)
		EndIf
		; ---------------------------------------------------------------------
	endif
	Utility.Wait(0.1)
	currentElement += 1
	Endwhile

EndFunction

Int Function CountNearby()
	SLKR_FindFriendlies_Quest.stop()
	SLKR_FindFriendlies_Quest.Start()
	
	int currentElement = 0
	int akCount = 0
	while currentElement < 5
		If Nearby[currentElement].GetReference() as Actor
			akCount += 1
		endif
		currentElement += 1
	endWhile
	return akCount
EndFunction

Function RestartQuest(Quest akQuest)
	akQuest.Stop()
	akQuest.Start()
EndFunction

Int Function AddChances(GlobalVariable[] akGlobal, int aklength, int akcreaturelength)
	int currentElement = 0
	int SumSoFar = 0
	
	While currentElement < aklength
		SumSoFar += akGlobal[currentElement].GetValueInt()
		if currentElement == akcreaturelength
			CreatureTotalChances = SumSoFar
		endif
		currentElement += 1
		utility.wait(0.01)
	Endwhile
	
	return SumSoFar
EndFunction

Function DetermineKidnappers(Quest[] akQuest, GlobalVariable[] akGlobal, int akLength, int akCreatureLength)
	AmbushActors = new Actor[3]
	TotalChances = AddChances(akGlobal, akLength, akCreatureLength)

	codeChosen = 0
	int cumulative = 0
	int Dice
	
	If WalledKidnap == 1
		Dice = Utility.RandomInt((CreatureTotalChances +1), TotalChances)
	else
		Dice = Utility.RandomInt(0, TotalChances)	
	endif	

	While cumulative <= Dice && codeChosen < 49
		cumulative += akGlobal[codeChosen].GetValueInt()
		codeChosen += 1
		Utility.Wait(0.01)
	Endwhile

	codeChosen -= 1

	SLKR_BeastialityKidnapper_Global.setValue(0)	

	Quest currentQuest = akQuest[codeChosen]
	RestartQuest(currentQuest)
	AmbushActors[0] = (currentQuest.GetAlias(0) as ReferenceAlias).getReference() as Actor
	AmbushActors[1] = (currentQuest.GetAlias(1) as ReferenceAlias).getReference() as Actor
	AmbushActors[2] = (currentQuest.GetAlias(2) as ReferenceAlias).getReference() as Actor
EndFunction


; --- MOC: per-creature-type scene-partner filter ---------------------------
; OCreatures.esp tags every OStim-supported creature race with an OCr*Race
; keyword. We mirror that set with one global each in DefeatAndCapture_SLKR.esp,
; 0x802..0x831, in the SAME order as the keyword FormIDs 0x5C2C..0x5C59 then
; 0x5C5D..0x5C5E. A global at 0 means that creature type is never used as a
; scene partner. A missing plugin, keyword or global reads as ALLOWED, so this
; degrades to stock behaviour instead of blocking everything.
Keyword[] DAC_CrKw
GlobalVariable[] DAC_CrGl

Function DAC_LoadCreatureFilter()
	DAC_CrKw = new Keyword[48]
	DAC_CrGl = new GlobalVariable[48]
	Int i = 0
	While i < 48
		Int kwid = 0x5C2C + i
		If i >= 46
			kwid = 0x5C5D + (i - 46)
		EndIf
		DAC_CrKw[i] = Game.GetFormFromFile(kwid, "OCreatures.esp") as Keyword
		DAC_CrGl[i] = Game.GetFormFromFile(0x802 + i, "DefeatAndCapture_SLKR.esp") as GlobalVariable
		i += 1
	EndWhile
EndFunction

Bool Function DAC_PartnerAllowed(Actor akActor)
	If !akActor
		Return True
	EndIf
	If DAC_CrKw == None
		Return True
	EndIf
	Int i = 0
	While i < 48
		Keyword kw = DAC_CrKw[i]
		If kw && akActor.HasKeyword(kw)
			GlobalVariable g = DAC_CrGl[i]
			If g && g.GetValue() == 0
				Return False
			EndIf
		EndIf
		i += 1
	EndWhile
	Return True
EndFunction
; ---------------------------------------------------------------------------

Function FilterRapists()
	DAC_LoadCreatureFilter()
	int currentElement = 0
	RapistsIndex = 0
	CreatureRapistsIndex = 0
	Rapists = New Actor[10]
	CreatureRapists = New Actor[10]

	While currentElement < 20
		If RapistsRA[currentElement].GetReference()
			If SLKR_DDOn_Global.GetValue() == 1 && currentElement == 0 
				SetUpDD()
			Endif
			
			Actor CurrentActor = RapistsRA[currentElement].GetReference() As Actor
			If !DAC_PartnerAllowed(CurrentActor)
				Debug.Trace("SLKR: MOC - scene partner blocked, creature type disabled")
			ElseIf currentElement < 10
				Rapists[RapistsIndex] = CurrentActor
				RapistsIndex += 1
			Elseif  SLKR_BestialityChance_Global.GetValue() != 0 && (SexLabCreatures.Find(CurrentActor.GetRace()) > -1 || (SLKR_MNC_Global.GetValue() == 1 && MNCCreatures.Find(CurrentActor.GetRace()) > -1)  )
				CreatureRapists[CreatureRapistsIndex] = CurrentActor
				CreatureRapistsIndex += 1
			EndIf
			
		Elseif currentElement == 0 ; no first human kidnapper, for stealing inventory
			SLKR_BeastialityKidnapper_Global.SetValue(1)
		EndIf
		
		Utility.Wait(0.1)
		currentElement += 1
	EndWhile
EndFunction

Function FilterVictims(ReferenceAlias[] VictimsRA)
	; --- MOC: optional player-only scenes ------------------------
	GlobalVariable DAC_PlayerOnlyG = Game.GetFormFromFile(0x801, "DefeatAndCapture_SLKR.esp") as GlobalVariable
	Bool DAC_PlayerOnly = False
	If DAC_PlayerOnlyG
		DAC_PlayerOnly = DAC_PlayerOnlyG.GetValue() == 1
	EndIf
	; ------------------------------------------------------------
	int currentElement = 0
	VictimsIndex = 0
	Victims = New Actor[4]
	PerversionRounds = New Int[4]
	While currentElement < VictimsRA.Length
		If VictimsRA[currentElement].GetReference()
			Actor CurrentActor = VictimsRA[currentElement].GetReference() As Actor
			; DAC: stripping and taking part in a scene are separate questions.
			; Stock SLKR strips inside the participation branch, so our
			; "Player-only Scenes" toggle was also sparing followers their clothes -
			; they arrived in the dungeon as prisoners, fully dressed. Stripping now
			; happens for everyone SLKR's OWN gender filter admits, whatever our
			; toggle says, so the toggle removes people from the scene and not from
			; the captivity. The gender filter's stock behaviour is left alone.
			Bool DAC_GenderOK = SLKR_VictimGender_Global.GetValue() == -1 || CurrentActor.GetActorBase().GetSex() == SLKR_VictimGender_Global.GetValue()
			If CurrentActor != PlayerRef && DAC_GenderOK
				CurrentActor.UnEquipAll()
			EndIf

			If (!DAC_PlayerOnly || CurrentActor == PlayerRef) && DAC_GenderOK
				Victims[VictimsIndex] = CurrentActor
				PerversionRounds[VictimsIndex] = ( (CurrentActor.GetBaseActorValue("Magicka") * (SLKR_MultiMagicka_Global.GetValue() as float)) as int ) + Utility.RandomInt(-2,2)
				If CurrentActor == PlayerRef
					ExhaustionRound = ( (PlayerRef.GetBaseActorValue("Stamina") * (SLKR_MultiStamina_Global.GetValue() as float)) as int ) + Utility.RandomInt(-2,2)
				endif
				VictimsIndex += 1
			Endif
		Endif
		Utility.Wait(0.1)
		currentElement += 1
	EndWhile
EndFunction


Function CheckNoStrip(Actor akActor)
	Int CurrentSlot = 0x01
	Int currentElement = 0
	ItemsReturned = new Armor[32]
	While CurrentSlot < 0x80000000
		Armor currentItem =  PlayerRef.GetWornForm(CurrentSlot) as Armor
		If currentItem && FormListHas(none, "NoStrip", currentItem)
			ItemsReturned[currentElement]= currentItem
			currentElement +=1
		Endif
		CurrentSlot *= 2
		utility.wait(0.1)
	EndWhile
EndFunction


Function ReturnNoStrip(Actor akActor)
	int currentElement = 0
	While currentElement < 32
		If ItemsReturned[currentElement]
			PlayerRef.EquipItem(ItemsReturned[currentElement],False,True)
		Endif
		currentElement += 1
		utility.wait(0.1)
	Endwhile
EndFunction


Function Outcome()
	While OActor.IsInOstim(PlayerRef)
		Utility.Wait(3)
	EndWhile
	
	Utility.Wait(2)
	
	DAC_SetStage(3)
	SLKR_FindRapists_Quest.Stop()

	If Utility.RandomInt(0,99) < SLKR_Slavery_Global.GetValue()
		; --- DAC: this kidnapping is going to Simple Slavery, not to us -------
		; The stage was published as 3 (resolved) BEFORE this roll, and Defeat and
		; Capture adopts the captivity on exactly that value. Left alone, a
		; non-zero slavery chance meant BOTH happened: the player was captured
		; where they stood AND handed to the Simple Slavery auction.
		;
		; 4 means "resolved, but somebody else took it". Nothing in SLKR reads the
		; mirror, and DAC only adopts on exactly 3, so it simply stands down. That
		; makes a slavery chance between 1 and 99 a real split rather than a
		; conflict - the README's "set it to 0" is no longer a hard requirement.
		DAC_SetMirror(4)
		sendModEvent("SSLV Entry")
	Else
		SLKR_Exhaustion_Message.Show()
		; --- DAC: this teleport home is what the takeover replaces ---------
		; Previously neutralised by stripping the Origin property in
		; DefeatAndCapture_SLKR.esp. That meant the plugin carried an override of
		; SLKR's player-alias quest, and a quest override is a copy of every
		; script property in it - each one a FormID into SL_Kidnapped_Redux.esp.
		; Those FormIDs are NOT stable: ESLifier compaction renumbers them, so the
		; override was valid only against the exact copy of SLKR it was built from
		; and produced 181 dangling references against the stock plugin.
		;
		; Guarding the one line the property was ever used for does the same job,
		; needs no override at all, and cannot break when FormIDs move.
		If DAC_TakeoverOn()
			Debug.Trace("SLKR: DAC - takeover on, skipping the teleport home")
		Else
			PlayerRef.MoveTo(Origin.GetReference())
		EndIf
	Endif
		Int CurrentElement = 0
		While CurrentElement < 3
			Actor CurrentFollower = SLKR_Followers[currentElement].GetReference() as Actor
			IF CurrentFollower
				CurrentFollower.MoveToPackageLocation()
			Endif
			CurrentElement += 1
			utility.wait(0.1)
		EndWhile
	
	SendModEvent("dhlp-Resume")
EndFunction

Function OrgyStart_Creature(Actor[] Victims1, Actor[] Rapists1, Actor[] CreatureRapists1, int akVictims)
	int tid = -1
	; CREATURE START HERE
	If (SLKR_Stage_Global.GetValue() == 2 || SLKR_Rescue_Quest.GetStage() == 10) && CreatureRapists1[0].Is3DLoaded()
		Actor CurrentRapist = CreatureRapists1[creatureElement]
		If CurrentRapist.IsInFaction(MagicCharmFaction)
			If (SLKR_Stage_Global.GetValue() == 2 || SLKR_Rescue_Quest.GetStage() == 10) && !OActor.IsInOstim(CurrentRapist)
				Actor currentVictim = Victims1[currentVictimi]
				If !OActor.IsInOstim(CurrentVictim) 

					If IndividualRounds[0] >= ExhaustionRound
						Outcome()
					Else

						If IndividualRounds[0] > 1
							
							If rescued == 0 && RescuerActor && Utility.RandomInt(0,99) < SLKR_RescuerChance_Global.GetValue()
								rescued = 1
								RescuerActor.MoveTo(PlayerRef)
								debug.notification(RescuerActor.GetDisplayName()+"$SLKR_ONRESCUEMISSION")

								Int RapistIndex = 0
								While RapistIndex < CreatureRapistsIndex
									Actor currentAttacker = CreatureRapists[RapistIndex]
									If !OActor.IsInOstim(currentAttacker) && currentAttacker.Is3DLoaded() && !currentAttacker.IsDead() 
										currentAttacker.StartCombat(RescuerActor)
									Endif
									Utility.Wait(0.1)
									RapistIndex += 1
								EndWhile
							Endif
							
							VictimApproached.ForceRefTo(CurrentVictim)
							SLKR_Approach_Quest.Start()
							utility.wait(3)
						Endif

						actor[] sexActors
						string anims
						
						sexActors = New Actor[2]
						sexActors[1] = currentVictim		
						sexActors[0] = currentRapist						
						;sexActors = OActorUtil.Sort(sexActors,sexActors)
						anims = OLibrary.GetRandomSceneSuperloadCSV(sexActors, scenetagBlacklist="idle")			

						String HookName = ""
						If currentVictim == PlayerRef
							HookName = "Player1"
						Else 
							HookName = "FollowerSLKR"
						endif
						RegisterForModEvent("SLKR_End_"+HookName, "CheckPlayer1Done")	
						
						SLKR_Approach_Quest.Stop()
						
						If !currentRapist.IsDead() && currentRapist.Is3DLoaded()
							int builder = OThreadbuilder.create(sexActors)
							OThreadbuilder.setstartinganimation(builder,anims)
							OThreadbuilder.setduration(builder,90)
							String[] meta = new String[2]
							meta[0] = HookName
							meta[1] = currentVictim.getformid()
							OThreadbuilder.setmetadata(builder, meta)
							OThreadbuilder.NoFurniture(builder)
							tid = OThreadbuilder.start(builder)
							
							if tid != -1
								RegisterForSingleUpdate(120)
								debug.trace("SLKR: Creature Sex Starts")
							Endif
							IndividualRounds[currentVictimi] = IndividualRounds[currentVictimi] + 1
						Endif
					endif
				Endif
				
				If currentVictimi < (VictimsIndex - 1)
					currentVictimi  += 1
				Else	; reach end of victim list, no rush to move to next kidnapper
					currentVictimi = 0
				Endif
			Endif
		EndIf
		
		If creatureElement == (CreatureRapistsIndex - 1)
			creatureElement = 0
		Else
			creatureElement += 1
		Endif
		if tid == -1
			OrgyStart_Actual(loopvictimsarr,looprapistsarr,loopcreaturesarr,loopakVictims)
		Else
			return
		Endif
	Endif
EndFunction

Function OrgyStart_NPC(Actor[] Victims1, Actor[] Rapists1, Actor[] CreatureRapists1, int akVictims)
	int tid = -1
	If (SLKR_Stage_Global.GetValue() == 2 || SLKR_Rescue_Quest.GetStage() == 10) && orgycurrentElement < RapistsIndex && Rapists1[0].Is3DLoaded()
		SLKR_SexHappening_Global.SetValue(0)
		Actor CurrentRapist = Rapists1[orgycurrentElement]
		If CurrentRapist.IsInFaction(MagicCharmFaction)

			If (SLKR_Stage_Global.GetValue() == 2 || SLKR_Rescue_Quest.GetStage() == 10) && !OActor.IsInOstim(CurrentRapist)
				Actor currentVictim = Victims1[currentVictimi]
				If !OActor.IsInOstim(CurrentVictim)

					Actor victimx = currentVictim
				
					;DEVIOUS DEVICES
					IF SLKR_DDOn_Global.GetValue() == 1
						int currentElementi = 0
						While currentElementi < numEquippedDD
							CurrentVictim.EquipItem(EquippedDD[currentElementi], false, true)
							currentElementi += 1
							utility.wait(0.1)
						Endwhile

						If numEquippedDD < DAC_DDCap()
							Int ddSlot = DAC_PickDDSlot(CurrentVictim)
							Armor CurrentDD = None
							If ddSlot >= 0
								CurrentDD = DDIArmors[ddSlot]
							EndIf
							If CurrentDD && CurrentVictim.GetItemCount(CurrentDD) <=0
								CurrentVictim.AddItem(CurrentDD, 1, true)
								CurrentVictim.EquipItemEx(CurrentDD, 0, false, true)
								EquippedDD[numEquippedDD] = CurrentDD
								numEquippedDD += 1
							Endif
						Endif
					Endif

					Bool Aggressive = True
					
					;  If currentRapist.getwornform(0x00000004)
						;  currentRapist.unequipall()
					;  Endif

					If IndividualRounds[0] >= ExhaustionRound			
						Outcome()
					Else

						If IndividualRounds[0] > 1
								
							If RescuerActor && rescued == 0 && Utility.RandomInt(0,99) < SLKR_RescuerChance_Global.GetValue() 
								rescued = 1
								RescuerActor.MoveTo(PlayerRef)
								debug.notification(RescuerActor.GetDisplayName()+"$SLKR_ONRESCUEMISSION")

								Int RapistIndex = 0
								While RapistIndex < RapistsIndex
									Actor currentAttacker = Rapists[RapistIndex]
									If !OActor.IsInOstim(currentAttacker) && currentAttacker.Is3DLoaded() && !currentAttacker.IsDead()							
										currentAttacker.StartCombat(RescuerActor)
									Endif
									Utility.Wait(0.1)	
									RapistIndex += 1
								EndWhile
							Endif
							
							Approacher.ForceRefTo(currentRapist)			

							If IndividualRounds[currentVictimi] < PerversionRounds[currentVictimi]
								VictimApproached.ForceRefTo(CurrentVictim)
							Else
								IF CurrentVictim == PlayerRef
									debug.notification(PlayerName+": "+PerversionComments[(Utility.RandomInt(0,38))] )
								Else
									VictimPerversed.ForceRefTo(CurrentVictim)
								Endif
								victimx = None
								Aggressive = False
							Endif

							SLKR_Approach_Quest.Start()
							Utility.Wait(7); give victim enough time to say their line
						Endif
						
						actor[] sexActors
						String anims

						If orgycurrentElement < (RapistsIndex - 1)  && !OActor.IsInOstim(Rapists1[orgycurrentElement+1]) && Utility.RandomInt(0, 99) < (SLKR_Threesome_Global.GetValue() as int)
							sexActors = New Actor[3]
							sexActors[2] = currentVictim		
							sexActors[0] = currentRapist
							sexActors[1] = Rapists1[orgycurrentElement+1]
							sexActors = OActorUtil.sort(sexActors,sexActors)
							
							If SLKR_AggThreesome.GetValue() == 1
								anims = OLibrary.GetRandomSceneWithAnySceneTagCSV(sexActors,"rape,forced,aggressive")
								if anims == ""
									anims = OLibrary.GetRandomSceneSuperloadCSV(sexActors, scenetagBlacklist="idle")
								Endif
							Else
								anims = OLibrary.GetRandomSceneSuperloadCSV(sexActors, scenetagBlacklist="idle")
							Endif
							
							;  If Rapists1[orgycurrentElement+1].getwornform(0x00000004)
								;  Rapists1[orgycurrentElement+1].unequipall()
							;  Endif
						Else
							sexActors = New Actor[2]
							sexActors[1] = currentVictim		
							sexActors[0] = currentRapist						
							sexActors = OActorUtil.sort(sexActors,sexActors)
							
							If Aggressive
								anims = OLibrary.GetRandomSceneWithAnySceneTagCSV(sexActors,"rape,forced,aggressive")
								if anims == ""
									anims = OLibrary.GetRandomSceneWithAnySceneTagCSV(sexActors,"missionary,prone,doggy")
								Endif
							Else
								anims = OLibrary.GetRandomSceneSuperloadCSV(sexActors, scenetagBlacklist="idle")
							Endif
						EndIf	
						if anims == ""
							anims = OLibrary.GetRandomSceneSuperloadCSV(sexActors, scenetagBlacklist="idle")
						Endif
						
						String HookName = ""
						
						If currentVictim == PlayerRef
							HookName = "Player1"
						Else 
							HookName = "FollowerSLKR"
						endif
						RegisterForModEvent("SLKR_End_"+HookName, "CheckPlayer1Done")	
						
						SLKR_Approach_Quest.Stop()
						
						If !currentRapist.IsDead() && currentRapist.Is3DLoaded() && (sexActors.length == 2 || (!Rapists1[orgycurrentElement+1].IsDead() && Rapists1[orgycurrentElement+1].Is3DLoaded()) )
						
							int builder = OThreadbuilder.create(sexActors)
							OThreadbuilder.setstartinganimation(builder,anims)
							OThreadbuilder.setduration(builder,90)
							String[] meta = new String[2]
							meta[0] = HookName
							meta[1] = victimX.getformid()
							OThreadbuilder.setmetadata(builder, meta)
							OThreadbuilder.NoFurniture(builder)
							tid = OThreadbuilder.start(builder)
								
							if tid != -1
								RegisterForSingleUpdate(120)
								debug.trace("SLKR: Human Sex Starts")
								SLKR_SexHappening_Global.SetValue(1)
							Endif
							IndividualRounds[currentVictimi] = IndividualRounds[currentVictimi] + 1
						Endif
					Endif			
				Endif
				; move on to next victim whether sex started or not
				
				If currentVictimi < (VictimsIndex - 1)
					currentVictimi  += 1
				Else	; reach end of victim list, no rush to move to next kidnapper
					currentVictimi = 0
				Endif	
			Endif ;Victim If
		EndIf
			
		If orgycurrentElement == (RapistsIndex - 1) && CreatureRapistsIndex == 0
			orgycurrentElement = 0
		Else
			orgycurrentElement += 1
		Endif
		if tid == -1
			OrgyStart_Actual(loopvictimsarr,looprapistsarr,loopcreaturesarr,loopakVictims)
		Else
			return
		Endif
	EndIf
	OrgyStart_Creature(Victims1, Rapists1, CreatureRapists1, akVictims)
EndFunction

Function OrgyStart_Actual(Actor[] Victims1, Actor[] Rapists1, Actor[] CreatureRapists1, int akVictims)
	
	OrgyStart_NPC(Victims1, Rapists1, CreatureRapists1, akVictims)

EndFunction

int orgycurrentElement
int creatureElement
Armor[] EquippedDD
int numEquippedDD
int currentVictimi

Actor[] loopvictimsarr
Actor[] looprapistsarr
Actor[] loopcreaturesarr
int loopakVictims

Actor RescuerActor
String PlayerName

Function OrgyStart(Actor[] Victims1, Actor[] Rapists1, Actor[] CreatureRapists1, int akVictims)
	; --- MOC: optional no-scenes mode ----------------------------
	GlobalVariable DAC_NoScenesG = Game.GetFormFromFile(0x800, "DefeatAndCapture_SLKR.esp") as GlobalVariable
	Bool DAC_NoScenes = False
	If DAC_NoScenesG
		DAC_NoScenes = DAC_NoScenesG.GetValue() == 1
	EndIf
	; Also resolve when the creature filter left nobody: otherwise the stage
	; would sit at 2 forever and the MOC handoff would never fire.
	If DAC_NoScenes || (RapistsIndex == 0 && CreatureRapistsIndex == 0)
		UnregisterForUpdate()
		SLKR_SexHappening_Global.SetValue(0)
		Debug.Trace("SLKR: MOC - scenes disabled, resolving instead of starting an orgy")
		; Outcome() is the ONLY thing that sets SLKR_Stage_Global to 3, and MOC's
		; kidnap handoff adopts the captivity on exactly that. Returning bare here
		; would leave the stage at 2 forever, so the takeover would never fire and
		; the whole thing would just time out. Resolve properly instead: Outcome()
		; stops the rapist quest, sends dhlp-Resume, and sets stage 3. Its
		; MoveTo(Origin) is already a no-op because DefeatAndCapture_SLKR strips Origin.
		; Guarded to the main kidnap flow (stage 2) so the rescue quest, which
		; also routes through OrgyStart, is left alone.
		If SLKR_Stage_Global.GetValue() == 2
			Outcome()
		EndIf
		Return
	EndIf
	; ------------------------------------------------------------
	
	If Victims1.Find(PlayerRef) == -1
		ExhaustionRound = ( (Victims1[0].GetBaseActorValue("Stamina") * (SLKR_MultiStamina_Global.GetValue() as float)) as int ) + Utility.RandomInt(-2,2)
	Endif
	
	If SLKR_Rescue_Quest.GetStage() == 10
		VictimsIndex = akVictims
		ExhaustionRound = 999
		PerversionRounds = New Int[1]
		PerversionRounds[0] = 5
	Endif

	orgycurrentElement = 0
	creatureElement = 0
	IndividualRounds = new Int[4]
	EquippedDD = new Armor[99]
	numEquippedDD = 0
	currentVictimi = 0
	
	loopvictimsarr = Victims1
	looprapistsarr = Rapists1
	loopcreaturesarr = CreatureRapists1
	loopakVictims = akVictims
	
	RescuerActor = Rescuer.GetReference() as Actor
	PlayerName = PlayerRef.GetDisplayName()
	
	OrgyStart_Actual(Victims1, Rapists1, CreatureRapists1, akVictims)

EndFunction


Function DefaultVariables()
	AmbushActors = new Actor[3]
	KidnappedStatus = 0
	DAC_SetStage(1)
	WalledKidnap = 0
	rescued = 0
EndFunction

Function HandleFollowers(ReferenceAlias[] akFollowers)
	int currentElement = 0
	While currentElement < 3
		Actor Follower001 = akFollowers[currentElement].GetReference() as Actor
		If Follower001
			Follower001.MoveTo(PlayerRef)		
		Endif
		currentElement +=1
		utility.wait(0.1)
	EndWhile
EndFunction


; FOR RESCUE QUEST
Function RescueIni (ReferenceAlias akVictim, Quest[] akQuest, GlobalVariable[] akGlobal, int akLength, int akCreatureLength)
	DetermineKidnappers(akQuest, akGlobal, akLength, akCreatureLength)
	While !AmbushActors[0]
		DetermineKidnappers(akQuest, akGlobal, akLength, akCreatureLength)
		utility.wait(0.1)
	Endwhile
	(akVictim.GetReference() As Actor).MoveTo(AmbushActors[0])
	DefaultVariables()
EndFunction


Function RescueOrgy(Actor[] Victims1, int akVictims)
	RestartQuest(SLKR_FindRapists_Quest)
	FilterRapists()
	OrgyStart(Victims1, Rapists, CreatureRapists, akVictims)
EndFunction



; EVENT SECTION -----------------------------------------------------------------------------------------------------------------------------

Event OnInit()
	Utility.Wait(2.0)
	debug.notification("$SLKR_INSTALLTHANKS")
	
	If PlayerREF.GetItemCount(SpellTome) < 1
		PlayerRef.AddItem(SpellTome, 1)
	Endif
	
	DefaultVariables()
	
	RegisterForModEvent("SLKR_Ambushed", "OnAmbushed")
	RegisterForModEvent("SLKR_Ambushed_EvenInterior", "OnAmbushed_EvenInterior")
	RegisterForModEvent("SLKR_Ambushed_NoCondition", "OnAmbushed_NoCondition")
	RegisterForModEvent("ostim_thread_end","ostimthreadend")
	RegisterForModEvent("DAC_SLKR_Surrender", "DAC_OnSurrender")
	RegisterForModEvent("DAC_SLKR_Reset", "DAC_OnReset")
	
	CurrentVersion = 410; PUT CURRENT VERSION HERE
	
	RegisterForSingleUpdateGameTime(1)
EndEvent


Event OnUpdate()			
	OrgyStart_Actual(loopvictimsarr,looprapistsarr,loopcreaturesarr,loopakVictims)
EndEvent

Event OnPlayerLoadGame()
	CheckUpdate()
EndEvent


Event OnUpdateGameTime()
	DefaultVariables()
	debug.trace("SLKR: One hour passes. Checking ...")
	Night = 0
	If GameHour.GetValue() > (SLKR_NightLater_Global.GetValue() as int) || GameHour.GetValue() < (SLKR_NightEarlier_Global.GetValue() as int)
		Night = SLKR_Night.GetValue() as Int
		debug.trace("SLKR: Night")
	endif
	
	Location PlayerLocation = PlayerRef.GetCurrentLocation()
	
	WalledKidnap = 0
	Discount = 0
	
	If WalledCities.Find(PlayerLocation) > -1
		Discount = SLKR_WalledCities.GetValue() as int
		WalledKidnap = 1
		debug.trace("SLKR: Walled city")
	elseif NonWalledCities.Find(PlayerLocation) > -1
		Discount = SLKR_NonWalledCities.GetValue() as int
		debug.trace("SLKR: Non-walled city")
	elseif Towns.Find(PlayerLocation) > -1
		Discount = SLKR_Towns.GetValue() as int
		debug.trace("SLKR: Town")
	else
		Discount = 0
		debug.trace("SLKR: Wilderness")
	endif
	
	Count = CountNearby()
	debug.trace("SLKR: "+Count+" nearby NPCs")

	Int Chance = (SLKR_Base.GetValue() as int) - Count*(SLKR_PerFriendly.GetValue() as int) + Night - Discount
	debug.trace("SLKR: Calculated chance is "+Chance+"%")
	
	AmbushActors = new Actor[3]
	KidnappedStatus = 0
	
	If SLKR_Modon_Global.GetValue() == 1 && Utility.RandomInt(0,99) < Chance && ( SLKR_AvoidRevenge_Global.GetValue() == 0 || !SLKR_Revenge_Quest.IsRunning() ) && ( SLKR_AvoidRescue_Global.GetValue() == 0 || !SLKR_Rescue_Quest.IsRunning() )
		
		int Attempts = 0
		While !AmbushActors[0] && Attempts < 10
			DetermineKidnappers(FindKidnappersQuest, SLKR_Chances, 49, 24)
			Attempts += 1
			utility.wait(0.1)
		EndWhile
		
		If Attempts < 10 && KidnappedStatus == 0 && !PlayerRef.IsInInterior() && (SLKR_AvoidDialogue_Global.GetValue() == 0 || !UI.IsMenuOpen("Dialogue Menu") ) && (SLKR_AvoidCombat_Global.GetValue() == 0 || !PlayerRef.IsInCombat() ) && (SLKR_AvoidSex_Global.GetValue() == 0 || !OActor.IsInOstim(PlayerRef) ) && (SLKR_AvoidScene_Global.GetValue() == 0 || !PlayerRef.GetCurrentScene() ) && (SLKR_AvoidSwimming_Global.GetValue() == 0 || !PlayerRef.IsSwimming() ) && (SLKR_AvoidWerewolf_Global.GetValue() == 0 || PlayerRef.GetRace() != WerewolfBeastRace ) && (SLKR_AvoidNaked_Global.GetValue() == 0 || !PlayerRef.getwornform(0x00000004) )
			; Kidnapper found, start ambush
			KidnappedStatus = 1
			AmbushStart(AmbushActors)
			SLKR_Ambushed_Message.Show()
			utility.wait(SLKR_SecAvoidHit.GetValue()); 5 seconds to avoid getting hit
			If KidnappedStatus != 2
				KidnappedStatus = 3
				SLKR_Dodged_Message.Show()
				RegisterForSingleUpdateGameTime(SLKR_TimeoutFailed_Global.GetValue())
			Endif
		Else
			RegisterForSingleUpdateGameTime(1)
		Endif
	Else
		RegisterForSingleUpdateGameTime(1); Check again in an hour if PC Kidnaps are off or the quests are running
	EndIf
EndEvent


Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, \
  bool abBashAttack, bool abHitBlocked)

If  KidnappedStatus == 1 && FakeAmbushActors.Find(akAggressor as actor) > - 1
	DAC_DoAbduction()
EndIf
EndEvent

; --- MOC: surrender during the ambush window --------------------------------
; SLKR only turns an ambush into an abduction when an ambusher lands a hit. The
; surrender hotkey sends "DAC_SLKR_Surrender", which takes the exact same path,
; so the player can skip the fight instead of standing there waiting to be hit.
; --- DAC: external reset ----------------------------------------------------
; After a successful abduction SLKR leaves KidnappedStatus at 2 and only clears
; it from OnUpdateGameTime, scheduled 2 + SLKR_Timeout_Global GAME-HOURS later.
; Until then OnAmbushed's "While KidnappedStatus == 0" loop rejects every new
; ambush - including SLKR's own force-trigger, which then silently does nothing.
; Defeat and Capture sends DAC_SLKR_Reset the moment captivity actually ends, so
; SLKR stops believing a kidnapping is still running.
Event DAC_OnReset(String eventName, String strArg, Float numArg, Form sender)
	If KidnappedStatus == 0 && SLKR_Stage_Global.GetValue() == 1
		Return
	EndIf
	Debug.Trace("SLKR: DAC - external reset; clearing stale kidnap state")
	SLKR_FindRapists_Quest.Stop()
	DefaultVariables()
	RegisterForSingleUpdateGameTime(1)
EndEvent

Event DAC_OnSurrender(String eventName, String strArg, Float numArg, Form sender)
	If KidnappedStatus == 1
		Debug.Trace("SLKR: MOC - player surrendered during the ambush window")
		DAC_DoAbduction()
	EndIf
EndEvent

Function DAC_DoAbduction()
	KidnappedStatus = 2
	; DAC: publish the stage IMMEDIATELY, not at the original line further down.
	; KidnappedStatus is script-local, so the stage global is the only way anything
	; outside this script can tell an ambush has become an abduction - and stock
	; SLKR does not set it until after ~0.3s of waits and a RestartQuest. Defeat
	; and Capture's surrender hotkey polls this to decide whether SLKR took the
	; surrender or whether it should capture the player itself, so the delay was
	; the difference between a handshake and a guess. Set again below, unchanged;
	; writing the same value twice costs nothing.
	DAC_SetStage(2)
	SendModEvent("dhlp-Suspend")
	
	int ambushIndex1 = 0
	While ambushIndex1 < 3
		Actor currentAmbusher = FakeAmbushActors[ambushIndex1]
		If currentAmbusher && !currentAmbusher.IsDead()
			currentAmbusher.AddToFaction(MagicCharmFaction)
		Endif
		ambushIndex1 += 1
		Utility.Wait(0.1)
	Endwhile
	
	PlayerRef.StopCombatAlarm()
	
	SLKR_Kidnapped_Message.Show()
	KnockDownISM.ApplyCrossFade(5)
	Game.ForceThirdPerson()
	PlayerRef.PlayIdle(KnockDown)
	
	RestartQuest(SLKR_FindFollowers_Quest)
	DAC_SetStage(2)
	CheckNoStrip(PlayerRef)
	Utility.Wait(3)

	Actor MainAmbusher = AmbushActors[0]
	
	;If SLKR_Abandoned_Global.GetValue() == 1
	;	MainAmbusher.Moveto(AbandonedHouses[Utility.RandomInt(0,1)])
	;Else
	;	MainAmbusher.Reset(); Latent function, no need to wait
	;EndIf
	;
	;If MainAmbusher.GetParentCell()
	;	MainAmbusher.GetParentCell().SetPublic()
	;else; Can't find ambusher's home
	;	MainAmbusher.Moveto(AbandonedHouses[Utility.RandomInt(0,1)])
	;endif	

	; --- MOC: make sure the real captors know this happened ---------------------
	; NO extra requirements beyond SkyrimNet itself, which this mod already talks
	; to optionally. The ambushers the player just fought are throwaway copies about
	; to be Delete()d, so their SkyrimNet memories die with them and the NPC holding
	; the player has no idea they ever met. There is no memory-READ function in
	; SkyrimNetApi - only write-side calls - so Papyrus alone cannot copy the real
	; conversation across; that is exactly why the Captive Bridge needed a native
	; DLL. What we CAN do without any dependency is write the FACT of the abduction
	; onto the real NPCs, so their first line in the dungeon is "we've met" instead
	; of "who are you".
	;
	; Runs BEFORE the MoveTo below, so GetCurrentLocation() still reports where the
	; ambush actually happened rather than the destination.
	If Game.GetModByName("SkyrimNet.esp") != 255
		String DAC_where = ""
		Location DAC_loc = PlayerRef.GetCurrentLocation()
		If DAC_loc
			DAC_where = " near " + DAC_loc.GetName()
		EndIf
		Int DAC_e = 0
		While DAC_e < 3
			Actor DAC_captor = AmbushActors[DAC_e]
			If DAC_captor
				SkyrimNetApi.RegisterPersistentEvent( \
					DAC_captor.GetDisplayName() + " and their people ambushed " + \
					PlayerRef.GetDisplayName() + DAC_where + \
					", beat them down and hauled them back here as a prisoner.", \
					DAC_captor, PlayerRef)
			EndIf
			DAC_e += 1
		EndWhile
		Debug.Trace("SLKR: MOC - abduction recorded on the real captors")
	EndIf
	; ---------------------------------------------------------------------------

	PlayerRef.Moveto(MainAmbusher)

	; --- MOC: carry the ambush over to the real captors (OPTIONAL) --------------
	; The FakeAmbushActors are deleted a few lines below, taking their SkyrimNet
	; identity with them - anything the player said to an ambusher is lost, and the
	; NPC actually holding them has no memory of ever having met. SkyrimNet Captive
	; Bridge exposes an EXPLICIT transfer that needs no name correlation, unlike its
	; automatic NotifyCaptive() path which resolves originals by unique display name
	; (RealNames Extended) and would be broken by NND's per-reference naming.
	;
	; Direction is inverted from the bridge's own use case: the throwaway copy is
	; the "original" holding the history, the real NPC is the "clone" inheriting it.
	; Index pairing is safe - AmbushStart() builds FakeAmbushActors[i] from
	; AmbushActors[i]. Must run BEFORE the Delete() loop while the UUID resolves.
	; Entirely optional: skipped when the bridge is not installed.
	If Game.GetModByName("SkyrimNetCaptiveBridge.esp") != 255 || Game.GetLightModByName("SkyrimNetCaptiveBridge.esp") != 65535
		If SNCaptiveBridge_Native.IsBridgeReady()
			; Mode 0 = ReplayMemories (additive). Mode 1 = DbRepoint REPOINTS the
			; identity in SkyrimNet's DB - correct for a blank clone, wrong here,
			; because our target already has a history of its own.
			SNCaptiveBridge_Native.SetTransferMode(0)
			Int DAC_t = 0
			While DAC_t < 3
				Actor DAC_fake = FakeAmbushActors[DAC_t]
				Actor DAC_real = AmbushActors[DAC_t]
				If DAC_fake && DAC_real
					Bool DAC_ok = SNCaptiveBridge_Native.TransferCaptiveIdentity(DAC_fake, DAC_real)
					Debug.Trace("SLKR: MOC - ambush identity transfer " + DAC_fake.GetDisplayName() + \
						" -> " + DAC_real.GetDisplayName() + " accepted=" + DAC_ok)
				EndIf
				DAC_t += 1
			EndWhile
		Else
			Debug.Trace("SLKR: MOC - captive bridge present but not ready; no identity transfer")
		EndIf
	EndIf
	; ---------------------------------------------------------------------------

	int ambushIndex = 0
	While ambushIndex < 3
		Actor currentAmbusher = FakeAmbushActors[ambushIndex]
		currentAmbusher.Delete()
		ambushIndex += 1
		Utility.Wait(0.1)
	Endwhile
	
	SLKR_ForceGreeted_Global.setValue(1) ;ready for when Rapist gets filled
	RestartQuest(SLKR_FindRapists_Quest)
	PlayerRef.StopCombatAlarm()		;Above sends rapists to Charm Faction. Stop combat is the next priority. 
	HandleFollowers(SLKR_Followers)

	SLKR_Revenge_Quest.Start(); latent, should stage 0 fragment should already be complete before next step
	ReturnNoStrip(PlayerRef)
	SLKR_Revenge_Quest.setActive()

	FilterRapists()	
	FilterVictims(VictimsRA)
	
	utility.wait(5); 5 seconds to make sure forcegreet triggers
	SLKR_ForceGreeted_Global.setValue(0)
	
	OrgyStart(Victims, Rapists, CreatureRapists, 19)
	RegisterForSingleUpdateGameTime(2+SLKR_Timeout_Global.getValue())
EndFunction

Event ostimthreadend(string eventname, string json, float argflt, Form sender)
	String[] meta = OJson.GetMetadata(json)
	int i = meta.Length
	while i>0
		i-=1
		int handle = Modevent.create("SLKR_End_"+meta[i])
		Modevent.pushstring(handle,eventname)
		Modevent.pushstring(handle,json)
		Modevent.pushfloat(handle,argflt)
		Modevent.pushform(handle,sender)
		Modevent.send(handle)
	Endwhile
EndEvent

Event CheckPlayer1Done(string eventname, string json, float argflt, Form sender)
	UnregisterforUpdate()
	Actor[] actarr = OJson.GetActors(json)
	if actarr.find(PlayerRef) > -1
		PlayerRef.PlayIdle(KnockDown)
		SLKR_SexHappening_Global.SetValue(0)
	Endif
	RegisterForSingleUpdate(20.0)
EndEvent


; CUSTOM EVENTS FOR MODDERS

Event OnAmbushed(string eventName, string strArg, float numArg, Form sender)
		While KidnappedStatus == 0
	
			If AmbushActors[0] == None; Empty kidnap leader, so try to find one
				DetermineKidnappers(FindKidnappersQuest, SLKR_Chances, 49, 24)
			Elseif !PlayerRef.IsInInterior() && (SLKR_AvoidDialogue_Global.GetValue() == 0 || !UI.IsMenuOpen("Dialogue Menu") ) && (SLKR_AvoidCombat_Global.GetValue() == 0 || !PlayerRef.IsInCombat() ) && (SLKR_AvoidSex_Global.GetValue() == 0 || !OActor.IsInOstim(PlayerRef) ) && (SLKR_AvoidScene_Global.GetValue() == 0 || !PlayerRef.GetCurrentScene() ) && (SLKR_AvoidSwimming_Global.GetValue() == 0 || !PlayerRef.IsSwimming() ) && (SLKR_AvoidWerewolf_Global.GetValue() == 0 || PlayerRef.GetRace() != WerewolfBeastRace ) && (SLKR_AvoidNaked_Global.GetValue() == 0 || !PlayerRef.getwornform(0x00000004) )
				; Kidnapper found, start ambush
				KidnappedStatus = 1
				AmbushStart(AmbushActors)
				SLKR_Ambushed_Message.Show()
				
				utility.wait(SLKR_SecAvoidHit.GetValue()); 5 seconds to avoid getting hit
				If KidnappedStatus != 2
					KidnappedStatus = 3
					SLKR_Dodged_Message.Show()
					Utility.WaitGameTime(SLKR_TimeoutFailed_Global.GetValue())
					RegisterForSingleUpdateGameTime(1)
					DefaultVariables()
				Endif
			Else
				;repeat the while loop until all avoid conditions are met
			Endif
			
			Utility.wait(1)
		Endwhile
EndEvent


Event OnAmbushed_EvenInterior(string eventName, string strArg, float numArg, Form sender)
		While KidnappedStatus == 0
	
			If AmbushActors[0] == None; Empty kidnap leader, so try to find one
				DetermineKidnappers(FindKidnappersQuest, SLKR_Chances, 49, 24)
			Elseif (SLKR_AvoidDialogue_Global.GetValue() == 0 || !UI.IsMenuOpen("Dialogue Menu") ) && (SLKR_AvoidCombat_Global.GetValue() == 0 || !PlayerRef.IsInCombat() ) && (SLKR_AvoidSex_Global.GetValue() == 0 || !OActor.IsInOstim(PlayerRef) ) && (SLKR_AvoidScene_Global.GetValue() == 0 || !PlayerRef.GetCurrentScene() ) && (SLKR_AvoidSwimming_Global.GetValue() == 0 || !PlayerRef.IsSwimming() ) && (SLKR_AvoidWerewolf_Global.GetValue() == 0 || PlayerRef.GetRace() != WerewolfBeastRace ) && (SLKR_AvoidNaked_Global.GetValue() == 0 || !PlayerRef.getwornform(0x00000004) )
				; Kidnapper found, start ambush
				KidnappedStatus = 1
				AmbushStart(AmbushActors)
				SLKR_Ambushed_Message.Show()
				
				utility.wait(SLKR_SecAvoidHit.GetValue()); 5 seconds to avoid getting hit
				If KidnappedStatus != 2
					KidnappedStatus = 3
					SLKR_Dodged_Message.Show()
					Utility.WaitGameTime(SLKR_TimeoutFailed_Global.GetValue())
					RegisterForSingleUpdateGameTime(1)
					DefaultVariables()
				Endif
			Else
				;repeat the while loop until all avoid conditions are met
			Endif
			
			Utility.wait(1)
		Endwhile
EndEvent


Event OnAmbushed_NoCondition(string eventName, string strArg, float numArg, Form sender)
		While KidnappedStatus == 0
	
			If AmbushActors[0] == None; Empty kidnap leader, so try to find one
				DetermineKidnappers(FindKidnappersQuest, SLKR_Chances, 49, 24)
			Else
				; Kidnapper found, start ambush
				KidnappedStatus = 1
				AmbushStart(AmbushActors)
				SLKR_Ambushed_Message.Show()
				
				utility.wait(SLKR_SecAvoidHit.GetValue()); 5 seconds to avoid getting hit
				If KidnappedStatus != 2
					KidnappedStatus = 3
					SLKR_Dodged_Message.Show()
					Utility.WaitGameTime(SLKR_TimeoutFailed_Global.GetValue())
					RegisterForSingleUpdateGameTime(1)
					DefaultVariables()
				Endif
			Endif
			
			Utility.wait(1)
		Endwhile
EndEvent

; --- DAC: single choke point for SLKR's stage -------------------------------
; Every SLKR_Stage_Global write in this script now goes through here so the value
; can be mirrored into a global THIS PATCH owns.
;
; Why: Defeat and Capture used to read SLKR's own global by hardcoded FormID.
; That FormID is not stable - ESLifier compaction renumbers it (0x414 compacted
; vs 0x31E1 stock), so the base mod silently decided SLKR was not installed on
; any load order where the numbering differed from the one it was built against.
; A global in DefeatAndCapture_SLKR.esp cannot move, because we ship it.
; Is the base mod's SLKR takeover switched on? Resolved at runtime, so with the
; base mod absent this returns false and SLKR behaves exactly as it always did -
; which is the correct fallback: without Defeat and Capture there is nothing to
; hand the player to, so the teleport home must still happen.
Bool Function DAC_TakeoverOn()
	GlobalVariable g = Game.GetFormFromFile(0x817, "DefeatAndCapture.esp") as GlobalVariable
	Return g && g.GetValue() as Int == 1
EndFunction

Function DAC_SetStage(int v)
	SLKR_Stage_Global.SetValue(v)
	DAC_SetMirror(v)
EndFunction

; Write the mirror WITHOUT touching SLKR's own global. Used to tell Defeat and
; Capture something SLKR has no value for - currently 4, "resolved by Simple
; Slavery, stand down".
Int Function DAC_PickDDSlot(Actor victim)
{Which DDIArmors slot to draw from. -1 means equip nothing this round.

 SetUpDD() fills 13 slots and each slot is a single CATEGORY - slot 3 is always an
 anal plug, slot 4 always a chastity belt, and so on. That is what makes a per-slot
 filter exact: we are not guessing at an item, we are excluding a category.

 A keyword test would have been the obvious approach and does NOT work here. The
 armours SLKR picks are DD's INVENTORY devices, and those carry only
 zad_InventoryDevice - the zad_DeviousBelt / zad_DeviousPlugVaginal type keywords
 live on the RENDERED device, which is a different form the script never touches.

 On a male victim these seven categories are dropped:
     3  plugs, anal          4  chastity belts       5  genital piercing
     6  nipple piercings     9  chastity bra        10  plugs, vaginal
 leaving gags, collars, armbinder/yoke, leg cuffs, blindfold, corset and arm
 cuffs/gloves - which read fine on anyone. SLKR's pool contains no heels and no
 bodysuits, so there is nothing to exclude on that front.

 Judged per victim, not per player, so a male follower in the same scene is covered.}
	GlobalVariable g = Game.GetFormFromFile(0x835, "DefeatAndCapture_SLKR.esp") as GlobalVariable
	If g == None || g.GetValue() as Int == 0
		Return Utility.RandomInt(0,12)
	EndIf
	ActorBase ab = victim.GetLeveledActorBase()
	If ab == None || ab.GetSex() == 1
		Return Utility.RandomInt(0,12)
	EndIf
	Int[] male = new Int[7]
	male[0] = 0     ; gags
	male[1] = 1     ; collars
	male[2] = 2     ; armbinder / yoke
	male[3] = 7     ; leg cuffs
	male[4] = 8     ; blindfold
	male[5] = 11    ; corset
	male[6] = 12    ; arm cuffs / gloves
	Return male[Utility.RandomInt(0,6)]
EndFunction

Int Function DAC_DDCap()
{SLKR adds one more device per scene round and never stops - EquippedDD is a 99 slot
 array cleared only when a captivity begins. A long captivity therefore buries the
 victim, and because every round re-equips the whole accumulated stack with a 0.1s
 wait each, the round cost grows with it.

 0 or unset means no cap, which is stock behaviour.}
	GlobalVariable g = Game.GetFormFromFile(0x836, "DefeatAndCapture_SLKR.esp") as GlobalVariable
	If g == None
		Return 99
	EndIf
	Int c = g.GetValue() as Int
	If c <= 0 || c > 99
		Return 99
	EndIf
	Return c
EndFunction

Function DAC_SetMirror(int v)
	GlobalVariable mirror = Game.GetFormFromFile(0x834, "DefeatAndCapture_SLKR.esp") as GlobalVariable
	If mirror
		mirror.SetValue(v)
	EndIf
EndFunction