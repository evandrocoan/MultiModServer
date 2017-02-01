/**
 *
 * Accuracy Fix
 *  by Numb
 *
 *
 * Description:
 *  One of the least known bugs in Counter-Strike is that accuracy of your bullet is set at
 *  the moment you made your previous shot, and how much time you wait has no effect on the
 *  bullet you just fired. However it has effect on the next time when you shall shoot.
 *  Sometimes players even think that their reg (bullet registration on the server) is off
 *  quite a bit. Fortunately this isn't a net code issue, but the actual glitch in accuracy
 *  calculation, what this plugin fixes. Also this plugin has few more has few more extra
 *  features. Shortly here's everything what it does:
 *  + Fixes "use accuracy from last bullet fired earlier" glitch.
 *  + Fixes and improves smooth spread transitions when shooting automatic weapons.
 *  + Fixes spread cool-down at low fps.
 *  + Fixes switched glock burst-fire accuracy of when moving and when standing still.
 *  + Improves accuracy drastically, when you aren't moving and your spread is cooled down
 *   so to speak. You must stay on ground of course for that to happen. If you crouch, than
 *   effect becomes even stronger (in most weapons this scenario makes first bullet dead on
 *   center).
 *  + One more drastic change is major improvement on sg550 weapon - as you may noticed,
 *   normally it isn't accurate at all, and that the spread is simply horrible, especially
 *   comparing to terrorist sniper rifle g3sg1.
 *  + Last, but not least, when standing scout accuracy is somewhat improved - normally
 *   scout is really inaccurate, you must duck to make a shot after what you wont ask
 *   yourself "Whaaat??? How did I miss?".
 *
 *
 * Requires:
 *  FakeMeta
 *  HamSandWich
 *
 *
 * Additional info:
 *  Tested in Counter-Strike 1.6 with amxmodx 1.8.2. You may also download demos to see for
 *  yourself this bugs and how well plugin handles them.
 *
 *
 * Notes:
 *  Once installed, you wont see no graphical changes in accuracy. This is due to
 *  client-side accuracy calculation, what server does not update by default. In order to
 *  see actual location where bullet decal appears, you have to type "cl_lw 0" in console.
 *  But don't use this setting in actual gameplay, cause it disables client-side fire
 *  animations, and forces server-side ones what are delayed due to ping ("cl_lw 0" may
 *  and will lead to laggy gameplay).
 *
 *
 * Credits:
 *  Special thanks to Arkshine ( http://forums.alliedmods.net/member.php?u=7779 ) for
 *  Counter-Strike SDK ( https://github.com/Arkshine/CSSDK/ )!
 *
 *
 * Change-Log:
 *
 *  + 3.0
 *  - Added: Fix for glock wrong movement condition accuracy when in burst mode.
 *
 *  + 2.0
 *  - Added: Fix for smooth spread transitions of automatic weapons.
 *  - Added: Improved smooth spread transitions of automatic weapons.
 *  - Added: Fix for slow spread cool-down of automatic weapons at low fps.
 *  - Added: Smoother transition to maximum accuracy for pistols and sg550.
 *
 *  + 1.0
 *  - First release.
 *
 *
 * Downloads:
 *  Amx Mod X forums: http://forums.alliedmods.net/showthread.php?p=1549133#post1549133
 *
**/


#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN_NAME	"Accuracy Fix"
#define PLUGIN_VERSION	"3.0"
#define PLUGIN_AUTHOR	"Numb"

#define SMOOTH_SPREAD_TRANSITION
#define LOW_FPS_SPREAD_COOLDOWN_FIX

#define m_pPlayer 41
#define m_flAccuracy 62
#define m_flLastFire 63
#define m_iShotsFired 64
#define m_fWeaponState 74
#define WEAPONSTATE_GLOCK18_BURST_MODE (1<<1)
#define m_flDecreaseShotsFired 76

new Float:g_fAccuracy;
#if defined LOW_FPS_SPREAD_COOLDOWN_FIX
new Float:g_fOldDecreaseShotsFired;
new g_iOldShotsFired;
#endif
new bool:g_bGlockDuckRemoved;
new bool:g_bGlockVelocityChanged;
new Float:g_fGlockVelocity[3];


