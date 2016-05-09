
#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <amxmisc>

/* Changelog:
 0.1b	Fixed many tag mismatch warnings that appeared only in 1.8.2. (ty Smiley92)
 0.1b	Fixed compatibility issue with 1.8.2 by registering the TraceLine forward as post. This works in both 1.8.2 and 1.8.3. (ty Smiley92)
 0.1c	Fixed issue where if a weapon is created with count of X and then a count change was made of Y it would always be created with original count value X on map change.
 0.1c	Fixed issue where items counts would revert back to one on new round. (ty Arkshine)
 0.2	Fixed issue in am_info table where it would incorrectly show a Change Weapon value when one did not exist. It was data that remained in the variable from the previous row.
 0.2	Changed am_info to display changes exactly as they are applied. If the item is changed and then reverted back to its original type/count/undeleted, it aill appear as unchanged.
 0.2	Increased MaxEntities count to 100. The original value of 50 was too low to accomodate fy_snow. An error will be thrown if this value is reached, the error tells you to increase it.
 0.2	If a change is applied and then the item is deleted, the change details as well as the deletion will be re-applied on map change.
 0.2	Menu callback added to disable type/count change options if the item is currently deleted. You must first Un-delete in order to make changes.
 0.2	Added workaround fix for duplicate last item in config getting loaded into array.
 0.2	Eliminated redundant pev_iuser4 reads. 
 0.2	Fixed issue where weapons could be picked up while the Manager was enabled if the weapon was modified of created.
 0.2b	Changed hud messages to use sync huds to avoid overlapping.
 0.2b	Added glow when aiming at an item. The glow color will change when item is selected.
 0.2b	Fixed permission issue. While players without the flag could not enable/disable the editor, they could manipulate entities while it is enabled.
 0.2c   Added multi-player support. Multiple players can now edit/create armoury entities at the same time. It was never actually documented that this wasn't possible--but now it is.
 0.2c   Made all huds disappear instantly once the manager is disabled. Previously, they would remain for 1~2 seconds while the holdtime expired.
 0.2c   Fixed rendering issue for when the manager is enabled and a deleted entity is hovered over and glows. When the glow is removed, it was rendering back to normal instead of semi-transparent.
 0.2c	Fixed invalid player error in traceline forward. 
 0.2c	Fixed bug when a created entity was deleted. The weapon deletion was not restored on map change.
 0.2c	Fixed bug that was breaking the aim origin returned in traceline. When the user selected to create an entity and exited out of the menu, I was not first checking if the user had an 
	existing entity selected before performing actions on the entity index. This was allowing actions to be taken on an entity index of 0 which was breaking traceline.	
 0.2c	Removed some redundant code.	
 0.3	Changed am_info to make it able to display all entities by allowing the user to specify the starting index as an optional parameter. 12 are displayed per cmd/MOTD.
 0.3	Fixed issue where after an entity was deleted and Armoury Manager disabled, the entity would be invisible but could still be picked up if walked over.
 0.3a	Fixed issue where if a non-armoury_entity existed where the player was aiming, it would not give the HUD to allow a weapon to be created.
 0.3a	Made plugin check all players status when attempting to disable the Armoury Manager to make sure nobody is in the middle of an edit. Previously, only the disable-requester was checked.
 0.3a	Misc code cleanup.
*/

new const Version[] = "0.3a";

#define MAX_PLAYERS 32

const MaxEntities = 100;
const Armoury_NotChanged = -1;
const AM_Permission = ADMIN_RCON;
const AM_EntitiesPerInfoPage = 12;

enum ArmouryInfo
{
	Float:aiOrigin[ 3 ],
	aiOriginalWeaponType,
	aiOriginalWeaponCount,
	bool:aiDeleted,
	bool:aiCreated,
	aiChangeWeaponType,
	aiChangeWeaponCount,
	aiEntityIndex
}

enum ArmouryData
{
	WeaponIndex,
	WeaponName[ 17 ]
}

new const g_ArmouryTypes[][ ArmouryData ] = 
{
	{ CSW_MP5NAVY , "mp5" },
	{ CSW_TMP , "tmp" },
	{ CSW_P90 , "p90" },
	{ CSW_MAC10 , "mac10" },
	{ CSW_AK47 , "ak47" },
	{ CSW_SG552 , "sg552" },
	{ CSW_M4A1 , "m4a1" },
	{ CSW_AUG , "aug" },
	{ CSW_SCOUT , "scout" },
	{ CSW_G3SG1 , "g3sg1" },
	{ CSW_AWP , "awp" },
	{ CSW_M3 , "m3" },
	{ CSW_XM1014 , "xm1014" },
	{ CSW_M249 , "m249" },
	{ CSW_FLASHBANG , "flashbang" },
	{ CSW_HEGRENADE , "he grenade" },
	{ CSW_VEST , "vest" },
	{ CSW_VESTHELM , "vest & helmet" },
	{ CSW_SMOKEGRENADE , "smoke grenade" }
};

new const g_szChangeValues[][] = 
{
	"1",
	"5",
	"10",
	"15",
	"25",
	"50",
	"100"
};

enum ChangeType
{
	ctNone,
	ctCreate,
	ctBase,
	ctCount,
	ctWeaponType
}

enum MenuTypes
{
	mtNone,
	mtType,
	mtCount
}

enum MenuInfo
{
	ChangeType:ctChangeType,
	MenuTypes:mtMenuType
}

enum GlowType
{
	ItemAiming,
	ItemSelected
}

enum ColorRGB
{
	rgbRed,
	rgbGreen,
	rgbBlue
}

new const g_iItemGlowColor[ GlowType ][ ColorRGB ] = 
{
	{ 255 , 255 , 255 },
	{   0 , 255 ,   0 }
}

