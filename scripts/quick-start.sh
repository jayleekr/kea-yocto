#!/bin/bash

# Yocto 5.0 LTS 강의 환경 빠른 시작 스크립트

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# 설정
DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"
WORKSPACE_DIR="yocto-workspace"

# 이미지 존재 여부 확인 함수
check_docker_image() {
    if ! docker image inspect $DOCKER_IMAGE >/dev/null 2>&1; then
        log_step "Docker 이미지를 찾을 수 없습니다. 먼저 이미지를 빌드합니다..."
        echo "다음 명령 중 하나를 선택하세요:"
        echo "1) 로컬 빌드: docker build -t $DOCKER_IMAGE ."
        echo "2) 멀티 아키텍처 빌드: ./scripts/build-multiarch.sh"
        echo "3) Docker Hub에서 다운로드: docker pull USERNAME/yocto-lecture:lecture"
        echo ""
        read -p "이미지를 지금 빌드하시겠습니까? [y/N]: " build_now
        if [[ "$build_now" == "y" ]] || [[ "$build_now" == "Y" ]]; then
            log_step "로컬 이미지 빌드 중... (시간이 오래 걸릴 수 있습니다)"
            docker build -t $DOCKER_IMAGE .
            if [ $? -ne 0 ]; then
                log_error "이미지 빌드 실패!"
                exit 1
            fi
        else
            echo "이미지 빌드를 취소했습니다. 먼저 이미지를 준비해주세요."
            exit 1
        fi
    fi
}

echo "🚀 KEA Yocto 빠른 시작"
echo "========================"

# 0단계: 플랫폼 설정
echo "0️⃣  플랫폼 설정 중..."
./scripts/setup-platform.sh

# 캐시 다운로드 먼저 실행
echo "1️⃣  캐시 준비 중..."
./scripts/prepare-cache.sh

# Docker 컨테이너 실행
echo "2️⃣  Docker 컨테이너 시작 중..."
docker compose run --rm yocto-lecture

echo "✅ 완료! 컨테이너에서 다음 명령어로 빠른 빌드를 시작하세요:"
echo "   yocto_init"
echo "   yocto_quick_build"

echo "======================================"
echo "Yocto 5.0 LTS 강의 환경 빠른 시작"
echo "======================================"
echo

# 이미지 존재 여부 확인
check_docker_image

# 워크스페이스 생성
log_step "워크스페이스 생성 중..."
mkdir -p ${WORKSPACE_DIR}/{workspace,downloads,sstate-cache}
log_info "워크스페이스가 생성되었습니다: ${WORKSPACE_DIR}"

# 아키텍처별 설정
ARCH=$(uname -m)
PLATFORM_FLAG=""

if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    if [ "$ARCH" = "arm64" ]; then
        log_info "Apple Silicon Mac에서 실행 중입니다."
    else
        log_info "ARM64 VM/시스템에서 실행 중입니다."
    fi
    
    echo "실행 방법을 선택하세요:"
    echo "1) ARM64 네이티브 (권장, 빠름)"
    echo "2) x86_64 에뮬레이션 (강의 환경 일치, 느림)"
    read -p "선택 [1/2]: " choice
    
    if [ "$choice" = "2" ]; then
        log_info "x86_64 에뮬레이션 모드로 실행합니다."
        PLATFORM_FLAG="--platform linux/amd64"
        BB_THREADS="4"
        PARALLEL_MAKE="-j 4"
        
        # QEMU 에뮬레이션 설정
        log_step "QEMU 에뮬레이션 설정 중..."
        
        # Docker Desktop의 QEMU 지원 확인
        if docker version | grep -q "Docker Desktop"; then
            log_info "Docker Desktop 환경: 내장 QEMU 지원 사용"
        else
            # 더 안전한 QEMU 설정 방법
            log_info "시스템 QEMU binfmt 설정 확인 중..."
            
            # binfmt_misc 지원 확인
            if [ ! -f /proc/sys/fs/binfmt_misc/status ]; then
                log_error "binfmt_misc가 지원되지 않습니다. ARM64 네이티브 모드를 사용해주세요."
                echo "다시 선택해주세요..."
                choice="1"
            else
                # QEMU 설정 시도
                if ! docker run --rm --privileged multiarch/qemu-user-static:register --reset 2>/dev/null; then
                    log_error "QEMU 설정 실패. ARM64 네이티브 모드로 전환합니다."
                    choice="1"
                fi
            fi
        fi
        
        # 실패시 ARM64 네이티브로 폴백
        if [ "$choice" != "2" ]; then
            log_info "ARM64 네이티브 모드로 변경합니다."
            PLATFORM_FLAG="--platform linux/arm64"
            BB_THREADS="8"
            PARALLEL_MAKE="-j 8"
        fi
        
        # x86_64 이미지 다운로드 (choice가 여전히 2인 경우만)
        if [ "$choice" = "2" ]; then
            log_step "x86_64 이미지 다운로드 중..."
            
            # Docker buildx 사용해서 더 안전하게 pull
            if docker buildx version >/dev/null 2>&1; then
                docker buildx imagetools inspect $DOCKER_IMAGE >/dev/null 2>&1 || {
                    log_error "x86_64 이미지를 찾을 수 없습니다. ARM64 네이티브 모드로 전환합니다."
                    choice="1"
                    PLATFORM_FLAG="--platform linux/arm64"
                    BB_THREADS="8"
                    PARALLEL_MAKE="-j 8"
                }
            fi
            
            if [ "$choice" = "2" ]; then
                docker pull --platform linux/amd64 $DOCKER_IMAGE 2>/dev/null || {
                    log_error "x86_64 이미지 다운로드 실패. ARM64 네이티브로 전환합니다."
                    choice="1"
                    PLATFORM_FLAG="--platform linux/arm64"
                    BB_THREADS="8"
                    PARALLEL_MAKE="-j 8"
                }
            fi
        fi
    else
        log_info "ARM64 네이티브 모드로 실행합니다."
        PLATFORM_FLAG="--platform linux/arm64"
        BB_THREADS="8"
        PARALLEL_MAKE="-j 8"
    fi
    
    # ARM64 이미지 다운로드 (네이티브 모드인 경우)
    if [ "$choice" != "2" ]; then
        log_step "ARM64 이미지 다운로드 중..."
        docker pull --platform linux/arm64 $DOCKER_IMAGE 2>/dev/null || {
            log_info "ARM64 이미지가 없습니다. 멀티아키텍처 이미지를 시도합니다."
            docker pull $DOCKER_IMAGE
        }
    fi
