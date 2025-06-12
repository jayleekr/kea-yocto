# 커스텀 레이어 및 레시피 생성

## 새 레이어 생성

커스텀 애플리케이션을 위한 새 레이어를 생성해보겠습니다:

### 레이어 생성 명령

```bash
# 새 레이어 생성
bitbake-layers create-layer ../meta-myapp

# 생성된 레이어 구조 확인
tree ../meta-myapp

# 레이어를 빌드에 추가
bitbake-layers add-layer ../meta-myapp

# 레이어 목록 확인
bitbake-layers show-layers
```

### 표준 레이어 구조

```
meta-myapp/
├── conf/
│   └── layer.conf          # 레이어 기본 설정
├── recipes-example/        # 예제 레시피들
├── recipes-myapp/          # 커스텀 애플리케이션 레시피
│   └── hello-world/
│       ├── files/          # 소스 파일들
│       └── hello-world_1.0.bb  # 레시피 파일
├── classes/                # 공통 클래스 파일들
├── files/                  # 공통 파일들
└── README                  # 레이어 설명서
```

### layer.conf 설정

```bash
# meta-myapp/conf/layer.conf
BBPATH .= ":${LAYERDIR}"
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb ${LAYERDIR}/recipes-*/*/*.bbappend"
BBFILE_COLLECTIONS += "myapp"
BBFILE_PATTERN_myapp = "^${LAYERDIR}/"
BBFILE_PRIORITY_myapp = "6"

# 의존성 레이어 정의
LAYERDEPENDS_myapp = "core openembedded-layer"

# Yocto 버전 호환성
LAYERSERIES_COMPAT_myapp = "scarthgap"
```

## Hello World 애플리케이션 만들기

### 소스 코드 작성

```bash
# 소스 코드 디렉토리 생성
mkdir -p ../meta-myapp/recipes-myapp/hello-world/files

# C 소스 코드 작성
cat > ../meta-myapp/recipes-myapp/hello-world/files/hello.c << 'EOF'
#include <stdio.h>
#include <time.h>

int main() {
    time_t rawtime;
    struct tm * timeinfo;
    
    time(&rawtime);
    timeinfo = localtime(&rawtime);
    
    printf("Hello from Yocto Custom Layer!\n");
    printf("This is my first custom application.\n");
    printf("Built at: %s", __DATE__ " " __TIME__ "\n");
    printf("Current time: %s", asctime(timeinfo));
    
    return 0;
}
EOF
```

### Makefile 작성

```bash
# Makefile 생성
cat > ../meta-myapp/recipes-myapp/hello-world/files/Makefile << 'EOF'
CC ?= gcc
CFLAGS ?= -Wall -O2
TARGET = hello
SOURCE = hello.c

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)

install:
	install -d $(DESTDIR)/usr/bin
	install -m 755 $(TARGET) $(DESTDIR)/usr/bin/

clean:
	rm -f $(TARGET)

.PHONY: install clean
EOF
```

### 레시피 파일 작성

```bash
# 레시피 파일 생성
cat > ../meta-myapp/recipes-myapp/hello-world/hello-world_1.0.bb << 'EOF'
SUMMARY = "Hello World application for Yocto"
DESCRIPTION = "A simple Hello World C application demonstrating custom layer creation"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# 소스 파일들 정의
SRC_URI = "file://hello.c \
           file://Makefile"

# 작업 디렉토리 설정
S = "${WORKDIR}"

# 컴파일 태스크
do_compile() {
    oe_runmake
}

# 설치 태스크
do_install() {
    oe_runmake install DESTDIR=${D}
}

# 패키지 정보
FILES:${PN} = "/usr/bin/hello"
EOF
```

## 레시피 빌드 및 테스트

### 개별 레시피 빌드

```bash
# 레시피만 빌드
bitbake hello-world

# 빌드 과정 상세 확인
bitbake hello-world -v

# 생성된 패키지 확인
find tmp/deploy -name "*hello-world*"
```

### 이미지에 포함시키기

```bash
# local.conf에 추가
echo 'IMAGE_INSTALL:append = " hello-world"' >> conf/local.conf

# 전체 이미지 재빌드
bitbake core-image-minimal

# QEMU에서 테스트
runqemu qemux86-64 core-image-minimal nographic

# 애플리케이션 실행 (QEMU 내부에서)
hello
```

## 고급 레시피 기능

### 패치 적용

```bash
# 패치 파일 추가
mkdir -p ../meta-myapp/recipes-myapp/hello-world/files
cat > ../meta-myapp/recipes-myapp/hello-world/files/add-version.patch << 'EOF'
--- a/hello.c
+++ b/hello.c
@@ -1,4 +1,6 @@
 #include <stdio.h>
+#include <time.h>
+
+#define VERSION "1.0"
 
 int main() {
     time_t rawtime;
@@ -8,6 +10,7 @@
     timeinfo = localtime(&rawtime);
     
     printf("Hello from Yocto Custom Layer!\n");
+    printf("Version: %s\n", VERSION);
     printf("This is my first custom application.\n");
     printf("Built at: %s", __DATE__ " " __TIME__ "\n");
     printf("Current time: %s", asctime(timeinfo));
EOF

# 레시피에 패치 추가
echo 'SRC_URI += "file://add-version.patch"' >> ../meta-myapp/recipes-myapp/hello-world/hello-world_1.0.bb
```

### 설정 파일 포함

