#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#pragma semicolon true
#pragma ctrlchar '\'

#define PLUGIN "Always-Usable Impulse"
#define VERSION "v1.1.0"
#define AUTHOR "KliPPy"


new m_pTank;

new g_hasExecuted[33];

new HamHook: g_hamPostThink_Post;
new HamHook: g_hamPostThink_Pre;
new HamHook: g_hamImpulseCommands;


public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	g_hamPostThink_Pre = RegisterHam(Ham_Player_PostThink, "player", "Player_PostThink_Pre", false);
	g_hamPostThink_Post = RegisterHam(Ham_Player_PostThink, "player", "Player_PostThink_Post", true);
	g_hamImpulseCommands = RegisterHam(Ham_Player_ImpulseCommands, "player", "Player_ImpulseCommands", true);
	
#if AMXX_VERSION_NUM < 183
	m_pTank = 1408; // (int)352
#else
	m_pTank = find_ent_data_info("CBasePlayer", "m_pTank");
#endif
}


public Player_PostThink_Pre(this) {
	g_hasExecuted[this] = false;
}

public Player_ImpulseCommands(this) {
	g_hasExecuted[this] = true;
}

public Player_PostThink_Post(this) {
	if(!g_hasExecuted[this] && !pev_valid(get_pdata_ent(this, m_pTank))) {
		ExecuteHamB(Ham_Player_ImpulseCommands, this);
	}
}


public plugin_pause() {
	DisableHamForward(g_hamPostThink_Pre);
	DisableHamForward(g_hamPostThink_Post);
	DisableHamForward(g_hamImpulseCommands);
}

public plugin_unpause() {
	EnableHamForward(g_hamPostThink_Pre);
	EnableHamForward(g_hamPostThink_Post);
	EnableHamForward(g_hamImpulseCommands);
}
