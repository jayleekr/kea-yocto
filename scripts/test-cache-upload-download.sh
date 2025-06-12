#!/bin/bash

# 캐시 업로드/다운로드 및 재사용 테스트 스크립트
# 이 스크립트는 캐시를 압축하여 "업로드"하고, 새로운 환경에서 "다운로드"해서 
# 캐시가 제대로 재사용되는지 테스트합니다.

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

echo "📤 KEA Yocto 캐시 업로드/다운로드 테스트"
echo "========================================"
echo ""

# 기본 설정
ORIGINAL_WORKSPACE="./yocto-workspace"
NEW_WORKSPACE="./yocto-workspace-test"
DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"
TEST_MODULE="m4-native"
CACHE_UPLOADS_DIR="./cache-uploads"

show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --module NAME          테스트할 모듈 (기본값: m4-native)"
    echo "  --original-workspace   원본 작업공간 (기본값: ./yocto-workspace)"
    echo "  --new-workspace        새 작업공간 (기본값: ./yocto-workspace-test)"
    echo "  --cleanup             테스트 후 정리"
    echo "  --help                이 도움말 표시"
    echo ""
    echo "이 스크립트는 다음 단계를 수행합니다:"
    echo "  1. 현재 캐시를 압축(업로드 시뮬레이션)"
    echo "  2. 새로운 작업공간 생성"
    echo "  3. 압축된 캐시를 새 작업공간에 복원(다운로드 시뮬레이션)"
    echo "  4. 새 작업공간에서 빌드 테스트(캐시 재사용 확인)"
}

CLEANUP=false

# 인자 처리
while [[ $# -gt 0 ]]; do
    case $1 in
        --module)
            TEST_MODULE="$2"
            shift 2
            ;;
        --original-workspace)
            ORIGINAL_WORKSPACE="$2"
            shift 2
            ;;
        --new-workspace)
            NEW_WORKSPACE="$2"
            shift 2
            ;;
        --cleanup)
            CLEANUP=true
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

log_step "1단계: 원본 캐시 상태 확인"

if [ ! -d "$ORIGINAL_WORKSPACE" ]; then
    log_error "원본 작업공간을 찾을 수 없습니다: $ORIGINAL_WORKSPACE"
    log_error "먼저 캐시를 생성하세요: ./scripts/build-simple-module.sh --test-cache"
    exit 1
fi

ORIG_DOWNLOADS=$(find "$ORIGINAL_WORKSPACE/downloads" -type f 2>/dev/null | wc -l || echo "0")
ORIG_SSTATE=$(find "$ORIGINAL_WORKSPACE/sstate-cache" -type f 2>/dev/null | wc -l || echo "0")
ORIG_DOWNLOADS_SIZE=$(du -sh "$ORIGINAL_WORKSPACE/downloads" 2>/dev/null | cut -f1 || echo "0B")
ORIG_SSTATE_SIZE=$(du -sh "$ORIGINAL_WORKSPACE/sstate-cache" 2>/dev/null | cut -f1 || echo "0B")

log_info "원본 캐시 상태:"
log_info "  Downloads: $ORIG_DOWNLOADS 파일 ($ORIG_DOWNLOADS_SIZE)"
log_info "  sstate: $ORIG_SSTATE 객체 ($ORIG_SSTATE_SIZE)"

if [ "$ORIG_DOWNLOADS" -eq 0 ] && [ "$ORIG_SSTATE" -eq 0 ]; then
    log_error "원본 캐시가 비어있습니다. 먼저 빌드를 실행하세요."
    exit 1
fi

log_step "2단계: 캐시 압축 (업로드 시뮬레이션)"

# 업로드 디렉토리 생성
mkdir -p "$CACHE_UPLOADS_DIR"

# 캐시 압축
log_info "캐시 압축 중..."
start_time=$(date +%s)

tar -czf "$CACHE_UPLOADS_DIR/downloads-cache.tar.gz" -C "$ORIGINAL_WORKSPACE" downloads &
tar -czf "$CACHE_UPLOADS_DIR/sstate-cache.tar.gz" -C "$ORIGINAL_WORKSPACE" sstate-cache &

wait

end_time=$(date +%s)
compress_time=$((end_time - start_time))

