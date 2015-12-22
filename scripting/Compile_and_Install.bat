uncrustify.exe -c uncrustify\cfg\amxmodx.cfg --no-backup galileo_reloaded.sma

intend_empty_lines.lua galileo_reloaded.sma > temp_file.txt
del galileo_reloaded.sma

rem convert the EOF from CRLF to LF due the loss by the " > " above. 
tr -d '\r' < temp_file.txt > galileo_reloaded.sma
del temp_file.txt

compile.exe
xcopy /E /S /Y ".\compiled" "F:\SteamCMD\steamapps\common\Half-Life\cstrike\addons\amxmodx\plugins"
xcopy /E /S /Y ".\compiled" "F:\SteamCMD\steamapps\common\Half-Life\czero\addons\amxmodx\plugins"

pause
