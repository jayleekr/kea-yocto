#!/bin/bash

# ARM64 VM 전용 안전한 시작 스크립트
# x86_64 에뮬레이션 문제를 피하고 ARM64 네이티브로만 실행

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🛡️  ARM64 VM 안전 모드 시작"
echo "============================="
echo

# 아키텍처 확인
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    log_error "이 스크립트는 ARM64 시스템 전용입니다."
    echo "현재 아키텍처: $ARCH"
    echo "대신 ./scripts/quick-start.sh를 사용하세요."
    exit 1
fi

log_info "ARM64 시스템 확인됨: $ARCH"

# 1단계: 플랫폼 설정
echo
log_step "1단계: ARM64 플랫폼 설정 중..."
./scripts/setup-platform.sh

# 2단계: 캐시 준비
echo
log_step "2단계: 캐시 다운로드 시도 중..."
./scripts/prepare-cache.sh

# 3단계: 워크스페이스 생성
echo
log_step "3단계: 워크스페이스 생성 중..."
mkdir -p yocto-workspace/{workspace,downloads,sstate-cache}
log_info "워크스페이스 준비 완료"

# 4단계: Docker 이미지 확인
echo
log_step "4단계: ARM64 전용 이미지 준비 중..."

ARM64_IMAGE="yocto-lecture:arm64-fast"
ORIGINAL_IMAGE="jabang3/yocto-lecture:5.0-lts"

# ARM64 전용 이미지가 있는지 확인
if docker image inspect $ARM64_IMAGE >/dev/null 2>&1; then
    log_info "✅ ARM64 전용 이미지 발견: $ARM64_IMAGE"
    DOCKER_IMAGE=$ARM64_IMAGE
    
    # 아키텍처 검증
    CONTAINER_ARCH=$(docker run --rm $ARM64_IMAGE uname -m 2>/dev/null || echo "unknown")
    if [ "$CONTAINER_ARCH" = "aarch64" ]; then
        log_info "✅ 이미지 검증 완료 - ARM64 네이티브"
    else
        log_error "⚠️  이미지 아키텍처 불일치: $CONTAINER_ARCH"
    fi
else
    log_info "ARM64 전용 이미지가 없습니다. 빌드를 시도합니다..."
    
    if [ -f "Dockerfile.arm64" ]; then
        log_info "🏗️  ARM64 이미지 빌드 중... (5-10분 소요)"
        if docker build -f Dockerfile.arm64 -t $ARM64_IMAGE . >/dev/null 2>&1; then
            log_info "✅ ARM64 이미지 빌드 성공!"
            DOCKER_IMAGE=$ARM64_IMAGE
        else
            log_error "❌ ARM64 이미지 빌드 실패. 기존 이미지를 사용합니다."
            DOCKER_IMAGE=$ORIGINAL_IMAGE
        fi
    else
        log_info "기존 이미지 사용: $ORIGINAL_IMAGE"
        DOCKER_IMAGE=$ORIGINAL_IMAGE
        
        # 기존 이미지 다운로드 시도
        if ! docker image inspect $DOCKER_IMAGE >/dev/null 2>&1; then
            log_info "이미지 다운로드 중..."
            docker pull --platform linux/arm64 $DOCKER_IMAGE 2>/dev/null || docker pull $DOCKER_IMAGE
        fi
    fi
fi

# 5단계: 컨테이너 실행
echo
log_step "5단계: Docker Compose로 컨테이너 시작..."

# Docker Compose 사용으로 변경 (더 안정적)
log_info "Docker Compose 설정 확인 중..."
if docker compose config >/dev/null 2>&1; then
    log_info "Docker Compose로 컨테이너 시작..."
    docker compose run --rm yocto-lecture
else
    log_error "Docker Compose 설정 오류. 직접 Docker 실행으로 대체합니다..."
    
    # 기존 컨테이너 정리
    docker rm -f yocto-lecture-arm64 2>/dev/null || true

    # ARM64 네이티브 실행 (에뮬레이션 없음)
    docker run -it --privileged \
        --platform linux/arm64 \
        -v $(pwd)/yocto-workspace/workspace:/workspace \
        -v $(pwd)/yocto-workspace/downloads:/opt/yocto/downloads \
        -v $(pwd)/yocto-workspace/sstate-cache:/opt/yocto/sstate-cache \
        -e BB_NUMBER_THREADS=8 \
        -e PARALLEL_MAKE="-j 8" \
        -e MACHINE=qemux86-64 \
        -e TMPDIR=/tmp/yocto-build \
        --name yocto-lecture-arm64 \
        $DOCKER_IMAGE \
        /bin/bash -c "
            echo '🎉 ARM64 Yocto 환경 시작'
            echo '========================'
            echo '아키텍처: \$(uname -m)'
            echo '타겟 머신: qemux86-64 (에뮬레이션됨)'
            echo
            echo '📝 주의사항:'
            echo '- ARM64에서 x86_64 타겟 빌드는 QEMU로 에뮬레이션됩니다'
            echo '- 빌드는 정상 작동하지만 속도가 느릴 수 있습니다'
            echo '- 빌드된 이미지는 QEMU x86_64에서 실행됩니다'
            echo
            echo '=== 빌드 환경 초기화 ==='
            source /opt/poky/oe-init-build-env /workspace/build
            
            echo
            echo '=== 빌드 시작 가능 ==='
            echo '다음 명령어를 사용하세요:'
            echo '  bitbake core-image-minimal    # 최소 이미지 빌드'
            echo '  yocto_quick_build            # 편의 함수 사용'
            echo '  runqemu qemux86-64           # 빌드된 이미지 실행'
            echo
            /bin/bash -l
        "
fi

echo
log_info "ARM64 안전 모드 종료"
log_info "워크스페이스는 yocto-workspace/에 보존됩니다." 