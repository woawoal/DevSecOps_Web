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

Write-Host "환경 초기화를 시작합니다..." -ForegroundColor Red

# 1. 쿠버네티스 클러스터 삭제
Write-Host "`n1. 쿠버네티스 클러스터를 정리하고 있습니다..." -ForegroundColor Yellow
try {
    $result = kind delete cluster --name devsecops-cluster 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  - 클러스터가 성공적으로 제거되었습니다" -ForegroundColor Green
    } else {
        Write-Host "  - 현재 실행 중인 클러스터가 없어 건너뜁니다" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  - Kind가 설치되어 있지 않아 건너뜁니다" -ForegroundColor Yellow
}

# 2. Docker 정리
Write-Host "`n2. Docker 환경을 정리하고 있습니다..." -ForegroundColor Yellow
try {
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        Write-Host "  - 실행 중인 컨테이너를 중지합니다..."
        docker stop $(docker ps -aq) 2>&1 | Out-Null
        Write-Host "  - 모든 컨테이너를 제거합니다..."
        docker rm $(docker ps -aq) 2>&1 | Out-Null
        Write-Host "  - 모든 이미지를 제거합니다..."
        docker rmi $(docker images -q) -f 2>&1 | Out-Null
        Write-Host "  - Docker 정리가 완료되었습니다" -ForegroundColor Green
    } else {
        Write-Host "  - Docker가 설치되어 있지 않아 건너뜁니다" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  - Docker가 실행 중이지 않거나 정리할 항목이 없어 건너뜁니다" -ForegroundColor Yellow
}

# 3. 프로그램 제거
Write-Host "`n3. 설치된 프로그램들을 제거하고 있습니다..." -ForegroundColor Yellow

# Chocolatey 확인
$chocoExists = Get-Command choco -ErrorAction SilentlyContinue
if ($chocoExists) {
    # 프로그램 제거 함수
    function Uninstall-Program {
        param (
            [string]$Name,
            [string]$DisplayName
        )
        Write-Host "  - $DisplayName 제거를 시도합니다..." -ForegroundColor Cyan
        $result = choco uninstall -y --force $Name 2>&1
        if ($result -match "is not installed") {
            Write-Host "    이미 제거되어 있어 건너뜁니다" -ForegroundColor Yellow
        } else {
            Write-Host "    제거가 완료되었습니다" -ForegroundColor Green
        }
    }

    # 각 프로그램 제거
    Uninstall-Program "kind" "Kind"
    Uninstall-Program "kubernetes-cli" "Kubernetes CLI"
    Uninstall-Program "docker-desktop" "Docker Desktop"
    Uninstall-Program "git.install" "Git"
    Uninstall-Program "git" "Git (기본 패키지)"
    Uninstall-Program "git-lfs" "Git LFS"
    Uninstall-Program "github-desktop" "GitHub Desktop"
    Uninstall-Program "gitextensions" "Git Extensions"
    Uninstall-Program "tortoisegit" "TortoiseGit"

    # Windows 기능에서 WSL 제거
    Write-Host "  - Windows WSL 기능을 제거하고 있습니다..." -ForegroundColor Cyan
    try {
        $result = Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart 2>&1
        if ($result.RestartNeeded) {
            Write-Host "    WSL 기능이 제거되었습니다 (재시작 필요)" -ForegroundColor Yellow
        } else {
            Write-Host "    WSL 기능이 제거되었습니다" -ForegroundColor Green
        }
    } catch {
        Write-Host "    WSL 기능이 이미 제거되어 있어 건너뜁니다" -ForegroundColor Yellow
    }

    # WSL 배포판 제거
    Write-Host "  - WSL 배포판을 제거하고 있습니다..." -ForegroundColor Cyan
    try {
        wsl --shutdown 2>&1 | Out-Null
        $distros = wsl --list --quiet 2>&1
        if ($distros -and $distros -notmatch "Windows Subsystem for Linux has no installed distributions") {
            foreach ($distro in $distros) {
                $distro = $distro.Trim()
                if ($distro -ne "") {
                    Write-Host "    $distro 배포판을 제거합니다..."
                    wsl --unregister $distro 2>&1 | Out-Null
                }
            }
            Write-Host "    모든 WSL 배포판이 제거되었습니다" -ForegroundColor Green
        } else {
            Write-Host "    설치된 WSL 배포판이 없어 건너뜁니다" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    WSL이 설치되어 있지 않아 건너뜁니다" -ForegroundColor Yellow
    }

    # 환경 변수 정리
    Write-Host "`n4. 환경 변수를 정리하고 있습니다..." -ForegroundColor Yellow
    try {
        # Docker 관련 환경 변수 제거
        [Environment]::SetEnvironmentVariable("DOCKER_HOST", $null, "User")
        [Environment]::SetEnvironmentVariable("DOCKER_CERT_PATH", $null, "User")
        [Environment]::SetEnvironmentVariable("DOCKER_TLS_VERIFY", $null, "User")
        [Environment]::SetEnvironmentVariable("DOCKER_BUILDKIT", $null, "User")
        [Environment]::SetEnvironmentVariable("COMPOSE_DOCKER_CLI_BUILD", $null, "User")
        
        # Kubernetes 관련 환경 변수 제거
        [Environment]::SetEnvironmentVariable("KUBECONFIG", $null, "User")
        
        # WSL 관련 환경 변수 제거
        [Environment]::SetEnvironmentVariable("WSL_UTF8", $null, "User")
        [Environment]::SetEnvironmentVariable("WSLENV", $null, "User")
        
        Write-Host "  - 환경 변수가 정리되었습니다" -ForegroundColor Green
    } catch {
        Write-Host "  - 일부 환경 변수 제거에 실패했지만 무시해도 됩니다" -ForegroundColor Yellow
    }

    # 5. Chocolatey 제거
    Write-Host "`n5. Chocolatey를 제거하고 있습니다..." -ForegroundColor Yellow
    if (Test-Path env:ChocolateyInstall) {
        try {
            Remove-Item -Recurse -Force "$env:ChocolateyInstall" -ErrorAction SilentlyContinue
            [System.Environment]::SetEnvironmentVariable("ChocolateyInstall", $null, "Machine")
            Write-Host "  - Chocolatey가 제거되었습니다" -ForegroundColor Green
        } catch {
            Write-Host "  - Chocolatey 제거 중 오류가 발생했지만 무시해도 됩니다" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  - Chocolatey가 설치되어 있지 않아 건너뜁니다" -ForegroundColor Yellow
    }
} else {
    Write-Host "  - Chocolatey가 설치되어 있지 않아 프로그램 제거를 건너뜁니다" -ForegroundColor Yellow
}

Write-Host "`n환경 초기화가 완료되었습니다!" -ForegroundColor Green
Write-Host "`n다음 단계:" -ForegroundColor Yellow
Write-Host "1. 컴퓨터를 재시작해주세요." -ForegroundColor Cyan
Write-Host "2. PowerShell을 관리자 권한으로 실행해주세요." -ForegroundColor Cyan
Write-Host "3. 다음 명령어로 새로운 환경을 구성할 수 있습니다:" -ForegroundColor Cyan
Write-Host "   .\install-requirements.ps1" -ForegroundColor White
pause
