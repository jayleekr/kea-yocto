#!/bin/bash

# VM용 Yocto 5.0 LTS 강의 환경 시작 스크립트
# x86_64 Ubuntu VM에서 확실하게 작동하도록 최적화

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "============================================"
echo "🚀 VM용 Yocto 5.0 LTS 강의 환경 시작"
echo "============================================"
echo

# 시스템 정보 확인
ARCH=$(uname -m)
log_info "시스템 아키텍처: $ARCH"

if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
    log_error "이 스크립트는 x86_64/ARM64 VM 전용입니다."
    echo "현재 시스템: $ARCH"
    echo "다른 스크립트를 사용하세요:"
    echo "  - 범용: ./scripts/quick-start.sh"
    exit 1
fi

# Docker 설치 확인
log_step "Docker 설치 확인 중..."
if ! command -v docker &> /dev/null; then
    log_error "Docker가 설치되지 않았습니다!"
    echo ""
    echo "Ubuntu에서 Docker 설치 방법:"
    echo "1. sudo apt update"
    echo "2. sudo apt install docker.io"
    echo "3. sudo systemctl start docker"
    echo "4. sudo systemctl enable docker"
    echo "5. sudo usermod -aG docker \$USER"
    echo "6. 로그아웃 후 다시 로그인"
    exit 1
fi

# Docker 서비스 상태 확인
if ! systemctl is-active --quiet docker; then
    log_warning "Docker 서비스가 실행되지 않았습니다."
    log_step "Docker 서비스 시작 중..."
    sudo systemctl start docker
    sleep 2
fi

# Docker 권한 확인
if ! docker ps >/dev/null 2>&1; then
    log_error "Docker 권한이 없습니다!"
    echo ""
    echo "다음 명령으로 권한을 설정하세요:"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    echo ""
    echo "또는 sudo로 실행하세요:"
    echo "  sudo ./scripts/vm-start.sh"
    exit 1
fi

# 워크스페이스 생성
WORKSPACE_DIR="yocto-workspace"
log_step "워크스페이스 생성 중..."
mkdir -p ${WORKSPACE_DIR}/{workspace,downloads,sstate-cache}
log_info "워크스페이스: ${WORKSPACE_DIR}"

# 기존 컨테이너 정리
log_step "기존 컨테이너 정리 중..."
docker rm -f yocto-lecture-vm 2>/dev/null || true

# Docker 이미지 다운로드 (아키텍처별 처리)
DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"

# 아키텍처별 플랫폼 설정
if [ "$ARCH" = "x86_64" ]; then
    TARGET_PLATFORM="linux/amd64"
    TARGET_ARCH="amd64"
    log_step "x86_64 Docker 이미지 다운로드 중..."
else
    # aarch64 (ARM64) VM의 경우
    echo "ARM64 VM에서 실행 중입니다. 실행 방법을 선택하세요:"
    echo "1) ARM64 네이티브 (권장, 빠름)"
    echo "2) x86_64 에뮬레이션 (강의 환경 일치, 느림)"
    read -p "선택 [1/2]: " vm_choice
    
    if [ "$vm_choice" = "2" ]; then
        TARGET_PLATFORM="linux/amd64"
        TARGET_ARCH="amd64"
        log_info "x86_64 에뮬레이션 모드로 실행합니다."
        
        # QEMU 에뮬레이션 설정
        log_step "QEMU 에뮬레이션 설정 중..."
        if ! command -v qemu-user-static >/dev/null 2>&1; then
            log_step "QEMU 설치 중..."
            sudo apt-get update && sudo apt-get install -y qemu-user-static binfmt-support
        fi
        docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    else
        TARGET_PLATFORM="linux/arm64"
        TARGET_ARCH="arm64"
        log_info "ARM64 네이티브 모드로 실행합니다."
    fi
fi

log_step "${TARGET_PLATFORM} Docker 이미지 다운로드 중..."

# 이미지 다운로드
if ! docker image inspect $DOCKER_IMAGE >/dev/null 2>&1; then
    log_info "이미지를 다운로드합니다..."
    docker pull --platform $TARGET_PLATFORM $DOCKER_IMAGE
