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

Write-Host "워게임 환경 구축에 필요한 도구들을 설치합니다..." -ForegroundColor Green

# Windows 기능 활성화
Write-Host "`n1. Windows 필수 기능을 활성화하고 있습니다..." -ForegroundColor Yellow
try {
    Write-Host "  - WSL 기능을 활성화하고 있습니다..."
    $result = Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart 2>&1
    if ($result.RestartNeeded) {
        Write-Host "    WSL 기능이 활성화되었습니다 (재시작 필요)" -ForegroundColor Yellow
    } else {
        Write-Host "    WSL 기능이 활성화되었습니다" -ForegroundColor Green
    }

    Write-Host "  - 가상 머신 플랫폼을 활성화하고 있습니다..."
    $result = Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart 2>&1
    if ($result.RestartNeeded) {
        Write-Host "    가상 머신 플랫폼이 활성화되었습니다 (재시작 필요)" -ForegroundColor Yellow
    } else {
        Write-Host "    가상 머신 플랫폼이 활성화되었습니다" -ForegroundColor Green
    }
} catch {
    Write-Error "Windows 기능 활성화 중 오류가 발생했습니다: $_"
    Write-Host "`n다음 사항을 확인해주세요:" -ForegroundColor Cyan
    Write-Host "- Windows 업데이트가 최신 상태인지 확인" -ForegroundColor White
    Write-Host "- 컴퓨터를 재시작한 후 다시 시도" -ForegroundColor White
    pause
    exit
}

# Chocolatey 설치 전 설정
$env:ChocolateyEnvironmentDebug = 'false'
$env:ChocolateyQuiet = 'true'

# 프로그램 설치 함수
function Install-Program {
    param (
        [string]$Name,
        [string]$DisplayName
    )
    Write-Host "  - $DisplayName 설치를 시도합니다..." -ForegroundColor Cyan
    $result = choco install -y --force --confirm $Name 2>&1
    if ($result -match "already installed") {
        Write-Host "    이미 설치되어 있어 건너뜁니다" -ForegroundColor Yellow
    } else {
        Write-Host "    설치가 완료되었습니다" -ForegroundColor Green
    }
}

# Chocolatey 설치
Write-Host "`n2. 패키지 관리자(Chocolatey)를 설치하고 있습니다..." -ForegroundColor Yellow
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "  - 패키지 관리자 설치가 완료되었습니다" -ForegroundColor Green
} catch {
    Write-Error "  - 패키지 관리자 설치 실패: $_"
    pause
    exit
}

# 필수 도구 설치
Write-Host "`n3. 필수 도구들을 설치하고 있습니다..." -ForegroundColor Yellow

# Git 관련 도구 설치
Install-Program "git" "Git (기본 패키지)"
Install-Program "git.install" "Git"
Install-Program "git-lfs" "Git LFS"
Install-Program "github-desktop" "GitHub Desktop"
Install-Program "gitextensions" "Git Extensions"
Install-Program "tortoisegit" "TortoiseGit"

# Docker Desktop 설치
Install-Program "docker-desktop" "Docker Desktop"

# Kubernetes 관련 도구 설치
Install-Program "kubernetes-cli" "Kubernetes CLI"
Install-Program "kind" "Kind"

# WSL 관련 설치
Write-Host "  - WSL을 설치하고 있습니다..." -ForegroundColor Cyan
try {
    # WSL2 Linux 커널 업데이트 패키지 다운로드 및 설치
    Write-Host "    WSL2 Linux 커널 업데이트 패키지를 설치하고 있습니다..."
    $wslUrl = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $wslInstaller = "$env:TEMP\wsl_update_x64.msi"
    Invoke-WebRequest -Uri $wslUrl -OutFile $wslInstaller -UseBasicParsing
    Start-Process msiexec.exe -Wait -ArgumentList "/I $wslInstaller /quiet" -NoNewWindow
    Remove-Item $wslInstaller
    
    # WSL 기본 버전을 2로 설정
    Write-Host "    WSL 기본 버전을 2로 설정하고 있습니다..."
    wsl --set-default-version 2 2>&1 | Out-Null
    
    Write-Host "    WSL 설치가 완료되었습니다" -ForegroundColor Green
} catch {
    Write-Warning "    WSL 설치 중 오류가 발생했지만 무시하고 진행합니다"
}

# 환경 변수 설정
Write-Host "`n4. 환경 변수를 설정하고 있습니다..." -ForegroundColor Yellow
try {
    Write-Host "  - Docker 관련 환경 변수를 설정합니다..."
    [Environment]::SetEnvironmentVariable("DOCKER_BUILDKIT", "1", "User")
    [Environment]::SetEnvironmentVariable("COMPOSE_DOCKER_CLI_BUILD", "1", "User")
    
    Write-Host "  - WSL 관련 환경 변수를 설정합니다..."
    [Environment]::SetEnvironmentVariable("WSL_UTF8", "1", "User")
    
    Write-Host "  - Git 관련 환경 변수를 설정합니다..."
    [Environment]::SetEnvironmentVariable("GIT_INSTALL_ROOT", "$env:ProgramFiles\Git", "User")
    
    Write-Host "  - 모든 환경 변수가 설정되었습니다" -ForegroundColor Green
} catch {
    Write-Warning "  - 일부 환경 변수 설정에 실패했지만 무시하고 진행합니다"
}

# 설치 후 초기 설정
Write-Host "`n5. 초기 설정을 진행하고 있습니다..." -ForegroundColor Yellow
try {
    Write-Host "  - Git 설정을 적용합니다..."
    git config --system core.longpaths true 2>&1 | Out-Null
    git config --system core.protectNTFS false 2>&1 | Out-Null
    Write-Host "  - Git 설정이 완료되었습니다" -ForegroundColor Green
} catch {
    Write-Warning "  - Git 설정 중 오류가 발생했지만 무시하고 진행합니다"
}

Write-Host "`n모든 설치가 완료되었습니다!" -ForegroundColor Green
Write-Host "`n다음 단계:" -ForegroundColor Yellow
Write-Host "1. 지금 바로 컴퓨터를 재시작해주세요" -ForegroundColor Cyan
Write-Host "2. 재시작 후 Docker Desktop을 실행해주세요" -ForegroundColor Cyan
Write-Host "3. Docker Desktop 설정에서 다음 사항을 확인해주세요:" -ForegroundColor Cyan
Write-Host "   - 'Use Docker Compose V2' 옵션 켜기" -ForegroundColor White
Write-Host "   - 'Kubernetes' 옵션 끄기" -ForegroundColor White
Write-Host "4. 설정이 완료되면 'deploy-wargame.ps1'을 실행해주세요" -ForegroundColor Cyan
Write-Host "`n문제가 발생하면:" -ForegroundColor Yellow
Write-Host "- 모든 설치가 완료될 때까지 기다려주세요" -ForegroundColor White
Write-Host "- 재시작 후에도 문제가 지속되면 스크립트를 다시 실행해보세요" -ForegroundColor White
pause
