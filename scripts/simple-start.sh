#!/bin/bash

# 간단한 Yocto 컨테이너 시작 스크립트 (ARM64 네이티브)

echo "🚀 Yocto 컨테이너 간단 시작 (ARM64 네이티브)"
echo "==============================================="

# 워크스페이스 생성
mkdir -p yocto-workspace/workspace

# 기존 컨테이너 정리
docker rm -f yocto-lecture 2>/dev/null || true

echo "컨테이너 시작 중..."

# ARM64 네이티브 모드로 직접 실행
docker run -it --rm \
    --platform linux/arm64 \
    -v $(pwd)/yocto-workspace/workspace:/workspace \
    -e TMPDIR=/tmp/yocto-build \
    -e BB_ENV_PASSTHROUGH_ADDITIONS=TMPDIR \
    --name yocto-lecture \
    jabang3/yocto-lecture:5.0-lts \
    /bin/bash -c "
        echo '🎉 Yocto 5.0 LTS 환경 시작!'
        echo 'Architecture: \$(uname -m)'
        echo 'OS: \$(cat /etc/os-release | head -1)'
        echo ''
        echo '=== Yocto 환경 초기화 ==='
        source /opt/poky/oe-init-build-env /workspace/build
        echo ''
        echo '=== 환경 확인 ==='
        echo 'BitBake 버전:'
        bitbake --version
        echo ''
        echo '=== 빌드 명령어 예시 ==='
        echo '  bitbake core-image-minimal'
        echo '  bitbake -k core-image-minimal  # 에러 무시하고 계속'
        echo ''
        echo '준비 완료! Yocto 빌드를 시작하세요.'
        /bin/bash -l
    "

echo "컨테이너가 종료되었습니다." 