public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	register_cvar("accuracy_fix", PLUGIN_VERSION, (FCVAR_SERVER|FCVAR_SPONLY));
	
#if defined LOW_FPS_SPREAD_COOLDOWN_FIX
	RegisterHam(Ham_Item_PostFrame, "weapon_ak47",    "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_aug",     "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_famas",   "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_galil",   "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_m249",    "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_m4a1",    "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_mac10",   "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_mp5navy", "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_p90",     "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_sg552",   "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_tmp",     "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_ump45",   "Ham_PostFrame_Pre", 0);
	RegisterHam(Ham_Item_PostFrame, "weapon_ak47",    "Ham_PostFrame_Pre", 0);
	
	RegisterHam(Ham_Item_PostFrame, "weapon_aug",     "Ham_PostFrame_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_famas",   "Ham_PostFrame_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_galil",   "Ham_PostFrame_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_m249",    "Ham_PostFrame_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_m4a1",    "Ham_PostFrame_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_mac10",   "Ham_PostFrame_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_mp5navy", "Ham_PostFrame_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_p90",     "Ham_PostFrame_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_sg552",   "Ham_PostFrame_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_tmp",     "Ham_PostFrame_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_ump45",   "Ham_PostFrame_Post", 1);
#endif
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47",      "Ham_Attack_ak47_Pre",    0);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_aug",       "Ham_Attack_aug_Pre",     0);
	
	// awp accuracy offset does not exist
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle",    "Ham_Attack_deagle_Pre",  0);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle",    "Ham_Attack_deagle_Post", 1);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_elite",     "Ham_Attack_elite_Pre",   0);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_elite",     "Ham_Attack_elite_Post",  1);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_famas",     "Ham_Attack_famas_Pre",   0);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_fiveseven", "Ham_Attack_57_Pre",      0);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_fiveseven", "Ham_Attack_57_Post",     1);
	
	// g3sg1 accuracy offset has no effect
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil",     "Ham_Attack_galil_Pre",   0);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_glock18",   "Ham_Attack_glock_Pre",   0);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_glock18",   "Ham_Attack_glock_Post",  1);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m249",      "Ham_Attack_m249_Pre",    0);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m4a1",      "Ham_Attack_m4a1_Pre",    0);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mac10",     "Ham_Attack_mac10_Pre",   0);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_mp5navy",   "Ham_Attack_mp5_Pre",     0);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_p228",      "Ham_Attack_p228_Pre",    0);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_p228",      "Ham_Attack_p228_Post",   1);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_p90",       "Ham_Attack_p90_Pre",     0);
	
	// scout accuracy offset does not exist
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_scout",     "Ham_Attack_scout_Pre",   0);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_scout",     "Ham_Attack_scout_Post",  1);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg550",     "Ham_Attack_sg550_Pre",   0);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_sg552",     "Ham_Attack_sg552_Pre",   0);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_tmp",       "Ham_Attack_tmp_Pre",     0);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ump45",     "Ham_Attack_ump45_Pre",   0);
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_usp",       "Ham_Attack_usp_Pre",     0);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_usp",       "Ham_Attack_usp_Post",    1);
}

public plugin_unpause()
{
	g_fAccuracy = 0.0;
#if defined LOW_FPS_SPREAD_COOLDOWN_FIX
	g_fOldDecreaseShotsFired = 0.0;
	g_iOldShotsFired = 0;
#endif
	
	g_bGlockDuckRemoved = false;
	g_bGlockVelocityChanged = false;
}

#if defined LOW_FPS_SPREAD_COOLDOWN_FIX
public Ham_PostFrame_Pre(iEnt)
{
	if( pev(get_pdata_cbase(iEnt, m_pPlayer, 4), pev_button)&IN_ATTACK )
	{
		g_fOldDecreaseShotsFired = 0.0;
		g_iOldShotsFired = 0;
	}
	else
	{
		g_fOldDecreaseShotsFired = get_pdata_float(iEnt, m_flDecreaseShotsFired, 4);
		if( g_fOldDecreaseShotsFired<get_gametime() )
			g_iOldShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4);
		else
		{
			g_fOldDecreaseShotsFired = 0.0;
			g_iOldShotsFired = 0;
		}
	}
}

