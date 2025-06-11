#!/bin/bash

# 📚 KEA Yocto Project PDF 생성 (Docker 버전)
# =============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# 도움말 함수
show_help() {
    cat << EOF
🚀 KEA Yocto Project PDF 생성 (Docker 버전) v1.0
================================================

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help     이 도움말을 표시합니다
    -v, --verbose  상세한 로그를 출력합니다
    -r, --rebuild  컨테이너를 다시 빌드합니다

DESCRIPTION:
    Docker 컨테이너 내에서 pandoc을 사용하여 강의 자료 PDF를 생성합니다.
    
EXAMPLES:
    $0                          # 기본 PDF 생성
    $0 --verbose               # 상세 로그와 함께 생성
    $0 --rebuild              # 컨테이너 재빌드 후 생성

EOF
}

# 옵션 파싱
VERBOSE=false
REBUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -r|--rebuild)
            REBUILD=true
            shift
            ;;
        *)
            error "알 수 없는 옵션: $1"
            show_help
            exit 1
            ;;
    esac
done

# 헤더 출력
echo -e "${BLUE}"
cat << 'EOF'
🚀 KEA Yocto Project PDF 생성 (Docker 버전)
=============================================
EOF
echo -e "${NC}"

# 현재 디렉토리 확인
log "현재 작업 디렉토리: $(pwd)"

# materials 디렉토리 존재 확인
if [ ! -d "${PROJECT_DIR}/materials" ]; then
    error "materials 디렉토리를 찾을 수 없습니다."
    error "프로젝트 루트 디렉토리에서 실행해주세요."
    exit 1
fi

# Docker 설치 확인
if ! command -v docker &> /dev/null; then
    error "Docker가 설치되지 않았습니다."
    error "Docker를 설치한 후 다시 시도해주세요."
    exit 1
fi

# Docker Compose 설치 확인
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    error "Docker Compose가 설치되지 않았습니다."
    error "Docker Compose를 설치한 후 다시 시도해주세요."
    exit 1
fi

# Docker 서비스 상태 확인
if ! docker info &> /dev/null; then
    error "Docker 서비스가 실행되지 않고 있습니다."
    error "Docker를 시작한 후 다시 시도해주세요."
    exit 1
fi

log "Docker 환경 확인 완료 ✓"

# 컨테이너 재빌드 옵션
if [ "$REBUILD" = true ]; then
    log "컨테이너를 다시 빌드합니다..."
    cd "$PROJECT_DIR"
    docker-compose build --no-cache yocto-lecture
fi

# Docker Compose 명령어 결정
DOCKER_COMPOSE_CMD="docker-compose"
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
fi

log "PDF 생성을 시작합니다..."

# Docker 컨테이너에서 PDF 생성 실행
cd "$PROJECT_DIR"

if [ "$VERBOSE" = true ]; then
    log "상세 모드로 PDF 생성 중..."
    $DOCKER_COMPOSE_CMD run --rm yocto-lecture \
        bash -c "cd /materials && ./generate-pdf.sh --verbose"
else
    log "PDF 생성 중..."
    $DOCKER_COMPOSE_CMD run --rm yocto-lecture \
        bash -c "cd /materials && ./generate-pdf.sh"
fi

# 결과 확인
if [ -f "${PROJECT_DIR}/materials/KEA-Yocto-Project-강의자료-latest.pdf" ]; then
    log "✅ PDF 생성이 완료되었습니다!"
    log "📄 생성된 파일:"
    ls -la "${PROJECT_DIR}/materials/"*.pdf 2>/dev/null || true
    
    # 파일 크기 확인
    FILESIZE=$(du -h "${PROJECT_DIR}/materials/KEA-Yocto-Project-강의자료-latest.pdf" | cut -f1)
    log "📊 파일 크기: $FILESIZE"
    
    echo ""
    log "🎉 PDF 파일이 성공적으로 생성되었습니다!"
    log "📁 위치: ./materials/KEA-Yocto-Project-강의자료-latest.pdf"
else
    error "❌ PDF 생성에 실패했습니다."
    error "자세한 오류 내용은 위의 로그를 확인해주세요."
    exit 1
fi

echo ""
log "💡 사용 팁:"
log "   - 생성된 PDF는 materials/ 디렉토리에 저장됩니다"
log "   - 버전별 PDF 파일과 latest 링크가 함께 생성됩니다"
log "   - 다시 생성하려면 이 스크립트를 다시 실행하세요" 