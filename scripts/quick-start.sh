#!/bin/bash

# Yocto 5.0 LTS 강의 환경 빠른 시작 스크립트

set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
    echo "🚀 KEA Yocto 빠른 시작 v2.0"
    echo "============================"
    echo ""
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --dry-run     실제 실행 없이 시스템 준비 상태만 확인"
    echo "  --check       모든 구성 요소와 설정 확인"
    echo "  --verbose     상세한 진단 정보 표시"
    echo "  --help        이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0 --dry-run    # 시스템 준비 상태 확인"
    echo "  $0 --check     # 모든 구성 요소 검증"
    echo "  $0             # 실제 빠른 시작 실행"
    echo ""
    echo "단계별 확인:"
    echo "  1. 플랫폼 설정 상태"
    echo "  2. 캐시 다운로드 가능성"
    echo "  3. Docker 환경 준비"
    echo "  4. 포트 및 리소스 확인"
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
        echo ""
        if [ "$DRY_RUN" = true ]; then
            log_error "========================="
            log_error "🧪 시스템 검사에서 문제 발견!"
            log_error "========================="
            log_error "위의 오류를 해결한 후 다시 시도하세요."
        else
            log_error "========================="
            log_error "🚨 스크립트가 실패했습니다!"
            log_error "========================="
            log_error "오류가 발생한 단계를 확인하고 문제를 해결한 후 다시 시도하세요."
        fi
        
        echo ""
        log_error "일반적인 해결 방법:"
        log_error "1. 네트워크 연결 확인"
        log_error "2. Docker 서비스 상태 확인: docker info"
        log_error "3. 디스크 공간 확인 (최소 20GB 필요)"
        log_error "4. 메모리 확인 (최소 8GB 권장)"
        log_error "5. 방화벽/보안 소프트웨어 확인"
        
        if [ "$DRY_RUN" = false ]; then
            echo ""
            log_error "❓ 도움이 필요하시면:"
            log_error "   ./scripts/quick-start.sh --dry-run  # 문제 진단"
            log_error "   ./scripts/vm-test.sh                # 상세 테스트"
        fi
    fi
    exit $exit_code
}

# 신호 처리
trap cleanup EXIT INT TERM

if [ "$DRY_RUN" = true ]; then
    echo "🧪 KEA Yocto 시스템 준비 상태 검사"
    echo "=================================="
    echo "📋 실제 실행 없이 모든 구성 요소를 확인합니다..."
else
    echo "🚀 KEA Yocto 빠른 시작"
    echo "======================"
fi

# 0단계: 기본 환경 검사
if [ "$DRY_RUN" = true ]; then
    log_step "0단계: 기본 환경 검사 중..."
    
    # 운영체제 확인
    if [ "$VERBOSE" = true ]; then
        log_info "운영체제: $(uname -s) $(uname -r)"
        log_info "아키텍처: $(uname -m)"
    fi
    
    # 셸 환경 확인
    if [ -z "$BASH_VERSION" ]; then
        log_warn "Bash가 아닌 셸에서 실행 중입니다. 일부 기능이 제한될 수 있습니다."
    fi
    
    # 기본 명령어 확인
    required_commands=("docker" "curl" "tar" "gzip")
    missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        elif [ "$VERBOSE" = true ]; then
            log_info "$cmd: $(command -v "$cmd")"
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        log_error "필수 명령어가 없습니다: ${missing_commands[*]}"
        log_error "▶ 설치 방법:"
        for cmd in "${missing_commands[@]}"; do
            case $cmd in
                docker)
                    log_error "  Docker: https://docs.docker.com/get-docker/"
                    ;;
                curl)
                    log_error "  curl: apt install curl (Ubuntu) 또는 brew install curl (macOS)"
                    ;;
                tar|gzip)
                    log_error "  $cmd: 일반적으로 시스템에 기본 설치됨"
                    ;;
            esac
        done
        exit 1
    fi
    
    log_info "기본 환경 확인 ✓"
fi

# 1단계: 플랫폼 설정 확인
log_step "$([ "$DRY_RUN" = true ] && echo "1" || echo "0")단계: 플랫폼 설정 $([ "$DRY_RUN" = true ] && echo "확인" || echo "중")..."

