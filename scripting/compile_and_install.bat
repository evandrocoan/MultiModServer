@echo off


rem Components:
rem
rem Time calculation downloaded from:
rem http://stackoverflow.com/q/9922498/4934640
rem http://stackoverflow.com/questions/9922498/calculate-time-difference-in-windows-batch-file
rem
rem AMX Mod X compiling batch downloaded from:
rem https://github.com/alliedmodders/amxmodx/pull/212/commits



rem Get the current date to the variable CURRENT_DATE
for /f %%i in ('date /T') do set CURRENT_DATE=%%i

rem Here begins the command you want to measure
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
   set /A "start=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)


rem Update the current galileo version file include
xcopy /E /S /Y ".\include" "%AMXX_COMPILER%\include"

del F:\SteamCMD\steamapps\common\Half-Life\czero\addons\amxmodx\plugins\galileo.amxx

for %%i in (*.sma) do (
    echo.
    rem The format of %TIME% is HH:MM:SS,CS for example 23:59:59,99
    echo // Compiling %%i ... Current time is: %TIME% - %CURRENT_DATE%
    echo.

    del D:\User\Dropbox\Applications\SoftwareVersioning\Subtrees\Galileo\scripting\compiled\galileo.amxx
    amxxpc.exe "%%i" -ocompiled/"%%~ni.amxx"
)

rem Run the files installer.
echo.
start /min install.bat 1


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
echo Took %hh%:%mm%:%ss%,%cc% seconds to run this script.



rem Pause the script for result reading, when it is run without any command line parameters.
echo.
if "%1"=="" pause



