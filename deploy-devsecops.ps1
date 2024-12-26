# UTF-8 인코딩 설정
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# 관리자 권한 확인
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "이 스크립트는 관리자 권한이 필요합니다!"
    Write-Warning "PowerShell을 관리자 권한으로 다시 실행해주세요."
    pause
    exit
}

Write-Host "워게임 환경 구축을 시작합니다..." -ForegroundColor Green

# Docker Desktop 실행 확인
Write-Host "`n1. Docker Desktop 상태를 확인합니다..." -ForegroundColor Yellow
try {
    $dockerStatus = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Docker Desktop이 실행되지 않았습니다!"
        Write-Host "Docker Desktop을 먼저 실행해주세요." -ForegroundColor Cyan
        pause
        exit
    }
} catch {
    Write-Warning "Docker Desktop을 찾을 수 없습니다!"
    exit
}

# 기존 클러스터 삭제
Write-Host "`n1. 기존 클러스터를 정리하고 있습니다..." -ForegroundColor Yellow
try {
    Write-Host "  - 실행 중인 컨테이너를 중지합니다..."
    docker stop $(docker ps -aq) 2>&1 | Out-Null
    Write-Host "  - 모든 컨테이너를 제거합니다..."
    docker rm $(docker ps -aq) 2>&1 | Out-Null
    Write-Host "  - 모든 이미지를 제거합니다..."
    docker rmi $(docker images -q) -f 2>&1 | Out-Null
    Write-Host "  - 기존 클러스터를 삭제합니다..."
    $result = kind delete cluster --name devsecops-cluster 2>&1
    Write-Host "  - 클러스터 정리가 완료되었습니다" -ForegroundColor Green
} catch {
    Write-Host "  - 정리할 클러스터나 컨테이너가 없어 건너뜁니다" -ForegroundColor Yellow
}

# 새 클러스터 생성
Write-Host "`n2. 새로운 클러스터를 생성하고 있습니다..." -ForegroundColor Yellow
try {
    Write-Host "  - Kind 클러스터를 생성합니다..."
    kind create cluster --config k8s-yaml/kind-config.yaml --name devsecops-cluster
    
    Write-Host "  - 클러스터 상태를 확인합니다..."
    $nodes = kubectl get nodes 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  - 클러스터가 성공적으로 생성되었습니다" -ForegroundColor Green
    } else {
        throw "클러스터 생성은 완료되었으나 노드 확인에 실패했습니다"
    }
} catch {
    Write-Error "클러스터 생성에 실패했습니다. 오류 내용: $_"
    Write-Host "`n문제 해결 방법:" -ForegroundColor Yellow
    Write-Host "1. Docker Desktop이 정상적으로 실행 중인지 확인해주세요" -ForegroundColor White
    Write-Host "2. 이전 클러스터가 완전히 제거되었는지 확인해주세요" -ForegroundColor White
    Write-Host "3. 컴퓨터를 재시작한 후 다시 시도해보세요" -ForegroundColor White
    pause
    exit
}

# 웹 이미지 빌드 및 로드
Write-Host "`n3. 웹 애플리케이션 이미지를 준비하고 있습니다..." -ForegroundColor Yellow
try {
    Set-Location web_wargamer
    Write-Host "  - 도커 이미지를 빌드하고 있습니다..."
    docker build -t wargame-web:latest . 2>&1 | Out-Null
    Write-Host "  - 이미지를 클러스터에 로드하고 있습니다..."
    kind load docker-image wargame-web:latest --name devsecops-cluster 2>&1 | Out-Null
    Set-Location ..
    Write-Host "  - 이미지 준비가 완료되었습니다" -ForegroundColor Green
} catch {
    Write-Error "이미지 준비 중 오류가 발생했습니다. 오류 내용: $_"
    pause
    exit
}

# 쿠버네티스 리소스 배포
Write-Host "`n4. 쿠버네티스 리소스를 배포하고 있습니다..." -ForegroundColor Yellow
try {
    Write-Host "  - 데이터베이스 초기 설정을 적용하고 있습니다..."
    kubectl apply -f k8s-yaml/db-init-configmap.yaml 2>&1 | Out-Null
    
    Write-Host "  - 데이터베이스를 배포하고 있습니다..."
    kubectl apply -f k8s-yaml/db-deployment.yaml 2>&1 | Out-Null
    
    Write-Host "  - 웹 서버를 배포하고 있습니다..."
    kubectl apply -f k8s-yaml/web-deployment.yaml 2>&1 | Out-Null
    
    Write-Host "  - 서비스를 구성하고 있습니다..."
    kubectl apply -f k8s-yaml/services.yaml 2>&1 | Out-Null
    
    Write-Host "  - 모든 리소스가 성공적으로 배포되었습니다" -ForegroundColor Green
} catch {
    Write-Error "리소스 배포 중 오류가 발생했습니다. 오류 내용: $_"
    pause
    exit
}

# 배포 상태 확인
Write-Host "`n5. 배포 상태를 확인하고 있습니다..." -ForegroundColor Yellow
Write-Host "  - 모든 Pod가 준비될 때까지 잠시 기다려주세요..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

Write-Host "`n[Pod 상태]" -ForegroundColor White
kubectl get pods -o wide

Write-Host "`n[서비스 상태]" -ForegroundColor White
kubectl get services

Write-Host "`n환경 구성이 완료되었습니다!" -ForegroundColor Green
Write-Host "`n접속 방법:" -ForegroundColor Yellow
Write-Host "1. 웹 브라우저를 실행합니다" -ForegroundColor Cyan
Write-Host "2. 다음 주소로 접속합니다: http://localhost:30080" -ForegroundColor Cyan
Write-Host "`n문제가 발생한 경우:" -ForegroundColor Yellow
Write-Host "- Pod 상태가 'Running'이 될 때까지 잠시 기다려주세요" -ForegroundColor White
Write-Host "- Docker Desktop이 정상적으로 실행 중인지 확인해주세요" -ForegroundColor White
Write-Host "- 문제가 지속되면 스크립트를 다시 실행해주세요" -ForegroundColor White
pause
