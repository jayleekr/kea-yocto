#!/bin/bash

# ARM64 VM에서 Docker 플랫폼 문제 해결 스크립트

set -e

echo "🔧 ARM64 VM Docker 플랫폼 문제 해결 시작..."

# 현재 시스템 정보 확인
echo "=== 시스템 정보 ==="
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME)"
echo ""

# Docker 정보 확인
echo "=== Docker 정보 ==="
docker version --format 'Version: {{.Server.Version}}'
docker info --format 'Architecture: {{.Architecture}}'
echo ""

# 이미지 매니페스트 확인
echo "=== 이미지 매니페스트 확인 ==="
if command -v docker &> /dev/null; then
    echo "Docker Hub 이미지 매니페스트:"
    docker buildx imagetools inspect jabang3/yocto-lecture:5.0-lts 2>/dev/null || echo "매니페스트 조회 실패"
    echo ""
fi

# 해결방법 1: 명시적 플랫폼 지정으로 이미지 pull
echo "🔄 해결방법 1: ARM64 플랫폼 명시적 지정"
echo "ARM64 전용 이미지 pull 중..."

# 기존 이미지 제거
docker rmi jabang3/yocto-lecture:5.0-lts 2>/dev/null || true
docker rmi jabang3/yocto-lecture:latest 2>/dev/null || true

# ARM64 플랫폼 명시적 지정하여 pull
docker pull --platform linux/arm64 jabang3/yocto-lecture:5.0-lts
docker tag jabang3/yocto-lecture:5.0-lts jabang3/yocto-lecture:latest

echo "✅ ARM64 이미지 pull 완료"

# 테스트
echo "🧪 이미지 테스트 중..."
docker run --rm --platform linux/arm64 jabang3/yocto-lecture:5.0-lts uname -m
docker run --rm --platform linux/arm64 jabang3/yocto-lecture:5.0-lts cat /etc/os-release | head -2

echo ""
echo "🔄 해결방법 2: Docker Compose 설정 업데이트"

# docker-compose.yml 백업
if [ -f "docker-compose.yml" ]; then
    cp docker-compose.yml docker-compose.yml.backup
    echo "기존 docker-compose.yml 백업됨"
fi

# 새로운 docker-compose.yml 생성 (플랫폼 명시)
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  yocto-lecture:
    image: jabang3/yocto-lecture:5.0-lts
    platform: linux/arm64  # ARM64 명시적 지정
    container_name: yocto-lecture
    hostname: yocto-builder
    working_dir: /workspace
    environment:
      - TMPDIR=/tmp/yocto-build
      - BB_ENV_PASSTHROUGH_ADDITIONS=TMPDIR
    volumes:
      - ./workspace:/workspace
      - /tmp/yocto-build:/tmp/yocto-build
    stdin_open: true
    tty: true
    command: /bin/bash

  # GitHub Container Registry 옵션 (권장)
  yocto-lecture-ghcr:
    image: ghcr.io/jayleekr/yocto-lecture:5.0-lts
    platform: linux/arm64
    container_name: yocto-lecture-ghcr
    hostname: yocto-builder-ghcr
    working_dir: /workspace
    environment:
      - TMPDIR=/tmp/yocto-build
      - BB_ENV_PASSTHROUGH_ADDITIONS=TMPDIR
    volumes:
      - ./workspace:/workspace
      - /tmp/yocto-build:/tmp/yocto-build
    stdin_open: true
    tty: true
    command: /bin/bash
EOF

echo "✅ docker-compose.yml 업데이트 완료 (ARM64 플랫폼 명시)"

# Docker Compose 테스트
echo "🧪 Docker Compose 테스트..."
docker compose run --rm yocto-lecture uname -m

echo ""
echo "🔄 해결방법 3: 대안 이미지 소스 (GitHub Container Registry)"
echo "GitHub Container Registry 이미지 pull 중..."

# GHCR 이미지 시도
docker pull --platform linux/arm64 ghcr.io/jayleekr/yocto-lecture:5.0-lts 2>/dev/null || echo "GHCR 이미지 사용 불가 (아직 빌드되지 않음)"

echo ""
echo "=== 💡 사용법 안내 ==="
echo ""
echo "1️⃣ Docker Compose 사용 (권장):"
echo "   docker compose run --rm yocto-lecture"
echo ""
echo "2️⃣ 직접 Docker 실행:"
echo "   docker run -it --platform linux/arm64 \\"
echo "     -v \$(pwd)/workspace:/workspace \\"
echo "     -e TMPDIR=/tmp/yocto-build \\"
echo "     jabang3/yocto-lecture:5.0-lts"
echo ""
echo "3️⃣ GHCR 사용 (향후):"
echo "   docker compose run --rm yocto-lecture-ghcr"
echo ""
echo "✅ ARM64 VM 문제 해결 완료!"
echo ""
echo "🔍 문제가 지속되면 다음 명령어로 디버깅:"
echo "   docker info | grep Architecture"
echo "   docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.ID}}'"
echo "   docker run --rm jabang3/yocto-lecture:5.0-lts file /bin/bash" 