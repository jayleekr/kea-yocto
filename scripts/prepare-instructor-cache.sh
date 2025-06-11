#!/bin/bash

# 강화된 오류 처리
set -euo pipefail

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

# 옵션 파싱
DRY_RUN=false
VERBOSE=false

show_usage() {
    echo "👨‍🏫 강사용 캐시 준비 스크립트 v2.0"
    echo "====================================="
    echo ""
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --dry-run     실제 빌드 없이 시스템 검사만 수행"
    echo "  --check       시스템 요구사항과 설정 확인"
    echo "  --verbose     상세한 진단 정보 표시"
    echo "  --help        이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0 --dry-run    # 빌드 준비 상태 확인"
    echo "  $0 --check     # 시스템 요구사항 확인"
    echo "  $0             # 실제 캐시 빌드 실행"
}

# 인자 처리
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|--check)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            log_error "알 수 없는 옵션: $1"
            show_usage
            exit 1
            ;;
    esac
done

# 정리 함수
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        if [ "$DRY_RUN" = true ]; then
            log_error "시스템 검사에서 문제가 발견되었습니다."
            log_error "위의 오류를 해결한 후 다시 시도하세요."
        else
            log_error "스크립트가 오류로 인해 중단되었습니다."
            log_error "현재 상태를 확인하고 문제를 해결한 후 다시 시도하세요."
        fi
    fi
    exit $exit_code
}

# 신호 처리
trap cleanup EXIT INT TERM

if [ "$DRY_RUN" = true ]; then
    echo "🧪 KEA Yocto 캐시 준비 시스템 검사"
    echo "==================================="
    echo "📋 실제 빌드 없이 모든 조건을 확인합니다..."
else
    echo "👨‍🏫 강사용 캐시 준비 스크립트 v2.0"
    echo "====================================="
fi

WORKSPACE_DIR="./yocto-workspace"
BUILD_DIR="$WORKSPACE_DIR/instructor-build"
MIN_DISK_SPACE_GB=50
MIN_MEMORY_GB=8

# 예상 빌드 크기 정보
BUILD_ESTIMATE_CORE_MINIMAL="15GB disk, 45분"
BUILD_ESTIMATE_CORE_BASE="25GB disk, 90분"
BUILD_ESTIMATE_TOOLCHAIN="5GB disk, 30분"
BUILD_ESTIMATE_TOTAL="45GB disk, 3-4시간"

# 1단계: 시스템 요구사항 확인
log_step "1단계: 시스템 요구사항 확인 중..."

# 디스크 공간 확인
available_space=$(df . | tail -1 | awk '{print $4}')
available_space_gb=$((available_space / 1024 / 1024))

if [ "$VERBOSE" = true ]; then
    log_info "사용 가능한 디스크 공간: ${available_space_gb}GB"
    log_info "필요한 최소 공간: ${MIN_DISK_SPACE_GB}GB"
fi

if [ $available_space_gb -lt $MIN_DISK_SPACE_GB ]; then
    log_error "디스크 공간 부족: ${available_space_gb}GB 사용 가능 (최소 ${MIN_DISK_SPACE_GB}GB 필요)"
    log_error "예상 빌드 크기: ${BUILD_ESTIMATE_TOTAL}"
    
    if [ "$DRY_RUN" = true ]; then
        log_error "▶ 해결 방법:"
        log_error "  1. 불필요한 파일 삭제"
        log_error "  2. Docker 시스템 정리: docker system prune -a"
        log_error "  3. 더 큰 디스크로 이동"
        exit 1
    else
        exit 1
    fi
fi

log_info "디스크 공간 확인: ${available_space_gb}GB 사용 가능 ✓"

# 메모리 확인
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    total_memory_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    total_memory_gb=$((total_memory_kb / 1024 / 1024))
elif [[ "$OSTYPE" == "darwin"* ]]; then
    total_memory_bytes=$(sysctl -n hw.memsize)
    total_memory_gb=$((total_memory_bytes / 1024 / 1024 / 1024))
else
    total_memory_gb=8  # 기본값
    log_warn "메모리 크기를 자동으로 감지할 수 없습니다. 기본값 ${total_memory_gb}GB 사용"
fi

if [ "$VERBOSE" = true ]; then
    log_info "시스템 메모리: ${total_memory_gb}GB"
    log_info "권장 최소 메모리: ${MIN_MEMORY_GB}GB"
fi

