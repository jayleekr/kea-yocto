#!/bin/bash
set -e

CACHE_VERSION="5.0-lts-v1"

# 여러 미러 서버 URL 목록 (빠른 곳을 우선 시도)
MIRROR_SERVERS=(
    "https://github.com/jayleekr/kea-yocto-cache/releases/download/${CACHE_VERSION}"
    "https://your-cdn.example.com/yocto-cache/${CACHE_VERSION}"
    "https://drive.google.com/uc?id=DOWNLOAD_ID&export=download"
)

echo "🚀 KEA Yocto 캐시 다운로드 중..."
echo "📡 여러 미러 서버를 시도합니다..."

# 작업공간 생성
mkdir -p yocto-workspace

# 캐시 다운로드 함수
download_with_mirrors() {
    local filename="$1"
    local success=false
    
    for mirror in "${MIRROR_SERVERS[@]}"; do
        local url="${mirror}/${filename}"
        echo "📡 시도 중: $mirror"
        
        if wget --timeout=30 --tries=2 -O "$filename" "$url" 2>/dev/null; then
            echo "✅ 다운로드 성공: $mirror"
            success=true
            break
        else
            echo "❌ 실패: $mirror"
        fi
    done
    
    if [ "$success" = false ]; then
        echo "⚠️  모든 미러에서 다운로드 실패: $filename"
        return 1
    fi
    return 0
}

# Downloads 캐시 다운로드
echo "📦 Downloads 캐시 다운로드 중..."
if [ ! -f "yocto-workspace/.downloads-cached" ]; then
    if download_with_mirrors "downloads-cache.tar.gz"; then
        echo "📦 Downloads 캐시 압축 해제 중..."
        tar -xzf downloads-cache.tar.gz -C yocto-workspace/
        rm downloads-cache.tar.gz
        touch yocto-workspace/.downloads-cached
        echo "✅ Downloads 캐시 준비 완료"
    else
        echo "⚠️  Downloads 캐시 다운로드 실패. 온라인 다운로드를 사용합니다."
    fi
fi

# sstate 캐시 다운로드
echo "🏗️  sstate 캐시 다운로드 중..."
if [ ! -f "yocto-workspace/.sstate-cached" ]; then
    if download_with_mirrors "sstate-cache.tar.gz"; then
        echo "🏗️  sstate 캐시 압축 해제 중..."
        tar -xzf sstate-cache.tar.gz -C yocto-workspace/
        rm sstate-cache.tar.gz
        touch yocto-workspace/.sstate-cached
        echo "✅ sstate 캐시 준비 완료"
    else
        echo "⚠️  sstate 캐시 다운로드 실패. 첫 빌드가 오래 걸릴 수 있습니다."
    fi
fi

echo ""
echo "📊 캐시 준비 상태:"
if [ -f "yocto-workspace/.downloads-cached" ]; then
    echo "✅ Downloads 캐시: 준비됨"
else
    echo "❌ Downloads 캐시: 없음 (온라인 다운로드 사용)"
fi

if [ -f "yocto-workspace/.sstate-cached" ]; then
    echo "✅ sstate 캐시: 준비됨"
else
    echo "❌ sstate 캐시: 없음 (처음부터 빌드)"
fi

if [ -f "yocto-workspace/.downloads-cached" ] || [ -f "yocto-workspace/.sstate-cached" ]; then
    echo ""
    echo "🎉 캐시가 준비되었습니다! 빌드 시간이 대폭 단축됩니다."
    echo "💡 예상 빌드 시간:"
    if [ -f "yocto-workspace/.downloads-cached" ] && [ -f "yocto-workspace/.sstate-cached" ]; then
        echo "   - 첫 빌드: 15-30분"
    elif [ -f "yocto-workspace/.sstate-cached" ]; then
        echo "   - 첫 빌드: 45분-1시간 (다운로드 시간 포함)"
    else
        echo "   - 첫 빌드: 1-2시간 (sstate 빌드 시간 단축)"
    fi
else
    echo ""
    echo "⚠️  캐시 다운로드에 실패했습니다."
    echo "💡 기본 빌드 시간: 2-3시간 (캐시 없음)"
    echo "🔄 나중에 다시 시도하려면: ./scripts/prepare-cache.sh"
fi 