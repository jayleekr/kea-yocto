#!/bin/bash

# 🔍 KEA Yocto Project 시스템 검증 스크립트 v1.0
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
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 결과 추적
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
TEST_RESULTS=()

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

# 테스트 함수
run_test() {
    local test_name="$1"
    local test_command="$2"
    local description="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "\n${CYAN}[TEST $TOTAL_TESTS]${NC} $test_name"
    echo "Description: $description"
    echo "Command: $test_command"
    echo "----------------------------------------"
    
    if eval "$test_command" > /tmp/test_output 2>&1; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        success "✅ PASSED"
        TEST_RESULTS+=("✅ $test_name: PASSED")
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        error "❌ FAILED"
        echo "Error output:"
        cat /tmp/test_output
        TEST_RESULTS+=("❌ $test_name: FAILED")
    fi
}

# 헤더 출력
show_header() {
    echo -e "${PURPLE}"
    echo "🔍 KEA Yocto Project 시스템 검증 스크립트"
    echo "=============================================="
    echo -e "${NC}"
    echo "📅 실행 시간: $(date)"
    echo "📁 프로젝트 디렉토리: $PROJECT_DIR"
    echo "🖥️  운영체제: $(uname -s) $(uname -m)"
    echo "🐚 셸: $SHELL"
    echo ""
}

# 기본 시스템 검증
test_basic_system() {
    echo -e "${BLUE}=== 기본 시스템 검증 ===${NC}"
    
    run_test "Docker 설치 확인" \
        "docker --version" \
        "Docker가 설치되어 있고 접근 가능한지 확인"
    
    run_test "Docker Compose 확인" \
        "docker compose version || docker-compose --version" \
        "Docker Compose가 설치되어 있는지 확인"
    
    run_test "Git 설치 확인" \
        "git --version" \
        "Git이 설치되어 있는지 확인"
    
    run_test "디스크 공간 확인 (최소 50GB)" \
        "[ \$(df . | tail -1 | awk '{print \$4}') -gt 52428800 ]" \
        "빌드에 필요한 최소 50GB 디스크 공간 확인"
}

# 프로젝트 구조 검증
test_project_structure() {
    echo -e "${BLUE}=== 프로젝트 구조 검증 ===${NC}"
    
    run_test "Dockerfile 존재 확인" \
        "[ -f '$PROJECT_DIR/Dockerfile' ]" \
        "메인 Dockerfile이 존재하는지 확인"
    
    run_test "docker-compose.yml 확인" \
        "[ -f '$PROJECT_DIR/docker-compose.yml' ]" \
        "Docker Compose 설정 파일 확인"
    
    run_test "scripts 디렉토리 확인" \
        "[ -d '$PROJECT_DIR/scripts' ]" \
        "스크립트 디렉토리 존재 확인"
    
    run_test "materials 디렉토리 확인" \
        "[ -d '$PROJECT_DIR/materials' ]" \
        "강의 자료 디렉토리 존재 확인"
    
    run_test "강의 자료 Markdown 확인" \
        "[ -f '$PROJECT_DIR/materials/lecture-materials.md' ]" \
        "강의 자료 마크다운 파일 확인"
}

# Docker 환경 검증
test_docker_environment() {
    echo -e "${BLUE}=== Docker 환경 검증 ===${NC}"
    
    run_test "Docker 서비스 상태" \
        "docker info > /dev/null 2>&1" \
        "Docker 데몬이 실행 중인지 확인"
    
    run_test "Docker 이미지 빌드 테스트" \
        "cd '$PROJECT_DIR' && docker build -t yocto-test:verify ." \
        "Dockerfile로 이미지를 성공적으로 빌드할 수 있는지 확인"
    
    run_test "컨테이너 실행 테스트" \
        "docker run --rm yocto-test:verify echo 'Container works'" \
        "빌드된 이미지로 컨테이너 실행 가능 확인"
    
    # pandoc 설치 확인 제거됨
}

# 스크립트 실행 가능성 검증
test_scripts() {
    echo -e "${BLUE}=== 스크립트 검증 ===${NC}"
    
    local scripts=(
        "quick-start.sh"
        "prepare-cache.sh"
        "generate-html.sh"
        "verify-system.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$PROJECT_DIR/scripts/$script" ]; then
            run_test "$script 실행 권한" \
                "[ -x '$PROJECT_DIR/scripts/$script' ]" \
                "$script 파일의 실행 권한 확인"
            
            run_test "$script 구문 검사" \
                "bash -n '$PROJECT_DIR/scripts/$script'" \
                "$script 파일의 bash 구문 유효성 검사"
        fi
    done
}

# HTML 생성 테스트
test_html_generation() {
    echo -e "${BLUE}=== HTML 생성 테스트 ===${NC}"

    run_test "HTML 생성 스크립트 실행" \
        "cd '$PROJECT_DIR' && ./scripts/generate-html.sh < /dev/null" \
        "HTML 생성 테스트"

    run_test "HTML 파일 생성 확인" \
        "[ -f '$PROJECT_DIR/materials/KEA-Yocto-Project-강의자료.html' ]" \
        "실제로 HTML 파일이 생성되었는지 확인"
}

