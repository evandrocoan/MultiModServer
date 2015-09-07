/*************************************
* Daily Mapcycle
*  by JustinHoMi
**************************************
* Ported by Burnzy
*  Visit www.burnsdesign.org
**************************************
*
* WARNING!!!!
* ===========
*   YOU MUST DISABLE NEXTMAP.AMX FOR THIS TO WORK!
*
*
* Allows you to specify a different map
* rotation for every day. Mapcycles.ini should
* be placed in cstrike/mapcycles
* And for daily_cfgs to be placed into
* cstrike/mapcycles
* The cfgs should be started with the
* week days first three letters in the
* name.
*
* REMEMBER!:
* ==========
*  -the files in the daily_mapcycles folder should be .ini
*  -the files in the daily_cfgs folder should be .cfg
*
* Examples:
* =========
*  Sun.cfg
*  Wed.cfg
*  Fri.cfg
*
*   (Sun,Mon,Tue,Wed,Thu,Fri,Sat).cfg
*   (Sun,Mon,Tue,Wed,Thu,Fri,Sat).ini
*
* In the cfg's, u just put what cvars u want to apply for that day
* In the ini's, u just put the maps u want to be rotated though on that day
*    Example:
*       de_dust
*       de_aztec_cz
*       cs_assault_cz
* (u dont need .bsp)
*
* Changelog:
*  v1.2, Make it .ini for map stuff
*  v1.1, Made it so that there is
*  v1.0, Initial Release
*************************************/

#include <amxmodx>
#include <amxmisc>

public plugin_init()
{
    register_plugin("Daily Changer", "1.2", "JustinHoMi & JGHG")
    new today[8], workpath[32]

    new isFirstTime[32]
    get_localinfo( "isFirstTimeLoadMapCycle", isFirstTime, charsmax( isFirstTime ) );
    new isFirstTimeNum = str_to_num( isFirstTime )

    if ( isFirstTimeNum == 2 )
	{
        get_time("%a", today, 8)

        format(workpath, 31, "mapcycles/%s.ini", today)
        set_cvar_string("mapcyclefile", workpath)

        format(workpath, 31, "mapcycles/%s.cfg", today)
        set_cvar_string("mapchangecfgfile", workpath)
    }
}
