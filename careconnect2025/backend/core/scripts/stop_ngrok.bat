@echo off
for /f "tokens=2" %%p in ('tasklist ^| findstr /i "ngrok.exe"') do taskkill /PID %%p /F >nul 2>&1
echo ngrok stopped (if it was running).
