@echo off
setlocal

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-copilot-proxy.ps1"
exit /b %ERRORLEVEL%
