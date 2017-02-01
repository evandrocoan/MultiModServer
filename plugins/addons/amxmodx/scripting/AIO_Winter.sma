
#include < amxmodx >
#include < amxmisc >

#include < fakemeta >
#include < hamsandwich >
#include < engine >
#include < cstrike >
#include < fun >
#include < xs >

#pragma semicolon 1

#define PLUGIN_VERSION			"1.0.2"

#if AMXX_VERSION_NUM < 183
	#define MAX_PLAYERS		32
	
	#define INT_BYTES        	4 
	#define BYTE_BITS       	8
#endif

#define AMBIENT_SOUND_LARGERADIUS	8
#define ADMIN_ACCESS_FLAG		ADMIN_BAN
 
#define TASKID_INVIS			2733
#define IS_PLAYER(%1)			( 1 <= %1 <= gMaxPlayers )

enum _: iChristmasGifts
{
	GIFT_ARMOR,
	GIFT_ARMOR_KEVLAR,
	GIFT_AMMO,
	GIFT_BONUS_HEALTH,
	GIFT_RANDOM_GRENADE,
	GIFT_FRAG,
	GIFT_INVISIBILITY,
	GIFT_RANDOM_GLOW,
	GIFT_RANDOM_HAT_GLOW_EFFECT,
	GIFT_DEFUSER,
	GIFT_CAMOUFLAGE,
	GIFT_MONEY
};

enum _: iBombEvents
{
	BOMB_PLANTED,
	BOMB_EXPLODED,
	BOMB_DEFUSED
};

enum _: iGrenadeModels
{
	VIEW_MODEL,
	PLAYER_MODEL,
	WORLD_MODEL
};

enum _: iRGB
{
	iRed = 0,
	iGreen,
	iBlue
};

new const szGiftNames[ iChristmasGifts ][ ] =
{
	"Armor",
	"Armor + Helmet",
	"Some Ammunition",
	"Bonus Health",
	"Random Grenade",
	"Bonus Frag",
	"Invisibility",
	"Random Glow",
	"Random Glow on Santa Hat",
	"Defuser Kit",
	"Camouflage: [You look like enemy until you die]",
	"Money"
};

new const gCounterTerrModels[ ][ ] =
{
	"urban",
	"gsg9",
	"gign",
	"sas"
};

new const gTerroristModels[ ][ ] = 
{
	"terror", 
	"leet",
	"artic",
	"guerilla"
};

new const gGrenadeEntities[ ][ ] =
{
	"weapon_hegrenade",
	"weapon_flashbang",
	"weapon_smokegrenade"
};

new const gGunEvents[ ][ ] =
{
	"events/awp.sc",
	"events/g3sg1.sc",
        "events/ak47.sc",
        "events/scout.sc",
        "events/m249.sc",
        "events/m4a1.sc",
        "events/sg552.sc",
        "events/aug.sc",
        "events/sg550.sc",
        "events/m3.sc",
        "events/xm1014.sc",
        "events/usp.sc",
        "events/mac10.sc",
        "events/ump45.sc",
        "events/fiveseven.sc",
        "events/p90.sc",
        "events/deagle.sc",
        "events/p228.sc",
        "events/glock18.sc",
        "events/mp5n.sc",
        "events/tmp.sc",
        "events/elite_left.sc",
        "events/elite_right.sc",
        "events/galil.sc",
        "events/famas.sc"
};

new const gGiftModels[ ][ ] = 
{
	"models/aio_winter/present_1.mdl",
	"models/aio_winter/present_2.mdl",
	"models/aio_winter/present_3.mdl"
};

new const gSantaHatModels[ ][ ] =
{
	"models/aio_winter/santahat.mdl",
	"models/aio_winter/santahat_2.mdl"
};

new const szChristmasTreeModels[ ][ ] =
{
	"models/aio_winter/christmas_tree_1.mdl",
	"models/aio_winter/christmas_tree_2.mdl"
};

new const szFrostBombModels[ ][ ] = 
{
	"models/aio_winter/snowman.mdl",
	"models/aio_winter/frost_man.mdl"
};

new const gBombSounds[ iBombEvents ][ ] =
{
	"aio_winter/bmb_planted_santa.wav",
	"aio_winter/bmb_exploded_santa.wav",
	"aio_winter/bmb_defused_santa.wav"
};

new const szGrenadeModels[ iGrenadeModels ][ ] =
{
	"models/aio_winter/v_xmasgrenade.mdl",
	"models/aio_winter/p_xmasgrenade.mdl",
	"models/aio_winter/w_xmasgrenade.mdl"
};

new const szConfigFileName[ ] = "AIO_Winter.cfg";
new const szPluginTag[ ] = "[ AIO Winter ]";

new const szSnowBallClassname[ ] = "SnowBall_Entity";
new const szGiftClassname[ ] = "Present_Entity";

new const szSnowballModel[ ] = "sprites/bhit.spr";
new const szTrailSprite[ ] = "sprites/laserbeam.spr";
new const szGlowSpriteLed[ ] = "sprites/ledglow.spr";
new const szShadowSpr[ ] = "sprites/shadow_circle.spr";

new const szCandyKnifeModel[ ] = "models/aio_winter/v_candycane.mdl";
new const szCandyKnifeModelPlayer[ ] = "models/aio_winter/p_candycane.mdl";

new const szChristmasTreeSong[ ] = "aio_winter/merry_christmas.wav";
new const szPickupArmorSound[ ] = "items/ammopickup2.wav";
new const szHealthPickUpSound[ ] = "items/medshot4.wav";
new const szBonusFragsPickupSound[ ] = "bullchicken/bc_bite1.wav";
new const szInvisPickupSound[ ] = "barney/seeya.wav";
new const szInvisDisabledSound[ ] = "barney/aintgoin.wav";
new const szGlowPickupSound[ ] = "items/airtank1.wav";
new const szDefuserPickupSound[ ] = "items/gunpickup3.wav";
new const szCamouflagePickupSound[ ] = "items/weapondrop1.wav";
new const szMoneyPickupSound[ ] = "barney/gladof38.wav";

