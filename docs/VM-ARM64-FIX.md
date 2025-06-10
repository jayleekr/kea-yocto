# 🔧 **ARM64 VM "exec format error" 즉시 해결**

## **🚨 문제 상황**
```bash
docker compose run --rm yocto-lecture
exec /bin/bash: exec format error
```

## **⚡ 즉시 해결 (3가지 방법)**

### **방법 1: 플랫폼 명시적 지정 (가장 빠름)**

#### VM에서 실행:
```bash
# 1. 기존 이미지 제거
docker rmi jabang3/yocto-lecture:5.0-lts

# 2. ARM64 플랫폼 명시하여 다시 pull
docker pull --platform linux/arm64 jabang3/yocto-lecture:5.0-lts

# 3. 테스트
docker run --rm --platform linux/arm64 jabang3/yocto-lecture:5.0-lts uname -m
# 출력되어야 할 값: aarch64
```

### **방법 2: Docker Compose 수정**

#### `docker-compose.yml` 파일 수정:
```yaml
version: '3.8'

services:
  yocto-lecture:
    image: jabang3/yocto-lecture:5.0-lts
    platform: linux/arm64  # 이 줄 추가!
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
```

#### 이후 정상 실행:
```bash
docker compose run --rm yocto-lecture
```

### **방법 3: 직접 Docker 실행**

```bash
# 플랫폼 명시하여 직접 실행
docker run -it --platform linux/arm64 \
  -v $(pwd)/workspace:/workspace \
  -e TMPDIR=/tmp/yocto-build \
  jabang3/yocto-lecture:5.0-lts
```

## **🔍 원인 분석**

### **문제 원인:**
- ARM64 시스템에서 x86_64 이미지를 실행하려고 시도
- Docker가 멀티플랫폼 이미지에서 올바른 아키텍처를 자동 선택하지 못함

### **확인 방법:**
```bash
# 현재 시스템 아키텍처
uname -m
# 출력: aarch64 (ARM64)

# 현재 이미지 아키텍처 확인
docker run --rm jabang3/yocto-lecture:5.0-lts file /bin/bash
# x86_64면 문제, aarch64면 정상

# 이미지 매니페스트 확인 (buildx 설치된 경우)
docker buildx imagetools inspect jabang3/yocto-lecture:5.0-lts
```

## **🎯 완전 자동화 스크립트**

### GitHub에서 스크립트 다운로드:
```bash
# VM에서 실행
curl -sSL https://raw.githubusercontent.com/jayleekr/kea-yocto/main/scripts/fix-arm64-vm.sh | bash
```

### 또는 수동 다운로드:
```bash
wget https://github.com/jayleekr/kea-yocto/archive/main.zip
unzip main.zip
cd kea-yocto-main
./scripts/fix-arm64-vm.sh
```

## **✅ 검증 단계**

### 정상 작동 확인:
```bash
# 1. 시스템 정보
docker run --rm --platform linux/arm64 jabang3/yocto-lecture:5.0-lts uname -a

# 2. Yocto 환경 확인
docker run --rm --platform linux/arm64 jabang3/yocto-lecture:5.0-lts bash -c "
  source /opt/poky/oe-init-build-env /tmp/test && 
  bitbake --version
"

# 3. Docker Compose 테스트
docker compose run --rm yocto-lecture bitbake --version
```

## **🚀 이후 정상 사용법**

### 일반적인 사용:
```bash
# Docker Compose 사용 (권장)
docker compose run --rm yocto-lecture

# 컨테이너 내에서
source /opt/poky/oe-init-build-env
bitbake core-image-minimal
```

### 개발 모드:
```bash
# 지속적 개발용 컨테이너
docker compose up -d yocto-lecture
docker compose exec yocto-lecture bash
```

## **❓ 문제 지속시 디버깅**

### 1단계: 이미지 확인
```bash
docker images | grep yocto-lecture
docker inspect jabang3/yocto-lecture:5.0-lts | grep Architecture
```

### 2단계: 플랫폼 강제
```bash
docker pull --platform linux/arm64 jabang3/yocto-lecture:5.0-lts --quiet
```

### 3단계: Docker 정보
```bash
docker info | grep -E "(Architecture|Operating System)"
docker version
```

### 4단계: 완전 초기화
```bash
docker system prune -a
docker pull --platform linux/arm64 jabang3/yocto-lecture:5.0-lts
```

---

**💡 한줄 요약**: ARM64 VM에서는 `--platform linux/arm64` 옵션을 명시하거나 `docker-compose.yml`에 `platform: linux/arm64`를 추가하세요! 