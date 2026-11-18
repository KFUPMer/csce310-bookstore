@echo off
rem Runs scripts\stop-services.ps1. Double-click it; the window stays open so you can read the result.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\stop-services.ps1" %*
pause

