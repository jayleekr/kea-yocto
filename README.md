# Yocto 5.0 LTS 강의 환경 자동화 프로젝트

> Docker 기반의 Yocto Project 5.0 LTS 학습 환경을 자동으로 제공하는 프로젝트입니다.

[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![Yocto](https://img.shields.io/badge/Yocto-5.0_LTS-green.svg)](https://www.yoctoproject.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04_LTS-orange.svg)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 📖 프로젝트 개요

본 프로젝트는 **Yocto Project 5.0 LTS (Scarthgap)** 기반의 8시간 집중 강의를 위한 Docker 환경을 제공합니다. 강의 참석자들이 일관된 환경에서 실습할 수 있도록 사전 구성된 컨테이너를 Docker Hub를 통해 배포합니다.

### 🎯 주요 목표
- **일관성**: 모든 참석자가 동일한 환경에서 실습
- **간편성**: 복잡한 환경 설정 없이 즉시 시작
- **재현성**: 언제든지 동일한 결과를 얻을 수 있는 환경
- **확장성**: 다양한 하드웨어에서 동작 가능

## 🏗️ 시스템 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    Host System                             │
├─────────────────────────────────────────────────────────────┤
│                   Docker Engine                            │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐ │
│ │              Yocto Container                            │ │
│ │ ┌─────────────────┐  ┌─────────────────┐              │ │
│ │ │  Ubuntu 24.04   │  │  Poky 5.0 LTS   │              │ │
│ │ │     Base        │  │   Repository    │              │ │
│ │ └─────────────────┘  └─────────────────┘              │ │
│ │ ┌─────────────────┐  ┌─────────────────┐              │ │
│ │ │   BitBake       │  │      QEMU       │              │ │
│ │ │   Build Tool    │  │   Emulator      │              │ │
│ │ └─────────────────┘  └─────────────────┘              │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 📚 강의 커리큘럼

### 🕘 전체 일정 (8시간)

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

### 🎓 학습 목표
- Yocto Project의 기본 개념과 구조 이해
- 커스텀 리눅스 배포판 생성 능력 배양
- 레이어와 레시피 작성 방법 습득
- 실제 임베디드 시스템 개발 경험

## 🚀 빠른 시작

### 시스템 요구사항
- **OS**: Linux (권장), macOS (Intel/Apple Silicon), Windows (WSL2)
- **Docker**: 20.10 이상
- **Docker Compose**: 2.0 이상
- **RAM**: 최소 8GB, 권장 16GB
- **Storage**: 최소 50GB 여유 공간
- **CPU**: 4코어 이상 권장

> 📖 **VM 환경에서 Docker 설치가 필요한 경우**: [VM Docker 설치 가이드](docs/vm-docker-installation.md)를 참조하세요.

### 1단계: 프로젝트 클론 또는 Docker 이미지 다운로드

#### 옵션 A: 프로젝트 클론하여 빌드
```bash
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto
```

#### 옵션 B: 사전 빌드된 이미지 사용 (권장)
```bash
# Docker Hub에서 직접 다운로드
docker pull jabang3/yocto-lecture:5.0-lts
docker pull jabang3/yocto-lecture:latest
```

### 2단계: 워크스페이스 생성
```bash
mkdir -p yocto-workspace/{workspace,downloads,sstate-cache}
```

### 3단계: Docker Compose로 빌드 및 실행

#### 🔨 이미지 빌드
```bash
# Docker 이미지 빌드
docker-compose build

# 캐시 없이 완전 재빌드
docker-compose build --no-cache
```

#### 🚀 컨테이너 실행
```bash
# 대화형 모드로 실행 (권장)
docker-compose run --rm yocto-lecture

# 백그라운드에서 실행
docker-compose up -d

# 실행 중인 컨테이너에 접속
docker-compose exec yocto-lecture /bin/bash
```

#### 🛑 컨테이너 관리
```bash
# 컨테이너 중지
docker-compose down

# 컨테이너 상태 확인
docker-compose ps

# 로그 확인
docker-compose logs -f
```

#### 🔧 개발용 고성능 컨테이너
```bash
# 개발용 컨테이너 시작 (더 많은 CPU/메모리 할당)
docker-compose --profile dev up -d yocto-lecture-dev

# 개발용 컨테이너 접속
docker-compose --profile dev exec yocto-lecture-dev /bin/bash

# 개발용 컨테이너 중지
docker-compose --profile dev down
```

### 4단계: Yocto 환경 초기화
```bash
# 컨테이너 내에서 실행
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
# QEMU로 빌드된 이미지 실행
runqemu qemux86-64 core-image-minimal

# 또는 편의 함수 사용
yocto_run_qemu
```

## 📂 프로젝트 구조

```
yocto-lecture/
├── 📄 README.md                 # 프로젝트 메인 문서
├── 📄 Dockerfile               # Docker 이미지 빌드 파일
├── 📄 docker-compose.yml       # Docker Compose 설정
├── 📁 docs/                    # 문서 디렉토리
│   ├── 📄 yocto_lecture.md     # 강의 실라버스
│   ├── 📄 project_config.md    # 프로젝트 설정
│   └── 📄 workflow.md          # 워크플로우 정의
├── 📁 scripts/                 # 자동화 스크립트
│   ├── 🔧 setup.sh            # 환경 설정 스크립트
│   ├── 🔧 build-env.sh        # 빌드 환경 초기화
│   ├── 🔧 quick-start.sh      # 빠른 시작 스크립트
│   ├── 🔧 test-image.sh       # 이미지 테스트
│   └── 🔧 cleanup.sh          # 정리 스크립트
├── 📁 configs/                 # 설정 파일 템플릿
│   ├── ⚙️ local.conf.template   # BitBake 로컬 설정
│   └── ⚙️ bblayers.conf.template # 레이어 설정
├── 📁 examples/                # 실습 예제
│   ├── 📁 meta-myapp/         # 커스텀 레이어 예제
│   └── 📄 helloworld_1.0.bb   # 샘플 레시피
└── 📁 yocto-workspace/         # 작업 공간 (자동 생성)
    ├── 📁 workspace/          # Yocto 빌드 작업공간
    ├── 📁 downloads/          # 패키지 다운로드 캐시
    └── 📁 sstate-cache/       # 빌드 상태 캐시
```

## 🛠️ Docker Compose 서비스 구성

### 기본 서비스 (yocto-lecture)
- **CPU**: 4코어
- **메모리**: 적당한 할당
- **포트**: 2222 (SSH), 5555 (QEMU), 8080 (웹서버)
- **용도**: 일반적인 학습 및 실습

### 개발 서비스 (yocto-lecture-dev)
- **CPU**: 8코어
- **메모리**: 높은 할당
- **포트**: 2223 (SSH), 5556 (QEMU), 8081 (웹서버)
- **용도**: 고성능이 필요한 개발 작업
- **활성화**: `--profile dev` 플래그로 실행

## 💡 유용한 Docker Compose 명령어

### 빌드 관련
```bash
# 특정 서비스만 빌드
docker-compose build yocto-lecture

# 병렬 빌드 (빠른 빌드)
docker-compose build --parallel

# 빌드 중 진행상황 확인
docker-compose build --progress plain
```

### 실행 관련
```bash
# 특정 서비스만 실행
docker-compose up yocto-lecture

# 스케일링 (같은 서비스 여러 개)
docker-compose up --scale yocto-lecture=2

# 강제 재생성
docker-compose up --force-recreate
```

### 관리 관련
```bash
# 모든 컨테이너와 네트워크 제거
docker-compose down --volumes --remove-orphans

# 이미지까지 함께 제거
docker-compose down --rmi all

# 특정 서비스 재시작
docker-compose restart yocto-lecture

# 리소스 사용량 확인
docker-compose top
```

### 로그 관리
```bash
# 특정 서비스 로그만 보기
docker-compose logs yocto-lecture

# 실시간 로그 + 타임스탬프
docker-compose logs -f -t

# 최근 로그만 보기
docker-compose logs --tail=100
```

## 🛠️ 주요 기능

### ✨ 사전 구성된 환경
- **Ubuntu 24.04 LTS** 기반 안정적인 환경
- **Yocto 5.0 LTS** 사전 설치 및 설정
- **필수 패키지** 및 **의존성** 자동 설치
- **QEMU 에뮬레이터** 완전 설정

### 🔧 최적화 기능
- **sstate 캐시** 볼륨 마운트로 빌드 시간 단축
- **다운로드 캐시** 공유로 네트워크 트래픽 절약
- **멀티코어 빌드** 지원으로 성능 최적화
- **증분 빌드** 지원으로 개발 효율성 증대

### 🔧 실습 지원 도구
- **단계별 스크립트** 제공
- **자동화된 환경 설정**
- **트러블슈팅 가이드**
- **실시간 로그 모니터링**

## 🧑‍💻 실습 가이드

### 실습 1: 기본 환경 확인
```bash
# BitBake 버전 확인
bitbake --version

# 사용 가능한 레이어 확인
bitbake-layers show-layers

# 사용 가능한 이미지 확인
ls meta*/recipes*/images/*.bb
```

### 실습 2: 설정 커스터마이징
```bash
# local.conf 편집
nano conf/local.conf

# 주요 설정 항목
MACHINE = "qemux86-64"
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"
DL_DIR = "/opt/yocto/downloads"
SSTATE_DIR = "/opt/yocto/sstate-cache"
```

### 실습 3: 패키지 추가
```bash
# 이미지에 패키지 추가
echo 'IMAGE_INSTALL:append = " nano vim git"' >> conf/local.conf

# 증분 빌드 수행
bitbake core-image-minimal
```

### 실습 4: 커스텀 레이어 생성
```bash
# 새 레이어 생성
bitbake-layers create-layer ../meta-myapp

# 레이어 추가
bitbake-layers add-layer ../meta-myapp

# 레이어 확인
bitbake-layers show-layers
```

### 실습 5: 커스텀 레시피 작성
```bash
# helloworld 레시피 생성
mkdir -p ../meta-myapp/recipes-hello/helloworld
cat > ../meta-myapp/recipes-hello/helloworld/helloworld_1.0.bb << 'EOF'
DESCRIPTION = "Simple Hello World application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://helloworld.c"
S = "${WORKDIR}"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} -o helloworld helloworld.c
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 helloworld ${D}${bindir}
}
EOF

# 소스 파일 생성
mkdir -p ../meta-myapp/recipes-hello/helloworld/files
cat > ../meta-myapp/recipes-hello/helloworld/files/helloworld.c << 'EOF'
#include <stdio.h>
int main() {
    printf("Hello, Yocto World!\n");
    return 0;
}
EOF

# 빌드 및 테스트
bitbake helloworld
bitbake core-image-minimal
```

## 🍎 Apple Silicon Mac 사용자 가이드

### Mac에서 x86_64 이미지 빌드하기
```bash
# Docker buildx를 이용한 멀티 아키텍처 빌드
./scripts/build-multiarch.sh your-dockerhub-username

# 빌드 옵션 선택:
# 1) 로컬 테스트 빌드만 (현재 아키텍처)
# 2) x86_64 전용 빌드 및 푸시 (강의용)
# 3) 멀티 아키텍처 빌드 및 푸시
# 4) 모든 빌드 수행
```

### Mac에서 x86_64 이미지 테스트하기
```bash
# 에뮬레이션으로 x86_64 이미지 테스트
./scripts/test-x86-on-mac.sh

# 옵션:
# -i, --interactive    대화형 테스트
# -q, --quick         빠른 빌드 테스트만
# -p, --performance   성능 벤치마크
# -c, --cleanup       테스트 환경 정리
```

### 성능 고려사항
- **Apple Silicon**에서 **x86_64 에뮬레이션**은 네이티브 실행 대비 **2-3배 느림**
- 개발은 **arm64** 네이티브로, 강의 배포는 **x86_64**로 권장
- 빌드 시간을 고려하여 **BB_NUMBER_THREADS=4** 정도로 제한 권장

### 크로스 플랫폼 작업 흐름
```bash
# 1. Mac에서 개발 (arm64 네이티브)
docker run -it yocto-lecture:5.0-lts

# 2. x86_64 이미지 빌드 및 배포
./scripts/build-multiarch.sh username

# 3. x86_64 환경에서 최종 테스트
./scripts/test-x86-on-mac.sh -q
```

## 🔧 고급 사용법

### 개발자 모드
```bash
# Extensible SDK 생성
bitbake core-image-minimal -c populate_sdk_ext

# devtool을 이용한 개발
devtool add helloworld-dev file://./helloworld-dev.c
devtool build helloworld-dev
```

### 성능 최적화
```bash
# 빌드 통계 확인
bitbake -g core-image-minimal && cat pn-buildlist | wc -l

# 병렬 빌드 설정
echo 'BB_NUMBER_THREADS = "$(nproc)"' >> conf/local.conf
echo 'PARALLEL_MAKE = "-j $(nproc)"' >> conf/local.conf

# 디스크 사용량 모니터링
watch -n 30 'df -h | grep workspace'
```

### 디버깅 및 트러블슈팅
```bash
# 상세 로그 확인
bitbake -v core-image-minimal

# 특정 태스크 재실행
bitbake -c clean core-image-minimal
bitbake -c compile core-image-minimal

# 의존성 그래프 생성
bitbake -g core-image-minimal
```

## 🐛 문제 해결

### 일반적인 문제들

#### 💾 디스크 공간 부족
```bash
# 현재 사용량 확인
df -h

# 불필요한 파일 정리
docker system prune -a
rm -rf tmp/work/*
```

#### 🌐 네트워크 연결 문제
```bash
# 연결 테스트
ping -c 3 downloads.yoctoproject.org

# 프록시 설정 (필요한 경우)
export http_proxy=http://proxy.company.com:8080
export https_proxy=http://proxy.company.com:8080
```

#### 🔐 권한 문제
```bash
# 소유권 수정
sudo chown -R $(id -u):$(id -g) workspace/

# 권한 수정
chmod -R 755 workspace/
```

#### ⚡ 메모리 부족
```bash
# 스왑 확인
free -h

# 병렬 작업 수 줄이기
echo 'BB_NUMBER_THREADS = "4"' >> conf/local.conf
echo 'PARALLEL_MAKE = "-j 4"' >> conf/local.conf
```

## 📊 성능 벤치마크

### 빌드 시간 (참고용)
| 하드웨어 스펙 | core-image-minimal | core-image-base |
|---------------|-------------------|-----------------|
| 4C/8GB RAM    | 2-3시간           | 3-4시간         |
| 8C/16GB RAM   | 1-2시간           | 2-3시간         |
| 16C/32GB RAM  | 30-60분           | 1-2시간         |

### 디스크 사용량
- **초기 환경**: ~10GB
- **첫 빌드 후**: ~20-30GB
- **sstate 캐시**: ~10-15GB
- **다운로드 캐시**: ~5-10GB

## 🤝 기여하기

프로젝트 개선에 기여해주세요!

1. **Fork** 프로젝트
2. **Feature branch** 생성 (`git checkout -b feature/amazing-feature`)
3. **Commit** 변경사항 (`git commit -m 'Add amazing feature'`)
4. **Push** to branch (`git push origin feature/amazing-feature`)
5. **Pull Request** 생성

### 기여 가이드라인
- 코드 스타일 일관성 유지
- 충분한 테스트 수행
- 문서 업데이트
- 의미있는 커밋 메시지 작성

## 📄 라이선스

이 프로젝트는 [MIT License](LICENSE) 하에 배포됩니다.

## 🆘 지원 및 도움말

### 공식 문서
- [Yocto Project 공식 문서](https://docs.yoctoproject.org/)
- [BitBake 사용자 매뉴얼](https://docs.yoctoproject.org/bitbake/)
- [Docker 공식 문서](https://docs.docker.com/)

### 커뮤니티
- [Yocto Project 메일링 리스트](https://lists.yoctoproject.org/)
- [Stack Overflow - Yocto](https://stackoverflow.com/questions/tagged/yocto)
- [Reddit - r/yocto](https://reddit.com/r/yocto)

### 이슈 리포팅
문제가 발생했을 때:
1. [Issues](https://github.com/your-repo/yocto-lecture/issues)에서 기존 이슈 확인
2. 새 이슈 생성 시 다음 정보 포함:
   - 환경 정보 (OS, Docker 버전)
   - 에러 메시지 전문
   - 재현 단계
   - 로그 파일

## 🙏 감사의 말

- **Yocto Project** 커뮤니티
- **OpenEmbedded** 프로젝트
- **Docker** 팀
- 모든 **기여자**들

---

**Happy Building! 🚀**

> "The best way to learn Yocto is by doing it hands-on in a consistent environment." 

## 🔧 GitHub Actions 자동 빌드 설정

### Docker Hub Token 설정
GitHub Actions에서 Docker Hub로 자동 푸시하려면 Docker Hub Access Token이 필요합니다.

1. **Docker Hub Access Token 생성**
   - [Docker Hub](https://hub.docker.com/) 로그인
   - Account Settings > Security > New Access Token
   - Token 이름: `github-actions`
   - 권한: Read, Write, Delete
   - 생성된 토큰 복사

2. **GitHub Repository Secrets 설정**
   - GitHub 저장소 페이지에서 Settings > Secrets and variables > Actions
   - "New repository secret" 클릭
   - Name: `DOCKERHUB_TOKEN`
   - Secret: 복사한 Docker Hub Access Token 붙여넣기
   - "Add secret" 클릭

3. **자동 빌드 확인**
   - 코드 푸시시 자동으로 GitHub Actions 실행
   - Docker Hub에 새 이미지 자동 업로드
   - Actions 탭에서 빌드 상태 확인

### GitHub Actions 특징
- **트리거**: main/master 브랜치 푸시시 자동 실행
- **멀티플랫폼**: linux/amd64, linux/arm64 지원
- **캐싱**: Docker layer 캐시로 빌드 시간 단축
- **태그**: 브랜치명, 버전 태그, latest 자동 생성

---

## 📞 지원 및 문의

- **GitHub Issues**: 버그 리포트 및 기능 요청
- **Docker Hub**: [jabang3/yocto-lecture](https://hub.docker.com/r/jabang3/yocto-lecture)
- **문서**: 프로젝트 README 및 docs/ 디렉토리

---

## 📄 라이선스

MIT License - 자세한 내용은 LICENSE 파일을 참조하세요.

---

**Happy Yocto Building! 🚀** 