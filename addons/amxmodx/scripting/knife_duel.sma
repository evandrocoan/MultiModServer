#define PLUGINNAME	"Automatic knife duel"
#define VERSION		"0.3"
#define AUTHOR		"JGHG"
/*
Copyleft 2005
Plugin topic: http://www.amxmodx.org/forums/viewtopic.php?p=91239


AUTOMATIC KNIFE DUEL
====================
Where I come from, if you cut the wall repeteadly with your knife it means you're challenging your last opponent to a knife duel. ;-)

I decided to automate this process.

If only you and another person on the opposite team remain in the round, you can hit a wall (or another object) with your knife, THREE TIMES in fast succession.
By this action you challenge your opponent to a knife duel. The person you challenge gets a menu where he can accept/decline your
challenge. The challenged person has 10 seconds to decide his mind, else the challenge is automatically declined, and the menu should be closed automatically.

Should a knife duel start, it works out pretty much like a round of Knife Arena: you can only use the knife (and the C4!).
As soon as the round ends the Knife Arena mode is turned off.

/JGHG


VERSIONS
========
050421	0.3 You must now slash with your knife three times in fast succession to challenge someone.
050208	0.2	Fixed seconds display.
			Bots should now respond correctly and a little human like. They will mostly accept challenges. ;-)
			Small fixes here and there. :-)
050208	0.1	First version - largely untested
*/

#include <amxmodx>
#include <fakemeta>
#include <fun>

#define DEBUG

#if defined DEBUG
#include <amxmisc>
#endif // defined DEBUG

#define MENUSELECT1				0
#define MENUSELECT2				1
#define TASKID_CHALLENGING		2348923
#define TASKID_BOTTHINK			3242321
#define DECIDESECONDS			10
#define ALLOWED_WEAPONS			2
#define KNIFESLASHES			3 // the nr of slashes within a short amount of time until a challenge starts...
// Globals below
new g_allowedWeapons[ALLOWED_WEAPONS] = {CSW_KNIFE, CSW_C4}
new g_MAXPLAYERS
new bool:g_challenging = false
new bool:g_knifeArena = false
new bool:g_noChallengingForAWhile = false
new g_challengemenu
new g_challenger
new g_challenged
new g_challenges[33]
// Globals above

public plugin_modules()
{
	require_module("fakemeta")
	require_module("fun")
}

public forward_emitsound(const PIRATE, const Onceuponatimetherewasaverysmall, noise[], const Float:turtlewhoateabiggerturtleand, const Float:afterthatthesmallturtlegot, const veryveryverybig, const theend) {
	if (g_noChallengingForAWhile || g_knifeArena || g_challenging || PIRATE < 1 || PIRATE > g_MAXPLAYERS || !is_user_alive(PIRATE) || !equal(noise, "weapons/knife_hitwall1.wav"))
		return FMRES_IGNORED

	new team = get_user_team(PIRATE), otherteam = 0, matchingOpponent = 0
	// Make sure exactly one person on each team is alive.
	for (new i = 1; i <= g_MAXPLAYERS; i++) {
		if (!is_user_connected(i) || !is_user_alive(i) || PIRATE == i)
			continue
		if (get_user_team(i) == team) {
			// No fun.
			return FMRES_IGNORED
		}
		else {
			if (++otherteam > 1) {
				// No fun.
				return FMRES_IGNORED
			}
			matchingOpponent = i
		}
	}

	if (matchingOpponent == 0)
		return FMRES_IGNORED

	if (++g_challenges[PIRATE] >= KNIFESLASHES) {
		Challenge(PIRATE, matchingOpponent)
		if (is_user_bot(matchingOpponent)) {
			new Float:val = float(DECIDESECONDS)
			if (val < 2.0)
				val = 2.0
			remove_task(TASKID_BOTTHINK)
			set_task(random_float(1.0, float(DECIDESECONDS) - 1.0), "BotDecides", TASKID_BOTTHINK)
		}
		g_challenges[PIRATE] = 0
	}
	else
		set_task(1.0, "decreaseChallenges", PIRATE)

	//client_print(PIRATE, print_chat, "Your challenges: %d", g_challenges[PIRATE])

	return FMRES_IGNORED
}

public decreaseChallenges(id) {
	if (--g_challenges[id] < 0)
		g_challenges[id] = 0
}

public BotDecides() {
	if (!g_challenging)
		return

	if (random_num(0,9) > 0)
		Accept()
	else {
		DeclineMsg()
	}
	g_challenging = false
	remove_task(TASKID_CHALLENGING)
}

Challenge(challenger, challenged) {
	g_challenger = challenger
	g_challenged = challenged
	g_challenging = true
	new challenger_name[32], challenged_name[32]
	get_user_name(challenger, challenger_name, 31)
	get_user_name(challenged, challenged_name, 31)

	client_print(challenger, print_chat, "You challenge %s to a knife duel! Await the answer within %d seconds...", challenged_name, DECIDESECONDS)

	new menu[1024], keys = MENU_KEY_1 | MENU_KEY_2
	format(menu, 1023, "You are challenged by %s to a knife duel!^n^nWhat will it be? You have %d seconds to answer!^n^n\y1\w. Bring it on!^n\y2\w. No, I'd rather use my boomstick!", challenger_name, DECIDESECONDS)
	show_menu(challenged, keys, menu, DECIDESECONDS, "JGHG's automatic knife duel")
	set_task(float(DECIDESECONDS), "timed_toolate", TASKID_CHALLENGING)
}