new gCvarEnableGunSnowballs;
new gCvarGunSnowballDuration;
new gCvarEnableTrees;
new gCvarEnableCustomBomb;
new gCvarSantaHat;
new gCvarSantaHatAdminOnly;
new gCvarChristmasBombSounds;
new gCvarUserWeatherMenu;
new gCvarUserWeatherMenuDisplayTime;
new gCvarEnableDarkness;
new gCvarChangeSkyname;
new gCvarEnablePresents;
new gCvarBonusHealthAmount;
new gCvarGiftArmor;
new gCvarBonusFragAmount;
new gCvarGiftInvisibilityDuration;
new gCvarGiftMoney;
new gCvarRainySupport;
new gCvarEnableKnifeCandy;
new gCvarChristmasGrenade;
new gCvarChristmasGrenadeType;

new i;
new gHudSync;
new gMaxPlayers;
new gTrailSprite;
new gLedBombSprite;
new gMessageScoreInfo;
new gMessageShadowIdx;
new gInfoTarget;
new gShadowSpr;

new gEventsIndex[ sizeof gGunEvents ];

new gPlayerSantaHat[ MAX_PLAYERS + 1 ];

const m_pPlayer = 41;
const m_LinuxDiff = 5;
const m_bIsC4 = 385;

public plugin_init( )
{
	register_plugin( "AIO: Winter Plugin", PLUGIN_VERSION, "tuty" );
	register_cvar( "aio_winter_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY | FCVAR_UNLOGGED );

	register_event( "DeathMsg", "EVENT_DeathMsg", "a" );
	register_event( "TextMsg", "EVENT_RoundStart", "a", "2&#Game_C", "2&#Game_w", "2&#Game_will_restart_in" );
	register_event( "BombDrop", "EVENT_OnBombDrop", "a", "4=1" );

	register_logevent( "EVENT_RoundStart", 2, "1=Round_Start" );
	register_logevent( "LOGEvent_BombPlanted", 3, "2=Planted_The_Bomb" );
	register_logevent( "LOGEvent_BombDefused", 3, "2=Defused_The_Bomb" );
	register_logevent( "LOGEvent_BombExploded", 6, "3=Target_Bombed" );

	RegisterHam( Ham_Spawn, "player", "bacon_PlayerSpawn", 1 );
	RegisterHam( Ham_Item_Deploy, "weapon_knife", "bacon_KnifeDeploy", 1 );
	RegisterHam( Ham_Think, "ambient_generic", "bacon_TreeThink", 1 );

	for( i = 0; i < sizeof gGrenadeEntities; i++ )
	{
		RegisterHam( Ham_Item_Deploy, gGrenadeEntities[ i ], "bacon_GrenadeDeploy", 1 );
	}

	register_forward( FM_SetModel, "forward_FM_SetModel", 1 );
	register_forward( FM_PlaybackEvent, "forward_FM_PlaybackEvent" );

	register_think( szSnowBallClassname, "forward_SnowballThink" );
	register_think( szGiftClassname, "forward_GiftThink" );
	
	register_touch( szGiftClassname, "player", "forward_TouchGift" );
	
	register_message( SVC_TEMPENTITY, "Message_TempEntity" );

	gCvarEnableGunSnowballs = register_cvar( "aio_winter_gun_snowball", "1" );
	gCvarGunSnowballDuration = register_cvar( "aio_winter_gun_snowball_duration", "5.0" );
	gCvarChangeSkyname = register_cvar( "aio_winter_changesky", "1" );
	gCvarEnableDarkness = register_cvar( "aio_winter_darkness", "1" );
	gCvarChristmasBombSounds = register_cvar( "aio_winter_bombsounds", "1" );
	gCvarUserWeatherMenu = register_cvar( "aio_winter_weathermenu", "1" );
	gCvarUserWeatherMenuDisplayTime = register_cvar( "aio_winter_weathermenu_time", "8.0" );
	gCvarEnableCustomBomb = register_cvar( "aio_winter_custombomb", "1" );
	gCvarEnableTrees = register_cvar( "aio_winter_tree", "1" );
	gCvarSantaHat = register_cvar( "aio_winter_hat", "1" );
	gCvarSantaHatAdminOnly = register_cvar( "aio_winter_hat_adminonly", "0" );
	gCvarEnablePresents = register_cvar( "aio_winter_presents", "1" );
	gCvarBonusHealthAmount = register_cvar( "aio_winter_bonus_health_amount", "50" );
	gCvarGiftArmor = register_cvar( "aio_winter_gift_armor", "100" );
	gCvarBonusFragAmount = register_cvar( "aio_bonus_frag", "2" );
	gCvarGiftInvisibilityDuration = register_cvar( "aio_winter_invis_duration", "15" );
	gCvarGiftMoney = register_cvar( "aio_winter_gift_money", "1500" );
	gCvarRainySupport = register_cvar( "aio_winter_rainymap_support", "1" );
	gCvarEnableKnifeCandy = register_cvar( "aio_winter_candyknife", "1" );
	gCvarChristmasGrenade = register_cvar( "aio_winter_grenade", "1" );
	gCvarChristmasGrenadeType = register_cvar( "aio_winter_grenade_type", "0" );

	gHudSync = CreateHudSyncObj( );
	gMaxPlayers = get_maxplayers( );

	gMessageScoreInfo = get_user_msgid( "ScoreInfo" );
	gMessageShadowIdx = get_user_msgid( "ShadowIdx" );

	gInfoTarget = engfunc( EngFunc_AllocString, "info_target" );
}

public plugin_cfg( )
{
	if( get_pcvar_num( gCvarEnableDarkness ) != 0 )
	{
		set_lights( "d" );
		server_cmd( "mp_flashlight 1" );
	}
	
	if( get_pcvar_num( gCvarChangeSkyname ) != 0  )
	{
		server_cmd( "sv_skyname ^"space^"" );
	}
	
	if( get_pcvar_num( gCvarEnableTrees ) != 0 )
	{
		UTIL_FindSpawnPoints( );
	}
	
	if( get_pcvar_num( gCvarRainySupport ) != 0 )
	{
		new szMapName[ MAX_PLAYERS ], iEntity = FM_NULLENT;
		get_mapname( szMapName, charsmax( szMapName ) );
		
		while( ( iEntity = find_ent_by_class( iEntity, "env_rain" ) ) )
		{
			if( pev_valid( iEntity ) )
			{
				UTIL_RemoveEntities( "env_rain" );
			
				server_print( "%s Found a map that has rain built in: '%s'. Support for rainy maps is enabled, so the map has been patched", szPluginTag, szMapName );
				log_amx( "%s Found a map that has rain built in: '%s'. Support for rainy maps is enabled, so the map has been patched", szPluginTag, szMapName );
			}
		}
	}
	
	new szConfigsDir[ MAX_PLAYERS ], szFile[ 256 ];

	get_configsdir( szConfigsDir, charsmax( szConfigsDir ) );
	formatex( szFile, charsmax( szFile ), "%s/%s", szConfigsDir, szConfigFileName );
	
	if( file_exists( szFile ) )
	{
		server_cmd( "exec %s", szFile );
		
		log_amx( "%s Configuration file '%s' loaded successfully!", szPluginTag, szConfigFileName );
		server_print( "%s Configuration file '%s' loaded successfully!", szPluginTag, szConfigFileName );
	}

	else
	{
		log_amx( "%s Configuration file '%s' not found! Loading default Cvars...", szPluginTag, szConfigFileName );
		server_print( "%s Configuration file '%s' not found! Loading default Cvars...", szPluginTag, szConfigFileName );
	}
}

public plugin_precache( )
{
	engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "env_snow" ) );

	for( i = 0 ; i < sizeof gGunEvents; i++ )
	{
		gEventsIndex[ i ] = engfunc( EngFunc_PrecacheEvent, 1, gGunEvents[ i ] );
	}

	gTrailSprite = precache_model( szTrailSprite );
	gLedBombSprite = precache_model( szGlowSpriteLed );
	gShadowSpr = precache_model( szShadowSpr );

	precache_model( szCandyKnifeModelPlayer );
	precache_model( szSnowballModel );
	precache_model( szCandyKnifeModel );

	for( i = 0; i < iGrenadeModels; i++ )
	{
		precache_model( szGrenadeModels[ i ] );
	}
	
	for( i = 0; i < iBombEvents; i++ )
	{
		precache_sound( gBombSounds[ i ] );
	}

	for( i = 0; i < sizeof gGiftModels; i++ )
	{
		precache_model( gGiftModels[ i ] );
	}
	
	for( i = 0; i < sizeof gSantaHatModels; i++ )
	{
		precache_model( gSantaHatModels[ i ] );
	}

	for( i = 0; i < sizeof szChristmasTreeModels; i++ )
	{
		precache_model( szChristmasTreeModels[ i ] );
	}
	
	for( i = 0; i < sizeof szFrostBombModels; i++ )
	{
		precache_model( szFrostBombModels[ i ] );
	}

	precache_sound( szChristmasTreeSong );
	precache_sound( szPickupArmorSound );
	precache_sound( szHealthPickUpSound );
	precache_sound( szBonusFragsPickupSound );
	precache_sound( szInvisPickupSound );
	precache_sound( szInvisDisabledSound );
	precache_sound( szGlowPickupSound );
	precache_sound( szDefuserPickupSound );
	precache_sound( szCamouflagePickupSound );
	precache_sound( szMoneyPickupSound );
}

