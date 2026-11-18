@echo off
rem Runs scripts\start-services.ps1. Double-click it; the window stays open so you can read the result.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-services.ps1" %*
pause

