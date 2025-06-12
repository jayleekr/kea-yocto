# VM에서 Docker 설치 가이드

이 가이드는 **강의장 x86_64 PC의 Ubuntu 24.04 VM**에서 Docker를 설치하고 Yocto 환경을 설정하는 방법을 안내합니다.

## 📋 시스템 요구사항

### 강의장 PC 사양
- **CPU**: x86_64 (Intel/AMD)
- **메모리**: 최소 8GB, 권장 16GB+
- **저장공간**: 최소 50GB 여유 공간
- **가상화**: VT-x/AMD-V 지원 및 활성화

### VM 설정 권장사양
- **메모리**: 6-8GB 할당
- **CPU**: 4-6 코어 할당  
- **디스크**: 40GB+ (동적 할당)
- **네트워크**: NAT 또는 브리지 모드

## 🔧 사전 요구사항

### 시스템 요구사항
- **OS**: Ubuntu 20.04 LTS 이상 (권장: Ubuntu 22.04 LTS)
- **RAM**: 최소 4GB, 권장 8GB 이상
- **Storage**: 최소 20GB 여유 공간
- **CPU**: 가상화 지원 (VT-x/AMD-V 활성화)

### VM 설정 확인
```bash
# 가상화 지원 확인
egrep -c '(vmx|svm)' /proc/cpuinfo
# 0이 아닌 값이 나와야 함

# 시스템 정보 확인
uname -a
lsb_release -a
free -h
df -h
```

## 📦 Docker 설치

### 1단계: 시스템 업데이트 및 기본 패키지 설치

```bash
# 시스템 업데이트
sudo apt-get update
sudo apt-get upgrade -y

# 필수 패키지 설치
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common
```

### 2단계: Docker GPG 키 및 저장소 설정

```bash
# 기존 Docker 관련 패키지 제거 (있다면)
sudo apt-get remove -y docker docker-engine docker.io containerd runc

# Docker의 공식 GPG 키 추가
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Docker 저장소를 Apt sources에 추가
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 패키지 목록 업데이트
sudo apt-get update
```

### 3단계: Docker 엔진 설치

```bash
# 최신 버전 Docker 설치
sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 설치 확인
sudo docker --version
sudo docker compose version
```

### 4단계: Docker Compose 설정

Docker Compose는 두 가지 방식으로 사용할 수 있습니다:

#### 방법 1: Docker Compose Plugin (권장 - 이미 설치됨)
```bash
# Docker 플러그인으로 설치된 compose 확인
docker compose version
```

#### 방법 2: Standalone Docker Compose 설치 (호환성용)
```bash
# 기존 docker-compose 명령어 사용을 위한 standalone 버전 설치
sudo apt-get update
sudo apt-get install -y docker-compose

# 설치 확인
docker-compose --version
```

> 💡 **두 방식의 차이점**:
> - **`docker compose`** (플러그인): 최신 권장 방식, Docker CLI에 통합
> - **`docker-compose`** (standalone): 기존 방식, 별도 Python 패키지
> 
> 둘 다 설치하면 양쪽 명령어 모두 사용 가능합니다.

## 👤 사용자 권한 설정

### Docker 그룹에 사용자 추가
```bash
# 현재 사용자를 docker 그룹에 추가
sudo usermod -aG docker $USER

# 새 그룹 권한 적용 (재로그인 또는 다음 명령어 실행)
newgrp docker

# 또는 시스템 재시작
# sudo reboot
```

### 권한 확인
```bash
# sudo 없이 Docker 명령어 실행 가능한지 확인
docker --version
groups $USER
```

### 🔧 VM 사용자 sudo 설정 (선택사항)

VM에서 패스워드 없이 sudo를 사용하려면 다음 한 줄 명령어를 실행하세요:

```bash
# 사용자를 sudo 그룹에 추가하고 패스워드 없이 sudo 사용 가능하도록 설정
sudo usermod -aG sudo $USER && echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER
```

**이 명령어는 다음을 수행합니다:**
- 현재 사용자를 sudo 그룹에 추가
- 패스워드 입력 없이 sudo 명령어 사용 가능하도록 설정

**설정 후 권한 적용:**
```bash
# 새 터미널 세션 시작하거나 다음 명령어 실행
newgrp sudo

# 또는 로그아웃 후 재로그인

# 테스트 (패스워드 입력 없이 실행되어야 함)
sudo whoami
```

> 💡 **보안 참고**: 이 설정은 개발/학습 환경용입니다. 프로덕션 환경에서는 보안상 권장하지 않습니다.

## 🔄 Docker 서비스 관리

### 서비스 시작 및 활성화
```bash
# Docker 서비스 시작
sudo systemctl start docker

# 부팅 시 자동 시작 활성화
sudo systemctl enable docker

# 서비스 상태 확인
sudo systemctl status docker
```

