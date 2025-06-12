#!/bin/bash

# 간단한 모듈 빌드로 캐시 효율성 빠른 테스트
# 전체 이미지 대신 개별 패키지를 빌드하여 캐시 재사용률을 확인합니다.

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

echo "🧪 KEA Yocto 간단한 모듈 캐시 테스트"
echo "===================================="
echo ""

# 기본 설정
WORKSPACE_DIR="./yocto-workspace"
DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"
TEST_PACKAGES=("busybox" "zlib" "openssl" "glibc" "gcc-runtime")
ITERATIONS=2
OUTPUT_FILE=""
VERBOSE=false

show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --workspace DIR     작업공간 디렉토리 (기본값: ./yocto-workspace)"
    echo "  --packages LIST     테스트할 패키지 목록 (쉼표로 구분)"
    echo "  --iterations N      반복 빌드 횟수 (기본값: 2)"
    echo "  --output FILE       결과를 JSON 파일로 저장"
    echo "  --verbose          상세 로그 출력"
    echo "  --help             이 도움말 표시"
    echo ""
    echo "기본 테스트 패키지:"
    echo "  busybox, zlib, openssl, glibc, gcc-runtime"
    echo ""
    echo "예시:"
    echo "  $0                                    # 기본 설정으로 테스트"
    echo "  $0 --packages busybox,zlib           # 특정 패키지만 테스트"
    echo "  $0 --iterations 3 --verbose         # 3회 반복, 상세 로그"
    echo "  $0 --output cache_test.json          # 결과를 JSON으로 저장"
}

# 인자 처리
while [[ $# -gt 0 ]]; do
    case $1 in
        --workspace)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        --packages)
            IFS=',' read -ra TEST_PACKAGES <<< "$2"
            shift 2
            ;;
        --iterations)
            ITERATIONS="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
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

# 결과 저장용 변수들
declare -A PACKAGE_RESULTS
declare -A BUILD_TIMES
declare -A CACHE_STATS

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
log_info "  반복 횟수: $ITERATIONS"

# 캐시 초기 상태 확인
log_step "2단계: 캐시 초기 상태 확인 중..."

INITIAL_DOWNLOADS=$(find "$WORKSPACE_DIR/downloads" -type f 2>/dev/null | wc -l || echo "0")
INITIAL_SSTATE=$(find "$WORKSPACE_DIR/sstate-cache" -type f 2>/dev/null | wc -l || echo "0")

log_info "초기 캐시 상태:"
log_info "  Downloads 파일: $INITIAL_DOWNLOADS"
log_info "  sstate 객체: $INITIAL_SSTATE"

# JSON 결과 초기화
if [ -n "$OUTPUT_FILE" ]; then
    cat > "$OUTPUT_FILE" << EOF
{
  "test_info": {
    "timestamp": "$(date -Iseconds)",
    "workspace": "$WORKSPACE_DIR",
    "packages": [$(printf '"%s",' "${TEST_PACKAGES[@]}" | sed 's/,$//')]
    "iterations": $ITERATIONS,
    "initial_cache": {
      "downloads_files": $INITIAL_DOWNLOADS,
      "sstate_objects": $INITIAL_SSTATE
    }
  },
  "package_results": {},
  "summary": {}
}
EOF
fi

