#!/bin/bash

# 간단한 모듈 빌드 및 캐시 테스트 스크립트
# 전체 이미지 대신 빠르게 빌드되는 모듈로 캐시 효율성을 테스트합니다.

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

echo "🔧 KEA Yocto 간단한 모듈 빌드 및 캐시 테스트"
echo "============================================="
echo ""

# 기본 설정
WORKSPACE_DIR="./yocto-workspace"
DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"
TARGET_MODULE="busybox"
CLEAN_BUILD=false
TEST_CACHE=false

show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --module NAME       빌드할 모듈 (기본값: busybox)"
    echo "  --workspace DIR     작업공간 디렉토리 (기본값: ./yocto-workspace)"
    echo "  --clean            클린 빌드 (캐시 무시)"
    echo "  --test-cache       캐시 효율성 테스트 (2회 빌드)"
    echo "  --help             이 도움말 표시"
    echo ""
    echo "추천 모듈 (빠른 빌드):"
    echo "  busybox, zlib, m4-native, autoconf-native, pkgconfig-native"
    echo ""
    echo "예시:"
    echo "  $0                           # busybox 빌드"
    echo "  $0 --module zlib            # zlib 빌드"
    echo "  $0 --test-cache             # 캐시 효율성 테스트"
    echo "  $0 --clean --module busybox # busybox 클린 빌드"
}

# 인자 처리
while [[ $# -gt 0 ]]; do
    case $1 in
        --module)
            TARGET_MODULE="$2"
            shift 2
            ;;
        --workspace)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --test-cache)
            TEST_CACHE=true
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

log_step "1단계: 환경 확인 중..."

# Docker 확인
if ! command -v docker &> /dev/null; then
    log_error "Docker가 설치되지 않았습니다."
    exit 1
fi

# 작업공간 생성
if [ ! -d "$WORKSPACE_DIR" ]; then
    log_info "작업공간 생성: $WORKSPACE_DIR"
    mkdir -p "$WORKSPACE_DIR"/{downloads,sstate-cache}
fi

log_info "설정:"
log_info "  모듈: $TARGET_MODULE"
log_info "  작업공간: $WORKSPACE_DIR"
log_info "  클린 빌드: $CLEAN_BUILD"
log_info "  캐시 테스트: $TEST_CACHE"

# 빌드 함수
build_module() {
    local module=$1
    local clean=$2
    local iteration=${3:-1}
    
    log_info "[$iteration] $module 빌드 시작..."
    
    # 빌드 시작 시간
    start_time=$(date +%s)
    
    # 클린 명령 설정
    if [ "$clean" = true ]; then
        CLEAN_CMD="bitbake -c cleanall $module && "
        log_info "  클린 빌드 실행 중..."
    else
        CLEAN_CMD=""
        log_info "  캐시 사용 빌드 실행 중..."
    fi
    
    # Docker 컨테이너에서 빌드 실행
    BUILD_LOG=$(mktemp)
    
    docker run --rm \
        -v "$PWD/$WORKSPACE_DIR/downloads:/workdir/downloads" \
        -v "$PWD/$WORKSPACE_DIR/sstate-cache:/workdir/sstate-cache" \
        -w /workdir \
        "$DOCKER_IMAGE" \
        /bin/bash -c "
            set -eo pipefail
            # Yocto 환경 설정
            source /opt/poky/oe-init-build-env build 2>/dev/null
            
            # 캐시 디렉토리 설정
            export DL_DIR=/workdir/downloads
            export SSTATE_DIR=/workdir/sstate-cache
            
            # 빌드 시작 시간 기록
            echo '🚀 $module 빌드 시작: \$(date)'
            
            # 빌드 실행
            ${CLEAN_CMD}bitbake $module
            
            echo '✅ $module 빌드 완료: \$(date)'
        " > "$BUILD_LOG" 2>&1
    
    build_result=$?
    end_time=$(date +%s)
    build_time=$((end_time - start_time))
    
    if [ $build_result -eq 0 ]; then
        log_info "✅ [$iteration] $module 빌드 완료 (${build_time}초)"
        
        # 빌드 로그 분석
        if [ -f "$BUILD_LOG" ]; then
            # sstate 캐시 히트율 분석
            sstate_hit_count=$(grep -c "sstate.*Found existing" "$BUILD_LOG" 2>/dev/null || echo "0")
            sstate_total_count=$(grep -c "sstate.*Searching" "$BUILD_LOG" 2>/dev/null || echo "1")
            
            if [ "$sstate_total_count" -gt 0 ]; then
                sstate_hit_rate=$(echo "scale=1; $sstate_hit_count * 100 / $sstate_total_count" | bc -l 2>/dev/null || echo "0")
                log_info "  sstate 히트율: ${sstate_hit_rate}% ($sstate_hit_count/$sstate_total_count)"
            fi
            
            # 태스크 실행 정보
            task_count=$(grep -c "Running task" "$BUILD_LOG" 2>/dev/null || echo "0")
            log_info "  실행된 태스크: $task_count 개"
            
            # 다운로드 정보
            download_count=$(grep -c "Fetching" "$BUILD_LOG" 2>/dev/null || echo "0")
            if [ "$download_count" -gt 0 ]; then
                log_info "  새로운 다운로드: $download_count 개"
            fi
        fi
        
        rm -f "$BUILD_LOG"
        echo "$build_time"
        return 0
    else
        log_error "❌ [$iteration] $module 빌드 실패"
        echo "빌드 로그 (마지막 20줄):"
        tail -20 "$BUILD_LOG" 2>/dev/null || echo "로그 없음"
        rm -f "$BUILD_LOG"
        echo "0"
        return 1
    fi
}

