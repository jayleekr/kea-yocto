# Yocto 고급 주제 및 실무 활용

## 개발 워크플로우 최적화

### devtool을 활용한 효율적인 개발

devtool은 Yocto에서 제공하는 강력한 개발 도구입니다:

```bash
# 개발용 워크스페이스 생성
devtool create-workspace ../workspace

# 기존 레시피 수정 모드로 진입
devtool modify hello-world

# 소스 코드 위치 확인 (Git 저장소로 관리됨)
ls -la ../workspace/sources/hello-world/
git log --oneline -5

# 실시간 개발 및 테스트
cd ../workspace/sources/hello-world/
vi hello.c  # 소스 수정
devtool build hello-world  # 빌드
devtool deploy-target hello-world root@192.168.7.2  # 타겟에 직접 배포

# 변경사항을 레시피에 반영
devtool finish hello-world ../meta-myapp
```

### SDK (Software Development Kit) 활용

```bash
# SDK 생성
bitbake core-image-minimal -c populate_sdk

# SDK 설치 스크립트 위치
ls tmp/deploy/sdk/

# SDK 설치 및 사용
./tmp/deploy/sdk/poky-glibc-x86_64-core-image-minimal-cortexa15t2hf-neon-toolchain-5.0.sh

# SDK 환경 설정
source /opt/poky/5.0/environment-setup-cortexa15t2hf-neon-poky-linux-gnueabi

# 크로스 컴파일 확인
$CC --version
echo $CROSS_COMPILE
```

### eSDK (Extensible SDK) 활용

```bash
# 확장 가능한 SDK 생성
bitbake core-image-minimal -c populate_sdk_ext

# eSDK의 장점
# - devtool 포함
# - 레시피 추가/수정 가능
# - 이미지 커스터마이징 가능

# eSDK 환경에서 새 애플리케이션 추가
devtool add myapp https://github.com/example/myapp.git
devtool build myapp
```

## 고급 빌드 시스템 활용

### 멀티 컨피그 빌드

서로 다른 아키텍처를 동시에 빌드:

```bash
# conf/local.conf에 추가
BBMULTICONFIG = "arm x86"

# conf/multiconfig/arm.conf 생성
MACHINE = "beaglebone-yocto"
TMPDIR = "${TOPDIR}/tmp-arm"

# conf/multiconfig/x86.conf 생성  
MACHINE = "qemux86-64"
TMPDIR = "${TOPDIR}/tmp-x86"

# 멀티 아키텍처 빌드
bitbake mc:arm:core-image-minimal mc:x86:core-image-minimal
```

### 고급 이미지 타입

```bash
# 다양한 이미지 타입 생성
IMAGE_FSTYPES += "ext4 tar.bz2 wic squashfs"

# 압축된 이미지
IMAGE_FSTYPES += "ext4.xz tar.xz"

# 컨테이너 이미지
IMAGE_FSTYPES += "tar.gz"
INHERIT += "image-container"

# 실시간 업데이트 가능한 이미지
INHERIT += "swupdate"
```

### 커스텀 배포판 생성

```bash
# meta-mydistro 레이어 생성
bitbake-layers create-layer ../meta-mydistro

# 배포판 설정 파일 생성
mkdir -p ../meta-mydistro/conf/distro

cat > ../meta-mydistro/conf/distro/mydistro.conf << 'EOF'
DISTRO = "mydistro"
DISTRO_NAME = "My Custom Distribution"
DISTRO_VERSION = "1.0"
DISTRO_CODENAME = "custom"

# 기본 기능 설정
DISTRO_FEATURES = "systemd wifi bluetooth ipv4 ipv6 pam"
DISTRO_FEATURES:append = " opengl wayland"

# 보안 기능
DISTRO_FEATURES:append = " seccomp"

# 패키지 관리
PACKAGE_CLASSES = "package_rpm"

# 기본 로그인
EXTRA_IMAGE_FEATURES += "debug-tweaks"

# 라이선스 허용
LICENSE_FLAGS_ACCEPTED = "commercial"
EOF

# 배포판 사용
echo 'DISTRO = "mydistro"' >> conf/local.conf
```

