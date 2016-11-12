@echo off


SET ERROR_LOG_FILE=uncrustify_log.txt
SET CONFIG_FILE=D:\User\Dropbox\Applications\SoftwareVersioning\MyUncrustifyConfigs\amxmodx.cfg




for /f %%i in ('date /T') do set CURRENT_DATE=%%i

echo.
echo Parsing file... Current time is: %time% - %CURRENT_DATE%

>compiled\%ERROR_LOG_FILE% 2>&1 (
for %%i in (*.sma) do (
    echo.
    echo uncrustify.exe -c %CONFIG_FILE% --no-backup "%%i"... Current time is: %time% - %CURRENT_DATE%
    uncrustify.exe -c %CONFIG_FILE% --no-backup "%%i" || goto error
    
    echo intend_empty_lines.lua "%%i" > temp_file.txt
    intend_empty_lines.lua "%%i" > temp_file.txt
    
    del "%%i"
    mv "temp_file.txt" "%%i"
)

echo.
)


goto successfully

:error
echo.
echo There is an ERROR! See the error log file on:
echo scripting\compiled\%ERROR_LOG_FILE%
echo.
pause
start compiled\%ERROR_LOG_FILE%
goto exit

:successfully
echo.
echo Successfully parsed the file! See the file logs on:
echo scripting\compiled\%ERROR_LOG_FILE%
if "%1"=="" goto exit
pause

:exit
