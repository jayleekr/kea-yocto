#!/bin/bash

# 강사용 캐시 업로드 스크립트
# 생성된 캐시 파일들을 다양한 호스팅 서비스에 업로드합니다.

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

echo "📤 KEA Yocto 캐시 업로드 도구"
echo "================================"
echo ""

# 기본 설정
WORKSPACE_DIR="./yocto-workspace"
UPLOAD_TYPE=""
DRY_RUN=false

show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --type TYPE        업로드 방식 (github|ftp|s3|local)"
    echo "  --workspace DIR    작업공간 디렉토리 (기본값: ./yocto-workspace)"
    echo "  --dry-run         실제 업로드 없이 준비 상태만 확인"
    echo "  --help            이 도움말 표시"
    echo ""
    echo "업로드 방식:"
    echo "  github    GitHub Release에 업로드"
    echo "  ftp       FTP 서버에 업로드"
    echo "  s3        AWS S3에 업로드"
    echo "  local     로컬 웹 서버용 준비"
    echo ""
    echo "예시:"
    echo "  $0 --type github       # GitHub Release에 업로드"
    echo "  $0 --type local        # 로컬 웹 서버용 준비"
    echo "  $0 --dry-run           # 업로드 준비 상태 확인"
}

# 인자 처리
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            UPLOAD_TYPE="$2"
            shift 2
            ;;
        --workspace)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
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

if [ -z "$UPLOAD_TYPE" ] && [ "$DRY_RUN" = false ]; then
    log_error "업로드 방식을 지정해주세요: --type [github|ftp|s3|local]"
    show_usage
    exit 1
fi

log_step "1단계: 캐시 파일 확인 중..."

# 캐시 파일 존재 확인
DOWNLOADS_CACHE="$WORKSPACE_DIR/downloads-cache.tar.gz"
SSTATE_CACHE="$WORKSPACE_DIR/sstate-cache.tar.gz"

if [ ! -f "$DOWNLOADS_CACHE" ]; then
    log_error "Downloads 캐시 파일을 찾을 수 없습니다: $DOWNLOADS_CACHE"
    log_error "먼저 ./scripts/prepare-instructor-cache.sh 를 실행하세요."
    exit 1
fi

if [ ! -f "$SSTATE_CACHE" ]; then
    log_error "sstate 캐시 파일을 찾을 수 없습니다: $SSTATE_CACHE"
    log_error "먼저 ./scripts/prepare-instructor-cache.sh 를 실행하세요."
    exit 1
fi

# 파일 크기 확인
downloads_size=$(du -h "$DOWNLOADS_CACHE" | cut -f1)
sstate_size=$(du -h "$SSTATE_CACHE" | cut -f1)

log_info "캐시 파일 확인 완료:"
log_info "  downloads-cache.tar.gz: $downloads_size"
log_info "  sstate-cache.tar.gz: $sstate_size"

log_step "2단계: 파일 무결성 확인 중..."

# 압축 파일 무결성 검사
if ! tar -tzf "$DOWNLOADS_CACHE" >/dev/null 2>&1; then
    log_error "Downloads 캐시 파일이 손상되었습니다: $DOWNLOADS_CACHE"
    exit 1
fi

if ! tar -tzf "$SSTATE_CACHE" >/dev/null 2>&1; then
    log_error "sstate 캐시 파일이 손상되었습니다: $SSTATE_CACHE"
    exit 1
fi

log_info "파일 무결성 확인 완료 ✓"

# 체크섬 생성
log_step "3단계: 체크섬 생성 중..."

cd "$WORKSPACE_DIR"

log_info "MD5 체크섬 생성 중..."
md5sum downloads-cache.tar.gz > downloads-cache.tar.gz.md5
md5sum sstate-cache.tar.gz > sstate-cache.tar.gz.md5

log_info "SHA256 체크섬 생성 중..."
sha256sum downloads-cache.tar.gz > downloads-cache.tar.gz.sha256
sha256sum sstate-cache.tar.gz > sstate-cache.tar.gz.sha256

log_info "체크섬 생성 완료 ✓"

# 메타데이터 생성
log_step "4단계: 메타데이터 생성 중..."

cat > cache-info.txt << EOF
KEA Yocto Project 5.0 LTS 캐시 파일
=====================================

생성 날짜: $(date)
Yocto 버전: 5.0 LTS (Scarthgap)
Docker 이미지: jabang3/yocto-lecture:5.0-lts

