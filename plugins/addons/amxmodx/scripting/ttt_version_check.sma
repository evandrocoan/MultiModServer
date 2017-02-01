#include <amxmodx>
#include <sockets>
#include <ttt>

new g_pSocket;

#define SCRIPT_NAME "/ttt_version_check.php"
#define REMOTE_HOST "cs.hackers.lv"

public plugin_init()
{
	register_plugin("[TTT] Version Check", TTT_VERSION, TTT_AUTHOR);

	new error;
	g_pSocket = socket_open(REMOTE_HOST, 80, SOCKET_TCP, error);
	if(g_pSocket > 0)
	{
		new string[256];
		formatex(string, charsmax(string), "GET %s HTTP/1.1^r^nHost: %s^r^n^r^n", SCRIPT_NAME, REMOTE_HOST);
		socket_send(g_pSocket, string, charsmax(string));
		set_task(1.0, "read_web");
	}
	else
	{
		switch(error)
		{
			case 1: server_print("Error creating socket");
			case 2: server_print("Error resolving remote hostname");
			case 3: server_print("Error connecting socket");
		}
	}
}

public read_web()
{
	new text[256], int_v[5], str_v[7];
	socket_recv(g_pSocket, text, charsmax(text));
	strtok(text[165], int_v, charsmax(int_v), str_v, charsmax(str_v));
	new version = str_to_num(int_v);
	if(version > TTT_VERSION_INT)
	{
		log_amx("[TTT] You are using %s version, but newest is %s!", TTT_VERSION, str_v);
		log_amx("[TTT] Download @ https://forums.alliedmods.net/showthread.php?t=238780");
	}
}
