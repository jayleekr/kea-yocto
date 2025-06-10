#!/bin/bash

# Docker 자격증명 문제 해결 스크립트

echo "🔧 Docker 자격증명 문제 해결 중..."

# Docker config 디렉토리 확인
DOCKER_CONFIG_DIR="${HOME}/.docker"
if [ ! -d "$DOCKER_CONFIG_DIR" ]; then
    echo "Docker 설정 디렉토리 생성 중..."
    mkdir -p "$DOCKER_CONFIG_DIR"
fi

# config.json 백업 및 수정
CONFIG_FILE="${DOCKER_CONFIG_DIR}/config.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "기존 config.json 백업 중..."
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
fi

# 문제가 되는 credential helper 제거
echo "credential helper 설정 수정 중..."
cat > "$CONFIG_FILE" << 'EOF'
{
    "auths": {},
    "credsStore": ""
}
EOF

echo "✅ Docker 자격증명 설정 수정 완료"
echo ""
echo "이제 다음 명령어로 다시 로그인하세요:"
echo "docker login"
echo ""
echo "또는 토큰을 사용하여 로그인:"
echo "echo 'YOUR_TOKEN' | docker login --username YOUR_USERNAME --password-stdin" 