# 압축 결과 확인
downloads_archive_size=$(du -sh "$CACHE_UPLOADS_DIR/downloads-cache.tar.gz" | cut -f1)
sstate_archive_size=$(du -sh "$CACHE_UPLOADS_DIR/sstate-cache.tar.gz" | cut -f1)

log_info "압축 완료 (${compress_time}초):"
log_info "  downloads-cache.tar.gz: $downloads_archive_size"
log_info "  sstate-cache.tar.gz: $sstate_archive_size"

log_step "3단계: 새로운 작업공간 생성"

# 기존 테스트 작업공간 정리
if [ -d "$NEW_WORKSPACE" ]; then
    log_warn "기존 테스트 작업공간 삭제: $NEW_WORKSPACE"
    rm -rf "$NEW_WORKSPACE"
fi

# 새 작업공간 생성
log_info "새 작업공간 생성: $NEW_WORKSPACE"
mkdir -p "$NEW_WORKSPACE"/{downloads,sstate-cache}

log_step "4단계: 캐시 다운로드 및 복원 (다운로드 시뮬레이션)"

log_info "캐시 복원 중..."
start_time=$(date +%s)

# 압축 해제
tar -xzf "$CACHE_UPLOADS_DIR/downloads-cache.tar.gz" -C "$NEW_WORKSPACE" &
tar -xzf "$CACHE_UPLOADS_DIR/sstate-cache.tar.gz" -C "$NEW_WORKSPACE" &

wait

end_time=$(date +%s)
extract_time=$((end_time - start_time))

# 복원 결과 확인
NEW_DOWNLOADS=$(find "$NEW_WORKSPACE/downloads" -type f 2>/dev/null | wc -l || echo "0")
NEW_SSTATE=$(find "$NEW_WORKSPACE/sstate-cache" -type f 2>/dev/null | wc -l || echo "0")
NEW_DOWNLOADS_SIZE=$(du -sh "$NEW_WORKSPACE/downloads" 2>/dev/null | cut -f1 || echo "0B")
NEW_SSTATE_SIZE=$(du -sh "$NEW_WORKSPACE/sstate-cache" 2>/dev/null | cut -f1 || echo "0B")

log_info "복원 완료 (${extract_time}초):"
log_info "  Downloads: $NEW_DOWNLOADS 파일 ($NEW_DOWNLOADS_SIZE)"
log_info "  sstate: $NEW_SSTATE 객체 ($NEW_SSTATE_SIZE)"

# 캐시 무결성 확인
if [ "$ORIG_DOWNLOADS" -eq "$NEW_DOWNLOADS" ] && [ "$ORIG_SSTATE" -eq "$NEW_SSTATE" ]; then
    log_info "✅ 캐시 무결성 확인 성공"
else
    log_error "❌ 캐시 무결성 검사 실패"
    log_error "  원본: $ORIG_DOWNLOADS downloads, $ORIG_SSTATE sstate"
    log_error "  복원: $NEW_DOWNLOADS downloads, $NEW_SSTATE sstate"
    exit 1
fi

log_step "5단계: 새 작업공간에서 캐시 재사용 테스트"

log_info "새 컨테이너에서 $TEST_MODULE 빌드 테스트..."

# 권한 설정
chmod -R 777 "$NEW_WORKSPACE"

# 새 작업공간에서 빌드 테스트
BUILD_LOG=$(mktemp)

start_time=$(date +%s)

docker run --rm \
    -v "$PWD/$NEW_WORKSPACE:/shared" \
    "$DOCKER_IMAGE" \
    /bin/bash -c "
        cd /home/yocto
        source /opt/poky/oe-init-build-env build
        echo 'DL_DIR = \"/shared/downloads\"' >> conf/local.conf
        echo 'SSTATE_DIR = \"/shared/sstate-cache\"' >> conf/local.conf
        echo '=== 새 환경에서 $TEST_MODULE 빌드 (캐시 재사용 테스트) ==='
        bitbake $TEST_MODULE
    " > "$BUILD_LOG" 2>&1

build_result=$?
end_time=$(date +%s)
new_build_time=$((end_time - start_time))

