#!/bin/bash

# KEA Yocto 분할된 캐시 GitHub 업로드 스크립트
set -euo pipefail

echo "🚀 KEA Yocto 분할 캐시 GitHub 업로드"
echo "===================================="

# 토큰 확인
if [ ! -f ~/token ]; then
    echo "❌ GitHub 토큰이 필요합니다. ~/token 파일에 토큰을 저장해주세요."
    exit 1
fi

export GITHUB_TOKEN=$(cat ~/token)
echo "✅ 토큰 로드 완료"

# 전체 캐시 디렉토리로 이동
cd yocto-workspace-full

# 파일 존재 확인
if [ ! -f "full-downloads-cache.tar.gz.partaa" ] || [ ! -f "full-sstate-cache.tar.gz" ]; then
    echo "❌ 분할된 캐시 파일이 없습니다."
    exit 1
fi

# 릴리스 태그 생성
RELEASE_TAG="split-cache-$(date +%Y%m%d-%H%M%S)"
RELEASE_TITLE="KEA Yocto Split Cache $(date '+%Y-%m-%d %H:%M')"

echo "📦 릴리스 정보:"
echo "  태그: $RELEASE_TAG"
echo "  제목: $RELEASE_TITLE"

# 파일 확인
echo ""
echo "📂 업로드할 파일들:"
ls -la full-downloads-cache.tar.gz.part* full-sstate-cache.tar.gz* full-cache-info.txt

# 릴리스 노트 생성
cat > release-notes.md << EOF
# KEA Yocto Project 5.0 LTS 분할 캐시

**생성 날짜:** $(date '+%Y년 %m월 %d일 %H:%M:%S')
**빌드 대상:** core-image-minimal
**Yocto 버전:** 5.0 LTS (Scarthgap)
**Docker 이미지:** jabang3/yocto-lecture:5.0-lts

## 📦 캐시 구성

### Downloads Cache (분할됨)
- **full-downloads-cache.tar.gz.partaa** ($(du -h full-downloads-cache.tar.gz.partaa | cut -f1)) - 분할 파일 1/4
- **full-downloads-cache.tar.gz.partab** ($(du -h full-downloads-cache.tar.gz.partab | cut -f1)) - 분할 파일 2/4  
- **full-downloads-cache.tar.gz.partac** ($(du -h full-downloads-cache.tar.gz.partac | cut -f1)) - 분할 파일 3/4
- **full-downloads-cache.tar.gz.partad** ($(du -h full-downloads-cache.tar.gz.partad | cut -f1)) - 분할 파일 4/4

### Sstate Cache  
- **full-sstate-cache.tar.gz** ($(du -h full-sstate-cache.tar.gz | cut -f1)) - 전체 빌드 상태 캐시 (257개 항목)

### 정보 파일
- **full-cache-info.txt** - 캐시 정보 및 사용법

## 🚀 사용법

