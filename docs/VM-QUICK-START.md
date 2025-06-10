# VM 빠른 시작 가이드

**Yocto 5.0 LTS 강의 환경**을 VM에서 빠르게 설정하는 가이드입니다.

## 🎯 VM별 맞춤 가이드

### 1️⃣ x86_64 Ubuntu VM (권장)

**최적화된 VM 전용 스크립트**를 사용하세요:

```bash
# 프로젝트 클론
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto

# VM 전용 시작 스크립트 실행
./scripts/vm-start.sh
```

**vm-start.sh 특징:**
- ✅ x86_64 VM에 최적화됨
- ✅ 플랫폼 강제 지정 (`--platform linux/amd64`)
- ✅ Docker 권한 자동 확인
- ✅ 이미지 아키텍처 검증
- ✅ CPU 코어 수에 따른 자동 최적화

### 2️⃣ ARM64 VM (aarch64)

ARM64 VM에서는 추가 설정이 필요합니다:

```bash
# 1. 멀티플랫폼 지원 설치
sudo apt-get install -y qemu-user-static binfmt-support

# 2. QEMU 에뮬레이션 활성화
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# 3. x86_64 이미지 강제 다운로드
docker pull --platform linux/amd64 jabang3/yocto-lecture:5.0-lts

# 4. VM 스크립트 실행
./scripts/vm-start.sh
```

## 🔧 VM 환경 준비

### Docker 설치 (Ubuntu)

```bash
# 1. 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# 2. Docker 설치
sudo apt install docker.io -y

# 3. Docker 서비스 시작
sudo systemctl start docker
sudo systemctl enable docker

# 4. 사용자 권한 설정
sudo usermod -aG docker $USER

# 5. 재로그인 후 확인
newgrp docker
docker --version
```

### Git 설치 (필요한 경우)

```bash
sudo apt install git -y
```

## 🚀 실행 및 테스트

### 기본 실행

```bash
cd kea-yocto
./scripts/vm-start.sh
```

### 실행 결과 예시

```
🚀 VM용 Yocto 5.0 LTS 강의 환경 시작
============================================

[INFO] 시스템 아키텍처: x86_64
[STEP] Docker 설치 확인 중...
[STEP] 워크스페이스 생성 중...
[INFO] 워크스페이스: yocto-workspace
[STEP] x86_64 Docker 이미지 다운로드 중...
[INFO] 이미지 아키텍처: amd64
[INFO] CPU 코어: 4
[INFO] BitBake 스레드: 4
[INFO] 병렬 빌드: -j 4

🎯 VM용 Yocto 5.0 LTS 환경 시작!
=================================
아키텍처: x86_64
OS: NAME="Ubuntu"
CPU 코어: 4

=== Yocto 환경 초기화 ===
This is the default build configuration for the Poky reference distribution.

### Shell environment set up for builds. ###

=== 환경 확인 ===
BitBake 버전: BitBake Build Tool Core version 2.8.0
MACHINE: qemux86-64
TMPDIR: /tmp/yocto-build
BB_NUMBER_THREADS: 4
PARALLEL_MAKE: -j 4

🚀 준비 완료! 빌드를 시작하세요.
```

## 🧪 빌드 테스트

컨테이너 안에서 다음 명령어로 빌드를 테스트하세요:

```bash
# 빌드 계획 확인 (빠름)
bitbake -n core-image-minimal

# 간단한 패키지 빌드
bitbake hello-world

# 전체 최소 이미지 빌드 (1-2시간)
bitbake core-image-minimal
```

## ❗ 문제 해결

### exec format error

x86_64 VM에서 이 오류가 발생하면:

```bash
# 1. 기존 이미지 삭제
docker rmi jabang3/yocto-lecture:5.0-lts

# 2. 플랫폼 명시하여 다운로드
docker pull --platform linux/amd64 jabang3/yocto-lecture:5.0-lts

# 3. VM 스크립트 재실행
./scripts/vm-start.sh
```

### Docker 권한 오류

```bash
# 권한 설정
sudo usermod -aG docker $USER
newgrp docker

# 또는 sudo로 실행
sudo ./scripts/vm-start.sh
```

### 메모리 부족

VM에 최소 8GB RAM을 할당하세요:

```bash
# BitBake 스레드 수 줄이기
export BB_NUMBER_THREADS=2
export PARALLEL_MAKE="-j 2"
```

## 🔗 추가 가이드

- **ARM64 수정**: [VM-ARM64-FIX.md](VM-ARM64-FIX.md)
- **Docker 설치**: [vm-docker-installation.md](vm-docker-installation.md)
- **보안 설정**: [SECURITY-GUIDE.md](SECURITY-GUIDE.md)

## 📞 지원

문제가 지속되면:
1. [GitHub Issues](https://github.com/jayleekr/kea-yocto/issues)에 문의
2. 시스템 정보와 오류 메시지 포함
3. `uname -a` 및 `docker --version` 출력 첨부 