new g_EntityData[ MaxEntities ][ ArmouryInfo ] , g_SelectedEntity[ MAX_PLAYERS + 1 ] , Float:g_fCurrentOrigin[ MAX_PLAYERS + 1 ][ 3 ] , g_iMapEntityCount , g_AimedEntity[ MAX_PLAYERS + 1 ];
new g_TL_Forward , g_szMapFile[ 64 ] , g_iMenuInfo[ MAX_PLAYERS + 1 ][ MenuInfo ] , g_HUDSyncObj_Action , g_HUDSyncObj_Weapon , g_MaxPlayers;

const m_iType = 34;
const m_iCount = 35;
const XO_Armoury = 4;

#define IsPlayer(%1)		(1<=%1<=g_MaxPlayers)
#define IsArmoury(%1)		(%1[0]=='a'&&%1[1]=='r'&&%1[7]=='_'&&%1[8]=='e'&&%1[12]=='t'&&%1[13]=='y')
#define GetArmouryType(%1)	(g_EntityData[%1][aiChangeWeaponType]==Armoury_NotChanged?g_EntityData[%1][aiOriginalWeaponType]:g_EntityData[%1][aiChangeWeaponType])
#define GetArmouryCount(%1)	(g_EntityData[%1][aiChangeWeaponCount]==Armoury_NotChanged?g_EntityData[%1][aiOriginalWeaponCount]:g_EntityData[%1][aiChangeWeaponCount])

public plugin_init() 
{
	register_plugin( "Armoury Manager" , Version , "bugsy" );

	register_clcmd( "am_enable" , "EnableManager" , AM_Permission , "- Enable Armoury Manager" );
	register_clcmd( "am_disable" , "DisableManager" , AM_Permission , "- Disable Armoury Manager" );
	register_clcmd( "am_deletemapconfig" , "DeleteConfig" , AM_Permission , "- Delete Armoury Manager config for current map" );
	register_clcmd( "am_info" , "DisplayInfo" , AM_Permission , "<optional start index> - Show armoury_entity details" );
	
	register_logevent( "RoundStart" , 2 , "1=Round_Start" ); 
	
	g_MaxPlayers = get_maxplayers();
	
	g_HUDSyncObj_Action = CreateHudSyncObj();
	g_HUDSyncObj_Weapon = CreateHudSyncObj();
	
	//Create file name/location to store map entity data (original status and changes).
	new iPos;
	iPos = get_configsdir( g_szMapFile , charsmax( g_szMapFile ) );
	iPos += copy( g_szMapFile[ iPos ] , charsmax( g_szMapFile ) - iPos  , "/ArmouryManager/" ); 
	mkdir( g_szMapFile );
	get_mapname( g_szMapFile[ iPos ] , charsmax( g_szMapFile ) - iPos );
	
	//If a file exists then this data has already been saved. Load all data into the entity array
	//and then process the changes to the entities that are saved in the file/array.
	if ( file_exists( g_szMapFile ) )
	{
		//Load all entity data into array and return the number of entities loaded.
		g_iMapEntityCount = LoadFile();
		//Process entity changes.
		ProcessEntities();
	}
	else
	{
		//Load all armoury_entity's on the map into the entity array.
		g_iMapEntityCount = LoadEntities();
	}
	
	if ( g_iMapEntityCount == MaxEntities )
	{
		set_fail_state( "Max entities reached, you must increase MaxEntities to a larger value." );
	}
}
	
public client_disconnect( id )
{
	g_SelectedEntity[ id ] = 0;
	g_AimedEntity[ id ] = 0;
	g_fCurrentOrigin[ id ][ 0 ] = 0.0;
	g_fCurrentOrigin[ id ][ 1 ] = 0.0;
	g_fCurrentOrigin[ id ][ 2 ] = 0.0;
	g_iMenuInfo[ id ][ ctChangeType ] = _:ctNone;
	g_iMenuInfo[ id ][ mtMenuType ] = _:mtNone;
}

