@echo off

SET MULTIMOD_FOLDER=D:\User\Archives\Dropbox\Applications\SoftwareVersioning\MultiMod_Manager

echo.
echo xcopy /E /S /Y ".\multimod" "%MULTIMOD_FOLDER%\configs\multimod"
xcopy /E /S /Y ".\multimod" "%MULTIMOD_FOLDER%\configs\multimod"

echo.
echo xcopy /E /S /Y ".\maps" "%MULTIMOD_FOLDER%\configs\maps"
xcopy /E /S /Y ".\maps" "%MULTIMOD_FOLDER%\configs\maps"

if "%1"=="" pause

exit
