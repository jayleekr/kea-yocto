#!/bin/bash

# Yocto 빌드 진행상황 모니터링 스크립트

set -euo pipefail

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_progress() {
    echo -e "${BLUE}[PROGRESS]${NC} $1"
}

echo "📊 KEA Yocto 빌드 모니터링"
echo "=========================="
echo ""

# Docker 컨테이너 ID 자동 감지
CONTAINER_ID=$(docker ps --filter "ancestor=jabang3/yocto-lecture:5.0-lts" --format "{{.ID}}" | head -1)

if [ -z "$CONTAINER_ID" ]; then
    echo "❌ 실행 중인 Yocto 빌드 컨테이너를 찾을 수 없습니다."
    exit 1
fi

log_info "컨테이너 ID: $CONTAINER_ID"
echo ""

while true; do
    # 컨테이너가 여전히 실행 중인지 확인
    if ! docker ps -q --no-trunc | grep -q "$CONTAINER_ID"; then
        echo ""
        log_info "🎉 빌드 컨테이너가 종료되었습니다!"
        break
    fi
    
    # 현재 진행상황 확인
    LATEST_TASK=$(docker logs "$CONTAINER_ID" 2>/dev/null | grep "Running task" | tail -1 || echo "")
    
    if [ -n "$LATEST_TASK" ]; then
        # 태스크 번호 추출
        CURRENT_TASK=$(echo "$LATEST_TASK" | grep -o "task [0-9]* of [0-9]*" | head -1)
        TASK_NAME=$(echo "$LATEST_TASK" | grep -o "(/.*\.bb:" | sed 's#(.*recipes[^/]*/##' | sed 's#/.*\.bb:##' | head -1)
        
        if [ -n "$CURRENT_TASK" ]; then
            # 진행율 계산
            CURRENT_NUM=$(echo "$CURRENT_TASK" | awk '{print $2}')
            TOTAL_NUM=$(echo "$CURRENT_TASK" | awk '{print $4}')
            PERCENTAGE=$(echo "$CURRENT_NUM $TOTAL_NUM" | awk '{printf "%.1f", ($1/$2)*100}')
            
            log_progress "$CURRENT_TASK ($PERCENTAGE%) - $TASK_NAME"
        fi
    fi
    
    # 캐시 상태 확인
    DOWNLOADS_COUNT=$(find yocto-workspace/downloads -type f 2>/dev/null | wc -l || echo "0")
    SSTATE_COUNT=$(find yocto-workspace/sstate-cache -type f 2>/dev/null | wc -l || echo "0")
    
    if [ "$DOWNLOADS_COUNT" -gt 0 ] || [ "$SSTATE_COUNT" -gt 0 ]; then
        echo -n "   📁 Downloads: $DOWNLOADS_COUNT files, sstate: $SSTATE_COUNT files"
        
        # 디렉토리 크기 확인 (빠른 버전)
        if [ -d "yocto-workspace/downloads" ]; then
            DOWNLOADS_SIZE=$(du -sh yocto-workspace/downloads 2>/dev/null | cut -f1 || echo "0B")
            echo -n " ($DOWNLOADS_SIZE)"
        fi
        echo ""
    fi
    
    # 메모리 사용량 확인
    MEMORY_USAGE=$(docker stats --no-stream --format "{{.MemUsage}}" "$CONTAINER_ID" 2>/dev/null || echo "N/A")
    if [ "$MEMORY_USAGE" != "N/A" ]; then
        echo "   💾 메모리 사용량: $MEMORY_USAGE"
    fi
    
    echo ""
    sleep 30  # 30초마다 업데이트
done

# 빌드 완료 후 상태 확인
echo ""
log_info "📋 빌드 완료 후 상태 확인:"

# 최종 로그에서 결과 확인
BUILD_RESULT=$(docker logs "$CONTAINER_ID" 2>/dev/null | tail -20)

if echo "$BUILD_RESULT" | grep -q "빌드 완료"; then
    log_info "✅ 빌드가 성공적으로 완료되었습니다!"
elif echo "$BUILD_RESULT" | grep -q "빌드 실패"; then
    echo "❌ 빌드가 실패했습니다."
    exit 1
else
    echo "⚠️  빌드 상태를 확인할 수 없습니다. 로그를 직접 확인해주세요:"
    echo "   docker logs $CONTAINER_ID | tail -50"
fi

# 캐시 파일 크기 확인
if [ -d "yocto-workspace/downloads" ]; then
    DOWNLOADS_SIZE=$(du -sh yocto-workspace/downloads | cut -f1)
    DOWNLOADS_FILES=$(find yocto-workspace/downloads -type f | wc -l)
    log_info "📦 Downloads 캐시: $DOWNLOADS_SIZE ($DOWNLOADS_FILES files)"
fi

if [ -d "yocto-workspace/sstate-cache" ]; then
    SSTATE_SIZE=$(du -sh yocto-workspace/sstate-cache | cut -f1)
    SSTATE_FILES=$(find yocto-workspace/sstate-cache -type f | wc -l)
    log_info "🏗️  sstate 캐시: $SSTATE_SIZE ($SSTATE_FILES files)"
fi

echo ""
log_info "🔄 다음 단계:"
echo "   1. 캐시 효율성 테스트: ./scripts/quick-cache-test.sh"
echo "   2. 캐시 업로드 준비: ./scripts/upload-cache.sh --dry-run"
echo "   3. 실제 업로드: ./scripts/upload-cache.sh --type local" 