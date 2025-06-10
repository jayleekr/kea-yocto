#!/bin/bash

# 자동 업데이트 스크립트 - Git과 Docker Hub를 항상 최신 상태로 유지

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

# 사용법 확인
if [[ $# -lt 1 ]]; then
    echo "🔄 Yocto 프로젝트 자동 업데이트"
    echo "================================"
    echo ""
    echo "사용법: $0 <commit-message> [--force-rebuild]"
    echo ""
    echo "예시:"
    echo "  $0 \"새로운 스크립트 추가\""
    echo "  $0 \"버그 수정\" --force-rebuild"
    echo ""
    echo "옵션:"
    echo "  --force-rebuild  Docker 이미지 강제 재빌드 트리거"
    echo ""
    exit 1
fi

COMMIT_MESSAGE="$1"
FORCE_REBUILD="${2:-}"

echo "🔄 Yocto 프로젝트 자동 업데이트"
echo "================================"
echo "📝 커밋 메시지: $COMMIT_MESSAGE"
echo "🔧 강제 재빌드: ${FORCE_REBUILD:-비활성화}"
echo

# 1. Git 상태 확인
log_step "Git 리포지토리 상태 확인..."

if ! git diff --quiet || ! git diff --cached --quiet; then
    log_info "변경사항이 감지되었습니다."
    git status --short
else
    log_warning "변경사항이 없습니다."
    echo "계속 진행하시겠습니까? [y/N]"
    read -r response
    if [[ ! "$response" =~ ^[yY]$ ]]; then
        log_info "업데이트를 취소했습니다."
        exit 0
    fi
fi

# 2. 현재 브랜치 확인
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    log_warning "현재 브랜치가 main이 아닙니다: $CURRENT_BRANCH"
    echo "main 브랜치로 전환하시겠습니까? [y/N]"
    read -r response
    if [[ "$response" =~ ^[yY]$ ]]; then
        git checkout main
        git pull origin main
    fi
fi

# 3. 변경사항 커밋 및 푸시
log_step "변경사항 커밋 및 푸시..."

# 모든 변경사항 추가
git add .

# 커밋 (변경사항이 있을 때만)
if ! git diff --cached --quiet; then
    # 강제 재빌드 옵션 처리
    if [[ "$FORCE_REBUILD" == "--force-rebuild" ]]; then
        COMMIT_MESSAGE="$COMMIT_MESSAGE [rebuild]"
        log_info "강제 재빌드 태그 추가: [rebuild]"
    fi
    
    git commit -m "$COMMIT_MESSAGE"
    log_info "✅ 커밋 완료: $(git log -1 --oneline)"
else
    log_info "새로운 변경사항이 없어서 커밋을 건너뜁니다."
fi

# 원격 저장소와 동기화
log_step "원격 저장소와 동기화..."
git pull origin main --rebase || {
    log_error "Pull 중 충돌 발생. 수동으로 해결해주세요."
    exit 1
}

# 푸시
git push origin main
log_info "✅ GitHub 푸시 완료"

# 4. GitHub Actions 트리거 확인
log_step "GitHub Actions 자동 빌드 트리거 확인..."
sleep 2

# 최신 커밋 해시
LATEST_COMMIT=$(git rev-parse HEAD)
SHORT_COMMIT=${LATEST_COMMIT:0:7}

log_info "최신 커밋: $SHORT_COMMIT"
log_info "GitHub Actions이 자동으로 Docker 이미지를 빌드합니다."

# 5. 워크플로우 상태 모니터링
echo
log_step "배포 상태 모니터링..."
echo "🌐 실시간 확인:"
echo "   GitHub Actions: https://github.com/jayleekr/kea-yocto/actions"
echo "   Docker Hub: https://hub.docker.com/r/jabang3/yocto-lecture/tags"
echo

# 6. 자동 배포 상태 확인
log_step "자동 배포 상태 확인 중..."
sleep 5

if command -v ./scripts/check-deployment.sh >/dev/null 2>&1; then
    ./scripts/check-deployment.sh
else
    log_warning "배포 상태 확인 스크립트를 찾을 수 없습니다."
fi

# 7. 완료 안내
echo
log_info "🎉 자동 업데이트 완료!"
echo "======================================="
echo "✅ Git 커밋 및 푸시 완료"
echo "✅ GitHub Actions 트리거됨"
echo "⏳ Docker 이미지 빌드 진행 중 (5-10분 소요)"
echo

echo "📍 모니터링 링크:"
echo "   🔄 GitHub Actions: https://github.com/jayleekr/kea-yocto/actions"
echo "   🐳 Docker Hub: https://hub.docker.com/r/jabang3/yocto-lecture"
echo "   📦 GitHub Packages: https://github.com/jayleekr/kea-yocto/pkgs/container/yocto-lecture"

echo
echo "💡 다음 명령어로 배포 완료를 확인할 수 있습니다:"
echo "   ./scripts/check-deployment.sh"
echo
echo "🚀 VM 사용자들은 몇 분 후 다음 명령으로 최신 이미지를 받을 수 있습니다:"
echo "   docker pull jabang3/yocto-lecture:5.0-lts" 