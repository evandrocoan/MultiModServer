Monster - Version 3.00.00 (June 30th, 2002)

Monster is a metamod (www.metamod.org) plugin that will allow you to add
some of the monsters from the Half-Life single player game into other MODs.

To set up Monster you should first make sure you have metamod installed and
configured properly for your server.  If you have installed AdminMOD, you will
already have metamod installed and configured.  If you have not installed
metamod, you can download it from the metamod web site at...

http://www.metamod.org/


Metamod installation for Windows servers:

Copy the metamod.dll file to the MODs dlls folder (the default for Team
Fortress 1.5 is C:\SIERRA\Half-Life\tfc\dlls, the default for Counter-Strike
is C:\SIERRA\Half-Life\cstrike\dlls, and the default for Half-Life deathmatch
is C:\SIERRA\Half-Life\valve\dlls).  Then, using any text editor (like Notepad),
modify the liblist.gam file in the MODs folder and change the "gamedll" entry
so that it uses the "metamod.dll" file instead of the game DLL file.  For
example, to change the Half-Life deathmatch liblist.gam file in the "valve"
folder, you would have this...

//gamedll "dlls\hl.dll"
gamedll "dlls\metamod.dll"

...I have commented out the original gamedll line and added a new gamedll line
that specifies "dlls\metamod.dll" as the file to load.  You should now be able
to start the server and you should see something like this...

   Metamod version 1.12.20, Copyright (c) 2001 Will Day <willday@metamod.org>
   Metamod comes with ABSOLUTELY NO WARRANTY; for details type `meta gpl'.
   This is free software, and you are welcome to redistribute it
   under certain conditions; type `meta gpl' for details.


Metamod installation for Linux servers:

Copy the metamod_i386.so file to the MODs dlls directory (for example
/usr/hlds_l/tfc/dlls for Team Fortress 1.5, /usr/hlds_l/cstrike/dlls for
Counter-Strike, or /usr/hlds_l/valve/dlls for Half-Life deathmatch).  Then
modify the liblist.gam file in the MODs directory and change the
"gamedll_linux" entry so that it uses the "metamod_i386.so" file instead
of the game DLL file.  For example, to change the Half-Life deathmatch
liblist.gam file in the "valve" directory, you would have this...

//gamedll_linux "dlls/hl_i386.so"
gamedll_linux "dlls/metamod_i386.so"

...I have commented out the original gamedll line and added a new gamedll line
that specifies "dlls/metamod_i386.so" as the file to load.  You should now be
able to start the server and you should see something like this...

   Metamod version 1.12.20, Copyright (c) 2001 Will Day <willday@metamod.org>
   Metamod comes with ABSOLUTELY NO WARRANTY; for details type `meta gpl'.
   This is free software, and you are welcome to redistribute it
   under certain conditions; type `meta gpl' for details.


Configuring Metamod to work with plugins:

First, copy the monster_mm.dll file into the same dlls folder where you put
the metamod.dll file (for Linux, copy the monster_mm_i386.so to the same
directory where you copied the metamod_i386.so file).

Then, you will need to create a file called "metamod.ini" in the MODs folder
(the same place where the liblist.gam file is found).  You can create this
file with any text editor.  You will want it to contain these two lines...

win32 dlls/monster_mm.dll
linux dlls/monster_mm_i386.so

...IMPORTANT!!!  Note that both win32 and linux use FORWARD SLASHES '/' when
specifying the plugin filename.  Don't use the backslash '\' for Windows.

Now when you start the server, you should see the Metamod banner message
and right after it, you should see the MONSTER banner message, like this...

[MONSTER] Monster v3.00.00, 06/30/2002
[MONSTER] by botman <botman@planethalflife.com>


Configuring Monster for specific maps:

Now you will want to create configuration files for Monster to use when
loading a map.  When a map loads, Monster will look for a configuration file
that is specifically made for that map.  The filename for these map specific
configuration files will be in the following format "mapname_monster.cfg"
(where "mapname" is the name of the BSP map file).  These map specific
configuration files MUST be in the maps folder found inside the MOD folder.
For example, if you wanted to create a map specific configuration file for
the map 2fort in Team Fortress 1.5, the file would be...

C:\SIERRA\Half-Life\tfc\maps\2fort_monster.cfg

The map specific Monster configuration files allow you to add monsters to
the map by specifying a spawn point (the origin), a respawn delay (time
to wait before spawning the monster after it dies), an angle (the direction
to face when spawning) or an angle_min and angle_max (a minimum and maximum
range of angles to randomly select from when spawning), and the types of
monsters that you want to spawn at that location (chosen randomly from the
ones provided).  Here's a couple of example entries in a .cfg file...

{
origin/-420 -700 -300
delay/10
angle/45
monster/barney
monster/hassassin
monster/hgrunt
monster/scientist
monster/snark
}

