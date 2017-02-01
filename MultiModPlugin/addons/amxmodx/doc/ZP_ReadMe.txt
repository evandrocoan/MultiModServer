/*================================================================================
	
		*****************************************************
		************** [Zombie Plague Mod 5.0] **************
		*****************************************************
	
	----------------------
	-*- Licensing Info -*-
	----------------------
	
	Zombie Plague Mod
	Copyright (C) 2008-2011 by ZP Dev Team
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	In addition, as a special exception, the author gives permission to
	link the code of this program with the Half-Life Game Engine ("HL
	Engine") and Modified Game Libraries ("MODs") developed by Valve,
	L.L.C ("Valve"). You must obey the GNU General Public License in all
	respects for all of the code used other than the HL Engine and MODs
	from Valve. If you modify this file, you may extend this exception
	to your version of the file, but you are not obligated to do so. If
	you do not wish to do so, delete this exception statement from your
	version.
	
	-------------------
	-*- Description -*-
	-------------------
	
	Zombie Plague is a Counter-Strike server side modification, developed as
	an AMX Mod X plugin, which completely revamps the gameplay, turning the
	game into an intense "Humans vs Zombies" survival experience.
	
	Even though it's strongly based on the classic zombie infection mods, it
	takes the concept to a new level by introducing:
	
	* New Gameplay Modes: Nemesis, Survivor, Multi Infection, Swarm, and more
	* Zombie Classes System: allows addding unlimited custom zombie classes
	* Human Classes System: allows addding unlimited custom human classes
	* Ammo Packs: awarded to skilled players, can be exchanged for goods
	* Extra Items System: allows adding unlimited custom items to buy
	* Custom Grenades: Napalms, Frost Nades, Flares, and Infection Bombs
	* Deathmatch Mode: where zombies or humans can continually respawn
	* Admin Menus: to easily perform the included console commands
	* Special Effects: from the HL Engine, such as dynamic lighting and fog
	
	There is plenty of customization as well, which enables you to create
	several different styles of gameplay. You can:
	
	* Set zombies and humans' health, speed, models, rewards, and more
	* Toggle unlimited ammo and adjustable knockback for weapons
	* Separately enable and customize the new gameplay modes to your liking
	* Change overall map lighting (lightnings available for the dark settings)
	* Set different colors and sizes for flashlight and nightvision
	* Toggle leap (long jumping) and pain shock free (no damage slowdowns)
	* Toggle various infection effects, such as sparks and screen shakes
	* Enable random spawning (CSDM-spawn friendly)
	* Replace sounds or add some background themes
	* And many more...
	
	-------------
	-*- Media -*-
	-------------
	
	* Gameplay Video 1: http://www.youtube.com/watch?v=HFUyF7-_uzw
	* Gameplay Video 2: http://www.youtube.com/watch?v=XByif6Mti-w
	
	--------------------
	-*- Requirements -*-
	--------------------
	
	* Mods: Counter-Strike 1.6 or Condition-Zero
	* AMXX: Version 1.8.0 or later
	
	--------------------
	-*- Installation -*-
	--------------------
	
	Extract the contents from the .zip file to your server's mod directory
	("cstrike" or "czero"). Make sure to keep folder structure.
	
	-----------------------
	-*- Official Forums -*-
	-----------------------
	
	For the official Zombie Plague forums visit:
	http://forums.alliedmods.net/forumdisplay.php?f=126
	
	There you can:
	
	* Get the latest releases and early betas
	* Discuss new features and suggestions
	* Share sub-plugins (expansions) for the mod
	* Find the support and help you need
	* Report any bugs you might find
	* And all that sort of stuff...
	
	-------------------------------
	-*- CVARS and Customization -*-
	-------------------------------
	
	For a complete and in-depth cvar list, look at the zombieplague.cfg file
	located in the amxmodx\configs directory.
	
	Additionally, you can change player models, sounds, weather effects,
	and some other stuff from the configuration file zombieplague.ini.
	
	As for editing attributes of classes or custom extra items, you'll find
	a zp_zombieclasses.ini, zp_humanclasses.ini, and zp_extraitems.ini. These
	files will be automatically updated as you install new custom classes or
	items with new entries for you to edit conveniently.
	
	----------------------
	-*- Infection Mode -*-
	----------------------
	
	On every round players start out as humans, equip themselves with a few
	weapons and grenades, and head to the closest cover they find, knowing
	that one of them is infected with the T-Virus, and will suddenly turn
	into a vicious brain eating creature.
	
	Only little time after, the battle for survival begins. The first zombie
	has to infect as many humans as possible to cluster a numerous zombie
	horde and take over the world.
	
	Maps are set in the dark by default. Humans must use flashlights to light
	their way and spot any enemies. Zombies, on the other hand, have night
	vision but can only attack melee.
	
	--------------------------
	-*- New Gameplay Modes -*-
	--------------------------
	
	* Nemesis:
	   The first zombie may turn into a Nemesis, a powerful fast-moving
	   beast. His goal is to kill every human while sustaining the gunfire.
	
	* Survivor:
	   Everyone became a zombie except him. The survivor gets a machinegun
	   with unlimited ammo and has to stop the never-ending army of undead.
	
	* Multiple Infection:
	   The round starts with many humans infected, so the remaining players
	   will have to act quickly in order to control the situation.
	
	* Swarm Mode:
	   Half of the players turn into zombies, the rest become immune and
	   cannot be infected. It's a battle to death.
	
	* Plague Mode: [bonus]
	   A full armed Survivor and his soldiers are to face Nemesis and
	   his zombie minions. The future of the world is in their hands.
	
	--------------------
	-*- In-Game Menu -*-
	--------------------
	
	Players can access the mod menu by typing "zpmenu" on chat, or by
	pressing the M ("chooseteam") key. The menu allows players to choose
	their zombie/human class, buy extra items, or see the ingame help.
	Admins will find an additional option to easily perform all console
	commands.
	
	----------------------
	-*- Admin Commands -*-
	----------------------
	
	The following console commands are available:
	
	* zp_zombie <target> - Turn someone into a Zombie
	* zp_human <target> - Turn someone back to Human
	* zp_nemesis <target> - Turn someone into a Nemesis
	* zp_survivor <target> - Turn someone into a Survivor
	* zp_respawn <target> - Respawn someone
	* zp_start_game_mode <game mode id> - Start specific game mode, IDs from 0 to [total modes - 1]
	
	------------------
	-*- Plugin API -*-
	------------------
	
	From version 3.6, some natives and forwards have been added to ease the
	development of sub-plugins, though you may also find them useful to work
	out compatibility issues with existing plugins.
	
	Look for the include files in your amxmodx\scripting\include folder
	for the full documented list.
	
	----------------------
	-*- Zombie Classes -*-
	----------------------
	
	From version 4.0 it is possible to create and add an unlimited number of
	zombie classes to the main mod. They can be made as separate plugins,
	by using the provided zombie class API, and easily distributed.
	
	By default, these zombie classes are included:
	
	* Classic Zombie: well balanced zombie for beginners.
	* Raptor Zombie: fast moving zombie, but also the weakest.
	* Light Zombie: light weighed zombie, jumps higher.
	* Fat Zombie: slow but strong zombie, with lots of hit points.
	* Leech Zombie: regains additional health when infecting.
	* Rage Zombie: has been affected by radioactivity.
	
	-------------------
	-*- Extra Items -*-
	-------------------
	
	From version 4.0 it is possible to add an unlimited number of items
	which can be purchased through the Extra Items menu. All you need
	to do is use the provided item registration natives on your custom
	plugins. You can set the name, the cost in ammo packs, and the team
	the extra item should be available for.
	
	By default there is a number of items already included, listed here:
	
	* Night Vision: makes you able to see in the dark for a single round [Human]
	* T-Virus Antidote: makes you turn back to your human form [Zombie]
	* Zombie Madness: you develop a powerful shield for a short time [Zombie]
	* Infection Bomb: infects anyone within its explosion radius [Zombie]
	
	You are also able to choose some weapons to act as extra items in the
	customization file (zombieplague.ini).
	
	---------------
	-*- Credits -*-
	---------------
	
	* AMXX Dev Team: for all the hard work which made this possible
	* Imperio LNJ Community: for providing the first server where I
	   could really test the plugin and for everyone's support
	* Mini_Midget: for his Zombie Swarm plugin which I used for reference
	   on earliest stages of development
	* Avalanche: for the random spawning code I got from GunGame and the
	   original Frostnades concept that I ported in here
	* cheap_suit: for some modelchange and knockback codes that I got from
	   Biohazard
	* Simon Logic/ConnorMcLeod: for the Pain Shock Free feature
	* KRoT@L: for some code from Follow the Wounded, used to make the zombie
	   bleeding feature
	* VEN: for Fakemeta Utilities and some useful stocks
	* RaaPuar and Goltark: for the custom grenade models
	* Orangutanz: for finding the precached modelindex offset
	* ML Translations: DKs/nunoabc/DarkMarcos (bp), JahMan/KWo (pl), DA (de),
	   Zombie Lurker (ls), DoPe^ (da), k1nny (fr), NeWbiE' (cz), skymoon (tc),
	   SUPER MATRIX/Shidla/zDemon/4eRT (ru), zsy314 (cn), lOlIl/Seehank (sk),
	   Bridgestone (sv), crazyeffect.net/Mave/Wesley (nl), hleV/aaarnas (lt),
	   darkbad945 (bg), decongamco (vn), beckham9224 (mn), TehGeorge (gr),
	   shadoww_ro/tuty/georgik57/EastSider (ro)
	* Beta testers: for all the feedback, bug reports, and suggestions which
	   constantly help improve this mod further
	* And to all zombie-mod supporters out there!
	
	-----------------
	-*- Changelog -*-
	-----------------
	
	* v1.0: (Dec 2007)
	   - First Release: most of the basic stuff done.
	   - Added: random spawning, HP display on hud, lighting setting,
	      simple buy menu, custom nightvision, admin commands, Nemesis
	      and Survivor modes, glow and leap settings for them.
	
	* v2.2: (Jan 2008)
	   - Added: zombie classes, ammo packs system, buying ammo for weapons,
	      custom flashlight, admin skins setting, zombieplague.cfg file
	   - Upgraded: weapons menu improved, flashlight and nightvision colors
	      now customizable, HamSandwich module used to handle damage.
	   - Fixed various bugs.
	
	* v3.0: (Mar 2008)
	   - Added: door removal setting, unstuck feature, human cvars, armor
	      cvar for zombies, weapon knockback, zombie bleeding, flares,
	      extra items (weapons, antidote, infection bomb), pain shock
	      free setting, Multiple Infection and Swarm modes.
	   - Upgraded: dumped Engine, Fun and Cstrike modules, code optimized,
	      new model change method, new gfx effects for zombie infections.
	   - Fixed a bunch of gameplay bugs.
	
	* v3.5: (May 2008)
	   - Added: deathmatch setting with spawn protection, unlimited ammo
	      setting, fire and frost grenades, additional customization cvars,
	      new extra items, help menu.
	   - Upgraded: better objectives removal method, dropped weapons now
	      keep their bpammo, code optimized a lot.
	   - Fixed: no more game commencing bug when last zombie/human leaves,
	      no more hegrenade infection bug, reduced svc_bad errors, and
	      many more.
	
	* v3.6: (Jun 2008)
	   - Added: a few natives and forwards for sub-plugins support,
	      zombie classes can now have their own models, additional
	      knockback customization, bot support, various CVARs.
	   - Upgraded: extra items now supporting grenades and pistols, changed
	      bomb removal method, players can join on survivor/swarm rounds,
	      extended lightnings support to other dark settings.
	   - Fixed: a bunch of minor bugs, and a server crash with CZ bots.
	
	* v4.0: (Aug 2008)
	   - Added: new gameplay mode (Plague Mode), option to remember weapon
	      selection, command to enable/disable the plugin, more CVARs.
	   - Upgraded: redid all the menus, extra items and zombie classes now
	      support external additions, survivor can now have its own model,
	      upgraded model changing method.
	   - Fixed: some bugs with bots, win sounds not being precached.
	
	* v4.1: (Oct 2008)
	   - Added: more CVARs, more customization, more natives, custom
	      leap system, admin zombie models support, and more.
	   - Upgraded: custom grenades compatible with Nade Modes, ambience
	      sounds specific game mode support, optimized bandwidth usage
	      for temp ents, admin commands logged with IP and SteamID.
	   - Fixed: lots of bugs (some minor, some not)
	
	* v4.2: (Feb 2009)
	   - Added various CVARs for customization, improved prevention of
	      svc_bad in some cases, optimized ammo handling code.
	   - Fixed server crash with 'msg 35 has not been sent yet' error,
	      fixed client overflow issues with ambience sounds, resolved
	      many gameplay bugs.
	
	* v4.3: (Apr 2009)
	   - Customization settings can now be edited through external files,
	      added support for global and multiple random zombie models,
	      added even more CVARs for tweaking stuff, extended admin commands'
	      functionality, greatly extended API capabilities, implemented a
	      more efficient Pain Shock Free code, reworked some menus.
	   - Fixed pretty much all reported bugs to the date.
	
	* v5.0: (Sep 2011)
	   - Redid the entire Mod: there is now a separate plugin/module for
	      each set of features, added support for custom Game Modes,
	      added support for custom Human Classes, added CVARs for
		  extensive customization, added ability to fully switch
		  between Ammo Packs and CS Money, extended ML support to
		  custom items/classes/modes.
	   - Bug fixes.
	
=================================================================================*/