@echo off

for %%i in (*.sma) do (
    echo.
    echo uncrustify.exe -c uncrustify\cfg\amxmodx.cfg --no-backup %%i
    uncrustify.exe -c uncrustify\cfg\amxmodx.cfg --no-backup %%i
    
    echo intend_empty_lines.lua %%i > temp_file.txt
    intend_empty_lines.lua %%i > temp_file.txt
    del %%i

    :: convert the EOF from CRLF to LF due the loss by the " > " above. 
    echo tr -d '\r' < temp_file.txt > %%i
    tr -d '\r' < temp_file.txt > %%i
    del temp_file.txt

    echo.
    echo // Compiling %%i ...
    echo.

    amxxpc.exe "%%i" -ocompiled/"%%~ni.amxx"

    echo.
)

xcopy /E /S /Y ".\compiled" "F:\SteamCMD\steamapps\common\Half-Life\cstrike\addons\amxmodx\plugins"
xcopy /E /S /Y ".\compiled" "F:\SteamCMD\steamapps\common\Half-Life\czero\addons\amxmodx\plugins"

if "%1"=="" pause