# 각 패키지별 테스트
for package in "${TEST_PACKAGES[@]}"; do
    log_step "3단계: $package 패키지 테스트 중..."
    
    declare -a build_times=()
    declare -a sstate_hits=()
    declare -a task_cache_hits=()
    
    for ((i=1; i<=ITERATIONS; i++)); do
        log_info "[$i/$ITERATIONS] $package 빌드 시작..."
        
        # 빌드 시작 시간
        start_time=$(date +%s)
        
        # Docker 컨테이너에서 패키지 빌드
        BUILD_LOG=$(mktemp)
        
        if [ "$VERBOSE" = true ]; then
            log_info "빌드 명령 실행 중..."
        fi
        
        # 첫 번째 빌드는 cleanall로 시작 (캐시 없이)
        if [ "$i" -eq 1 ]; then
            CLEAN_CMD="bitbake -c cleanall $package && "
        else
            CLEAN_CMD=""
        fi
        
        docker run --rm \
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
            log_info "✅ [$i/$ITERATIONS] $package 빌드 완료 (${build_time}초)"
            build_times+=($build_time)
            
            # sstate 캐시 히트율 분석
            sstate_hit_count=$(grep -c "sstate.*Found existing" "$BUILD_LOG" 2>/dev/null || echo "0")
            sstate_total_count=$(grep -c "sstate.*Searching" "$BUILD_LOG" 2>/dev/null || echo "1")
            sstate_hit_rate=$(echo "scale=1; $sstate_hit_count * 100 / $sstate_total_count" | bc -l 2>/dev/null || echo "0")
            
            # 태스크 캐시 히트율 분석
            task_cached_count=$(grep -c "cached" "$BUILD_LOG" 2>/dev/null || echo "0")
            task_total_count=$(grep -c "Running task" "$BUILD_LOG" 2>/dev/null || echo "1")
            task_cache_rate=$(echo "scale=1; $task_cached_count * 100 / $task_total_count" | bc -l 2>/dev/null || echo "0")
            
            sstate_hits+=($sstate_hit_rate)
            task_cache_hits+=($task_cache_rate)
            
            if [ "$VERBOSE" = true ]; then
                log_info "  sstate 히트율: ${sstate_hit_rate}% ($sstate_hit_count/$sstate_total_count)"
                log_info "  태스크 캐시율: ${task_cache_rate}% ($task_cached_count/$task_total_count)"
            fi
        else
            log_error "❌ [$i/$ITERATIONS] $package 빌드 실패"
            if [ "$VERBOSE" = true ]; then
                echo "빌드 로그:"
                tail -20 "$BUILD_LOG"
            fi
            build_times+=(0)
            sstate_hits+=(0)
            task_cache_hits+=(0)
        fi
        
        rm -f "$BUILD_LOG"
        
        # 빌드 간 잠시 대기
        if [ "$i" -lt "$ITERATIONS" ]; then
            sleep 2
        fi
    done
    
    # 패키지별 결과 분석
    if [ ${#build_times[@]} -ge 2 ]; then
        first_build=${build_times[0]}
        second_build=${build_times[1]}
        
        if [ "$first_build" -gt 0 ] && [ "$second_build" -gt 0 ]; then
            speedup=$(echo "scale=2; $first_build / $second_build" | bc -l)
            time_saved=$((first_build - second_build))
            efficiency=$(echo "scale=1; (1 - $second_build / $first_build) * 100" | bc -l)
            
            log_info "📊 $package 결과:"
            log_info "  첫 빌드: ${first_build}초"
            log_info "  두 번째 빌드: ${second_build}초"
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
            
            # 결과 저장
            PACKAGE_RESULTS["$package"]="$efficiency"
            BUILD_TIMES["$package"]="$first_build,$second_build"
            
            # JSON 업데이트
            if [ -n "$OUTPUT_FILE" ] && command -v jq >/dev/null 2>&1; then
                jq --arg pkg "$package" \
                   --argjson first "$first_build" \
                   --argjson second "$second_build" \
                   --arg efficiency "$efficiency" \
                   --arg speedup "$speedup" \
                   '.package_results[$pkg] = {
                     "first_build_time": $first,
                     "second_build_time": $second,
                     "efficiency_percentage": $efficiency,
                     "speedup_ratio": $speedup,
                     "time_saved": ($first - $second)
                   }' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
            fi
        fi
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
echo "┌─────────────────┬──────────────┬──────────────┬──────────────┬──────────┐"
echo "│ 패키지          │ 첫 빌드(초)  │ 두번째(초)   │ 효율성(%)    │ 평가     │"
echo "├─────────────────┼──────────────┼──────────────┼──────────────┼──────────┤"

total_efficiency=0
valid_packages=0

for package in "${TEST_PACKAGES[@]}"; do
    if [[ -n "${PACKAGE_RESULTS[$package]:-}" ]]; then
        IFS=',' read -ra times <<< "${BUILD_TIMES[$package]}"
        first_time=${times[0]}
        second_time=${times[1]}
        efficiency=${PACKAGE_RESULTS[$package]}
        
        # 효율성 평가 아이콘
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
        
        printf "│ %-15s │ %12s │ %12s │ %12s │ %-8s │\n" \
               "$package" "$first_time" "$second_time" "$efficiency" "$rating"
        
        total_efficiency=$(echo "$total_efficiency + $efficiency" | bc -l)
        ((valid_packages++))
    else
        printf "│ %-15s │ %12s │ %12s │ %12s │ %-8s │\n" \
               "$package" "실패" "실패" "0.0" "❌ 실패"
    fi
done

echo "└─────────────────┴──────────────┴──────────────┴──────────────┴──────────┘"

if [ "$valid_packages" -gt 0 ]; then
    average_efficiency=$(echo "scale=1; $total_efficiency / $valid_packages" | bc -l)
    log_info "평균 캐시 효율성: ${average_efficiency}%"
    
    # 전체 평가
    avg_int=${average_efficiency%.*}
    if [ "$avg_int" -ge 80 ]; then
        log_info "🎉 전체 평가: 매우 우수한 캐시 성능!"
    elif [ "$avg_int" -ge 60 ]; then
        log_info "✅ 전체 평가: 양호한 캐시 성능"
    elif [ "$avg_int" -ge 40 ]; then
        log_warn "🟡 전체 평가: 보통 수준의 캐시 성능"
    else
        log_error "🔴 전체 평가: 캐시 성능 개선 필요"
    fi
    
    # JSON 요약 업데이트
    if [ -n "$OUTPUT_FILE" ] && command -v jq >/dev/null 2>&1; then
        jq --arg avg "$average_efficiency" \
           --argjson valid "$valid_packages" \
           --argjson new_downloads "$NEW_DOWNLOADS" \
           --argjson new_sstate "$NEW_SSTATE" \
           '.summary = {
             "average_efficiency": $avg,
             "tested_packages": $valid,
             "new_downloads": $new_downloads,
             "new_sstate_objects": $new_sstate,
             "test_completed": true
           }' "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"
        
        log_info "결과가 $OUTPUT_FILE에 저장되었습니다."
    fi
else
    log_error "모든 패키지 빌드가 실패했습니다."
    exit 1
fi

echo ""
log_info "💡 권장사항:"
if [ "$avg_int" -ge 60 ]; then
    echo "   ✅ 캐시가 잘 작동하고 있습니다."
    echo "   ✅ 학생들에게 배포할 준비가 되었습니다."
else
    echo "   🔧 캐시 성능 개선이 필요합니다:"
    echo "   1. sstate-cache 디렉토리 권한 확인"
    echo "   2. Docker 볼륨 마운트 확인"
    echo "   3. 네트워크 연결 상태 확인"
    echo "   4. 캐시 재생성 고려"
fi

echo ""
log_info "🔄 다음 단계:"
echo "   1. 전체 이미지 빌드 테스트: ./scripts/quick-cache-test.sh"
echo "   2. 캐시 업로드 준비: ./scripts/upload-cache.sh --dry-run"
echo "   3. 문제 발생 시 진단: ./scripts/complete-instructor-setup.sh --skip-test" 