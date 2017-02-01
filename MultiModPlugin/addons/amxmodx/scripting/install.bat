@echo off


rem Game list to install the new files.
set GAMES_MODS[0]=F:\SteamCMD\steamapps\common\Half-Life\cstrike
set GAMES_MODS[1]=F:\SteamCMD\steamapps\common\Half-Life\czero
set GAMES_MODS[2]=F:\SteamLibrary\steamapps\common\Sven Co-op Dedicated Server\svencoop

rem Sub game installation folders to copy the new data.
SET PLUGINS_FOLDER=addons\amxmodx\plugins
SET CONFIGS_FOLDER=addons\amxmodx\configs
SET LANGS_FOLDER=addons\amxmodx\data\lang

rem Initial array index to loop into.
set "currentIndex=0"

rem Loop throw all games to install the new files.
:SymLoop
if defined GAMES_MODS[%currentIndex%] (
    rem Print what mod it currently copying/installing
    echo.
    call echo Coping files to "%%GAMES_MODS[%currentIndex%]%%"...
    
    rem To do the actual copying/installing.
    call xcopy /E /S /Y ".\compiled" "%%GAMES_MODS[%currentIndex%]%%\%PLUGINS_FOLDER%"
    
    cd ..
    call xcopy /E /S /Y ".\configs" "%%GAMES_MODS[%currentIndex%]%%\%CONFIGS_FOLDER%"
    call xcopy /E /S /Y ".\data\lang" "%%GAMES_MODS[%currentIndex%]%%\%LANGS_FOLDER%"
    cd scripting
    
    rem Update the next 'for/array' index to copy/install.
    set /a "currentIndex+=1"
    GOTO :SymLoop
)


rem Pause the script for result reading, when it is run without any command line parameters.
echo.
if "%1"=="" pause

exit



