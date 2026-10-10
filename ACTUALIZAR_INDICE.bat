@echo off
title Indice de logs - IAdashems
cd /d "%~dp0"

echo Regenerando logs\INDICE_LOGS.md ...

rem py launcher (Python oficial)
where py >nul 2>nul
if not errorlevel 1 (
    py --version >nul 2>nul && (py tools\indice_logs.py & goto :done)
)

rem python que SÍ funcione (no el stub de Microsoft Store)
where python >nul 2>nul
if not errorlevel 1 (
    python --version >nul 2>nul && (python tools\indice_logs.py & goto :done)
)

rem fallback: venv de Hermes
"C:\Users\nicol\AppData\Local\hermes\hermes-agent\venv\Scripts\python.exe" tools\indice_logs.py

:done
echo.
pause
