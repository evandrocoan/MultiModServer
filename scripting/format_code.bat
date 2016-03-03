>compiled\uncrustify_log.txt 2>&1 (

@echo off

for %%i in (*.sma) do (
    echo.
    echo uncrustify.exe -c amxmodx.cfg --no-backup %%i
    uncrustify.exe -c amxmodx.cfg --no-backup %%i || pause
    
    if %ERRORLEVEL% neq 0 (
    echo 'Error!'
    pause
    )
    
    echo intend_empty_lines.lua %%i > temp_file.txt
    intend_empty_lines.lua %%i > temp_file.txt
    del %%i

    :: convert the EOF from CRLF to LF due the loss by the " > " above. 
    echo tr -d '\r' < temp_file.txt > %%i
    tr -d '\r' < temp_file.txt > %%i
    del temp_file.txt
)

echo.
rem if "%1"=="" pause

)