public Ham_PostFrame_Post(iEnt)
{
	if( g_iOldShotsFired>0 && g_fOldDecreaseShotsFired>0.0 )
	{
		static s_iShotsFired;
		s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4);
		
		if( g_iOldShotsFired>s_iShotsFired>0 )
		{
			static Float:s_fDecreaseShotsFired;
			s_fDecreaseShotsFired = get_pdata_float(iEnt, m_flDecreaseShotsFired, 4);
			
			if( s_fDecreaseShotsFired>g_fOldDecreaseShotsFired )
			{
				static Float:s_fGameTime;
				s_fGameTime = get_gametime();
				
				if( s_fDecreaseShotsFired>s_fGameTime )
				{
					static Float:s_fDelay;
					s_fDelay = (s_fDecreaseShotsFired-s_fGameTime);
					s_fDecreaseShotsFired -= (s_fGameTime-g_fOldDecreaseShotsFired);
					
					/*while( s_fDecreaseShotsFired<s_fGameTime ) // may not be super CPU friendly, if some other plugin messes things up
					{
						s_fDecreaseShotsFired += s_fDelay;
						s_iShotsFired--;
						
						if( s_iShotsFired<=0 )
							break;
					}
					
					set_pdata_float(iEnt, m_flDecreaseShotsFired, s_fDecreaseShotsFired, 4);
					set_pdata_int(iEnt, m_iShotsFired, s_iShotsFired, 4);*/
					
					if( s_fDecreaseShotsFired<s_fGameTime ) // 'a bit' more complicated way, but does the same thing
					{
						static s_iDecreaseCount;
						s_iDecreaseCount = floatround(((s_fGameTime-s_fDecreaseShotsFired)/s_fDelay), floatround_ceil);
						
						if( s_iDecreaseCount>s_iShotsFired )
							s_iDecreaseCount = s_iShotsFired;
						
						set_pdata_float(iEnt, m_flDecreaseShotsFired, (s_fDecreaseShotsFired+(float(s_iDecreaseCount)*s_fDelay)), 4);
						set_pdata_int(iEnt, m_iShotsFired, (s_iShotsFired-s_iDecreaseCount), 4);
					}
					else
						set_pdata_float(iEnt, m_flDecreaseShotsFired, s_fDecreaseShotsFired, 4);
				}
			}
		}
	}
}
#endif


public Ham_Attack_ak47_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired*s_iShotsFired)/200.0)+0.2+smooth_accuracy_transition((s_iShotsFired+1), 0.15, 3));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired*s_iShotsFired)/200.0)+0.35;
#endif
		
		if( g_fAccuracy>1.25 )
			g_fAccuracy = 1.25;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.1, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
	}
}

public Ham_Attack_aug_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired*s_iShotsFired)/215.0)+0.2+smooth_accuracy_transition((s_iShotsFired+1), 0.1, 2));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired*s_iShotsFired)/215.0)+0.3;
#endif
		
		if( g_fAccuracy>1.0 )
			g_fAccuracy = 1.0;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.1, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
	}
}