### Docker 데몬 설정 (선택사항)
```bash
# Docker 데몬 설정 파일 생성/편집
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF

# Docker 서비스 재시작
sudo systemctl restart docker
```

## ✅ 설치 검증

### 1. Hello World 테스트
```bash
# Docker 설치 확인
docker run hello-world
```

### 2. 시스템 정보 확인
```bash
# Docker 시스템 정보
docker system info

# Docker 버전 상세 정보
docker version

# Docker Compose 버전 확인 (두 방식 모두)
docker compose version      # 플러그인 방식
docker-compose --version    # standalone 방식

# 실행 중인 컨테이너 확인
docker ps

# 이미지 목록 확인
docker images
```

### 3. 고급 테스트
```bash
# Ubuntu 컨테이너 실행 테스트
docker run -it --rm ubuntu:22.04 bash

# 컨테이너 내부에서 실행:
# cat /etc/os-release
# exit
```

## 🚀 Yocto 강의 환경 설정

### Docker Compose 확인
```bash
# 플러그인 방식 확인 (권장)
docker compose version

# Standalone 방식 확인
docker-compose --version
```

### Yocto 이미지 다운로드 및 테스트
```bash
# Yocto 강의 환경 이미지 다운로드
docker pull jabang3/yocto-lecture:5.0-lts

# 이미지 확인
docker images jabang3/yocto-lecture

# 기본 이미지 테스트 (Ubuntu 기반 확인)
docker run --rm jabang3/yocto-lecture:5.0-lts cat /etc/os-release

# Yocto 환경 확인 (BitBake는 환경 초기화 후 사용 가능)
docker run --rm jabang3/yocto-lecture:5.0-lts bash -c "source /opt/poky/oe-init-build-env /tmp/test && bitbake --version"
```

## 🔧 VM 환경 최적화

### 메모리 설정
```bash
# 스왑 설정 확인
swapon --show
free -h

# 필요시 스왑 파일 생성 (8GB 예제)
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 영구적으로 적용
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 디스크 정리
```bash
# 불필요한 패키지 제거
sudo apt-get autoremove -y
sudo apt-get autoclean

# Docker 시스템 정리
docker system prune -f
```

### 네트워크 설정 (방화벽)
```bash
# UFW 상태 확인
sudo ufw status

# Docker가 사용하는 포트 허용 (필요시)
sudo ufw allow 2376/tcp  # Docker daemon
sudo ufw allow 2377/tcp  # Docker swarm
```

## 🔧 ARM64 VM 특별 설정 (aarch64)

VM이 ARM64 아키텍처인 경우 x86_64 이미지 실행을 위한 추가 설정이 필요합니다.

### QEMU 에뮬레이션 설정
```bash
# 현재 아키텍처 확인
uname -m
# aarch64 결과가 나오면 ARM64 VM

# QEMU 사용자 에뮬레이션 설치
sudo apt-get update
sudo apt-get install -y qemu-user-static binfmt-support

# 크로스 플랫폼 지원 활성화
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# 에뮬레이션 테스트
docker run --rm --platform linux/amd64 ubuntu:22.04 uname -m
# 결과가 x86_64로 나와야 정상
```

### 플랫폼 명시 이미지 Pull
```bash
# ARM64 VM에서는 반드시 플랫폼을 명시해서 pull
docker pull --platform linux/amd64 jabang3/yocto-lecture:5.0-lts

# 이미지 아키텍처 확인
docker image inspect jabang3/yocto-lecture:5.0-lts --format '{{.Architecture}}'
# amd64 결과가 나와야 함
```

## 🛠️ 문제 해결

### 일반적인 문제들

#### 1. 권한 거부 오류
```bash
# 문제: Got permission denied while trying to connect to the Docker daemon socket
# 해결:
sudo usermod -aG docker $USER
newgrp docker
```

#### 2. Docker Compose 버전 호환성 문제
```bash
# 문제: services.xxx.build contains unsupported option: 'platforms'
# 원인: standalone docker-compose (v1.x)가 일부 최신 기능을 지원하지 않음

# 해결 방법 1: Docker Compose 플러그인 사용 (권장)
docker compose run --rm yocto-lecture

# 해결 방법 2: 최신 Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

#### 3. ARM64 VM에서 exec format error
```bash
# 문제: exec /usr/bin/bash: exec format error
# 원인: ARM64 VM에서 x86_64 이미지 실행 시 에뮬레이션 미설정

# 해결:
sudo apt-get install -y qemu-user-static binfmt-support
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# 올바른 이미지 pull 및 실행:
docker pull --platform linux/amd64 jabang3/yocto-lecture:5.0-lts
docker run --rm --platform linux/amd64 jabang3/yocto-lecture:5.0-lts bash -c "uname -m"
```