if [ "$DRY_RUN" = true ]; then
    # 아키텍처 감지
    ARCH=$(uname -m)
    log_info "현재 아키텍처: $ARCH"
    
    # 플랫폼별 권장 사항
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        log_info "ARM64 환경 감지됨"
        
        # ARM64 전용 이미지 확인
        ARM64_IMAGE="yocto-lecture:arm64-fast"
        if docker image inspect "$ARM64_IMAGE" >/dev/null 2>&1; then
            log_info "ARM64 전용 이미지 확인: $ARM64_IMAGE ✓"
        else
            log_warn "ARM64 전용 이미지가 없습니다"
            log_warn "▶ 권장 사항:"
            log_warn "  ./scripts/vm-arm64-safe.sh  # ARM64 안전 모드 사용"
        fi
        
        # Dockerfile.arm64 확인
        if [ -f "Dockerfile.arm64" ]; then
            log_info "ARM64 Dockerfile 확인: Dockerfile.arm64 ✓"
        else
            log_warn "ARM64 Dockerfile이 없습니다: Dockerfile.arm64"
        fi
    else
        log_info "x86_64 환경 감지됨 - 표준 이미지 사용"
    fi
    
    # 기존 override 파일 확인
    if [ -f "docker-compose.override.yml" ]; then
        log_info "기존 플랫폼 설정 발견: docker-compose.override.yml"
        if [ "$VERBOSE" = true ]; then
            log_info "설정 내용:"
            grep -E "(platform|image)" docker-compose.override.yml | sed 's/^/    /' || true
        fi
    else
        log_info "플랫폼 설정이 필요합니다 (자동 생성 예정)"
    fi
else
    # 실제 플랫폼 설정 실행
    log_info "🔍 플랫폼 감지 중..."
    ARCH=$(uname -m)
    log_info "현재 아키텍처: $ARCH"
    
    # 기존 override 파일 제거
    if [ -f docker-compose.override.yml ]; then
        rm -f docker-compose.override.yml
        log_info "기존 override 설정 제거됨"
    fi
    
    if ./scripts/setup-platform.sh; then
        log_info "✅ 플랫폼 설정 완료!"
    else
        log_error "플랫폼 설정에 실패했습니다"
        exit 1
    fi
fi

# 2단계: 캐시 준비 상태 확인
log_step "$([ "$DRY_RUN" = true ] && echo "2" || echo "1")단계: 캐시 준비 상태 $([ "$DRY_RUN" = true ] && echo "확인" || echo "중")..."

if [ "$DRY_RUN" = true ]; then
    # 기존 캐시 상태 확인
    if [ -d "yocto-workspace/downloads" ] && [ "$(ls -A yocto-workspace/downloads 2>/dev/null)" ]; then
        downloads_size=$(du -sh yocto-workspace/downloads | cut -f1)
        log_info "기존 downloads 캐시: $downloads_size ✓"
        DOWNLOADS_AVAILABLE=true
    else
        log_info "downloads 캐시: 없음 (다운로드 필요)"
        DOWNLOADS_AVAILABLE=false
    fi
    
    if [ -d "yocto-workspace/sstate-cache" ] && [ "$(ls -A yocto-workspace/sstate-cache 2>/dev/null)" ]; then
        sstate_size=$(du -sh yocto-workspace/sstate-cache | cut -f1)
        log_info "기존 sstate 캐시: $sstate_size ✓"
        SSTATE_AVAILABLE=true
    else
        log_info "sstate 캐시: 없음 (다운로드 필요)"
        SSTATE_AVAILABLE=false
    fi
    
    # 캐시 다운로드 가능성 테스트
    if [ "$DOWNLOADS_AVAILABLE" = false ] || [ "$SSTATE_AVAILABLE" = false ]; then
        log_info "캐시 다운로드 가능성 테스트 중..."
        
        # prepare-cache.sh 스크립트 찾기
        cache_script_path=""
        if [ -f "./scripts/prepare-cache.sh" ]; then
            cache_script_path="./scripts/prepare-cache.sh"
        elif [ -f "../scripts/prepare-cache.sh" ]; then
            cache_script_path="../scripts/prepare-cache.sh"
        elif [ -f "scripts/prepare-cache.sh" ]; then
            cache_script_path="scripts/prepare-cache.sh"
        else
            log_warn "prepare-cache.sh 스크립트를 찾을 수 없습니다. 캐시 테스트를 건너뜁니다."
            cache_script_path=""
        fi
        
        if [ -n "$cache_script_path" ]; then
            if [ "$VERBOSE" = true ]; then
                # 상세 테스트 실행
                if "$cache_script_path" --dry-run --verbose; then
                    log_info "캐시 다운로드 가능성: ✓"
                else
                    log_warn "캐시 다운로드에 문제가 있을 수 있습니다"
                fi
            else
                # 간단한 테스트
                if "$cache_script_path" --dry-run >/dev/null 2>&1; then
                    log_info "캐시 다운로드 가능성: ✓"
                else
                    log_warn "캐시 다운로드에 문제가 있을 수 있습니다"
                    if [ "$DRY_RUN" = true ]; then
                        log_warn "▶ 상세 확인: $cache_script_path --dry-run --verbose"
                    fi
                fi
            fi
        fi
    fi