{
origin/475 560 -300
delay/30
angle_min/90
angle_max/270
monster/agrunt
monster/bullsquid
monster/headcrab
monster/houndeye
monster/islave
monster/snark
monster/zombie
}

{
origin/-540 -800 240
delay/5
monster/hgrunt
}

...This will create 3 monster spawn points.  Notice the opening and closing
braces '{' and '}'.  These must be at the beginning and ending of a spawn
point group and MUST be on lines by themselves.

The first group will create a monster spawn point at location (-420 -700 -300)
in the map.  This monster will respawn 10 seconds after it has been killed.
It will spawn facing a direction of 45 degrees.  When the monster spawns, the
Monster plugin will randomly select from "barney", "hassassin" (the black
"ninja" babes), "hgrunt" (the human military grunts), "scientist" or "snark".
The monster will spawn, stand there (or run around depending on the type of
monster), and will attack players that come within range (the scientists don't
attack players, but any barney monsters that get spawned will attack players).

The second group will create a monster spawn point at location (475 560 -300)
in the map.  This monster will respawn 30 seconds after it has been killed.
It will spawn facing an angle between 90 degrees and 270 degrees (which will
be randomly chosen at spawn time).  When the monster spawns, the Monster
plugin will randomly select from "agrunt" (the big alien grunts that shoot
the hornet gun), "bullsquid" (the big spotted chick-looking thing with
tentacles over its mouth), "headcrab", "houndeye" (the small dog-like monster
that runs around on 3 legs), "islave" (the alien slave monster that shoots
lightning bolts), "snark", and "zombie" (the tall alien monster that slashes
at you with its claws).