#### 4. 서비스 시작 실패
```bash
# Docker 서비스 상태 확인
sudo systemctl status docker

# 로그 확인
sudo journalctl -u docker.service

# 서비스 재시작
sudo systemctl restart docker
```

#### 5. 디스크 공간 부족
```bash
# Docker 디스크 사용량 확인
docker system df

# 사용하지 않는 리소스 정리
docker system prune -a --volumes
```

#### 6. 네트워크 문제
```bash
# Docker 네트워크 확인
docker network ls

# 기본 브리지 네트워크 상태 확인
docker network inspect bridge
```

### VM 특화 문제들

#### 1. 가상화 중첩 비활성화
- **VMware**: VM 설정 → 프로세서 → "Virtualize Intel VT-x/EPT or AMD-V/RVI" 체크
- **VirtualBox**: VM 설정 → 시스템 → 가속 → "Enable VT-x/AMD-V" 체크

#### 2. 메모리 부족
```bash
# 메모리 사용량 모니터링
watch -n 1 free -h

# Docker 컨테이너 메모리 제한
docker run -m 2g jabang3/yocto-lecture:5.0-lts
```

## 📋 설치 완료 체크리스트

- [ ] Ubuntu 시스템 업데이트 완료
- [ ] Docker Engine 설치 완료
- [ ] Docker Compose 설치 확인
- [ ] 사용자 docker 그룹 추가
- [ ] Docker 서비스 자동 시작 설정
- [ ] hello-world 컨테이너 실행 성공
- [ ] Yocto 이미지 다운로드 및 테스트 완료
- [ ] VM 메모리/디스크 최적화 완료

## 🎯 다음 단계

설치가 완료되면 다음과 같이 Yocto 강의 환경을 시작할 수 있습니다:

```bash
# 방법 1: GitHub 프로젝트를 이용한 실행 (권장)
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto
docker-compose run --rm yocto-lecture

# 방법 2: 직접 컨테이너 실행
docker run -it --privileged \
    -v $(pwd)/workspace:/workspace \
    -v $(pwd)/downloads:/opt/yocto/downloads \
    -v $(pwd)/sstate-cache:/opt/yocto/sstate-cache \
    jabang3/yocto-lecture:5.0-lts
```

## 🧪 Yocto 환경 테스트

```bash
# Yocto 프로젝트 클론
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto

# ARM64 VM인 경우 QEMU 에뮬레이션 설정 (한 번만 실행)
if [ "$(uname -m)" = "aarch64" ]; then
    echo "ARM64 VM 감지 - QEMU 에뮬레이션 설정 중..."
    sudo apt-get install -y qemu-user-static binfmt-support
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    docker pull --platform linux/amd64 jabang3/yocto-lecture:5.0-lts
else
    echo "x86_64 VM 감지 - 일반 이미지 다운로드"
    docker pull jabang3/yocto-lecture:5.0-lts
fi

# 실제 Yocto 환경 테스트 방법 1: Docker Compose 플러그인 (권장)
docker compose run --rm yocto-lecture bash -c "
    echo 'Yocto 환경 테스트 시작...'
    source /opt/poky/oe-init-build-env /workspace/test-build
    echo 'BitBake 버전:' 
    bitbake --version
    echo 'Yocto 환경 테스트 완료!'
"

# 실제 Yocto 환경 테스트 방법 2: Standalone docker-compose
docker-compose run --rm yocto-lecture bash -c "
    echo 'Yocto 환경 테스트 시작...'
    source /opt/poky/oe-init-build-env /workspace/test-build
    echo 'BitBake 버전:' 
    bitbake --version
    echo 'Yocto 환경 테스트 완료!'
"
```

> ✅ **강의장 환경**: x86_64 PC에서 네이티브 성능으로 실행됩니다.
>
> 💡 **호환성 참고**: 
> - **`docker compose`** (플러그인): 모든 기능 지원, 권장 방식
> - **`docker-compose`** (standalone): 기본 기능만 지원, 일부 제한 있음
> - **ARM64 VM**: QEMU 에뮬레이션으로 x86_64 이미지 실행 (약간 느림)
>
> 📝 **참고**: 이 이미지는 multi-platform을 지원하므로 개발자의 Apple Silicon Mac에서도 테스트 가능합니다.

## 📞 지원

문제가 발생하면:
1. **로그 확인**: `sudo journalctl -u docker.service`
2. **GitHub Issues**: https://github.com/jayleekr/kea-yocto/issues
3. **Docker 공식 문서**: https://docs.docker.com/

**Happy Docker & Yocto Learning! 🚀** 