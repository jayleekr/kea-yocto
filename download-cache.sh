#!/bin/bash

# Enhanced KEA Yocto Cache Download Script
echo "📥 KEA Yocto 캐시 자동 다운로드 from GitHub"
echo "============================================"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

BASE_URL="https://github.com/jayleekr/kea-yocto/releases/download/split-cache-20250612-153704"

# Files to download
DOWNLOAD_FILES=(
    "full-downloads-cache.tar.gz.partaa"
    "full-downloads-cache.tar.gz.partab"
    "full-downloads-cache.tar.gz.partac"
    "full-downloads-cache.tar.gz.partad"
    "full-sstate-cache.tar.gz"
    "full-cache-info.txt"
)

# Download function with retry logic
download_file() {
    local file=$1
    local url="$BASE_URL/$file"
    local retries=3
    
    # Skip if file already exists and is large enough
    if [ -f "$file" ] && [ $(stat -c%s "$file" 2>/dev/null || echo 0) -gt 1000000 ]; then
        log_info "파일이 이미 존재합니다: $file"
        return 0
    fi
    
    echo "⬇️  다운로드 중: $file"
    
    for ((i=1; i<=retries; i++)); do
        if wget --progress=bar:force --timeout=30 --tries=1 "$url" -O "$file.tmp"; then
            # Verify download
            if [ -f "$file.tmp" ] && [ $(stat -c%s "$file.tmp" 2>/dev/null || echo 0) -gt 1000 ]; then
                mv "$file.tmp" "$file"
                log_info "✅ 성공: $file"
                return 0
            else
                log_warn "다운로드된 파일이 손상되었습니다: $file"
                rm -f "$file.tmp"
            fi
        else
            log_warn "다운로드 실패 (시도 $i/$retries): $file"
            rm -f "$file.tmp"
        fi
        
        if [ $i -lt $retries ]; then
            echo "⏳ 5초 후 재시도..."
            sleep 5
        fi
    done
    
    log_error "모든 재시도 실패: $file"
    return 1
}

# Download all files
echo "📥 파일 다운로드 시작..."
failed_files=()

for file in "${DOWNLOAD_FILES[@]}"; do
    if ! download_file "$file"; then
        failed_files+=("$file")
    fi
done

# Report failed downloads
if [ ${#failed_files[@]} -gt 0 ]; then
    log_warn "다음 파일 다운로드에 실패했습니다:"
    for file in "${failed_files[@]}"; do
        echo "  ❌ $file"
    done
    echo ""
fi

# Combine split files if all parts are available
echo "🔧 분할 파일 재결합 중..."

# Check if we have all split parts
split_parts=("full-downloads-cache.tar.gz.partaa" "full-downloads-cache.tar.gz.partab" "full-downloads-cache.tar.gz.partac" "full-downloads-cache.tar.gz.partad")
all_parts_available=true

for part in "${split_parts[@]}"; do
    if [ ! -f "$part" ] || [ $(stat -c%s "$part" 2>/dev/null || echo 0) -lt 1000000 ]; then
        log_warn "분할 파일이 없거나 손상됨: $part"
        all_parts_available=false
    fi
done

if [ "$all_parts_available" = true ]; then
    log_info "모든 분할 파일이 준비되었습니다. 재결합 중..."
    
    if cat full-downloads-cache.tar.gz.part* > full-downloads-cache.tar.gz; then
        # Verify combined file
        if [ -f "full-downloads-cache.tar.gz" ] && [ $(stat -c%s "full-downloads-cache.tar.gz" 2>/dev/null || echo 0) -gt 5000000000 ]; then
            log_info "✅ 재결합 성공: full-downloads-cache.tar.gz"
            
            # Clean up split parts
            rm -f full-downloads-cache.tar.gz.part*
            log_info "분할 파일 정리 완료"
        else
            log_error "재결합된 파일이 손상되었습니다"
        fi
    else
        log_error "파일 재결합 실패"
    fi
else
    log_warn "⚠️  일부 분할 파일이 누락되어 재결합할 수 없습니다"
    log_warn "개별 파일들을 확인하거나 다시 다운로드를 시도하세요"
fi

echo ""
echo "✅ 다운로드 완료!"
echo "📊 파일 크기:"
ls -lh *cache* *info* 2>/dev/null | grep -v "cache-uploads\|web-cache"

echo ""
if [ -f "full-downloads-cache.tar.gz" ] && [ -f "full-sstate-cache.tar.gz" ]; then
    log_info "🎉 캐시 다운로드가 성공적으로 완료되었습니다!"
    log_info "다음 단계: ./scripts/quick-start.sh"
elif [ ${#failed_files[@]} -eq 0 ]; then
    log_info "📁 개별 캐시 파일들을 사용할 수 있습니다"
    log_info "다음 단계: ./scripts/quick-start.sh"
else
    log_warn "⚠️  일부 파일 다운로드에 실패했습니다"
    log_warn "네트워크 상태를 확인하고 다시 시도하세요"
fi 