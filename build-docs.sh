#!/bin/bash
set -e

echo "🚀 MkDocs 문서 빌드 시작..."

# Python 가상환경 생성 (있다면 건너뛰기)
if [ ! -d "venv" ]; then
    echo "📦 Python 가상환경 생성중..."
    python3 -m venv venv
fi

# 가상환경 활성화
echo "🔄 가상환경 활성화..."
source venv/bin/activate

# 필요한 패키지 설치
echo "📚 패키지 설치중..."
pip install -r requirements.txt

# 기존 빌드 정리
if [ -d "site" ]; then
    echo "🧹 기존 빌드 정리..."
    rm -rf site
fi

# 문서 빌드
echo "🏗️ 문서 빌드중..."
mkdocs build

echo "✅ 빌드 완료!"
echo "📁 결과물: site/ 디렉토리"
echo ""
echo "🌐 로컬 서버 실행: mkdocs serve"
echo "🚀 배포 준비: site/ 디렉토리를 웹서버에 업로드" 