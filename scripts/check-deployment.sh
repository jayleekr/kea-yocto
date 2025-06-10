#!/bin/bash

# GitHub Actions 및 Docker Hub 배포 상태 확인 스크립트

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔍 Yocto 프로젝트 배포 상태 확인"
echo "=================================="
echo

# GitHub 상태 확인
log_step "GitHub 리포지토리 상태 확인..."
GIT_REMOTE=$(git remote get-url origin)
REPO_URL=${GIT_REMOTE%.git}
REPO_URL=${REPO_URL#https://github.com/}

log_info "리포지토리: $REPO_URL"
log_info "현재 브랜치: $(git branch --show-current)"
log_info "최신 커밋: $(git log -1 --oneline)"

echo
log_step "GitHub Actions 워크플로우 확인..."
echo "🌐 GitHub Actions 페이지:"
echo "   https://github.com/$REPO_URL/actions"
echo

# Docker Hub 이미지 확인
log_step "Docker Hub 이미지 상태 확인..."

DOCKER_IMAGES=(
    "jabang3/yocto-lecture:5.0-lts"
    "jabang3/yocto-lecture:latest"
)

for image in "${DOCKER_IMAGES[@]}"; do
    log_info "이미지 확인: $image"
    
    if docker manifest inspect $image >/dev/null 2>&1; then
        echo "  ✅ 이미지 존재"
        
        # 이미지 정보 출력
        docker manifest inspect $image 2>/dev/null | jq -r '
            if .manifests then
                "  📋 지원 플랫폼: " + (.manifests | map(.platform.architecture + "/" + .platform.os) | join(", "))
            else
                "  🏗️ 단일 플랫폼: " + .architecture + "/" + .os
            end
        ' 2>/dev/null || echo "  📋 플랫폼 정보 확인 불가"
        
    else
        echo "  ❌ 이미지 없음 또는 접근 불가"
    fi
    echo
done

# GHCR 이미지 확인
log_step "GitHub Container Registry 확인..."
GHCR_IMAGE="ghcr.io/jayleekr/yocto-lecture:5.0-lts"

log_info "GHCR 이미지: $GHCR_IMAGE"
if docker manifest inspect $GHCR_IMAGE >/dev/null 2>&1; then
    echo "  ✅ GHCR 이미지 존재"
    docker manifest inspect $GHCR_IMAGE 2>/dev/null | jq -r '
        if .manifests then
            "  📋 지원 플랫폼: " + (.manifests | map(.platform.architecture + "/" + .platform.os) | join(", "))
        else
            "  🏗️ 단일 플랫폼: " + .architecture + "/" + .os
        end
    ' 2>/dev/null || echo "  📋 플랫폼 정보 확인 불가"
else
    echo "  ❌ GHCR 이미지 없음 또는 접근 불가"
fi

echo
log_step "로컬 이미지 테스트..."

# 로컬에서 이미지 테스트
TEST_IMAGE="jabang3/yocto-lecture:5.0-lts"
log_info "로컬 테스트 이미지: $TEST_IMAGE"

if docker image inspect $TEST_IMAGE >/dev/null 2>&1; then
    log_info "로컬 이미지 존재 - 기본 테스트 실행 중..."
    
    # 간단한 테스트 실행
    docker run --rm $TEST_IMAGE /bin/bash -c '
        echo "✅ 컨테이너 실행: $(uname -m)"
        echo "✅ Yocto 버전: $(source /opt/poky/oe-init-build-env /tmp/test >/dev/null 2>&1 && bitbake --version 2>/dev/null || echo "확인 불가")"
        echo "✅ 환경 준비 완료"
    ' 2>/dev/null && log_info "✅ 로컬 이미지 테스트 성공" || log_warning "⚠️ 로컬 이미지 테스트 실패"
else
    log_warning "로컬에 이미지가 없습니다."
    echo "다음 명령으로 다운로드할 수 있습니다:"
    echo "  docker pull $TEST_IMAGE"
fi

echo
log_step "배포 상태 요약..."
echo "==================================="
echo "🌐 GitHub 리포지토리: https://github.com/$REPO_URL"
echo "🔄 GitHub Actions: https://github.com/$REPO_URL/actions"
echo "🐳 Docker Hub: https://hub.docker.com/r/jabang3/yocto-lecture"
echo "📦 GHCR: https://github.com/jayleekr/kea-yocto/pkgs/container/yocto-lecture"
echo

log_info "배포 확인이 완료되었습니다!"
echo "GitHub Actions가 완료되면 몇 분 내에 이미지가 업데이트됩니다."

# 유용한 명령어 표시
echo
echo "=== 유용한 명령어 ==="
echo "이미지 강제 업데이트: docker pull --no-cache $TEST_IMAGE"
echo "워크플로우 상태 확인: gh run list --repo $REPO_URL"
echo "로컬 테스트 실행: ./scripts/test-build.sh" 