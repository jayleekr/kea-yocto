# Yocto 5.0 LTS 강의 환경

**KEA Yocto Project 강의**를 위한 완전한 Docker 기반 개발 환경입니다.

## 🚀 빠른 시작

### 시스템 요구사항
- **Docker**: 20.10 이상 설치 필요
- **RAM**: 최소 8GB, 권장 16GB
- **Storage**: 최소 50GB 여유 공간
- **CPU**: 4코어 이상 권장

### 환경별 시작 방법

#### **x86_64 VM/Ubuntu** (강의실 환경, 권장)
```bash
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto
./scripts/vm-start.sh
```

#### **ARM64 VM/Ubuntu** (aarch64)
```bash
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto
./scripts/arm64-vm-fix.sh
```

#### **ARM64 Mac** (Apple Silicon)
```bash
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto
./scripts/simple-start.sh
```

#### **Docker Compose** (일반적인 경우)
```bash
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto
docker compose run --rm yocto-lecture
```

> 💡 **문제 발생 시**: [VM 설치 가이드](docs/vm-docker-installation.md) 또는 [문제해결 가이드](docs/troubleshooting.md) 참조

---

## 📖 강의 개요

본 프로젝트는 **Yocto Project 5.0 LTS (Scarthgap)** 기반의 8시간 집중 강의를 위한 Docker 환경을 제공합니다.

## 🏗️ 시스템 아키텍처

```
┌───────────────────────────────────────────────────────────┐
│                     Host System                          │
│                (Windows, macOS, Linux)                   │
├───────────────────────────────────────────────────────────┤
│                    Docker Engine                         │
├───────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐  │
│  │              Yocto Container                        │  │
│  │                                                     │  │
│  │  ┌─────────────────┐    ┌─────────────────┐        │  │
│  │  │  Ubuntu 24.04   │    │  Poky 5.0 LTS   │        │  │
│  │  │     Base        │    │   Repository    │        │  │
│  │  └─────────────────┘    └─────────────────┘        │  │
│  │                                                     │  │
│  │  ┌─────────────────┐    ┌─────────────────┐        │  │
│  │  │    BitBake      │    │      QEMU       │        │  │
│  │  │   Build Tool    │    │    Emulator     │        │  │
│  │  └─────────────────┘    └─────────────────┘        │  │
│  │                                                     │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────┘
```

### 아키텍처 구성 요소
- **Host System**: Windows, macOS, Linux 등 다양한 운영체제
- **Docker Engine**: 컨테이너 실행 환경
- **Yocto Container**: 
  - **Ubuntu 24.04 Base**: 안정적인 베이스 시스템
  - **Poky 5.0 LTS Repository**: Yocto 참조 배포판
  - **BitBake Build Tool**: 빌드 시스템 엔진
  - **QEMU Emulator**: 타겟 하드웨어 에뮬레이션

### 🎯 학습 목표
- Yocto Project의 기본 개념과 구조 이해
- 커스텀 리눅스 배포판 생성 능력 배양
- 레이어와 레시피 작성 방법 습득
- 실제 임베디드 시스템 개발 경험

### 📚 강의 일정 (8시간)

| 시간 | 내용 | 유형 |
|------|------|------|
| 09:00 - 09:30 | 강의 소개 및 개요 | 이론 |
| 09:30 - 10:30 | Yocto 기본 구조 및 아키텍처 | 이론 |
| 10:45 - 11:30 | Yocto 빌드 환경 설정 | 실습 |
| 11:30 - 12:30 | 첫 빌드: 코어 이미지 및 빌드 프로세스 | 실습 + 이론 |
| 13:30 - 14:00 | 빌드된 이미지 실행하기 | 실습 |
| 14:00 - 14:30 | 이미지 커스터마이징: 패키지 추가 | 실습 |
| 14:45 - 16:00 | 커스텀 레이어 및 레시피 생성 | 실습 |
| 16:00 - 16:30 | Yocto 고급 주제 개요 | 이론 |
| 16:30 - 17:00 | 마무리 및 Q&A | 토론 |

## 🛠️ 실습 가이드

### 1단계: 환경 준비

Docker가 설치되어 있지 않다면 [VM Docker 설치 가이드](docs/vm-docker-installation.md)를 참조하여 설치하세요.

### 2단계: 프로젝트 다운로드

```bash
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto
```

### 3단계: 컨테이너 실행

```bash
# 대화형 모드로 실행 (권장)
docker compose run --rm yocto-lecture

# 또는 미리 빌드된 이미지 직접 사용
docker run -it --rm \
  -v $(pwd)/yocto-workspace:/workspace \
  jabang3/yocto-lecture:5.0-lts
```

### 4단계: Yocto 환경 초기화

컨테이너 내에서 다음 명령어를 실행하세요:

```bash
# Yocto 빌드 환경 초기화
source /opt/poky/oe-init-build-env /workspace/build

# 또는 편의 함수 사용
yocto_init
```

### 5단계: 첫 번째 빌드

```bash
# core-image-minimal 빌드 (약 1-2시간 소요)
bitbake core-image-minimal

# 또는 편의 함수 사용
yocto_quick_build
```