```bash
# 설정 파일 생성
cat > ../meta-myapp/recipes-myapp/hello-world/files/hello.conf << 'EOF'
# Hello World Application Configuration
greeting=Hello from Yocto
show_time=true
debug_mode=false
EOF

# 레시피에 설정 파일 추가
cat >> ../meta-myapp/recipes-myapp/hello-world/hello-world_1.0.bb << 'EOF'

SRC_URI += "file://hello.conf"

do_install:append() {
    install -d ${D}${sysconfdir}
    install -m 644 ${WORKDIR}/hello.conf ${D}${sysconfdir}/
}

FILES:${PN} += "${sysconfdir}/hello.conf"
EOF
```

### 의존성 추가

```bash
# 런타임 의존성 추가
cat >> ../meta-myapp/recipes-myapp/hello-world/hello-world_1.0.bb << 'EOF'

# 빌드 시간 의존성
DEPENDS = "zlib openssl"

# 런타임 의존성  
RDEPENDS:${PN} = "bash python3"

# 권장 패키지
RRECOMMENDS:${PN} = "nano vim"
EOF
```

## 커스텀 이미지 레시피 생성

### 전용 이미지 레시피

```bash
# 커스텀 이미지 레시피 생성
mkdir -p ../meta-myapp/recipes-core/images

cat > ../meta-myapp/recipes-core/images/my-custom-image.bb << 'EOF'
SUMMARY = "My custom image with additional tools"
DESCRIPTION = "Custom image including hello-world app and development tools"
LICENSE = "MIT"

# core-image 클래스 상속
inherit core-image

# 이미지 기능 설정
IMAGE_FEATURES += "ssh-server-openssh package-management"
IMAGE_FEATURES += "debug-tweaks tools-debug"

# 포함할 패키지들
IMAGE_INSTALL = "packagegroup-core-boot \
                 packagegroup-base-extended \
                 hello-world \
                 nano \
                 vim \
                 htop \
                 git \
                 python3 \
                 python3-pip \
                 curl \
                 wget \
                 ${CORE_IMAGE_EXTRA_INSTALL}"

# 이미지 이름 설정
export IMAGE_BASENAME = "my-custom-image"

# 추가 설정
IMAGE_ROOTFS_EXTRA_SPACE = "1024"
IMAGE_OVERHEAD_FACTOR = "1.3"
EOF
```

### 커스텀 이미지 빌드

```bash
# 커스텀 이미지 빌드
bitbake my-custom-image

# QEMU에서 테스트
runqemu qemux86-64 my-custom-image
```

## Python 애플리케이션 레시피

### Python 스크립트 생성

```bash
# Python 애플리케이션 디렉토리 생성
mkdir -p ../meta-myapp/recipes-myapp/python-hello/files

# Python 스크립트 작성
cat > ../meta-myapp/recipes-myapp/python-hello/files/hello.py << 'EOF'
#!/usr/bin/env python3
"""
Simple Hello World Python application for Yocto
"""

import sys
import datetime
import platform

def main():
    print("="*50)
    print("Hello from Python on Yocto!")
    print("="*50)
    print(f"Python version: {sys.version}")
    print(f"Platform: {platform.platform()}")
    print(f"Current time: {datetime.datetime.now()}")
    print(f"Arguments: {sys.argv[1:] if len(sys.argv) > 1 else 'None'}")
    print("="*50)

if __name__ == "__main__":
    main()
EOF

# 실행 권한 부여
chmod +x ../meta-myapp/recipes-myapp/python-hello/files/hello.py
```

### Python 레시피 작성

```bash
cat > ../meta-myapp/recipes-myapp/python-hello/python-hello_1.0.bb << 'EOF'
SUMMARY = "Python Hello World application"
DESCRIPTION = "A simple Python application for Yocto demonstration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Python 관련 설정
inherit python3native

SRC_URI = "file://hello.py"

S = "${WORKDIR}"

# Python3 런타임 의존성
RDEPENDS:${PN} = "python3"

do_install() {
    install -d ${D}${bindir}
    install -m 755 ${WORKDIR}/hello.py ${D}${bindir}/python-hello
}

FILES:${PN} = "${bindir}/python-hello"
EOF
```

## 고급 레이어 관리

### 레이어 버전 관리

```bash
# 레이어에 버전 정보 추가
cat >> ../meta-myapp/conf/layer.conf << 'EOF'

# 레이어 버전
LAYERVERSION_myapp = "1"

# 레이어 시리즈 호환성
LAYERSERIES_COMPAT_myapp = "scarthgap nanbield"
EOF
```

### 다중 레시피 버전

```bash
# 다른 버전의 레시피 생성
cp ../meta-myapp/recipes-myapp/hello-world/hello-world_1.0.bb \
   ../meta-myapp/recipes-myapp/hello-world/hello-world_2.0.bb

# 버전별 기본 설정
echo 'PREFERRED_VERSION_hello-world = "2.0"' >> conf/local.conf
```

## devtool을 활용한 개발

### devtool 워크스페이스 생성

```bash
# 개발용 워크스페이스 생성
devtool create-workspace ../workspace

# 기존 레시피 수정
devtool modify hello-world

# 소스 코드 위치 확인
echo "소스 코드가 ../workspace/sources/hello-world 에 있습니다"

# 변경사항 빌드
devtool build hello-world

# 변경사항 적용
devtool finish hello-world ../meta-myapp
```

## 문제 해결

### 일반적인 레시피 오류

```bash
# 레시피 구문 확인
bitbake-layers show-recipes hello-world

# 레시피 파싱 오류 확인
bitbake -e hello-world | grep ERROR

# 의존성 문제 해결
bitbake -g hello-world
cat pn-depends.dot | grep hello-world
```

### 빌드 디버깅

```bash
# 상세 빌드 로그
bitbake hello-world -v -D

# 개발 쉘 진입
bitbake -c devshell hello-world

# 특정 태스크 재실행
bitbake -c compile hello-world -f
```

---

← [이미지 커스터마이징](customize.md) | [고급 주제](advanced.md) → 