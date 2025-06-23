#!/bin/bash
set -e

echo "📚 문서 빌드 및 PDF 생성 스크립트"
echo "================================="

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 1단계: MkDocs 문서 빌드
log_info "1단계: MkDocs 문서 빌드 중..."

# Python 가상환경 확인/생성
if [ ! -d "venv" ]; then
    log_info "Python 가상환경 생성 중..."
    python3 -m venv venv
fi

# 가상환경 활성화
source venv/bin/activate

# Python 의존성 설치
log_info "Python 패키지 설치 중..."
pip install -r requirements.txt

# 기존 빌드 정리
if [ -d "site" ]; then
    log_info "기존 빌드 정리 중..."
    rm -rf site
fi

# MkDocs 빌드
log_info "MkDocs 빌드 실행 중..."
mkdocs build

log_success "MkDocs 빌드 완료!"

# 2단계: Node.js 환경 설정
log_info "2단계: Node.js 환경 설정 중..."

# Node.js 설치 확인
if ! command -v node &> /dev/null; then
    log_warn "Node.js가 설치되어 있지 않습니다."
    log_warn "Node.js를 설치한 후 다시 실행하세요: https://nodejs.org/"
    exit 1
fi

# npm 패키지 설치
if [ ! -d "node_modules" ]; then
    log_info "npm 패키지 설치 중..."
    npm install
else
    log_info "npm 패키지 업데이트 중..."
    npm update
fi

# 3단계: 로컬 서버 시작
log_info "3단계: 로컬 서버 시작 중..."

# 백그라운드에서 로컬 서버 실행
log_info "MkDocs 서버 시작 중... (포트 8000)"
mkdocs serve --dev-addr=127.0.0.1:8000 &
MKDOCS_PID=$!

# 서버가 준비될 때까지 대기
log_info "서버 준비 대기 중..."
sleep 5

# 서버 상태 확인
if curl -s http://localhost:8000 > /dev/null; then
    log_success "로컬 서버 준비 완료!"
else
    log_warn "로컬 서버 시작에 실패했습니다. 사이트 디렉토리를 직접 사용합니다."
    kill $MKDOCS_PID 2>/dev/null || true
    
    # 간단한 HTTP 서버로 대체
    cd site
    python3 -m http.server 8000 &
    SERVER_PID=$!
    cd ..
    sleep 3
fi

# 4단계: PDF 생성
log_info "4단계: PDF 생성 중..."

# PDF 출력 디렉토리 정리
if [ -d "pdf-output" ]; then
    rm -rf pdf-output
fi

# PDF 생성 실행
log_info "전체 PDF 및 개별 강의 PDF 생성 중..."
node scripts/generate-pdf.js --base-url http://localhost:8000

# 5단계: 정리
log_info "5단계: 정리 중..."

# 서버 종료
if [ ! -z "$MKDOCS_PID" ]; then
    kill $MKDOCS_PID 2>/dev/null || true
fi

if [ ! -z "$SERVER_PID" ]; then
    kill $SERVER_PID 2>/dev/null || true
fi

# 6단계: 결과 확인
log_success "모든 작업이 완료되었습니다!"

echo ""
echo "📁 생성된 파일들:"
echo "=================="

if [ -d "site" ]; then
    site_size=$(du -sh site | cut -f1)
    log_success "HTML 사이트: site/ ($site_size)"
fi

if [ -d "pdf-output" ]; then
    echo ""
    echo "📄 PDF 파일들:"
    find pdf-output -name "*.pdf" -exec basename {} \; | while read file; do
        size=$(du -sh "pdf-output/$file" | cut -f1)
        log_success "  $file ($size)"
    done
    
    total_pdf_size=$(du -sh pdf-output | cut -f1)
    echo ""
    log_success "총 PDF 크기: $total_pdf_size"
fi

echo ""
echo "🚀 다음 단계:"
echo "============="
echo "1. 웹사이트 배포: site/ 디렉토리를 웹서버에 업로드"
echo "2. PDF 배포: pdf-output/ 의 PDF 파일들을 다운로드 링크로 제공"
echo "3. 로컬 미리보기: mkdocs serve"

echo ""
log_success "빌드 프로세스가 성공적으로 완료되었습니다!" 