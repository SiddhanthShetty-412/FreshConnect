#!/bin/bash

echo "========================================"
echo "FreshConnect Integration Startup Script"
echo "========================================"
echo

echo "Starting Node.js Backend..."
cd server
gnome-terminal --title="FreshConnect Backend" -- npm run dev &
cd ..

echo
echo "Waiting for backend to start..."
sleep 3

echo
echo "Starting Flutter Frontend..."
cd frontend
gnome-terminal --title="FreshConnect Frontend" -- flutter run &
cd ..

echo
echo "========================================"
echo "Integration started!"
echo "========================================"
echo
echo "Backend: http://localhost:5000"
echo "Frontend: Check the Flutter console for the URL"
echo
echo "Press Ctrl+C to stop all processes..."
wait
