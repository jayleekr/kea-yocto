#!/bin/bash

# Yocto 5.0 LTS 이미지 테스트 스크립트

set -e

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

DOCKER_IMAGE="yocto-lecture:5.0-lts"

echo "======================================"
echo "Yocto 5.0 LTS 이미지 테스트"
echo "======================================"

# 이미지 존재 확인
log_step "Docker 이미지 확인 중..."
if ! docker image inspect $DOCKER_IMAGE >/dev/null 2>&1; then
    log_error "이미지 '$DOCKER_IMAGE'를 찾을 수 없습니다."
    echo "먼저 이미지를 빌드하세요: docker build -t $DOCKER_IMAGE ."
    exit 1
fi

log_info "이미지 '$DOCKER_IMAGE' 확인됨"

# 이미지 정보 출력
log_step "이미지 정보 확인 중..."
docker images $DOCKER_IMAGE --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# 컨테이너 테스트 실행
log_step "컨테이너 기본 테스트 실행 중..."

CURRENT_ARCH=$(uname -m)
if [ "$CURRENT_ARCH" = "arm64" ]; then
    log_info "Apple Silicon에서 x86_64 에뮬레이션으로 테스트 (플랫폼 경고 무시)"
else
    log_info "x86_64 네이티브 환경에서 테스트"
fi

# 기본 테스트
docker run --rm $DOCKER_IMAGE bash -c "
    echo '=== 시스템 정보 ==='
    echo '아키텍처: \$(uname -m)'
    echo '운영체제: \$(cat /etc/os-release | grep PRETTY_NAME)'
    echo '사용자: \$(whoami)'
    echo
    echo '=== Yocto 환경 확인 ==='
    echo 'Poky 디렉토리: '
    ls -la /opt/poky/ | head -5
    echo
    echo '=== BitBake 확인 ==='
    source /opt/poky/oe-init-build-env /tmp/test >/dev/null 2>&1
    bitbake --version
    echo
    echo '=== Python 패키지 확인 ==='
    python3 --version
    python3 -c \"import git, jinja2; print('Git and Jinja2 모듈 정상')\"
    echo
    echo '=== QEMU 확인 ==='
    qemu-system-x86_64 --version | head -1
    echo
    echo '=== 환경 변수 확인 ==='
    echo \"MACHINE: \$MACHINE\"
    echo \"POKY_DIR: \$POKY_DIR\"
"

if [ $? -eq 0 ]; then
    log_info "✅ 모든 테스트 통과!"
    echo
    log_info "이미지 사용법:"
    echo "  로컬 실행: ./scripts/quick-start.sh"
    echo "  수동 실행: docker run -it $DOCKER_IMAGE"
else
    log_error "❌ 테스트 실패"
    exit 1
fi 