### 6단계: 이미지 실행

```bash
# QEMU에서 빌드된 이미지 실행
runqemu qemux86-64 core-image-minimal

# 종료할 때는 QEMU 콘솔에서
poweroff
```

### 7단계: 패키지 추가하기

```bash
# local.conf 파일에 패키지 추가
echo 'IMAGE_INSTALL:append = " nano"' >> conf/local.conf

# 다시 빌드
bitbake core-image-minimal

# 실행해서 nano가 설치되었는지 확인
runqemu qemux86-64 core-image-minimal
```

### 8단계: 커스텀 레이어 만들기

```bash
# 새 레이어 생성
bitbake-layers create-layer ../meta-myapp

# 레이어 추가
bitbake-layers add-layer ../meta-myapp

# 레이어 목록 확인
bitbake-layers show-layers
```

## 📁 프로젝트 구조

```
kea-yocto/
├── README.md                    # 이 파일
├── Dockerfile                   # Docker 이미지 정의
├── docker-compose.yml          # Docker Compose 설정
├── scripts/                     # 편의 스크립트들
│   ├── vm-start.sh             # x86_64 VM용 시작 스크립트
│   ├── arm64-vm-fix.sh         # ARM64 VM용 수정 스크립트
│   ├── simple-start.sh         # Mac용 간단 시작 스크립트
│   └── ...
├── docs/                        # 문서
│   ├── vm-docker-installation.md  # VM에서 Docker 설치 가이드
│   ├── troubleshooting.md       # 문제해결 가이드
│   └── ...
├── examples/                    # 예제 코드
│   └── meta-myapp/             # 커스텀 레이어 예제
└── yocto-workspace/            # 작업 공간 (빌드 결과물 저장)
    ├── workspace/              # 빌드 디렉토리
    ├── downloads/              # 다운로드 캐시
    └── sstate-cache/           # 상태 캐시
```

## 🔧 유용한 명령어

### 컨테이너 관리
```bash
# 컨테이너 중지
docker compose down

# 컨테이너 상태 확인
docker compose ps

# 로그 확인
docker compose logs -f
```

### Yocto 명령어
```bash
# 빌드 환경 초기화
source /opt/poky/oe-init-build-env /workspace/build

# 사용 가능한 머신 확인
ls /opt/poky/meta*/conf/machine/

# 사용 가능한 이미지 확인
ls /opt/poky/meta*/recipes*/images/

# 레시피 정보 확인
bitbake -s | grep <package-name>

# 패키지 의존성 확인
bitbake -g <package-name>
```

## 🚨 문제해결

### 일반적인 문제들

1. **디스크 공간 부족**
   ```bash
   # Docker 시스템 정리
   docker system prune -a
   
   # 빌드 캐시 정리
   rm -rf yocto-workspace/workspace/build/tmp
   ```

2. **메모리 부족**
   ```bash
   # local.conf에서 병렬 작업 수 조정
   echo 'BB_NUMBER_THREADS = "2"' >> conf/local.conf
   echo 'PARALLEL_MAKE = "-j 2"' >> conf/local.conf
   ```

3. **네트워크 연결 문제**
   ```bash
   # 프록시 설정이 필요한 경우 local.conf에 추가
   echo 'http_proxy = "http://proxy.company.com:8080"' >> conf/local.conf
   echo 'https_proxy = "http://proxy.company.com:8080"' >> conf/local.conf
   ```

더 자세한 문제해결 방법은 [문제해결 가이드](docs/troubleshooting.md)를 참조하세요.

## 📖 추가 문서

- [VM에서 Docker 설치하기](docs/vm-docker-installation.md)
- [ARM64 VM 수정 가이드](docs/VM-ARM64-FIX.md)
- [VM 빠른 시작 가이드](docs/VM-QUICK-START.md)
- [보안 가이드](docs/SECURITY-GUIDE.md)
- [문제해결 가이드](docs/troubleshooting.md)

## ⚡ 편의 기능

컨테이너 내에서 다음 편의 함수들을 사용할 수 있습니다:

- `yocto_init`: Yocto 빌드 환경 초기화
- `yocto_quick_build`: 빠른 빌드 (core-image-minimal)
- `yocto_clean`: 빌드 캐시 정리
- `yocto_help`: 도움말 표시

## 🎯 학습 팁

1. **첫 빌드는 시간이 오래 걸립니다** (1-3시간)
   - 네트워크에서 소스 코드를 다운로드하고 컴파일하기 때문입니다
   - 두 번째 빌드부터는 캐시를 사용하여 훨씬 빠릅니다

2. **병렬 빌드 조정**
   - 메모리가 부족하면 `BB_NUMBER_THREADS`와 `PARALLEL_MAKE`를 줄이세요
   - 충분한 메모리가 있으면 값을 늘려서 빌드 속도를 향상시킬 수 있습니다

3. **sstate 캐시 활용**
   - 컨테이너를 삭제하더라도 `yocto-workspace/sstate-cache`는 보존됩니다
   - 다음 빌드에서 캐시를 재사용하여 시간을 절약할 수 있습니다

Happy coding! 🚀 