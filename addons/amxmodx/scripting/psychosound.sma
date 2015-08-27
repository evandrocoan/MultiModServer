// PsychoSound, Copyright 2002, PsychoGuard. No warranties.
// Props to OLO for all the great Metamod plugins he developed.
// Props to Luke Sankey for his Sank Sounds plugin.
//
// Modified April 27th, 2003 by [LADT]Weasel
//	Based largely upon the German port created by:
//
//
//PsychoSound is a AMX-Mod-X port of the PsychoSounds AMX-Mod plugin by PsychoGuard.
//This port is based in part on a German language port created by KSK|Osiris and KSK|EPROK
//
//This version is all English.
//It also changes the default sound file location to be more in keeping with the AMX-Mod-X convention.
//The new sound file location is "$game/addons/amxx/configs/sounds.cfg".
//
//Both the source .SMA file and the compiled .AMX file are included in the .ZIP file.
//A sample Sounds.CFG file is also included.
//The sample Sounds.CFG file uses only sounds that are embedded into Half-Life (and subsequently all HL mods).
//No custom sound files are included.
//The Sounds.CFG file includes notes on how to add more custom sounds.
//Any custom sounds (that are not part of HL or whatever mod is being used) must be downloaded to the clients.
//This plugin does not provide that functionality.
//There are other AMX-Mod-X plugins that perform that function.
//
//The source .SMA file should be copied to your "$game/addons/amxx/scripting" folder.
//The compiled .AMX file should be copied to your "$game/addons/amxx/plugins" folder.
//The sample Sounds.CFG file should be copied to your "$game/addons/amxx/configs" folder.
//
//No warranties, expressed or implied intended.
//Use at your own risk.
//
//	+----------------------------------------------------+
//	|       AMX Plugins und ins Deutsche uebersetzt      |
//	|             unter www.ksk-amx.de.vu                |
//	|  German AMX Plugins by KSK|Osiris and KSK|EPROK    |
//	|          Clan URL: http://www.real-ksk.de          |
//	|      Im Qnet IRC Channel: #headquarter-bremen      |
//	|          Das Offizielle AMX zuhause:               |
//	|           http://amxmod.net/amx.php                |
//	+----------------------------------------------------+
//
// Play configurable sounds to all clients when players say certain keywords.
//
// Cvars:
//   pd_sound_file      Location of the configuration file. Default:
//                      addons/amxx/configs/sounds.cfg
//   pd_sound_mode      Default "ab"
//                      a - Alive players hear dead players
//                      b - Alive players can trigger sounds
//                      c - Only admins can trigger sounds
//                          (ADMIN_LEVEL_A required)
//                      d - Don't display says.
//   pd_sound_warn      Number of sound says before player will be warned.
//                      Default: 20.
//   pd_sound_max       Maximum number of says before player will be muted.
//                      Default: 25.
//   pd_sound_join      Sound to play when player joins. Default: None.
//   pd_sound_leave     Sound to play when player leaves. Default:
//                      misc/comeagain.wav.
// Client commands:
//   pd_sound_mute      Mutes players by nick. Level A needed.
//   pd_sound_unmute    Unmutes players by nick. Level A needed.
//
// Server commands:
//   pd_sound           Register a new keyword/sound pair or list registered
//                      sounds.
// Files:
//   $game/addons/amxx/configs/sounds.cfg
//                      This file is executed on loading of this plugin. It
//                      should initialize the sound matrix.
//
// Configuration file: This file contains mappings between
// keywords and sound files to play. It should contain commands like the
// following examples:
//
// pd_sound "ha ha" "misc/haha.wav"
// pd_sound "doh"   "misc/doh.wav"
// pd_sound "doh"   "misc/doh2.wav"
//
// So if a players says "ha ha", the sound file haha.wav will be played to all
// players. If a player says "doh", randomly one of the two sounds doh.wav and
// doh2.wav will be played. The matching is case sensitive. Make sure says
// containing spaces (like "ha ha") are enclosed in quotes.
//

#include <amxmodx>
#include <amxmisc>

