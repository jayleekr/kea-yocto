#!/bin/bash

# 간단한 캐시 효율성 테스트 스크립트
# 이 스크립트는 Python 테스트 스크립트를 사용하여 캐시 효율성을 빠르게 확인합니다.

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

echo "🧪 KEA Yocto 캐시 효율성 간단 테스트"
echo "======================================"
echo ""

# 기본 설정
WORKSPACE_DIR="./yocto-workspace"
DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"
TEST_TARGET="core-image-minimal"

# 옵션 처리
show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --workspace DIR    작업공간 디렉토리 (기본값: ./yocto-workspace)"
    echo "  --image IMAGE      Docker 이미지 (기본값: jabang3/yocto-lecture:5.0-lts)"
    echo "  --target TARGET    빌드 대상 (기본값: core-image-minimal)"
    echo "  --iterations N     반복 횟수 (기본값: 2)"
    echo "  --report          상세 리포트 표시"
    echo "  --help            이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0                           # 기본 설정으로 테스트"
    echo "  $0 --target core-image-base  # core-image-base 테스트"
    echo "  $0 --iterations 3 --report  # 3회 반복하고 상세 리포트 표시"
}

ITERATIONS=2
SHOW_REPORT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --workspace)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        --image)
            DOCKER_IMAGE="$2"
            shift 2
            ;;
        --target)
            TEST_TARGET="$2"
            shift 2
            ;;
        --iterations)
            ITERATIONS="$2"
            shift 2
            ;;
        --report)
            SHOW_REPORT=true
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

# Python 스크립트 존재 확인
TEST_SCRIPT="./scripts/test-cache-efficiency.py"
if [ ! -f "$TEST_SCRIPT" ]; then
    log_error "테스트 스크립트를 찾을 수 없습니다: $TEST_SCRIPT"
    exit 1
fi

# Python 실행 가능 확인
if ! command -v python3 &> /dev/null; then
    log_error "Python3가 설치되지 않았습니다."
    exit 1
fi

# Docker 실행 확인
if ! docker info &> /dev/null; then
    log_error "Docker가 실행되지 않습니다."
    exit 1
fi

log_info "환경 확인 완료 ✓"

log_step "2단계: 캐시 상태 확인 중..."

# 캐시 디렉토리 존재 확인
if [ -d "$WORKSPACE_DIR/downloads" ] || [ -d "$WORKSPACE_DIR/sstate-cache" ]; then
    downloads_files=$(find "$WORKSPACE_DIR/downloads" -type f 2>/dev/null | wc -l || echo 0)
    sstate_files=$(find "$WORKSPACE_DIR/sstate-cache" -name "*.siginfo" 2>/dev/null | wc -l || echo 0)
    
    log_info "기존 캐시 발견:"
    log_info "  Downloads: $downloads_files 파일"
    log_info "  sstate: $sstate_files 시그니처"
    
    if [ "$downloads_files" -gt 0 ] || [ "$sstate_files" -gt 0 ]; then
        log_info "캐시가 존재합니다. 효율성 테스트를 진행합니다."
    else
        log_warn "캐시가 비어있습니다. 첫 번째 빌드가 오래 걸릴 수 있습니다."
    fi
else
    log_warn "캐시 디렉토리가 없습니다. 새로 생성됩니다."
fi

log_step "3단계: 캐시 효율성 테스트 실행 중..."

# 테스트 명령 구성
TEST_CMD="python3 $TEST_SCRIPT"
TEST_CMD="$TEST_CMD --workspace $WORKSPACE_DIR"
TEST_CMD="$TEST_CMD --image $DOCKER_IMAGE"
TEST_CMD="$TEST_CMD --targets $TEST_TARGET"
TEST_CMD="$TEST_CMD --iterations $ITERATIONS"

if [ "$SHOW_REPORT" = true ]; then
    TEST_CMD="$TEST_CMD --report"
fi

log_info "테스트 명령: $TEST_CMD"
log_info "예상 소요 시간: 15-60분 (캐시 상태에 따라)"
echo ""

# 테스트 실행
if $TEST_CMD; then
    echo ""
    log_info "🎉 캐시 효율성 테스트 완료!"
    
    # 결과 파일 확인
    RESULT_FILE=$(ls -t cache_test_results_*.json 2>/dev/null | head -1 || echo "")
    if [ -n "$RESULT_FILE" ]; then
        log_info "📄 결과 파일: $RESULT_FILE"
        
        # 간단한 요약 출력
        if command -v jq &> /dev/null; then
            echo ""
            log_info "📊 테스트 요약:"
            
            jq -r '
                if .performance_analysis then
                    .performance_analysis | to_entries[] | 
                    "  " + .key + ":" +
                    "\n    첫 빌드: " + (.value.first_build_time / 60 | tostring | .[0:4]) + "분" +
                    "\n    두 번째 빌드: " + (.value.second_build_time / 60 | tostring | .[0:4]) + "분" +
                    "\n    속도 향상: " + (.value.speedup_ratio | tostring | .[0:4]) + "배" +
                    "\n    효율성: " + (.value.efficiency_percentage | tostring | .[0:4]) + "%"
                else
                    "  성능 분석 데이터가 없습니다."
                end
            ' "$RESULT_FILE"
            
            # 전체 평가
            EFFICIENCY=$(jq -r '
                if .performance_analysis then
                    [.performance_analysis | to_entries[] | .value.efficiency_percentage] | add / length
                else
                    0
                end
            ' "$RESULT_FILE")
            
            if [ "$EFFICIENCY" != "null" ] && [ "$EFFICIENCY" != "0" ]; then
                EFFICIENCY_INT=${EFFICIENCY%.*}
                echo ""
                if [ "$EFFICIENCY_INT" -ge 80 ]; then
                    log_info "✅ 캐시 시스템이 매우 효율적으로 작동하고 있습니다! (${EFFICIENCY_INT}%)"
                elif [ "$EFFICIENCY_INT" -ge 60 ]; then
                    log_info "🟡 캐시 시스템이 잘 작동하고 있습니다. (${EFFICIENCY_INT}%)"
                elif [ "$EFFICIENCY_INT" -ge 40 ]; then
                    log_warn "🟠 캐시 효율성이 보통입니다. (${EFFICIENCY_INT}%)"
                else
                    log_error "❌ 캐시 효율성이 낮습니다. 설정을 확인해주세요. (${EFFICIENCY_INT}%)"
                fi
            fi
        else
            log_info "💡 jq가 설치되어 있으면 더 상세한 요약을 볼 수 있습니다."
        fi
    fi
    
    echo ""
    log_info "🔍 자세한 분석을 원하면:"
    log_info "  python3 $TEST_SCRIPT --report --workspace $WORKSPACE_DIR"
    
else
    log_error "❌ 캐시 효율성 테스트 실패"
    exit 1
fi 