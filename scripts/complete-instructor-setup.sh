#!/bin/bash

# 강사용 캐시 완료 후 자동 검증 및 업로드 스크립트
# 이 스크립트는 빌드 완료 후 자동으로 실행되어 캐시 효율성 테스트, 
# 문제 진단 및 수정, 업로드 준비를 수행합니다.

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

echo "🔧 KEA Yocto 강사용 캐시 완료 후 검증 및 준비"
echo "=============================================="
echo ""

WORKSPACE_DIR="./yocto-workspace"
UPLOAD_TYPE="local"  # 기본값은 로컬 웹서버 준비

# 옵션 처리
show_usage() {
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --upload-type TYPE  업로드 방식 (github|ftp|s3|local)"
    echo "  --workspace DIR     작업공간 디렉토리 (기본값: ./yocto-workspace)"
    echo "  --skip-test        캐시 효율성 테스트 건너뛰기"
    echo "  --help             이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0                           # 기본 설정으로 실행"
    echo "  $0 --upload-type github      # GitHub Release로 업로드"
    echo "  $0 --skip-test              # 테스트 없이 바로 업로드 준비"
}

SKIP_TEST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --upload-type)
            UPLOAD_TYPE="$2"
            shift 2
            ;;
        --workspace)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        --skip-test)
            SKIP_TEST=true
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

# 1단계: 빌드 완료 확인
log_step "1단계: 빌드 완료 상태 확인 중..."

# 캐시 파일 존재 확인
DOWNLOADS_CACHE="$WORKSPACE_DIR/downloads-cache.tar.gz"
SSTATE_CACHE="$WORKSPACE_DIR/sstate-cache.tar.gz"

if [ ! -f "$DOWNLOADS_CACHE" ] || [ ! -f "$SSTATE_CACHE" ]; then
    log_error "빌드가 아직 완료되지 않았거나 실패했습니다."
    log_error "다음 명령으로 빌드 상태를 확인하세요:"
    log_error "  docker ps -a"
    log_error "  ./scripts/monitor-build.sh"
    exit 1
fi

# 캐시 파일 크기 확인
downloads_size=$(du -h "$DOWNLOADS_CACHE" | cut -f1)
sstate_size=$(du -h "$SSTATE_CACHE" | cut -f1)
downloads_mb=$(du -m "$DOWNLOADS_CACHE" | cut -f1)
sstate_mb=$(du -m "$SSTATE_CACHE" | cut -f1)

log_info "빌드 완료 확인 ✓"
log_info "  downloads-cache.tar.gz: $downloads_size"
log_info "  sstate-cache.tar.gz: $sstate_size"

# 최소 크기 검증
if [ "$downloads_mb" -lt 100 ]; then  # 100MB 미만
    log_error "Downloads 캐시가 너무 작습니다 ($downloads_size). 빌드가 제대로 완료되지 않았을 수 있습니다."
    exit 1
fi

if [ "$sstate_mb" -lt 500 ]; then  # 500MB 미만
    log_error "sstate 캐시가 너무 작습니다 ($sstate_size). 빌드가 제대로 완료되지 않았을 수 있습니다."
    exit 1
fi

# 2단계: 캐시 효율성 테스트
if [ "$SKIP_TEST" = false ]; then
    log_step "2단계: 캐시 효율성 테스트 실행 중..."
    
    log_info "캐시 재사용률을 테스트하여 품질을 검증합니다..."
    
    if ./scripts/quick-cache-test.sh --iterations 2 --output efficiency_test.json; then
        log_info "✅ 캐시 효율성 테스트 완료"
        
        # 효율성 결과 분석
        if command -v jq >/dev/null 2>&1; then
            EFFICIENCY=$(jq -r '.performance_analysis."core-image-minimal".efficiency_percentage // 0' efficiency_test.json 2>/dev/null || echo "0")
            if [ "$EFFICIENCY" != "0" ] && [ "$EFFICIENCY" != "null" ]; then
                EFFICIENCY_INT=${EFFICIENCY%.*}
                
                if [ "$EFFICIENCY_INT" -ge 80 ]; then
                    log_info "🎉 캐시 품질 우수: ${EFFICIENCY_INT}% 효율성"
                elif [ "$EFFICIENCY_INT" -ge 60 ]; then
                    log_info "✅ 캐시 품질 양호: ${EFFICIENCY_INT}% 효율성"
                elif [ "$EFFICIENCY_INT" -ge 40 ]; then
                    log_warn "🟠 캐시 품질 보통: ${EFFICIENCY_INT}% 효율성"
                else
                    log_error "❌ 캐시 품질 불량: ${EFFICIENCY_INT}% 효율성"
                    log_error "캐시 재생성을 권장합니다."
                    
                    # 문제 진단
                    log_step "문제 진단 중..."
                    diagnose_cache_issues
                    exit 1
                fi
            fi
        fi
    else
        log_warn "캐시 효율성 테스트에 실패했지만 업로드 준비는 계속 진행합니다."
    fi
