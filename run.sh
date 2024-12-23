#!/bin/bash

# 기존 컨테이너 정리
echo "Cleaning up existing container..."
docker stop web-wargamer 2>/dev/null
docker rm web-wargamer 2>/dev/null

# 새 이미지 빌드
echo "Building new image..."
docker build -t web-wargamer .

# 새 컨테이너 실행
echo "Starting new container..."
docker run -d -p 80:80 -p 3307:3307 --name web-wargamer web-wargamer

# 컨테이너 로그 확인
echo "Container logs:"
docker logs web-wargamer

echo "Container is running at http://localhost"
echo "MariaDB is available at localhost:3307 (user: root, password: 1234)"