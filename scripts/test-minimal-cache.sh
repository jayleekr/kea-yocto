#!/bin/bash

# 최소한의 네이티브 도구로 캐시 효율성 빠른 테스트
# 가장 기본적인 native 패키지들만 테스트하여 빠르게 캐시 동작을 확인합니다.

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

echo "⚡ KEA Yocto 최소 캐시 테스트 (빠른 검증)"
echo "========================================"
echo ""

# 기본 설정
WORKSPACE_DIR="./yocto-workspace"
DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"
# 빠르게 빌드되는 네이티브 도구들만 선택
TEST_PACKAGES=("m4-native" "autoconf-native" "pkgconfig-native")
TIMEOUT=300  # 5분 타임아웃

show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --workspace DIR     작업공간 디렉토리 (기본값: ./yocto-workspace)"
    echo "  --timeout SECONDS   각 빌드 타임아웃 (기본값: 300초)"
    echo "  --help             이 도움말 표시"
    echo ""
    echo "이 스크립트는 가장 빠르게 빌드되는 네이티브 도구들로만 테스트합니다:"
    echo "  m4-native, autoconf-native, pkgconfig-native"
    echo ""
    echo "예시:"
    echo "  $0                    # 기본 설정으로 빠른 테스트"
    echo "  $0 --timeout 180     # 3분 타임아웃으로 테스트"
}