## 배포 및 업데이트 시스템

### SWUpdate를 활용한 안전한 업데이트

```bash
# SWUpdate 레이어 추가
git clone git://github.com/sbabic/meta-swupdate.git
bitbake-layers add-layer ../meta-swupdate

# 업데이트 이미지 생성
inherit swupdate

SWU_IMAGES = "core-image-minimal"
SWUPDATE_IMAGES = "core-image-minimal"

# 업데이트 패키지 생성
bitbake core-image-minimal-swu
```

### Mender를 통한 OTA 업데이트

```bash
# Mender 레이어 추가
git clone -b scarthgap https://github.com/mendersoftware/meta-mender.git
bitbake-layers add-layer ../meta-mender/meta-mender-core

# Mender 설정
INHERIT += "mender-full"
MENDER_ARTIFACT_NAME = "release-1.0"
MENDER_DEVICE_TYPE = "mydevice"

# 듀얼 파티션 설정
MENDER_BOOT_PART_SIZE_MB = "16"
MENDER_DATA_PART_SIZE_MB = "128"
```

### OSTree 기반 원자적 업데이트

```bash
# OSTree 지원 레이어
git clone git://git.yoctoproject.org/meta-updater
bitbake-layers add-layer ../meta-updater

# OSTree 설정
DISTRO_FEATURES:append = " sota"
INHERIT += "sota"

# 업데이트 서버 설정
SOTA_SERVER = "https://my-update-server.com"
```

## 보안 강화

### 보안 기능 활성화

```bash
# 읽기 전용 루트 파일시스템
IMAGE_FEATURES += "read-only-rootfs"

# 보안 컴파일러 옵션
SECURITY_CFLAGS = "-fstack-protector-strong -Wformat -Wformat-security"
SECURITY_LDFLAGS = "-Wl,-z,relro,-z,now"

# SELinux 지원
DISTRO_FEATURES:append = " selinux"
PREFERRED_PROVIDER_virtual/refpolicy = "refpolicy-targeted"

# 사용자 계정 보안
INHERIT += "extrausers"
EXTRA_USERS_PARAMS = "useradd -p '\$1\$UgMJE2kf\$e/Uw8MueDVi0sQ/YlBTB.1' myuser;"
```

### 라이선스 관리

```bash
# 라이선스 추적 활성화
INHERIT += "archiver"
ARCHIVER_MODE[src] = "original"
ARCHIVER_MODE[diff] = "1"
ARCHIVER_MODE[recipe] = "1"

# 특정 라이선스 제외
INCOMPATIBLE_LICENSE = "GPL-3.0 LGPL-3.0"

# 상용 라이선스 허용
LICENSE_FLAGS_ACCEPTED = "commercial"

# 라이선스 매니페스트 생성
COPY_LIC_MANIFEST = "1"
COPY_LIC_DIRS = "1"
```

## 성능 최적화

### 컴파일 최적화

```bash
# CPU 최적화
DEFAULTTUNE = "cortexa72"
TUNE_FEATURES:append = " neon vfpv4"

# 링크 타임 최적화 (LTO)
SELECTED_OPTIMIZATION:append = " -flto"

# 병렬 빌드 최적화
BB_NUMBER_THREADS = "${@oe.utils.cpu_count()}"
PARALLEL_MAKE = "-j ${@oe.utils.cpu_count()}"

# ccache 사용
INHERIT += "ccache"
```

### 메모리 최적화

```bash
# 불필요한 로케일 제거
IMAGE_LINGUAS = "en-us"

# 문서 파일 제거
INHERIT += "rm_work"

# 개발 파일 제거 (프로덕션)
IMAGE_FEATURES:remove = "dev-pkgs"
IMAGE_FEATURES:remove = "doc-pkgs"
```

## 테스트 및 품질 보증

### 자동화된 테스트

