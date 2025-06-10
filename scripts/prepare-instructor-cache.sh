#!/bin/bash
set -e

echo "👨‍🏫 강사용 캐시 준비 스크립트"
echo "================================"

WORKSPACE_DIR="./yocto-workspace"
BUILD_DIR="$WORKSPACE_DIR/instructor-build"

# 작업공간 생성
mkdir -p "$WORKSPACE_DIR"/{downloads,sstate-cache,mirror}

echo "🏗️  강의용 이미지들을 빌드하여 캐시를 생성합니다..."
echo "⏰ 이 과정은 2-4시간이 소요될 수 있습니다."

# Docker 컨테이너에서 빌드 실행
docker run --rm -it \
  -v "$WORKSPACE_DIR/downloads:/opt/yocto/downloads" \
  -v "$WORKSPACE_DIR/sstate-cache:/opt/yocto/sstate-cache" \
  -e BB_NUMBER_THREADS=8 \
  -e PARALLEL_MAKE="-j 8" \
  jabang3/yocto-lecture:5.0-lts \
  /bin/bash -c "
    source /opt/poky/oe-init-build-env /tmp/cache-build
    
    echo '📦 core-image-minimal 빌드 중...'
    bitbake core-image-minimal
    
    echo '📦 core-image-base 빌드 중...'
    bitbake core-image-base
    
    echo '📦 meta-toolchain 빌드 중...'
    bitbake meta-toolchain
    
    echo '✅ 모든 기본 이미지 빌드 완료!'
  "

echo "📦 캐시 압축 중..."

# Downloads 캐시 압축
cd "$WORKSPACE_DIR"
tar -czf downloads-cache.tar.gz downloads/
echo "✅ downloads-cache.tar.gz 생성 완료"

# sstate 캐시 압축
tar -czf sstate-cache.tar.gz sstate-cache/
echo "✅ sstate-cache.tar.gz 생성 완료"

echo ""
echo "🎉 강사용 캐시 준비 완료!"
echo "📁 생성된 파일:"
echo "   - downloads-cache.tar.gz ($(du -h downloads-cache.tar.gz | cut -f1))"
echo "   - sstate-cache.tar.gz ($(du -h sstate-cache.tar.gz | cut -f1))"
echo ""
echo "💡 이제 이 파일들을 GitHub Release 또는 파일 서버에 업로드하세요."
echo "🔄 prepare-cache.sh 스크립트의 URL을 업데이트하는 것을 잊지 마세요!" 