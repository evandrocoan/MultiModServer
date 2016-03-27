@echo off

for /f %%i in ('date /T') do set CURRENT_DATE=%%i

for %%i in (*.sma) do (
    echo.
    echo // Compiling %%i ... Current time is: %time% - %CURRENT_DATE% 
    echo.
    
    amxxpc.exe "%%i" -ocompiled/"%%~ni.amxx"
)

echo.
if "%1"=="" pause

start /min install.bat 1
