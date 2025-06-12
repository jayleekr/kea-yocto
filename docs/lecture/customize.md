# 이미지 커스터마이징: 패키지 추가

## local.conf를 통한 패키지 추가

기본 이미지에 추가 패키지를 포함시켜보겠습니다:

### 기본 패키지 추가

```bash
# local.conf 파일 편집
vi conf/local.conf

# 다음 라인들을 추가
IMAGE_INSTALL:append = " nano vim htop git"
IMAGE_INSTALL:append = " python3 python3-pip"
IMAGE_INSTALL:append = " openssh-server dropbear"
```

!!! tip "패키지 추가 방법들"
    - **IMAGE_INSTALL:append**: 기존 설정에 패키지 추가
    - **IMAGE_INSTALL:prepend**: 기존 설정 앞에 패키지 추가  
    - **IMAGE_INSTALL:remove**: 특정 패키지 제거

### 개발 도구 추가

```bash
# 개발 환경 구성
IMAGE_INSTALL:append = " packagegroup-core-buildessential"
IMAGE_INSTALL:append = " cmake make autoconf automake"
IMAGE_INSTALL:append = " gdb strace ltrace"

# 네트워킹 도구
IMAGE_INSTALL:append = " curl wget netcat iperf3"
IMAGE_INSTALL:append = " tcpdump wireshark-cli"
```

### 시스템 도구 추가

```bash
# 시스템 관리 도구
IMAGE_INSTALL:append = " systemd-analyze"
IMAGE_INSTALL:append = " procps util-linux coreutils"
IMAGE_INSTALL:append = " findutils grep sed awk"

# 파일시스템 도구
IMAGE_INSTALL:append = " e2fsprogs dosfstools"
IMAGE_INSTALL:append = " tree file which"
```

## 고급 이미지 커스터마이징

### IMAGE_FEATURES 활용

```bash
# local.conf에 추가할 이미지 기능들

# 개발 관련 기능
IMAGE_FEATURES += "debug-tweaks"           # 개발 편의 기능
IMAGE_FEATURES += "tools-debug"            # 디버깅 도구
IMAGE_FEATURES += "tools-profile"          # 프로파일링 도구

# 패키지 관리
IMAGE_FEATURES += "package-management"     # opkg 패키지 매니저

# SSH 접속
IMAGE_FEATURES += "ssh-server-openssh"     # OpenSSH 서버
IMAGE_FEATURES += "ssh-server-dropbear"    # 경량 SSH 서버

# 개발 도구
IMAGE_FEATURES += "tools-sdk"              # SDK 도구들
IMAGE_FEATURES += "dev-pkgs"               # 개발 헤더 파일들
```

### 이미지 크기 최적화

```bash
# 크기 최적화 설정
IMAGE_FEATURES += "read-only-rootfs"       # 읽기 전용 루트 파일시스템
EXTRA_IMAGE_FEATURES = "empty-root-password" # 루트 패스워드 없음

# 불필요한 기능 제거
IMAGE_FEATURES:remove = "x11-base"         # X11 제거
DISTRO_FEATURES:remove = "wayland x11"     # 그래픽 스택 제거
```

### 커널 모듈 추가

```bash
# 특정 커널 모듈 포함
IMAGE_INSTALL:append = " kernel-modules"
IMAGE_INSTALL:append = " kernel-module-usbnet"
IMAGE_INSTALL:append = " kernel-module-cdc-acm"

# 전체 커널 모듈 (크기 주의)
IMAGE_INSTALL:append = " kernel-modules"
```

## 재빌드 및 확인

### 수정된 설정으로 재빌드

```bash
# 변경사항 적용을 위한 재빌드
bitbake core-image-minimal

# 또는 강제 재빌드
bitbake -c clean core-image-minimal
bitbake core-image-minimal
```

!!! warning "빌드 시간"
    새로운 패키지 추가 시 추가 다운로드 및 컴파일 시간이 소요됩니다.

### 새 이미지로 실행 및 확인

```bash
# 새 이미지로 QEMU 실행
runqemu qemux86-64 core-image-minimal

# 추가된 패키지들 확인
which nano vim htop git python3
python3 --version
git --version

# 설치된 패키지 목록
opkg list-installed | grep -E "(nano|vim|git|python)"
```