#define MAX_WORDS       64
#define MAX_SOUNDS      64
#define MAX_STR_LENGTH  32

new words[MAX_WORDS][MAX_STR_LENGTH];
new sounds[MAX_SOUNDS][MAX_STR_LENGTH];
new num_sounds[MAX_WORDS] = {0,...};
new word2sound[MAX_WORDS][MAX_SOUNDS];

new word_count;
new sound_count;

new sound_use[33] = {0,...};
new muted[33] = {0,...};

new gmsgSayText;

public list_sounds() {
    new line[256];
    for (new i = 0; i < word_count; i++) {
        format(line, 255, "%-20s ", words[i]);

        for (new j = 0; j < MAX_SOUNDS; j++) {
            if (word2sound[i][j]) {
                add(line, 255, sounds[j]);
                add(line, 255, " ");
            }
        }
        server_print(line);
    }
}

public new_sound() {
    if (read_argc() == 1) {
        list_sounds();
        return PLUGIN_HANDLED;
    }

    if (read_argc() != 3) {
        server_print("Usage: pd_sound <keyword> <soundfile>");
        return PLUGIN_HANDLED;
    }

    new keyword[MAX_STR_LENGTH];
    new snd[MAX_STR_LENGTH];

    read_argv(1, keyword, MAX_STR_LENGTH);
    read_argv(2, snd, MAX_STR_LENGTH);

    if (! add_sound(keyword, snd)) {
        log_message("[PD] Too many sounds or words.");
    }

    return PLUGIN_HANDLED;
}

add_sound(keyword[], sound[]) {
    new word_index = find_word_or_append(keyword);
    new sound_index = find_sound_or_append(sound);

    if (word_index >= 0 && sound_index >= 0) {
        word2sound[word_index][sound_index] = 1;
        num_sounds[word_index]++;
        return 1;
    }

    return 0;
}


find_word_or_append(word[]) {
    new index = find_word(word);

    if (index != -1) {
        return index;
    } else {
        if (word_count < MAX_WORDS) {
            copy(words[word_count], MAX_STR_LENGTH, word);
            word_count++;
            return word_count - 1;
        }
    }

    return -1; // Max words used.
}

find_word(word[]) {
    for (new i = 0; i < word_count; i++) {
        if (equal(word, words[i])) {
            return i;
        }
    }

    return -1;
}

find_sound_or_append(sound[]) {
    new index = find_sound(sound);

    if (index != -1) {
        return index;
    } else {
        if (sound_count < MAX_SOUNDS) {
            copy(sounds[sound_count], MAX_STR_LENGTH, sound);
            sound_count++;
            return sound_count - 1;
        }
    }

    return -1; // Max sounds used.
}


find_sound(sound[]) {
    for (new i = 0; i < sound_count; i++) {
        if (equal(sound, sounds[i]))
            return i;
    }
    return -1;
}


get_mode() {
    new mode[5];
    get_cvar_string("pd_sound_mode", mode, 4);
    return read_flags(mode);
}