# Yocto 환경 기본 테스트
test_yocto_environment() {
    echo -e "${BLUE}=== Yocto 환경 기본 테스트 ===${NC}"
    
    run_test "Poky 저장소 확인 (컨테이너 내)" \
        "docker run --rm yocto-test:verify test -d /opt/poky" \
        "컨테이너 내부에 Poky 저장소가 존재하는지 확인"
    
    run_test "BitBake 실행 테스트" \
        "docker run --rm yocto-test:verify bash -c 'source /opt/poky/oe-init-build-env /tmp/test && bitbake --version'" \
        "BitBake가 정상적으로 실행되는지 확인"
    
    run_test "빌드 환경 초기화 테스트" \
        "docker run --rm yocto-test:verify bash -c 'source /opt/poky/oe-init-build-env /tmp/test && ls conf/'" \
        "빌드 환경이 정상적으로 초기화되는지 확인"
}

# 네트워크 연결 테스트
test_network() {
    echo -e "${BLUE}=== 네트워크 연결 테스트 ===${NC}"
    
    run_test "GitHub 연결 확인" \
        "curl -s --connect-timeout 10 https://github.com > /dev/null" \
        "GitHub에 접속할 수 있는지 확인"
    
    run_test "Yocto 저장소 연결 확인" \
        "curl -s --connect-timeout 10 https://git.yoctoproject.org > /dev/null" \
        "Yocto 프로젝트 저장소에 접속할 수 있는지 확인"
    
    run_test "Docker Hub 연결 확인" \
        "curl -s --connect-timeout 10 https://hub.docker.com > /dev/null" \
        "Docker Hub에 접속할 수 있는지 확인"
    
    # HTML 생성 스크립트 권한 확인 제거됨
}

# 강의 자료 관련 테스트
echo ""
log "📚 강의 자료 테스트"

run_test "Markdown 파일 존재 확인" \
    "[ -f '$PROJECT_DIR/materials/lecture-materials.md' ]" \
    "강의 자료 Markdown 파일 확인"

# HTML 생성 스크립트 존재 확인 제거됨

# Pandoc 설치 확인 제거됨

if [ "$QUICK_MODE" = false ]; then
    # HTML 생성 테스트 제거됨
    true
fi

# 결과 요약 출력
show_summary() {
    echo -e "\n${PURPLE}🎯 검증 결과 요약${NC}"
    echo "==============================="
    echo "총 테스트: $TOTAL_TESTS"
    echo -e "통과: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "실패: ${RED}$FAILED_TESTS${NC}"
    echo ""
    
    echo "📋 상세 결과:"
    for result in "${TEST_RESULTS[@]}"; do
        echo "  $result"
    done
    
    echo ""
    if [ $FAILED_TESTS -eq 0 ]; then
        success "🎉 모든 테스트가 통과했습니다! 시스템이 정상적으로 설정되었습니다."
        return 0
    else
        error "⚠️  일부 테스트가 실패했습니다. 위의 오류를 확인하고 수정해주세요."
        
        echo -e "\n${YELLOW}💡 문제 해결 가이드:${NC}"
        echo "1. Docker가 실행 중인지 확인: sudo systemctl start docker"
        echo "2. 사용자를 docker 그룹에 추가: sudo usermod -aG docker \$USER"
        echo "3. 디스크 공간 확인: df -h"
        echo "4. 네트워크 연결 확인: ping google.com"
        echo "5. 스크립트 권한 확인: chmod +x scripts/*.sh"
        
        return 1
    fi
}

# 정리 작업
cleanup() {
    log "정리 작업 중..."
    
    # 테스트용 이미지 삭제
    if docker images | grep -q "yocto-test:verify"; then
        docker rmi yocto-test:verify 2>/dev/null || true
    fi
    
    # 임시 파일 삭제
    rm -f /tmp/test_output
    
    log "정리 완료"
}

# 도움말 출력
show_help() {
    echo "🔍 KEA Yocto Project 시스템 검증 스크립트"
    echo ""
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  -h, --help     이 도움말을 표시합니다"
    echo "  -q, --quick    빠른 검증 (Docker 빌드 제외)"
    echo "  -v, --verbose  상세한 출력을 표시합니다"
    echo ""
    echo "예제:"
    echo "  $0              # 전체 검증 실행"
    echo "  $0 --quick      # 빠른 검증 실행"
    echo "  $0 --verbose    # 상세 모드로 실행"
}

# 메인 함수
main() {
    local quick_mode=false
    local verbose_mode=false
    
    # 명령행 인수 처리
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -q|--quick)
                quick_mode=true
                shift
                ;;
            -v|--verbose)
                verbose_mode=true
                set -x
                shift
                ;;
            *)
                error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 시작
    show_header
    
    # 정리 함수 등록
    trap cleanup EXIT
    
    # 테스트 실행
    test_basic_system
    test_project_structure
    
    if [ "$quick_mode" = false ]; then
        test_docker_environment
        test_html_generation
        test_yocto_environment
    else
        warn "빠른 모드: Docker 빌드 및 Yocto 테스트 건너뜀"
    fi
    
    test_scripts
    test_network
    
    # 결과 요약
    show_summary
}

# 스크립트 실행
main "$@" 