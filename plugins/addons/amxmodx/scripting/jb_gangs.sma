	
	/*
			Jailbreak Gang System
			H3avY Ra1n
	
			Description
			-----------
			This plugin allows prisoners to create gangs and upgrade specific skills that apply to everybody in the gang.
	
	
			Gang Menu
			---------
			Create a Gang 		- Allows a user to create a gang by paying money.
			Invite to Gang 		- Only the leader of the gang can invite people to the gang.
			Skills 				- Opens the skills menu, where any member of the gang can pay money to upgrade their skills.
			Top-10 				- Shows a MOTD with the top10 gangs, SORTED BY KILLS. (If you have a good way to sort it, please post it below)
			Leave Gang 			- Allows a player to leave the gang. The leader cannot leave the gang until he transfers leadership to somebody else (explained later).
			Gang Leader Menu 	- Shows a menu with options to disband the gang, kick a player from the gang, or transfer leadership to somebody else in the gang.
			Online Members 		- Shows a list of gang members that are currently in the server.
	
	
			Skills
			------
			HP - Increased health
			Stealing - Increased money earnings.
			Gravity - Lower Gravity
			Damage - Increased damage
			Stamina - Gives higher speed to players.
			Weapon Drop - Chance of making the guard drop the weapon when you knife them. (%1 chance increase per level)
	
	
			CVARS
			-----
			jb_gang_cost 		- The cost to create a gang.
			jb_health_cost 		- The cost to upgrade gang health.
			jb_stealing_cost 	- The cost to upgrade gang money earning.
			jb_gravity_cost 	- The cost to upgrade gang gravity.
			jb_damage_cost 		- The cost to upgrade gang damage.
			jb_stamina_cost 	- The cost to upgrade gang stamina (speed).
			jb_weapondrop_cost 	- The cost to upgrade gang weapon drop percentage.
	
			Additionally there are CVars for the max level for each type of upgrade, so replace _cost above with _max.
			Also there are CVars for the amount per level, so replace _cost above with _per.
			
			jb_points_per_kill	- The amount of points you get for a kill
			jb_headshot_bonus	- The amount of points you get for a headshot
			
			jb_max_members		- The max amount of members a gang can hold
			jb_admin_create		- Whether or not an admin can create gangs without using points
	
			Credits
			-------
			F0RCE 	- Original Plugin Idea
			Exolent	- SQLVault Include
			Drekes 	- Freezetime Fix (I was too lazy) :)
	
	
			Changelog
			---------
			September 26, 2011	- v1.0 - 	Initial Release
			September 27, 2011	- v1.01 - 	Added more cvars, fixed a few bugs.
			September 28, 2011	- v1.1 - 	Added gang admins, jb points instead of money, and a few other things I can't remember :)
			January 21, 2011	- v1.1.1 -	Added a cvar for whether an admin can create a gang without using points.
			January 23, 2011	- v1.1.2 - 	Fixed freezetime problem
	
	
			http://forums.alliedmods.net/showthread.php?p=1563919
	*/

	/* Includes */
		
		#include < amxmodx >
		#include < amxmisc >
		#include < sqlvault_ex >
		#include < cstrike >
		#include < colorchat >
		#include < hamsandwich >
		#include < fun >

	/* Defines */
	
		#define ADMIN_CREATE	ADMIN_LEVEL_B

	/* Constants */
	
		new const g_szVersion[ ] = "1.1.2";

		enum _:GangInfo
		{
			Trie:GangMembers,
			GangName[ 64 ],
			GangHP,
			GangStealing,
			GangGravity,
			GangDamage,
			GangStamina,
			GangWeaponDrop,
			GangKills,
			NumMembers
		};
			
		enum
		{
			VALUE_HP,
			VALUE_STEALING,
			VALUE_GRAVITY,
			VALUE_DAMAGE,
			VALUE_STAMINA,
			VALUE_WEAPONDROP,
			VALUE_KILLS
		}

		enum
		{
			STATUS_NONE,
			STATUS_MEMBER,
			STATUS_ADMIN,
			STATUS_LEADER
		};

		new const g_szGangValues[ ][ ] = 
		{
			"HP",
			"Stealing",
			"Gravity",
			"Damage",
			"Stamina",
			"WeaponDrop",
			"Kills"
		};

		new const g_szPrefix[ ] = "^04[Gang System]^01";

	/* Tries */
	
		new Trie:g_tGangNames;
		new Trie:g_tGangValues;

	/* Vault */
	
		new SQLVault:g_hVault;
		new SQLVault:g_hPointsVault;

	/* Arrays */
	
		new Array:g_aGangs;

	/* Pcvars */
	
		new g_pCreateCost;

		new g_pHealthCost;
		new g_pStealingCost;
		new g_pGravityCost;
		new g_pDamageCost;
		new g_pStaminaCost;
		new g_pWeaponDropCost;

		new g_pHealthMax;
		new g_pStealingMax;
		new g_pGravityMax;
		new g_pDamageMax;
		new g_pStaminaMax;
		new g_pWeaponDropMax;

		new g_pHealthPerLevel;
		new g_pStealingPerLevel;
		new g_pGravityPerLevel;
		new g_pDamagePerLevel;
		new g_pStaminaPerLevel;
		new g_pWeaponDropPerLevel;

		new g_pPointsPerKill;
		new g_pHeadshotBonus;

		new g_pMaxMembers;
		new g_pAdminCreate;

	/* Integers */
	
		new g_iGang[ 33 ];
		new g_iPoints[ 33 ];
		

	public plugin_init()
	{
		register_plugin( "Jailbreak Gang System", g_szVersion, "H3avY Ra1n" );
		
		g_aGangs 				= ArrayCreate( GangInfo );

		g_tGangValues 			= TrieCreate();
		g_tGangNames 			= TrieCreate();
		
		g_hVault 				= sqlv_open_local( "jb_gangs", false );
		sqlv_init_ex( g_hVault );

		g_hPointsVault			= sqlv_open_local( "jb_points", true );
		
		g_pCreateCost			= register_cvar( "jb_gang_cost", 		"50" );
		g_pHealthCost			= register_cvar( "jb_health_cost", 		"20" );
		g_pStealingCost 		= register_cvar( "jb_stealing_cost", 	"20" );
		g_pGravityCost			= register_cvar( "jb_gravity_cost", 	"20" );
		g_pDamageCost			= register_cvar( "jb_damage_cost", 		"20" );
		g_pStaminaCost			= register_cvar( "jb_stamina_cost", 	"20" );
		g_pWeaponDropCost		= register_cvar( "jb_weapondrop_cost", 	"20" );

		g_pHealthMax			= register_cvar( "jb_health_max", 		"10" );
		g_pStealingMax			= register_cvar( "jb_stealing_max", 	"10" );
		g_pGravityMax			= register_cvar( "jb_gravity_max", 		"10" ); // Max * Gravity Per Level must be LESS than 800
		g_pDamageMax			= register_cvar( "jb_damage_max", 		"10" );
		g_pStaminaMax			= register_cvar( "jb_stamina_max", 		"10" );
		g_pWeaponDropMax		= register_cvar( "jb_weapondrop_max", 	"10" );

		g_pHealthPerLevel		= register_cvar( "jb_health_per", 		"10" 	);
		g_pStealingPerLevel		= register_cvar( "jb_stealing_per", 	"0.05" 	);
		g_pGravityPerLevel		= register_cvar( "jb_gravity_per", 		"50" 	);
		g_pDamagePerLevel		= register_cvar( "jb_damage_per", 		"3" 	);
		g_pStaminaPerLevel		= register_cvar( "jb_stamina_per", 		"3" 	);
		g_pWeaponDropPerLevel 	= register_cvar( "jb_weapondrop_per", 	"1" 	);

		g_pPointsPerKill		= register_cvar( "jb_points_per_kill",	"3" );
		g_pHeadshotBonus		= register_cvar( "jb_headshot_bonus",	"2" );
		
		g_pMaxMembers			= register_cvar( "jb_max_members",		"10" );
		g_pAdminCreate			= register_cvar( "jb_admin_create", 	"0" ); // Admins can create gangs without points
		
		register_cvar( "jb_gang_version", g_szVersion, FCVAR_SPONLY | FCVAR_SERVER );
		
		register_menu( "Gang Menu", 1023, "GangMenu_Handler" );
		register_menu( "Skills Menu", 1023, "SkillsMenu_Handler" );
		
		for( new i = 0; i < sizeof g_szGangValues; i++ )
		{
			TrieSetCell( g_tGangValues, g_szGangValues[ i ], i );
		}

		RegisterHam( Ham_Spawn, "player", "Ham_PlayerSpawn_Post", 1 );
		RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Pre", 0 );
		RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Post", 1 );
		RegisterHam( Ham_Item_PreFrame, "player", "Ham_PlayerResetSpeedPost", 1);
		
		register_event( "DeathMsg", "Event_DeathMsg", "a" );
				
		register_clcmd( "say /gang", "Cmd_Gang" );
		register_clcmd( "gang_name", "Cmd_CreateGang" );
		
		LoadGangs();
	}

	public client_disconnect( id )
	{
		g_iGang[ id ] = -1;
		
		new szAuthID[ 35 ];
		get_user_authid( id, szAuthID, charsmax( szAuthID ) );
		
		sqlv_set_num( g_hPointsVault, szAuthID, g_iPoints[ id ] );
	}

	public client_putinserver( id )
	{
		g_iGang[ id ] = get_user_gang( id );
		new szAuthID[ 35 ];
		get_user_authid( id, szAuthID, charsmax( szAuthID ) );
		
		g_iPoints[ id ] = sqlv_get_num( g_hPointsVault, szAuthID );
	}

	public plugin_end()
	{
		SaveGangs();
		sqlv_close( g_hVault );
	}

	public Ham_PlayerSpawn_Post( id )
	{
		if( !is_user_alive( id ) || cs_get_user_team( id ) != CS_TEAM_T )
			return HAM_IGNORED;
			
		if( g_iGang[ id ] == -1 )
		{
			return HAM_IGNORED;
		}
			
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		
		new iHealth = 100 + aData[ GangHP ] * get_pcvar_num( g_pHealthPerLevel );
		set_user_health( id, iHealth );
		
		new iGravity = 800 - ( get_pcvar_num( g_pGravityPerLevel ) * aData[ GangGravity ] );
		set_user_gravity( id, float( iGravity ) / 800.0 );
			
		return HAM_IGNORED;
	}

	public Ham_TakeDamage_Pre( iVictim, iInflictor, iAttacker, Float:flDamage, iBits )
	{
		if( !is_user_alive( iAttacker ) || cs_get_user_team( iAttacker ) != CS_TEAM_T )
			return HAM_IGNORED;
			
		if( g_iGang[ iAttacker ] == -1 )
			return HAM_IGNORED;
		
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ iAttacker ], aData );
		
		SetHamParamFloat( 4, flDamage + ( get_pcvar_num( g_pDamagePerLevel ) * ( aData[ GangDamage ] ) ) );
		
		return HAM_IGNORED;
	}

	public Ham_TakeDamage_Post( iVictim, iInflictor, iAttacker, Float:flDamage, iBits )
	{
		if( !is_user_alive( iAttacker ) || g_iGang[ iAttacker ] == -1 || get_user_weapon( iAttacker ) != CSW_KNIFE || cs_get_user_team( iAttacker ) != CS_TEAM_T  )
		{
			return HAM_IGNORED;
		}
		
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ iAttacker ], aData );
		
		new iChance = aData[ GangWeaponDrop ] * get_pcvar_num( g_pWeaponDropPerLevel );
		
		if( iChance == 0 )
			return HAM_IGNORED;
		
		new bool:bDrop = ( random_num( 1, 100 ) <= iChance );
		
		if( bDrop )
			client_cmd( iVictim, "drop" );
		
		return HAM_IGNORED;
	}

	public Ham_PlayerResetSpeedPost( id )
	{
		if( g_iGang[ id ] == -1 || !is_user_alive( id ) || cs_get_user_team( id ) != CS_TEAM_T )
		{
			return HAM_IGNORED;
		}
		
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		
		if( aData[ GangStamina ] > 0 && get_user_maxspeed( id ) > 1.0 )
			set_user_maxspeed( id, 250.0 + ( aData[ GangStamina ] * get_pcvar_num( g_pStaminaPerLevel ) ) );
			
		return HAM_IGNORED;
	}

	public Event_DeathMsg()
	{
		new iKiller = read_data( 1 );
		new iVictim = read_data( 2 );
		
		if( !is_user_alive( iKiller ) || cs_get_user_team( iVictim ) != CS_TEAM_CT || cs_get_user_team( iKiller ) != CS_TEAM_T )
			return PLUGIN_CONTINUE;
		
		new iTotal = get_pcvar_num( g_pPointsPerKill ) + ( bool:read_data( 3 ) ? get_pcvar_num( g_pHeadshotBonus ) : 0 );
		
		if( g_iGang[ iKiller ] > -1 )
		{
			new aData[ GangInfo ];
			ArrayGetArray( g_aGangs, g_iGang[ iKiller ], aData );
			aData[ GangKills ]++;
			ArraySetArray( g_aGangs, g_iGang[ iKiller ], aData );
			
			iTotal += iTotal * ( aData[ GangStealing ] * get_pcvar_num( g_pStealingPerLevel ) );
		}
		
		g_iPoints[ iKiller ] += iTotal;
		
		return PLUGIN_CONTINUE;
	}

	public Cmd_Gang( id )
	{	
		if( !is_user_connected( id ) || cs_get_user_team( id ) != CS_TEAM_T )
		{
			ColorChat( id, NORMAL, "%s Only ^03prisoners ^01can access this menu.", g_szPrefix );
			return PLUGIN_HANDLED;
		}
		
		static szMenu[ 512 ], iLen, aData[ GangInfo ], iKeys, iStatus;
		
		iKeys = MENU_KEY_0 | MENU_KEY_4;
		
		iStatus = getStatus( id, g_iGang[ id ] );
		
		if( g_iGang[ id ] > -1 )
		{
			ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
			iLen 	= 	formatex( szMenu, charsmax( szMenu ),  "\yGang Menu^n\wCurrent Gang:\y %s^n", aData[ GangName ] );
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\yJB Points: \w%i^n^n", g_iPoints[ id ] );
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r1. \dCreate a Gang [%i Points]^n", get_pcvar_num( g_pCreateCost ) );
		}
		
		else
		{
			iLen 	= 	formatex( szMenu, charsmax( szMenu ),  "\yGang Menu^n\wCurrent Gang:\r None^n" );
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\yJB Points: \w%i^n^n", g_iPoints[ id ] );
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r1. \wCreate a Gang [%i Points]^n", get_pcvar_num( g_pCreateCost ) );
			
			iKeys |= MENU_KEY_1;
		}
		
		
		if( iStatus > STATUS_MEMBER && g_iGang[ id ] > -1 && get_pcvar_num( g_pMaxMembers ) > aData[ NumMembers ] )
		{
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r2. \wInvite Player to Gang^n" );
			iKeys |= MENU_KEY_2;
		}
		else
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r2. \dInvite Player to Gang^n" );
		
		if( g_iGang[ id ] > -1 )
		{
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r3. \wSkills^n" );
			iKeys |= MENU_KEY_3;
		}
		
		else
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r3. \dSkills^n" );
			
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r4. \wTop-10^n" );
		
		if( g_iGang[ id ] > -1 )
		{
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r5. \wLeave Gang^n" );
			iKeys |= MENU_KEY_5;
		}
		
		else
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r5. \dLeave Gang^n" );
		
		
		if( iStatus > STATUS_MEMBER )
		{
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r6. \wGang Admin Menu^n" );
			iKeys |= MENU_KEY_6;
		}
		
		else
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r6. \dGang Admin Menu^n" );
		
		if( g_iGang[ id ] > -1 )
		{
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r7. \wOnline Members^n" );
			iKeys |= MENU_KEY_7;
		}
			
		else
			iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r7. \dOnline Members^n" );
		
		iLen	+=	formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "^n\r0. \wExit" );
		
		show_menu( id, iKeys, szMenu, -1, "Gang Menu" );
		
		return PLUGIN_CONTINUE;
	}

	public GangMenu_Handler( id, iKey )
	{
		switch( ( iKey + 1 ) % 10 )
		{
			case 0: return PLUGIN_HANDLED;
			
			case 1: 
			{
				if( get_pcvar_num( g_pAdminCreate ) && get_user_flags( id ) & ADMIN_CREATE )
				{
					client_cmd( id, "messagemode gang_name" );
				}
				
				else if( g_iPoints[ id ] < get_pcvar_num( g_pCreateCost ) )
				{
					ColorChat( id, NORMAL, "%s You do not have enough points to create a gang!", g_szPrefix );
					return PLUGIN_HANDLED;
				}
				
				else
					client_cmd( id, "messagemode gang_name" );
			}
			
			case 2:
			{
				ShowInviteMenu( id );
			}
			
			case 3:
			{
				ShowSkillsMenu( id );
			}
			
			case 4:
			{
				Cmd_Top10( id );
			}
			
			case 5:
			{
				ShowLeaveConfirmMenu( id );
			}
			
			case 6:
			{
				ShowLeaderMenu( id );
			}
			
			case 7:
			{
				ShowMembersMenu( id );
			}
		}
		
		return PLUGIN_HANDLED;
	}

	public Cmd_CreateGang( id )
	{
		new bool:bAdmin = false;
		
		if( get_pcvar_num( g_pAdminCreate ) && get_user_flags( id ) & ADMIN_CREATE )
		{
			bAdmin = true;
		}
		
		else if( g_iPoints[ id ] < get_pcvar_num( g_pCreateCost ) )
		{
			ColorChat( id, NORMAL, "%s You do not have enough points to create a gang.", g_szPrefix );
			return PLUGIN_HANDLED;
		}
		
		else if( g_iGang[ id ] > -1 )
		{
			ColorChat( id, NORMAL, "%s You cannot create a gang if you are already in one!", g_szPrefix );
			return PLUGIN_HANDLED;
		}
		
		else if( cs_get_user_team( id ) != CS_TEAM_T )
		{
			ColorChat( id, NORMAL, "%s Only ^03prisoners ^01can create gangs!", g_szPrefix );
			return PLUGIN_HANDLED;
		}
		
		new szArgs[ 60 ];
		read_args( szArgs, charsmax( szArgs ) );
		
		remove_quotes( szArgs );
		
		if( TrieKeyExists( g_tGangNames, szArgs ) )
		{
			ColorChat( id, NORMAL, "%s That gang with that name already exists.", g_szPrefix );
			Cmd_Gang( id );
			return PLUGIN_HANDLED;
		}
		
		new aData[ GangInfo ];
		
		aData[ GangName ] 		= szArgs;
		aData[ GangHP ] 		= 0;
		aData[ GangStealing ] 	= 0;
		aData[ GangGravity ] 	= 0;
		aData[ GangStamina ] 	= 0;
		aData[ GangWeaponDrop ] = 0;
		aData[ GangDamage ] 	= 0;
		aData[ NumMembers ] 	= 0;
		aData[ GangMembers ] 	= _:TrieCreate();
		
		ArrayPushArray( g_aGangs, aData );
		
		if( !bAdmin )
			g_iPoints[ id ] -= get_pcvar_num( g_pCreateCost );
		
		set_user_gang( id, ArraySize( g_aGangs ) - 1, STATUS_LEADER );
		
		ColorChat( id, NORMAL, "%s You have successfully created gang '^03%s^01'.", g_szPrefix, szArgs );
		
		return PLUGIN_HANDLED;
	}

	public ShowInviteMenu( id )
	{	
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum );
		
		new szInfo[ 6 ], hMenu;
		hMenu = menu_create( "Choose a Player to Invite:", "InviteMenu_Handler" );
		new szName[ 32 ];
		
		for( new i = 0, iPlayer; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			
			if( iPlayer == id || g_iGang[ iPlayer ] == g_iGang[ id ] || cs_get_user_team( iPlayer ) != CS_TEAM_T )
				continue;
				
			get_user_name( iPlayer, szName, charsmax( szName ) );
			
			num_to_str( iPlayer, szInfo, charsmax( szInfo ) );
			
			menu_additem( hMenu, szName, szInfo );
		}
			
		menu_display( id, hMenu, 0 );
	}

	public InviteMenu_Handler( id, hMenu, iItem )
	{
		if( iItem == MENU_EXIT )
		{
			Cmd_Gang( id );
			return PLUGIN_HANDLED;
		}
		
		new szData[ 6 ], iAccess, hCallback, szName[ 32 ];
		menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, 31, hCallback );
		
		new iPlayer = str_to_num( szData );

		if( !is_user_connected( iPlayer ) )
			return PLUGIN_HANDLED;
			
		ShowInviteConfirmMenu( id, iPlayer );

		ColorChat( id, NORMAL, "%s You have successfully invited %s to join your gang.", g_szPrefix, szName );
		
		Cmd_Gang( id );
		return PLUGIN_HANDLED;
	}

	public ShowInviteConfirmMenu( id, iPlayer )
	{
		new szName[ 32 ];
		get_user_name( id, szName, charsmax( szName ) );
		
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		
		new szMenuTitle[ 128 ];
		formatex( szMenuTitle, charsmax( szMenuTitle ), "%s Invited You to Join	%s", szName, aData[ GangName ] );
		new hMenu = menu_create( szMenuTitle, "InviteConfirmMenu_Handler" );
		
		new szInfo[ 6 ];
		num_to_str( g_iGang[ id ], szInfo, 5 );
		
		menu_additem( hMenu, "Accept Invitation", szInfo );
		menu_additem( hMenu, "Decline Invitation", "-1" );
		
		menu_display( iPlayer, hMenu, 0 );	
	}

	public InviteConfirmMenu_Handler( id, hMenu, iItem )
	{
		if( iItem == MENU_EXIT )
			return PLUGIN_HANDLED;
		
		new szData[ 6 ], iAccess, hCallback;
		menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
		
		new iGang = str_to_num( szData );
		
		if( iGang == -1 )
			return PLUGIN_HANDLED;
		
		if( getStatus( id, g_iGang[ id ] ) == STATUS_LEADER )
		{
			ColorChat( id, NORMAL, "%s You cannot leave your gang while you are the leader.", g_szPrefix );
			return PLUGIN_HANDLED;
		}
		
		set_user_gang( id, iGang );
		
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, iGang, aData );
		
		ColorChat( id, NORMAL, "%s You have successfully joined the gang ^03%s^01.", g_szPrefix, aData[ GangName ] );
		
		return PLUGIN_HANDLED;
	}
		

	public ShowSkillsMenu( id )
	{	
		static szMenu[ 512 ], iLen, iKeys, aData[ GangInfo ];
		
		if( !iKeys )
		{
			iKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_0;
		}
		
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		
		iLen	=	formatex( szMenu, charsmax( szMenu ), "\ySkills Menu^n^n" );
		iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r1. \wHealth Upgrade [\rCost: \y%i Points\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pHealthCost ), aData[ GangHP ], get_pcvar_num( g_pHealthMax ) );
		iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r2. \wStealing Upgrade [\rCost: \y%i Points\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pStealingCost ), aData[ GangStealing ], get_pcvar_num( g_pStealingMax ) );
		iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r3. \wGravity Upgrade [\rCost: \y%i Points\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pGravityCost ), aData[ GangGravity ], get_pcvar_num( g_pGravityMax ) );
		iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r4. \wDamage Upgrade [\rCost: \y%i Points\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pDamageCost ), aData[ GangDamage ], get_pcvar_num( g_pDamageMax ) );
		iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r5. \wWeapon Drop Upgrade [\rCost: \y%i Points\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pWeaponDropCost ), aData[ GangWeaponDrop ], get_pcvar_num( g_pWeaponDropMax ) );
		iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "\r6. \wSpeed Upgrade [\rCost: \y%i Points\w] \y[Level:%i/%i]^n", get_pcvar_num( g_pStaminaCost ), aData[ GangStamina ], get_pcvar_num( g_pStaminaMax ) );
		
		iLen	+=	formatex( szMenu[ iLen ], 511 - iLen, "^n\r0. \wExit" );
		
		show_menu( id, iKeys, szMenu, -1, "Skills Menu" );
	}

	public SkillsMenu_Handler( id, iKey )
	{
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
		
		switch( ( iKey + 1 ) % 10 )
		{
			case 0: 
			{
				Cmd_Gang( id );
				return PLUGIN_HANDLED;
			}
			
			case 1:
			{
				if( aData[ GangHP ] == get_pcvar_num( g_pHealthMax ) )
				{
					ColorChat( id, NORMAL, "%s Your gang is already at the max level for that skill.", g_szPrefix  );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pHealthCost );
				
				if( iRemaining < 0 )
				{
					ColorChat( id, NORMAL, "%s You don't have enough points for that.", g_szPrefix );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				aData[ GangHP ]++;
				
				g_iPoints[ id ] = iRemaining;
			}
			
			case 2:
			{
				if( aData[ GangStealing ] == get_pcvar_num( g_pStealingMax ) )
				{
					ColorChat( id, NORMAL, "%s Your gang is already at the max level for that skill.", g_szPrefix  );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pStealingCost );
				
				if( iRemaining < 0 )
				{
					ColorChat( id, NORMAL, "%s You don't have enough points for that.", g_szPrefix );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				aData[ GangStealing ]++;
				
				g_iPoints[ id ] = iRemaining;
			}
			
			case 3:
			{
				if( aData[ GangGravity ] == get_pcvar_num( g_pGravityMax ) )
				{
					ColorChat( id, NORMAL, "%s Your gang is already at the max level for that skill.", g_szPrefix  );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pGravityCost );
				
				if( iRemaining < 0 )
				{
					ColorChat( id, NORMAL, "%s You don't have enough points for that.", g_szPrefix );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				aData[ GangGravity ]++;
				
				g_iPoints[ id ] = iRemaining;
			}
			
			case 4:
			{
				if( aData[ GangDamage ] == get_pcvar_num( g_pDamageMax ) )
				{
					ColorChat( id, NORMAL, "%s Your gang is already at the max level for that skill.", g_szPrefix  );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pDamageCost );
				
				if( iRemaining < 0 )
				{
					ColorChat( id, NORMAL, "%s You don't have enough points for that.", g_szPrefix );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				aData[ GangDamage ]++;
				
				g_iPoints[ id ] = iRemaining;
			}
			
			case 5:
			{
				if( aData[ GangWeaponDrop ] == get_pcvar_num( g_pWeaponDropMax ) )
				{
					ColorChat( id, NORMAL, "%s Your gang is already at the max level for that skill.", g_szPrefix  );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pWeaponDropCost );
				
				if( iRemaining < 0 )
				{
					ColorChat( id, NORMAL, "%s You don't have enough points for that.", g_szPrefix );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				aData[ GangWeaponDrop ]++;
				
				g_iPoints[ id ] = iRemaining;
			}
			
			case 6:
			{
				if( aData[ GangStamina ] == get_pcvar_num( g_pStaminaMax ) )
				{
					ColorChat( id, NORMAL, "%s Your gang is already at the max level for that skill.", g_szPrefix  );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				new iRemaining = g_iPoints[ id ] - get_pcvar_num( g_pStaminaCost );
				
				if( iRemaining < 0 )
				{
					ColorChat( id, NORMAL, "%s You don't have enough points for that.", g_szPrefix );
					ShowSkillsMenu( id );
					return PLUGIN_HANDLED;
				}
				
				aData[ GangStamina ]++;
				
				g_iPoints[ id ] = iRemaining;
			}
		}
		
		ArraySetArray( g_aGangs, g_iGang[ id ], aData );
		
		new iPlayers[ 32 ], iNum, iPlayer;
		new szName[ 32 ];
		get_players( iPlayers, iNum );
		
		for( new i = 0; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			if( iPlayer == id || g_iGang[ iPlayer ] != g_iGang[ id ] )
				continue;
				
			ColorChat( iPlayer, NORMAL, "%s ^03%s ^01has just upgraded one of your gang's skills.", g_szPrefix, szName );
		}
		
		ColorChat( id, NORMAL, "%s You have successfully upgraded your gang.", g_szPrefix );
		
		ShowSkillsMenu( id );
		
		return PLUGIN_HANDLED;
	}
			
		
	public Cmd_Top10( id )
	{
		new iSize = ArraySize( g_aGangs );
		
		new iOrder[ 100 ][ 2 ];
		
		new aData[ GangInfo ];
		
		for( new i = 0; i < iSize; i++ )
		{
			ArrayGetArray( g_aGangs, i, aData );
			
			iOrder[ i ][ 0 ] = i;
			iOrder[ i ][ 1 ] = aData[ GangKills ];
		}
		
		SortCustom2D( iOrder, iSize, "Top10_Sort" );
		
		new szMessage[ 2048 ];
		formatex( szMessage, charsmax( szMessage ), "<body bgcolor=#000000><font color=#FFB000><pre>" );
		format( szMessage, charsmax( szMessage ), "%s%2s %-22.22s %7s %4s %10s %9s %9s %11s %8s^n", szMessage, "#", "Name", "Kills", "HP", "Stealing", 
			"Gravity", "Stamina", "WeaponDrop", "Damage" );
			
		for( new i = 0; i < min( 10, iSize ); i++ )
		{
			ArrayGetArray( g_aGangs, iOrder[ i ][ 0 ], aData );
			
			format( szMessage, charsmax( szMessage ), "%s%-2d %22.22s %7d %4d %10d %9d %9d %11d %8d^n", szMessage, i + 1, aData[ GangName ], 
			aData[ GangKills ], aData[ GangHP ], aData[ GangStealing ], aData[ GangGravity ], aData[ GangStamina], aData[ GangWeaponDrop ], aData[ GangDamage ] );
		}
		
		show_motd( id, szMessage, "Gang Top 10" );
	}

	public Top10_Sort( const iElement1[ ], const iElement2[ ], const iArray[ ], szData[], iSize ) 
	{
		if( iElement1[ 1 ] > iElement2[ 1 ] )
			return -1;
		
		else if( iElement1[ 1 ] < iElement2[ 1 ] )
			return 1;
		
		return 0;
	}

	public ShowLeaveConfirmMenu( id )
	{
		new hMenu = menu_create( "Are you sure you want to leave?", "LeaveConfirmMenu_Handler" );
		menu_additem( hMenu, "Yes, Leave Now", "0" );
		menu_additem( hMenu, "No, Don't Leave", "1" );
		
		menu_display( id, hMenu, 0 );
	}

	public LeaveConfirmMenu_Handler( id, hMenu, iItem )
	{
		if( iItem == MENU_EXIT )
			return PLUGIN_HANDLED;
		
		new szData[ 6 ], iAccess, hCallback;
		menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
		
		switch( str_to_num( szData ) )
		{
			case 0: 
			{
				if( getStatus( id, g_iGang[ id ] ) == STATUS_LEADER )
				{
					ColorChat( id, NORMAL, "%s You must transfer leadership before leaving this gang.", g_szPrefix );
					Cmd_Gang( id );
					
					return PLUGIN_HANDLED;
				}
				
				ColorChat( id, NORMAL, "%s You have successfully left your gang.", g_szPrefix );
				set_user_gang( id, -1 );
				Cmd_Gang( id );
			}
			
			case 1: Cmd_Gang( id );
		}
		
		return PLUGIN_HANDLED;
	}

	public ShowLeaderMenu( id )
	{
		new hMenu = menu_create( "Gang Leader Menu", "LeaderMenu_Handler" );
		
		new iStatus = getStatus( id, g_iGang[ id ] );
		
		if( iStatus == STATUS_LEADER )
		{
			menu_additem( hMenu, "Disband Gang", "0" );
			menu_additem( hMenu, "Transfer Leadership", "1" );
			menu_additem( hMenu, "Add An Admin", "4" );
			menu_additem( hMenu, "Remove An Admin", "5" );
		}
		
		menu_additem( hMenu, "Kick From Gang", "2" );
		menu_additem( hMenu, "Change Gang Name", "3" );
		
		
		menu_display( id, hMenu, 0 );
	}

	public LeaderMenu_Handler( id, hMenu, iItem )
	{
		if( iItem == MENU_EXIT )
		{
			Cmd_Gang( id );
			return PLUGIN_HANDLED;
		}
		
		new iAccess, hCallback, szData[ 6 ];
		menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
		
		switch( str_to_num( szData ) )
		{
			case 0:
			{
				ShowDisbandConfirmMenu( id );
			}
			
			case 1:
			{
				ShowTransferMenu( id );
			}
			
			case 2:
			{
				ShowKickMenu( id );
			}
			
			case 3:
			{
				client_cmd( id, "messagemode New_Name" );
			}
			
			case 4:
			{
				ShowAddAdminMenu( id );
			}
			
			case 5:
			{
				ShowRemoveAdminMenu( id );
			}
		}
		
		return PLUGIN_HANDLED;
	}

	public ShowDisbandConfirmMenu( id )
	{
		new hMenu = menu_create( "Are you sure you want to disband the gang?", "DisbandConfirmMenu_Handler" );
		menu_additem( hMenu, "Yes, Disband Now", "0" );
		menu_additem( hMenu, "No, Don't Disband", "1" );
		
		menu_display( id, hMenu, 0 );
	}

	public DisbandConfirmMenu_Handler( id, hMenu, iItem )
	{
		if( iItem == MENU_EXIT )
			return PLUGIN_HANDLED;
		
		new szData[ 6 ], iAccess, hCallback;
		menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, _, _, hCallback );
		
		switch( str_to_num( szData ) )
		{
			case 0: 
			{
				
				ColorChat( id, NORMAL, "%s You have successfully disbanded your gang.", g_szPrefix );
				
				new iPlayers[ 32 ], iNum;
				
				get_players( iPlayers, iNum );
				
				new iPlayer;
				
				for( new i = 0; i < iNum; i++ )
				{
					iPlayer = iPlayers[ i ];
					
					if( iPlayer == id )
						continue;
					
					if( g_iGang[ id ] != g_iGang[ iPlayer ] )
						continue;

					ColorChat( iPlayer, NORMAL, "%s Your gang has been disband by its leader.", g_szPrefix );
					set_user_gang( iPlayer, -1 );
				}
				
				new iGang = g_iGang[ id ];
				
				set_user_gang( id, -1 );
				
				ArrayDeleteItem( g_aGangs, iGang );

				Cmd_Gang( id );
			}
			
			case 1: Cmd_Gang( id );
		}
		
		return PLUGIN_HANDLED;
	}

	public ShowTransferMenu( id )
	{
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "e", "TERRORIST" );
		
		new hMenu = menu_create( "Transfer Leadership to:", "TransferMenu_Handler" );
		new szName[ 32 ], szData[ 6 ];
		
		for( new i = 0, iPlayer; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			if( g_iGang[ iPlayer ] != g_iGang[ id ] || id == iPlayer )
				continue;
				
			get_user_name( iPlayer, szName, charsmax( szName ) );
			num_to_str( iPlayer, szData, charsmax( szData ) );
			
			menu_additem( hMenu, szName, szData );
		}
		
		menu_display( id, hMenu, 0 );
	}

	public TransferMenu_Handler( id, hMenu, iItem )
	{
		if( iItem == MENU_EXIT )
		{
			ShowLeaderMenu( id );
			return PLUGIN_HANDLED;
		}
		
		new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
		
		menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, charsmax( szName ), hCallback );
		
		new iPlayer = str_to_num( szData );
		
		if( !is_user_connected( iPlayer ) )
		{
			ColorChat( id, NORMAL, "%s That player is no longer connected.", g_szPrefix );
			ShowTransferMenu( id );
			return PLUGIN_HANDLED;
		}
		
		set_user_gang( iPlayer, g_iGang[ id ], STATUS_LEADER );
		set_user_gang( id, g_iGang[ id ], STATUS_ADMIN );
		
		Cmd_Gang( id );
		
		new iPlayers[ 32 ], iNum, iTemp;
		get_players( iPlayers, iNum );

		for( new i = 0; i < iNum; i++ )
		{
			iTemp = iPlayers[ i ];
			
			if( iTemp == iPlayer )
			{
				ColorChat( iTemp, NORMAL, "%s You are the new leader of your gang.", g_szPrefix );
				continue;
			}
			
			else if( g_iGang[ iTemp ] != g_iGang[ id ] )
				continue;
			
			ColorChat( iTemp, NORMAL, "%s ^03%s^01 is the new leader of your gang.", g_szPrefix, szName );
		}
		
		return PLUGIN_HANDLED;
	}


	public ShowKickMenu( id )
	{
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum );
		
		new hMenu = menu_create( "Kick Player From Gang:", "KickMenu_Handler" );
		new szName[ 32 ], szData[ 6 ];
		
		
		for( new i = 0, iPlayer; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			if( g_iGang[ iPlayer ] != g_iGang[ id ] || id == iPlayer )
				continue;
				
			get_user_name( iPlayer, szName, charsmax( szName ) );
			num_to_str( iPlayer, szData, charsmax( szData ) );
			
			menu_additem( hMenu, szName, szData );
		}
		
		menu_display( id, hMenu, 0 );
	}

	public KickMenu_Handler( id, hMenu, iItem )
	{
		if( iItem == MENU_EXIT )
		{
			ShowLeaderMenu( id );
			return PLUGIN_HANDLED;
		}
		
		new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
		
		menu_item_getinfo( hMenu, iItem, iAccess, szData, 5, szName, charsmax( szName ), hCallback );
		
		new iPlayer = str_to_num( szData );
		
		if( !is_user_connected( iPlayer ) )
		{
			ColorChat( id, NORMAL, "%s That player is no longer connected.", g_szPrefix );
			ShowTransferMenu( id );
			return PLUGIN_HANDLED;
		}
		
		set_user_gang( iPlayer, -1 );
		
		Cmd_Gang( id );
		
		new iPlayers[ 32 ], iNum, iTemp;
		get_players( iPlayers, iNum );
		
		for( new i = 0; i < iNum; i++ )
		{
			iTemp = iPlayers[ i ];
			
			if( iTemp == iPlayer || g_iGang[ iTemp ] != g_iGang[ id ] )
				continue;
			
			ColorChat( iTemp, NORMAL, "%s ^03%s^01 has been kicked from the gang.", g_szPrefix, szName );
		}
		
		ColorChat( iPlayer, NORMAL, "%s You have been kicked from your gang.", g_szPrefix, szName );
		
		return PLUGIN_HANDLED;
	}

	public ChangeName_Handler( id )
	{
		if( g_iGang[ id ] == -1 || getStatus( id, g_iGang[ id ] ) == STATUS_MEMBER )
		{
			return;
		}
		
		new iGang = g_iGang[ id ];
		
		new szArgs[ 64 ];
		read_args( szArgs, charsmax( szArgs ) );
		
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum );
		
		new bool:bInGang[ 33 ];
		new iStatus[ 33 ];
		
		for( new i = 0, iPlayer; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			if( g_iGang[ id ] != g_iGang[ iPlayer ] )
				continue;
		
			bInGang[ iPlayer ] = true;
			iStatus[ iPlayer ] = getStatus( id, iGang );
			
			set_user_gang( iPlayer, -1 );
		}
		
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, iGang, aData );
		
		aData[ GangName ] = szArgs;
		
		ArraySetArray( g_aGangs, iGang, aData );
		
		for( new i = 0, iPlayer; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			if( !bInGang[ iPlayer ] )
				continue;
			
			set_user_gang( iPlayer, iGang, iStatus[ id ] );
		}
	}
		
	public ShowAddAdminMenu( id )
	{
		new iPlayers[ 32 ], iNum;
		new szName[ 32 ], szData[ 6 ];
		new hMenu = menu_create( "Choose a Player to Promote:", "AddAdminMenu_Handler" );
		
		get_players( iPlayers, iNum );
		
		for( new i = 0, iPlayer; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			if( g_iGang[ id ] != g_iGang[ iPlayer ] || getStatus( iPlayer, g_iGang[ iPlayer ] ) > STATUS_MEMBER )
				continue;
			
			get_user_name( iPlayer, szName, charsmax( szName ) );
			
			num_to_str( iPlayer, szData, charsmax( szData ) );
			
			menu_additem( hMenu, szName, szData );
		}
		
		menu_display( id, hMenu, 0 );
	}

	public AddAdminMenu_Handler( id, hMenu, iItem )
	{
		if( iItem == MENU_EXIT )
		{
			menu_destroy( hMenu );
			ShowLeaderMenu( id );
			return PLUGIN_HANDLED;
		}
		
		new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
		
		menu_item_getinfo( hMenu, iItem, iAccess, szData, charsmax( szData ), szName, charsmax( szName ), hCallback );
		
		new iChosen = str_to_num( szData );
		
		if( !is_user_connected( iChosen ) )
		{
			menu_destroy( hMenu );
			ShowLeaderMenu( id );
			return PLUGIN_HANDLED;
		}
		
		set_user_gang( iChosen, g_iGang[ id ], STATUS_LEADER );
		
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum );
		
		for( new i = 0, iPlayer; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			if( g_iGang[ iPlayer ] != g_iGang[ id ] || iPlayer == iChosen )
				continue;
			
			ColorChat( iPlayer, NORMAL, "%s ^03%s ^01has been promoted to an admin of your gang.", g_szPrefix, szName );
		}
		
		ColorChat( iChosen, NORMAL, "%s ^01You have been promoted to an admin of your gang.", g_szPrefix );
		
		menu_destroy( hMenu );
		return PLUGIN_HANDLED;
	}

	public ShowRemoveAdminMenu( id )
	{
		new iPlayers[ 32 ], iNum;
		new szName[ 32 ], szData[ 6 ];
		new hMenu = menu_create( "Choose a Player to Demote:", "RemoveAdminMenu_Handler" );
		
		get_players( iPlayers, iNum );
		
		for( new i = 0, iPlayer; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			if( g_iGang[ id ] != g_iGang[ iPlayer ] || getStatus( iPlayer, g_iGang[ iPlayer ] ) != STATUS_ADMIN )
				continue;
			
			get_user_name( iPlayer, szName, charsmax( szName ) );
			
			num_to_str( iPlayer, szData, charsmax( szData ) );
			
			menu_additem( hMenu, szName, szData );
		}
		
		menu_display( id, hMenu, 0 );
	}

	public RemoveAdminMenu_Handler( id, hMenu, iItem )
	{
		if( iItem == MENU_EXIT )
		{
			menu_destroy( hMenu );
			ShowLeaderMenu( id );
			return PLUGIN_HANDLED;
		}
		
		new iAccess, hCallback, szData[ 6 ], szName[ 32 ];
		
		menu_item_getinfo( hMenu, iItem, iAccess, szData, charsmax( szData ), szName, charsmax( szName ), hCallback );
		
		new iChosen = str_to_num( szData );
		
		if( !is_user_connected( iChosen ) )
		{
			menu_destroy( hMenu );
			ShowLeaderMenu( id );
			return PLUGIN_HANDLED;
		}
		
		set_user_gang( iChosen, g_iGang[ id ], STATUS_MEMBER );
		
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum );
		
		for( new i = 0, iPlayer; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			if( g_iGang[ iPlayer ] != g_iGang[ id ] || iPlayer == iChosen )
				continue;
			
			ColorChat( iPlayer, NORMAL, "%s ^03%s ^01has been demoted from being an admin of your gang.", g_szPrefix, szName );
		}
		
		ColorChat( iChosen, NORMAL, "%s ^01You have been demoted from being an admin of your gang.", g_szPrefix );
		
		menu_destroy( hMenu );
		return PLUGIN_HANDLED;
	}
		
	public ShowMembersMenu( id )
	{
		new szName[ 64 ], iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum );
		
		new hMenu = menu_create( "Online Members:", "MemberMenu_Handler" );
		
		for( new i = 0, iPlayer; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			if( g_iGang[ id ] != g_iGang[ iPlayer ] )
				continue;
			
			get_user_name( iPlayer, szName, charsmax( szName ) );
			
			switch( getStatus( iPlayer, g_iGang[ id ] ) )
			{
				case STATUS_MEMBER:
				{
					add( szName, charsmax( szName ), " \r[Member]" );
				}
				
				case STATUS_ADMIN:
				{
					add( szName, charsmax( szName ), " \r[Admin]" );
				}
				
				case STATUS_LEADER:
				{
					add( szName, charsmax( szName ), " \r[Leader]" );
				}
			}

			menu_additem( hMenu, szName );
		}
		
		menu_display( id, hMenu, 0 );
	}

	public MemberMenu_Handler( id, hMenu, iItem )
	{
		if( iItem == MENU_EXIT )
		{
			menu_destroy( hMenu );
			Cmd_Gang( id );
			return PLUGIN_HANDLED;
		}
		
		menu_destroy( hMenu );
		
		ShowMembersMenu( id )
		return PLUGIN_HANDLED;
	}

	// Credits to Tirant from zombie mod and xOR from xRedirect
	public LoadGangs()
	{
		new szConfigsDir[ 60 ];
		get_configsdir( szConfigsDir, charsmax( szConfigsDir ) );
		add( szConfigsDir, charsmax( szConfigsDir ), "/jb_gangs.ini" );
		
		new iFile = fopen( szConfigsDir, "rt" );
		
		new aData[ GangInfo ];
		
		new szBuffer[ 512 ], szData[ 6 ], szValue[ 6 ], i, iCurGang;
		
		while( !feof( iFile ) )
		{
			fgets( iFile, szBuffer, charsmax( szBuffer ) );
			
			trim( szBuffer );
			remove_quotes( szBuffer );
			
			if( !szBuffer[ 0 ] || szBuffer[ 0 ] == ';' ) 
			{
				continue;
			}
			
			if( szBuffer[ 0 ] == '[' && szBuffer[ strlen( szBuffer ) - 1 ] == ']' )
			{
				copy( aData[ GangName ], strlen( szBuffer ) - 2, szBuffer[ 1 ] );
				aData[ GangHP ] = 0;
				aData[ GangStealing ] = 0;
				aData[ GangGravity ] = 0;
				aData[ GangStamina ] = 0;
				aData[ GangWeaponDrop ] = 0;
				aData[ GangDamage ] = 0;
				aData[ GangKills ] = 0;
				aData[ NumMembers ] = 0;
				aData[ GangMembers ] = _:TrieCreate();
				
				if( TrieKeyExists( g_tGangNames, aData[ GangName ] ) )
				{
					new szError[ 256 ];
					formatex( szError, charsmax( szError ), "[JB Gangs] Gang already exists: %s", aData[ GangName ] );
					set_fail_state( szError );
				}
				
				ArrayPushArray( g_aGangs, aData );
				
				TrieSetCell( g_tGangNames, aData[ GangName ], iCurGang );

				log_amx( "Gang Created: %s", aData[ GangName ] );
				
				iCurGang++;
				
				continue;
			}
			
			strtok( szBuffer, szData, 31, szValue, 511, '=' );
			trim( szData );
			trim( szValue );
			
			if( TrieGetCell( g_tGangValues, szData, i ) )
			{
				ArrayGetArray( g_aGangs, iCurGang - 1, aData );
				
				switch( i )
				{					
					case VALUE_HP:
						aData[ GangHP ] = str_to_num( szValue );
					
					case VALUE_STEALING:
						aData[ GangStealing ] = str_to_num( szValue );
					
					case VALUE_GRAVITY:
						aData[ GangGravity ] = str_to_num( szValue );
					
					case VALUE_STAMINA:
						aData[ GangStamina ] = str_to_num( szValue );
					
					case VALUE_WEAPONDROP:
						aData[ GangWeaponDrop ] = str_to_num( szValue );
						
					case VALUE_DAMAGE:
						aData[ GangDamage ] = str_to_num( szValue );
					
					case VALUE_KILLS:
						aData[ GangKills ] = str_to_num( szValue );
				}
				
				ArraySetArray( g_aGangs, iCurGang - 1, aData );
			}
		}
		
		new Array:aSQL;
		sqlv_read_all_ex( g_hVault, aSQL );
		
		new aVaultData[ SQLVaultEntryEx ];
		
		new iGang;
		
		for( i = 0; i < ArraySize( aSQL ); i++ )
		{
			ArrayGetArray( aSQL, i, aVaultData );
			
			if( TrieGetCell( g_tGangNames, aVaultData[ SQLVEx_Key2 ], iGang ) )
			{
				ArrayGetArray( g_aGangs, iGang, aData );
				
				TrieSetCell( aData[ GangMembers ], aVaultData[ SQLVEx_Key1 ], str_to_num( aVaultData[ SQLVEx_Data ] ) );
				
				aData[ NumMembers ]++;
				
				ArraySetArray( g_aGangs, iGang, aData );
			}
		}
		
		fclose( iFile );
	}

	public SaveGangs()
	{
		new szConfigsDir[ 64 ];
		get_configsdir( szConfigsDir, charsmax( szConfigsDir ) );
		
		add( szConfigsDir, charsmax( szConfigsDir ), "/jb_gangs.ini" );
		
		if( file_exists( szConfigsDir ) )
			delete_file( szConfigsDir );
			
		new iFile = fopen( szConfigsDir, "wt" );
			
		new aData[ GangInfo ];
		
		new szBuffer[ 256 ];

		for( new i = 0; i < ArraySize( g_aGangs ); i++ )
		{
			ArrayGetArray( g_aGangs, i, aData );
			
			formatex( szBuffer, charsmax( szBuffer ), "[%s]^n", aData[ GangName ] );
			fputs( iFile, szBuffer );
			
			formatex( szBuffer, charsmax( szBuffer ), "HP=%i^n", aData[ GangHP ] );
			fputs( iFile, szBuffer );
			
			formatex( szBuffer, charsmax( szBuffer ), "Stealing=%i^n", aData[ GangStealing ] );
			fputs( iFile, szBuffer );
			
			formatex( szBuffer, charsmax( szBuffer ), "Gravity=%i^n", aData[ GangGravity ] );
			fputs( iFile, szBuffer );
			
			formatex( szBuffer, charsmax( szBuffer ), "Stamina=%i^n", aData[ GangStamina ] );
			fputs( iFile, szBuffer );
			
			formatex( szBuffer, charsmax( szBuffer ), "WeaponDrop=%i^n", aData[ GangWeaponDrop ] );
			fputs( iFile, szBuffer );
			
			formatex( szBuffer, charsmax( szBuffer ), "Damage=%i^n", aData[ GangDamage ] );
			fputs( iFile, szBuffer );
			
			formatex( szBuffer, charsmax( szBuffer ), "Kills=%i^n^n", aData[ GangKills ] );
			fputs( iFile, szBuffer );
		}
		
		fclose( iFile );
	}
		
		

	set_user_gang( id, iGang, iStatus=STATUS_MEMBER )
	{
		new szAuthID[ 35 ];
		get_user_authid( id, szAuthID, charsmax( szAuthID ) );

		new aData[ GangInfo ];
		
		if( g_iGang[ id ] > -1 )
		{
			ArrayGetArray( g_aGangs, g_iGang[ id ], aData );
			TrieDeleteKey( aData[ GangMembers ], szAuthID );
			aData[ NumMembers ]--;
			ArraySetArray( g_aGangs, g_iGang[ id ], aData );
			
			sqlv_remove_ex( g_hVault, szAuthID, aData[ GangName ] );
		}

		if( iGang > -1 )
		{
			ArrayGetArray( g_aGangs, iGang, aData );
			TrieSetCell( aData[ GangMembers ], szAuthID, iStatus );
			aData[ NumMembers ]++;
			ArraySetArray( g_aGangs, iGang, aData );
			
			sqlv_set_num_ex( g_hVault, szAuthID, aData[ GangName ], iStatus );		
		}

		g_iGang[ id ] = iGang;
		
		return 1;
	}
		
	get_user_gang( id )
	{
		new szAuthID[ 35 ];
		get_user_authid( id, szAuthID, charsmax( szAuthID ) );
		
		new aData[ GangInfo ];
		
		for( new i = 0; i < ArraySize( g_aGangs ); i++ )
		{
			ArrayGetArray( g_aGangs, i, aData );
			
			if( TrieKeyExists( aData[ GangMembers ], szAuthID ) )
				return i;
		}
		
		return -1;
	}
				
	getStatus( id, iGang )
	{
		if( !is_user_connected( id ) || iGang == -1 )
			return STATUS_NONE;
			
		new aData[ GangInfo ];
		ArrayGetArray( g_aGangs, iGang, aData );
		
		new szAuthID[ 35 ];
		get_user_authid( id, szAuthID, charsmax( szAuthID ) );
		
		new iStatus;
		TrieGetCell( aData[ GangMembers ], szAuthID, iStatus );
		
		return iStatus;
	}