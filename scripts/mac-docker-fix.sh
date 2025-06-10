#!/bin/bash

# Mac Docker 문제 완전 해결 스크립트

set -e

echo "🔧 Mac Docker 문제 진단 및 해결 중..."
echo "======================================"

# 1. 시스템 정보 확인
echo "=== 시스템 정보 ==="
echo "macOS: $(sw_vers -productVersion)"
echo "Architecture: $(uname -m)"
echo "Docker Version:"
docker --version 2>/dev/null || echo "Docker not found"
echo ""

# 2. Docker Desktop 상태 확인
echo "=== Docker 상태 확인 ==="
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker가 실행되지 않고 있습니다."
    echo "해결방법:"
    echo "1. Docker Desktop 앱을 시작하세요"
    echo "2. 또는 터미널에서: open -a Docker"
    exit 1
fi

echo "✅ Docker가 실행 중입니다."
echo ""

# 3. Docker Desktop 재시작
echo "=== Docker Desktop 재시작 ==="
echo "Docker를 재시작하여 문제를 해결합니다..."
read -p "Docker Desktop을 재시작하시겠습니까? [y/N]: " restart_docker

if [[ "$restart_docker" == "y" ]] || [[ "$restart_docker" == "Y" ]]; then
    echo "Docker Desktop 중지 중..."
    osascript -e 'quit app "Docker Desktop"' 2>/dev/null || true
    killall Docker 2>/dev/null || true
    sleep 5
    
    echo "Docker Desktop 시작 중..."
    open -a Docker
    echo "Docker가 완전히 시작될 때까지 30초 대기..."
    sleep 30
    
    # Docker 준비 확인
    echo "Docker 준비 상태 확인 중..."
    for i in {1..10}; do
        if docker info >/dev/null 2>&1; then
            echo "✅ Docker가 준비되었습니다."
            break
        fi
        echo "대기 중... ($i/10)"
        sleep 3
    done
fi

# 4. 이미지 강제 삭제 및 재다운로드
echo "=== 이미지 문제 해결 ==="
echo "기존 문제 이미지 제거 중..."
docker rmi jabang3/yocto-lecture:5.0-lts 2>/dev/null || true
docker rmi jabang3/yocto-lecture:latest 2>/dev/null || true

echo "시스템 정리 중..."
docker system prune -f

echo "올바른 이미지 다운로드 중..."
# Mac에서는 자동으로 적절한 아키텍처 선택하도록 함
docker pull jabang3/yocto-lecture:5.0-lts

# 5. 이미지 확인
echo "=== 이미지 확인 ==="
if docker buildx imagetools inspect jabang3/yocto-lecture:5.0-lts >/dev/null 2>&1; then
    echo "이미지 매니페스트:"
    docker buildx imagetools inspect jabang3/yocto-lecture:5.0-lts
else
    echo "buildx를 사용할 수 없습니다. 기본 확인 방법 사용..."
    docker images jabang3/yocto-lecture:5.0-lts
fi

# 6. 간단한 테스트
echo "=== 이미지 테스트 ==="
echo "기본 테스트 실행 중..."

# Rosetta 2 확인 (Apple Silicon에서)
if [ "$(uname -m)" = "arm64" ]; then
    echo "Apple Silicon 감지됨. Rosetta 2 확인 중..."
    if ! /usr/bin/pgrep oahd >/dev/null 2>&1; then
        echo "⚠️  Rosetta 2가 설치되지 않았을 수 있습니다."
        echo "   다음 명령어로 Rosetta 2를 설치하세요:"
        echo "   softwareupdate --install-rosetta"
    fi
fi

# 컨테이너 테스트 (기본 설정으로)
echo "컨테이너 기본 테스트..."
if timeout 30 docker run --rm jabang3/yocto-lecture:5.0-lts echo "✅ 컨테이너 실행 성공" 2>/dev/null; then
    echo "✅ 기본 컨테이너 테스트 성공"
    
    echo "아키텍처 확인 중..."
    docker run --rm jabang3/yocto-lecture:5.0-lts uname -m
    
    echo "Yocto 환경 확인 중..."
    docker run --rm jabang3/yocto-lecture:5.0-lts bash -c "
        source /opt/poky/oe-init-build-env /tmp/test >/dev/null 2>&1 && 
        echo '✅ Yocto 환경 정상' && 
        bitbake --version
    "
else
    echo "❌ 기본 테스트 실패. 고급 해결방법을 시도합니다..."
    
    # VM 설정 확인 및 조정
    echo "=== 고급 해결방법 ==="
    echo "Docker Desktop 설정을 확인하세요:"
    echo "1. Docker Desktop > Settings > General"
    echo "2. 'Use Virtualization framework' 체크"
    echo "3. 'Use Rosetta for x86/amd64 emulation on Apple Silicon' 체크"
    echo "4. Apply & Restart 클릭"
    echo ""
    
    read -p "설정을 변경하셨나요? Docker를 다시 테스트하시겠습니까? [y/N]: " retry_test
    if [[ "$retry_test" == "y" ]] || [[ "$retry_test" == "Y" ]]; then
        echo "재테스트 중..."
        if docker run --rm jabang3/yocto-lecture:5.0-lts echo "✅ 재테스트 성공"; then
            echo "✅ 문제가 해결되었습니다!"
        else
            echo "❌ 여전히 문제가 있습니다."
        fi
    fi
fi

# 7. 최종 권장사항
echo ""
echo "=== 최종 권장사항 ==="
echo ""
echo "✅ 성공적으로 해결된 경우:"
echo "   ./scripts/quick-start.sh 를 실행하세요"
echo ""
echo "❌ 여전히 문제가 있는 경우:"
echo "   1. Docker Desktop 완전 재설치"
echo "   2. macOS 재부팅"
echo "   3. GitHub Container Registry 사용:"
echo "      docker pull ghcr.io/jayleekr/yocto-lecture:5.0-lts"
echo ""
echo "📧 지속적인 문제 시 이슈 리포트:"
echo "   https://github.com/jayleekr/kea-yocto/issues"
echo ""
echo "완료!" 