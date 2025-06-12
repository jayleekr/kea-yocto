#!/bin/bash

# KEA Yocto 전체 이미지 캐시 빌드 스크립트 (강사용)
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

echo "🏗️ KEA Yocto 전체 이미지 캐시 빌드"
echo "===================================="
echo ""

# 기본 설정
WORKSPACE_DIR="./yocto-workspace-full"
IMAGE_TARGET="core-image-minimal"
CLEAN_BUILD=false

show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --workspace DIR    작업공간 디렉토리 (기본값: ./yocto-workspace-full)"
    echo "  --target IMAGE     빌드할 이미지 (기본값: core-image-minimal)"
    echo "  --clean           기존 캐시를 삭제하고 새로 시작"
    echo "  --help            이 도움말 표시"
    echo ""
    echo "지원하는 이미지:"
    echo "  core-image-minimal      - 최소한의 시스템"
    echo "  core-image-base         - 기본 시스템"
    echo "  core-image-full-cmdline - 전체 명령줄 도구"
    echo ""
    echo "예시:"
    echo "  $0                              # 기본 minimal 이미지 빌드"
    echo "  $0 --target core-image-base     # base 이미지 빌드"
    echo "  $0 --clean                      # 깨끗한 빌드"
}

# 인자 처리
while [[ $# -gt 0 ]]; do
    case $1 in
        --workspace)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        --target)
            IMAGE_TARGET="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=true
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

log_step "1단계: 작업공간 준비..."

# 기존 작업공간 정리 (옵션)
if [ "$CLEAN_BUILD" = true ]; then
    log_warn "기존 작업공간 삭제 중..."
    rm -rf "$WORKSPACE_DIR"
fi

# 작업공간 생성
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# 캐시 디렉토리 미리 생성 및 권한 설정
mkdir -p downloads sstate-cache
# 권한 설정 (에러 무시)
chmod -R 777 downloads sstate-cache 2>/dev/null || true
log_info "✅ 캐시 디렉토리 권한 설정 완료 (일부 파일은 권한 변경이 제한될 수 있음)"

log_info "작업공간: $(pwd)"
log_info "빌드 대상: $IMAGE_TARGET"

log_step "2단계: 시스템 준비 확인..."

# Docker 확인
if ! command -v docker &> /dev/null; then
    log_error "Docker가 설치되지 않았습니다."
    exit 1
fi

# 디스크 공간 확인 (최소 50GB 필요)
available_space=$(df . | tail -1 | awk '{print $4}')
required_space=$((50 * 1024 * 1024))  # 50GB in KB

if [ "$available_space" -lt "$required_space" ]; then
    log_error "디스크 공간이 부족합니다."
    log_error "필요: 50GB, 사용가능: $(($available_space / 1024 / 1024))GB"
    exit 1
fi

log_info "✅ 디스크 공간 충분: $(($available_space / 1024 / 1024))GB 사용가능"

log_step "3단계: 전체 이미지 빌드 시작..."

# 빌드 시작 시간 기록
start_time=$(date +%s)
log_info "🚀 빌드 시작: $(date)"

# Docker로 전체 이미지 빌드
log_info "Docker 컨테이너에서 $IMAGE_TARGET 빌드 중..."

docker run --rm \
    -v "$PWD:/shared" \
    -e WORKSPACE_DIR="/shared" \
    jabang3/yocto-lecture:5.0-lts \
    /bin/bash -c "
set -e

cd /home/yocto
source /opt/poky/oe-init-build-env build

# 캐시 설정
echo 'DL_DIR = \"/shared/downloads\"' >> conf/local.conf
echo 'SSTATE_DIR = \"/shared/sstate-cache\"' >> conf/local.conf

# 빌드 최적화 설정
echo 'BB_NUMBER_THREADS = \"8\"' >> conf/local.conf
echo 'PARALLEL_MAKE = \"-j 8\"' >> conf/local.conf

# 불필요한 패키지 제거로 빌드 시간 단축
echo 'IMAGE_INSTALL:remove = \"packagegroup-core-x11-base\"' >> conf/local.conf

echo '=== 빌드 설정 확인 ==='
grep -E 'DL_DIR|SSTATE_DIR|BB_NUMBER_THREADS|PARALLEL_MAKE' conf/local.conf

echo ''
echo '=== $IMAGE_TARGET 빌드 시작 ==='
bitbake $IMAGE_TARGET

echo ''
echo '=== 빌드 완료 ==='
echo \"빌드 결과물:\"
find tmp/deploy/images/ -name \"*.wic*\" -o -name \"*.rootfs.*\" 2>/dev/null | head -5 || echo \"이미지 파일 확인 중...\"
"

