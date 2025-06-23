#!/bin/bash

echo "📄 Yocto 강의 문서 PDF 생성 가이드"
echo "=================================="
echo ""

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔧 현재 Puppeteer에서 macOS 호환성 문제가 발생하여,"
echo "   수동 PDF 생성 방법을 안내드립니다."
echo ""

# 1. 로컬 서버 시작
log_info "1단계: 로컬 서버 시작 중..."

if [ ! -d "site" ]; then
    log_error "site 디렉토리가 없습니다. 먼저 mkdocs build를 실행하세요."
    exit 1
fi

# 사용 가능한 포트 찾기
PORT=8000
while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; do
    PORT=$((PORT+1))
done

log_info "포트 $PORT 에서 서버 시작 중..."

cd site
python3 -m http.server $PORT &
SERVER_PID=$!
cd ..

sleep 3

if ps -p $SERVER_PID > /dev/null; then
    log_success "서버가 http://localhost:$PORT 에서 실행 중입니다."
else
    log_error "서버 시작에 실패했습니다."
    exit 1
fi

echo ""
log_info "2단계: 브라우저에서 PDF 생성"
echo "=============================="

echo ""
echo "🌐 브라우저를 열고 다음 주소로 이동하세요:"
echo "   👉 http://localhost:$PORT"
echo ""

echo "📄 각 페이지별 PDF 생성 방법:"
echo ""
echo "📋 전체 강의 자료:"
echo "   1. http://localhost:$PORT (홈페이지)"
echo "   2. http://localhost:$PORT/lecture/intro/ (강의 소개)"
echo "   3. http://localhost:$PORT/lecture/architecture/ (아키텍처)"
echo "   4. http://localhost:$PORT/lecture/setup/ (환경 설정)"
echo "   5. http://localhost:$PORT/lecture/first-build/ (첫 빌드)"
echo "   6. http://localhost:$PORT/lecture/run-image/ (이미지 실행)"
echo "   7. http://localhost:$PORT/lecture/customize/ (커스터마이징)"
echo "   8. http://localhost:$PORT/lecture/custom-layer/ (커스텀 레이어)"
echo "   9. http://localhost:$PORT/lecture/advanced/ (고급 주제)"
echo "   10. http://localhost:$PORT/lecture/conclusion/ (마무리)"
echo ""

echo "📖 추가 가이드:"
echo "   • http://localhost:$PORT/vm-docker-installation/ (VM/Docker 설치)"
echo "   • http://localhost:$PORT/troubleshooting/ (문제 해결)"
echo "   • http://localhost:$PORT/SECURITY-GUIDE/ (보안 가이드)"
echo ""

echo "🖨️  PDF 생성 방법:"
echo "   1. 각 페이지에서 Cmd+P (macOS) 또는 Ctrl+P (Windows/Linux)"
echo "   2. '대상'에서 'PDF로 저장' 선택"
echo "   3. '옵션' → '배경 그래픽' 체크"
echo "   4. 파일명: 'Yocto강의-페이지명.pdf'"
echo "   5. 저장 위치: ./pdf-output/"
echo ""

# PDF 출력 디렉토리 생성
mkdir -p pdf-output

log_info "PDF 저장 디렉토리 준비: ./pdf-output/"

echo ""
echo "💡 고급 팁:"
echo "   • Safari: 개발자 도구 → 반응형 디자인 모드에서 A4 크기로 설정"
echo "   • Chrome: 더 많은 설정 → 용지 크기: A4, 여백: 최소"
echo "   • Firefox: 인쇄 미리보기에서 스케일 조정"
echo ""

echo "⏹️  서버 종료 방법:"
echo "   Ctrl+C 또는 다음 명령어: kill $SERVER_PID"
echo ""

log_warn "서버가 백그라운드에서 실행 중입니다."
log_warn "PDF 생성을 완료한 후 서버를 종료하세요."

echo ""
echo "🎯 자동 종료 설정 (선택사항):"
echo "   30초 후 자동 종료: sleep 30 && kill $SERVER_PID &"

read -p "❓ 30초 후 자동 종료를 설정하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    (sleep 30 && kill $SERVER_PID && echo "🔄 서버가 자동으로 종료되었습니다.") &
    log_info "30초 후 자동 종료가 설정되었습니다."
fi

echo ""
log_success "브라우저에서 http://localhost:$PORT 으로 이동하여 PDF를 생성하세요!"

# 브라우저 자동 열기 (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    sleep 2
    open "http://localhost:$PORT"
    log_info "브라우저가 자동으로 열렸습니다."
fi 