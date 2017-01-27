
/**

https://forums.alliedmods.net/showthread.php?p=1047629?p=1047629

https://www.google.com/search?q=Bad+spawn+preventer+site:forums.alliedmods.net

*/



#include < amxmodx >
#include < engine >
#include < hamsandwich >

new HamHook:g_iFwdTakeDamage, bool:g_bHamHookEnabled;

new const Float:g_flMoves[ ][ 3 ] = { // Credits to Ramono
	{0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
	{0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
	{0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
	{0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
	{0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0}
};

public plugin_init( ) {
	register_plugin( "Bad Spawns Preventer", "1.2", "xPaw" );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn_Pre" );
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn_Post", 1 );
	
	DisableHamForward( g_iFwdTakeDamage = RegisterHam( Ham_TakeDamage, "player", "FwdHamPlayerDamage" ) );
}

public FwdHamPlayerDamage( const id, const iInflictor, const iAttacker, Float:flDamage, iDamageBits )
	return ( iDamageBits == DMG_GENERIC && iAttacker == 0 && flDamage == 200.0 ) ? HAM_SUPERCEDE : HAM_IGNORED;

public FwdHamPlayerSpawn_Pre( const id ) {
	if( !g_bHamHookEnabled ) {
		EnableHamForward( g_iFwdTakeDamage );
		
		g_bHamHookEnabled = true;
	}
}

public FwdHamPlayerSpawn_Post( const id ) {
	if( g_bHamHookEnabled ) {
		DisableHamForward( g_iFwdTakeDamage );
		
		g_bHamHookEnabled = false;
	}
	
	if( is_user_alive( id ) ) {
		new Float:vOrigin[ 3 ], iFlags = entity_get_int( id, EV_INT_flags );
		entity_get_vector( id, EV_VEC_origin, vOrigin );
		
		if( IsUserStuck( id, vOrigin, iFlags ) ) {
			new Float:vNewOrigin[ 3 ], Float:vMins[ 3 ];
			entity_get_vector( id, EV_VEC_mins, vMins );
			
			for( new i = 0; i < sizeof g_flMoves; i++ ) {
				vNewOrigin[ 0 ] = vOrigin[ 0 ] - vMins[ 0 ] * g_flMoves[ i ][ 0 ];
				vNewOrigin[ 1 ] = vOrigin[ 1 ] - vMins[ 1 ] * g_flMoves[ i ][ 1 ];
				vNewOrigin[ 2 ] = vOrigin[ 2 ] - vMins[ 2 ] * g_flMoves[ i ][ 2 ];
				
				if( !IsUserStuck( id, vNewOrigin, iFlags ) ) {
					entity_set_vector( id, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } );
					entity_set_int( id, EV_INT_flags, iFlags | FL_DUCKING );
					
					entity_set_size( id, Float:{ -16.0, -16.0, -18.0 }, Float:{ 16.0, 16.0, 18.0 } );
					entity_set_origin( id, vNewOrigin );
					
					break;
				}
			}
		}
	}
}

bool:IsUserStuck( const id, const Float:vOrigin[ 3 ], const iFlags )
	return bool:( trace_hull( vOrigin, iFlags & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, id, IGNORE_MONSTERS ) & 2 );
