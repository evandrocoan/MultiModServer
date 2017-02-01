//Bf2 Rank Mod effects File
//Contains subroutines for all graphical features.


#if defined effects_included
  #endinput
#endif
#define effects_included


// Creates an icon above target players head. Used to displays rank icon

stock Create_TE_PLAYERATTACHMENT(id, entity, vOffset, iSprite, life)
{

	message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, { 0, 0, 0 }, id )
	write_byte( TE_PLAYERATTACHMENT )
	write_byte( entity )			// entity
	write_coord( vOffset )			// vertical offset ( attachment origin.z = player origin.z + vertical offset )
	write_short( iSprite )			// model index
	write_short( life )				// (life * 10 )
	message_end()
}

// Makes the users screen flash given colour

public screen_flash(id,red,green,blue,alpha)
{
        message_begin( MSG_ONE_UNRELIABLE , gmsgScreenFade , {0,0,0} , id );
        write_short( 1<<12 );
        write_short( 1<<12 );
        write_short( 1<<12 );
        write_byte( red );
        write_byte( green );
        write_byte( blue );
        write_byte( alpha );
        message_end();
}

//Makes a player glow the given colour

public player_glow(id,red,green,blue)
{
	fm_set_rendering(id,kRenderFxGlowShell,red,green,blue,kRenderNormal,16)

	set_task(1.0,"player_noglow",id)
}

//Resets player to not glowing

public player_noglow(id)
{
	fm_set_rendering(id,kRenderFxGlowShell,0,0,0,kRenderNormal,16)
	set_invis(id)

}