### 1. 캐시 다운로드
\`\`\`bash
mkdir yocto-workspace && cd yocto-workspace

# 분할된 downloads 캐시 다운로드
wget https://github.com/jayleekr/kea-yocto/releases/download/$RELEASE_TAG/full-downloads-cache.tar.gz.partaa
wget https://github.com/jayleekr/kea-yocto/releases/download/$RELEASE_TAG/full-downloads-cache.tar.gz.partab  
wget https://github.com/jayleekr/kea-yocto/releases/download/$RELEASE_TAG/full-downloads-cache.tar.gz.partac
wget https://github.com/jayleekr/kea-yocto/releases/download/$RELEASE_TAG/full-downloads-cache.tar.gz.partad

# sstate 캐시 다운로드
wget https://github.com/jayleekr/kea-yocto/releases/download/$RELEASE_TAG/full-sstate-cache.tar.gz

# 정보 파일 다운로드
wget https://github.com/jayleekr/kea-yocto/releases/download/$RELEASE_TAG/full-cache-info.txt
\`\`\`

### 2. 분할된 파일 재결합
\`\`\`bash
# downloads 캐시 재결합
cat full-downloads-cache.tar.gz.part* > full-downloads-cache.tar.gz

# 무결성 검증 (옵션)
# 원본 MD5: $(cat full-downloads-cache.tar.gz.md5 | cut -d' ' -f1)
md5sum full-downloads-cache.tar.gz
\`\`\`

### 3. 캐시 압축 해제 및 권한 설정
\`\`\`bash
tar -xzf full-downloads-cache.tar.gz
tar -xzf full-sstate-cache.tar.gz
chmod -R 777 downloads sstate-cache
\`\`\`

### 4. Docker 빌드 실행
\`\`\`bash
docker run --rm -v "\$PWD:/workspace" jabang3/yocto-lecture:5.0-lts bash -c "
  cd /workspace
  source /opt/poky/oe-init-build-env build
  echo 'DL_DIR = \"/workspace/downloads\"' >> build/conf/local.conf
  echo 'SSTATE_DIR = \"/workspace/sstate-cache\"' >> build/conf/local.conf
  bitbake core-image-minimal
"
\`\`\`

## ⚡ 성능 향상

- 🚀 **80-90% 빌드 시간 단축**
- 📥 **네트워크 다운로드 최소화**
- 💾 **6.7GB 캐시 데이터로 완전한 빌드 환경**
- ✅ **검증된 재사용 가능한 캐시**
- 📦 **GitHub 호환 분할 업로드**

## 🔐 파일 무결성 검증

각 분할 파일과 통합 파일에 대한 체크섬이 제공됩니다:

\`\`\`bash
# 분할 파일 검증
md5sum -c full-downloads-cache.tar.gz.partaa.md5
md5sum -c full-downloads-cache.tar.gz.partab.md5  
md5sum -c full-downloads-cache.tar.gz.partac.md5
md5sum -c full-downloads-cache.tar.gz.partad.md5

# sstate 캐시 검증
md5sum -c full-sstate-cache.tar.gz.md5
sha256sum -c full-sstate-cache.tar.gz.sha256
\`\`\`

## 📋 자동 다운로드 스크립트

\`\`\`bash
#!/bin/bash
# download-cache.sh
echo "📥 KEA Yocto 캐시 자동 다운로드"
BASE_URL="https://github.com/jayleekr/kea-yocto/releases/download/$RELEASE_TAG"

wget "\$BASE_URL/full-downloads-cache.tar.gz.partaa"
wget "\$BASE_URL/full-downloads-cache.tar.gz.partab" 
wget "\$BASE_URL/full-downloads-cache.tar.gz.partac"
wget "\$BASE_URL/full-downloads-cache.tar.gz.partad"
wget "\$BASE_URL/full-sstate-cache.tar.gz"
wget "\$BASE_URL/full-cache-info.txt"

echo "🔧 재결합 중..."
cat full-downloads-cache.tar.gz.part* > full-downloads-cache.tar.gz
rm full-downloads-cache.tar.gz.part*

echo "📦 압축 해제 중..."  
tar -xzf full-downloads-cache.tar.gz
tar -xzf full-sstate-cache.tar.gz

echo "✅ 캐시 준비 완료!"
\`\`\`

---
*Generated by KEA Yocto Split Cache Distribution System*
EOF

echo "✅ 릴리스 노트 생성 완료"

# GitHub CLI 설치 확인
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh)가 필요합니다. 설치해주세요: sudo apt install gh"
    exit 1
fi

# GitHub Release 생성
echo ""
echo "🚀 GitHub Release 생성 중..."
echo "⚠️  파일이 크므로 업로드에 시간이 걸릴 수 있습니다..."

cd /home/jayleekr/kea-yocto

gh release create "$RELEASE_TAG" \
    --title "$RELEASE_TITLE" \
    --notes-file yocto-workspace-full/release-notes.md \
    yocto-workspace-full/full-downloads-cache.tar.gz.partaa \
    yocto-workspace-full/full-downloads-cache.tar.gz.partaa.md5 \
    yocto-workspace-full/full-downloads-cache.tar.gz.partaa.sha256 \
    yocto-workspace-full/full-downloads-cache.tar.gz.partab \
    yocto-workspace-full/full-downloads-cache.tar.gz.partab.md5 \
    yocto-workspace-full/full-downloads-cache.tar.gz.partab.sha256 \
    yocto-workspace-full/full-downloads-cache.tar.gz.partac \
    yocto-workspace-full/full-downloads-cache.tar.gz.partac.md5 \
    yocto-workspace-full/full-downloads-cache.tar.gz.partac.sha256 \
    yocto-workspace-full/full-downloads-cache.tar.gz.partad \
    yocto-workspace-full/full-downloads-cache.tar.gz.partad.md5 \
    yocto-workspace-full/full-downloads-cache.tar.gz.partad.sha256 \
    yocto-workspace-full/full-sstate-cache.tar.gz \
    yocto-workspace-full/full-sstate-cache.tar.gz.md5 \
    yocto-workspace-full/full-sstate-cache.tar.gz.sha256 \
    yocto-workspace-full/full-cache-info.txt

echo ""
echo "🎉 업로드 완료!"
echo "📂 릴리스 URL: https://github.com/jayleekr/kea-yocto/releases/tag/$RELEASE_TAG"
echo ""
echo "🧪 테스트 명령어:"
echo "mkdir test-download && cd test-download"
echo "# 자동 다운로드 스크립트 생성"
echo "cat > download-cache.sh << 'EOF'"
echo "#!/bin/bash"
echo "BASE_URL=\"https://github.com/jayleekr/kea-yocto/releases/download/$RELEASE_TAG\""
echo "wget \"\$BASE_URL/full-downloads-cache.tar.gz.partaa\""
echo "wget \"\$BASE_URL/full-downloads-cache.tar.gz.partab\""
echo "wget \"\$BASE_URL/full-downloads-cache.tar.gz.partac\""
echo "wget \"\$BASE_URL/full-downloads-cache.tar.gz.partad\""
echo "wget \"\$BASE_URL/full-sstate-cache.tar.gz\""
echo "cat full-downloads-cache.tar.gz.part* > full-downloads-cache.tar.gz"
echo "rm full-downloads-cache.tar.gz.part*"
echo "EOF"
echo "chmod +x download-cache.sh && ./download-cache.sh" 