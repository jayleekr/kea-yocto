#!/bin/bash

# VM에서 exec format error 해결 테스트 스크립트

set -e

echo "🧪 VM exec format error 해결 테스트"
echo "=================================="

ARCH=$(uname -m)
echo "현재 아키텍처: $ARCH"

if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    echo "❌ 이 테스트는 ARM64 VM 전용입니다"
    exit 1
fi

# 1. 플랫폼 설정
echo ""
echo "🔧 1단계: 플랫폼 자동 설정"
./scripts/setup-platform.sh

# 2. Docker Compose 설정 확인
echo ""
echo "🐳 2단계: Docker Compose 설정 확인"
if docker compose config >/dev/null 2>&1; then
    echo "✅ Docker Compose 설정 OK"
    
    # 플랫폼 확인
    PLATFORM=$(docker compose config | grep -A 1 "platform:" | grep "linux" || echo "not found")
    echo "설정된 플랫폼: $PLATFORM"
    
    if echo "$PLATFORM" | grep -q "arm64"; then
        echo "✅ ARM64 플랫폼 올바르게 설정됨"
    else
        echo "❌ ARM64 플랫폼 설정 실패"
        exit 1
    fi
else
    echo "❌ Docker Compose 설정 오류"
    exit 1
fi

# 3. 간단한 컨테이너 테스트
echo ""
echo "🚀 3단계: 간단한 실행 테스트"

# 작업공간 생성
mkdir -p yocto-workspace/{workspace,downloads,sstate-cache}

echo "간단한 명령어 실행 테스트 중..."
if docker compose run --rm yocto-lecture /bin/bash -c "
    echo '=== 시스템 정보 ==='
    echo '아키텍처: \$(uname -m)'
    echo '배포판: \$(cat /etc/os-release | grep PRETTY_NAME)'
    echo '=== BitBake 확인 ==='
    bitbake --version || echo 'BitBake 경로 문제'
    echo '=== 환경 변수 ==='
    echo 'MACHINE: \$MACHINE'
    echo 'BB_NUMBER_THREADS: \$BB_NUMBER_THREADS'
    echo '=== 테스트 완료 ==='
" 2>&1; then
    echo ""
    echo "🎉 테스트 성공!"
    echo "✅ exec format error 해결됨"
    echo "✅ ARM64 VM에서 정상 실행 가능"
    echo ""
    echo "이제 안전하게 다음 명령어를 사용할 수 있습니다:"
    echo "  ./scripts/vm-arm64-safe.sh"
    echo "  ./scripts/quick-start.sh"
    echo "  docker compose run --rm yocto-lecture"
else
    echo ""
    echo "❌ 테스트 실패"
    echo "여전히 exec format error가 발생할 수 있습니다."
    echo ""
    echo "추가 확인사항:"
    echo "1. Docker 버전: $(docker --version)"
    echo "2. Docker Compose 버전: $(docker compose version)"
    echo "3. 이미지 아키텍처 확인 필요"
fi 