# 캐시 상태 확인 함수
check_cache_status() {
    local downloads_count=$(find "$WORKSPACE_DIR/downloads" -type f 2>/dev/null | wc -l || echo "0")
    local sstate_count=$(find "$WORKSPACE_DIR/sstate-cache" -type f 2>/dev/null | wc -l || echo "0")
    local downloads_size=$(du -sh "$WORKSPACE_DIR/downloads" 2>/dev/null | cut -f1 || echo "0B")
    local sstate_size=$(du -sh "$WORKSPACE_DIR/sstate-cache" 2>/dev/null | cut -f1 || echo "0B")
    
    log_info "캐시 상태:"
    log_info "  Downloads: $downloads_count 파일 ($downloads_size)"
    log_info "  sstate: $sstate_count 객체 ($sstate_size)"
}

# 2단계: 초기 캐시 상태 확인
log_step "2단계: 초기 캐시 상태 확인 중..."
check_cache_status

# 3단계: 빌드 실행
if [ "$TEST_CACHE" = true ]; then
    log_step "3단계: 캐시 효율성 테스트 실행 중..."
    
    # 첫 번째 빌드 (클린)
    first_time=$(build_module "$TARGET_MODULE" true 1)
    
    if [ "$first_time" -gt 0 ]; then
        echo ""
        log_step "중간 캐시 상태 확인..."
        check_cache_status
        echo ""
        
        # 잠시 대기
        sleep 2
        
        # 두 번째 빌드 (캐시 사용)
        second_time=$(build_module "$TARGET_MODULE" false 2)
        
        if [ "$second_time" -gt 0 ]; then
            # 결과 분석
            if [ "$first_time" -gt "$second_time" ]; then
                speedup=$(echo "scale=2; $first_time / $second_time" | bc -l)
                time_saved=$((first_time - second_time))
                efficiency=$(echo "scale=1; (1 - $second_time / $first_time) * 100" | bc -l)
                
                echo ""
                log_step "4단계: 캐시 효율성 분석 결과"
                log_info "📊 $TARGET_MODULE 캐시 효율성:"
                log_info "  첫 빌드 시간: ${first_time}초"
                log_info "  두 번째 빌드 시간: ${second_time}초"
                log_info "  속도 향상: ${speedup}배"
                log_info "  시간 절약: ${time_saved}초"
                log_info "  효율성: ${efficiency}%"
                
                # 효율성 평가
                efficiency_int=${efficiency%.*}
                if [ "$efficiency_int" -ge 80 ]; then
                    log_info "  평가: ✅ 매우 우수한 캐시 성능!"
                elif [ "$efficiency_int" -ge 60 ]; then
                    log_info "  평가: 🟢 양호한 캐시 성능"
                elif [ "$efficiency_int" -ge 40 ]; then
                    log_warn "  평가: 🟡 보통 수준의 캐시 성능"
                else
                    log_error "  평가: 🔴 캐시 성능 개선 필요"
                fi
            else
                log_warn "⚠️  두 번째 빌드가 더 오래 걸렸습니다. 캐시 설정을 확인하세요."
            fi
        else
            log_error "두 번째 빌드에 실패했습니다."
            exit 1
        fi
    else
        log_error "첫 번째 빌드에 실패했습니다."
        exit 1
    fi
else
    log_step "3단계: $TARGET_MODULE 빌드 실행 중..."
    
    build_time=$(build_module "$TARGET_MODULE" "$CLEAN_BUILD")
    
    if [ "$build_time" -gt 0 ]; then
        log_info "✅ 빌드 완료! (총 소요시간: ${build_time}초)"
    else
        log_error "빌드에 실패했습니다."
        exit 1
    fi
fi

# 최종 캐시 상태 확인
echo ""
log_step "최종 캐시 상태 확인..."
check_cache_status

echo ""
log_info "🎉 작업 완료!"
echo ""
log_info "💡 다음 단계:"
if [ "$TEST_CACHE" = true ]; then
    echo "   1. 다른 모듈 테스트: $0 --module zlib --test-cache"
    echo "   2. 전체 이미지 빌드: ./scripts/prepare-instructor-cache.sh"
    echo "   3. 캐시 업로드 준비: ./scripts/upload-cache.sh --dry-run"
else
    echo "   1. 캐시 효율성 테스트: $0 --test-cache"
    echo "   2. 다른 모듈 빌드: $0 --module zlib"
    echo "   3. 전체 이미지 빌드: ./scripts/prepare-instructor-cache.sh"
fi 