//This finds any entities in the area where the user is aiming. If an entity is found, the user can select the entity to 
//apply changes to it. If no entity exists, the user can create an entity.
public TraceLine( Float:fStartOrigin[ 3 ] , Float:fEndOrigin[ 3 ] , trConditions , id , trResult )
{
	static iEntity , szClassname[ 15 ] , iMenu , szWeapon[ 21 ] , iArrayIndex , iSelectedBy , bool:bArmouryFound;
	
	if ( !IsPlayer( id ) || ( IsPlayer( id ) && ( ( get_user_flags( id ) & AM_Permission ) != AM_Permission ) ) || ( g_iMenuInfo[ id ][ ctChangeType ] != ctNone ) )
		return;
	
	if ( g_iMapEntityCount == MaxEntities )
	{
		set_hudmessage( 255 , 255 , 255 , -1.0 , 0.25 , .holdtime=0.4 , .channel=-1 );
		ShowSyncHudMsg( id , g_HUDSyncObj_Action , "Max entities reached!^n^nYou must increase MaxEntities value in source and re-compile." );
		return;
	}
	
	//Get end origin of traceline.
	get_tr2( trResult , TR_vecEndPos , fEndOrigin );
	
	//Used to debug error discovered in 0.2c where I was calling pev() on an entity index of 0 which was making the end origin outside the 
	//confines of the map. I will leave this here to see if it somehow comes back.
	if ( engfunc( EngFunc_PointContents , fEndOrigin ) == CONTENTS_SOLID )
	{
		ClearSyncHud( id , g_HUDSyncObj_Action );
		ClearSyncHud( id , g_HUDSyncObj_Weapon );
		set_hudmessage( 255 , 0 , 0 , -1.0 , 0.25 , .holdtime=0.4 , .channel=-1 );
		ShowSyncHudMsg( id , g_HUDSyncObj_Action , "Something broke, tell bugsy." );
		return;
	}
	
	//Look for armoury_entity's within a sphere of the end origin, within 15 units.
	iEntity = -1;
	bArmouryFound = false;
	while ( ( iEntity = find_ent_in_sphere( iEntity , fEndOrigin , 15.0 ) ) )
	{
		pev( iEntity , pev_classname , szClassname , charsmax( szClassname ) );
		if ( IsArmoury( szClassname ) ) 
		{
			bArmouryFound = true;
			break;
		}
	}
	
	//If not currently aiming at an entity and menu not currently open, allow user to create an entity in this location.
	if ( !bArmouryFound )
	{		
		//User currently not aiming at an entity but was previously aiming at an entity. Remove selected glow and make it 
		//appear as it should.
		if ( g_AimedEntity[ id ] )
		{
			iArrayIndex = pev( g_AimedEntity[ id ] , pev_iuser4 );
			set_pev( g_AimedEntity[ id ] , pev_renderfx , kRenderFxNone );
			set_pev( g_AimedEntity[ id ] , pev_renderamt , g_EntityData[ iArrayIndex ][ aiDeleted ] ? 100.0 : 255.0 );
			set_pev( g_AimedEntity[ id ] , pev_rendermode , g_EntityData[ iArrayIndex ][ aiDeleted ] ? kRenderTransColor : kRenderNormal );
			g_AimedEntity[ id ] = 0;
		}
		
		ClearSyncHud( id , g_HUDSyncObj_Action );
		ClearSyncHud( id , g_HUDSyncObj_Weapon );
		set_hudmessage( 255 , 255 , 0 , -1.0 , 0.25 , .holdtime=0.4 , .channel=-1 );
		ShowSyncHudMsg( id , g_HUDSyncObj_Action , "Hold 'Use' to create an item" );
		
		//Player pressing Use button
		if ( ( pev( id , pev_button ) | pev( id , pev_oldbuttons ) ) & IN_USE )
		{
			ClearSyncHud( id , g_HUDSyncObj_Action );
			
			//Get origin of where selection was made so it can be used as location to create entity
			g_fCurrentOrigin[ id ][ 0 ] = fEndOrigin[ 0 ];
			g_fCurrentOrigin[ id ][ 1 ] = fEndOrigin[ 1 ];
			g_fCurrentOrigin[ id ][ 2 ] = fEndOrigin[ 2 ];
				
			g_iMenuInfo[ id ][ ctChangeType ] = _:ctCreate;
			g_iMenuInfo[ id ][ mtMenuType ] = _:mtType;
			ShowTypeMenu( id );
		}
	}//User is hovering over an existing entity and menu not currently open, allow user to edit entity.
	else
	{
		//If an entity is not currently being edited.
		if( !g_SelectedEntity[ id ] )
		{
			iArrayIndex = pev( iEntity , pev_iuser4 );
			iSelectedBy = pev( iEntity , pev_iuser3 );
			
			if ( !iSelectedBy )
			{
				if ( ( g_AimedEntity[ id ] != iEntity ) )
				{
					set_pev( g_AimedEntity[ id ] , pev_renderfx , kRenderFxNone );
					set_pev( g_AimedEntity[ id ] , pev_renderamt , g_EntityData[ iArrayIndex ][ aiDeleted ] ? 100.0 : 255.0 );
					set_pev( g_AimedEntity[ id ] , pev_rendermode , g_EntityData[ iArrayIndex ][ aiDeleted ] ? kRenderTransColor : kRenderNormal );
					set_rendering( iEntity , kRenderFxGlowShell , g_iItemGlowColor[ ItemAiming ][ rgbRed ] , g_iItemGlowColor[ ItemAiming ][ rgbGreen ] , g_iItemGlowColor[ ItemAiming ][ rgbBlue ] , kRenderTransColor, 100 );
					g_AimedEntity[ id ] = iEntity;
				}
			
				ClearSyncHud( id , g_HUDSyncObj_Action );
				set_hudmessage( 255 , 255 , 0 , -1.0 , 0.25 , .holdtime=0.4 , .channel=-1 );
				ShowSyncHudMsg( id , g_HUDSyncObj_Action , "Hold 'Use' to select this item" );
				GetWeaponName( cs_get_armoury_type( iEntity ) , szWeapon , charsmax( szWeapon ) );
				set_hudmessage( 255 , 255 , 255 , -1.0 , 0.30 , .holdtime=0.4 , .channel=-1 );
				ShowSyncHudMsg( id , g_HUDSyncObj_Weapon , "Item Type: %s^nCurrent Item Count: %d%s" , szWeapon[ 7 ] , get_pdata_int( iEntity , m_iCount , XO_Armoury ) , g_EntityData[ iArrayIndex ][ aiDeleted ] ? "^n^nItem Deleted" : "");
			
				//User is aiming at entity and holding 'Use' button to select the entity.
				if ( ( pev( id , pev_button ) | pev( id , pev_oldbuttons ) ) & IN_USE )
				{
					ClearSyncHud( id , g_HUDSyncObj_Action );
					ClearSyncHud( id , g_HUDSyncObj_Weapon );
					
					//Set users selected entity as this entity.
					g_SelectedEntity[ id ] = iEntity;
					set_pev( iEntity , pev_iuser3 , id );
					
					//Make entity glow the selected color
					set_rendering( iEntity , kRenderFxGlowShell , g_iItemGlowColor[ ItemSelected ][ rgbRed ] , g_iItemGlowColor[ ItemSelected ][ rgbGreen ] , g_iItemGlowColor[ ItemSelected ][ rgbBlue ] , kRenderTransColor, 100 );
					
					//Set menu info.
					g_iMenuInfo[ id ][ ctChangeType ] = _:ctBase;
					g_iMenuInfo[ id ][ mtMenuType ] = _:mtNone;
					
					new iCallback = menu_makecallback( "MenuBaseCallBack" );
					
					//Display menu so user can make changes to entity.
					iMenu = menu_create( "Select Action" , "MenuHandler" );
					menu_additem( iMenu , "Change Type" , .callback=iCallback );
					menu_additem( iMenu , "Change Count" , .callback=iCallback );
					menu_additem( iMenu , g_EntityData[ iArrayIndex ][ aiDeleted ] ? "Un-Delete Item" : "Delete Item" );
					menu_display( id , iMenu );
				}
			}
		}
	}
}

