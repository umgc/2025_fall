start "" ngrok.exe http 8080
timeout /t 2 >nul
for /f "tokens=2 delims=:," %%A in ('curl -s http://127.0.0.1:4040/api/tunnels ^| findstr /i "public_url" ^| findstr /i "https"') do set URL=%%A
set URL=%URL:~2,-1%
echo %URL%> .public_url
echo Public URL: %URL%