if [ $total_memory_gb -lt $MIN_MEMORY_GB ]; then
    log_warn "메모리 부족: ${total_memory_gb}GB (권장: ${MIN_MEMORY_GB}GB 이상)"
    log_warn "빌드 병렬성을 제한합니다."
    BB_NUMBER_THREADS=2
    PARALLEL_MAKE="-j 2"
    
    if [ "$DRY_RUN" = true ]; then
        log_warn "▶ 성능 최적화 방법:"
        log_warn "  1. 메모리 추가 설치"
        log_warn "  2. 스왑 공간 늘리기"
        log_warn "  3. 다른 프로그램 종료"
    fi
else
    log_info "메모리 확인: ${total_memory_gb}GB ✓"
    BB_NUMBER_THREADS=4
    PARALLEL_MAKE="-j 4"
fi

if [ "$DRY_RUN" = true ]; then
    log_info "빌드 설정: BB_NUMBER_THREADS=$BB_NUMBER_THREADS, PARALLEL_MAKE=\"$PARALLEL_MAKE\""
fi

# 2단계: 네트워크 연결 확인
log_step "2단계: 네트워크 연결 확인 중..."

check_connectivity() {
    local url=$1
    local name=$2
    local timeout=${3:-10}
    
    if [ "$VERBOSE" = true ]; then
        log_info "연결 테스트: $url (타임아웃: ${timeout}초)"
    fi
    
    if curl -s --connect-timeout $timeout --max-time $((timeout * 2)) "$url" >/dev/null 2>&1; then
        log_info "$name 연결 확인 ✓"
        return 0
    else
        log_error "$name 연결 실패 ✗"
        if [ "$DRY_RUN" = true ]; then
            log_error "▶ $url 에 접근할 수 없습니다"
        fi
        return 1
    fi
}

# 주요 서버 연결 확인
connectivity_ok=true
check_connectivity "https://git.yoctoproject.org" "Yocto Git 서버" 15 || connectivity_ok=false
check_connectivity "https://downloads.yoctoproject.org" "Yocto 다운로드 서버" 10 || connectivity_ok=false
check_connectivity "https://github.com" "GitHub" 10 || connectivity_ok=false

if [ "$connectivity_ok" = false ]; then
    log_error "네트워크 연결에 문제가 있습니다."
    if [ "$DRY_RUN" = true ]; then
        log_error "▶ 해결 방법:"
        log_error "  1. 인터넷 연결 상태 확인"
        log_error "  2. 방화벽 설정 확인"
        log_error "  3. 프록시 설정 확인"
        log_error "  4. DNS 설정 확인"
        exit 1
    else
        exit 1
    fi
fi

# 3단계: Docker 환경 확인
log_step "3단계: Docker 환경 확인 중..."

if ! docker info >/dev/null 2>&1; then
    log_error "Docker가 실행되지 않습니다."
    if [ "$DRY_RUN" = true ]; then
        log_error "▶ 해결 방법:"
        log_error "  1. Docker Desktop 시작"
        log_error "  2. Docker 서비스 시작: sudo systemctl start docker"
        log_error "  3. Docker 설치 확인"
        exit 1
    else
        exit 1
    fi
fi

# Docker 시스템 정보
if [ "$VERBOSE" = true ]; then
    docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    log_info "Docker 버전: $docker_version"
    
    docker_disk=$(docker system df --format "table {{.Type}}\t{{.Size}}" 2>/dev/null | grep "Local Volumes" | awk '{print $3}' || echo "알 수 없음")
    log_info "Docker 디스크 사용량: $docker_disk"
fi

# ARM64용 이미지 확인
ARM64_IMAGE="yocto-lecture:arm64-fast"
ARCH=$(uname -m)

if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    log_info "ARM64 환경 감지됨"
    
    if docker image inspect "$ARM64_IMAGE" >/dev/null 2>&1; then
        log_info "ARM64 전용 이미지 발견: $ARM64_IMAGE ✓"
        DOCKER_IMAGE="$ARM64_IMAGE"
    else
        log_warn "ARM64 전용 이미지가 없습니다"
        if [ "$DRY_RUN" = true ]; then
            log_warn "▶ 권장 사항:"
            log_warn "  1. ARM64 이미지 빌드: docker build -f Dockerfile.arm64 -t $ARM64_IMAGE ."
            log_warn "  2. ARM64 안전 모드 사용: ./scripts/vm-arm64-safe.sh"
        fi
        DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"
    fi
else
    log_info "x86_64 환경 감지됨"
    DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"
fi

# 기본 이미지 확인
if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
    log_warn "Docker 이미지가 로컬에 없습니다: $DOCKER_IMAGE"
    if [ "$DRY_RUN" = true ]; then
        log_warn "▶ 이미지 다운로드가 필요합니다 (약 2-3GB)"
        log_warn "  docker pull $DOCKER_IMAGE"
    else
        log_info "이미지 다운로드를 시도합니다..."
        if ! docker pull "$DOCKER_IMAGE"; then
            log_error "이미지 다운로드에 실패했습니다"
            exit 1
        fi
    fi