public Ham_Attack_deagle_Pre(iEnt)
{
	static Float:s_fLastFire;
	s_fLastFire = get_pdata_float(iEnt, m_flLastFire, 4);
	if( !s_fLastFire )
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					g_fAccuracy = 1.0;
				else
					g_fAccuracy = 0.96;
			}
			else
				g_fAccuracy = 0.92;
		}
		else
			g_fAccuracy = 0.92;
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else if( get_pdata_int(iEnt, m_iShotsFired, 4)<=0 )
	{
		g_fAccuracy = get_pdata_float(iEnt, m_flAccuracy, 4);
		g_fAccuracy -= (0.4-(get_gametime()-s_fLastFire))*0.35;
		
		if( g_fAccuracy<0.55 )
			g_fAccuracy = 0.55;
		else if( g_fAccuracy>0.92 )
		{
			static s_iOwner, s_iFlags;
			s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
			s_iFlags = pev(s_iOwner, pev_flags);
			
			if( s_iFlags&FL_ONGROUND )
			{
				static Float:s_fVelocity[3];
				pev(s_iOwner, pev_velocity, s_fVelocity);
				
				if( !s_fVelocity[0] && !s_fVelocity[1] )
				{
					if( s_iFlags&FL_DUCKING )
					{
						if( g_fAccuracy>1.0 )
							g_fAccuracy = 1.0;
					}
					else if( g_fAccuracy>0.96 )
						g_fAccuracy = 0.96;
				}
				else
					g_fAccuracy = 0.92;
			}
			else
				g_fAccuracy = 0.92;
		}
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
	}
	else
		g_fAccuracy = -1.0;
}

public Ham_Attack_deagle_Post(iEnt)
{
	if( g_fAccuracy>0.92 )
		set_pdata_float(iEnt, m_flAccuracy , 0.92, 4);
	else if( g_fAccuracy>0.0 )
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
}


public Ham_Attack_elite_Pre(iEnt)
{
	static Float:s_fLastFire;
	s_fLastFire = get_pdata_float(iEnt, m_flLastFire, 4);
	if( !s_fLastFire )
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					g_fAccuracy = 1.0;
				else
					g_fAccuracy = 0.94;
			}
			else
				g_fAccuracy = 0.88;
		}
		else
			g_fAccuracy = 0.88;
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else if( get_pdata_int(iEnt, m_iShotsFired, 4)<=0 )
	{
		g_fAccuracy = get_pdata_float(iEnt, m_flAccuracy, 4);
		g_fAccuracy -= (0.325-(get_gametime()-s_fLastFire))*0.275;
		
		if( g_fAccuracy<0.55 )
			g_fAccuracy = 0.55;
		else if( g_fAccuracy>0.88 )
		{
			static s_iOwner, s_iFlags;
			s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
			s_iFlags = pev(s_iOwner, pev_flags);
			
			if( s_iFlags&FL_ONGROUND )
			{
				static Float:s_fVelocity[3];
				pev(s_iOwner, pev_velocity, s_fVelocity);
				
				if( !s_fVelocity[0] && !s_fVelocity[1] )
				{
					if( s_iFlags&FL_DUCKING )
					{
						if( g_fAccuracy>1.0 )
							g_fAccuracy = 1.0;
					}
					else if( g_fAccuracy>0.94 )
						g_fAccuracy = 0.94;
				}
				else
					g_fAccuracy = 0.88;
			}
			else
				g_fAccuracy = 0.88;
		}
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
	}
	else
		g_fAccuracy = -1.0;
}

public Ham_Attack_elite_Post(iEnt)
{
	if( g_fAccuracy>0.88 )
		set_pdata_float(iEnt, m_flAccuracy , 0.88, 4);
	else if( g_fAccuracy>0.0 )
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
}


public Ham_Attack_famas_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired*s_iShotsFired)/215.0)+0.2+smooth_accuracy_transition((s_iShotsFired+1), 0.1, 2));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired*s_iShotsFired)/215.0)+0.3;
#endif
		
		if( g_fAccuracy>1.0 )
			g_fAccuracy = 1.0;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.1, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
	}
}


