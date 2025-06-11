#!/bin/bash

# 🧪 KEA Yocto Project 기본 테스트 스크립트 v1.0
# ===============================================

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

test_count=0
pass_count=0

# 테스트 함수
test_item() {
    local name="$1"
    local command="$2"
    
    test_count=$((test_count + 1))
    echo -n "  [$test_count] $name ... "
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        pass_count=$((pass_count + 1))
    else
        echo -e "${RED}✗${NC}"
    fi
}

# 헤더 출력
echo -e "${PURPLE}"
echo "🧪 KEA Yocto Project 기본 테스트"
echo "==============================="
echo -e "${NC}"
echo "📅 실행 시간: $(date)"
echo "📁 프로젝트 디렉토리: $PROJECT_DIR"
echo ""

# 1. 기본 시스템 도구 확인
echo -e "${BLUE}1. 기본 시스템 도구 확인${NC}"
test_item "Docker 설치" "command -v docker"
test_item "Git 설치" "command -v git"
test_item "curl 설치" "command -v curl"

# 2. 프로젝트 구조 확인
echo -e "\n${BLUE}2. 프로젝트 구조 확인${NC}"
test_item "Dockerfile 존재" "[ -f '$PROJECT_DIR/Dockerfile' ]"
test_item "docker-compose.yml 존재" "[ -f '$PROJECT_DIR/docker-compose.yml' ]"
test_item "scripts 디렉토리 존재" "[ -d '$PROJECT_DIR/scripts' ]"
test_item "materials 디렉토리 존재" "[ -d '$PROJECT_DIR/materials' ]"

# 3. 스크립트 권한 확인
echo -e "\n${BLUE}3. 스크립트 실행 권한 확인${NC}"
test_item "quick-start.sh 실행 가능" "[ -x '$PROJECT_DIR/scripts/quick-start.sh' ]"
test_item "prepare-cache.sh 실행 가능" "[ -x '$PROJECT_DIR/scripts/prepare-cache.sh' ]"
test_item "generate-pdf-docker.sh 실행 가능" "[ -x '$PROJECT_DIR/scripts/generate-pdf-docker.sh' ]"
test_item "verify-system.sh 실행 가능" "[ -x '$PROJECT_DIR/scripts/verify-system.sh' ]"

# 4. Docker 환경 확인
echo -e "\n${BLUE}4. Docker 환경 확인${NC}"
test_item "Docker 서비스 실행 중" "docker info"
test_item "Docker Compose 사용 가능" "docker compose version || docker-compose --version"

# 5. 네트워크 연결 확인  
echo -e "\n${BLUE}5. 네트워크 연결 확인${NC}"
test_item "GitHub 연결" "curl -s --connect-timeout 5 https://github.com"
test_item "Yocto 저장소 연결" "curl -s --connect-timeout 5 https://git.yoctoproject.org"

# 6. 강의 자료 확인
echo -e "\n${BLUE}6. 강의 자료 확인${NC}"
test_item "강의 자료 Markdown 존재" "[ -f '$PROJECT_DIR/materials/lecture-materials.md' ]"
test_item "PDF 템플릿 존재" "[ -f '$PROJECT_DIR/materials/pandoc-template.yaml' ]"
test_item "버전 파일 존재" "[ -f '$PROJECT_DIR/materials/version.txt' ]"

# 7. 추가 구성 요소 확인
echo -e "\n${BLUE}7. 추가 구성 요소 확인${NC}"
test_item "agent-configs 디렉토리 존재" "[ -d '$PROJECT_DIR/agent-configs' ]"
test_item "yocto-workspace 디렉토리 존재" "[ -d '$PROJECT_DIR/yocto-workspace' ]"

# 결과 요약
echo -e "\n${PURPLE}📊 테스트 결과 요약${NC}"
echo "=============================="
echo "총 테스트: $test_count"
echo -e "통과: ${GREEN}$pass_count${NC}"
echo -e "실패: ${RED}$((test_count - pass_count))${NC}"

if [ $pass_count -eq $test_count ]; then
    echo -e "\n${GREEN}🎉 모든 기본 테스트가 통과했습니다!${NC}"
    echo "이제 다음 단계를 시도해볼 수 있습니다:"
    echo "  1. PDF 생성: ./scripts/generate-pdf-docker.sh"
    echo "  2. 전체 검증: ./scripts/verify-system.sh"
    echo "  3. 빠른 시작: ./scripts/quick-start.sh"
    exit 0
else
    echo -e "\n${YELLOW}⚠️  일부 테스트가 실패했습니다.${NC}"
    echo "실패한 항목들을 확인하고 수정해주세요."
    echo ""
    echo "💡 일반적인 해결책:"
    echo "  1. 스크립트 권한 수정: ./scripts/fix-system.sh --permissions"
    echo "  2. Docker 설치: https://docs.docker.com/get-docker/"
    echo "  3. 네트워크 연결 확인: 방화벽/프록시 설정 확인"
    exit 1
fi 