#!/bin/bash

# 강화된 오류 처리
set -euo pipefail

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 로깅 함수
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

# 옵션 파싱
DRY_RUN=false
VERBOSE=false

show_usage() {
    echo "🚀 KEA Yocto 캐시 다운로드 v2.0"
    echo "================================="
    echo ""
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --dry-run     실제 다운로드 없이 미러 서버 테스트만 수행"
    echo "  --check       네트워크 연결과 미러 서버 상태 확인"
    echo "  --verbose     상세한 진단 정보 표시"
    echo "  --help        이 도움말 표시"
    echo ""
    echo "예시:"
    echo "  $0 --dry-run    # 미러 서버 상태 확인"
    echo "  $0 --check     # 네트워크 및 서버 테스트"
    echo "  $0             # 실제 캐시 다운로드 실행"
}

# 인자 처리
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run|--check)
            DRY_RUN=true
            shift
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

# 정리 함수
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        if [ "$DRY_RUN" = true ]; then
            log_error "미러 서버 테스트에서 문제가 발견되었습니다."
            log_error "네트워크 연결을 확인하고 다시 시도하세요."
        else
            log_error "캐시 다운로드가 실패했습니다."
            log_error "네트워크 연결을 확인하고 다시 시도하세요."
        fi
    fi
}

# 신호 처리
trap cleanup EXIT

if [ "$DRY_RUN" = true ]; then
    echo "🧪 KEA Yocto 캐시 미러 서버 테스트"
    echo "==================================="
    echo "📋 실제 다운로드 없이 모든 미러 서버를 테스트합니다..."
else
    echo "🚀 KEA Yocto 캐시 다운로드 v2.0"
    echo "================================="
fi

# 작업 디렉토리 생성
mkdir -p yocto-workspace/{downloads,sstate-cache}

# 캐시 미러 서버 목록 (우선순위순)
MIRRORS=(
    "https://github.com/jayleekr/kea-yocto/releases/download/split-cache-20250612-153704"
    "https://github.com/jayleekr/kea-yocto-cache/releases/download/5.0-lts-v1"
    "https://your-cdn.example.com/yocto-cache/5.0-lts-v1"
    "https://drive.google.com/uc?id=DOWNLOAD_ID&export=download"
)

# 캐시 파일 정보
CACHE_FILE_DOWNLOADS="downloads-cache.tar.gz"
CACHE_DESC_DOWNLOADS="Downloads 캐시 (약 2-5GB)"
CACHE_FILE_SSTATE="sstate-cache.tar.gz"
CACHE_DESC_SSTATE="sstate 캐시 (약 5-20GB)"

# 미러 서버 테스트 함수
test_mirror() {
    local mirror_url=$1
    local timeout=${2:-10}
    
    if [ "$VERBOSE" = true ]; then
        log_info "미러 테스트: $mirror_url (타임아웃: ${timeout}초)"
    fi
    
    # HTTP 헤더만 확인하여 서버 응답 테스트
    local start_time=$(date +%s.%N)
    
    if curl -I -s --connect-timeout $timeout --max-time $((timeout * 2)) "$mirror_url" >/dev/null 2>&1; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
        
        if [ "$VERBOSE" = true ] && [ "$duration" != "N/A" ]; then
            log_info "응답 시간: ${duration}초"
        fi
        return 0
    else
        return 1
    fi
}

# 파일 존재 여부 테스트
test_file_availability() {
    local mirror_url=$1
    local filename=$2
    local full_url="$mirror_url/$filename"
    
    if [ "$VERBOSE" = true ]; then
        log_info "파일 확인: $full_url"
    fi
    
    # HEAD 요청으로 파일 존재 확인
    if curl -I -s --connect-timeout 10 --max-time 20 "$full_url" | grep -q "200\|302"; then
        # 파일 크기 정보 추출 (가능한 경우)
        local file_size=$(curl -I -s --connect-timeout 10 --max-time 20 "$full_url" | grep -i "content-length" | awk '{print $2}' | tr -d '\r' || echo "")
        
        if [ -n "$file_size" ] && [ "$file_size" -gt 0 ] 2>/dev/null; then
            local size_mb=$((file_size / 1024 / 1024))
            if [ "$VERBOSE" = true ]; then
                log_info "파일 크기: ${size_mb}MB"
            fi
        fi
        return 0
    else
        return 1
    fi
}