파일 정보:
- downloads-cache.tar.gz: $downloads_size
- sstate-cache.tar.gz: $sstate_size

사용법:
1. 두 파일을 yocto-workspace/ 디렉토리에 다운로드
2. tar -xzf downloads-cache.tar.gz
3. tar -xzf sstate-cache.tar.gz
4. ./scripts/quick-start.sh 실행

체크섬:
- downloads MD5: $(cat downloads-cache.tar.gz.md5 | cut -d' ' -f1)
- sstate MD5: $(cat sstate-cache.tar.gz.md5 | cut -d' ' -f1)
EOF

log_info "메타데이터 생성 완료 ✓"

if [ "$DRY_RUN" = true ]; then
    echo ""
    log_info "🎉 업로드 준비 완료!"
    echo ""
    log_info "✅ 준비된 파일들:"
    echo "   📦 downloads-cache.tar.gz ($downloads_size)"
    echo "   📦 sstate-cache.tar.gz ($sstate_size)"
    echo "   🔐 체크섬 파일들 (MD5, SHA256)"
    echo "   📄 cache-info.txt (메타데이터)"
    echo ""
    log_info "🚀 실제 업로드를 실행하려면:"
    echo "   $0 --type [github|ftp|s3|local]"
    exit 0
fi

# 업로드 실행
log_step "5단계: 업로드 실행 중..."

case $UPLOAD_TYPE in
    "github")
        upload_to_github
        ;;
    "ftp")
        upload_to_ftp
        ;;
    "s3")
        upload_to_s3
        ;;
    "local")
        prepare_local_hosting
        ;;
    *)
        log_error "지원하지 않는 업로드 방식: $UPLOAD_TYPE"
        exit 1
        ;;
esac

upload_to_github() {
    log_info "GitHub Release에 업로드 중..."
    
    # GitHub CLI 확인
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh)가 설치되지 않았습니다."
        log_error "설치 방법: https://cli.github.com/"
        exit 1
    fi
    
    # 인증 확인
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI 인증이 필요합니다."
        log_error "실행: gh auth login"
        exit 1
    fi
    
    # 릴리스 태그 생성
    RELEASE_TAG="cache-$(date +%Y%m%d-%H%M%S)"
    
    log_info "릴리스 생성 중: $RELEASE_TAG"
    
    # 릴리스 생성 및 파일 업로드
    gh release create "$RELEASE_TAG" \
        --title "KEA Yocto Cache $(date +%Y-%m-%d)" \
        --notes-file cache-info.txt \
        downloads-cache.tar.gz \
        downloads-cache.tar.gz.md5 \
        downloads-cache.tar.gz.sha256 \
        sstate-cache.tar.gz \
        sstate-cache.tar.gz.md5 \
        sstate-cache.tar.gz.sha256 \
        cache-info.txt
    
    if [ $? -eq 0 ]; then
        log_info "✅ GitHub Release 업로드 완료!"
        log_info "📂 릴리스 URL: https://github.com/$(gh repo view --json owner,name -q '.owner.login + "/" + .name')/releases/tag/$RELEASE_TAG"
    else
        log_error "❌ GitHub Release 업로드 실패"
        exit 1
    fi
}

upload_to_ftp() {
    log_info "FTP 서버에 업로드 중..."
    
    # FTP 설정 확인
    if [ -z "${FTP_HOST:-}" ] || [ -z "${FTP_USER:-}" ] || [ -z "${FTP_PASS:-}" ]; then
        log_error "FTP 설정이 필요합니다:"
        log_error "  export FTP_HOST=your.ftp.server.com"
        log_error "  export FTP_USER=username"
        log_error "  export FTP_PASS=password"
        exit 1
    fi
    
    # lftp 확인
    if ! command -v lftp &> /dev/null; then
        log_error "lftp가 설치되지 않았습니다."
        log_error "설치: sudo apt install lftp"
        exit 1
    fi
    
    # FTP 업로드
    lftp -c "
        set ftp:ssl-allow no
        open ftp://$FTP_USER:$FTP_PASS@$FTP_HOST
        cd /public_html/yocto-cache/
        mput *.tar.gz *.md5 *.sha256 cache-info.txt
        quit
    "
    
    if [ $? -eq 0 ]; then
        log_info "✅ FTP 업로드 완료!"
        log_info "📂 접속 URL: http://$FTP_HOST/yocto-cache/"
    else
        log_error "❌ FTP 업로드 실패"
        exit 1
    fi
}