else
    log_info "Docker 이미지 확인: $DOCKER_IMAGE ✓"
fi

# 4단계: 빌드 계획 표시
log_step "4단계: 빌드 계획 확인 중..."

if [ "$DRY_RUN" = true ]; then
    echo ""
    log_info "📋 빌드 계획:"
    echo "   1. core-image-minimal: ${BUILD_ESTIMATE_CORE_MINIMAL}"
    echo "   2. core-image-base: ${BUILD_ESTIMATE_CORE_BASE}"
    echo "   3. meta-toolchain: ${BUILD_ESTIMATE_TOOLCHAIN}"
    echo ""
    log_info "📊 총 예상 소요:"
    echo "   - 디스크 사용량: 45GB (압축 후 5-10GB)"
    echo "   - 예상 시간: 3-4시간 (시스템 성능에 따라)"
    echo "   - 네트워크 다운로드: 2-5GB"
    echo ""
    log_info "🔧 최적화 설정:"
    echo "   - BB_NUMBER_THREADS: $BB_NUMBER_THREADS"
    echo "   - PARALLEL_MAKE: $PARALLEL_MAKE"
    echo "   - Docker 이미지: $DOCKER_IMAGE"
    echo ""
fi

# 5단계: 작업공간 확인
log_step "5단계: 작업공간 확인 중..."

if [ ! -d "$WORKSPACE_DIR" ]; then
    log_info "작업공간 디렉토리가 없습니다. 생성합니다: $WORKSPACE_DIR"
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$WORKSPACE_DIR"/{downloads,sstate-cache,mirror}
    fi
else
    log_info "작업공간 디렉토리 확인: $WORKSPACE_DIR ✓"
    
    if [ "$VERBOSE" = true ]; then
        if [ -d "$WORKSPACE_DIR/downloads" ]; then
            downloads_size=$(du -sh "$WORKSPACE_DIR/downloads" 2>/dev/null | cut -f1 || echo "0B")
            log_info "기존 downloads 캐시: $downloads_size"
        fi
        
        if [ -d "$WORKSPACE_DIR/sstate-cache" ]; then
            sstate_size=$(du -sh "$WORKSPACE_DIR/sstate-cache" 2>/dev/null | cut -f1 || echo "0B")
            log_info "기존 sstate 캐시: $sstate_size"
        fi
    fi
fi

# Dry-run 모드에서는 여기서 종료
if [ "$DRY_RUN" = true ]; then
    echo ""
    log_info "🎉 시스템 검사 완료!"
    echo ""
    log_info "✅ 모든 요구사항이 충족되었습니다:"
    echo "   ✓ 충분한 디스크 공간 (${available_space_gb}GB 사용 가능)"
    echo "   ✓ 적절한 메모리 설정 (${total_memory_gb}GB)"
    echo "   ✓ 네트워크 연결 정상"
    echo "   ✓ Docker 환경 준비됨"
    echo "   ✓ 빌드 이미지 준비됨"
    echo ""
    log_info "🚀 실제 빌드를 시작하려면:"
    echo "   $0"
    echo ""
    log_info "💡 예상 결과:"
    echo "   - downloads-cache.tar.gz (2-5GB)"
    echo "   - sstate-cache.tar.gz (5-10GB)"
    echo "   - 총 소요 시간: 3-4시간"
    exit 0
fi

# 실제 빌드 실행 (기존 코드)
log_step "6단계: 빌드 실행 중..."

log_warn "강의용 이미지들을 빌드하여 캐시를 생성합니다."
log_warn "이 과정은 시스템 사양에 따라 2-6시간이 소요될 수 있습니다."
log_warn "빌드 설정: BB_NUMBER_THREADS=$BB_NUMBER_THREADS, PARALLEL_MAKE=$PARALLEL_MAKE"