public client_connect( id )
{
	if( gPlayerSantaHat[ id ] > 0 )
	{
		engfunc( EngFunc_RemoveEntity, gPlayerSantaHat[ id ] );
	}

	gPlayerSantaHat[ id ] = 0;
}

public client_disconnect( id )
{
	if( gPlayerSantaHat[ id ] > 0 )
	{
		engfunc( EngFunc_RemoveEntity, gPlayerSantaHat[ id ] );
	}

	remove_task( id + TASKID_INVIS );

	gPlayerSantaHat[ id ] = 0;
}

public client_putinserver( id )
{
	if( get_pcvar_num( gCvarUserWeatherMenu ) != 0 )
	{
		set_task( get_pcvar_float( gCvarUserWeatherMenuDisplayTime ), "DisplayWeather_Menu", id );
	}
}

public DisplayWeather_Menu( id )
{
	if( is_user_connected( id ) )
	{
		new szName[ 32 ];
		get_user_name( id, szName, charsmax( szName ) );
		
		new szFormatMenuTitle[ 350 ];
		formatex( szFormatMenuTitle, charsmax( szFormatMenuTitle ), "\wHi\r %s\w, in order to enjoy the best \rChirstmas Environment\w on this server, we recommend the following action:^n* Set the \r^"cl_weather^"\w to \y1\w/\y2\w/\y3\w in console to enable the \ySnow \weffect!^nWould you like to set this up for you?^n^n", szName );

		new iMenu = menu_create( szFormatMenuTitle, "menu_Handler" );
	
		menu_additem( iMenu, "Yes, enable weather for me!", "1", 0 );
		menu_additem( iMenu, "No, thanks.", "2", 0 );
		
		menu_setprop( iMenu, MPROP_EXIT, MEXIT_NEVER );
		menu_display( id, iMenu, 0 );
	}
}