else
    # 실제 캐시 준비 실행
    cache_script_path=""
    if [ -f "./scripts/prepare-cache.sh" ]; then
        cache_script_path="./scripts/prepare-cache.sh"
    elif [ -f "../scripts/prepare-cache.sh" ]; then
        cache_script_path="../scripts/prepare-cache.sh"
    elif [ -f "scripts/prepare-cache.sh" ]; then
        cache_script_path="scripts/prepare-cache.sh"
    else
        log_error "prepare-cache.sh 스크립트를 찾을 수 없습니다"
        exit 1
    fi
    
    if "$cache_script_path"; then
        log_info "캐시 준비 완료"
    else
        log_warn "캐시 준비에 일부 실패했습니다. 계속 진행합니다."
    fi
fi

# 3단계: Docker 환경 확인
log_step "$([ "$DRY_RUN" = true ] && echo "3" || echo "2")단계: Docker 환경 $([ "$DRY_RUN" = true ] && echo "확인" || echo "중")..."

if [ "$DRY_RUN" = true ]; then
    # Docker 서비스 상태 확인
    if docker info >/dev/null 2>&1; then
        log_info "Docker 서비스: 실행 중 ✓"
        
        if [ "$VERBOSE" = true ]; then
            docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
            log_info "Docker 버전: $docker_version"
            
            # Docker 리소스 정보
            docker_info=$(docker info --format "{{.NCPU}} CPUs, {{.MemTotal}}" 2>/dev/null || echo "정보 없음")
            log_info "Docker 리소스: $docker_info"
            
            # Docker 디스크 사용량
            docker_disk=$(docker system df --format "table {{.Type}}\t{{.Size}}" 2>/dev/null | grep "Total" | awk '{print $2}' || echo "알 수 없음")
            log_info "Docker 디스크 사용량: $docker_disk"
        fi
    else
        log_error "Docker 서비스가 실행되지 않습니다"
        log_error "▶ 해결 방법:"
        log_error "  1. Docker Desktop 시작 (macOS/Windows)"
        log_error "  2. Docker 서비스 시작: sudo systemctl start docker (Linux)"
        log_error "  3. Docker 설치 확인: docker --version"
        exit 1
    fi
    
    # Docker Compose 확인
    if docker compose version >/dev/null 2>&1; then
        log_info "Docker Compose: 사용 가능 ✓"
        if [ "$VERBOSE" = true ]; then
            compose_version=$(docker compose version --short 2>/dev/null || echo "알 수 없음")
            log_info "Docker Compose 버전: $compose_version"
        fi
    else
        log_error "Docker Compose를 사용할 수 없습니다"
        log_error "▶ Docker Desktop을 업데이트하거나 docker-compose를 설치하세요"
        exit 1
    fi
    
    # 이미지 확인
    DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        ARM64_IMAGE="yocto-lecture:arm64-fast"
        if docker image inspect "$ARM64_IMAGE" >/dev/null 2>&1; then
            DOCKER_IMAGE="$ARM64_IMAGE"
        fi
    fi
    
    if docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
        log_info "Docker 이미지 확인: $DOCKER_IMAGE ✓"
        if [ "$VERBOSE" = true ]; then
            image_size=$(docker image inspect "$DOCKER_IMAGE" --format "{{.Size}}" | awk '{print int($1/1024/1024) "MB"}')
            log_info "이미지 크기: $image_size"
        fi
    else
        log_warn "Docker 이미지가 로컬에 없습니다: $DOCKER_IMAGE"
        log_warn "▶ 이미지 다운로드가 필요합니다 (약 2-3GB)"
    fi
    
    # 포트 사용 확인
    VNC_PORT=5900
    SSH_PORT=2222
    
    check_port() {
        local port=$1
        if command -v lsof >/dev/null 2>&1; then
            if lsof -i :$port >/dev/null 2>&1; then
                return 1  # 포트 사용 중
            fi
        elif command -v netstat >/dev/null 2>&1; then
            if netstat -an | grep ":$port " >/dev/null 2>&1; then
                return 1  # 포트 사용 중
            fi
        fi
        return 0  # 포트 사용 가능
    }
    
    if check_port $VNC_PORT; then
        log_info "VNC 포트 ($VNC_PORT): 사용 가능 ✓"
    else
        log_warn "VNC 포트 ($VNC_PORT): 사용 중"
        log_warn "▶ VNC 연결에 문제가 있을 수 있습니다"
    fi
    
    if check_port $SSH_PORT; then
        log_info "SSH 포트 ($SSH_PORT): 사용 가능 ✓"
    else
        log_warn "SSH 포트 ($SSH_PORT): 사용 중"
        log_warn "▶ SSH 연결에 문제가 있을 수 있습니다"
    fi
