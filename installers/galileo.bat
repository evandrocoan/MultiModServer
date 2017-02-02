

@echo off

rem AMXX Plugin Compiler Script
rem
rem  This program is free software; you can redistribute it and/or modify it
rem  under the terms of the GNU General Public License as published by the
rem  Free Software Foundation; either version 2 of the License, or ( at
rem  your option ) any later version.
rem
rem  This program is distributed in the hope that it will be useful, but
rem  WITHOUT ANY WARRANTY; without even the implied warranty of
rem  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
rem  See the GNU General Public License for more details.
rem
rem  You should have received a copy of the GNU General Public License
rem  along with this program.  If not, see <http://www.gnu.org/licenses/>.
rem


rem Get the current date to the variable CURRENT_DATE
for /f %%i in ('date /T') do set CURRENT_DATE=%%i

rem The format of %TIME% is HH:MM:SS,CS for example 23:59:59,99
echo.
echo Compiling %2... Current time is: %TIME% - %CURRENT_DATE%
echo.

rem Put here the paths to the folders where do you want to install the plugin.
rem You must to provide at least one folder.
set folders_list[0]=F:\SteamCMD\steamapps\common\Half-Life\cstrike\addons\amxmodx\plugins
set folders_list[1]=F:\SteamCMD\steamapps\common\Half-Life\czero\addons\amxmodx\plugins
set folders_list[2]=F:\SteamLibrary\steamapps\common\Sven Co-op Dedicated Server\svencoop\addons\amxmodx\plugins

rem Where is your compiler?
rem
rem Example:
rem F:/SteamCMD/steamapps/common/Half-Life/czero/addons/amxmodx/scripting/amxxpc.exe
rem
set AMXX_COMPILER_PATH=F:\SteamCMD\steamapps\common\Half-Life\czero\addons\amxmodx\scripting\amxxpc.exe





rem Components:
rem
rem Time calculation downloaded from:
rem http://stackoverflow.com/questions/9922498/calculate-time-difference-in-windows-batch-file
rem
rem AMX Mod X compiling batch downloaded from:
rem https://github.com/alliedmodders/amxmodx/pull/212/commits

rem Here begins the command you want to measure
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)


rem %1 is the first shell argument and %2 is the second shell argument passed by AmxxPawn.sublime-build
rem Usually they should be the plugin's file full path and the plugin's file name without extension.
rem
rem Example: %1="F:\SteamCMD\steamapps\common\Half-Life\czero\addons\my_plugin.sma"
set PLUGIN_SOURCE_CODE_FILE_PATH="%1"



rem Example: $2="my_plugin"
set PLUGIN_BASE_FILE_NAME=%2
set PLUGIN_BINARY_FILE_PATH=%folders_list[0]%\%PLUGIN_BASE_FILE_NAME%.amxx

rem Delete the old binary in case some crazy problem on the compiler, or in the system while copy it.
rem So, this way there is not way you are going to use the wrong version of the plugin without knowing it.
IF EXIST "%PLUGIN_BINARY_FILE_PATH%" del "%PLUGIN_BINARY_FILE_PATH%"

rem To call the compiler to compile the plugin to the output folder $PLUGIN_BINARY_FILE_PATH
"%AMXX_COMPILER_PATH%" -o"%PLUGIN_BINARY_FILE_PATH%" %PLUGIN_SOURCE_CODE_FILE_PATH%

rem If there was a compilation error, there is nothing more to be done.
IF NOT EXIST "%PLUGIN_BINARY_FILE_PATH%" GOTO end



echo.
echo 1 File(s) copied, to the folder %folders_list[0]%

rem Initial array index to loop into.
set "currentIndex=1"

rem Loop throw all games to install the new files.
:SymLoop
if defined folders_list[%currentIndex%] (

    rem Some how the AMXX compiler could not compiling/copied some times, so let us know when it does not.
    setlocal EnableDelayedExpansion

    rem Try to delete the file only if it exists
    IF EXIST "!folders_list[%currentIndex%]!\%PLUGIN_BASE_FILE_NAME%.amxx" del "!folders_list[%currentIndex%]!\%PLUGIN_BASE_FILE_NAME%.amxx"

    rem To do the actual copying/installing.
    for /f "delims=" %%a in ( 'xcopy /E /S /Y "%PLUGIN_BINARY_FILE_PATH%"^
            "!folders_list[%currentIndex%]!"^|find /v "%PLUGIN_BASE_FILE_NAME%"' ) do echo %%a, to the folder !folders_list[%currentIndex%]!

    rem Update the next 'for/array' index to copy/install.
    set /a "currentIndex+=1"

    GOTO :SymLoop
)



:end

rem Calculating the duration is easy.
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "end=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

rem Get elapsed time.
set /A elapsed=end-start

rem Show elapsed time:
set /A hh=elapsed/(60*60*100), rest=elapsed%%(60*60*100), mm=rest/(60*100), rest%%=60*100, ss=rest/100, cc=rest%%100
if %mm% lss 10 set mm=0%mm%
if %ss% lss 10 set ss=0%ss%
if %cc% lss 10 set cc=0%cc%

rem Outputting.
echo.
echo Took %hh%:%mm%:%ss%,%cc% seconds to run this script.

rem Pause the script for result reading, when it is run without any command line parameters.
echo.
if "%1"=="" pause



