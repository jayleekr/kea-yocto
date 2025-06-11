#!/bin/bash

# 🔧 KEA Yocto Project 시스템 수정 스크립트 v1.0
# ================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 로깅 함수
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 헤더 출력
show_header() {
    echo -e "${PURPLE}"
    echo "🔧 KEA Yocto Project 시스템 수정 스크립트"
    echo "=========================================="
    echo -e "${NC}"
    echo "📅 실행 시간: $(date)"
    echo "📁 프로젝트 디렉토리: $PROJECT_DIR"
    echo ""
}

# 스크립트 권한 수정
fix_script_permissions() {
    log "스크립트 실행 권한 수정 중..."
    
    if [ -d "$PROJECT_DIR/scripts" ]; then
        find "$PROJECT_DIR/scripts" -name "*.sh" -type f -exec chmod +x {} \;
        success "스크립트 실행 권한 수정 완료"
    else
        error "scripts 디렉토리를 찾을 수 없습니다"
    fi
}

# Docker 환경 수정
fix_docker_environment() {
    log "Docker 환경 확인 및 수정 중..."
    
    # Docker 설치 확인
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker가 설치되지 않았습니다. Docker를 먼저 설치해주세요."
        echo "설치 방법:"
        echo "  macOS: https://docs.docker.com/desktop/mac/install/"
        echo "  Ubuntu: sudo apt-get install docker.io"
        return 1
    fi
    
    success "Docker 환경 확인 완료"
}

# 디렉토리 구조 수정
fix_directory_structure() {
    log "디렉토리 구조 확인 및 수정 중..."
    
    # 필요한 디렉토리들 생성
    local directories=(
        "materials"
        "agent-configs" 
        "yocto-workspace"
        "yocto-workspace/downloads"
        "yocto-workspace/sstate-cache"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$PROJECT_DIR/$dir" ]; then
            mkdir -p "$PROJECT_DIR/$dir"
            log "디렉토리 생성: $dir"
        fi
    done
    
    success "디렉토리 구조 확인 완료"
}

# 네트워크 연결 테스트
test_network_connectivity() {
    log "네트워크 연결 테스트 중..."
    
    local test_urls=(
        "github.com"
        "google.com"
    )
    
    for url in "${test_urls[@]}"; do
        if curl -s --connect-timeout 5 "https://$url" >/dev/null 2>&1; then
            log "✓ $url 연결 가능"
        else
            warn "✗ $url 연결 실패"
        fi
    done
    
    success "네트워크 연결 테스트 완료"
}

# 디스크 공간 확인
check_disk_space() {
    log "디스크 공간 확인 중..."
    
    local available_gb=$(df . | tail -1 | awk '{print int($4/1024/1024)}')
    log "사용 가능한 디스크 공간: ${available_gb}GB"
    
    if [ "$available_gb" -lt 50 ]; then
        warn "디스크 공간이 부족합니다 (필요: 50GB, 사용 가능: ${available_gb}GB)"
    else
        success "디스크 공간 충분 (사용 가능: ${available_gb}GB)"
    fi
}

# 전체 수정 실행
run_all_fixes() {
    log "모든 수정 작업 시작..."
    
    fix_script_permissions
    fix_docker_environment
    fix_directory_structure
    test_network_connectivity
    check_disk_space
    
    success "모든 수정 작업 완료!"
}

# 도움말 출력
show_help() {
    echo "🔧 KEA Yocto Project 시스템 수정 스크립트"
    echo ""
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -h, --help        이 도움말을 표시합니다"
    echo "  -a, --all         모든 수정 작업을 실행합니다"
    echo "  -p, --permissions 스크립트 권한만 수정합니다"
    echo "  -d, --docker      Docker 환경만 확인합니다"
    echo ""
    echo "예제:"
    echo "  $0 --all          # 모든 수정 작업 실행"
    echo "  $0 --permissions  # 스크립트 권한만 수정"
    echo "  $0 --docker       # Docker 환경만 확인"
}

# 메인 함수
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--all)
            show_header
            run_all_fixes
            ;;
        -p|--permissions)
            show_header
            fix_script_permissions
            ;;
        -d|--docker)
            show_header
            fix_docker_environment
            ;;
        "")
            show_header
            run_all_fixes
            ;;
        *)
            error "알 수 없는 옵션: $1"
            show_help
            exit 1
            ;;
    esac
}

# 스크립트 실행
main "$@" 