else
    # 실제 Docker 환경 시작
    log_info "🐳 Docker 설정 확인:"
    if docker compose config --services; then
        log_info "✅ Docker 설정 유효!"
    else
        log_error "Docker Compose 설정에 오류가 있습니다"
        exit 1
    fi
fi

# 4단계: 시스템 리소스 확인 (dry-run에서만)
if [ "$DRY_RUN" = true ]; then
    log_step "4단계: 시스템 리소스 확인 중..."
    
    # 디스크 공간 확인
    available_space=$(df . | tail -1 | awk '{print $4}')
    available_space_gb=$((available_space / 1024 / 1024))
    required_space_gb=20
    
    if [ $available_space_gb -ge $required_space_gb ]; then
        log_info "디스크 공간: ${available_space_gb}GB 사용 가능 ✓"
    else
        log_error "디스크 공간 부족: ${available_space_gb}GB 사용 가능 (최소 ${required_space_gb}GB 필요)"
        log_error "▶ 해결 방법:"
        log_error "  1. 불필요한 파일 삭제"
        log_error "  2. Docker 정리: docker system prune -a"
        log_error "  3. 다른 볼륨으로 이동"
        exit 1
    fi
    
    # 메모리 확인
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        total_memory_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        total_memory_gb=$((total_memory_kb / 1024 / 1024))
        available_memory_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        available_memory_gb=$((available_memory_kb / 1024 / 1024))
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        total_memory_bytes=$(sysctl -n hw.memsize)
        total_memory_gb=$((total_memory_bytes / 1024 / 1024 / 1024))
        available_memory_gb=$total_memory_gb  # 근사치
    else
        total_memory_gb=8
        available_memory_gb=6
        log_warn "메모리 정보를 자동으로 감지할 수 없습니다. 추정값 사용"
    fi
    
    min_memory_gb=4
    if [ $available_memory_gb -ge $min_memory_gb ]; then
        log_info "메모리: ${available_memory_gb}GB/${total_memory_gb}GB 사용 가능 ✓"
    else
        log_warn "메모리 부족: ${available_memory_gb}GB 사용 가능 (권장: ${min_memory_gb}GB 이상)"
        log_warn "▶ 성능이 저하될 수 있습니다"
    fi
    
    # CPU 확인
    if command -v nproc >/dev/null 2>&1; then
        cpu_cores=$(nproc)
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        cpu_cores=$(sysctl -n hw.ncpu)
    else
        cpu_cores=4  # 기본값
    fi
    
    min_cores=2
    if [ $cpu_cores -ge $min_cores ]; then
        log_info "CPU: ${cpu_cores}코어 ✓"
    else
        log_warn "CPU 코어 수가 적습니다: ${cpu_cores}코어 (권장: ${min_cores}코어 이상)"
    fi
fi