public Ham_Attack_57_Pre(iEnt)
{
	static Float:s_fLastFire;
	s_fLastFire = get_pdata_float(iEnt, m_flLastFire, 4);
	if( !s_fLastFire )
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					g_fAccuracy = 1.0;
				else
					g_fAccuracy = 0.96;
			}
			else
				g_fAccuracy = 0.92;
		}
		else
			g_fAccuracy = 0.92;
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else if( get_pdata_int(iEnt, m_iShotsFired, 4)<=0 )
	{
		g_fAccuracy = get_pdata_float(iEnt, m_flAccuracy, 4);
		g_fAccuracy -= (0.275-(get_gametime()-s_fLastFire))*0.25;
		
		if( g_fAccuracy<0.725 )
			g_fAccuracy = 0.725;
		else if( g_fAccuracy>0.92 )
		{
			static s_iOwner, s_iFlags;
			s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
			s_iFlags = pev(s_iOwner, pev_flags);
			
			if( s_iFlags&FL_ONGROUND )
			{
				static Float:s_fVelocity[3];
				pev(s_iOwner, pev_velocity, s_fVelocity);
				
				if( !s_fVelocity[0] && !s_fVelocity[1] )
				{
					if( s_iFlags&FL_DUCKING )
					{
						if( g_fAccuracy>1.0 )
							g_fAccuracy = 1.0;
					}
					else if( g_fAccuracy>0.96 )
						g_fAccuracy = 0.96;
				}
				else
					g_fAccuracy = 0.92;
			}
			else
				g_fAccuracy = 0.92;
		}
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
	}
	else
		g_fAccuracy = -1.0;
}

public Ham_Attack_57_Post(iEnt)
{
	if( g_fAccuracy>0.92 )
		set_pdata_float(iEnt, m_flAccuracy , 0.92, 4);
	else if( g_fAccuracy>0.0 )
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
}


public Ham_Attack_galil_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired*s_iShotsFired)/200.0)+0.2+smooth_accuracy_transition((s_iShotsFired+1), 0.15, 4));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired*s_iShotsFired)/200.0)+0.35;
#endif
		
		if( g_fAccuracy>1.25 )
			g_fAccuracy = 1.25;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.1, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
	}
}

public Ham_Attack_glock_Pre(iEnt)
{
	static Float:s_fLastFire, bool:s_bInBurst;
	s_fLastFire = get_pdata_float(iEnt, m_flLastFire, 4);
	if( get_pdata_int(iEnt, m_fWeaponState, 4)&WEAPONSTATE_GLOCK18_BURST_MODE )
		s_bInBurst = true;
	else
		s_bInBurst = false;
	if( !s_fLastFire )
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			pev(s_iOwner, pev_velocity, g_fGlockVelocity);
			
			if( !g_fGlockVelocity[0] && !g_fGlockVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					g_fAccuracy = 1.0;
				else
					g_fAccuracy = 0.95;
				
				if( s_bInBurst )
				{
					if( ~s_iFlags&FL_DUCKING )
					{
						g_bGlockVelocityChanged = true;
						set_pev(s_iOwner, pev_velocity, Float:{150.0, 0.0, 0.0});
					}
				}
			}
			else
			{
				g_fAccuracy = 0.90;
				
				if( s_bInBurst )
				{
					g_bGlockVelocityChanged = true;
					set_pev(s_iOwner, pev_velocity, Float:{0.0, 0.0, 0.0});
					if( s_iFlags&FL_DUCKING )
					{
						g_bGlockDuckRemoved = true;
						set_pev(s_iOwner, pev_flags, (s_iFlags&~FL_DUCKING));
					}
				}
			}
		}
		else
			g_fAccuracy = 0.90;
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else if( get_pdata_int(iEnt, m_iShotsFired, 4)<=0 || s_bInBurst )
	{
		g_fAccuracy = get_pdata_float(iEnt, m_flAccuracy, 4);
		g_fAccuracy -= (0.325-(get_gametime()-s_fLastFire))*0.275;
		
		if( g_fAccuracy<0.6 )
			g_fAccuracy = 0.6;
		else if( g_fAccuracy>0.90 )
		{
			static s_iOwner, s_iFlags;
			s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
			s_iFlags = pev(s_iOwner, pev_flags);
			
			if( s_iFlags&FL_ONGROUND )
			{
				pev(s_iOwner, pev_velocity, g_fGlockVelocity);
				
				if( !g_fGlockVelocity[0] && !g_fGlockVelocity[1] )
				{
					if( s_iFlags&FL_DUCKING )
					{
						if( g_fAccuracy>1.0 )
							g_fAccuracy = 1.0;
					}
					else if( g_fAccuracy>0.95 )
						g_fAccuracy = 0.95;
				
					if( s_bInBurst )
					{
						if( ~s_iFlags&FL_DUCKING )
						{
							g_bGlockVelocityChanged = true;
							set_pev(s_iOwner, pev_velocity, Float:{150.0, 0.0, 0.0});
						}
					}
				}
				else
				{
					g_fAccuracy = 0.90;
				
					if( s_bInBurst )
					{
						g_bGlockVelocityChanged = true;
						set_pev(s_iOwner, pev_velocity, Float:{0.0, 0.0, 0.0});
						if( s_iFlags&FL_DUCKING )
						{
							g_bGlockDuckRemoved = true;
							set_pev(s_iOwner, pev_flags, (s_iFlags&~FL_DUCKING));
						}
					}
				}
			}
			else
				g_fAccuracy = 0.90;
		}
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
	}
	else
		g_fAccuracy = -1.0;
}