public handle_say(id) {
    new mode = get_mode();
    new user_flags = get_user_flags(id);

    if ((mode & 4) && !(user_flags & ADMIN_LEVEL_A))
        return PLUGIN_CONTINUE;

    if (! (user_flags & ADMIN_IMMUNITY) &&
        (muted[id] || sound_use[id] > get_cvar_num("pd_sound_max")))
        return PLUGIN_CONTINUE;

    new word[MAX_STR_LENGTH];
    new part[MAX_STR_LENGTH];

    for (new i = 1; i < read_argc(); i++) {
        read_argv(i, part, MAX_STR_LENGTH-1);
        add(word, MAX_STR_LENGTH-1, part);
        if (i < read_argc()-1)
            add(word, MAX_STR_LENGTH-1, " ");
    }

    new index = find_word(word);
    if (index == -1) return PLUGIN_CONTINUE;

    if (sound_use[id] > get_cvar_num("pd_sound_warn")) {
        new says_left = get_cvar_num("pd_sound_max") - sound_use[id];

        set_hudmessage(255, 50, 30, -1.0, 0.80, 0, 0.05, 3.0, 0.25, 0.25, 2);

        if (says_left > 0) {
            show_hudmessage(id, "STOP TALKING! %d more and you will be muted.",
                            says_left);
        } else {
            show_hudmessage(id, "You have been muted. Silence - after all.");
            client_cmd(id, "spk barney/youtalkmuch");
        }
    }

    new random_sound = random_num(1, num_sounds[index]);
    new current_sound = 0;

    for (new i = 0; i < sound_count; i++) {
        if (word2sound[index][i]) {
            current_sound++;
            if (current_sound == random_sound) {
                if ((mode & 1) || (is_user_alive(id) && (mode & 2))) {
                    // These are the only broadcast situations: Either the
                    // player is alive and alive players may trigger sound or
                    // the player is dead and sounds from dead player are
                    // broadcasted to all players (dead or alive).
                    sound_use[id]++;

                    client_cmd(0, "spk %s", sounds[i]);

                    if (! (mode & 8)) {
                        new origin[3];
                        new message[129];
                        new name[33];

                        get_user_name(id, name, 32);
                        format(message, 128, "%c%s :    %s^n", 2, name, word);

                        message_begin(MSG_ALL, gmsgSayText, origin, id);
                        write_byte(id);
                        write_string(message);
                        message_end();
                    }

                    return PLUGIN_HANDLED;
                } else if (!is_user_alive(id)) {
                    sound_use[id]++;
                    new players[32];
                    new player_count;

                    get_players(players, player_count, "b");

                    for (new p = 0; p < player_count; p++) {
                        client_cmd(players[p], "spk %s", sounds[i]);
                    }

                    return PLUGIN_CONTINUE;
                }
            }
        }
    }
    return PLUGIN_CONTINUE;
}

public mute(id, level, cid) {
    if (! cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED;

    new target[32];
    read_argv(1, target, 31);
    new player = cmd_target(id, target, 0);

    if (! player) {
        console_print(id, "[PD] No player matching '%s'.");
        return PLUGIN_HANDLED;
    }

    get_user_name(player, target, 31);
    if (get_user_flags(player) & ADMIN_IMMUNITY) {
        console_print(id, "[PD] Player '%s' has immunity.");
        return PLUGIN_HANDLED;
    }

    new command[32];
    read_argv(0, command, 31);
    muted[player] = (command[9] == 'u') ? 0 : 1;
    console_print(id, "[PD] Player '%s' has been %s.", target, muted[player] ? "muted" : "unmuted");
    return PLUGIN_HANDLED;
}


public client_connect(id) {
    new snd[MAX_STR_LENGTH];
    get_cvar_string("pd_sound_join", snd, MAX_STR_LENGTH-1);
    if (! equal(snd, "")) client_cmd(0, "spk %s", snd);
    sound_use[id] = 0;
    muted[id] = 0;
}

public client_disconnect(id) {
    new snd[MAX_STR_LENGTH];
    get_cvar_string("pd_sound_leave", snd, MAX_STR_LENGTH-1);
    if (! equal(snd, "")) client_cmd(0, "spk %s", snd);
}

public plugin_init() {
    register_plugin("PsychoSound", "0.16", "PsychoGuard");
    register_srvcmd("pd_sound", "new_sound", 0, "<keyword> <sound> [flags]");
    register_concmd("pd_sound_mute", "mute", ADMIN_SLAY, "<authid, name oder #userid>");
    register_concmd("pd_sound_unmute", "mute", ADMIN_SLAY, "<authid, name oder #userid>");
    register_clcmd("say", "handle_say");
    //register_cvar("pd_sound_join", "");
    register_cvar("pd_sound_leave", "barney/ba_endline.wav");
    register_cvar("pd_sound_warn", "20");
    register_cvar("pd_sound_max", "25");
    register_cvar("pd_sound_mode", "ab");
    gmsgSayText = get_user_msgid("SayText");
    server_cmd("exec addons/amxmodx/configs/sounds.cfg");
    return PLUGIN_CONTINUE;
}
