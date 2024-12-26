#!/bin/bash

# 기존 컨테이너 정리
echo "Cleaning up existing container..."
docker stop web-wargamer 2>/dev/null
docker rm web-wargamer 2>/dev/null

# 새 이미지 빌드
echo "Building new image..."
docker build -t web-wargamer .

echo "Docker image name is web-wargamer"