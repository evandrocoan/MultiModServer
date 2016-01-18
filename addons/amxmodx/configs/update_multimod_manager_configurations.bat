@echo off

SET MULTIMOD_FOLDER=D:\Evandro\Archives\Dropbox\Aplicativos\SoftwareVersioning\MultiMod_Manager

echo.
echo xcopy /E /S /Y ".\multimod" "%MULTIMOD_FOLDER%\configs\multimod"
xcopy /E /S /Y ".\multimod" "%MULTIMOD_FOLDER%\configs\multimod"

echo.
echo xcopy /E /S /Y ".\maps" "%MULTIMOD_FOLDER%\configs\maps"
xcopy /E /S /Y ".\maps" "%MULTIMOD_FOLDER%\configs\maps"

if "%1"=="" pause

exit
