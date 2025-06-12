#!/bin/bash

# VM 사용자 sudo 설정 스크립트
# 사용자를 sudo 그룹에 추가하고 패스워드 없이 sudo를 사용할 수 있도록 설정

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "============================================"
echo "🔧 VM 사용자 sudo 설정"
echo "============================================"
echo

# 현재 사용자 확인
CURRENT_USER=$(whoami)
log_info "현재 사용자: $CURRENT_USER"

# root 사용자 체크
if [ "$CURRENT_USER" = "root" ]; then
    log_error "root 사용자로 실행하지 마세요!"
    echo "일반 사용자로 로그인한 후 실행하세요."
    exit 1
fi

# sudo 권한 확인
if ! sudo -n true 2>/dev/null; then
    log_error "sudo 권한이 필요합니다!"
    echo "현재 사용자가 sudo를 사용할 수 있는지 확인하세요."
    echo ""
    echo "관리자 권한으로 다음 명령을 실행하세요:"
    echo "  sudo usermod -aG sudo $CURRENT_USER"
    exit 1
fi

echo "🚀 한 줄 명령어로 VM 사용자 sudo 설정:"
echo "================================================"
echo ""
echo -e "${BLUE}sudo usermod -aG sudo \$USER && echo \"\$USER ALL=(ALL) NOPASSWD:ALL\" | sudo tee /etc/sudoers.d/\$USER${NC}"
echo ""
echo "📝 이 명령어는 다음을 수행합니다:"
echo "  1. 현재 사용자를 sudo 그룹에 추가"
echo "  2. 패스워드 없이 sudo 사용 가능하도록 설정"
echo ""

read -p "지금 실행하시겠습니까? [y/N]: " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    log_info "sudo 설정을 진행합니다..."
    
    # 한 줄 명령어 실행
    sudo usermod -aG sudo $CURRENT_USER && echo "$CURRENT_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$CURRENT_USER
    
    if [ $? -eq 0 ]; then
        log_info "✅ sudo 설정이 완료되었습니다!"
        echo ""
        echo "설정 완료 후 권한 적용 방법:"
        echo "  1. 로그아웃 후 다시 로그인"
        echo "  2. 또는 새 터미널 세션 시작"
        echo "  3. 또는 'newgrp sudo' 명령어 실행"
        echo ""
        echo "테스트: sudo whoami (패스워드 입력 없이 실행되어야 함)"
    else
        log_error "sudo 설정 중 오류가 발생했습니다."
        exit 1
    fi
else
    echo "설정을 취소했습니다."
    echo ""
    echo "나중에 수동으로 실행하려면:"
    echo -e "${BLUE}sudo usermod -aG sudo \$USER && echo \"\$USER ALL=(ALL) NOPASSWD:ALL\" | sudo tee /etc/sudoers.d/\$USER${NC}"
fi 