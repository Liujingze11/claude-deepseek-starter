@echo off
setlocal

set "SCRIPT_DIR=%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install.ps1"

echo.
echo 如果窗口没有自动关闭，可以按任意键退出。
pause >nul
