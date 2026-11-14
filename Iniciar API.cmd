@echo off
cd /d "%~dp0"
python scripts\mysql_local.py iniciar
if errorlevel 1 goto error
".tools\composer\php\php.exe" api\artisan migrate --force
if errorlevel 1 goto error
cd api
"..\.tools\composer\php\php.exe" artisan serve --host=127.0.0.1 --port=8000
exit /b
:error
echo No se pudo iniciar la API. Revisa el mensaje anterior.
pause
exit /b 1
