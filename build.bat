@echo off
echo Building web-wargamer Docker image...
docker build -t web-wargamer .

echo.
echo Build completed!
echo You can now run the container using run.bat