else
    log_info "캐시 효율성 테스트를 건너뜁니다."
fi

# 3단계: 파일 무결성 검증
log_step "3단계: 파일 무결성 검증 중..."

# 압축 파일 무결성 확인
if tar -tzf "$DOWNLOADS_CACHE" >/dev/null 2>&1; then
    log_info "downloads 캐시 무결성 확인 ✓"
else
    log_error "downloads 캐시 파일이 손상되었습니다!"
    exit 1
fi

if tar -tzf "$SSTATE_CACHE" >/dev/null 2>&1; then
    log_info "sstate 캐시 무결성 확인 ✓"
else
    log_error "sstate 캐시 파일이 손상되었습니다!"
    exit 1
fi

# 4단계: 업로드 준비
log_step "4단계: 업로드 준비 중..."

if ./scripts/upload-cache.sh --dry-run --workspace "$WORKSPACE_DIR"; then
    log_info "✅ 업로드 준비 완료"
else
    log_error "업로드 준비에 실패했습니다."
    exit 1
fi

# 5단계: 실제 업로드 (선택사항)
log_step "5단계: 업로드 실행 중..."

if ./scripts/upload-cache.sh --type "$UPLOAD_TYPE" --workspace "$WORKSPACE_DIR"; then
    log_info "✅ 업로드 완료"
else
    log_error "업로드에 실패했습니다."
    exit 1
fi

# 6단계: 최종 보고서 생성
log_step "6단계: 최종 보고서 생성 중..."

REPORT_FILE="cache-build-report-$(date +%Y%m%d-%H%M%S).txt"

cat > "$REPORT_FILE" << EOF
KEA Yocto Project 5.0 LTS 강사용 캐시 빌드 보고서
================================================

빌드 완료 시간: $(date)
작업공간: $WORKSPACE_DIR
업로드 방식: $UPLOAD_TYPE

파일 정보:
- downloads-cache.tar.gz: $downloads_size ($downloads_mb MB)
- sstate-cache.tar.gz: $sstate_size ($sstate_mb MB)

캐시 내용:
- Downloads 파일 수: $(find "$WORKSPACE_DIR/downloads" -type f 2>/dev/null | wc -l || echo "N/A")
- sstate 객체 수: $(find "$WORKSPACE_DIR/sstate-cache" -type f 2>/dev/null | wc -l || echo "N/A")

시스템 정보:
- 운영체제: $(uname -a)
- Docker 버전: $(docker --version)
- 사용 가능 공간: $(df . | tail -1 | awk '{print $4/1024/1024 "GB"}')

품질 검증:
EOF

if [ "$SKIP_TEST" = false ] && command -v jq >/dev/null 2>&1 && [ -f "efficiency_test.json" ]; then
    EFFICIENCY=$(jq -r '.performance_analysis."core-image-minimal".efficiency_percentage // 0' efficiency_test.json 2>/dev/null || echo "0")
    if [ "$EFFICIENCY" != "0" ] && [ "$EFFICIENCY" != "null" ]; then
        echo "- 캐시 효율성: ${EFFICIENCY}%" >> "$REPORT_FILE"
        
        FIRST_BUILD=$(jq -r '.performance_analysis."core-image-minimal".first_build_time // 0' efficiency_test.json 2>/dev/null || echo "0")
        SECOND_BUILD=$(jq -r '.performance_analysis."core-image-minimal".second_build_time // 0' efficiency_test.json 2>/dev/null || echo "0")
        
        if [ "$FIRST_BUILD" != "0" ] && [ "$SECOND_BUILD" != "0" ]; then
            FIRST_MINUTES=$(echo "$FIRST_BUILD / 60" | bc -l | cut -d. -f1)
            SECOND_MINUTES=$(echo "$SECOND_BUILD / 60" | bc -l | cut -d. -f1)
            echo "- 첫 빌드 시간: ${FIRST_MINUTES}분" >> "$REPORT_FILE"
            echo "- 두 번째 빌드 시간: ${SECOND_MINUTES}분" >> "$REPORT_FILE"
        fi
    fi