# 네트워크 연결 기본 테스트
log_step "1단계: 기본 네트워크 연결 확인 중..."

basic_connectivity=true

# 기본 DNS 해상도 테스트
if ! nslookup github.com >/dev/null 2>&1; then
    log_error "DNS 해상도 실패"
    basic_connectivity=false
fi

# 기본 인터넷 연결 테스트
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    log_warn "인터넷 연결 문제 (ping 실패)"
    # ping이 실패해도 HTTP는 될 수 있으므로 계속 진행
fi

# HTTP/HTTPS 기본 테스트
if ! curl -s --connect-timeout 10 --max-time 20 "https://httpbin.org/status/200" >/dev/null 2>&1; then
    log_error "HTTPS 연결 실패"
    basic_connectivity=false
fi

if [ "$basic_connectivity" = false ]; then
    log_error "기본 네트워크 연결에 문제가 있습니다."
    if [ "$DRY_RUN" = true ]; then
        log_error "▶ 해결 방법:"
        log_error "  1. 인터넷 연결 상태 확인"
        log_error "  2. DNS 설정 확인 (8.8.8.8, 1.1.1.1)"
        log_error "  3. 방화벽/프록시 설정 확인"
        exit 1
    else
        exit 1
    fi
fi

log_info "기본 네트워크 연결 확인 ✓"

# 미러 서버 상태 테스트
log_step "2단계: 미러 서버 상태 확인 중..."