# 빌드 함수
build_target() {
    local target=$1
    local step_num=$2
    
    log_info "[$step_num] $target 빌드 시작..."
    
    if docker run --rm \
        -v "$WORKSPACE_DIR/downloads:/opt/yocto/downloads" \
        -v "$WORKSPACE_DIR/sstate-cache:/opt/yocto/sstate-cache" \
        -e BB_NUMBER_THREADS="$BB_NUMBER_THREADS" \
        -e PARALLEL_MAKE="$PARALLEL_MAKE" \
        -e MACHINE=qemux86-64 \
        "$DOCKER_IMAGE" \
        /bin/bash -c "
            set -euo pipefail
            source /opt/poky/oe-init-build-env /tmp/cache-build
            
            # 빌드 시작 시간 기록
            start_time=\$(date +%s)
            echo '🚀 $target 빌드 시작: \$(date)'
            
            # 빌드 실행
            if ! bitbake $target; then
                echo '❌ $target 빌드 실패!'
                exit 1
            fi
            
            # 빌드 완료 시간 계산
            end_time=\$(date +%s)
            duration=\$((end_time - start_time))
            echo '✅ $target 빌드 완료: \$(date) (소요시간: \${duration}초)'
        "; then
        log_info "[$step_num] $target 빌드 성공 ✓"
        return 0
    else
        log_error "[$step_num] $target 빌드 실패 ✗"
        return 1
    fi
}

# 순차적 빌드 실행
build_target "core-image-minimal" "6.1" || exit 1
sleep 5  # 메모리 정리 시간

build_target "core-image-base" "6.2" || exit 1
sleep 5  # 메모리 정리 시간

build_target "meta-toolchain" "6.3" || exit 1

log_info "모든 빌드 완료!"

# 7단계: 캐시 검증 및 압축
log_step "7단계: 캐시 검증 및 압축 중..."

cd "$WORKSPACE_DIR"

# Downloads 캐시 검증
if [ ! -d "downloads" ] || [ -z "$(ls -A downloads)" ]; then
    log_error "Downloads 캐시가 비어있거나 존재하지 않습니다."
    exit 1
fi

downloads_size=$(du -s downloads | cut -f1)
if [ "$downloads_size" -lt 1000000 ]; then  # 1GB 미만이면 문제
    log_warn "Downloads 캐시 크기가 예상보다 작습니다: $(du -h downloads | cut -f1)"
fi

# sstate 캐시 검증
if [ ! -d "sstate-cache" ] || [ -z "$(ls -A sstate-cache)" ]; then
    log_error "sstate 캐시가 비어있거나 존재하지 않습니다."
    exit 1
fi

sstate_size=$(du -s sstate-cache | cut -f1)
if [ "$sstate_size" -lt 5000000 ]; then  # 5GB 미만이면 문제
    log_warn "sstate 캐시 크기가 예상보다 작습니다: $(du -h sstate-cache | cut -f1)"
fi

# 압축 실행
log_info "Downloads 캐시 압축 중..."
if tar -czf downloads-cache.tar.gz downloads/; then
    downloads_compressed_size=$(du -h downloads-cache.tar.gz | cut -f1)
    log_info "downloads-cache.tar.gz 생성 완료: $downloads_compressed_size"
else
    log_error "Downloads 캐시 압축 실패"
    exit 1
fi

log_info "sstate 캐시 압축 중..."
if tar -czf sstate-cache.tar.gz sstate-cache/; then
    sstate_compressed_size=$(du -h sstate-cache.tar.gz | cut -f1)
    log_info "sstate-cache.tar.gz 생성 완료: $sstate_compressed_size"
else
    log_error "sstate 캐시 압축 실패"
    exit 1
fi

# 8단계: 최종 검증
log_step "8단계: 최종 검증 중..."

# 압축 파일 크기 확인
downloads_final_kb=$(du -k downloads-cache.tar.gz | cut -f1)
sstate_final_kb=$(du -k sstate-cache.tar.gz | cut -f1)

if [ "$downloads_final_kb" -lt 100000 ]; then  # 100MB 미만
    log_error "Downloads 캐시 파일이 너무 작습니다: ${downloads_compressed_size}"
    log_error "빌드가 제대로 완료되지 않았을 수 있습니다."
    exit 1
fi

if [ "$sstate_final_kb" -lt 500000 ]; then  # 500MB 미만
    log_error "sstate 캐시 파일이 너무 작습니다: ${sstate_compressed_size}"
    log_error "빌드가 제대로 완료되지 않았을 수 있습니다."
    exit 1
fi

# 성공 메시지
echo ""
log_info "🎉 강사용 캐시 준비 완료!"
echo "📁 생성된 파일:"
echo "   ✅ downloads-cache.tar.gz ($downloads_compressed_size)"
echo "   ✅ sstate-cache.tar.gz ($sstate_compressed_size)"
echo ""
echo "💡 다음 단계:"
echo "   1. 이 파일들을 GitHub Release 또는 파일 서버에 업로드"
echo "   2. prepare-cache.sh 스크립트의 URL 업데이트"
echo "   3. 학생들에게 새로운 캐시 URL 공지"
echo ""
log_info "캐시 준비가 성공적으로 완료되었습니다!" 