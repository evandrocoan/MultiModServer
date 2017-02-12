#include <amxmodx>
#include <fakemeta>
#include <regex>
#include <kve>
public plugin_init()
{
    register_plugin("Texture Model & WAD Precacher", "2.0", "ts2do");

    // Disconnect from the AMXX interface
    pause("ad");
}
public plugin_precache()
{
    // Catch these engine functions so we can precache *t.mdl
    register_forward(FM_PrecacheModel, "PrecacheCallback");
    register_forward(FM_PrecacheGeneric, "PrecacheCallback");
    register_keyvalue("worldspawn", "wad", "PrecacheWADs")
}
public PrecacheCallback(const szModel[])
{
    new iNum, szError[128];
    // The model's extension can be removed like this:
    new Regex:hReg = regex_match(szModel, "(.*).mdl$", iNum, szError, 127);
    if(hReg>=REGEX_OK)
    {
        new sz[128];
        regex_substr(hReg, 1, sz, 127);

        // Determine the associated *t.mdl file and check if it exists
        strcat(sz, "t.mdl", 127);
        // Calling engfunc completes precache right away, whereas a
        // call to precache_model is, more or less, added to a queue.
        if(file_exists(sz)) engfunc(EngFunc_PrecacheModel, sz);
        regex_free(hReg);
    }
    return FMRES_IGNORED;
}
public PrecacheWADs(bExists, szValue[])
{
    new iNum, szError[128];
    // Read off data from BSP
    if(bExists)
    {
        new szWad[128];
        do
        {
            // Chip off a wad and try to precache it
            strtok(szValue, szWad, 127, szValue, 1023, ';');

            // Remove the unnecessary directory data
            new Regex:hReg = regex_match(szWad, "(.*)[/\\](.*.wad)", iNum, szError, 127);
            if(hReg>=REGEX_OK)
            {
                regex_substr(hReg, 2, szWad, 127);
                // For some reason, some shipped WADs like halflife.wad do not
                // get precached; this doesn't affect what the plugin is
                // intended for, but if problems arise, this is why.
                if(file_exists(szWad)) engfunc(EngFunc_PrecacheGeneric, szWad);
                regex_free(hReg);
            }
        }while(szWad[0]);
    }
}