# Dry-run 모드 결과 요약
if [ "$DRY_RUN" = true ]; then
    echo ""
    log_info "🎉 시스템 준비 상태 검사 완료!"
    echo ""
    echo "📊 검사 결과 요약:"
    echo "=================="
    
    echo ""
    echo "🖥️  시스템 환경:"
    echo "   ✅ 운영체제: $(uname -s) $(uname -m)"
    echo "   ✅ 필수 명령어: 모두 설치됨"
    echo "   ✅ 디스크 공간: ${available_space_gb}GB"
    echo "   ✅ 메모리: ${available_memory_gb}GB/${total_memory_gb}GB"
    echo "   ✅ CPU: ${cpu_cores}코어"
    
    echo ""
    echo "🐳 Docker 환경:"
    echo "   ✅ Docker 서비스: 실행 중"
    echo "   ✅ Docker Compose: 사용 가능"
    if docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
        echo "   ✅ Docker 이미지: $DOCKER_IMAGE"
    else
        echo "   ⚠️  Docker 이미지: 다운로드 필요 ($DOCKER_IMAGE)"
    fi
    
    echo ""
    echo "📦 캐시 상태:"
    if [ "$DOWNLOADS_AVAILABLE" = true ]; then
        echo "   ✅ Downloads 캐시: $downloads_size"
    else
        echo "   ⚠️  Downloads 캐시: 다운로드 필요"
    fi
    if [ "$SSTATE_AVAILABLE" = true ]; then
        echo "   ✅ sstate 캐시: $sstate_size"
    else
        echo "   ⚠️  sstate 캐시: 다운로드 필요"
    fi
    
    echo ""
    echo "⏱️  예상 빌드 시간:"
    if [ "$DOWNLOADS_AVAILABLE" = true ] && [ "$SSTATE_AVAILABLE" = true ]; then
        echo "   🚀 15-30분 (풀 캐시 사용)"
    elif [ "$SSTATE_AVAILABLE" = true ]; then
        echo "   ⚡ 45분-1시간 (sstate 캐시만)"
    elif [ "$DOWNLOADS_AVAILABLE" = true ]; then
        echo "   🕐 1.5-2시간 (downloads 캐시만)"
    else
        echo "   ⏰ 2-3시간 (캐시 없음)"
    fi
    
    echo ""
    log_info "🚀 실제 빠른 시작을 실행하려면:"
    echo "   $0"
    echo ""
    
    if docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1 || [ "$DOWNLOADS_AVAILABLE" = false ] || [ "$SSTATE_AVAILABLE" = false ]; then
        log_info "💡 예상 실행 과정:"
        echo "   1. 플랫폼 설정 자동 구성"
        [ "$DOWNLOADS_AVAILABLE" = false ] && echo "   2. Downloads 캐시 다운로드 (2-5GB)"
        [ "$SSTATE_AVAILABLE" = false ] && echo "   3. sstate 캐시 다운로드 (5-20GB)"
        [ ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1 ] && echo "   4. Docker 이미지 다운로드 (2-3GB)"
        echo "   5. Docker 컨테이너 시작"
        echo "   6. Yocto 환경 준비 완료"
    fi
    
    exit 0
fi

# 실제 실행 계속 (기존 코드)
log_step "2단계: Docker 컨테이너 시작 중..."

if docker compose run --rm yocto-lecture; then
    echo ""
    log_info "🎉 KEA Yocto 환경이 성공적으로 시작되었습니다!"
    log_info ""
    log_info "다음 단계:"
    log_info "1. 컨테이너 내에서 'yocto_init' 실행"
    log_info "2. 'yocto_quick_build' 로 첫 빌드 시작"
    log_info "3. 빌드 완료 후 'runqemu qemux86-64 core-image-minimal' 로 실행"
else
    log_error "Docker 컨테이너 시작에 실패했습니다."
    log_error ""
    log_error "문제해결 방법:"
    log_error "1. Docker 서비스 상태 확인: docker info"
    log_error "2. 이미지 다시 다운로드: docker pull jabang3/yocto-lecture:5.0-lts"
    log_error "3. ARM64 VM인 경우: ./scripts/vm-arm64-safe.sh"
    log_error "4. 상세 테스트: ./scripts/vm-test.sh"
    exit 1
fi 