echo ADDONS ZZ MULTI-MOD SERVER INSTALLER
pause

xcopy /E /S /Y ".\gamemod_common" "F:\SteamCMD\steamapps\common\Half-Life\czero\"
xcopy /E /S /Y ".\gamemod_common" "F:\SteamCMD\steamapps\common\Half-Life\cstrike\"

xcopy /E /S /Y ".\czero" "F:\SteamCMD\steamapps\common\Half-Life\czero\"
xcopy /E /S /Y ".\cstrike" "F:\SteamCMD\steamapps\common\Half-Life\cstrike\"

xcopy /E /S /Y ".\cstrike_czero" "F:\SteamCMD\steamapps\common\Half-Life\czero\"
xcopy /E /S /Y ".\cstrike_czero" "F:\SteamCMD\steamapps\common\Half-Life\cstrike\"

pause