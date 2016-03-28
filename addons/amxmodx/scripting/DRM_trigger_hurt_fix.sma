#include <amxmodx>
#include <fakemeta>

#define MAX_TRIGGERS 300

new Float:g_flHurtMins[ MAX_TRIGGERS ][ 3 ];
new Float:g_flHurtMaxs[ MAX_TRIGGERS ][ 3 ];
new g_iHurt[ MAX_TRIGGERS ];
new g_iCount;

public plugin_init() {
	register_plugin( "DRM: trigger_hurt fix", "1.3", "coderiz / xPaw" );
	
	// Searching for 'trigger_hurt'
	new iEntity, szTarget[ 32 ];
	new iSize = charsmax( szTarget );
	
	while( ( iEntity = engfunc( EngFunc_FindEntityByString, iEntity, "classname", "trigger_hurt" ) ) > 0 ) {
		pev( iEntity, pev_targetname, szTarget, iSize );
		
		if( equal( szTarget, "" ) ) {
			pev( iEntity, pev_absmin, g_flHurtMins[ g_iCount ] );
			pev( iEntity, pev_absmax, g_flHurtMaxs[ g_iCount ] );
			
			g_iHurt[ g_iCount ] = iEntity;
			g_iCount++;
		}
	}
	
	// if found any 'trigger_hurt' lets active PlayerPreThink forward.
	if( g_iCount > 0 )
		register_forward(FM_PlayerPreThink, "FwdPlayerPreThink");
}

public FwdPlayerPreThink( id ) {
	if( !is_user_alive( id ) )
		return FMRES_IGNORED;
	
	if( pev( id, pev_solid ) != SOLID_NOT )
		return FMRES_IGNORED;
	
	static Float:flMins[ 3 ], Float:flMaxs[ 3 ];
	
	pev( id, pev_absmin, flMins );
	pev( id, pev_absmax, flMaxs );
	
	for( new i = 0; i < g_iCount; i++ )
		if( !( g_flHurtMins[i][0] > flMaxs[0] || g_flHurtMaxs[i][0] < flMins[0] )
		&& !( g_flHurtMins[i][1] > flMaxs[1] || g_flHurtMaxs[i][1] < flMins[1] )
		&& !( g_flHurtMins[i][2] > flMaxs[2] || g_flHurtMaxs[i][2] < flMins[2] ) ) {
			dllfunc( DLLFunc_Touch, id, g_iHurt[i] );
			dllfunc( DLLFunc_Touch, g_iHurt[i], id );
		}
	
	return FMRES_IGNORED;
}