working_mirrors=0
total_mirrors=${#MIRRORS[@]}
mirror_status=""
mirror_response_time=""

mirror_index=0
for mirror in "${MIRRORS[@]}"; do
    echo -n "  📡 테스트: $mirror ... "
    
    start_time=$(date +%s.%N 2>/dev/null || date +%s)
    if test_mirror "$mirror" 15; then
        end_time=$(date +%s.%N 2>/dev/null || date +%s)
        if command -v bc >/dev/null 2>&1; then
            duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
        else
            duration="~1"
        fi
        
        echo -e "${GREEN}✓${NC} (${duration}초)"
        mirror_status="${mirror_status}${mirror_index}:OK;"
        mirror_response_time="${mirror_response_time}${mirror_index}:${duration};"
        ((working_mirrors++))
    else
        echo -e "${RED}✗${NC}"
        mirror_status="${mirror_status}${mirror_index}:FAIL;"
        mirror_response_time="${mirror_response_time}${mirror_index}:N/A;"
    fi
    ((mirror_index++))
done

if [ $working_mirrors -eq 0 ]; then
    log_error "모든 미러 서버에 연결할 수 없습니다."
    if [ "$DRY_RUN" = true ]; then
        log_error "▶ 가능한 원인:"
        log_error "  1. 서버 유지보수 중"
        log_error "  2. 네트워크 방화벽 차단"
        log_error "  3. 임시 서버 장애"
        log_error "  4. GitHub/CDN 서비스 장애"
        exit 1
    else
        exit 1
    fi
fi

log_info "미러 서버 상태: ${working_mirrors}/${total_mirrors} 서버 사용 가능"

# 파일 가용성 테스트 (dry-run 모드에서만)
if [ "$DRY_RUN" = true ]; then
    log_step "3단계: 캐시 파일 가용성 확인 중..."
    
    # Downloads 캐시 파일 확인
    echo ""
    log_info "📦 ${CACHE_DESC_DOWNLOADS} 확인 중..."
    
    file_available=false
    available_mirrors=()
    
    mirror_index=0
    for mirror in "${MIRRORS[@]}"; do
        if echo "$mirror_status" | grep -q "${mirror_index}:OK;"; then
            echo -n "    📡 $mirror/$CACHE_FILE_DOWNLOADS ... "
            
            if test_file_availability "$mirror" "$CACHE_FILE_DOWNLOADS"; then
                echo -e "${GREEN}✓${NC}"
                file_available=true
                available_mirrors+=("$mirror")
            else
                echo -e "${RED}✗${NC}"
            fi
        fi
        ((mirror_index++))
    done
    
    if [ "$file_available" = true ]; then
        log_info "$CACHE_FILE_DOWNLOADS: ${#available_mirrors[@]}개 미러에서 사용 가능"
    else
        log_warn "$CACHE_FILE_DOWNLOADS: 사용 가능한 미러가 없습니다"
    fi
    
    # sstate 캐시 파일 확인
    echo ""
    log_info "📦 ${CACHE_DESC_SSTATE} 확인 중..."
    
    file_available=false
    available_mirrors=()
    
    mirror_index=0
    for mirror in "${MIRRORS[@]}"; do
        if echo "$mirror_status" | grep -q "${mirror_index}:OK;"; then
            echo -n "    📡 $mirror/$CACHE_FILE_SSTATE ... "
            
            if test_file_availability "$mirror" "$CACHE_FILE_SSTATE"; then
                echo -e "${GREEN}✓${NC}"
                file_available=true
                available_mirrors+=("$mirror")
            else
                echo -e "${RED}✗${NC}"
            fi
        fi
        ((mirror_index++))
    done
    
    if [ "$file_available" = true ]; then
        log_info "$CACHE_FILE_SSTATE: ${#available_mirrors[@]}개 미러에서 사용 가능"
    else
        log_warn "$CACHE_FILE_SSTATE: 사용 가능한 미러가 없습니다"
    fi
fi

# 디스크 공간 확인
log_step "$([ "$DRY_RUN" = true ] && echo "4" || echo "3")단계: 로컬 환경 확인 중..."

available_space=$(df . | tail -1 | awk '{print $4}')
available_space_gb=$((available_space / 1024 / 1024))
required_space_gb=30  # downloads + sstate 압축 해제 후 예상 크기

if [ "$VERBOSE" = true ]; then
    log_info "사용 가능한 디스크 공간: ${available_space_gb}GB"
    log_info "필요한 예상 공간: ${required_space_gb}GB"
fi

if [ $available_space_gb -lt $required_space_gb ]; then
    log_error "디스크 공간 부족: ${available_space_gb}GB 사용 가능 (최소 ${required_space_gb}GB 필요)"
    if [ "$DRY_RUN" = true ]; then
        log_error "▶ 해결 방법:"
        log_error "  1. 불필요한 파일 삭제"
        log_error "  2. Docker 정리: docker system prune -a"
        log_error "  3. 다른 볼륨으로 이동"
        exit 1
    else
        exit 1
    fi
fi

log_info "디스크 공간 확인: ${available_space_gb}GB 사용 가능 ✓"

# 기존 캐시 상태 확인
HAVE_DOWNLOADS=false
HAVE_SSTATE=false

if [ -d "yocto-workspace/downloads" ] && [ "$(ls -A yocto-workspace/downloads 2>/dev/null)" ]; then
    existing_downloads=$(du -sh yocto-workspace/downloads | cut -f1)
    log_info "기존 downloads 캐시: $existing_downloads"
    HAVE_DOWNLOADS=true
fi

if [ -d "yocto-workspace/sstate-cache" ] && [ "$(ls -A yocto-workspace/sstate-cache 2>/dev/null)" ]; then
    existing_sstate=$(du -sh yocto-workspace/sstate-cache | cut -f1)
    log_info "기존 sstate 캐시: $existing_sstate"
    HAVE_SSTATE=true
fi

# 캐시가 이미 충분히 있다면 다운로드 건너뛰기
if [ "$HAVE_DOWNLOADS" = true ] && [ "$HAVE_SSTATE" = true ]; then
    log_info "✅ 기존 캐시가 충분합니다. 다운로드를 건너뜁니다."
    log_info "📊 캐시 상태:"
    echo "   ✅ Downloads 캐시: $existing_downloads"
    echo "   ✅ sstate 캐시: $existing_sstate"
    echo ""
    log_info "💡 예상 빌드 시간: 15-30분 (풀 캐시)"
    log_info "캐시 준비가 완료되었습니다!"
    exit 0
fi

# Dry-run 모드 결과 요약
if [ "$DRY_RUN" = true ]; then
    echo ""
    log_info "🎉 미러 서버 테스트 완료!"
    echo ""
    echo "📊 테스트 결과 요약:"
    echo "==================="
    
    echo ""
    echo "🌐 미러 서버 상태:"
    mirror_index=0
    for mirror in "${MIRRORS[@]}"; do
        if echo "$mirror_status" | grep -q "${mirror_index}:OK;"; then
            response_time=$(echo "$mirror_response_time" | grep "${mirror_index}:" | cut -d':' -f2 | cut -d';' -f1)
            echo "   ✅ $mirror (응답시간: ${response_time}초)"
        else
            echo "   ❌ $mirror (연결 실패)"
        fi
        ((mirror_index++))
    done
    
    echo ""
    echo "💾 시스템 준비 상태:"
    echo "   ✅ 네트워크 연결: 정상"
    echo "   ✅ 사용 가능한 미러: ${working_mirrors}/${total_mirrors}"
    echo "   ✅ 디스크 공간: ${available_space_gb}GB"
    
    if [ $working_mirrors -gt 0 ]; then
        echo ""
        log_info "🚀 실제 다운로드를 시작하려면:"
        echo "   $0"
        echo ""
        log_info "💡 예상 다운로드:"
        echo "   - downloads-cache.tar.gz: 2-5GB"
        echo "   - sstate-cache.tar.gz: 5-20GB"
        echo "   - 예상 시간: 10-60분 (네트워크 속도에 따라)"
    else
        echo ""
        log_error "❌ 현재 캐시 다운로드가 불가능합니다."
        log_error "미러 서버 문제를 해결한 후 다시 시도하세요."
    fi
    
    exit 0
fi

# 실제 다운로드 실행 (기존 코드)
log_step "3단계: 캐시 다운로드 실행 중..."

log_info "📡 여러 미러 서버를 시도합니다..."

# 다운로드 함수 개선
download_cache_file() {
    local filename=$1
    local description=$2
    
    log_info "$description 다운로드 중..."
    
    mirror_index=0
    for mirror in "${MIRRORS[@]}"; do
        if echo "$mirror_status" | grep -q "${mirror_index}:OK;"; then
            echo "📡 시도 중: $mirror"
            
            # 파일이 이미 존재하는지 확인
            if [ -f "$filename" ]; then
                log_info "기존 파일 발견. 크기 확인 중..."
                local existing_size=$(stat -f%z "$filename" 2>/dev/null || stat -c%s "$filename" 2>/dev/null || echo "0")
                
                if [ "$existing_size" -gt 1000000 ]; then  # 1MB 이상이면 유효한 파일로 간주
                    log_info "$filename 이미 존재합니다. 다운로드를 건너뜁니다."
                    return 0
                else
                    log_warn "기존 파일이 손상된 것 같습니다. 다시 다운로드합니다."
                    rm -f "$filename"
                fi
            fi
            
            # 실제 다운로드 시도
            if curl -L --fail \
                --connect-timeout 30 \
                --max-time 3600 \
                --retry 3 \
                --retry-delay 5 \
                --progress-bar \
                -o "$filename.tmp" \
                "$mirror/$filename"; then
                
                # 다운로드된 파일 크기 확인
                local downloaded_size=$(stat -f%z "$filename.tmp" 2>/dev/null || stat -c%s "$filename.tmp" 2>/dev/null || echo "0")
                
                if [ "$downloaded_size" -gt 1000000 ]; then  # 1MB 이상
                    mv "$filename.tmp" "$filename"
                    local size_mb=$((downloaded_size / 1024 / 1024))
                    log_info "✅ $filename 다운로드 성공 (${size_mb}MB)"
                    return 0
                else
                    log_error "다운로드된 파일이 너무 작습니다: ${downloaded_size} bytes"
                    rm -f "$filename.tmp"
                fi
            else
                log_error "❌ 실패: $mirror"
                rm -f "$filename.tmp" 2>/dev/null
            fi
        fi
        ((mirror_index++))
    done
    
    log_error "⚠️  모든 미러에서 다운로드 실패: $filename"
    return 1
}

# 작업 디렉토리로 이동
cd yocto-workspace

# Downloads 캐시 다운로드
if download_cache_file "downloads-cache.tar.gz" "📦 Downloads 캐시"; then
    log_info "Downloads 캐시 압축 해제 중..."
    if tar -xzf downloads-cache.tar.gz; then
        log_info "✅ Downloads 캐시 준비 완료"
        
        # 압축 파일 삭제 (선택사항)
        if [ "$VERBOSE" = false ]; then
            rm -f downloads-cache.tar.gz
        fi
    else
        log_error "Downloads 캐시 압축 해제 실패"
    fi
else
    log_warn "⚠️  Downloads 캐시 다운로드 실패. 온라인 다운로드를 사용합니다."
fi

# sstate 캐시 다운로드
if download_cache_file "sstate-cache.tar.gz" "🏗️  sstate 캐시"; then
    log_info "sstate 캐시 압축 해제 중..."
    if tar -xzf sstate-cache.tar.gz; then
        log_info "✅ sstate 캐시 준비 완료"
        
        # 압축 파일 삭제 (선택사항)
        if [ "$VERBOSE" = false ]; then
            rm -f sstate-cache.tar.gz
        fi
    else
        log_error "sstate 캐시 압축 해제 실패"
    fi
else
    log_warn "⚠️  sstate 캐시 다운로드 실패. 첫 빌드가 오래 걸릴 수 있습니다."
fi

# 최종 상태 확인
echo ""
log_info "📊 캐시 준비 상태:"

if [ -d "downloads" ] && [ "$(ls -A downloads)" ]; then
    downloads_final_size=$(du -sh downloads | cut -f1)
    echo "✅ Downloads 캐시: $downloads_final_size"
    DOWNLOADS_STATUS="사용 가능"
else
    echo "❌ Downloads 캐시: 없음 (온라인 다운로드 사용)"
    DOWNLOADS_STATUS="온라인 다운로드"
fi

if [ -d "sstate-cache" ] && [ "$(ls -A sstate-cache)" ]; then
    sstate_final_size=$(du -sh sstate-cache | cut -f1)
    echo "✅ sstate 캐시: $sstate_final_size"
    SSTATE_STATUS="사용 가능"
else
    echo "❌ sstate 캐시: 없음 (처음부터 빌드)"
    SSTATE_STATUS="처음부터 빌드"
fi

# 빌드 시간 예측
echo ""
if [ "$DOWNLOADS_STATUS" = "사용 가능" ] && [ "$SSTATE_STATUS" = "사용 가능" ]; then
    log_info "💡 예상 빌드 시간: 15-30분 (풀 캐시)"
elif [ "$SSTATE_STATUS" = "사용 가능" ]; then
    log_info "💡 예상 빌드 시간: 45분-1시간 (sstate 캐시만)"
elif [ "$DOWNLOADS_STATUS" = "사용 가능" ]; then
    log_info "💡 예상 빌드 시간: 1.5-2시간 (downloads 캐시만)"
else
    log_info "💡 기본 빌드 시간: 2-3시간 (캐시 없음)"
fi

if [ "$DOWNLOADS_STATUS" != "사용 가능" ] || [ "$SSTATE_STATUS" != "사용 가능" ]; then
    echo ""
    log_warn "⚠️  일부 캐시 다운로드에 실패했습니다."
    log_warn "🔄 나중에 다시 시도하려면: ./scripts/prepare-cache.sh"
fi

log_info "캐시 준비가 완료되었습니다!" 