public menu_Handler( id, menu, item )
{	
	switch( item )
	{
		case 0:
		{
			client_cmd( id, "speak ^"items/suitchargeok1.wav^"" );
			client_cmd( id, "wait; cl_weather 3" );

			client_print( id, print_chat, "%s Plugin enabled Snow effects to your client, with your permission.", szPluginTag );
			menu_destroy( menu );

			return PLUGIN_HANDLED;
		}
		
		case 1:
		{
			client_cmd( id, "speak ^"items/cliprelease1.wav^"" );

			client_print( id, print_chat, "%s Please make sure that you enable ^"cl_weather^" in to your game console, to experience the Christmas Environment!", szPluginTag );
			menu_destroy( menu );
			
			return PLUGIN_HANDLED;
		}
	}
	
	menu_destroy( menu );

	return PLUGIN_HANDLED;
}

public LOGEvent_BombPlanted( )
{
	if( get_pcvar_num( gCvarChristmasBombSounds ) != 0 )
	{
		emit_sound( 0, CHAN_AUTO, gBombSounds[ BOMB_PLANTED ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	}
}

public LOGEvent_BombDefused( )
{
	if( get_pcvar_num( gCvarChristmasBombSounds ) != 0 )
	{
		emit_sound( 0, CHAN_AUTO, gBombSounds[ BOMB_DEFUSED ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	}
}

public LOGEvent_BombExploded( )
{
	if( get_pcvar_num( gCvarChristmasBombSounds ) != 0 )
	{
		emit_sound( 0, CHAN_AUTO, gBombSounds[ BOMB_EXPLODED ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	}
}

public EVENT_RoundStart( )
{
	new iPlayers[ MAX_PLAYERS ]; 
	new iPlayerCount, iPlayerId;

	get_players( iPlayers, iPlayerCount, "c" );
	
	for( i = 0; i < iPlayerCount; i++ )
	{
   		iPlayerId = iPlayers[ i ];
		
		set_user_rendering( iPlayerId );
		cs_reset_user_model( iPlayerId );

		UTIL_ShadowStatus( iPlayerId, gShadowSpr );
		remove_task( iPlayerId + TASKID_INVIS );
	}

	// --| Reset bomb_planted sound :p
	client_cmd( 0, "wait; speak ^"vox/_period.wav^"" );

	UTIL_RemoveEntities( szGiftClassname );
}

public bacon_GrenadeDeploy( iWeaponEntity )
{
	if( get_pcvar_num( gCvarChristmasGrenade ) == 1 )
	{
		if( pev_valid( iWeaponEntity ) )
		{
    			new id = get_pdata_cbase( iWeaponEntity, m_pPlayer, m_LinuxDiff );
	
			if( is_user_alive( id ) )
			{
				set_pev( id, pev_viewmodel2, szGrenadeModels[ VIEW_MODEL ] );
				set_pev( id, pev_weaponmodel2, szGrenadeModels[ PLAYER_MODEL ] );
			}
		}
	}
}

public bacon_KnifeDeploy( iWeaponEntity )
{
	if( get_pcvar_num( gCvarEnableKnifeCandy ) != 0 )
	{
		if( pev_valid( iWeaponEntity ) )
		{
    			new id = get_pdata_cbase( iWeaponEntity, m_pPlayer, m_LinuxDiff );
	
			if( is_user_alive( id ) )
			{
				set_pev( id, pev_viewmodel2, szCandyKnifeModel );
				set_pev( id, pev_weaponmodel2, szCandyKnifeModelPlayer );
			}
		}
	}
}

public Message_TempEntity( msg_id, msg_dest, msg_ent )
{
	if( get_pcvar_num( gCvarEnableCustomBomb ) == 1 )
	{
		if( get_msg_arg_int( 1 ) == TE_GLOWSPRITE )
		{
			if( get_msg_arg_int( 5 ) == gLedBombSprite )
			{
				return PLUGIN_HANDLED;
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public EVENT_DeathMsg( )
{
	if( get_pcvar_num( gCvarEnablePresents ) == 0 )
	{
		return;
	}

	new iKiller = read_data( 1 );	
	new iVictim = read_data( 2 );

	if( !IS_PLAYER( iVictim ) )
	{
		return;
	}

	if( iVictim == iKiller )
	{
		UTIL_ShadowStatus( iVictim, gShadowSpr );
		remove_task( iVictim + TASKID_INVIS );

		set_user_rendering( iVictim );
		cs_reset_user_model( iVictim );

		return;
	}

	UTIL_ShadowStatus( iVictim, gShadowSpr );
	remove_task( iVictim + TASKID_INVIS );

	set_user_rendering( iVictim );
	cs_reset_user_model( iVictim );

	new Float:flOrigin[ 3 ];
	pev( iVictim, pev_origin, flOrigin );
	
	flOrigin[ 2 ] += -28.0;

	new Float:flAngles[ 3 ];
	pev( iVictim, pev_angles, flAngles );
		
	new iEntity = engfunc( EngFunc_CreateNamedEntity, gInfoTarget );

	if( !pev_valid( iEntity ) )
       	{
		return;
        }

	set_pev( iEntity, pev_classname, szGiftClassname );
	set_pev( iEntity, pev_angles, flAngles );

	engfunc( EngFunc_SetOrigin, iEntity, flOrigin );
	engfunc( EngFunc_SetModel, iEntity, gGiftModels[ random_num( 0, charsmax( gGiftModels ) ) ] );
	
	ExecuteHam( Ham_Spawn, iEntity );

        set_pev( iEntity, pev_solid, SOLID_BBOX );
        set_pev( iEntity, pev_movetype, MOVETYPE_NONE );
	set_pev( iEntity, pev_nextthink, get_gametime( ) + 2.0 );

        engfunc( EngFunc_SetSize, iEntity, Float:{ -23.160000, -13.660000, -0.050000 }, Float:{ 11.470000, 12.780000, 6.720000 } );
        engfunc( EngFunc_DropToFloor, iEntity );
	
	set_rendering( iEntity, kRenderFxGlowShell, random( 256 ), random( 256 ), random( 256 ), kRenderFxNone, 23 );

     	return;
}

public forward_GiftThink( iEntity )
{
	if( pev_valid( iEntity ) )
	{
		set_rendering( iEntity, kRenderFxGlowShell, random( 256 ), random( 256 ), random( 256 ), kRenderFxNone, random_num( 5, 20 ) );
		set_pev( iEntity, pev_nextthink, get_gametime( ) + 2.0 );
	}
}
	
public forward_TouchGift( iEntity, id )
{
        if( !pev_valid( iEntity )
	|| !is_user_alive( id ) )
        {
		return PLUGIN_HANDLED;
        }

	set_hudmessage( random( 256 ), random( 256 ), random( 256 ), -1.0, 0.72, 1, 6.0, 5.0 );

	switch( random( iChristmasGifts ) )
	{
		case GIFT_ARMOR:
		{
			new iArmor = get_pcvar_num( gCvarGiftArmor );
			set_user_armor( id, iArmor );
			
			ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s (%d)", szPluginTag, szGiftNames[ GIFT_ARMOR ], iArmor );
			emit_sound( id, CHAN_ITEM, szPickupArmorSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
		}
	
		case GIFT_ARMOR_KEVLAR:
		{
			new iArmor = get_pcvar_num( gCvarGiftArmor );
			cs_set_user_armor( id, iArmor, CS_ARMOR_VESTHELM );

			ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s (%d)", szPluginTag, szGiftNames[ GIFT_ARMOR_KEVLAR ], iArmor );
			emit_sound( id, CHAN_ITEM, szPickupArmorSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
      		}
		
		case GIFT_AMMO:
		{
			UTIL_GiveWeaponAmmo( id );
			ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s", szPluginTag, szGiftNames[ GIFT_AMMO ] );
		}
		
		case GIFT_BONUS_HEALTH:
		{
			new iBonusHealth = get_pcvar_num( gCvarBonusHealthAmount );
			set_user_health( id, get_user_health( id ) + iBonusHealth );
			
			ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s + (%d HP)", szPluginTag, szGiftNames[ GIFT_BONUS_HEALTH ], iBonusHealth );
			emit_sound( id, CHAN_ITEM, szHealthPickUpSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
		}
		
		case GIFT_RANDOM_GRENADE:
		{
			switch( random_num( 1, 3 ) )
			{
				case 1:
				{
					if( user_has_weapon( id, CSW_HEGRENADE ) )
					{	
						ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s^nYou already have this grenade (HE Grenade)!", szPluginTag, szGiftNames[ GIFT_BONUS_HEALTH ] );
					}
					
					give_item( id, "weapon_hegrenade" );
					ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s (HE Grenade)", szPluginTag, szGiftNames[ GIFT_RANDOM_GRENADE ] );
				}

				case 2:
				{
					give_item( id, "weapon_flashbang" );
					ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s (FB Grenade)", szPluginTag, szGiftNames[ GIFT_RANDOM_GRENADE ] );
				}

				case 3:
				{
					if( user_has_weapon( id, CSW_SMOKEGRENADE ) )
					{	
						ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s^nYou already have this grenade (Smoke Grenade)!", szPluginTag, szGiftNames[ GIFT_BONUS_HEALTH ] );
					}
		
					give_item( id, "weapon_smokegrenade" );
					ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s (Smoke Grenade)", szPluginTag, szGiftNames[ GIFT_RANDOM_GRENADE ] );
				}
			}
			
			emit_sound( id, CHAN_ITEM, szPickupArmorSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
		}
		
		case GIFT_FRAG:
		{
			new iBonusFrags = get_pcvar_num( gCvarBonusFragAmount );

			set_user_frags( id, get_user_frags( id ) + iBonusFrags );
			UTIL_UpdateScoreboard( id );

			ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s (%d Frag%s)", szPluginTag, szGiftNames[ GIFT_FRAG ], iBonusFrags, ( iBonusFrags == 1 ? "" : "s" ) );
			emit_sound( id, CHAN_ITEM, szBonusFragsPickupSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
		}
		
		case GIFT_INVISIBILITY:
		{
			new iInvisDuration = get_pcvar_num( gCvarGiftInvisibilityDuration );
			
			new iSantaHat = gPlayerSantaHat[ id ];

			if( iSantaHat > 0 )
			{
				set_rendering( iSantaHat, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0 );
			}

			UTIL_ShadowStatus( id, 0 );

			set_user_rendering( id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0 );
			set_task( float( iInvisDuration ), "RemovePlayer_InvisGift", id + TASKID_INVIS );
			
			ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s (%d Second%s)", szPluginTag, szGiftNames[ GIFT_INVISIBILITY ], iInvisDuration, ( iInvisDuration == 1 ? "" : "s" )  );
			emit_sound( id, CHAN_ITEM, szInvisPickupSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
		}
		
		case GIFT_RANDOM_GLOW:
		{
			remove_task( id + TASKID_INVIS );
			set_user_rendering( id, kRenderFxGlowShell, random( 256 ), random( 256 ), random( 256 ), kRenderNormal, random( 256 ) );
			
			ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s", szPluginTag, szGiftNames[ GIFT_RANDOM_GLOW ] );
			emit_sound( id, CHAN_ITEM, szGlowPickupSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
		}
		
		case GIFT_RANDOM_HAT_GLOW_EFFECT:
		{
			new iSantaHat = gPlayerSantaHat[ id ];

			if( iSantaHat > 0 )
			{
				set_rendering( iSantaHat, kRenderFxGlowShell, random( 256 ), random( 256 ), random( 256 ), kRenderNormal, 10 );
			}
			
			ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s", szPluginTag, szGiftNames[ GIFT_RANDOM_HAT_GLOW_EFFECT ] );
			emit_sound( id, CHAN_ITEM, szGlowPickupSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
		}
	
		case GIFT_DEFUSER:
		{
			if( get_user_team( id ) == 2 )
			{
				cs_set_user_defuse( id, 1 );
				ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s", szPluginTag, szGiftNames[ GIFT_DEFUSER ] );
				
				emit_sound( id, CHAN_ITEM, szDefuserPickupSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
			}
			
			else
			{
				ShowSyncHudMsg( id, gHudSync, "%s^nGift contained a Defuser Kit, but you are on Terrorist Force!", szPluginTag );
				
				emit_sound( id, CHAN_ITEM, szDefuserPickupSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
			}
		}
		
		case GIFT_CAMOUFLAGE:
		{
			switch( get_user_team( id ) )
			{
				case 1:
				{
					cs_set_user_model( id, gCounterTerrModels[ random_num( 0, charsmax( gCounterTerrModels ) ) ] );
				}
				
				case 2:
				{
					cs_set_user_model( id, gTerroristModels[ random_num( 0, charsmax( gTerroristModels ) ) ] );
				}
			}
			
			ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s", szPluginTag, szGiftNames[ GIFT_CAMOUFLAGE ] );
			emit_sound( id, CHAN_ITEM, szCamouflagePickupSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
		}
		
		case GIFT_MONEY:
		{
			new iMoney = cs_get_user_money( id );
			new iMoneyGift = get_pcvar_num( gCvarGiftMoney );

			cs_set_user_money( id, ( iMoney >= 16000 ) ? 16000 : iMoney + iMoneyGift, 1 );
			ShowSyncHudMsg( id, gHudSync, "%s^nYou picked up:^n%s + ($%d)", szPluginTag, szGiftNames[ GIFT_MONEY ], iMoneyGift );

			emit_sound( id, CHAN_ITEM, szMoneyPickupSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
		}	
	}

        engfunc( EngFunc_RemoveEntity, iEntity );

        return PLUGIN_CONTINUE;
}	

public RemovePlayer_InvisGift( iTaskid )
{
	new id = iTaskid - TASKID_INVIS;
	
	if( IS_PLAYER( id ) )
	{
		new iSantaHat = gPlayerSantaHat[ id ];

		if( iSantaHat > 0 )
		{
			set_rendering( iSantaHat );
		}

		set_hudmessage( random( 256 ), random( 256 ), random( 256 ), -1.0, 0.72, 1, 6.0, 5.0 );
		ShowSyncHudMsg( id, gHudSync, "Invisibility is no longer available" );

		UTIL_ShadowStatus( id, gShadowSpr );

		set_user_rendering( id );
		remove_task( id + TASKID_INVIS );

		emit_sound( id, CHAN_ITEM, szInvisDisabledSound, VOL_NORM, ATTN_NORM, 0 , PITCH_NORM );
	}
}
		
public forward_FM_PlaybackEvent( iFlags, id, eventIndex )
{
	if( get_pcvar_num( gCvarEnableGunSnowballs ) == 0 )
	{
		return FMRES_IGNORED;
	}

	new Float:flAimOrigin[ 3 ];
	
	new iEntity = engfunc( EngFunc_CreateNamedEntity, gInfoTarget );

	if( !pev_valid( iEntity ) )
	{
		return FMRES_IGNORED;
	}

	for( i = 0 ; i < sizeof gGunEvents; i++ )
	{
		if( eventIndex == gEventsIndex[ i ] )
		{
         		UTIL_GetAim_Origin( id, flAimOrigin );
		
			if( engfunc( EngFunc_PointContents, flAimOrigin ) != CONTENTS_SKY )
			{
				set_pev( iEntity, pev_solid, SOLID_NOT );
				set_pev( iEntity, pev_movetype, MOVETYPE_NONE );

				engfunc( EngFunc_SetModel, iEntity, szSnowballModel );
				set_pev( iEntity, pev_classname, szSnowBallClassname );
            
				engfunc( EngFunc_SetOrigin, iEntity, flAimOrigin );
            			set_rendering( iEntity, kRenderFxNoDissipation, 255, 255, 255, kRenderGlow, 255 );
            
				set_pev( iEntity, pev_scale, random_float( 0.2, 0.5 ) );
				set_pev( iEntity, pev_flags, FL_ALWAYSTHINK );
				set_pev( iEntity, pev_nextthink, get_gametime( ) + get_pcvar_float( gCvarGunSnowballDuration ) );
				
				return FMRES_IGNORED;
			}
		}
	}
	
	return FMRES_IGNORED;
}

public bacon_PlayerSpawn( id )
{
	if( get_pcvar_num( gCvarSantaHat ) != 0  )
	{
		if( is_user_alive( id ) )
		{
			switch( get_pcvar_num( gCvarSantaHatAdminOnly ) )
			{
				case 0:	UTIL_SetSantaHat( id );
				case 1:
				{
					if( get_user_flags( id ) & ADMIN_ACCESS_FLAG )
					{
						UTIL_SetSantaHat( id );
					}
				}
			}
		}
	}
}

public EVENT_OnBombDrop( )
{
	if( get_pcvar_num( gCvarEnableCustomBomb ) == 1 )
	{
		new Float:flAngles[ 3 ], iEntity = FM_NULLENT;

		while( ( iEntity = find_ent_by_class( iEntity, "grenade" ) ) )
		{
			if( pev_valid( iEntity ) )
			{
				if( get_pdata_bool( iEntity, m_bIsC4 ) == true )
        			{
					pev( iEntity, pev_angles, flAngles );

					flAngles[ 1 ] += random_float( 1.0, 360.0 );

					engfunc( EngFunc_SetModel, iEntity, szFrostBombModels[ random_num( 0, charsmax( szFrostBombModels ) ) ] );

					set_pev( iEntity, pev_angles, flAngles );
					set_pev( iEntity, pev_effects, EF_DIMLIGHT );

					set_rendering( iEntity, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 50 );
				}
			}
		}
	}
}
					
public forward_FM_SetModel( iEntity, const szModel[ ] )
{	
	if( get_pcvar_num( gCvarChristmasGrenade ) == 1 )
	{
		if( szModel[ 0 ] == 'm' 
		&& szModel[ 7 ] == 'w' 
		&& szModel[ 8 ] == '_' )
		{
			new Float:flDmgTime;
			pev( iEntity, pev_dmgtime, flDmgTime );
    
			if( flDmgTime == 0.0 )
			{
				return FMRES_IGNORED;
			}

			static iGrenadeRGB[ iRGB ];
			static const NUMBER_NINE = 9;

			switch( get_pcvar_num( gCvarChristmasGrenadeType ) )
			{
				case 0:
				{
					if( szModel[ NUMBER_NINE ] == 'h' 
					|| szModel[ NUMBER_NINE ] == 'f' 
					|| szModel[ NUMBER_NINE ] == 's' )
					{
						iGrenadeRGB[ iRed ] = 255;
						iGrenadeRGB[ iGreen ] = 255;
						iGrenadeRGB[ iBlue ] = 255;
					}
				}
				
				case 1:
				{
					switch( szModel[ NUMBER_NINE ] )
					{
						case 'h':
						{
							iGrenadeRGB[ iRed ] = 255;
							iGrenadeRGB[ iGreen ] = 10;
							iGrenadeRGB[ iBlue ] = 10;
						}
						
						case 'f':
						{
							iGrenadeRGB[ iRed ] = 10;
							iGrenadeRGB[ iGreen ] = 10;
							iGrenadeRGB[ iBlue ] = 255;
						}
					
						case 's':
						{
							iGrenadeRGB[ iRed ] = 10;
							iGrenadeRGB[ iGreen ] = 255;
							iGrenadeRGB[ iBlue ] = 10;
						}
					}
				}
					
				case 2:
				{
					iGrenadeRGB[ iRed ] = random( 256 );
					iGrenadeRGB[ iGreen ] = random( 256 );
					iGrenadeRGB[ iBlue ] = random( 256 );
				}
			}
			
			UTIL_Trail( iEntity, iGrenadeRGB[ iRed ], iGrenadeRGB[ iGreen ], iGrenadeRGB[ iBlue ], 200 );
			set_rendering( iEntity, kRenderFxGlowShell, iGrenadeRGB[ iRed ], iGrenadeRGB[ iGreen ], iGrenadeRGB[ iBlue ], kRenderNormal, 120 );
			
			engfunc( EngFunc_SetModel, iEntity, szGrenadeModels[ WORLD_MODEL ] );

		}

		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public bacon_TreeThink( iEntity )
{
	if( pev_valid( iEntity ) )
	{
		set_pev( iEntity, pev_nextthink, get_gametime( ) + 0.8 );
		
		new Float:flOrigin[ 3 ];
		pev( iEntity, pev_origin, flOrigin );

		UTIL_DynamicLight( flOrigin, random( 256 ), random( 256 ), random( 256 ), 255 );
		set_rendering( iEntity, kRenderFxGlowShell, random( 256 ), random( 256 ), random( 256 ), kRenderNormal, random_num( 1, 50 ) );
	}
}

public forward_SnowballThink( iEntity )
{
	if( pev_valid( iEntity ) )
	{
		engfunc( EngFunc_RemoveEntity, iEntity );
	}
}

UTIL_FindSpawnPoints( )
{
	new iCounterTerroristSpawn = engfunc( EngFunc_FindEntityByString, FM_NULLENT, "classname", "info_player_start" );

	if( !iCounterTerroristSpawn )
	{
		return;
	}
	
	new Float:flCounterTerroristOrigin[ 3 ];
	pev( iCounterTerroristSpawn, pev_origin, flCounterTerroristOrigin );
	
	UTIL_CreateChristmasTree( flCounterTerroristOrigin );
	
	new iTerroristSpawn = engfunc( EngFunc_FindEntityByString, FM_NULLENT, "classname", "info_player_deathmatch" );
	
	if( !iTerroristSpawn )
	{
		return;
	}
	
	new Float:flTerroristOrigin[ 3 ];
	pev( iTerroristSpawn, pev_origin, flTerroristOrigin );
	
	UTIL_CreateChristmasTree( flTerroristOrigin );
}

UTIL_CreateChristmasTree( Float:flOrigin[ 3 ] ) 
{	
	new iEntity = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "ambient_generic" ) );
	
	if( !pev_valid( iEntity ) )
	{
		return;
	}

	new Float:flAngles[ 3 ];
	flAngles[ 1 ] += random_float( 1.0, 360.0 );

	set_pev( iEntity, pev_message, szChristmasTreeSong );
	set_pev( iEntity, pev_spawnflags, AMBIENT_SOUND_LARGERADIUS );
	set_pev( iEntity, pev_effects, EF_BRIGHTFIELD );
	set_pev( iEntity, pev_origin, flOrigin );
	set_pev( iEntity, pev_movetype, MOVETYPE_TOSS );
	set_pev( iEntity, pev_health, 1.0 );
	set_pev( iEntity, pev_angles, flAngles );
	set_pev( iEntity, pev_nextthink, get_gametime( ) + 0.8 );
	
	ExecuteHam( Ham_Spawn, iEntity );

	engfunc( EngFunc_SetModel, iEntity, szChristmasTreeModels[ random_num( 0, charsmax( szChristmasTreeModels ) ) ] );
	engfunc( EngFunc_DropToFloor, iEntity );
}

UTIL_RemoveEntities( const szClassname[ ] )
{
	new iEntity = FM_NULLENT;
	
	while( ( iEntity = engfunc( EngFunc_FindEntityByString, FM_NULLENT, "classname", szClassname ) ) )
	{
		engfunc( EngFunc_RemoveEntity, iEntity );
	}
}

UTIL_SetSantaHat( id )
{
	engfunc( EngFunc_RemoveEntity, gPlayerSantaHat[ id ] );

	new iEntity = gPlayerSantaHat[ id ] = engfunc( EngFunc_CreateNamedEntity, gInfoTarget );
	
	if( pev_valid( iEntity ) )
	{
		engfunc( EngFunc_SetModel, iEntity, gSantaHatModels[ random_num( 0, charsmax( gSantaHatModels ) ) ] );

		set_pev( iEntity, pev_movetype, MOVETYPE_FOLLOW );
		set_pev( iEntity, pev_aiment, id );
		set_pev( iEntity, pev_owner, id );
		
		set_rendering( iEntity );
	}
}

UTIL_DynamicLight( Float:flOrigin[ 3 ], r, g, b, a )
{
	engfunc( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin );
	write_byte( TE_DLIGHT );
	engfunc( EngFunc_WriteCoord, flOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, flOrigin[ 2 ] );
	write_byte( 30 );
	write_byte( r );
	write_byte( g );
	write_byte( b );
	write_byte( a );
	write_byte( 40 );
	message_end( );
}

UTIL_GetAim_Origin( index, Float:flOrigin[ 3 ] )
{
	new Float:flStart[ 3 ], Float:flViewOfs[ 3 ];

	pev( index, pev_origin, flStart );
	pev( index, pev_view_ofs, flViewOfs );

	xs_vec_add( flStart, flViewOfs, flStart );
   
	new Float:flDest[ 3 ];
	pev( index, pev_v_angle, flDest );

	engfunc( EngFunc_MakeVectors, flDest );
	global_get( glb_v_forward, flDest );

	xs_vec_mul_scalar( flDest, 9999.0, flDest );
	xs_vec_add( flStart, flDest, flDest );
   
	engfunc( EngFunc_TraceLine, flStart, flDest, 0, index, 0 );
   	get_tr2( 0, TR_vecEndPos, flOrigin );
   
	return 1;
}

UTIL_ShadowStatus( const id, iStatus )
{
	message_begin( MSG_ONE_UNRELIABLE, gMessageShadowIdx, _, id );
	write_long( iStatus );
	message_end( );
}

UTIL_UpdateScoreboard( id )
{
	message_begin( MSG_ALL, gMessageScoreInfo );
	write_byte( id );
	write_short( get_user_frags( id ) );
	write_short( get_user_deaths(id ) );
	write_short( 0 );
	write_short( get_user_team( id ) ); 
	message_end( );
}

UTIL_Trail( index, iR, iG, iB, iAlpha )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );              
	write_short( index );      
	write_short( gTrailSprite );        
	write_byte( 25 );              
	write_byte( 5 );               
	write_byte( iR );            
	write_byte( iG );           
	write_byte( iB );            
	write_byte( iAlpha );                
	message_end( );
}

UTIL_GiveWeaponAmmo( index )
{
	new szCopyAmmoData[ 40 ];
	
	switch( get_user_weapon( index ) )
	{
		case CSW_P228: copy( szCopyAmmoData, charsmax( szCopyAmmoData ), "ammo_357sig" );
		case CSW_SCOUT, CSW_G3SG1, CSW_AK47: copy( szCopyAmmoData, charsmax( szCopyAmmoData ), "ammo_762nato" );
		case CSW_XM1014, CSW_M3: copy( szCopyAmmoData, charsmax( szCopyAmmoData ), "ammo_buckshot" );
		case CSW_MAC10, CSW_UMP45, CSW_USP: copy( szCopyAmmoData, charsmax( szCopyAmmoData ), "ammo_45acp" );
		case CSW_SG550, CSW_GALIL, CSW_FAMAS, CSW_M4A1, CSW_SG552, CSW_AUG: copy( szCopyAmmoData, charsmax( szCopyAmmoData ), "ammo_556nato" );
		case CSW_ELITE, CSW_GLOCK18, CSW_MP5NAVY, CSW_TMP: copy( szCopyAmmoData, charsmax( szCopyAmmoData ), "ammo_9mm" );
		case CSW_AWP: copy( szCopyAmmoData, charsmax( szCopyAmmoData ), "ammo_338magnum" );
		case CSW_M249: copy( szCopyAmmoData, charsmax( szCopyAmmoData ), "ammo_556natobox" );
		case CSW_FIVESEVEN, CSW_P90: copy( szCopyAmmoData, charsmax( szCopyAmmoData ), "ammo_57mm" );
		case CSW_DEAGLE: copy( szCopyAmmoData, charsmax( szCopyAmmoData ), "ammo_50ae" );
	}
	
	give_item( index, szCopyAmmoData );
	give_item( index, szCopyAmmoData );
	give_item( index, szCopyAmmoData );
}

#if AMXX_VERSION_NUM < 183
	bool:get_pdata_bool( ent, charbased_offset, intbase_linuxdiff = 5 ) 
	{
		return !!( get_pdata_int( ent, charbased_offset / INT_BYTES, intbase_linuxdiff ) & ( 0xFF << ( ( charbased_offset % INT_BYTES ) * BYTE_BITS ) ) ); 
	}
#endif
