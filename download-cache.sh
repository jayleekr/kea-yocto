#!/bin/bash
echo "📥 KEA Yocto 캐시 자동 다운로드 from GitHub"
BASE_URL="https://github.com/jayleekr/kea-yocto/releases/download/split-cache-20250612-153704"

echo "⬇️  Downloading split files..."
wget "$BASE_URL/full-downloads-cache.tar.gz.partaa"
wget "$BASE_URL/full-downloads-cache.tar.gz.partab"
wget "$BASE_URL/full-downloads-cache.tar.gz.partac"
wget "$BASE_URL/full-downloads-cache.tar.gz.partad"
wget "$BASE_URL/full-sstate-cache.tar.gz"
wget "$BASE_URL/full-cache-info.txt"

echo "🔧 재결합 중..."
cat full-downloads-cache.tar.gz.part* > full-downloads-cache.tar.gz
rm full-downloads-cache.tar.gz.part*

echo "✅ 다운로드 및 재결합 완료!"
echo "📊 파일 크기:"
ls -lh *.tar.gz *.txt 