else
    echo "- 캐시 효율성: 테스트되지 않음" >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

사용법:
1. 학생들이 다음 명령으로 캐시 다운로드:
   ./scripts/quick-start.sh
   
2. 또는 수동 다운로드:
   # 캐시 파일을 yocto-workspace/에 다운로드 후
   cd yocto-workspace
   tar -xzf downloads-cache.tar.gz
   tar -xzf sstate-cache.tar.gz

3. 빌드 실행:
   ./scripts/quick-start.sh

다음 업데이트 시:
- prepare-cache.sh 스크립트의 캐시 URL 업데이트 필요
- 학생들에게 새로운 캐시 버전 안내
EOF

log_info "최종 보고서 생성: $REPORT_FILE"

# 성공 완료
echo ""
log_info "🎉 강사용 캐시 설정 완료!"
echo ""
log_info "📋 완료된 작업:"
echo "   ✅ 빌드 완료 확인"
if [ "$SKIP_TEST" = false ]; then
    echo "   ✅ 캐시 효율성 테스트"
fi
echo "   ✅ 파일 무결성 검증"
echo "   ✅ 업로드 준비"
echo "   ✅ 업로드 실행 ($UPLOAD_TYPE)"
echo "   ✅ 최종 보고서 생성"
echo ""
log_info "📁 생성된 파일:"
echo "   📦 downloads-cache.tar.gz ($downloads_size)"
echo "   📦 sstate-cache.tar.gz ($sstate_size)"
echo "   📄 $REPORT_FILE"

if [ "$UPLOAD_TYPE" = "local" ]; then
    echo "   🌐 web-cache/ (로컬 웹서버 디렉토리)"
    echo ""
    log_info "🌐 로컬 웹서버 시작 방법:"
    echo "   cd web-cache && python3 -m http.server 8000"
    echo "   접속: http://localhost:8000"
fi

echo ""
log_info "✨ 학생들이 사용할 수 있는 최적화된 캐시가 준비되었습니다!"

# 문제 진단 함수
diagnose_cache_issues() {
    log_step "캐시 문제 진단 중..."
    
    # Docker 볼륨 확인
    if docker volume ls | grep -q yocto; then
        log_info "Docker 볼륨 상태:"
        docker volume ls | grep yocto
    fi
    
    # 캐시 디렉토리 권한 확인
    log_info "캐시 디렉토리 권한:"
    ls -la "$WORKSPACE_DIR/" | head -5
    
    # 디스크 공간 확인
    log_info "디스크 공간 사용량:"
    df -h "$WORKSPACE_DIR"
    
    # Docker 컨테이너 로그에서 오류 확인
    CONTAINER_ID=$(docker ps -a --filter "ancestor=jabang3/yocto-lecture:5.0-lts" --format "{{.ID}}" | head -1)
    if [ -n "$CONTAINER_ID" ]; then
        log_info "최근 빌드 오류 확인:"
        docker logs "$CONTAINER_ID" 2>&1 | grep -i "error\|fail\|warning" | tail -5 || echo "특별한 오류 없음"
    fi
    
    log_info "💡 문제 해결 방법:"
    echo "   1. 캐시 디렉토리 권한 수정: sudo chown -R \$USER:\$USER $WORKSPACE_DIR"
    echo "   2. Docker 시스템 정리: docker system prune -a"
    echo "   3. 캐시 재생성: rm -rf $WORKSPACE_DIR && ./scripts/prepare-instructor-cache.sh"
} 