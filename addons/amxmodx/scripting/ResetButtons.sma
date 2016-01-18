#include < amxmodx >
#include < engine >

public plugin_init( ) {
	register_plugin( "Reset Buttons", "1.2", "xPaw" );
	
	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );
}

public EventNewRound( ) {
	new iEntity;
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_button" ) ) > 0 )
		call_think( iEntity );
}