upload_to_s3() {
    log_info "AWS S3에 업로드 중..."
    
    # AWS CLI 확인
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI가 설치되지 않았습니다."
        log_error "설치 방법: https://aws.amazon.com/cli/"
        exit 1
    fi
    
    # S3 버킷 설정 확인
    if [ -z "${S3_BUCKET:-}" ]; then
        log_error "S3 버킷이 지정되지 않았습니다:"
        log_error "  export S3_BUCKET=your-bucket-name"
        exit 1
    fi
    
    # S3 업로드
    aws s3 cp downloads-cache.tar.gz s3://$S3_BUCKET/yocto-cache/
    aws s3 cp downloads-cache.tar.gz.md5 s3://$S3_BUCKET/yocto-cache/
    aws s3 cp downloads-cache.tar.gz.sha256 s3://$S3_BUCKET/yocto-cache/
    aws s3 cp sstate-cache.tar.gz s3://$S3_BUCKET/yocto-cache/
    aws s3 cp sstate-cache.tar.gz.md5 s3://$S3_BUCKET/yocto-cache/
    aws s3 cp sstate-cache.tar.gz.sha256 s3://$S3_BUCKET/yocto-cache/
    aws s3 cp cache-info.txt s3://$S3_BUCKET/yocto-cache/
    
    if [ $? -eq 0 ]; then
        log_info "✅ S3 업로드 완료!"
        log_info "📂 S3 URL: https://$S3_BUCKET.s3.amazonaws.com/yocto-cache/"
    else
        log_error "❌ S3 업로드 실패"
        exit 1
    fi
}

prepare_local_hosting() {
    log_info "로컬 웹 서버용 준비 중..."
    
    # 웹 서버 디렉토리 생성
    WEB_DIR="./web-cache"
    mkdir -p "$WEB_DIR"
    
    # 파일 복사
    cp downloads-cache.tar.gz "$WEB_DIR/"
    cp downloads-cache.tar.gz.md5 "$WEB_DIR/"
    cp downloads-cache.tar.gz.sha256 "$WEB_DIR/"
    cp sstate-cache.tar.gz "$WEB_DIR/"
    cp sstate-cache.tar.gz.md5 "$WEB_DIR/"
    cp sstate-cache.tar.gz.sha256 "$WEB_DIR/"
    cp cache-info.txt "$WEB_DIR/"
    
    # 간단한 index.html 생성
    cat > "$WEB_DIR/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>KEA Yocto Project 캐시</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>KEA Yocto Project 5.0 LTS 캐시</h1>
    <p>생성 날짜: $(date)</p>
    <h2>다운로드</h2>
    <ul>
        <li><a href="downloads-cache.tar.gz">downloads-cache.tar.gz</a> ($downloads_size)</li>
        <li><a href="sstate-cache.tar.gz">sstate-cache.tar.gz</a> ($sstate_size)</li>
        <li><a href="cache-info.txt">cache-info.txt</a> (사용법)</li>
    </ul>
    <h2>체크섬</h2>
    <ul>
        <li><a href="downloads-cache.tar.gz.md5">downloads MD5</a></li>
        <li><a href="downloads-cache.tar.gz.sha256">downloads SHA256</a></li>
        <li><a href="sstate-cache.tar.gz.md5">sstate MD5</a></li>
        <li><a href="sstate-cache.tar.gz.sha256">sstate SHA256</a></li>
    </ul>
</body>
</html>
EOF
    
    log_info "✅ 로컬 웹 서버 준비 완료!"
    log_info "📂 웹 디렉토리: $WEB_DIR"
    echo ""
    log_info "🌐 로컬 웹 서버 시작 방법:"
    echo "   cd $WEB_DIR && python3 -m http.server 8000"
    echo "   접속 URL: http://localhost:8000"
    echo ""
    log_info "🔧 nginx 설정 예시:"
    echo "   server {"
    echo "       listen 80;"
    echo "       root $(pwd)/$WEB_DIR;"
    echo "       index index.html;"
    echo "   }"
}

echo ""
log_info "🎉 캐시 업로드 완료!"
echo ""
log_info "💡 다음 단계:"
echo "   1. prepare-cache.sh 스크립트에서 새 URL 설정"
echo "   2. 학생들에게 새로운 캐시 URL 공지"
echo "   3. 캐시 효율성 테스트로 검증" 