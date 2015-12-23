@echo off

for %%i in (*.sma) do (
    echo.
    echo // Compiling %%i ...
    echo.

    amxxpc.exe "%%i" -ocompiled/"%%~ni.amxx"
)

xcopy /E /S /Y ".\compiled" "F:\SteamCMD\steamapps\common\Half-Life\cstrike\addons\amxmodx\plugins"
xcopy /E /S /Y ".\compiled" "F:\SteamCMD\steamapps\common\Half-Life\czero\addons\amxmodx\plugins"

if "%1"=="" pause