public Ham_Attack_glock_Post(iEnt)
{
	if( g_fAccuracy>0.90 )
		set_pdata_float(iEnt, m_flAccuracy , 0.90, 4);
	else if( g_fAccuracy>0.0 )
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
	
	static s_iOwner;
	s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
	
	if( g_bGlockVelocityChanged )
	{
		g_bGlockVelocityChanged = false;
		set_pev(s_iOwner, pev_velocity, g_fGlockVelocity);
	}
	
	if( g_bGlockDuckRemoved )
	{
		g_bGlockDuckRemoved = false;
		set_pev(s_iOwner, pev_flags, (pev(s_iOwner, pev_flags)|FL_DUCKING));
	}
}


public Ham_Attack_m249_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired*s_iShotsFired)/175.0)+0.2+smooth_accuracy_transition((s_iShotsFired+1), 0.2, 4));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired*s_iShotsFired)/175.0)+0.4;
#endif
		
		if( g_fAccuracy>0.9 )
			g_fAccuracy = 0.9;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.1, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
	}
}


public Ham_Attack_m4a1_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired*s_iShotsFired)/220.0)+0.2+smooth_accuracy_transition((s_iShotsFired+1), 0.15, 3));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired*s_iShotsFired)/220.0)+0.35;
#endif
		
		if( g_fAccuracy>1.25 )
			g_fAccuracy = 1.25;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.1, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
	}
}


public Ham_Attack_mac10_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired*s_iShotsFired)/200.0)+0.15+smooth_accuracy_transition((s_iShotsFired+1), 0.45, 8));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired*s_iShotsFired)/200.0)+0.6;
#endif
		
		if( g_fAccuracy>1.65 )
			g_fAccuracy = 1.65;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.075, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.15, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.15, 4);
	}
}


public Ham_Attack_mp5_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired)/220.0)+0.2+smooth_accuracy_transition((s_iShotsFired+1), 0.25, 5));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired)/220.0)+0.45;
#endif
		
		if( g_fAccuracy>0.75 )
			g_fAccuracy = 0.75;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.1, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
	}
}


public Ham_Attack_p228_Pre(iEnt)
{
	static Float:s_fLastFire;
	s_fLastFire = get_pdata_float(iEnt, m_flLastFire, 4);
	if( !s_fLastFire )
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					g_fAccuracy = 1.0;
				else
					g_fAccuracy = 0.95;
			}
			else
				g_fAccuracy = 0.90;
		}
		else
			g_fAccuracy = 0.90;
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else if( get_pdata_int(iEnt, m_iShotsFired, 4)<=0 )
	{
		g_fAccuracy = get_pdata_float(iEnt, m_flAccuracy, 4);
		g_fAccuracy -= (0.325-(get_gametime()-s_fLastFire))*0.3;
		
		if( g_fAccuracy<0.6 )
			g_fAccuracy = 0.6;
		else if( g_fAccuracy>0.90 )
		{
			static s_iOwner, s_iFlags;
			s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
			s_iFlags = pev(s_iOwner, pev_flags);
			
			if( s_iFlags&FL_ONGROUND )
			{
				static Float:s_fVelocity[3];
				pev(s_iOwner, pev_velocity, s_fVelocity);
				
				if( !s_fVelocity[0] && !s_fVelocity[1] )
				{
					if( s_iFlags&FL_DUCKING )
					{
						if( g_fAccuracy>1.0 )
							g_fAccuracy = 1.0;
					}
					else if( g_fAccuracy>0.95 )
						g_fAccuracy = 0.95;
				}
				else
					g_fAccuracy = 0.90;
			}
			else
				g_fAccuracy = 0.90;
		}
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
	}
	else
		g_fAccuracy = -1.0;
}