## 패키지 검색 및 정보 확인

### 사용 가능한 패키지 검색

```bash
# 패키지 이름으로 검색
bitbake -s | grep python

# 특정 패턴으로 검색
bitbake -s | grep -i network

# 패키지 상세 정보 확인
bitbake -e python3 | grep ^DESCRIPTION
bitbake -e python3 | grep ^LICENSE
```

### 패키지 의존성 확인

```bash
# 패키지 의존성 그래프 생성
bitbake -g python3

# 생성된 파일들 확인
ls pn-buildlist pn-depends.dot task-depends.dot

# 의존성 시각화 (그래프 도구 필요)
dot -Tpng pn-depends.dot -o python3-depends.png
```

### 패키지 내용 확인

```bash
# 패키지에 포함된 파일들 확인
oe-pkgdata-util list-pkg-files python3

# 패키지 정보 조회
oe-pkgdata-util lookup-recipe python3

# 패키지가 제공하는 파일들
oe-pkgdata-util find-path /usr/bin/python3
```

## 사용자 정의 패키지 그룹

### 패키지 그룹 생성

```bash
# meta-mylayer/recipes-core/packagegroups/packagegroup-mytools.bb
SUMMARY = "My custom tools package group"
LICENSE = "MIT"

inherit packagegroup

PACKAGES = "\
    packagegroup-mytools \
    packagegroup-mytools-debug \
    packagegroup-mytools-network \
"

RDEPENDS:packagegroup-mytools = "\
    nano \
    vim \
    htop \
    git \
    python3 \
"

RDEPENDS:packagegroup-mytools-debug = "\
    gdb \
    strace \
    ltrace \
    valgrind \
"

RDEPENDS:packagegroup-mytools-network = "\
    curl \
    wget \
    netcat \
    iperf3 \
    tcpdump \
"
```

### 패키지 그룹 사용

```bash
# local.conf에서 패키지 그룹 사용
IMAGE_INSTALL:append = " packagegroup-mytools"
IMAGE_INSTALL:append = " packagegroup-mytools-debug"
```

## 런타임 패키지 관리

### 이미지에서 패키지 추가/제거

```bash
# QEMU 실행 후 (네트워크 연결 필요)
opkg update

# 새 패키지 설치
opkg install htop

# 패키지 제거
opkg remove htop

# 설치 가능한 패키지 검색
opkg list | grep python
```

### 외부 저장소 추가

```bash
# /etc/opkg/ 설정 파일 편집
echo "src/gz myrepo http://myserver.com/packages" >> /etc/opkg/base-feeds.conf

# 저장소 업데이트
opkg update
```

## 이미지 크기 분석

### 이미지 크기 최적화

```bash
# 빌드 통계 확인
bitbake -e core-image-minimal | grep IMAGE_ROOTFS_SIZE

# 패키지별 크기 분석
oe-pkgdata-util list-pkg-files -r /workspace/build core-image-minimal

# 불필요한 파일 제거
IMAGE_INSTALL:remove = " man-pages"
IMAGE_INSTALL:remove = " doc-pkgs"
```

### 이미지 내용 분석

```bash
# 이미지에 포함된 모든 패키지
bitbake -g core-image-minimal
cat pn-buildlist

# 특정 패키지가 포함된 이유 추적
bitbake -g core-image-minimal
grep "specific-package" pn-depends.dot
```

## 문제 해결

### 패키지 충돌 해결

```bash
# 충돌하는 패키지 확인
bitbake core-image-minimal 2>&1 | grep -i conflict

# 특정 패키지 버전 고정
PREFERRED_VERSION_python3 = "3.11%"

# 패키지 제외
BAD_RECOMMENDATIONS += "package-name"
```

### 빌드 오류 디버깅

```bash
# 특정 패키지 로그 확인
bitbake -c compile python3 -v

# 작업 디렉토리 확인
bitbake -c devshell python3

# 패키지 정리 후 재빌드
bitbake -c cleanall python3
bitbake python3
```

---

← [이미지 실행](run-image.md) | [커스텀 레이어](custom-layer.md) → 