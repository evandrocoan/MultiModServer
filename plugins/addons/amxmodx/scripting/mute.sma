#include <amxmodx>
#include <amxmisc>

#define PLUGIN    "AMX Mute"
#define AUTHOR    "Nomad"
#define VERSION    "1.1"

#pragma semicolon 1

new bool:g_mutedPlayers[33];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    register_concmd("amx_mute", "mute", ADMIN_RESERVATION, "<nick> [minutes]");
    register_concmd("amx_unmute", "unmute", ADMIN_RESERVATION, "<nick>");
    register_clcmd("say", "hookSay");
    register_dictionary("mute.txt");
}

public client_connect(id) {
    g_mutedPlayers[id] = false;
}

public hookSay(id) {
    if (g_mutedPlayers[id]) {
        new msg[7], nick[32];
        read_argv(1, msg, charsmax(msg));

        if (equali(msg, "/sorry")) {
            get_user_name(id, nick, charsmax(nick));
            set_hudmessage(255,255,255,.channel=-1);
            show_hudmessage(0, "%L", LANG_PLAYER, "CLIENT_SORRY", nick);
        }

        client_print(id, print_chat, "%L", id, "MUTED");
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public mute(id, level, cid) {
    new argC = read_argc();

    new nick[32];
    read_argv(1, nick, charsmax(nick));

    new player = cmd_target(id, nick);
    if (!player) {
        client_print(id, print_chat, "%L", id, "SORRY", nick);
        client_print(id, print_console, "%L", id, "SORRY", nick);
        return PLUGIN_HANDLED;
    }

    new adminName[32];
    get_user_name(id, adminName, charsmax(adminName));

    g_mutedPlayers[player] = true;
    client_print(0, print_chat, "%L", LANG_PLAYER, "BEEN_MUTED", nick, adminName);

    if (argC == 3) {
        server_print("using timed mute");
        new arg[10]; read_argv(2, arg, charsmax(arg));
        new Float:time = str_to_float(arg);
        time *= 60;
        set_task(time, "unmuteId", player);
    }

    return PLUGIN_HANDLED;
}

public unmute(id, level, cid) {
    if (!cmd_access(id, level, cid, 2))
        return PLUGIN_HANDLED;

    new nick[32];
    read_argv(1, nick, charsmax(nick));

    new player = cmd_target(id, nick);
    if (!player) {
        client_print(id, print_chat, "%L", id, "SORRY", nick);
        client_print(id, print_console, "%L", id, "SORRY", nick);
    }

    g_mutedPlayers[player] = false;
    client_print(player, print_chat, "%L", player, "UNMUTED");

    return PLUGIN_HANDLED;
}

public unmuteId(id) {
    g_mutedPlayers[id] = false;
    client_print(id, print_chat, "%L", id, "UNMUTED");
}
