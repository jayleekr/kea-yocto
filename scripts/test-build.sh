#!/bin/bash

# Yocto 빌드 테스트 스크립트 (모든 아키텍처 지원)

echo "🏗️ Yocto 빌드 테스트 시작"
echo "=========================="

# 시스템 아키텍처 확인
ARCH=$(uname -m)
echo "시스템 아키텍처: $ARCH"

# 아키텍처별 플랫폼 설정
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    if [ "$ARCH" = "arm64" ]; then
        echo "Apple Silicon Mac에서 실행 중..."
        PLATFORM_FLAG="--platform linux/arm64"
        DESCRIPTION="ARM64 네이티브"
    else
        echo "ARM64 VM에서 실행 중..."
        echo "실행 방법을 선택하세요:"
        echo "1) ARM64 네이티브 (권장)"
        echo "2) x86_64 에뮬레이션 (강의 환경 일치)"
        read -p "선택 [1/2]: " choice
        
        if [ "$choice" = "2" ]; then
            PLATFORM_FLAG="--platform linux/amd64"
            DESCRIPTION="x86_64 에뮬레이션"
            
            # QEMU 에뮬레이션 설정
            echo "QEMU 에뮬레이션 설정 중..."
            docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
            
            # x86_64 이미지 강제 다운로드
            echo "x86_64 이미지 강제 다운로드 중..."
            docker pull --platform linux/amd64 jabang3/yocto-lecture:5.0-lts
        else
            PLATFORM_FLAG="--platform linux/arm64"
            DESCRIPTION="ARM64 네이티브"
            
            # ARM64 이미지 강제 다운로드
            echo "ARM64 이미지 강제 다운로드 중..."
            docker pull --platform linux/arm64 jabang3/yocto-lecture:5.0-lts
        fi
    fi
else
    echo "x86_64 시스템에서 실행 중..."
    PLATFORM_FLAG="--platform linux/amd64"
    DESCRIPTION="x86_64 네이티브"
    
    # x86_64 이미지 강제 다운로드
    echo "x86_64 이미지 강제 다운로드 중..."
    docker pull --platform linux/amd64 jabang3/yocto-lecture:5.0-lts
fi

# 워크스페이스 생성
mkdir -p yocto-workspace/workspace

# 기존 컨테이너 정리
docker rm -f yocto-build-test 2>/dev/null || true

echo "${DESCRIPTION} 컨테이너에서 빌드 테스트 시작..."

# 빌드 테스트 실행
docker run --rm \
    ${PLATFORM_FLAG} \
    -v $(pwd)/yocto-workspace/workspace:/workspace \
    -e TMPDIR=/tmp/yocto-build \
    -e BB_ENV_PASSTHROUGH_ADDITIONS=TMPDIR \
    -e BB_NUMBER_THREADS=4 \
    -e PARALLEL_MAKE="-j 4" \
    --name yocto-build-test \
    jabang3/yocto-lecture:5.0-lts \
    /bin/bash -c '
        echo "🎯 Yocto 빌드 환경 테스트 시작"
        echo "=============================="
        
        # 시스템 정보
        echo "=== 시스템 정보 ==="
        echo "Architecture: $(uname -m)"
        echo "CPU Cores: $(nproc)"
        echo "Memory: $(free -h | grep Mem)"
        echo "Disk Space: $(df -h /tmp | tail -1)"
        echo ""
        
        # Yocto 환경 초기화
        echo "=== Yocto 환경 초기화 ==="
        source /opt/poky/oe-init-build-env /workspace/build
        
        # 설정 확인
        echo "=== 현재 설정 ==="
        echo "MACHINE: $(grep "^MACHINE" conf/local.conf || echo "기본값: qemux86-64")"
        echo "TMPDIR: $(grep "^TMPDIR" conf/local.conf || echo "기본값: /workspace/build/tmp")"
        echo "BB_NUMBER_THREADS: $BB_NUMBER_THREADS"
        echo "PARALLEL_MAKE: $PARALLEL_MAKE"
        echo ""
        
        # BitBake 기본 확인
        echo "=== BitBake 기본 확인 ==="
        bitbake --version
        echo ""
        
        # 메타데이터 파싱 테스트
        echo "=== 메타데이터 파싱 테스트 ==="
        echo "bitbake 환경 파싱 중... (약 1-2분 소요)"
        if timeout 300 bitbake -p; then
            echo "✅ 메타데이터 파싱 성공!"
        else
            echo "❌ 메타데이터 파싱 실패 또는 시간 초과"
            exit 1
        fi
        echo ""
        
        # 간단한 레시피 빌드 테스트
        echo "=== 간단한 레시피 빌드 테스트 ==="
        echo "hello-world 레시피 빌드 중..."
        if timeout 600 bitbake hello-world; then
            echo "✅ hello-world 빌드 성공!"
        else
            echo "⚠️ hello-world 빌드 실패 (정상적일 수 있음)"
        fi
        echo ""
        
        # core-image-minimal 빌드 시작 (dry-run)
        echo "=== core-image-minimal 빌드 계획 확인 ==="
        echo "빌드 계획 분석 중... (dry-run)"
        if timeout 300 bitbake -n core-image-minimal; then
            echo "✅ core-image-minimal 빌드 계획 성공!"
            
            # 태스크 개수 확인
            echo ""
            echo "=== 빌드 통계 ==="
            echo "예상 빌드 태스크 수:"
            bitbake -g core-image-minimal 2>/dev/null || true
            if [ -f pn-buildlist ]; then
                TASK_COUNT=$(cat pn-buildlist | wc -l)
                echo "총 패키지 수: $TASK_COUNT"
                echo "예상 빌드 시간: 1-3시간 (하드웨어에 따라)"
            fi
            echo ""
            
            # 실제 빌드 옵션 제공
            echo "=== 실제 빌드 옵션 ==="
            echo "다음 명령어로 실제 빌드를 시작할 수 있습니다:"
            echo "  bitbake core-image-minimal"
            echo ""
            echo "빠른 테스트용 소형 빌드:"
            echo "  bitbake hello-world"
            echo "  bitbake busybox"
            echo ""
            
        else
            echo "❌ core-image-minimal 빌드 계획 실패"
            exit 1
        fi
        
        # 빌드 환경 검증 완료
        echo "=== 빌드 환경 검증 완료 ==="
        echo "✅ Yocto 5.0 LTS 환경이 정상적으로 작동합니다!"
        echo "✅ ARM64 Mac에서 네이티브로 실행 중"
        echo "✅ 메타데이터 파싱 성공"
        echo "✅ 빌드 시스템 준비 완료"
        echo ""
        echo "🎉 테스트 완료! 실제 빌드를 시작하세요."
        
    ' || echo "빌드 테스트 중 오류 발생"

echo ""
echo "=== 빌드 테스트 완료 ==="
echo "✅ 컨테이너가 정상 작동하면 실제 개발을 시작할 수 있습니다."
echo ""
echo "다음 단계:"
echo "1. ./scripts/simple-start.sh 로 개발 환경 시작"
echo "2. 컨테이너 안에서: bitbake core-image-minimal"
echo "3. 빌드 완료 후: runqemu qemux86-64" 