```bash
# oe-selftest 실행
oe-selftest --run-tests signing

# 런타임 테스트
bitbake core-image-minimal -c testimage

# 커스텀 테스트 추가
inherit testimage
TEST_SUITES = "ping ssh rpm smart kernelmodule"
```

### 이미지 분석

```bash
# 이미지 크기 분석
bitbake -e core-image-minimal | grep ^IMAGE_ROOTFS_SIZE
buildhistory-diff

# 패키지 의존성 분석
bitbake -g core-image-minimal
oe-pkgdata-util list-pkg-files -r core-image-minimal
```

### Buildhistory 활용

```bash
# 빌드 히스토리 활성화
INHERIT += "buildhistory"
BUILDHISTORY_COMMIT = "1"

# 히스토리 비교
buildhistory-diff HEAD~1 HEAD

# 패키지 크기 변화 추적
buildhistory-collect-srcrevs
```

## 고급 디버깅

### 원격 디버깅

```bash
# GDB 서버 설정
IMAGE_FEATURES += "tools-debug"
IMAGE_INSTALL:append = " gdbserver"

# 타겟에서 GDB 서버 실행
gdbserver localhost:2345 ./my-application

# 호스트에서 원격 디버깅
$GDB -ex "target remote 192.168.7.2:2345" my-application
```

### 프로파일링

```bash
# 프로파일링 도구 추가
IMAGE_FEATURES += "tools-profile"
IMAGE_INSTALL:append = " perf valgrind oprofile"

# 시스템 콜 추적
strace -o trace.log my-application

# 메모리 누수 검사
valgrind --leak-check=full ./my-application
```

## 클라우드 및 컨테이너 통합

### Docker 컨테이너 빌드

```bash
# 컨테이너 이미지 생성
DISTRO_FEATURES:append = " virtualization"
IMAGE_FSTYPES += "container"

# Docker 이미지로 변환
inherit container
CONTAINER_INSTALL:append = " packagegroup-core-boot"
```

### Kubernetes 지원

```bash
# 컨테이너 런타임 추가
IMAGE_INSTALL:append = " containerd docker runc"
IMAGE_INSTALL:append = " kubernetes kubelet"

# 네트워킹 지원
IMAGE_INSTALL:append = " cni-plugins flannel"
```

## 지속적 통합 (CI/CD)

### Jenkins 통합

```bash
#!/bin/bash
# Jenkins 빌드 스크립트 예시

# 환경 정리
docker compose down
docker compose up -d

# 빌드 실행
docker compose exec yocto-lecture bash -c "
    source /opt/poky/oe-init-build-env /workspace/build
    bitbake core-image-minimal
    bitbake core-image-minimal -c testimage
"

# 결과 수집
docker cp yocto-lecture:/workspace/build/tmp/deploy/images ./artifacts/
```

### GitHub Actions 워크플로우

```yaml
# .github/workflows/yocto-build.yml
name: Yocto Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Build Yocto Image
      run: |
        docker compose up -d
        docker compose exec -T yocto-lecture bash -c "
          source /opt/poky/oe-init-build-env /workspace/build
          bitbake core-image-minimal
        "
    
    - name: Archive artifacts
      uses: actions/upload-artifact@v4
      with:
        name: yocto-images
        path: tmp/deploy/images/
```

## 문제 해결 고급 기법

### 빌드 환경 분석

```bash
# 환경 변수 덤프
bitbake -e > environment.log

# 레시피 의존성 상세 분석
bitbake -g core-image-minimal
dot -Tpng pn-depends.dot -o depends.png

# 빌드 통계
bitbake -s | wc -l  # 총 패키지 수
du -sh sstate-cache/  # 캐시 크기
```

### 성능 프로파일링

```bash
# 빌드 시간 분석
bitbake -P core-image-minimal

# 병목 지점 찾기
buildstats-diff.py before.json after.json

# 네트워크 트래픽 모니터링
netstat -i
iftop -i eth0
```

---

← [커스텀 레이어](custom-layer.md) | [마무리](conclusion.md) → 