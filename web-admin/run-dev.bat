@echo off
REM Sobe o painel administrativo Angular em modo desenvolvimento (porta 4200).
REM Requer o back-end rodando em http://localhost:8080 (ver backend/run-dev.bat).
cd /d "%~dp0"
call npx ng serve --port 4200