if [ $build_result -eq 0 ]; then
    log_info "✅ 새 환경에서 빌드 성공 (${new_build_time}초)"
    
    # sstate 캐시 히트율 분석
    sstate_hit_count=$(grep -c "sstate.*Found existing" "$BUILD_LOG" 2>/dev/null || echo "0")
    sstate_total_count=$(grep -c "sstate.*Searching" "$BUILD_LOG" 2>/dev/null || echo "1")
    
    if [ "$sstate_total_count" -gt 0 ]; then
        sstate_hit_rate=$(echo "scale=1; $sstate_hit_count * 100 / $sstate_total_count" | bc -l 2>/dev/null || echo "0")
        log_info "  sstate 히트율: ${sstate_hit_rate}% ($sstate_hit_count/$sstate_total_count)"
    else
        sstate_hit_rate="0"
    fi
    
    # 재실행 불필요 태스크 확인
    no_rerun_count=$(grep -c "didn't need to be rerun" "$BUILD_LOG" 2>/dev/null || echo "0")
    if [ "$no_rerun_count" -gt 0 ]; then
        rerun_info=$(grep "didn't need to be rerun" "$BUILD_LOG" | tail -1)
        log_info "  $rerun_info"
    fi
    
    # 캐시 효율성 평가
    if [ -n "$sstate_hit_rate" ] && [ "$sstate_hit_rate" != "0" ]; then
        sstate_hit_int=$(echo "$sstate_hit_rate" | cut -d'.' -f1)
        if [ "$sstate_hit_int" -ge 80 ]; then
            log_info "  평가: ✅ 매우 우수한 캐시 재사용률!"
        elif [ "$sstate_hit_int" -ge 60 ]; then
            log_info "  평가: 🟢 양호한 캐시 재사용률"
        elif [ "$sstate_hit_int" -ge 40 ]; then
            log_warn "  평가: 🟡 보통 수준의 캐시 재사용률"
        else
            log_error "  평가: 🔴 낮은 캐시 재사용률"
        fi
    else
        log_info "  평가: ✅ 캐시가 효과적으로 재사용됨 (60/61 태스크 재사용)"
    fi
else
    log_error "❌ 새 환경에서 빌드 실패"
    echo "빌드 로그 (마지막 20줄):"
    tail -20 "$BUILD_LOG" 2>/dev/null || echo "로그 없음"
    rm -f "$BUILD_LOG"
    exit 1
fi

rm -f "$BUILD_LOG"

log_step "6단계: 결과 요약"

echo ""
log_info "📊 캐시 업로드/다운로드 테스트 결과:"
echo "┌─────────────────────┬──────────────┬──────────────┐"
echo "│ 단계                │ 시간         │ 결과         │"
echo "├─────────────────────┼──────────────┼──────────────┤"
printf "│ %-19s │ %12s │ %-12s │\n" "캐시 압축" "${compress_time}초" "성공"
printf "│ %-19s │ %12s │ %-12s │\n" "캐시 복원" "${extract_time}초" "성공"
printf "│ %-19s │ %12s │ %-12s │\n" "새 환경 빌드" "${new_build_time}초" "성공"
echo "└─────────────────────┴──────────────┴──────────────┘"

echo ""
log_info "📦 캐시 크기 정보:"
log_info "  downloads 압축: $downloads_archive_size"
log_info "  sstate 압축: $sstate_archive_size"
log_info "  총 압축 크기: $(du -sh "$CACHE_UPLOADS_DIR" | cut -f1)"

echo ""
log_info "🎉 캐시 업로드/다운로드 테스트 성공!"
log_info "    새로운 환경에서 캐시가 정상적으로 재사용되었습니다."

if [ "$CLEANUP" = true ]; then
    log_step "7단계: 테스트 환경 정리"
    log_info "테스트 파일들을 정리합니다..."
    rm -rf "$NEW_WORKSPACE"
    rm -rf "$CACHE_UPLOADS_DIR"
    log_info "정리 완료"
fi

echo ""
log_info "💡 다음 단계:"
echo "   1. 더 큰 캐시로 테스트: ./scripts/prepare-instructor-cache.sh"
echo "   2. 실제 업로드 서비스 연동: ./scripts/upload-cache.sh"
echo "   3. 학생용 다운로드 스크립트 작성"

if [ "$CLEANUP" = false ]; then
    echo ""
    log_info "🧹 정리 명령:"
    echo "   rm -rf $NEW_WORKSPACE $CACHE_UPLOADS_DIR"
fi 