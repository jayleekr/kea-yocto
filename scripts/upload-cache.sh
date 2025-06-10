#!/bin/bash
set -e

echo "📤 Yocto 캐시 업로드 스크립트"
echo "============================"

WORKSPACE_DIR="./yocto-workspace"
CACHE_VERSION=${1:-"5.0-lts-v1"}

# 필요한 파일들 확인
if [ ! -f "$WORKSPACE_DIR/downloads-cache.tar.gz" ]; then
    echo "❌ downloads-cache.tar.gz를 찾을 수 없습니다."
    echo "💡 먼저 ./scripts/prepare-instructor-cache.sh를 실행하세요."
    exit 1
fi

if [ ! -f "$WORKSPACE_DIR/sstate-cache.tar.gz" ]; then
    echo "❌ sstate-cache.tar.gz를 찾을 수 없습니다."
    echo "💡 먼저 ./scripts/prepare-instructor-cache.sh를 실행하세요."
    exit 1
fi

echo "📊 캐시 파일 정보:"
echo "📦 Downloads 캐시: $(du -h $WORKSPACE_DIR/downloads-cache.tar.gz | cut -f1)"
echo "🏗️  sstate 캐시: $(du -h $WORKSPACE_DIR/sstate-cache.tar.gz | cut -f1)"
echo ""

# GitHub Release 업로드 (gh CLI 사용)
if command -v gh &> /dev/null; then
    echo "🐙 GitHub Release로 업로드를 시도합니다..."
    echo "⚠️  GitHub repository와 gh CLI 설정이 필요합니다."
    
    read -p "GitHub Release로 업로드하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🏷️  태그 '$CACHE_VERSION' 생성 중..."
        git tag -a "$CACHE_VERSION" -m "Yocto 5.0 LTS 캐시 버전 $CACHE_VERSION" || true
        git push origin "$CACHE_VERSION" || true
        
        echo "📤 GitHub Release 생성 및 파일 업로드 중..."
        gh release create "$CACHE_VERSION" \
            --title "Yocto 5.0 LTS 캐시 $CACHE_VERSION" \
            --notes "미리 빌드된 Yocto 5.0 LTS downloads 및 sstate 캐시" \
            "$WORKSPACE_DIR/downloads-cache.tar.gz" \
            "$WORKSPACE_DIR/sstate-cache.tar.gz"
        
        echo "✅ GitHub Release 업로드 완료!"
        echo "🔗 URL: https://github.com/$(gh repo view --json owner,name -q '.owner.login + "/" + .name')/releases/tag/$CACHE_VERSION"
    fi
else
    echo "⚠️  GitHub CLI (gh)가 설치되지 않았습니다."
fi

echo ""
echo "🌐 다른 업로드 옵션들:"
echo ""
echo "1. **Google Drive** (큰 파일 지원):"
echo "   - 웹에서 drive.google.com 접속"
echo "   - 파일 업로드 후 '공유 링크' 생성"
echo "   - 공유 링크를 prepare-cache.sh에 업데이트"
echo ""
echo "2. **Dropbox** (2GB 제한):"
echo "   - dropbox.com에서 파일 업로드"
echo "   - 공유 링크 생성"
echo ""
echo "3. **AWS S3/CloudFront** (고속):"
echo "   aws s3 cp $WORKSPACE_DIR/downloads-cache.tar.gz s3://your-bucket/"
echo "   aws s3 cp $WORKSPACE_DIR/sstate-cache.tar.gz s3://your-bucket/"
echo ""
echo "4. **사설 서버** (nginx/apache):"
echo "   scp $WORKSPACE_DIR/*.tar.gz user@your-server:/var/www/html/yocto-cache/"
echo ""

echo "📝 업로드 완료 후 할 일:"
echo "1. prepare-cache.sh 스크립트의 URL 업데이트"
echo "2. 수강생들에게 새로운 캐시 버전 안내"
echo "3. 기존 캐시 서버에서 이전 버전 정리" 