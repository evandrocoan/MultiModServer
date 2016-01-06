@echo off

for %%i in (*.sma) do (
    echo.
    echo // Compiling %%i ...
    echo.

    amxxpc.exe "%%i" -ocompiled/"%%~ni.amxx"
)

echo.
if "%1"=="" pause

start /min install.bat 1