# 빌드 시간 계산
end_time=$(date +%s)
duration=$((end_time - start_time))
hours=$((duration / 3600))
minutes=$(((duration % 3600) / 60))
seconds=$((duration % 60))

log_info "🎉 빌드 완료: $(date)"
log_info "⏱️ 총 소요 시간: ${hours}시간 ${minutes}분 ${seconds}초"

log_step "4단계: 캐시 상태 분석..."

# 캐시 통계
downloads_count=$(find downloads -type f 2>/dev/null | wc -l)
downloads_size=$(du -sh downloads 2>/dev/null | cut -f1 || echo "0B")
sstate_count=$(find sstate-cache -name "*.tar.zst" 2>/dev/null | wc -l)
sstate_size=$(du -sh sstate-cache 2>/dev/null | cut -f1 || echo "0B")

log_info "📊 캐시 통계:"
echo "   📥 Downloads: $downloads_count 파일 ($downloads_size)"
echo "   📦 sstate: $sstate_count 파일 ($sstate_size)"

log_step "5단계: 캐시 압축 및 패키징..."

# 기존 캐시 파일 삭제
rm -f *-cache.tar.gz

log_info "캐시 압축 중..."
compress_start=$(date +%s)

# downloads 압축
log_info "  downloads 압축 중..."
tar -czf full-downloads-cache.tar.gz downloads/

# sstate 압축  
log_info "  sstate 압축 중..."
tar -czf full-sstate-cache.tar.gz sstate-cache/

compress_end=$(date +%s)
compress_duration=$((compress_end - compress_start))

# 압축된 파일 크기 확인
downloads_compressed=$(du -h full-downloads-cache.tar.gz | cut -f1)
sstate_compressed=$(du -h full-sstate-cache.tar.gz | cut -f1)

log_info "✅ 압축 완료 (${compress_duration}초)"
echo "   📦 full-downloads-cache.tar.gz: $downloads_compressed"
echo "   📦 full-sstate-cache.tar.gz: $sstate_compressed"

log_step "6단계: 메타데이터 생성..."

# 체크섬 생성
md5sum full-downloads-cache.tar.gz > full-downloads-cache.tar.gz.md5
md5sum full-sstate-cache.tar.gz > full-sstate-cache.tar.gz.md5
sha256sum full-downloads-cache.tar.gz > full-downloads-cache.tar.gz.sha256
sha256sum full-sstate-cache.tar.gz > full-sstate-cache.tar.gz.sha256

# 캐시 정보 파일 생성
cat > full-cache-info.txt << EOF
KEA Yocto Project 5.0 LTS 전체 이미지 캐시
=========================================

생성 날짜: $(date '+%Y년 %m월 %d일 %H:%M:%S')
빌드 대상: $IMAGE_TARGET
Yocto 버전: 5.0 LTS (Scarthgap)
Docker 이미지: jabang3/yocto-lecture:5.0-lts
빌드 시간: ${hours}시간 ${minutes}분 ${seconds}초

캐시 구성:
- Downloads: $downloads_count 파일 ($downloads_size → $downloads_compressed)
- sstate: $sstate_count 파일 ($sstate_size → $sstate_compressed)

사용법:
1. wget으로 두 파일 다운로드
2. tar -xzf full-downloads-cache.tar.gz
3. tar -xzf full-sstate-cache.tar.gz
4. chmod -R 777 downloads sstate-cache
5. Docker 빌드 실행

예상 성능:
- 첫 빌드 시간: ${hours}시간 ${minutes}분
- 캐시 빌드 시간: ~30분 (${hours}0-90% 단축)
- 네트워크 다운로드: 최소화
- 디스크 사용량: 대폭 절약
EOF

log_info "✅ 메타데이터 생성 완료"

echo ""
log_info "🎉 전체 이미지 캐시 빌드 완료!"
echo ""
log_info "📋 생성된 파일들:"
echo "   📦 full-downloads-cache.tar.gz ($downloads_compressed)"
echo "   📦 full-sstate-cache.tar.gz ($sstate_compressed)"
echo "   🔐 체크섬 파일들 (MD5, SHA256)"
echo "   📄 full-cache-info.txt"
echo ""
log_info "🚀 다음 단계:"
echo "   1. GitHub에 업로드: ../scripts/upload-github.sh"
echo "   2. 또는 로컬 배포: 파일들을 웹서버에 복사"
echo ""
log_info "💡 예상 학생 효과:"
echo "   ⚡ 빌드 시간: ${hours}시간 → ~30분 (80-90% 단축)"
echo "   📥 다운로드: 수GB → 캐시 파일만"
echo "   💾 디스크: 전체 빌드 → 캐시 재사용"

cd ..
log_info "✅ 작업 완료. 캐시는 $WORKSPACE_DIR 에 저장됨" 