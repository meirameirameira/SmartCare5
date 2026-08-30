@echo off
REM Sobe a API Smart HAS em modo desenvolvimento (perfil dev, banco H2 em arquivo).
REM Ajuste JAVA_HOME se o seu JDK 21+ estiver em outro caminho.
cd /d "%~dp0"
if "%JAVA_HOME%"=="" set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
call "%~dp0gradlew.bat" bootRun --console=plain