The third group will create a monster spawn point at location (-540 -800 240)
in the map.  This monster will respawn 5 seconds after it has been killed.
Since the angle, angle_min and angle_max haven't been specified, the monster
will face a random direction when spawning.  The monster that will be spawned
will always be an "hgrunt" (since it's the only choice).

The valid fields in each group are:

origin - The X, Y, and Z coordinates in the map for the spawn point location.

delay - The amount of time (in seconds) to delay before respawning a monster
        after it gets killed.

angle - The angle (0 to 360) in degrees of the direction you want the monster
        to face when spawning.

angle_min - The minimum angle (0 to 360) in degrees of the direction you want
            the monster to face when spawning.  You must also specify the
            angle_max value.  A direction will be chosen randomly between the
            angle_min and angle_max values.

angle_max - The maximum angle (0 to 360) in degrees of the direction you want
            the monster to face when spawning.  You must also specify the
            angle_min value.  A direction will be chosen randomly between the
            angle_min and angle_max values.

monster - The name(s) of the monster that you want to spawn at this spawn
          point.  Each time a monster respawns, one of the monsters from this
          list will be chosen.

          Note: if you want one type of monster to spawn more often than other
          types of monsters you can include that name more than once.  For
          example...

          {
          origin/720 -60 -90
          delay/10
          monster/barney
          monster/hgrunt
          monster/hgrunt
          monster/hgrunt
          }

          ...would cause the hgrunt monster to spawn 3/4th of the time and
          a barney monster to spawn 1/4th of the time.

          You can only have 20 "monster" fields for each monster spawn group.


You can have a maximum of 100 monster groups in each Monster .cfg file.

There are some example Monster .cfg files included for TFC that you can look
at for some examples.


Configuring the Monster skill (health and damage):

Copy the monster_skill.cfg file from the monster_plugin directory to the
MOD directory (i.e. Half-Life\valve, Half-Life\tfc, or Half-Life\cstrike)
and then open the monster_skill.cfg file with any text editor.  You can
change the health or damage amounts for each monster to cause monsters
spawned in the game to have greater (or less) health and to cause more
(or less) damage to players (and other monsters).  If the monster_skill.cfg
file does not exist in the MOD directory, default values will be used for
the health and damage amounts of the monsters.


Configuring Monster to log monsters added to the map:

You can configure the Monster plugin so that it will log the monsters that
were added to a map.  To do this you will need to create a file called
"metaexec.cfg" in the MODs folder (where the liblist.gam file and the
metamod.ini file is located).  In this metaexec.cfg file you will need to
add the following line...

monster_log 1

...save this file.  Then you will need to enable logging when you start up
your server.  This can be done by adding "+log on" on the command line when
starting your server.  The log files will be placed in a "logs" folder in
the MOD folder (for example C:\SIERRA\Half-Life\cstrike\logs).

If you want to turn off the Monster plugin logging, you can change the
"monster_log" setting from "1" to "0" in the metaexec.cfg file.  To turn
off logging completely, remove the "+log on" from the command line.


Creating monsters near players in the game:

In order to spawn monster near a player, the monster must be precached
(loaded into memory) at the time the map is loaded by the server.  You
will need to copy the "monster_precache.cfg" file from the monster_plugin
directory into the MOD subdirectory (i.e. Copy monster_plugin.cfg to
the Half-Life\cstrike directory for Counter-Strike.  Copy it into the
Half-Life\tfc directory for Team Fortress 1.5.  Copy it into the
Half-Life\dod directory for Day of Defeat, etc.).  Now edit the
monster_precache.cfg that you copied into the MOD directory using any
text editor and uncomment the names of the monsters that you want to
precache when each map is loaded (uncomment the monster names by
removing the two forward slash characters at the start of a line).

WARNING: Precaching too many monsters can cause problems in some MODs!
Each monster has models and sounds that are required by the monster
and these models and sounds take up memory on the server and memory
on the client.  If clients are crashing and seeing the error message
"S_Findname: Out of sfx_t", then you are precaching too many monsters
on the server.  Remove some of these monsters from the monster_precache.cfg
file and remove them from map specific monster .cfg file for the map
where the problems occurred (i.e. if clients are crashing when running
the map blastwar.bsp, the you may need to remove some of the monsters
from the blastwar_monster.cfg file).  Each type of monster is only
precached once (but each monster may have several models or sounds
associated with it).  When you remove a monster from the map specific
monster .cfg file, you need to remove ALL monsters with that name.
For example, if you had a .cfg file with 10 hgrunt monsters and were
getting the "Out of sfx_t", it would not be sufficient to remove just
one or two of the hgrunt monsters from the .cfg file.  You must remove
them ALL to prevent the hgrunt monster models and sounds from getting
precached on the server and clients.  When adding monsters to a map,
you should add monsters a few at a time and play that level with
several clients for a while before adding more monsters to that map.
The more monsters you add to the monster_precache.cfg or map specific
monster .cfg file, then more likely you are to cause the clients to
crash with the "Out of sfx_t" error message.

You can spawn monsters from the console using the "monster" command.  The
"monster" command should be followed by the name of the monster you wish to
spawn and the name of the player you wish to spawn the monster next to (or
you can use the player index # from the "status" command).  You can enter
"monster" (without the quotes) to get a list of the valid monster names that
can be spawned.  If the player's name contains a space, you will need to use
double quotes around the player's name.  Here's some examples of using the
"monster" command...

monster agrunt Player(1)
monster hassassin "The Dark Avenger"
monster snark #4

You can only spawn monsters next to players that are alive and not in
observer mode.  If there is not enough room to spawn a monster next to a
player, you will see a message telling you this.  Wait until the player
moves into a more open area and try spawning a monster again.


Enabling or disabling monster spawning:

You can use the server CVAR "monster_spawn" to enable or disable the spawning
of monsters in a level.  The CVAR "monster_spawn" is set to 1 (to enable
monster spawning) by default.  You can change the "monster_spawn" CVAR to 0
disable monster spawning and monsters will stop respawning.  This will not
remove any existing monsters that have already spawned into the level.  You
can display the current value of the CVAR by entering "monster_spawn" (without
quotes) on the console.


Some general tips on adding monsters:

You might wonder, "How do I know what origin to use when adding a monster to
a map file?".  The easiest way to determine an origin in a map file is to
load that map in Half-Life, then pull down the console (using the '~' key)
and enter "status" and press ENTER.  Make SURE you have started the server
on your PC by creating a LAN server (i.e. Multiplayer, LAN game, Create game)
or your won't get X, Y, and Z coordinates using the "status" command.

This will display a line similar to the following...

hostname:   TheKillingGrounds
version :   45/1.1.0.8 1786
tcp/ip  :   245.20.53.173:27015
map     :   boot_camp at:  -1540 x, 895 y, 145 z
players :   1 active (8 max)

...the "map" line contains the current map name and the 3D map location
where your player origin is currently at.  The player origin is ALWAYS at
the center of the body.  For Half-Life deathmatch, the player is 72 units
tall, 32 units wide and 32 units deep.  This means that if you are standing
right up against a wall, your origin is still 16 units away from the wall.

When you want to know the 3D coordinates of some point in the map, you can
run around until you get near that location, then use the console to enter
the "status" command (without the quotes), to print out what your current
location is.

Another method to determine the origin in maps is to use my BSP tools and
run the BSP viewer (bsp_view) to display a map...

http://planethalflife.com/botman/bsp_tool.shtml

The BSP viewer will constantly display the X, Y, and Z coordinates of your
location as you fly around in the map.  Also with the BSP viewer, you can
display the player spawn points (using player models) to determine where
existing spawn points are in maps.  This will help you if you plan on adding
new spawn points to a map.

When adding new monsters to a map, make SURE that these new monsters aren't
touching anything else in the map INCLUDING ANY WALLS OR FLOORS.  When you
spawn a monster in a map, it's best to make its origin at least 20 units up
in the air off the floor.  It will drop down to the floor when it spawns.
If you create one entity touching another entity, they will get "stuck"
together and won't work properly (you won't be able to pick up weapons,
or, in the case of player spawn points, players won't be able to move).
So make SURE you leave plenty of room between monsters and other things
in the map, like weapons, player spawn points and walls.

