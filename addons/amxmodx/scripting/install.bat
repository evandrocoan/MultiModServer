@echo off

SET GAME_FOLDER=F:\SteamCMD\steamapps\common\Half-Life

echo.
echo xcopy /E /S /Y ".\compiled" "%GAME_FOLDER%\cstrike\addons\amxmodx\plugins"
xcopy /E /S /Y ".\compiled" "%GAME_FOLDER%\cstrike\addons\amxmodx\plugins"
xcopy /E /S /Y ".\compiled" "%GAME_FOLDER%\czero\addons\amxmodx\plugins"

echo.
xcopy /E /S /Y ".\compiled" "%GAME_FOLDER%\cstrike\addons\amxmodx\plugins"
xcopy /E /S /Y ".\compiled" "%GAME_FOLDER%\czero\addons\amxmodx\plugins"

cd ..

echo.
xcopy /E /S /Y ".\configs" "%GAME_FOLDER%\cstrike\addons\amxmodx\configs"
xcopy /E /S /Y ".\configs" "%GAME_FOLDER%\czero\addons\amxmodx\configs"

echo.
xcopy /E /S /Y ".\data\lang" "%GAME_FOLDER%\cstrike\addons\amxmodx\data\lang"
xcopy /E /S /Y ".\data\lang" "%GAME_FOLDER%\czero\addons\amxmodx\data\lang"

if "%1"=="" pause

exit
