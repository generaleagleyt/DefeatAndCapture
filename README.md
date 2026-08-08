# Defeat and Capture
Defeat and Capture (DAC) is a defeat mod built with SkyrimNet in mind. Includes death prevention, player and follower capture by NPCs (by defeat or by AI) and bandit-to-ally conversion to keep them persistent. Other mods can initiate DAC capture too. ESL-flagged. Packed in a FOMOD with optional patches for supported mods.

SkyrimNet side includes new AI actions and NPC awareness. 

## Disclaimer
This mod is in ALPHA stage. It was built using [houseCARL](https://www.nexusmods.com/skyrimspecialedition/mods/181738) and Claude Opus 5. While I have a lot of experience with using Synthesis, xEdit and creating patches, this is the first time I was working with scripts. Everything was tested and is (so far) working on my end. There still might be bugs I didn't find. Prompts might need more refining. Make sure to report them here or in my post on SkyrimNet discord.

## TESTED ON SKYRIM AE ONLY. SE and VR should work.

# Overview
When you are defeated, the enemy that last hit you will capture you. The enemy group will stop attacking, your gear is taken, and you stay where you are, at mercy of your new captors. (If the group was fighting a third party, they keep fighting each other.)

This allows you to roleplay with AI NPCs from SkyrimNet. They will be aware that you (and your followers) were defeated and will act accordingly. They differentiate between a defeat and a surrender. NPCs can trigger the capture on their own too. If you tell someone you yield or surrender, they can trigger a new DAC_TakeCaptive action to trigger DAC's defeat and capture. If persuaded, they can also release you and give you your stuff back. An enemy can become your ally - join your side. If you are currently captured, they can help to free you.

Works well with SeverActions' new mechanic where most enemies are not hostile. Works without it too.

## Requirements
Tested on Skyrim AE only. If using SE and VR, make sure to get appropriate versions of the mods below.

**Hard:** 
- [Skyrim Script Extender (SKSE64)](https://www.nexusmods.com/skyrimspecialedition/mods/30379)
- [PapyrusUtil SE](https://www.nexusmods.com/skyrimspecialedition/mods/13048)
- [UIExtensions](https://www.nexusmods.com/skyrimspecialedition/mods/17561)

**For the MCM:**
- [SkyUI](https://www.nexusmods.com/skyrimspecialedition/mods/12604)
- [MCM Helper](https://www.nexusmods.com/skyrimspecialedition/mods/53000)

**Optional:**
- [SkyrimNet](https://github.com/MinLL/SkyrimNet-GamePlugin) - 
  Technically optional, but built with it in mind. AI-driven capture/release, NPC awareness.
  Expands to DAC integrations as well.
- [OStimNet](https://github.com/tetherball88/OStimNet) - 
  Not needed but recommended for NSFW content.
- [Devious Devices NG](https://www.loverslab.com/files/file/29779-devious-devices-ng/) And its requirements. - 
  Get bound after capture.

**Integrations:** (Optional, make sure to install their requirements as well.)
- [Yamete REDUX](https://www.loverslab.com/files/file/24430-yamete-redux/) - 
  Adds DAC capture consequence to Yamete REDUX.
  Overwrites Yamete's Consequences.json - the same content, with DAC at the end.
- [SL Kidnapped Redux SE](https://www.loverslab.com/files/file/10087-sexlab-kidnapped-redux-se/) and 
  [OStim Patch](https://www.loverslab.com/files/file/49431-sexlab-kidnapped-redux-ostim-patch/) - 
  For the DAC SL Kidnapped Redux Patch. You get captured and stay in the dungeon instead of being sent away.
- [Captive Player](https://www.loverslab.com/files/file/43497-captive-player/) - NOT SHIPPED YET. It contains an edited CP script. I messaged the author in case I need a permission for that. No reply yet.
  For the DAC Captive Player Patch. You get captured and stay in the dungeon instead of being sent away.
  Optional SkyrimNet awareness - NPCs differenciate between captives and captors.
- [Leash Framework](https://www.loverslab.com/files/file/50377-leash-framework/) - 
  For the DAC Leash Patch. On capture, a leash is placed on you and your followers, connected to your captor. Prevents you from walking away.
  (WIP) AI actions that allow to equip or unequip a leash, also to attach it to the ground and to pick it back up.
  Optional SkyrimNet actions - NPCs can add or remove leashes.
- [Dark Arena](https://www.loverslab.com/files/file/11946-dark-arena-sse/) and 
  [Dark Arena Fixes and OStim](https://www.loverslab.com/files/file/33930-dark-arena-fixes-and-ostim/) - 
  DAC capture won't fire as long as your debt is not paid. Also, DAC makes sure PC can't be killed during pit fights, which could sometimes happen.
  SkyrimNet - During pit fights, NPCs are aware a fight is happening and who wins. Your opponent knows he is facing you and who won. Also EXPERIMENTAL, during the "Serve X clients" quest, if you ask AI and they accept, it should count as a valid client.

## Installation

Install with a mod manager of your choice. Can be installed mid-save.

## Uninstallation

It is generally not recommended to remove mods mid-save. Do at your own risk. First end your current capture with the "Currently Captured" MCM setting. Then press **Forget all allies** and **Clear persistent allies**. Close the MCM, wait 5 seconds, then open MCM and press **Defeat and Capture enabled** (so it's OFF).

## How it works

When you are defeated, the enemy that defeated you will capture you. By default the player is essential, and the defeat triggers on player bleedout (configurable).

On capture, you and **everyone present** are put into a single faction that makes its members non-hostile. The whole group disengages, and anyone who arrives later is added too. Release takes it away again — it never touches a faction they legitimately belong to.

This membership is per individual, not per group. Being spared by one bandit does not make every bandit in Skyrim treat you as a friend; only the people actually there stand down.

Once you are defeated, DAC's capture system triggers. The closest enemy becomes your captor and takes your items (optional, takes non-quest items only). If you have Devious Devices, you can get bound and the captor keeps the key.

(Imagine it like Sanguine's Deubachery capture, but without the NSFW stuff.)

Random neutral sources of damage like fall damage or stray traps won't trigger capture.

## Your followers

What happens to your companions when you are captured is your choice:
**Keep fighting** - Followers continue the fight until they either defeat the enemies (you are freed) or are defeated themselves (get captured too).
**Pacified with you** - Followers stop fighting but aren't captured.
**Captured with you** - Followers surrender the moment you are defeated, and get captured too. 

Surrendering with DAC's Surrender hotkey makes your whole group surrender, not just you.

## Allies are persistent

If you manage to persuade a bandit to betray their group and join you instead, they can become your Ally. However, most enemies in Skyrim are generic actors spawned from a list. Their references are deleted by either dynamic reference cleanup or when their cell resets — roughly ten in-game days, thirty for a cleared dungeon. 

If you want this Ally to become a more important character in your story, the Ally status prevents it from being deleted. There are 16 Ally slots in total. You can have more allies then that, but only 16 will persist. You will get a notification if this list becomes full. 

You can use DAC's **Mark Ally** power to add NPCs to this group manually. Using it again on the same NPC will remove them. There is also a setting in MCM that will clear the saved ally list.

If your Ally dies, they are removed from this group. (In case you use a console command or other way to resurrect them, remember to add them again.)

## Ways captivity can start

**Player bleedout** - Default. Get downed, DAC keeps you alive, a nearby NPC captures you. Optionally enable the **Confirm captures** setting in the MCM to have a message box pop up when you would be captured, where you can select to Allow or Deny it.
**Health threshold** - Optional. Any hit leaving you at or below a set % of your Health captures you. This also catches the blow that kills outright, where there is no bleedout to enter (one-shot prevention). Off by default.
**Surrender hotkey** - Press the hotkey to surrender instantly. Closest NPC captures you (includes non-follower NPCs. If you use this next to a random farmer, he will capture you too.) 
**AI decision** - An AI NPC can choose to use `DAC_TakeCaptive` action when you say you yield or surrender. It's prompt-guided, not hardcoded.
**External defeat mod** - So far only Yamete REDUX. If you have it, DAC is registered as a possible outcome. 
**Console or MCM** - You can use `set DAC_Captured to 1` or MCM setting "Currently Captured". Targets closest non-follower NPC.

### Other mod patches
**Captive Player** - When Captive Player would trigger its own outcome (move you to another dungeon or Simple Slavery), it instead triggers DAC's capture and you stay in the dungeon.
**SL Kidnapped Redux** - When SLKR would trigger its outcome (Simple Slavery or return you back outside), it instead triggers DAC's capture and you stay in the dungeon.

**Only humans can take you captive by default**. Includes "humans, elfs, beast races and vampires". It's an MCM setting. Turn off at your own risk.

## How captivity can end

**Your captor dies** - Captivity ends, you can loot your stuff back.
**Captor loses interest** - Optional, game-hours timer - when itruns out, you are free.
**AI releases you (DAC_ReleaseCaptive)** - AI releases you and returns your gear. Must use your current captor.
**Run away** - Optional. When you stray too far from your captor, captivity ends. Your items are not returned, they stay in the captor's inventory.
**Console or MCM** - "set DAC_Captured to 0", or disable the "Currently Captured" MCM setting.

# SkyrimNet integration
**DAC_TakeCaptive** - An NPC can decide to capture you. Does nothing if you are already captured. 
**DAC_ReleaseCaptive** - Must use your actual captor, ends your captivity and returns gear.
**DAC_BecomeAlly** - A captor can turn on their own people and side with you. Only valid if you are captured.

**Character context** - you know you're a prisoner. The captor knows they hold you. Bystanders are aware of what's happening. Separate text for thoughts, dialogue and narration.
Capture and release are registered as memories, so NPCs remember it happened.

Everything under `SKSE/Plugins/SkyrimNet/` can be edited as you like. WARNING - if you also use the DAC Captive Player patch, it is shipping its own copy of `config/actions/dac_takecaptive.yaml`. If you want to edit it, edit the patch's copy.

## MCM Settings - Defeat and Capture

I tried to make this mod fully customizable, so you can enable only the features you want. Settings also persist between saves.

### General:

**Defeat and Capture enabled** - Master switch. Turn this OFF and the mod does nothing at all - no capture from any route, no keeping you Essential, and if you are captured when you switch it off you are first released. However, existing Allies are kept persistent.
Also use during quests when the player is expected to be defeated, or generally when it's not desired to be captured. 

**Capture when below % HP** - 0 = off, and bleedout is the only self-trigger. Above 0, any hit that leaves you at or below this percentage of your health captures you immediately. Bleedout only happens if something keeps you alive long enough to reach it - a single overwhelming blow skips it entirely, and this catches that. Ignored in External-only trigger mode.

**Trigger mode**
  **Standalone (own bleedout)** - Fires capture from player's own bleedout. 
  **External only (other mods)** - Waits for another mod to hand off (like Yamete REDUX).
  **Both** - Accepts both triggers.

**Player Essential (manage bleedout)** - ON: you are kept Essential, so a killing blow drops you into bleedout instead of killing you, and you are stood back up at the health value set below. OFF: you can die normally and whatever else you run - Respawn, Acheron, another defeat mod - owns that moment instead. Turn it off if another defeat mod already manages bleedout; two mods fighting over it might misbehave. 

**Health after bleedout** - The health you get back when the mod lifts you out of bleedout. A defeated player's health can be deeply negative, so the deficit is cancelled first and this value added on top.

**Captor search radius** - How far around you the mod looks, in game units. 0 searches the whole cell. This is not only about finding your captor - it also decides who stands down when you are captured, who gets pulled out of combat first, and who is picked up by the periodic re-scan. Too small and enemies a few paces away keep fighting; too large and a group you never met is dragged into the truce. 3000 is roughly a camp or a dungeon room.

**Humanoids Only** - ON: a captor must be a person - human, beast race or a vampire. Animals and creatures are skipped. If the only thing standing over you is a wolf, no capture happens at all. OFF: whatever won the fight takes you, which is what a mudcrab stripping your gear looks like.

**Captor takes your gear** - Everything you are carrying is transferred to your captor when they capture you. Quest items are left alone. Your belongings are returned only in specific cases. Otherwise they stay on whoever took them, so loot or pickpocket them back. Each captor's haul is tracked separately, so being robbed twice does not lose the first lot. If your captor turns into your ally, he gives you your items back.

**Currently captured** - Live state. Switch OFF to free yourself. Switch ON to force a capture by the nearest NPC.

**Distance breaks the capture** - Off by default. While ON, moving too far from your captor breaks the hold - you get free and their group turns hostile again. Captor keeps your items.

**Safe Distance** - How far you can move from your captor, in game units. Roughly: 1000 = same room, 2500 = a camp, 5000 = across a small hold. You get a warning notification at three quarters of this.

**Captor loses interest after (hours)** - Game-hours before your captor gives up and lets you go. This counts as a normal release, so if you were bound, you get the key back. 0 means never - captivity lasts until something else ends it.

**Surrender hotkey** - Press to give up a fight and be taken prisoner on the spot. If you have the SL Kidnapped Redux patch, it instead stops you resisting so the abduction proceeds without you waiting to be hit.

**Captors stay friendly after release** - ON: when a captor lets you go, everyone who was under the truce becomes an ally instead of turning hostile. Use this if you want to roleplay as joining their group. They then behave exactly like anyone you marked with the Mark Ally power, so later you can drop them individually or with "Forget all allies". I recommend you turn it off right after so future bandit groups don't get added too. OFF: the truce ends with the captivity and they treat you as an enemy again. Escaping never keeps anyone friendly, whatever this is set to.

**Grant the Mark Ally power** - Adds a lesser power called Mark Ally. Look at someone and cast it to make them a permanent ally - they stay friendly no matter what happens to everyone else around them. Cast it at the same person again to drop them. Also stops generic NPCs from despawning on cell resets. There are 16 persistent Ally slots. You can have more allies, but the rest won't survive cell resets.

**Manage allies** - Opens a list with all current Allies, selecting any of them removes them. Alternatively use the Mark Ally power.

**Forget all allies** - Drops everyone you have marked as an ally, all at once, and switches itself back off when you close this menu. Affects only their "friendly" state - they will attack if they were hostile before.

**Clear persistent allies** - Allies are held by the game so they are never cleaned up when a dungeon resets - that is what stops a bandit you befriended quietly ceasing to exist, along with everything the AI remembered about them. There are 16 slots. Switch this on to release every held reference at once; it clears itself when you close this menu. Only do this if you no longer care whether your allies survive.

**Allies hand back what they took** - ON: when someone becomes your ally, anything they personally took from you is returned on the spot.

**Followers on player defeat:**
  **Keep fighting** - Followers keep fighting. If they are defeated, they get captured by enemies as well.
  **Pacified with you** - Followers stop fighting but are not captured.
  **Captured with you** - They instantly surrender and are captured. (Surrender hotkey does this regardless.)

### NSFW Settings:

**Captor binds you** - Your captor locks leather cuffs and a collar on you and KEEPS THE KEY. Certain releases give you the key, otherwise you keep the restraints on (like escaping). If you use SkyrimNet UDNG, you may prefer to leave this off and let the AI decide when to bind you. Or to add more.

### Compatibility:

**Take over when SLKR would release you** - Off by default. SL Kidnapped Redux normally ends a kidnapping by selling you to Simple Slavery or teleporting you back. With this on, you instead stay where you are as a prisoner of the people who took you, and have to get out yourself. Its own scenes play out untouched - this only replaces what happens afterwards. Ignored if SLKR is not installed.
REQUIRES: DefeatAndCapture_SLKR.esp, SL Kidnapped Redux's own "sold into slavery" chance not set to 100 in ITS MCM. 

**Confirm captures** - ON: the mod shows a summary box when a capture lands, and asks first - naming who is taking you and why, with options to Allow or Deny.

**Get back your stuff** - Recovery tool. Hands back everything recorded as taken, from EVERY captor who ever robbed you - not just the most recent. Use it if a captor died somewhere you cannot reach. Does nothing if there is no record, or if they no longer have the items.

### Experimental:

**Simple Slavery when time runs out** - Experimental. Requires the **Captor loses interest after (hours)** setting to be set above 0. If you don't escape before the timer runs out, DAC will end the capture and send you to Simple Slavery.  

## MCM Settings - DAC - SLKR Patch

**Skip forced adult scenes** - ON: you are still ambushed, taken, stripped and held - but no forced SL/OStim scene starts, and the captivity resolves straight into DAC's own capture. Intended for SkyrimNet users who want the abduction as a roleplay setup with nothing forced.

**Player-only Scenes** - ON: no NPC-NPC scenes between captors and captives.

**Skip unfitting devices on men** - ON: male prisoners are never given plugs, chastity belts, chastity bras or piercings. They can still be gagged, collared, blindfolded, corseted, cuffed at the arms or legs, and put in an armbinder or yoke. OFF: SL Kidnapped Redux's original behaviour, anything on anyone.

**Device limit** - How many devices a single captivity may put on you. Set to 0 for no limit.

## MCM Settings - DAC - Captive Player Patch

**Trigger DAC when done** - ON: when Captive Player would move you to another dungeon or trigger one of its outcomes, it instead stops quietly and DAC makes a nearby enemy capture you - you stay in the dungeon. OFF: Captive Player resolves normally.

**Time between events** - Percentage of Captive Player's normal wait between captivity events. 100 is default - roughly two game hours each, and there are six to eight events before it can end. Lower it if the waiting gets in the way of roleplay.

**Forced free camera** - ON is Captive Player's normal behaviour: it switches you to the free camera every time it seats you in restraints. OFF leaves your camera alone, so you can stay in first person.

**Force skip to DAC** - Captive Player will not end a captivity until several events have played out, and that is the only route to DAC. Turn this on while held in restraints (not during scenes) to jump straight to the ending where DAC takes over. The setting switches itself back off once it fires.

## MCM Settings - DAC - Leash Framework Patch

**Leash you on capture** - Master switch for the whole leash module. ON: you - and any follower captured alongside you - are collared and leashed to your captor the moment you are taken, and AI may put on, take, tie off or cut a leash. OFF: nothing is applied on capture, to you or your followers, AND the four NPC leash actions stop being offered to AI. A leash from another mod is untouched either way. Turning this off does not remove a leash already on you - use Remove all leashes below.

**Remove all leashes** - Cuts every rope right now - yours and your followers' - and takes off the collar, then switches itself off when you close this menu. Use if an NPC leashes you at an inappropriate moment. This does NOT end the captivity.

**Attached to** - Your captor: he holds the rope and you are dragged along behind him. The capture spot: the rope is tied off where you were taken.

**Leash length** - How far you can get before the rope stops you, in game units. Roughly 100 units is a long stride. Shorter keeps you at your captor's heel; longer lets you wander the room.

**Free distance** - How much of the leash length you can move freely inside before the rope starts pulling, as a percentage. Low values mean the rope hauls you back almost at once; high values mean it only catches you at the very end. Clamped to 10-95: at 0 the rope drags you into your captor and at 100 it never pulls at all.

**Leash type** - The item the rope attaches to. All three neck collars sit on slot 45 - the same slot Devious Devices uses for its own collar. The base mod stands aside for you: pick a neck option with this module switched on, and the captor's DD restraints skip their collar so theirs fits. Any OTHER mod holding slot 45 will still win, and if your choice cannot be worn the body rope is used instead so a leash is never left attached to nothing.

## For mod authors

```
SendModEvent("DAC_Suppress", "", 1.0)   ; stand down
SendModEvent("DAC_Suppress", "", 0.0)   ; resume
```
Or set the `DAC_Suppressed` global directly. While suppressed there is no capture from any route and no bleedout recovery, so your scene keeps the outcome it is watching for. No hard dependency either way — if this mod is absent, the event goes unheard.

**The standard `dhlp-Suspend` / `dhlp-Resume` pair works too**, so if your mod already raises it you need to do nothing at all — this listens for it. A suspend that never receives its Resume lapses on its own after an hour of real time, so a lost Resume cannot disable this mod for the rest of the playthrough.

**What suppression does and does not do.** 
No capture fires, and the player is not stood back up — your scene keeps the defeated player it is watching for. But the **Essential flag stays on**, so they still cannot die. That split is deliberate: a mod that wants the player beaten almost always wants them alive to see the outcome. If your mod genuinely needs the player able to die, they must turn *Player Essential* off themselves; suppression will not do it.

### State exposed to other mods

| Where | Key | Meaning |
|---|---|---|
| Global | `DAC_Captured` | 0 = free, 1 = captured |
| Global | `DAC_ModEnabled` | 0 = the whole mod is stood down |
| Global | `DAC_Suppressed` | set to 1 to silence it temporarily — see the section above |
| StorageUtil (player, int) | `DAC_Captured` | same as the global |
| StorageUtil (player, form) | `DAC_Captor` | the capturing actor |
| StorageUtil (captor, int) | `DAC_IsCaptor` | 1 while holding you |
| Faction | `DAC_TruceFaction` | you and everyone standing down around you |
| Faction | `DAC_AllyFaction` | your permanent allies, captive or not |
| Mod event | `DAC_OnCapture` | sent when a capture completes. The captor is on the player as StorageUtil form `DAC_Captor` |
| Mod event | `DAC_OnRelease` | sent on release. `numArg` is 1 when it was an **escape** rather than a mercy release |

## Known limitations

- No containment (beyond the leash). Nothing physically stops you from walking away. NPCs do become hostile if you go too far (if they were hostile before capture).
- SkyrimNet prompts - work most of the time, certainly could be refined more. Work in progress.
- Not that many interesting mechanics for non-SkyrimNet users.
- If any quests expect the player to be defeated, there might be a conflict. Report such cases when you find them.

## Final thoughts

What started as a quick experiment turned into this wall of text you have just read. 

Anyone can do as they please with this mod, as long as you use the same licence and credit me. 