else
    log_info "x86_64 네이티브 환경에서 실행합니다."
    PLATFORM_FLAG="--platform linux/amd64"
    BB_THREADS="8"
    PARALLEL_MAKE="-j 8"
    
    # x86_64 환경에서 멀티플랫폼 Docker 지원 확인
    log_step "Docker 멀티플랫폼 지원 확인 중..."
    if ! docker buildx version >/dev/null 2>&1; then
        log_error "Docker buildx가 설치되지 않았습니다."
        echo "다음 명령으로 Docker를 업데이트하세요:"
        echo "sudo apt update && sudo apt install docker-ce docker-ce-cli containerd.io"
        exit 1
    fi
fi

# 컨테이너 실행
log_step "Yocto 컨테이너 시작 중..."

cd ${WORKSPACE_DIR}

# 기존 컨테이너 정리
docker rm -f yocto-lecture 2>/dev/null || true

docker run -it --privileged \
    ${PLATFORM_FLAG} \
    -v $(pwd)/workspace:/workspace \
    -v $(pwd)/downloads:/opt/yocto/downloads \
    -v $(pwd)/sstate-cache:/opt/yocto/sstate-cache \
    -e BB_NUMBER_THREADS=${BB_THREADS} \
    -e PARALLEL_MAKE="${PARALLEL_MAKE}" \
    -e MACHINE=qemux86-64 \
    -e TMPDIR=/tmp/yocto-build \
    --name yocto-lecture \
    ${DOCKER_IMAGE} \
    /bin/bash -c "
        echo '=== Yocto 5.0 LTS 강의 환경 시작 ==='
        echo '아키텍처: \$(uname -m)'
        echo 'BitBake 버전: \$(bitbake --version 2>/dev/null || echo 'BitBake not in PATH')'
        echo
        echo '=== 빌드 환경 초기화 ==='
        source /opt/poky/oe-init-build-env /workspace/build
        
        # 커스텀 설정 파일 복사
        if [ -f /opt/configs/local.conf.template ]; then
            echo '커스텀 local.conf 적용 중...'
            cp /opt/configs/local.conf.template conf/local.conf
        fi
        
        if [ -f /opt/configs/bblayers.conf.template ]; then
            echo '커스텀 bblayers.conf 적용 중...'
            cp /opt/configs/bblayers.conf.template conf/bblayers.conf
        fi
        
        echo
        echo '=== 설정 확인 ==='
        echo 'MACHINE: qemux86-64'
        echo 'TMPDIR: \$(grep \"^TMPDIR\" conf/local.conf || echo \"기본값 사용\")'
        echo 'DL_DIR: /opt/yocto/downloads'
        echo 'SSTATE_DIR: /opt/yocto/sstate-cache'
        echo
        echo '=== 빌드 준비 완료 ==='
        echo '다음 명령어로 이미지를 빌드할 수 있습니다:'
        echo '  bitbake core-image-minimal'
        echo '  bitbake core-image-full-cmdline'
        echo
        echo '=== 편의 명령어 ==='
        echo '  yocto_init           - 빌드 환경 재초기화'
        echo '  yocto_quick_build    - core-image-minimal 빌드'
        echo '  yocto_run_qemu       - QEMU로 이미지 실행'
        echo
        /bin/bash -l
    "

echo
log_info "Yocto 강의 환경이 종료되었습니다."
log_info "워크스페이스는 ${WORKSPACE_DIR}에 보존됩니다." 