public Ham_Attack_p228_Post(iEnt)
{
	if( g_fAccuracy>0.90 )
		set_pdata_float(iEnt, m_flAccuracy , 0.90, 4);
	else if( g_fAccuracy>0.0 )
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
}


public Ham_Attack_p90_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired)/175.0)+0.2+smooth_accuracy_transition((s_iShotsFired+1), 0.25, 6));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired)/175.0)+0.45;
#endif
		
		if( g_fAccuracy>1.0 )
			g_fAccuracy = 1.0;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.1, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
	}
}


public Ham_Attack_scout_Pre(iEnt)
{
	static s_iOwner, s_iFlags;
	s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
	s_iFlags = pev(s_iOwner, pev_flags);
	
	if( s_iFlags&FL_DUCKING || ~s_iFlags&FL_ONGROUND )
		g_fAccuracy = 0.0;
	else
	{
		static Float:s_fVelocity[3];
		pev(s_iOwner, pev_velocity, s_fVelocity);
		
		if( !s_fVelocity[0] && !s_fVelocity[1] )
		{
			set_pev(s_iOwner, pev_flags, (s_iFlags|FL_DUCKING));
			g_fAccuracy = 1.0;
		}
		else
			g_fAccuracy = 0.0;
	}
}

public Ham_Attack_scout_Post(iEnt)
{
	if( g_fAccuracy )
	{
		static s_iOwner;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		set_pev(s_iOwner, pev_flags, (pev(s_iOwner, pev_flags)&~FL_DUCKING));
	}
}


public Ham_Attack_sg550_Pre(iEnt)
{
	static Float:s_fLastFire;
	s_fLastFire = get_pdata_float(iEnt, m_flLastFire, 4);
	if( !s_fLastFire )
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					g_fAccuracy = 1.0;
				else
					g_fAccuracy = 0.99;
			}
			else
				g_fAccuracy = 0.98;
		}
		else
			g_fAccuracy = 0.98;
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		g_fAccuracy = (0.65+(get_gametime()-s_fLastFire))*0.725; //*0.35; (this is way too inaccurate comparing to g3sg1)
		
		if( g_fAccuracy>0.98 )
		{
			static s_iOwner, s_iFlags;
			s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
			s_iFlags = pev(s_iOwner, pev_flags);
			
			if( s_iFlags&FL_ONGROUND )
			{
				static Float:s_fVelocity[3];
				pev(s_iOwner, pev_velocity, s_fVelocity);
				
				if( !s_fVelocity[0] && !s_fVelocity[1] )
				{
					if( s_iFlags&FL_DUCKING )
					{
						if( g_fAccuracy>1.0 )
							g_fAccuracy = 1.0;
					}
					else if( g_fAccuracy>0.99 )
						g_fAccuracy = 0.99;
				}
				else
					g_fAccuracy = 0.98;
			}
			else
				g_fAccuracy = 0.98;
		}
		else if( g_fAccuracy<0.5 )
			g_fAccuracy = 0.5;
		
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
	}
}


public Ham_Attack_sg552_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired*s_iShotsFired)/220.0)+0.2+smooth_accuracy_transition((s_iShotsFired+1), 0.1, 3));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired*s_iShotsFired)/220.0)+0.3;
#endif
		
		if( g_fAccuracy>1.0 )
			g_fAccuracy = 1.0;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.1, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
	}
}


public Ham_Attack_tmp_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired*s_iShotsFired)/220.0)+0.2+smooth_accuracy_transition((s_iShotsFired+1), 0.35, 7));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired*s_iShotsFired)/220.0)+0.55;
#endif
		
		if( g_fAccuracy>1.4 )
			g_fAccuracy = 1.4;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.1, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
	}
}


