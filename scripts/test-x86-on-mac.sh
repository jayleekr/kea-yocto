#!/bin/bash

# Mac에서 x86_64 Yocto 이미지 테스트 스크립트
# Apple Silicon Mac에서 x86_64 이미지를 에뮬레이션으로 실행하여 테스트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 로깅 함수
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 설정 변수
DOCKER_IMAGE_NAME="yocto-lecture"
DOCKER_USERNAME=${DOCKER_USERNAME:-""}
CONTAINER_NAME="yocto-x86-test"
WORKSPACE_DIR="./test-workspace"

# 이미지 이름 설정
if [ -n "$DOCKER_USERNAME" ]; then
    FULL_IMAGE_NAME="${DOCKER_USERNAME}/${DOCKER_IMAGE_NAME}:lecture"
else
    FULL_IMAGE_NAME="${DOCKER_IMAGE_NAME}:5.0-lts"
fi

# 함수: 워크스페이스 준비
prepare_workspace() {
    log_step "테스트 워크스페이스 준비 중..."
    
    mkdir -p ${WORKSPACE_DIR}/{workspace,downloads,sstate-cache}
    
    log_info "워크스페이스가 준비되었습니다: ${WORKSPACE_DIR}"
}

# 함수: x86_64 이미지 강제 실행
run_x86_container() {
    log_step "x86_64 이미지를 에뮬레이션으로 실행 중..."
    
    # 기존 컨테이너 정리
    docker rm -f ${CONTAINER_NAME} 2>/dev/null || true
    
    # Mac에서 --platform linux/amd64 옵션으로 x86_64 이미지 강제 실행
    docker run -it --rm \
        --platform linux/amd64 \
        --privileged \
        --name ${CONTAINER_NAME} \
        -v $(pwd)/${WORKSPACE_DIR}/workspace:/workspace \
        -v $(pwd)/${WORKSPACE_DIR}/downloads:/opt/yocto/downloads \
        -v $(pwd)/${WORKSPACE_DIR}/sstate-cache:/opt/yocto/sstate-cache \
        -e MACHINE=qemux86-64 \
        -e BB_NUMBER_THREADS=4 \
        -e PARALLEL_MAKE="-j 4" \
        ${FULL_IMAGE_NAME} \
        /bin/bash -c "
            echo '=== Yocto x86_64 테스트 환경 ==='
            echo '현재 아키텍처: $(uname -m)'
            echo '컨테이너 플랫폼: $(uname -a)'
            echo
            echo 'BitBake 버전:'
            bitbake --version
            echo
            echo 'Yocto 환경 초기화 중...'
            source /opt/poky/oe-init-build-env /workspace/build
            echo
            echo '기본 설정 확인:'
            echo 'MACHINE = qemux86-64' >> conf/local.conf
            echo 'BB_NUMBER_THREADS = \"4\"' >> conf/local.conf
            echo 'PARALLEL_MAKE = \"-j 4\"' >> conf/local.conf
            echo 'DL_DIR = \"/opt/yocto/downloads\"' >> conf/local.conf
            echo 'SSTATE_DIR = \"/opt/yocto/sstate-cache\"' >> conf/local.conf
            echo
            echo '설정 파일 내용:'
            cat conf/local.conf | grep -E '(MACHINE|BB_NUMBER_THREADS|PARALLEL_MAKE|DL_DIR|SSTATE_DIR)'
            echo
            echo '사용 가능한 레이어:'
            bitbake-layers show-layers
            echo
            echo '=== 테스트 완료 ==='
            echo '대화형 쉘을 시작합니다. exit로 종료하세요.'
            /bin/bash -l
        "
}

# 함수: 빠른 빌드 테스트
quick_build_test() {
    log_step "빠른 빌드 테스트 실행 중..."
    
    docker run --rm \
        --platform linux/amd64 \
        --privileged \
        --name ${CONTAINER_NAME}-quick \
        -v $(pwd)/${WORKSPACE_DIR}/workspace:/workspace \
        -v $(pwd)/${WORKSPACE_DIR}/downloads:/opt/yocto/downloads \
        -v $(pwd)/${WORKSPACE_DIR}/sstate-cache:/opt/yocto/sstate-cache \
        -e MACHINE=qemux86-64 \
        ${FULL_IMAGE_NAME} \
        /bin/bash -c "
            source /opt/poky/oe-init-build-env /workspace/quick-test
            echo 'MACHINE = \"qemux86-64\"' >> conf/local.conf
            echo 'DL_DIR = \"/opt/yocto/downloads\"' >> conf/local.conf
            echo 'SSTATE_DIR = \"/opt/yocto/sstate-cache\"' >> conf/local.conf
            echo
            echo '간단한 레시피 파싱 테스트...'
            bitbake -p
            echo
            echo '빌드 환경 테스트 완료!'
        "
    
    log_info "빠른 빌드 테스트가 완료되었습니다."
}

