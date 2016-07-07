@echo off


rem Get the current date to the variable CURRENT_DATE
for /f %%i in ('date /T') do set CURRENT_DATE=%%i


rem Update the current galileo version file include
xcopy /E /S /Y ".\include" "%AMXX_COMPILER%\include"


for %%i in (*.sma) do (
    echo.
    echo // Compiling %%i ... Current time is: %time% - %CURRENT_DATE%
    echo.
    
    amxxpc.exe "%%i" -ocompiled/"%%~ni.amxx"
)


echo.
if "%1"=="" pause


start /min install.bat 1

