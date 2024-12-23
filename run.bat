@echo off
echo Cleaning up existing container...
docker stop web-wargamer 2>nul
docker rm web-wargamer 2>nul

echo.
echo Starting new container...
docker run -d -p 80:80 -p 3307:3307 --name web-wargamer web-wargamer

echo.
echo Container logs:
docker logs web-wargamer

echo.
echo Container is running at http://localhost
echo MariaDB is available at localhost:3307 (user: root, password: 1234)
pause