# 인자 처리
while [[ $# -gt 0 ]]; do
    case $1 in
        --workspace)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
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

log_step "1단계: 테스트 환경 확인 중..."

# Docker 확인
if ! command -v docker &> /dev/null; then
    log_error "Docker가 설치되지 않았습니다."
    exit 1
fi

# 작업공간 확인
if [ ! -d "$WORKSPACE_DIR" ]; then
    log_error "작업공간을 찾을 수 없습니다: $WORKSPACE_DIR"
    log_error "먼저 ./scripts/prepare-instructor-cache.sh를 실행하세요."
    exit 1
fi

log_info "테스트 설정:"
log_info "  작업공간: $WORKSPACE_DIR"
log_info "  테스트 패키지: ${TEST_PACKAGES[*]}"
log_info "  빌드 타임아웃: ${TIMEOUT}초"

# 캐시 초기 상태 확인
log_step "2단계: 캐시 초기 상태 확인 중..."

INITIAL_DOWNLOADS=$(find "$WORKSPACE_DIR/downloads" -type f 2>/dev/null | wc -l || echo "0")
INITIAL_SSTATE=$(find "$WORKSPACE_DIR/sstate-cache" -type f 2>/dev/null | wc -l || echo "0")

log_info "초기 캐시 상태:"
log_info "  Downloads 파일: $INITIAL_DOWNLOADS"
log_info "  sstate 객체: $INITIAL_SSTATE"

# 빌드 함수
build_package() {
    local package=$1
    local iteration=$2
    local clean_first=$3
    
    log_info "[$iteration/2] $package 빌드 시작..."
    
    # 빌드 시작 시간
    start_time=$(date +%s)
    
    # Docker 컨테이너에서 패키지 빌드
    BUILD_LOG=$(mktemp)
    
    # 첫 번째 빌드는 cleanall로 시작 (캐시 없이)
    if [ "$clean_first" = true ]; then
        CLEAN_CMD="bitbake -c cleanall $package && "
        log_info "  캐시 없이 클린 빌드 실행 중..."
    else
        CLEAN_CMD=""
        log_info "  캐시 사용 빌드 실행 중..."
    fi
    
    # 타임아웃과 함께 빌드 실행
    timeout $TIMEOUT docker run --rm \
        -v "$PWD/$WORKSPACE_DIR:/workdir" \
        -w /workdir \
        "$DOCKER_IMAGE" \
        /bin/bash -c "
            source /opt/poky/oe-init-build-env build 2>/dev/null
            export DL_DIR=/workdir/downloads
            export SSTATE_DIR=/workdir/sstate-cache
            ${CLEAN_CMD}bitbake $package
        " > "$BUILD_LOG" 2>&1
    
    build_result=$?
    end_time=$(date +%s)
    build_time=$((end_time - start_time))
    
    if [ $build_result -eq 0 ]; then
        log_info "✅ [$iteration/2] $package 빌드 완료 (${build_time}초)"
        
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
        
        rm -f "$BUILD_LOG"
        echo "$build_time"
        return 0
    elif [ $build_result -eq 124 ]; then
        log_error "❌ [$iteration/2] $package 빌드 타임아웃 (${TIMEOUT}초 초과)"
        rm -f "$BUILD_LOG"
        echo "0"
        return 1
    else
        log_error "❌ [$iteration/2] $package 빌드 실패"
        echo "빌드 로그 (마지막 10줄):"
        tail -10 "$BUILD_LOG" 2>/dev/null || echo "로그 없음"
        rm -f "$BUILD_LOG"
        echo "0"
        return 1
    fi
}

# 각 패키지별 테스트
declare -A RESULTS
successful_tests=0

for package in "${TEST_PACKAGES[@]}"; do
    log_step "3단계: $package 패키지 테스트 중..."
    
    # 첫 번째 빌드 (캐시 없이)
    first_time=$(build_package "$package" 1 true)
    
    if [ "$first_time" -gt 0 ]; then
        # 잠시 대기
        sleep 2
        
        # 두 번째 빌드 (캐시 사용)
        second_time=$(build_package "$package" 2 false)
        
        if [ "$second_time" -gt 0 ]; then
            # 결과 분석
            if [ "$first_time" -gt "$second_time" ]; then
                speedup=$(echo "scale=2; $first_time / $second_time" | bc -l)
                time_saved=$((first_time - second_time))
                efficiency=$(echo "scale=1; (1 - $second_time / $first_time) * 100" | bc -l)
                
                log_info "📊 $package 결과:"
                log_info "  첫 빌드: ${first_time}초"
                log_info "  두 번째 빌드: ${second_time}초"
                log_info "  속도 향상: ${speedup}배"
                log_info "  시간 절약: ${time_saved}초"
                log_info "  효율성: ${efficiency}%"
                
                # 효율성 평가
                efficiency_int=${efficiency%.*}
                if [ "$efficiency_int" -ge 80 ]; then
                    log_info "  평가: ✅ 매우 우수"
                elif [ "$efficiency_int" -ge 60 ]; then
                    log_info "  평가: 🟢 양호"
                elif [ "$efficiency_int" -ge 40 ]; then
                    log_info "  평가: 🟡 보통"
                else
                    log_info "  평가: 🔴 개선 필요"
                fi
                
                RESULTS["$package"]="$efficiency"
                ((successful_tests++))
            else
                log_warn "⚠️  $package: 두 번째 빌드가 더 오래 걸림 (캐시 문제 가능성)"
                RESULTS["$package"]="0"
            fi
        else
            log_error "❌ $package: 두 번째 빌드 실패"
            RESULTS["$package"]="0"
        fi
    else
        log_error "❌ $package: 첫 번째 빌드 실패"
        RESULTS["$package"]="0"
    fi
    
    echo ""
done

# 최종 캐시 상태 확인
log_step "4단계: 최종 캐시 상태 확인 중..."

FINAL_DOWNLOADS=$(find "$WORKSPACE_DIR/downloads" -type f 2>/dev/null | wc -l || echo "0")
FINAL_SSTATE=$(find "$WORKSPACE_DIR/sstate-cache" -type f 2>/dev/null | wc -l || echo "0")

NEW_DOWNLOADS=$((FINAL_DOWNLOADS - INITIAL_DOWNLOADS))
NEW_SSTATE=$((FINAL_SSTATE - INITIAL_SSTATE))

log_info "최종 캐시 상태:"
log_info "  Downloads 파일: $FINAL_DOWNLOADS (+$NEW_DOWNLOADS)"
log_info "  sstate 객체: $FINAL_SSTATE (+$NEW_SSTATE)"

# 전체 결과 요약
log_step "5단계: 전체 결과 요약"

echo ""
log_info "📊 패키지별 캐시 효율성 요약:"
echo "┌─────────────────┬──────────────┬──────────┐"
echo "│ 패키지          │ 효율성(%)    │ 평가     │"
echo "├─────────────────┼──────────────┼──────────┤"

total_efficiency=0

for package in "${TEST_PACKAGES[@]}"; do
    efficiency=${RESULTS[$package]}
    
    # 효율성 평가 아이콘
    if [ "$efficiency" != "0" ]; then
        efficiency_int=${efficiency%.*}
        if [ "$efficiency_int" -ge 80 ]; then
            rating="✅ 우수"
        elif [ "$efficiency_int" -ge 60 ]; then
            rating="🟢 양호"
        elif [ "$efficiency_int" -ge 40 ]; then
            rating="🟡 보통"
        else
            rating="🔴 개선필요"
        fi
        
        total_efficiency=$(echo "$total_efficiency + $efficiency" | bc -l)
    else
        rating="❌ 실패"
    fi
    
    printf "│ %-15s │ %12s │ %-8s │\n" "$package" "$efficiency" "$rating"
done

echo "└─────────────────┴──────────────┴──────────┘"

if [ "$successful_tests" -gt 0 ]; then
    average_efficiency=$(echo "scale=1; $total_efficiency / $successful_tests" | bc -l)
    log_info "평균 캐시 효율성: ${average_efficiency}% ($successful_tests/${#TEST_PACKAGES[@]} 패키지 성공)"
    
    # 전체 평가
    avg_int=${average_efficiency%.*}
    if [ "$avg_int" -ge 80 ]; then
        log_info "🎉 전체 평가: 매우 우수한 캐시 성능!"
        cache_status="excellent"
    elif [ "$avg_int" -ge 60 ]; then
        log_info "✅ 전체 평가: 양호한 캐시 성능"
        cache_status="good"
    elif [ "$avg_int" -ge 40 ]; then
        log_warn "🟡 전체 평가: 보통 수준의 캐시 성능"
        cache_status="average"
    else
        log_error "🔴 전체 평가: 캐시 성능 개선 필요"
        cache_status="poor"
    fi
else
    log_error "모든 패키지 테스트가 실패했습니다."
    cache_status="failed"
    exit 1
fi

echo ""
log_info "💡 권장사항:"
case $cache_status in
    "excellent"|"good")
        echo "   ✅ 캐시가 잘 작동하고 있습니다."
        echo "   ✅ 더 복잡한 패키지나 이미지 빌드를 테스트해볼 수 있습니다."
        echo "   ✅ 학생들에게 배포할 준비가 되었습니다."
        ;;
    "average")
        echo "   🔧 캐시 성능이 보통 수준입니다:"
        echo "   1. Docker 볼륨 마운트 확인"
        echo "   2. sstate-cache 디렉토리 권한 확인"
        echo "   3. 더 많은 패키지로 테스트 필요"
        ;;
    "poor")
        echo "   🔧 캐시 성능 개선이 필요합니다:"
        echo "   1. sstate-cache 디렉토리 권한 확인: ls -la $WORKSPACE_DIR/"
        echo "   2. Docker 볼륨 마운트 확인"
        echo "   3. 네트워크 연결 상태 확인"
        echo "   4. 캐시 재생성 고려"
        ;;
esac

echo ""
log_info "🔄 다음 단계:"
if [ "$cache_status" = "excellent" ] || [ "$cache_status" = "good" ]; then
    echo "   1. 더 복잡한 패키지 테스트: ./scripts/test-simple-cache.sh"
    echo "   2. 전체 이미지 빌드 테스트: ./scripts/quick-cache-test.sh"
    echo "   3. 캐시 업로드 준비: ./scripts/upload-cache.sh --dry-run"
else
    echo "   1. 캐시 문제 진단: ./scripts/complete-instructor-setup.sh --skip-test"
    echo "   2. 권한 확인: sudo chown -R \$USER:\$USER $WORKSPACE_DIR"
    echo "   3. 캐시 재생성: rm -rf $WORKSPACE_DIR && ./scripts/prepare-instructor-cache.sh"
fi

echo ""
log_info "⚡ 빠른 테스트 완료! (총 소요시간: 약 $(($(date +%s) - $(date +%s)))초)" 