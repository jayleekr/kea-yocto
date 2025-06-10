#!/bin/bash

# 플랫폼별 Docker Compose 설정 자동 생성 스크립트

set -e

ARCH=$(uname -m)

echo "🔍 플랫폼 감지 중..."
echo "현재 아키텍처: $ARCH"

# 기존 override 파일 제거
if [ -f "docker-compose.override.yml" ]; then
    rm -f docker-compose.override.yml
    echo "기존 override 설정 제거됨"
fi

if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    echo "🛡️  ARM64 환경 감지 - ARM64 네이티브 설정 생성 중..."
    
    cat > docker-compose.override.yml << 'EOF'
# ARM64 환경용 자동 생성 설정

services:
  yocto-lecture:
    platform: linux/arm64
    environment:
      - BB_NUMBER_THREADS=8
      - PARALLEL_MAKE=-j 8
      - MACHINE=qemux86-64
      - LANG=en_US.UTF-8
      - LC_ALL=en_US.UTF-8
      - TZ=Asia/Seoul
    volumes:
      - ./yocto-workspace/workspace:/workspace
      - ./yocto-workspace/downloads:/opt/yocto/downloads
      - ./yocto-workspace/sstate-cache:/opt/yocto/sstate-cache

  yocto-lecture-dev:
    platform: linux/arm64
    environment:
      - BB_NUMBER_THREADS=8
      - PARALLEL_MAKE=-j 8
      - MACHINE=qemux86-64
      - LANG=en_US.UTF-8
      - LC_ALL=en_US.UTF-8
      - TZ=Asia/Seoul
EOF

    echo "✅ ARM64 네이티브 설정 생성 완료"
    echo "📝 docker-compose.override.yml 파일이 생성되었습니다"
    
elif [ "$ARCH" = "x86_64" ]; then
    echo "🖥️  x86_64 환경 감지 - 기본 설정 사용"
    echo "📝 추가 override 설정이 필요하지 않습니다"
    
else
    echo "⚠️  알 수 없는 아키텍처: $ARCH"
    echo "💡 수동으로 플랫폼을 설정해야 할 수 있습니다"
fi

echo ""
echo "🐳 Docker 설정 확인:"
docker compose config --services 2>/dev/null || {
    echo "❌ Docker Compose 설정 오류"
    echo "💡 docker compose config 명령으로 설정을 확인하세요"
    exit 1
}

echo "✅ 플랫폼 설정 완료!"

# ARM64 환경에서 로컬 빌드가 필요한지 확인
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    echo ""
    echo "🔧 ARM64 환경에서 이미지 상태 확인 중..."
    
    # 현재 이미지가 올바른 아키텍처인지 확인
    DOCKER_IMAGE="jabang3/yocto-lecture:5.0-lts"
    if docker image inspect $DOCKER_IMAGE >/dev/null 2>&1; then
        # 이미지 내부 아키텍처 확인 (실제 바이너리 확인)
        if docker run --rm --platform linux/arm64 $DOCKER_IMAGE uname -m 2>/dev/null | grep -q "x86_64"; then
            echo "⚠️  기존 이미지가 x86_64 바이너리를 포함하고 있습니다."
            echo "🏗️  ARM64용 이미지를 로컬에서 빌드합니다..."
            
            if docker build --platform linux/arm64 -t yocto-lecture:arm64-local . >/dev/null 2>&1; then
                echo "✅ ARM64 이미지 로컬 빌드 성공"
                
                # override 파일에서 이미지 이름 변경
                sed -i.bak 's/image: jabang3\/yocto-lecture:5.0-lts/image: yocto-lecture:arm64-local/' docker-compose.override.yml 2>/dev/null || {
                    # sed 실패시 직접 수정
                    cat > docker-compose.override.yml << 'EOF'
# ARM64 환경용 자동 생성 설정

services:
  yocto-lecture:
    image: yocto-lecture:arm64-local
    platform: linux/arm64
    environment:
      - BB_NUMBER_THREADS=8
      - PARALLEL_MAKE=-j 8
      - MACHINE=qemux86-64
      - LANG=en_US.UTF-8
      - LC_ALL=en_US.UTF-8
      - TZ=Asia/Seoul
    volumes:
      - ./yocto-workspace/workspace:/workspace
      - ./yocto-workspace/downloads:/opt/yocto/downloads
      - ./yocto-workspace/sstate-cache:/opt/yocto/sstate-cache

  yocto-lecture-dev:
    image: yocto-lecture:arm64-local
    platform: linux/arm64
    environment:
      - BB_NUMBER_THREADS=8
      - PARALLEL_MAKE=-j 8
      - MACHINE=qemux86-64
      - LANG=en_US.UTF-8
      - LC_ALL=en_US.UTF-8
      - TZ=Asia/Seoul
EOF
                }
                
                echo "📝 로컬 빌드 이미지로 Docker Compose 설정 업데이트됨"
            else
                echo "❌ 로컬 빌드 실패. 기존 설정을 유지합니다."
            fi
        else
            echo "✅ 기존 이미지가 올바른 ARM64 아키텍처입니다."
        fi
    fi
fi 