//Menu handler for all menus.
public MenuHandler( id , iMenu , iItem )
{
	if ( iItem == MENU_EXIT ) 
	{
		menu_destroy( iMenu );
		
		//User exitted out of change menu, re-apply appropriate changes to entity that was selected (if any).
		if ( g_SelectedEntity[ id ] )
		{
			if ( g_EntityData[ pev( g_SelectedEntity[ id ] , pev_iuser4 ) ][ aiDeleted ] )
			{
				SetDeleted( g_SelectedEntity[ id ] , true );
			}
			else
			{
				set_pev( g_SelectedEntity[ id ] , pev_rendermode , kRenderNormal );
				set_pev( g_SelectedEntity[ id ] , pev_renderfx , kRenderFxNone );
			}
		
			set_pev( g_SelectedEntity[ id ] , pev_iuser3 , 0 );
		}
		
		g_iMenuInfo[ id ][ ctChangeType ] = _:ctNone;
		g_iMenuInfo[ id ][ mtMenuType ] = _:mtNone;
		g_SelectedEntity[ id ] = 0;
		g_AimedEntity[ id ] = 0;
		
		return PLUGIN_HANDLED;
	}
	
	new iArrayIndex;
	if ( g_SelectedEntity[ id ] )
	{
		iArrayIndex = pev( g_SelectedEntity[ id ] , pev_iuser4 );
	}
	
	//User selected item on base menu
	if ( g_iMenuInfo[ id ][ ctChangeType ] == ctBase )
	{
		switch ( iItem )
		{
			case 0: //Show Item Change menu
			{
				g_iMenuInfo[ id ][ ctChangeType ] = _:ctWeaponType;
				g_iMenuInfo[ id ][ mtMenuType ] = _:mtType;
				ShowTypeMenu( id );
			}
			case 1: //Show Count menu
			{
				g_iMenuInfo[ id ][ ctChangeType ] = _:ctCount;
				g_iMenuInfo[ id ][ mtMenuType ] = _:mtCount;
				ShowCountMenu( id );
			}
			case 2: //Delete complete
			{
				g_EntityData[ iArrayIndex ][ aiDeleted ] = !g_EntityData[ iArrayIndex ][ aiDeleted ];
				SetDeleted( g_SelectedEntity[ id ] , g_EntityData[ iArrayIndex ][ aiDeleted ] );
				set_pev( g_SelectedEntity[ id ] , pev_iuser3 , 0 );
				SaveAndResetVars( id );
			}
		}
	}
	else
	{
		//User made a selection on the Count or Item Type menu
		switch ( g_iMenuInfo[ id ][ mtMenuType ] )
		{
			case mtCount:
			{
				switch ( g_iMenuInfo[ id ][ ctChangeType ] )
				{
					case ctCreate:
					{
						//Weapon creation complete.
						g_EntityData[ g_iMapEntityCount ][ aiEntityIndex ] = CreateEntity( g_EntityData[ g_iMapEntityCount ][ aiOriginalWeaponType ] , str_to_num( g_szChangeValues[ iItem ] ) , g_fCurrentOrigin[ id ] , true );
						g_EntityData[ g_iMapEntityCount ][ aiOriginalWeaponCount ] = str_to_num( g_szChangeValues[ iItem ] );
						g_EntityData[ g_iMapEntityCount ][ aiOrigin ][ 0 ] = _:g_fCurrentOrigin[ id ][ 0 ];
						g_EntityData[ g_iMapEntityCount ][ aiOrigin ][ 1 ] = _:g_fCurrentOrigin[ id ][ 1 ];
						g_EntityData[ g_iMapEntityCount ][ aiOrigin ][ 2 ] = _:g_fCurrentOrigin[ id ][ 2 ];
						g_EntityData[ g_iMapEntityCount ][ aiCreated ] = true;
						g_EntityData[ g_iMapEntityCount ][ aiChangeWeaponType ] = Armoury_NotChanged;
						g_EntityData[ g_iMapEntityCount ][ aiChangeWeaponCount ] = Armoury_NotChanged;
						set_pev( g_EntityData[ g_iMapEntityCount ][ aiEntityIndex ] , pev_iuser4 , g_iMapEntityCount );
						g_iMapEntityCount++;
						SaveAndResetVars( id );
					}
					case ctCount:
					{
						//Weapon count change complete
						new iChangeCount = str_to_num( g_szChangeValues[ iItem ] );
						g_EntityData[ iArrayIndex ][ aiChangeWeaponCount ] = ( g_EntityData[ iArrayIndex ][ aiOriginalWeaponCount ] == iChangeCount ) ? Armoury_NotChanged : iChangeCount;
						ChangeCount( g_SelectedEntity[ id ] , GetArmouryCount( iArrayIndex ) , true );
						set_pev( g_SelectedEntity[ id ] , pev_iuser3 , 0 );
						SaveAndResetVars( id )
					}
				}
			}
			case mtType:
			{
				switch ( g_iMenuInfo[ id ][ ctChangeType ] )
				{
					case ctCreate:
					{
						//Type selected for Create entity, show count menu
						g_EntityData[ g_iMapEntityCount ][ aiOriginalWeaponType ] = iItem; 
						g_iMenuInfo[ id ][ mtMenuType ] = _:mtCount;
						ShowCountMenu( id );
					}
					case ctWeaponType:
					{
						//Weapon type change complete
						g_EntityData[ iArrayIndex ][ aiChangeWeaponType ] = ( iItem == g_EntityData[ iArrayIndex ][ aiOriginalWeaponType ] ) ? Armoury_NotChanged : iItem;
						ChangeWeapon( g_SelectedEntity[ id ] , GetArmouryType( iArrayIndex ) , true );
						set_pev( g_SelectedEntity[ id ] , pev_iuser3 , 0 );
						SaveAndResetVars( id )
					}
				}	
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

//Disable menu item if it is already the current state.
public MenuBaseCallBack( id , iMenu , iItem )
{
	return g_EntityData[ pev( g_SelectedEntity[ id ] , pev_iuser4 ) ][ aiDeleted ] ? ITEM_DISABLED : ITEM_ENABLED;
}

//Disable menu item if it is already the current state.
public MenuTypeCallBack( id , iMenu , iItem )
{
	return ( g_SelectedEntity[ id ] && ( get_pdata_int( g_SelectedEntity[ id ] , m_iType , XO_Armoury ) == iItem ) ) ? ITEM_DISABLED : ITEM_ENABLED;
}

//Disable menu item if it is already the current state.
public MenuCountCallBack( id , iMenu , iItem )
{
	return ( g_SelectedEntity[ id ] && ( GetArmouryCount( pev( g_SelectedEntity[ id ] , pev_iuser4 ) ) == str_to_num( g_szChangeValues[ iItem ] ) ) ) ? ITEM_DISABLED : ITEM_ENABLED;
}

 //Reset all entities to their appropriate count and make sure they are visible.
public RoundStart()
{
	for ( new i = 0 , iEntity ; i < g_iMapEntityCount ; i++ )
	{
		iEntity = g_EntityData[ i ][ aiEntityIndex ]; 
		set_pdata_int( iEntity , m_iCount , GetArmouryCount( i ) , XO_Armoury );
		set_pev( iEntity , pev_effects , pev( iEntity , pev_effects ) & ~EF_NODRAW );
	}
}

//Enables the manager which makes all entities visible and pickup is blocked so user can walk over items without picking them up.
public EnableManager( id , level , cid )
{
	if( !cmd_access( id , level , cid , 1 ) )
		return PLUGIN_HANDLED;

	if ( g_TL_Forward )
	{
		client_print( id , print_console , "* Armoury Manager is already enabled." );
		return PLUGIN_HANDLED;
	}

	//Enable forward.
	g_TL_Forward = register_forward( FM_TraceLine , "TraceLine" , true );

	//Set all armoury_entity's as visible so they can be edited.
	for ( new i = 0 , iEntity ; i < g_iMapEntityCount ; i++ )
	{
		iEntity = g_EntityData[ i ][ aiEntityIndex ];
			
		set_pev( iEntity , pev_effects , pev( iEntity , pev_effects ) & ~EF_NODRAW );	
		set_pev( iEntity , pev_renderfx , kRenderFxNone );
		set_pev( iEntity , pev_renderamt , g_EntityData[ i ][ aiDeleted ] ? 100.0 : 255.0 );
		set_pev( iEntity , pev_rendermode , g_EntityData[ i ][ aiDeleted ] ? kRenderTransColor : kRenderNormal );
		set_pev( iEntity , pev_solid , SOLID_NOT );
	}
	
	return PLUGIN_HANDLED;
}

//Disables the manager which sets all entities to their game-play state.
public DisableManager( id , level , cid )
{
	if( !cmd_access( id , level , cid , 1 ) )
		return PLUGIN_HANDLED;
		
	if ( !g_TL_Forward )
	{
		client_print( id , print_console , "* Armoury Manager is not currently enabled." );
		return PLUGIN_HANDLED;
	}
	
	//Check if players are doing anything before disabling.
	new iPlayers[ 32 ] , iNum , iPlayer;
	get_players( iPlayers , iNum , "ch" );
	for ( new i = 0 ; i < iNum ; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		//A player is currently doing something. They must finish before the Armoury Manager can be disabled.
		if ( g_SelectedEntity[ iPlayer ] || g_iMenuInfo[ iPlayer ][ mtMenuType ] || g_iMenuInfo[ iPlayer ][ ctChangeType ] )
		{
			client_print( id , print_console , "* A player is currently editing or creating an entity. Please have them complete this before disabling the Armoury Manager." );
			return PLUGIN_HANDLED;
		}
		
		//If player currently aiming at an entity, 
		if ( g_AimedEntity[ iPlayer ] )
		{
			set_pev( g_AimedEntity[ iPlayer ] , pev_rendermode , kRenderNormal );
			set_pev( g_AimedEntity[ iPlayer ] , pev_renderfx , kRenderFxNone );
			g_AimedEntity[ iPlayer ] = 0;
		}
		
		//Clear hud for all players.
		ClearSyncHud( iPlayer , g_HUDSyncObj_Action );
		ClearSyncHud( iPlayer , g_HUDSyncObj_Weapon );
	}
	
	//Disable forward.
	unregister_forward( FM_TraceLine , g_TL_Forward , true );
	g_TL_Forward = 0;
	
	//Set all armoury_entity's to their gameplay state.
	for ( new i = 0 , iEntity ; i < g_iMapEntityCount ; i++ )
	{
		iEntity = g_EntityData[ i ][ aiEntityIndex ];
		
		if ( g_EntityData[ i ][ aiCreated ] )
			dllfunc( DLLFunc_Spawn , iEntity );
			
		if ( !get_pdata_int( iEntity , m_iCount , XO_Armoury ) ) 
			set_pev( iEntity , pev_effects , pev( iEntity , pev_effects ) | EF_NODRAW );
			
		if ( g_EntityData[ i ][ aiDeleted ] )
		{
			set_pev( iEntity , pev_rendermode , kRenderTransAlpha );
			set_pev( iEntity , pev_renderamt , 0.0 );
			set_pev( iEntity , pev_solid , SOLID_NOT );
		}
		else
		{
			set_pev( iEntity , pev_solid , SOLID_TRIGGER );
		}	
	}
	
	return PLUGIN_HANDLED;
}

//Deletes the current maps configuration file. A map change is needed to put entities back to original state.
public DeleteConfig( id , level , cid )
{
	if( !cmd_access( id , level , cid , 1 ) )
		return PLUGIN_HANDLED;
	
	if ( !file_exists( g_szMapFile ) )
	{
		client_print( id , print_console , "* A config file for this map does not exist!" );
	}
	else 
	{
		if ( delete_file( g_szMapFile ) )
		{
			client_print( id , print_console , "* Config successfully deleted. You must change maps to reset the armoury_entity's." );	
		}
		else
		{
			client_print( id , print_console , "* Error deleting config file [%s]." , g_szMapFile );	
		}
	}
	
	return PLUGIN_HANDLED;
}

//Shows a MOTD status of any entities that have been created or changed. The MOTD character limit is too low to allow displaying
//every entity on a map that has > ~12 entities.
public DisplayInfo( id , level , cid )
{
	if( !cmd_access( id , level , cid , 1 ) )
		return PLUGIN_HANDLED;
	
	new szBuffer[ 1536 ] , szWeapon[ 21 ] , szChangeWeapon[ 21 ] , szCount[ 4 ] , iPos , szArg[ 4 ] , iStartPos , i , iProcessed;
	
	//None to display
	if ( !g_iMapEntityCount )
	{
		console_print( id , "* There are no armoury_entity's to display." );
		return PLUGIN_HANDLED;
	}
	else
	{
		//Check if user specified a starting index number and check if it is in the valid range. If it is, use that as starting index.
		if ( read_argv( 1 , szArg , charsmax( szArg ) ) )
		{
			if ( 0 < ( iStartPos = str_to_num( szArg ) ) < ( g_iMapEntityCount + 1 ) )
			{
				i = ( iStartPos - 1 );
			}
			else
			{
				console_print( id , "* You must specify an index start value between 1 and %d." , g_iMapEntityCount );
				return PLUGIN_HANDLED;
			}
		}
	}
	
	//Build MOTD
	iPos = copy( szBuffer , charsmax( szBuffer ) , "<html><head><style>table,th,td {border:1px solid black;border-collapse:collapse;} \
							th,td {padding:3px;text-align:center;}</style></head><body><font face=^"Arial^"><table>" );									
	iPos += copy( szBuffer[ iPos ] , charsmax( szBuffer ) - iPos ,"<tr><td>#</td><td><b>Orig Type</b></td><td><b>Orig #</b></td><td><b>Chg Type</b></td> \
									<td><b>Chg #</b></td><td><b>Deleted</b></td><td><b>Created</b></td></tr>" );
	
	//Add armoury info
	for ( ; i < g_iMapEntityCount && iProcessed < AM_EntitiesPerInfoPage ; i++ , iProcessed++ )
	{	
		GetWeaponName( g_ArmouryTypes[ g_EntityData[ i ][ aiOriginalWeaponType ] ][ WeaponIndex ]  , szWeapon , charsmax( szWeapon ) );
		
		if ( g_EntityData[ i ][ aiChangeWeaponType ] != Armoury_NotChanged )
			GetWeaponName( g_ArmouryTypes[ g_EntityData[ i ][ aiChangeWeaponType ] ][ WeaponIndex ] , szChangeWeapon , charsmax( szChangeWeapon ) );
		else
			szChangeWeapon[ 7 ] = EOS;
		
		if ( g_EntityData[ i ][ aiChangeWeaponCount ] != Armoury_NotChanged )
			num_to_str( g_EntityData[ i ][ aiChangeWeaponCount ] , szCount , charsmax( szCount ) );
		else
			szCount[ 0 ] = EOS;
			
		iPos += formatex( szBuffer[ iPos ] , charsmax( szBuffer ) - iPos , "<tr><td>%d</td><td>%s</td><td>%d</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>" , 
										i + 1 , szWeapon[ 7 ] , g_EntityData[ i ][ aiOriginalWeaponCount ] , szChangeWeapon[ 7 ] , szCount ,
										g_EntityData[ i ][ aiDeleted ] ? "Yes" : "No" , g_EntityData[ i ][ aiCreated ] ? "Yes" : "No" ); 								
	}
	
	//If there are more than 14 then let user know they can see items in the 15+ range by specifying the starting index.
	if ( g_iMapEntityCount > 14 )
		iPos += formatex( szBuffer[ iPos ] , charsmax( szBuffer ) - iPos , "</table><br>Total Entities: %d<br>To see more, use <b>am_info [start #]</b> command.</font></body></html>" , g_iMapEntityCount );
	else
		iPos += formatex( szBuffer[ iPos ] , charsmax( szBuffer ) - iPos , "</table><br>Total Entities: %d</font></body></html>" , g_iMapEntityCount );
	
	show_motd( id , szBuffer , "Armoury Info" );
	
	return PLUGIN_HANDLED;
}

//Save map config file and reset players values to 0/nothing
SaveAndResetVars( id )
{
	g_iMenuInfo[ id ][ mtMenuType ] = _:mtNone;
	g_iMenuInfo[ id ][ ctChangeType ] = _:ctNone;
	g_SelectedEntity[ id ] = 0;
	g_AimedEntity[ id ] = 0;
	SaveFile();
}

//Show menu with item type selection.
ShowTypeMenu( id )
{
	new iMenu = menu_create( "Select Item Type" , "MenuHandler" );
	new iCallback = menu_makecallback( "MenuTypeCallBack" );
	
	for ( new iChangeOptions = 0 ; iChangeOptions < sizeof( g_ArmouryTypes ) ; iChangeOptions++ )
		menu_additem( iMenu , g_ArmouryTypes[ iChangeOptions ][ WeaponName ] , .callback=iCallback );
	
	menu_display( id , iMenu );
}

//Show menu with item count selection.
ShowCountMenu( id )
{
	new iMenu = menu_create( "Select Item Count" , "MenuHandler" );
	new iCallback = menu_makecallback( "MenuCountCallBack" );

	for ( new iChangeOptions = 0 ; iChangeOptions < sizeof( g_szChangeValues ) ; iChangeOptions++ )
		menu_additem( iMenu , g_szChangeValues[ iChangeOptions ] , .callback=iCallback );

	menu_display( id , iMenu );
}

//This function processes all armoury_entity changes that were saved to file. The changes must first be 
//loaded from the file into the entity array.
ProcessEntities()
{
	new iEntity , Float:fOrigin[ 3 ] , Float:fEntOrigin[ 3 ] , szClassname[ 15 ];
	new Float:fCurrentDistance , Float:fNearestDistance , iClosestEnt;
	
	//Loop through all entities in the array.
	for ( new iCurrent = 0 ; iCurrent < g_iMapEntityCount ; iCurrent++ )
	{
		//Current entity was created 
		if ( g_EntityData[ iCurrent ][ aiCreated ] )
		{
			//Create entity
			g_EntityData[ iCurrent ][ aiEntityIndex ] = CreateEntity( GetArmouryType( iCurrent ) , GetArmouryCount( iCurrent ) , g_EntityData[ iCurrent ][ aiOrigin ] , false );
			set_pev( g_EntityData[ iCurrent ][ aiEntityIndex ] , pev_iuser4 , iCurrent );
			
			//If this created entity was deleted, delete it.
			if ( g_EntityData[ iCurrent ][ aiDeleted ] )
			{
				SetDeleted( g_EntityData[ iCurrent ][ aiEntityIndex ] , true );
			}
		}
		else
		{
			//find_ent_in_sphere() did not like the origin saved in the array most likely because
			//it is sized using an enum. As a work around, it is copied to a regular array.
			fOrigin[ 0 ] = g_EntityData[ iCurrent ][ aiOrigin ][ 0 ];
			fOrigin[ 1 ] = g_EntityData[ iCurrent ][ aiOrigin ][ 1 ];
			fOrigin[ 2 ] = g_EntityData[ iCurrent ][ aiOrigin ][ 2 ];

			//Reset everything for a new entity search.
			iEntity = -1;
			fNearestDistance = 0.0;
			iClosestEnt = 0;
			
			//Find all entities that are within 65 units of the saved origin for the current entity.
			while ( ( iEntity = find_ent_in_sphere( iEntity , fOrigin , 75.0 ) ) )
			{
				//Get the classname of current entity.
				pev( iEntity , pev_classname , szClassname , charsmax( szClassname ) );
		
				//If is it an armoury_entity, check if its the same weapon type as the current array item and get the closest one
				//to the saved origin location. There is a possibility that armoury_entity's are very close together so extra work
				//is needed to make sure the correct one is selected.
				if ( IsArmoury( szClassname ) && ( get_pdata_int( iEntity , m_iType ) == g_EntityData[ iCurrent ][ aiOriginalWeaponType ] ) )
				{
					//Get origin of current entity.
					pev( iEntity , pev_origin , fEntOrigin );
					
					//Get distance of current entity and location that is saved for the current entity in the array.
					fCurrentDistance = get_distance_f( fOrigin , fEntOrigin );
					
					//The goal is to find the entity that is closest to the origin in the entity array. I had issues 
					//with it finding an array directly with the first result of find_ent_in_sphere(). This seems to
					//work perfectly where it would find the correct entity about 90% of the time using the first found.
					if ( !fNearestDistance || ( fCurrentDistance < fNearestDistance ) )
					{
						iClosestEnt = iEntity;
						fNearestDistance = fCurrentDistance;
					}
				}
			}
			
			//Take action on closest entity found.
			if ( iClosestEnt )
			{
				//Set entity index to array.
				g_EntityData[ iCurrent ][ aiEntityIndex ] = iClosestEnt;
				
				//Get origin of entity.
				pev( iClosestEnt , pev_origin , g_EntityData[ iCurrent ][ aiOrigin ] );
				
				//Set pev_iuser4 value to the entity array index so it can be referenced later.
				set_pev( iClosestEnt , pev_iuser4 , iCurrent );

				//Apply changes to entities.
				if ( g_EntityData[ iCurrent ][ aiChangeWeaponType ] != Armoury_NotChanged )
				{
					ChangeWeapon( iClosestEnt , g_EntityData[ iCurrent ][ aiChangeWeaponType ] , false );
				}
				
				if ( g_EntityData[ iCurrent ][ aiChangeWeaponCount ] != Armoury_NotChanged )
				{
					ChangeCount( iClosestEnt , g_EntityData[ iCurrent ][ aiChangeWeaponCount ] , false );
				}
				
				if ( g_EntityData[ iCurrent ][ aiDeleted ] )
				{
					SetDeleted( iClosestEnt , true );
				}
			}
		}
	}
}

//This is called only the first time the plugin is ran on a map. It loads all base armoury_entity data and saves it
//to file. It also loads the data into the array to be used.
LoadEntities()
{
	new iEntity = -1 , iArrayIndex;
	
	//Find all armoury_entity's in the map.
	while ( ( iEntity = find_ent_by_class( iEntity , "armoury_entity" ) ) && ( iArrayIndex < MaxEntities ) )
	{
		//Save all values for an unmodified armoury_entity.
		pev( iEntity , pev_origin , g_EntityData[ iArrayIndex ][ aiOrigin ] );
		g_EntityData[ iArrayIndex ][ aiOriginalWeaponType ] = get_pdata_int( iEntity , m_iType , XO_Armoury );
		g_EntityData[ iArrayIndex ][ aiOriginalWeaponCount ] = get_pdata_int( iEntity , m_iCount , XO_Armoury );
		g_EntityData[ iArrayIndex ][ aiChangeWeaponType ] = Armoury_NotChanged;
		g_EntityData[ iArrayIndex ][ aiChangeWeaponCount ] = Armoury_NotChanged;
		g_EntityData[ iArrayIndex ][ aiDeleted ] = false;
		g_EntityData[ iArrayIndex ][ aiCreated ] = false;
		g_EntityData[ iArrayIndex ][ aiEntityIndex ] = iEntity;

		//Set entity array index to pev_iuser4
		set_pev( iEntity , pev_iuser4 , iArrayIndex++ );
	}
	
	return iArrayIndex;
}

//Save the entity array to file. See ArmouryInfo enum/struct for data layout.
SaveFile()
{
	new iFile;
		
	if ( ( iFile = fopen( g_szMapFile , "w+b" ) ) )
	{
		for ( new iArrayIndex = 0 ; ( iArrayIndex < g_iMapEntityCount ) && ( iArrayIndex < MaxEntities ) ; iArrayIndex++ )
		{
			if ( g_EntityData[ iArrayIndex ][ aiEntityIndex ] )
			{
				fwrite_blocks( iFile , g_EntityData[ iArrayIndex ][ ArmouryInfo:0 ] , sizeof( g_EntityData[] ) , BLOCK_INT );
			}
		}
		
		fclose( iFile );
	}
}

//Load the entity data file to array. See ArmouryInfo enum/struct for data layout.
LoadFile()
{
	new iLoaded , iFile , iSize , iBytesRead;
	
	if ( !( iSize = filesize( g_szMapFile ) ) ) 
		return 0;
		
	if ( ( iFile = fopen( g_szMapFile , "rb" ) ) )
	{
		while ( ( iLoaded < MaxEntities ) && ( ( iBytesRead * BLOCK_INT ) < iSize ) )
		{
			iBytesRead += fread_blocks( iFile , g_EntityData[ iLoaded++ ][ ArmouryInfo:0 ] , sizeof( g_EntityData[] ) , BLOCK_INT );
		}
		
		fclose( iFile );
	}
	
	return iLoaded;
}

//The get_weaponname() native does not support armor so a work-around is needed.
GetWeaponName( iWeaponIndex , szWeapon[] , len )
{
	if ( CSW_VEST <= iWeaponIndex <= CSW_VESTHELM )
	{
		copy( szWeapon , len , ( iWeaponIndex == CSW_VEST ) ? "weapon_vest" : "weapon_vest & helmet" );
	}
	else
	{
		get_weaponname( iWeaponIndex , szWeapon , len );
	}
}

CreateEntity( iWeaponType , iCount , Float:fOrigin[] , bool:bBlockPickup )
{
	new iEntity = create_entity( "armoury_entity" );

	if( !iEntity )
		set_fail_state( "Error creating entity" );
    
	set_pev( iEntity , pev_origin , fOrigin );
	set_pdata_int( iEntity , m_iType , iWeaponType , XO_Armoury );
	set_pdata_int( iEntity , m_iCount , iCount , XO_Armoury );
	dllfunc( DLLFunc_Spawn , iEntity );
	set_pev( iEntity , pev_solid , bBlockPickup ? SOLID_NOT : SOLID_TRIGGER );
	
	return iEntity;
}

//The below functions apply the selected changes to the entity:
ChangeWeapon( iEntity , iNewWeapon , bool:bBlockPickup )
{
	cs_set_armoury_type( iEntity , g_ArmouryTypes[ iNewWeapon ][ WeaponIndex ] );
	dllfunc( DLLFunc_Spawn , iEntity );
	set_pev( iEntity , pev_rendermode , kRenderNormal );
	set_pev( iEntity , pev_renderfx , kRenderFxNone );
	set_pev( iEntity , pev_renderamt , 255.0 );
	set_pev( iEntity , pev_solid , bBlockPickup ? SOLID_NOT : SOLID_TRIGGER );
}

ChangeCount( iEntity , iCount , bool:bBlockPickup )
{
	new iEffects = pev( iEntity , pev_effects );
	set_pdata_int( iEntity , m_iCount , iCount , XO_Armoury );
	set_pev( iEntity , pev_rendermode , kRenderNormal );
	set_pev( iEntity , pev_renderfx , kRenderFxNone );
	set_pev( iEntity , pev_renderamt , 255.0 );
	set_pev( iEntity , pev_solid , bBlockPickup ? SOLID_NOT : SOLID_TRIGGER );
	set_pev( iEntity , pev_effects , iCount ? ( iEffects & ~EF_NODRAW ) : ( iEffects | EF_NODRAW ) );
}

SetDeleted( iEntity , bool:bDeleted )
{
	set_pev( iEntity , pev_rendermode , bDeleted ? kRenderTransColor : kRenderNormal );
	set_pev( iEntity , pev_renderfx , kRenderFxNone );
	set_pev( iEntity , pev_solid , bDeleted ? SOLID_NOT : SOLID_TRIGGER );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