public timed_toolate() {
	if (g_challenging) {
		new challenger_name[32], challenged_name[32]
		get_user_name(g_challenger, challenger_name, 31)
		get_user_name(g_challenged, challenged_name, 31)
		client_print(0, print_chat, "%s didn't answer %s's knife duel challenge fast enough...", challenged_name, challenger_name)
		CancelAll()
	}
}

public client_putinserver(id) {
	set_task(600.0, "Announcement", id)

	return PLUGIN_CONTINUE
}

public Announcement(id) {
	client_print(id, print_chat, "When only you and one enemy are left standing, you can challenge him to a knife duel by slashing a wall with your knife.")
}

public challenged_menu(id, key) {
	switch (key) {
		case MENUSELECT1: {
			// Accept
			Accept()
		}
		case MENUSELECT2: {
			// Decline
			DeclineMsg()
		}
	}
	g_challenging = false
	remove_task(TASKID_CHALLENGING)

	return PLUGIN_HANDLED
}

DeclineMsg() {
	new challenger_name[32], challenged_name[32]
	get_user_name(g_challenger, challenger_name, 31)
	get_user_name(g_challenged, challenged_name, 31)
	client_print(0, print_chat, "%s turns down %s's knife duel challenge...", challenged_name, challenger_name)
}

Accept() {
	new challenger_name[32], challenged_name[32]
	get_user_name(g_challenger, challenger_name, 31)
	get_user_name(g_challenged, challenged_name, 31)

	client_print(0, print_chat, "%s accepts %s's knife duel challenge!", challenged_name, challenger_name)
	g_knifeArena = true
	give_item(g_challenger, "weapon_knife")
	give_item(g_challenged, "weapon_knife")
	engclient_cmd(g_challenger, "weapon_knife")
	engclient_cmd(g_challenged, "weapon_knife")
}

public event_holdwpn(id) {
	if (!g_knifeArena || !is_user_alive(id))
		return PLUGIN_CONTINUE

	new weaponType = read_data(2)

	for (new i = 0; i < ALLOWED_WEAPONS; i++) {
		if (weaponType == g_allowedWeapons[i])
			return PLUGIN_CONTINUE
	}

	engclient_cmd(id, "weapon_knife")

	return PLUGIN_CONTINUE
}

public event_roundend() {
	if (g_challenging || g_knifeArena)
		CancelAll()
	g_noChallengingForAWhile = true
	set_task(4.0, "NoChallengingForAWhileToFalse")

	return PLUGIN_CONTINUE
}

public NoChallengingForAWhileToFalse() {
	g_noChallengingForAWhile = false
}

CancelAll() {
	if (g_challenging) {
		g_challenging = false
		// Close menu of challenged
		if (is_user_connected(g_challenged)) {
			new usermenu, userkeys
			get_user_menu(g_challenged, usermenu, userkeys) // get user menu

			// Hmm this ain't working :-/
			if (usermenu == g_challengemenu) // Close it!
				show_menu(g_challenged, 0, "blabla") // show empty menu
		}
	}
	if (g_knifeArena) {
		g_knifeArena = false
	}
	remove_task(TASKID_BOTTHINK)
	remove_task(TASKID_CHALLENGING)
}

public event_death() {
	if (g_challenging || g_knifeArena)
		CancelAll()

	return PLUGIN_CONTINUE
}

#if defined DEBUG
public challengefn(id, level, cid) {
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED

	new challenger[64], challenged[64]
	read_argv(1, challenger, 63)
	read_argv(2, challenged, 63)

	console_print(id, "challenger: %s, challenged: %s", challenger, challenged)

	new r = str_to_num(challenger)
	new d = str_to_num(challenged)
	Challenge(r, d)
	if (is_user_bot(d))
		Accept()

	return PLUGIN_HANDLED
}
#endif // defined DEBUG

public plugin_init() {
	register_plugin(PLUGINNAME, VERSION, AUTHOR)
	register_event("CurWeapon", "event_holdwpn", "be", "1=1")
	register_forward(FM_EmitSound, "forward_emitsound")
	g_MAXPLAYERS = get_maxplayers()

	g_challengemenu = register_menuid("JGHG's automatic knife duel"/*"You are challenged"*/)
	register_menucmd(g_challengemenu, MENU_KEY_1 | MENU_KEY_2, "challenged_menu")

	register_event("DeathMsg", "event_death", "a")
	register_event("SendAudio", "event_roundend", "a", "2&%!MRAD_terwin")
	register_event("SendAudio", "event_roundend", "a", "2&%!MRAD_ctwin")
	register_event("SendAudio", "event_roundend", "a", "2&%!MRAD_rounddraw")

	#if defined DEBUG
	register_clcmd("0challenge", "challengefn", ADMIN_CFG, "<challenger> <challenged> - start knife duel challenge")
	#endif // defined DEBUG

	//set_task( 1200, "Announcement", 0, "", 0, "b")
}