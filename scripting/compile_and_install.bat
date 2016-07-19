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
set STARTTIME=%TIME%

rem Update the current galileo version file include
xcopy /E /S /Y ".\include" "%AMXX_COMPILER%\include"


for %%i in (*.sma) do (
    echo.
    rem The format of %TIME% is HH:MM:SS,CS for example 23:59:59,99
    echo // Compiling %%i ... Current time is: %TIME% - %CURRENT_DATE%
    echo.
    
    amxxpc.exe "%%i" -ocompiled/"%%~ni.amxx"
)

rem Run the files installer.
start /min install.bat 1

rem Pause the script for result reading, when it is run without any command line parameters.
echo.
if "%1"=="" pause



rem Here ends the command you want to measure.
set ENDTIME=%TIME%

rem Convert STARTTIME and ENDTIME to centiseconds.
set /A STARTTIME=(1%STARTTIME:~0,2%-100)*360000 + (1%STARTTIME:~3,2%-100)*6000 + (1%STARTTIME:~6,2%-100)*100 + (1%STARTTIME:~9,2%-100)
set /A ENDTIME=(1%ENDTIME:~0,2%-100)*360000 + (1%ENDTIME:~3,2%-100)*6000 + (1%ENDTIME:~6,2%-100)*100 + (1%ENDTIME:~9,2%-100)

rem Calculating the duration is easy.
set /A DURATION=%ENDTIME%-%STARTTIME%

rem we might have measured the time between days.
if %ENDTIME% LSS %STARTTIME% set set /A DURATION=%STARTTIME%-%ENDTIME%

rem Now break the centiseconds down to hors, minutes, seconds and the remaining centiseconds.
set /A DURATIONH=%DURATION% / 360000
set /A DURATIONM=(%DURATION% - %DURATIONH%*360000) / 6000
set /A DURATIONS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000) / 100
set /A DURATIONHS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000 - %DURATIONS%*100)

rem Some formatting.
if %DURATIONH% LSS 10 set DURATIONH=0%DURATIONH%
if %DURATIONM% LSS 10 set DURATIONM=0%DURATIONM%
if %DURATIONS% LSS 10 set DURATIONS=0%DURATIONS%
if %DURATIONHS% LSS 10 set DURATIONHS=0%DURATIONHS%

rem Outputting.
echo Took %DURATIONH%:%DURATIONM%:%DURATIONS%,%DURATIONHS% seconds to run this script.
