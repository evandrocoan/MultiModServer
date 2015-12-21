uncrustify.exe -c uncrustify\cfg\amxmodx.cfg -f galileo_reloaded.sma -o galileo_reloaded.sma

compile.exe
xcopy /E /S /Y ".\compiled" "F:\SteamCMD\steamapps\common\Half-Life\cstrike\addons\amxmodx\plugins"
xcopy /E /S /Y ".\compiled" "F:\SteamCMD\steamapps\common\Half-Life\czero\addons\amxmodx\plugins"

pause
