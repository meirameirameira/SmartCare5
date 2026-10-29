@echo off
REM Sobe a API Smart HAS sobre o Oracle (perfil "oracle", rotinas PL/SQL).
REM Pre-requisito: esquema instalado com database\oracle\instalar.sql.
REM Defina antes no terminal:
REM   set ORACLE_URL=jdbc:oracle:thin:@oracle.fiap.com.br:1521:ORCL
REM   set ORACLE_USER=seu_usuario
REM   set ORACLE_PASSWORD=sua_senha
cd /d "%~dp0"
REM Oracle local: credenciais em oracle.local.bat (fora do git), se existir.
if "%ORACLE_USER%"=="" if exist "%~dp0oracle.local.bat" call "%~dp0oracle.local.bat"
if "%ORACLE_USER%"=="" (
  echo Defina ORACLE_USER e ORACLE_PASSWORD antes de executar.
  exit /b 1
)
if "%JAVA_HOME%"=="" set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "SPRING_PROFILES_ACTIVE=oracle"
call "%~dp0gradlew.bat" bootRun --console=plain
