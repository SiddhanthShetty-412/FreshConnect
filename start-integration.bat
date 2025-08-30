@echo off
echo ========================================
echo FreshConnect Integration Startup Script
echo ========================================
echo.

echo Starting Node.js Backend...
cd server
start "FreshConnect Backend" cmd /k "npm run dev"
cd ..

echo.
echo Waiting for backend to start...
timeout /t 3 /nobreak > nul

echo.
echo Starting Flutter Frontend...
cd frontend
start "FreshConnect Frontend" cmd /k "flutter run"
cd ..

echo.
echo ========================================
echo Integration started!
echo ========================================
echo.
echo Backend: http://localhost:5000
echo Frontend: Check the Flutter console for the URL
echo.
echo Press any key to exit...
pause > nul