public Ham_Attack_ump45_Pre(iEnt)
{
	static s_iShotsFired;
	s_iShotsFired = get_pdata_int(iEnt, m_iShotsFired, 4)-1;
	if( s_iShotsFired>=0 )
	{
#if defined SMOOTH_SPREAD_TRANSITION
		g_fAccuracy = (((s_iShotsFired*s_iShotsFired)/210.0)+0.2+smooth_accuracy_transition((s_iShotsFired+1), 0.3, 5));
#else
		g_fAccuracy = ((s_iShotsFired*s_iShotsFired)/210.0)+0.5;
#endif
		
		if( g_fAccuracy>1.0 )
			g_fAccuracy = 1.0;
		
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					set_pdata_float(iEnt, m_flAccuracy, 0.0, 4);
				else
					set_pdata_float(iEnt, m_flAccuracy, 0.1, 4);
			}
			else
				set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
		}
		else
			set_pdata_float(iEnt, m_flAccuracy, 0.2, 4);
	}
}


public Ham_Attack_usp_Pre(iEnt)
{
	static Float:s_fLastFire;
	s_fLastFire = get_pdata_float(iEnt, m_flLastFire, 4);
	if( !s_fLastFire )
	{
		static s_iOwner, s_iFlags;
		s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
		s_iFlags = pev(s_iOwner, pev_flags);
		
		if( s_iFlags&FL_ONGROUND )
		{
			static Float:s_fVelocity[3];
			pev(s_iOwner, pev_velocity, s_fVelocity);
			
			if( !s_fVelocity[0] && !s_fVelocity[1] )
			{
				if( s_iFlags&FL_DUCKING )
					g_fAccuracy = 1.0;
				else
					g_fAccuracy = 0.96;
			}
			else
				g_fAccuracy = 0.92;
		}
		else
			g_fAccuracy = 0.92;
		set_pdata_float(iEnt, m_flAccuracy, g_fAccuracy, 4);
	}
	else if( get_pdata_int(iEnt, m_iShotsFired, 4)<=0 )
	{
		g_fAccuracy = get_pdata_float(iEnt, m_flAccuracy, 4);
		g_fAccuracy -= (0.3-(get_gametime()-s_fLastFire))*0.275;
		
		if( g_fAccuracy<0.6 )
			g_fAccuracy = 0.6;
		else if( g_fAccuracy>0.92 )
		{
			static s_iOwner, s_iFlags;
			s_iOwner = get_pdata_cbase(iEnt, m_pPlayer, 4);
			s_iFlags = pev(s_iOwner, pev_flags);
			
			if( s_iFlags&FL_ONGROUND )
			{
				static Float:s_fVelocity[3];
				pev(s_iOwner, pev_velocity, s_fVelocity);
				
				if( !s_fVelocity[0] && !s_fVelocity[1] )
				{
					if( s_iFlags&FL_DUCKING )
					{
						if( g_fAccuracy>1.0 )
							g_fAccuracy = 1.0;
					}
					else if( g_fAccuracy>0.96 )
						g_fAccuracy = 0.96;
				}
				else
					g_fAccuracy = 0.92;
			}
			else
				g_fAccuracy = 0.92;
		}
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
	}
	else
		g_fAccuracy = -1.0;
}

public Ham_Attack_usp_Post(iEnt)
{
	if( g_fAccuracy>0.92 )
		set_pdata_float(iEnt, m_flAccuracy , 0.92, 4);
	else if( g_fAccuracy>0.0 )
		set_pdata_float(iEnt, m_flAccuracy , g_fAccuracy, 4);
}

#if defined SMOOTH_SPREAD_TRANSITION
Float:smooth_accuracy_transition(iSteppingId, Float:fMaxInaccuracy, iSteppingsMax)
{
	if( iSteppingId>=iSteppingsMax )
		return fMaxInaccuracy;
	
	return ((float(iSteppingId)*fMaxInaccuracy)/float(iSteppingsMax));
}
#endif