else
    # 이미지 아키텍처 확인
    CURRENT_ARCH=$(docker image inspect $DOCKER_IMAGE 2>/dev/null | grep -o '"Architecture":"[^"]*"' | cut -d'"' -f4 | head -1)
    if [ "$CURRENT_ARCH" != "$TARGET_ARCH" ]; then
        log_warning "다른 아키텍처 이미지가 감지되어 올바른 버전을 다운로드합니다..."
        log_info "현재: $CURRENT_ARCH, 필요: $TARGET_ARCH"
        docker rmi $DOCKER_IMAGE 2>/dev/null || true
        docker pull --platform $TARGET_PLATFORM $DOCKER_IMAGE
    fi
fi

# 최종 이미지 아키텍처 확인
log_step "이미지 아키텍처 최종 확인..."
FINAL_ARCH=$(docker image inspect $DOCKER_IMAGE | grep -o '"Architecture":"[^"]*"' | cut -d'"' -f4 | head -1)
log_info "이미지 아키텍처: $FINAL_ARCH"

# VM 환경에 최적화된 설정
CPU_CORES=$(nproc)
BB_THREADS=$((CPU_CORES > 4 ? 4 : CPU_CORES))
PARALLEL_MAKE="-j $BB_THREADS"

log_info "CPU 코어: $CPU_CORES"
log_info "BitBake 스레드: $BB_THREADS"
log_info "병렬 빌드: $PARALLEL_MAKE"

cd ${WORKSPACE_DIR}

log_step "VM용 Yocto 컨테이너 시작 중..."
echo "========================================"

# VM 최적화된 컨테이너 실행
docker run -it --rm \
    --platform ${TARGET_PLATFORM} \
    --privileged \
    -v $(pwd)/workspace:/workspace \
    -v $(pwd)/downloads:/opt/yocto/downloads \
    -v $(pwd)/sstate-cache:/opt/yocto/sstate-cache \
    -e BB_NUMBER_THREADS=${BB_THREADS} \
    -e PARALLEL_MAKE="${PARALLEL_MAKE}" \
    -e MACHINE=qemux86-64 \
    -e TMPDIR=/tmp/yocto-build \
    -e BB_ENV_PASSTHROUGH_ADDITIONS=TMPDIR \
    --name yocto-lecture-vm \
    ${DOCKER_IMAGE} \
    /bin/bash -c '
        echo "🎯 VM용 Yocto 5.0 LTS 환경 시작!"
        echo "================================="
        echo "아키텍처: $(uname -m)"
        echo "OS: $(cat /etc/os-release | head -1)"
        echo "CPU 코어: '${BB_THREADS}'"
        echo ""
        
        echo "=== Yocto 환경 초기화 ==="
        source /opt/poky/oe-init-build-env /workspace/build
        
        echo ""
        echo "=== 환경 확인 ==="
        echo "BitBake 버전: $(bitbake --version)"
        echo "MACHINE: qemux86-64"
        echo "TMPDIR: /tmp/yocto-build"
        echo "BB_NUMBER_THREADS: '${BB_THREADS}'"
        echo "PARALLEL_MAKE: '${PARALLEL_MAKE}'"
        echo ""
        
        echo "=== 빌드 명령어 예시 ==="
        echo "  bitbake core-image-minimal    # 최소 시스템"
        echo "  bitbake core-image-full-cmdline  # 명령행 도구 포함"
        echo "  runqemu qemux86-64           # QEMU 실행"
        echo ""
        
        echo "=== 빠른 테스트 ==="
        echo "  bitbake -n core-image-minimal  # 빌드 계획만 확인"
        echo "  bitbake hello-world            # 간단한 테스트"
        echo ""
        
        echo "🚀 준비 완료! 빌드를 시작하세요."
        echo ""
        
        /bin/bash -l
    '

echo
log_info "VM용 Yocto 환경이 종료되었습니다."
log_info "워크스페이스는 ${WORKSPACE_DIR}에 보존됩니다." 