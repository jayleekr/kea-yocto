#!/bin/bash

# VM exec format error 강제 해결 스크립트
# Docker 이미지 완전 재설정

set -e

echo "🔧 VM exec format error 강제 해결"
echo "=================================="
echo

# 시스템 확인
ARCH=$(uname -m)
echo "시스템 아키텍처: $ARCH"

DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"

echo
echo "1단계: 모든 관련 이미지 완전 삭제"
echo "=================================="

# 모든 yocto 관련 이미지 삭제
docker images | grep yocto | awk '{print $3}' | xargs -r docker rmi -f || true
docker images | grep jabang3 | awk '{print $3}' | xargs -r docker rmi -f || true

# Docker 시스템 완전 정리
docker system prune -af
docker volume prune -f

echo "✅ 이미지 정리 완료"

echo
echo "2단계: 아키텍처별 이미지 강제 다운로드"
echo "========================================"

if [ "$ARCH" = "aarch64" ]; then
    echo "ARM64 VM 감지 - 실행 방법 선택:"
    echo "1) ARM64 네이티브 (권장)"
    echo "2) x86_64 에뮬레이션 (강의 환경 일치)"
    read -p "선택 [1/2]: " choice
    
    if [ "$choice" = "2" ]; then
        echo "x86_64 에뮬레이션 모드 설정..."
        
        # QEMU 설치
        if ! dpkg -l | grep -q qemu-user-static; then
            echo "QEMU 설치 중..."
            sudo apt-get update
            sudo apt-get install -y qemu-user-static binfmt-support
        fi
        
        # QEMU 에뮬레이션 활성화
        echo "QEMU 에뮬레이션 활성화..."
        docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
        
        # x86_64 이미지 강제 다운로드 (다이제스트 사용)
        echo "x86_64 이미지 다이제스트로 강제 다운로드..."
        docker pull jabang3/yocto-lecture@sha256:cf56f85fbfeddb20a1f9277b63ada51b884f1bc65b86b28ebeb3a8698ac6437f
        docker tag jabang3/yocto-lecture@sha256:cf56f85fbfeddb20a1f9277b63ada51b884f1bc65b86b28ebeb3a8698ac6437f $DOCKER_IMAGE
        
        PLATFORM_FLAG="--platform linux/amd64"
        TEST_MODE="x86_64 에뮬레이션"
        
    else
        echo "ARM64 네이티브 모드 설정..."
        
        # ARM64 이미지 강제 다운로드 (다이제스트 사용)
        echo "ARM64 이미지 다이제스트로 강제 다운로드..."
        docker pull jabang3/yocto-lecture@sha256:22ebbf27ef813ef38bdb681ff93c7c1d13c911bc9d68fb67460ca6f148a81939
        docker tag jabang3/yocto-lecture@sha256:22ebbf27ef813ef38bdb681ff93c7c1d13c911bc9d68fb67460ca6f148a81939 $DOCKER_IMAGE
        
        PLATFORM_FLAG="--platform linux/arm64"
        TEST_MODE="ARM64 네이티브"
    fi
    
elif [ "$ARCH" = "x86_64" ]; then
    echo "x86_64 시스템 감지"
    
    # x86_64 이미지 강제 다운로드 (다이제스트 사용)
    echo "x86_64 이미지 다이제스트로 강제 다운로드..."
    docker pull jabang3/yocto-lecture@sha256:cf56f85fbfeddb20a1f9277b63ada51b884f1bc65b86b28ebeb3a8698ac6437f
    docker tag jabang3/yocto-lecture@sha256:cf56f85fbfeddb20a1f9277b63ada51b884f1bc65b86b28ebeb3a8698ac6437f $DOCKER_IMAGE
    
    PLATFORM_FLAG="--platform linux/amd64"
    TEST_MODE="x86_64 네이티브"
    
else
    echo "지원하지 않는 아키텍처: $ARCH"
    exit 1
fi

echo "✅ 이미지 다운로드 완료"

echo
echo "3단계: 이미지 검증"
echo "=================="

# 이미지 아키텍처 확인
IMAGE_ARCH=$(docker image inspect $DOCKER_IMAGE | grep -o '"Architecture":"[^"]*"' | cut -d'"' -f4 | head -1)
echo "다운로드된 이미지 아키텍처: $IMAGE_ARCH"
echo "설정된 테스트 모드: $TEST_MODE"

echo
echo "4단계: 간단 테스트 실행"
echo "======================"

# 간단한 테스트 실행
echo "컨테이너 기본 테스트 중..."

mkdir -p test-workspace

docker run --rm \
    $PLATFORM_FLAG \
    -v $(pwd)/test-workspace:/workspace \
    --name yocto-quick-test \
    $DOCKER_IMAGE \
    /bin/bash -c "
        echo '=== 기본 테스트 ==='
        echo 'VM 아키텍처: $ARCH'
        echo '컨테이너 아키텍처: \$(uname -m)'
        echo '이미지 아키텍처: $IMAGE_ARCH'
        echo '테스트 모드: $TEST_MODE'
        echo ''
        echo '=== 환경 확인 ==='
        ls -la /opt/poky/
        echo ''
        echo '✅ 기본 테스트 성공!'
    " && {
    echo
    echo "🎉 VM exec format error 해결 완료!"
    echo "====================================="
    echo "✅ 컨테이너가 정상적으로 실행됩니다"
    echo "✅ $TEST_MODE 모드로 설정됨"
    echo "✅ 이미지 아키텍처: $IMAGE_ARCH"
    echo
    echo "다음 명령으로 Yocto 환경을 시작하세요:"
    echo "  ./scripts/arm64-vm-fix.sh"
    echo "  또는"
    echo "  docker run -it --rm $PLATFORM_FLAG -v \$(pwd)/yocto-workspace:/workspace $DOCKER_IMAGE"
    
} || {
    echo
    echo "❌ 여전히 문제가 있습니다"
    echo "=========================="
    echo "다음을 확인해보세요:"
    echo "1. Docker 버전: docker --version"
    echo "2. 권한 확인: groups | grep docker"
    echo "3. 재부팅 후 다시 시도"
    echo "4. Docker 재설치"
}

echo
echo "강제 수정 작업이 완료되었습니다." 