# 함수: 성능 벤치마크
performance_benchmark() {
    log_step "x86_64 에뮬레이션 성능 테스트 중..."
    
    log_warn "Apple Silicon에서 x86_64 에뮬레이션은 네이티브 실행 대비 2-3배 느릴 수 있습니다."
    
    docker run --rm \
        --platform linux/amd64 \
        --name ${CONTAINER_NAME}-perf \
        ${FULL_IMAGE_NAME} \
        /bin/bash -c "
            echo '=== 성능 벤치마크 ==='
            echo '아키텍처: $(uname -m)'
            echo 'CPU 정보:'
            grep -m 1 'model name' /proc/cpuinfo || echo 'CPU 정보를 가져올 수 없음'
            echo
            echo 'CPU 코어 수: $(nproc)'
            echo '메모리 정보:'
            free -h
            echo
            echo 'BitBake 파싱 성능 테스트...'
            time (source /opt/poky/oe-init-build-env /tmp/perf-test && bitbake -p)
        "
    
    log_info "성능 벤치마크가 완료되었습니다."
}

# 함수: 이미지 정보 확인
check_image_info() {
    log_step "이미지 정보 확인 중..."
    
    echo "=== 이미지 정보 ==="
    docker image inspect ${FULL_IMAGE_NAME} --format '{{.Architecture}}' 2>/dev/null || {
        log_error "이미지를 찾을 수 없습니다: ${FULL_IMAGE_NAME}"
        echo "사용 가능한 이미지:"
        docker images | grep yocto
        exit 1
    }
    
    echo "이미지 아키텍처: $(docker image inspect ${FULL_IMAGE_NAME} --format '{{.Architecture}}')"
    echo "이미지 크기: $(docker image inspect ${FULL_IMAGE_NAME} --format '{{.Size}}' | numfmt --to=iec)"
    echo "생성 날짜: $(docker image inspect ${FULL_IMAGE_NAME} --format '{{.Created}}')"
    echo
}

# 함수: 정리
cleanup() {
    log_step "정리 중..."
    
    docker rm -f ${CONTAINER_NAME} ${CONTAINER_NAME}-quick ${CONTAINER_NAME}-perf 2>/dev/null || true
    
    read -p "테스트 워크스페이스(${WORKSPACE_DIR})를 삭제하시겠습니까? (y/N): " delete_workspace
    if [[ "$delete_workspace" == "y" ]] || [[ "$delete_workspace" == "Y" ]]; then
        rm -rf ${WORKSPACE_DIR}
        log_info "워크스페이스가 삭제되었습니다."
    fi
}

# 함수: 사용법 출력
show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -i, --interactive    대화형 테스트 실행"
    echo "  -q, --quick         빠른 빌드 테스트만 실행"
    echo "  -p, --performance   성능 벤치마크 실행"
    echo "  -c, --cleanup       이전 테스트 정리"
    echo "  -h, --help          도움말 출력"
    echo ""
    echo "환경변수:"
    echo "  DOCKER_USERNAME     Docker Hub 사용자명"
    echo ""
    echo "예시:"
    echo "  $0 -i                    # 대화형 테스트"
    echo "  $0 -q                    # 빠른 테스트"
    echo "  DOCKER_USERNAME=user $0  # 특정 사용자 이미지 테스트"
}

# 메인 함수
main() {
    echo "======================================"
    echo "Mac에서 x86_64 Yocto 이미지 테스트"
    echo "======================================"
    echo ""
    
    # 옵션 파싱
    case "${1:-""}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -c|--cleanup)
            cleanup
            exit 0
            ;;
        -q|--quick)
            check_image_info
            prepare_workspace
            quick_build_test
            ;;
        -p|--performance)
            check_image_info
            performance_benchmark
            ;;
        -i|--interactive|"")
            check_image_info
            prepare_workspace
            run_x86_container
            ;;
        *)
            log_error "알 수 없는 옵션: $1"
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    log_info "테스트가 완료되었습니다."
    
    # 정리 옵션 제공
    if [[ "$1" != "-c" ]] && [[ "$1" != "--cleanup" ]]; then
        echo ""
        echo "정리하려면 다음 명령을 실행하세요:"
        echo "  $0 --cleanup"
    fi
}

# 사전 검사
if ! command -v docker &> /dev/null; then
    log_error "Docker가 설치되어 있지 않습니다."
    exit 1
fi

if ! docker info &> /dev/null; then
    log_error "Docker가 실행되고 있지 않습니다."
    exit 1
fi

# Apple Silicon 확인
if [[ "$(uname -m)" != "arm64" ]]; then
    log_warn "이 스크립트는 Apple Silicon Mac용으로 설계되었습니다."
    log_warn "현재 아키텍처: $(uname -m)"
fi

# 스크립트 실행
main "$@" 