# KEA Yocto Project 5.0 LTS 강의 자료

**강의명**: Yocto Project를 활용한 임베디드 리눅스 시스템 개발  
**대상**: 임베디드 시스템 개발자, 리눅스 시스템 엔지니어  
**시간**: 8시간 (휴식 포함)  
**환경**: Docker 기반 Yocto 5.0 LTS (Scarthgap)  

---

## 📋 강의 목차

| 시간 | 내용 | 유형 | 비고 |
|------|------|------|------|
| 09:00-09:30 | [강의 소개 및 개요](#1-강의-소개-및-개요) | 이론 | 30분 |
| 09:30-10:30 | [Yocto 기본 구조 및 아키텍처](#2-yocto-기본-구조-및-아키텍처) | 이론 | 60분 |
| 10:45-11:30 | [Yocto 빌드 환경 설정](#3-yocto-빌드-환경-설정) | 실습 | 45분 |
| 11:30-12:30 | [첫 빌드: 코어 이미지 및 빌드 프로세스](#4-첫-빌드-코어-이미지-및-빌드-프로세스) | 실습+이론 | 60분 |
| 13:30-14:00 | [빌드된 이미지 실행하기](#5-빌드된-이미지-실행하기) | 실습 | 30분 |
| 14:00-14:30 | [이미지 커스터마이징: 패키지 추가](#6-이미지-커스터마이징-패키지-추가) | 실습 | 30분 |
| 14:45-16:00 | [커스텀 레이어 및 레시피 생성](#7-커스텀-레이어-및-레시피-생성) | 실습 | 75분 |
| 16:00-16:30 | [Yocto 고급 주제 개요](#8-yocto-고급-주제-개요) | 이론 | 30분 |
| 16:30-17:00 | [마무리 및 Q&A](#9-마무리-및-qa) | 토론 | 30분 |

---

## 1. 강의 소개 및 개요

### 1.1 Yocto Project란?

**Yocto Project**는 임베디드 리눅스 배포판을 만들기 위한 오픈소스 프로젝트입니다.

#### 핵심 특징
- 📦 **커스텀 리눅스 배포판** 생성
- 🔧 **크로스 컴파일 툴체인** 자동 생성
- 📚 **레시피 기반** 패키지 관리
- 🎯 **타겟 하드웨어** 최적화

#### 주요 구성 요소
- **Poky**: Yocto의 참조 배포판
- **BitBake**: 빌드 도구 및 태스크 실행기
- **OpenEmbedded**: 메타데이터 및 레시피 저장소

### 1.2 강의 목표

이 강의를 통해 다음을 학습합니다:

✅ Yocto Project의 기본 개념과 아키텍처 이해  
✅ Docker 환경에서 Yocto 빌드 환경 구축  
✅ 커스텀 리눅스 이미지 생성 및 실행  
✅ 패키지 추가 및 이미지 커스터마이징  
✅ 커스텀 레이어와 레시피 작성  
✅ 실제 프로젝트 적용 가능한 실무 지식 습득  

---

## 2. Yocto 기본 구조 및 아키텍처

### 2.1 Yocto Project 개념적 이해

#### 2.1.1 Yocto Project의 핵심 철학

Yocto Project는 **"Create a custom Linux distribution for any hardware"**라는 목표를 가지고 설계되었습니다. 전통적인 Linux 배포판과 달리, Yocto는 **빌드 시스템 접근 방식**을 택했습니다:

**전통적인 배포판 vs Yocto Project**

| 구분 | 전통적인 배포판 | Yocto Project |
|------|----------------|---------------|
| 접근 방법 | 미리 빌드된 패키지 | 소스에서 빌드 |
| 패키지 관리 | APT, YUM 등 | 레시피 기반 |
| 커스터마이징 | 제한적 | 완전한 제어 |
| 크기 최적화 | 어려움 | 필요한 것만 포함 |
| 크로스 컴파일 | 복잡함 | 자동 지원 |

#### 2.1.2 핵심 구성 요소 상세 설명

**🔧 BitBake (빌드 도구)**
- **역할**: Yocto의 태스크 실행 엔진
- **특징**: 
  - Python과 shell 스크립트로 작성된 레시피를 파싱  
  - 의존성 기반 병렬 빌드 지원  
  - 공유 상태 캐시(sstate-cache)로 빌드 시간 단축
- **주요 명령어**: `bitbake core-image-minimal`, `bitbake -c cleanall <package>`

**📦 Poky (참조 배포판)**
- **역할**: Yocto Project의 참조 구현체
- **구성 요소**:
  - OpenEmbedded-Core (OE-Core): 핵심 메타데이터
  - BitBake: 빌드 도구
  - 문서 및 개발 도구
- **특징**: 최소한의 Linux 배포판을 만들기 위한 기본 설정 제공

**🧩 OpenEmbedded (메타데이터 프레임워크)**
- **역할**: 패키지 빌드를 위한 메타데이터 제공
- **구성 요소**:
  - **레시피 (.bb)**: 개별 소프트웨어 패키지 빌드 방법 정의
  - **클래스 (.bbclass)**: 공통 빌드 로직 재사용
  - **설정 (.conf)**: 빌드 환경 및 정책 정의
  - **어펜드 (.bbappend)**: 기존 레시피 확장

#### 2.1.3 레이어 모델의 이해

Yocto의 **레이어 모델**은 모듈성과 재사용성을 제공하는 핵심 아키텍처입니다:

**레이어의 목적과 장점**
- ✅ **모듈성**: 기능별로 분리된 독립적인 구성
- ✅ **재사용성**: 다른 프로젝트에서 레이어 재활용 가능
- ✅ **유지보수**: 각 레이어별 독립적 업데이트
- ✅ **협업**: 팀별 레이어 분담 개발

**레이어 우선순위 시스템**
```
BBFILE_PRIORITY_meta-custom = "10"
BBFILE_PRIORITY_meta-oe = "6" 
BBFILE_PRIORITY_meta = "5"
```
- 높은 숫자 = 높은 우선순위
- 같은 레시피가 여러 레이어에 있을 경우 우선순위가 높은 레이어의 레시피 사용

### 2.2 시스템 아키텍처

Yocto 시스템은 다음과 같은 계층 구조로 이루어져 있습니다:

```mermaid
graph TB
    subgraph "Host System<br/>(Windows, macOS, Linux)"
        H1["💻 Host OS"]
        H2["🖥️ Terminal/Console"]
        H3["📁 Project Directory<br/>kea-yocto/"]
    end
    
    subgraph "Docker Engine Layer"
        D1["🐋 Docker Engine"]
        D2["📦 Docker Images"]
        D3["🔄 Container Runtime"]
    end
    
    subgraph "Yocto Container Environment"
        subgraph "Ubuntu 24.04 Base System"
            U1["🐧 Ubuntu Base"]
            U2["📚 Development Tools"]
            U3["🛠️ Build Dependencies"]
        end
        
        subgraph "Yocto Project 5.0 LTS"
            Y1["📋 Poky Reference<br/>Distribution"]
            Y2["⚙️ BitBake Build<br/>System"]
            Y3["📦 Meta Layers<br/>(meta-oe, meta-**)"]
        end
        
        subgraph "Build & Runtime"
            B1["🏗️ Build Directory<br/>/workspace/build"]
            B2["💾 Downloads Cache<br/>/workspace/downloads"]
            B3["🎯 QEMU Emulator"]
            B4["🖼️ Generated Images<br/>(core-image-minimal)"]
        end
    end
    
    subgraph "Volume Mounts"
        V1["📂 yocto-workspace/<br/>Persistent Storage"]
        V2["🗄️ Downloads Cache"]
        V3["🔧 Build Artifacts"]
    end
    
    H1 --> D1
    H2 --> D3
    H3 --> V1
    D1 --> D2
    D2 --> Y1
    D3 --> U1
    U1 --> Y1
    Y1 --> Y2
    Y2 --> Y3
    Y2 --> B1
    B1 --> B2
    B1 --> B4
    B4 --> B3
    V1 --> B1
    V1 --> V2
    V1 --> V3
```

### 2.3 빌드 프로세스 심화 이해

#### 2.3.1 BitBake 작업 흐름 개념

Yocto의 빌드 프로세스는 **의존성 기반 태스크 그래프**를 생성하고 실행하는 복잡한 과정입니다:

**빌드 프로세스의 핵심 단계**
1. **파싱 단계**: 모든 레시피와 클래스 파일을 읽어 메타데이터 데이터베이스 구축
2. **의존성 해결**: DEPENDS, RDEPENDS 관계를 분석하여 빌드 순서 결정
3. **태스크 그래프 생성**: 각 패키지별 do_* 태스크들의 실행 순서 계획
4. **병렬 실행**: CPU 코어 수에 맞춰 독립적인 태스크들을 동시 실행

**주요 태스크 타입 설명**

| 태스크 | 목적 | 입력 | 출력 |
|--------|------|------|------|
| `do_fetch` | 소스 다운로드 | SRC_URI | DL_DIR/*.tar.gz |
| `do_unpack` | 압축 해제 | 다운로드된 파일 | WORKDIR/source |
| `do_patch` | 패치 적용 | 소스 + 패치 파일 | 패치된 소스 |
| `do_configure` | 빌드 설정 | 소스 | Makefile/CMake |
| `do_compile` | 컴파일 | 설정된 소스 | 바이너리 |
| `do_install` | 파일 설치 | 바이너리 | image/ 디렉토리 |
| `do_package` | 패키지 생성 | 설치된 파일 | .deb/.rpm 등 |

#### 2.3.2 공유 상태 캐시 (sstate-cache) 메커니즘

**sstate-cache의 중요성**
- 🚀 **빌드 속도 향상**: 이미 빌드된 결과를 재사용
- 💾 **저장 공간 효율**: 해시 기반 중복 제거
- 🔄 **증분 빌드**: 변경된 부분만 다시 빌드

**캐시 작동 원리**
```
패키지 입력(소스+설정) → SHA256 해시 → 캐시 키 생성
캐시 키 존재 확인 → 있으면 재사용, 없으면 새로 빌드
```

#### 2.3.3 크로스 컴파일 툴체인

Yocto는 **타겟 하드웨어용 크로스 컴파일 툴체인**을 자동으로 생성합니다:

**툴체인 구성 요소**
- **gcc-cross**: 크로스 컴파일러 (호스트에서 타겟용 바이너리 생성)
- **binutils-cross**: 링커, 어셈블러 등 바이너리 도구
- **glibc**: 타겟용 C 라이브러리
- **kernel-headers**: 커널 헤더 파일

**타겟 아키텍처 예시**
```bash
# x86_64 호스트에서 ARM용 빌드
MACHINE = "beaglebone-yocto"
TARGET_ARCH = "arm"
TUNE_FEATURES = "arm armv7a neon"
```

Yocto의 빌드 프로세스는 다음과 같은 단계로 진행됩니다:

```mermaid
flowchart TD
    Start([🚀 Yocto Build 시작]) --> Init[📋 BitBake 환경 초기화<br/>source oe-init-build-env]
    Init --> Config[⚙️ 빌드 설정<br/>local.conf & bblayers.conf]
    Config --> Parse[📖 Recipe 파싱<br/>BitBake가 .bb 파일들 분석]
    
    Parse --> Deps[🔗 의존성 해결<br/>DEPENDS & RDEPENDS 분석]
    Deps --> Tasks[📋 Task 생성<br/>do_fetch, do_unpack, do_compile...]
    
    subgraph "병렬 빌드 프로세스"
        Tasks --> Fetch[⬇️ do_fetch<br/>소스 코드 다운로드]
        Fetch --> Unpack[📦 do_unpack<br/>소스 압축 해제]
        Unpack --> Patch[🔧 do_patch<br/>패치 적용]
        Patch --> Configure[⚙️ do_configure<br/>빌드 설정]
        Configure --> Compile[🔨 do_compile<br/>컴파일 실행]
        Compile --> Install[📁 do_install<br/>파일 설치]
        Install --> Package[📦 do_package<br/>패키지 생성]
    end
    
    Package --> SState{🗄️ sstate-cache<br/>확인}
    SState -->|캐시 적중| Reuse[♻️ 캐시 재사용]
    SState -->|캐시 없음| Build[🏗️ 새로 빌드]
    
    Reuse --> Rootfs[🌳 Rootfs 생성<br/>파일시스템 구성]
    Build --> Rootfs
    
    Rootfs --> Image[🖼️ 이미지 생성<br/>core-image-minimal.ext4]
    Image --> Deploy[📤 Deploy<br/>tmp/deploy/images/]
    
    Deploy --> QEMU{🎯 QEMU 실행?}
    QEMU -->|Yes| Run[🚀 runqemu 실행<br/>이미지 테스트]
    QEMU -->|No| End([✅ 빌드 완료])
    Run --> End
```

### 2.4 레이어 구조 상세 분석

#### 2.4.1 레이어 계층 구조와 역할

Yocto는 **계층화된 레이어 아키텍처**를 통해 모듈성과 확장성을 제공합니다:

**레이어 분류와 특징**

**📚 Core Layers (필수 레이어)**
- **meta**: OpenEmbedded-Core 레이어
  - 역할: 기본 빌드 시스템과 핵심 레시피 제공
  - 포함 내용: gcc, glibc, busybox, linux-yocto 등
  - 특징: 모든 Yocto 빌드에 필수

- **meta-poky**: Poky 배포판 정책 레이어
  - 역할: Poky 배포판의 기본 설정과 정책 정의
  - 포함 내용: 기본 이미지, 배포판 설정, 툴체인 설정
 
- 특징: 다른 배포판으로 교체 가능

- **meta-yocto-bsp**: 하드웨어 지원 레이어
  - 역할: 특정 하드웨어에 대한 지원 제공
  - 포함 내용: 보드별 커널 설정, 부트로더, 하드웨어 드라이버
 
- 특징: MACHINE 변수와 연동

**🌐 확장 레이어 (선택적)**
- **meta-openembedded**: 확장 소프트웨어 컬렉션
  - meta-oe: 일반적인 오픈소스 소프트웨어
  - meta-python: Python 패키지 및 런타임
  - meta-networking: 네트워킹 도구 및 프로토콜
  - meta-multimedia: 멀티미디어 라이브러리 및 도구

**🏗️ 커스텀 레이어**
- **meta-company**: 회사별 특화 레이어
- **meta-product**: 제품별 특화 레이어
- **meta-application**: 애플리케이션별 레이어

#### 2.4.2 레이어 구성 파일 구조

**표준 레이어 디렉토리 구조**
```
meta-mylayer/
├── conf/
│   ├── layer.conf          # 레이어 기본 설정
│   └── machine/            # 머신 설정 파일들
├── recipes-kernel/         # 커널 관련 레시피
├── recipes-core/          # 핵심 시스템 레시피
├── recipes-extended/      # 확장 기능 레시피
├── recipes-connectivity/  # 네트워킹 레시피
├── classes/               # 공통 클래스 파일들
├── files/                 # 레시피에서 사용할 파일들
└── README                 # 레이어 설명서
```

**layer.conf 설정 예시**
```bash
# 레이어 호환성 정의
BBPATH .= ":${LAYERDIR}"
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb ${LAYERDIR}/recipes-*/*/*.bbappend"
BBFILE_COLLECTIONS += "mylayer"
BBFILE_PATTERN_mylayer = "^${LAYERDIR}/"
BBFILE_PRIORITY_mylayer = "6"

# 의존성 레이어 정의
LAYERDEPENDS_mylayer = "core openembedded-layer"

# Yocto 버전 호환성
LAYERSERIES_COMPAT_mylayer = "scarthgap"
```

#### 2.4.3 레이어 간 상호작용

**의존성 관리**
- **LAYERDEPENDS**: 필수 의존 레이어 정의
- **LAYERRECOMMENDS**: 권장 레이어 정의
- **LAYERSERIES_COMPAT**: 지원 Yocto 버전 명시

**레시피 오버라이드 메커니즘**
```bash
# 기본 레시피: meta/recipes-core/busybox/busybox_1.36.bb
# 확장 레시피: meta-mylayer/recipes-core/busybox/busybox_1.36.bbappend

# bbappend 파일에서 기본 레시피 확장
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://custom-config.cfg"
```

Yocto는 레이어 기반 아키텍처를 사용합니다:

```mermaid
graph TB
    subgraph "Yocto Layer 계층 구조"
        subgraph "Core Layers (필수)"
            Meta["meta<br/>🏗️ Core Layer<br/>• 기본 recipes<br/>• 툴체인<br/>• 기본 이미지"]
            MetaPoky["meta-poky<br/>🎯 Distro Layer<br/>• Poky 설정<br/>• 기본 정책<br/>• 버전 관리"]
            MetaYocto["meta-yocto-bsp<br/>💻 BSP Layer<br/>• 하드웨어 지원<br/>• 커널 설정<br/>• 부트로더"]
        end
        
        subgraph "OpenEmbedded Layers"
            MetaOE["meta-openembedded<br/>📦 확장 패키지<br/>• 추가 소프트웨어<br/>• 라이브러리<br/>• 도구들"]
            MetaNetworking["meta-networking<br/>🌐 네트워킹<br/>• 네트워크 도구<br/>• 프로토콜 스택"]
            MetaPython["meta-python<br/>🐍 Python<br/>• Python 패키지<br/>• 런타임"]
        end
        
        subgraph "Custom Layers (사용자 정의)"
            MetaMyApp["meta-myapp<br/>🚀 앱 Layer<br/>• 커스텀 recipes<br/>• 애플리케이션<br/>• 설정"]
            MetaCompany["meta-company<br/>🏢 회사 Layer<br/>• 회사 정책<br/>• 브랜딩<br/>• 특수 설정"]
        end
    end
```

#### 2.4.4 실제 레이어 활용 예시

**레이어 추가 과정**
```bash
# 1. 레이어 다운로드/복제
git clone https://github.com/openembedded/meta-openembedded.git

# 2. bblayers.conf에 레이어 경로 추가
echo 'BBLAYERS += "/path/to/meta-openembedded/meta-oe"' >> conf/bblayers.conf

# 3. 레이어 의존성 확인
bitbake-layers show-layers
bitbake-layers show-dependencies
```

### 2.5 핵심 개념 정리

#### 2.5.1 메타데이터의 이해

**메타데이터 계층 구조**
```
📋 메타데이터 (Metadata)
├── 🔧 Configuration (.conf)
│   ├── Machine 설정 (hardware 특성)
│   ├── Distribution 설정 (배포판 정책)
│   └── Local 설정 (개발자 환경)
├── 📦 Recipes (.bb, .bbappend)
│   ├── 소스 위치 (SRC_URI)
│   ├── 의존성 (DEPENDS, RDEPENDS)
│   ├── 빌드 방법 (do_* tasks)
│   └── 패키지 정보 (PACKAGES, FILES)
└── 🏗️ Classes (.bbclass)
    ├── 공통 빌드 로직
    ├── 언어별 빌드 (autotools, cmake, python)
    └── 패키지 타입별 처리
```

#### 2.5.2 변수 시스템과 오버라이드

**BitBake 변수 시스템의 특징**
- **🔄 지연 확장**: `${변수명}` 형태로 런타임에 해석
- **📊 조건부 설정**: `VARIABLE:append = "값"`, `VARIABLE:prepend = "값"`
- **🎯 오버라이드**: 머신, 아키텍처, 배포판별 조건부 설정

**변수 우선순위 예시**
```bash
# 기본값
VARIABLE = "기본값"

# 머신별 오버라이드
VARIABLE:qemux86-64 = "QEMU x86-64용 값"

# 조건부 추가
VARIABLE:append = " 추가값"
VARIABLE:prepend = "앞에추가 "

# 최종 결과: "앞에추가 QEMU x86-64용 값 추가값"
```

#### 2.5.3 빌드 출력물 이해

**주요 빌드 결과물**

| 디렉토리 | 내용 | 설명 |
|----------|------|------|
| `tmp/deploy/images/` | 최종 이미지 | 부팅 가능한 루트 파일시스템 |
| `tmp/deploy/ipk/` | 패키지 파일 | 개별 소프트웨어 패키지 |
| `tmp/deploy/sdk/` | SDK | 크로스 컴파일 개발 환경 |
| `tmp/work/` | 빌드 작업공간 | 소스 코드, 빌드 로그 |
| `sstate-cache/` | 상태 캐시 | 빌드 캐시 파일 |
| `downloads/` | 다운로드 | 원본 소스 아카이브 |

**이미지 타입별 특징**
- **.ext4**: Linux ext4 파일시스템 (개발용)
- **.wic**: 부팅 가능한 디스크 이미지 (실제 하드웨어)
- **.tar.bz2**: 압축된 루트 파일시스템 (배포용)
- **.manifest**: 포함된 패키지 목록

#### 2.5.4 초보자를 위한 핵심 포인트

**✅ 기억해야 할 핵심 개념**
1. **Yocto = 빌드 시스템**: 소스에서 완전한 Linux 배포판 생성
2. **레이어 = 모듈**: 기능별로 분리된 독립적인 구성 요소
3. **레시피 = 빌드 지침서**: 개별 소프트웨어 패키지 빌드 방법
4. **BitBake = 실행 엔진**: 의존성을 고려한 병렬 빌드 관리
5. **sstate-cache = 속도의 핵심**: 중복 빌드 방지로 시간 단축

**🚫 초보자 흔한 오해**
- ❌ Yocto는 Linux 배포판이다 → ⭕ Yocto는 배포판을 만드는 도구
- ❌ 패키지 매니저로 소프트웨어 설치 → ⭕ 레시피로 빌드 시점에 포함
- ❌ 빌드 한 번이면 끝 → ⭕ 개발 과정에서 반복적 빌드 필요

---

## 3. Yocto 빌드 환경 설정

### 3.1 시스템 요구사항

#### 최소 요구사항
- **CPU**: 4코어 이상
- **RAM**: 8GB (권장 16GB)
- **Storage**: 50GB 여유 공간
- **Docker**: 20.10 이상

#### 지원 플랫폼
- ✅ x86_64 (Intel/AMD)
- ✅ ARM64 (Apple Silicon)
- ✅ Virtual Machines

### 3.2 Docker 환경 설정 실습

Docker 환경 설정 과정을 따라해보겠습니다:

```mermaid
flowchart TD
    Start([🎯 Docker 환경 설정 시작]) --> Check{💻 시스템 확인}
    Check -->|x86_64 VM| VMSetup[🖥️ VM 환경 설정<br/>./scripts/vm-start.sh]
    Check -->|ARM64 VM| ARMSetup[🔧 ARM64 특별 설정<br/>./scripts/vm-arm64-safe.sh]
    Check -->|Mac Apple Silicon| MacSetup[🍎 Mac 설정<br/>./scripts/simple-start.sh]
    Check -->|일반 환경| GeneralSetup[⚙️ 일반 설정<br/>docker compose]
    
    VMSetup --> QuickStart[🚀 빠른 시작<br/>./scripts/quick-start.sh]
    ARMSetup --> QuickStart
    MacSetup --> QuickStart
    GeneralSetup --> QuickStart
    
    QuickStart --> Success[✅ 환경 설정 완료]
```

#### 실습 단계

**1단계: 프로젝트 다운로드**
```bash
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto
```

**2단계: 빠른 시작**
```bash
# 시스템 상태 사전 확인 (권장)
./scripts/quick-start.sh --dry-run

# 실제 환경 설정 및 실행
./scripts/quick-start.sh
```

**3단계: 컨테이너 진입 확인**
```bash
# 컨테이너 내부에서 실행
whoami  # yocto 사용자 확인
pwd     # /workspace 디렉토리 확인
ls -la  # 파일 구조 확인
```

### 3.3 환경 최적화

#### 빌드 시간 최적화 전략

| 방법 | 첫 빌드 시간 | 이후 빌드 | 설정 난이도 |
|------|-------------|-----------|------------|
| 기본 방식 | 2-3시간 | 30분 | 쉬움 |
| **웹 캐시** | **30분** | **10분** | **쉬움** ⭐ |
| CDN 캐시 | 15분 | 5분 | 보통 |


#### 메모리 최적화 설정
```bash
# local.conf에 추가할 설정들
echo 'BB_NUMBER_THREADS = "4"' >> conf/local.conf
echo 'PARALLEL_MAKE = "-j 4"' >> conf/local.conf
```

---

## 4. 첫 빌드: 코어 이미지 및 빌드 프로세스

### 4.1 Yocto 환경 초기화

컨테이너 내에서 Yocto 빌드 환경을 초기화합니다:

```bash
# Yocto 빌드 환경 초기화
source /opt/poky/oe-init-build-env /workspace/build

# 또는 편의 함수 사용
yocto_init
```

### 4.2 빌드 설정 확인

#### local.conf 주요 설정
```bash
# 현재 설정 확인
cat conf/local.conf | grep -E "(MACHINE|IMAGE_INSTALL|BB_NUMBER)"

# 주요 설정 예시
MACHINE ?= "qemux86-64"
BB_NUMBER_THREADS ?= "4"
PARALLEL_MAKE ?= "-j 4"
```

#### bblayers.conf 확인
```bash
# 레이어 구성 확인
cat conf/bblayers.conf

# 사용 가능한 레이어 목록
bitbake-layers show-layers
```

### 4.3 첫 번째 빌드 실행

#### core-image-minimal 빌드
```bash
# 첫 빌드 시작 (약 30분-3시간 소요)
bitbake core-image-minimal

# 또는 편의 함수 사용
yocto_quick_build
```

#### 빌드 과정 모니터링
```bash
# 빌드 로그 확인
tail -f tmp/log/cooker/console-latest.log

# 진행 상황 확인
bitbake -g core-image-minimal
```

### 4.4 빌드 결과 확인

```bash
# 생성된 이미지 위치
ls -la tmp/deploy/images/qemux86-64/

# 주요 파일들
# - core-image-minimal-qemux86-64.ext4 (루트 파일시스템)
# - bzImage (커널 이미지)
# - bootx64.efi (부트로더)
```

---

## 5. 빌드된 이미지 실행하기

### 5.1 QEMU를 사용한 이미지 실행

```bash
# QEMU에서 이미지 실행
runqemu qemux86-64 core-image-minimal

# 네트워크 포함 실행
runqemu qemux86-64 core-image-minimal slirp

# 그래픽 인터페이스로 실행
runqemu qemux86-64 core-image-minimal nographic
```

### 5.2 가상 머신 내부 탐색

QEMU가 실행되면 다음을 확인해보세요:

```bash
# 시스템 정보 확인
uname -a
cat /etc/os-release

# 설치된 패키지 확인
opkg list-installed

# 디스크 사용량 확인
df -h

# 메모리 사용량 확인
free -h

# 프로세스 확인
ps aux
```

### 5.3 네트워크 및 연결 테스트

```bash
# 네트워크 인터페이스 확인
ip addr show

# 인터넷 연결 테스트 (슬립 모드에서)
ping -c 3 8.8.8.8

# SSH 접속 가능 확인 (다른 터미널에서)
ssh -p 2222 root@localhost
```

### 5.4 QEMU 종료

```bash
# QEMU 내부에서 종료
poweroff

# 또는 강제 종료 (호스트에서)
Ctrl+A, X
```

---

## 6. 이미지 커스터마이징: 패키지 추가

### 6.1 local.conf를 통한 패키지 추가

기본 이미지에 추가 패키지를 포함시켜보겠습니다:

```bash
# local.conf 파일 편집
vi conf/local.conf

# 다음 라인 추가
IMAGE_INSTALL:append = " nano vim htop git"
IMAGE_INSTALL:append = " python3 python3-pip"
IMAGE_INSTALL:append = " openssh-server dropbear"
```

### 6.2 재빌드 및 확인

```bash
# 수정된 설정으로 재빌드
bitbake core-image-minimal

# 새 이미지로 실행
runqemu qemux86-64 core-image-minimal

# 추가된 패키지 확인
which nano vim htop git python3
python3 --version
```

### 6.3 고급 이미지 커스터마이징

#### 이미지 크기 최적화
```bash
# local.conf에 추가
IMAGE_FEATURES += "read-only-rootfs"
IMAGE_FEATURES += "package-management"
EXTRA_IMAGE_FEATURES = "debug-tweaks"
```

#### 커널 모듈 추가
```bash
# 특정 커널 모듈 포함
IMAGE_INSTALL:append = " kernel-modules"

# 개발 도구 추가
IMAGE_INSTALL:append = " packagegroup-core-buildessential"
```

### 6.4 패키지 검색 및 정보 확인

```bash
# 사용 가능한 패키지 검색
bitbake -s | grep python

# 패키지 정보 확인
bitbake -e python3 | grep ^DESCRIPTION

# 패키지 의존성 확인
bitbake -g python3
```

---

## 7. 커스텀 레이어 및 레시피 생성

### 7.1 새 레이어 생성

커스텀 애플리케이션을 위한 새 레이어를 생성해보겠습니다:

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

### 7.2 간단한 애플리케이션 레시피 작성

#### Hello World C 프로그램 생성

```bash
# 소스 코드 디렉토리 생성
mkdir -p ../meta-myapp/recipes-myapp/hello-world/files

# C 소스 코드 작성
cat > ../meta-myapp/recipes-myapp/hello-world/files/hello.c << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello from Yocto Custom Layer!\n");
    printf("This is my first custom application.\n");
    return 0;
}
EOF

# Makefile 작성
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

#### 레시피 파일 작성

```bash
# 레시피 파일 생성
cat > ../meta-myapp/recipes-myapp/hello-world/hello-world_1.0.bb << 'EOF'
SUMMARY = "Hello World application for Yocto"
DESCRIPTION = "A simple Hello World C application demonstrating custom layer creation"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://hello.c \
           file://Makefile"

S = "${WORKDIR}"

do_compile() {
    oe_runmake
}

do_install() {
    oe_runmake install DESTDIR=${D}
}
EOF
```

### 7.3 레시피 빌드 및 테스트

```bash
# 레시피만 빌드
bitbake hello-world

# 생성된 패키지 확인
find tmp/deploy -name "*hello-world*"

# 이미지에 포함시키기
echo 'IMAGE_INSTALL:append = " hello-world"' >> conf/local.conf

# 전체 이미지 재빌드
bitbake core-image-minimal
```

### 7.4 커스텀 이미지 레시피 생성

```bash
# 커스텀 이미지 레시피 생성
mkdir -p ../meta-myapp/recipes-core/images

cat > ../meta-myapp/recipes-core/images/my-custom-image.bb << 'EOF'
SUMMARY = "My custom image with additional tools"
LICENSE = "MIT"

inherit core-image

IMAGE_FEATURES += "ssh-server-openssh package-management"

IMAGE_INSTALL = "packagegroup-core-boot \
                 packagegroup-base-extended \
                 hello-world \
                 nano \
                 vim \
                 htop \
                 git \
                 python3 \
                 python3-pip \
                 ${CORE_IMAGE_EXTRA_INSTALL}"

export IMAGE_BASENAME = "my-custom-image"
EOF

# 커스텀 이미지 빌드
bitbake my-custom-image
```

### 7.5 고급 레시피 기능

#### 패치 적용
```bash
# 패치 파일 추가
mkdir -p ../meta-myapp/recipes-myapp/hello-world/files
cat > ../meta-myapp/recipes-myapp/hello-world/files/add-timestamp.patch << 'EOF'
--- a/hello.c
+++ b/hello.c
@@ -1,7 +1,9 @@
 #include <stdio.h>
+#include <time.h>
 
 int main() {
     printf("Hello from Yocto Custom Layer!\n");
     printf("This is my first custom application.\n");
+    printf("Built at: %s", __DATE__ " " __TIME__ "\n");
     return 0;
 }
EOF

# 레시피에 패치 추가
echo 'SRC_URI += "file://add-timestamp.patch"' >> ../meta-myapp/recipes-myapp/hello-world/hello-world_1.0.bb
```

---

## 8. Yocto 고급 주제 개요

### 8.1 개발 워크플로우 최적화

#### devtool 사용
```bash
# 개발용 워크스페이스 생성
devtool create-workspace ../workspace

# 기존 레시피 수정
devtool modify hello-world

# 변경사항 적용
devtool build hello-world

# 레시피에 변경사항 반영
devtool finish hello-world ../meta-myapp
```

#### 증분 빌드 활용
```bash
# 특정 태스크만 재실행
bitbake -c compile hello-world
bitbake -c install hello-world

# 캐시 상태 확인
bitbake-diffsigs tmp/stamps/*/hello-world/
```

### 8.2 배포 및 업데이트

#### 업데이트 시스템
- **SWUpdate**: 안전한 시스템 업데이트
- **Mender**: OTA(Over-The-Air) 업데이트
- **OSTree**: 원자적 업데이트

#### 이미지 형식
```bash
# 다양한 이미지 형식 생성
IMAGE_FSTYPES += "ext4 tar.gz wic"

# 압축 이미지
IMAGE_FSTYPES += "ext4.gz tar.bz2"

# SD 카드 이미지
IMAGE_FSTYPES += "wic.gz"
```

### 8.3 보안 및 최적화

#### 보안 강화
```bash
# 보안 기능 활성화
IMAGE_FEATURES += "read-only-rootfs"
EXTRA_IMAGE_FEATURES += "empty-root-password"

# SELinux 지원
DISTRO_FEATURES:append = " selinux"
```

#### 크기 최적화
```bash
# 불필요한 기능 제거
IMAGE_FEATURES:remove = "package-management"
DISTRO_FEATURES:remove = "x11"

# 언어 설정 최적화
IMAGE_LINGUAS = "ko"
```

### 8.4 멀티플랫폼 지원

#### 다중 머신 설정
```bash
# ARM 타겟 빌드
MACHINE = "qemuarm64"
bitbake core-image-minimal

# 라즈베리파이 지원
MACHINE = "raspberrypi4"
bitbake core-image-minimal
```

#### 교차 컴파일 SDK
```bash
# SDK 생성
bitbake core-image-minimal -c populate_sdk

# 생성된 SDK 설치
./tmp/deploy/sdk/poky-glibc-x86_64-core-image-minimal-cortexa57-qemuarm64-toolchain-5.0.sh
```

---

## 9. 마무리 및 Q&A

### 9.1 강의 요약

오늘 강의에서 다룬 내용:

✅ **Yocto Project 기본 개념** 이해  
✅ **Docker 기반 개발 환경** 구축  
✅ **첫 번째 리눅스 이미지** 빌드 및 실행  
✅ **패키지 추가 및 커스터마이징** 실습  
✅ **커스텀 레이어 및 레시피** 생성  
✅ **고급 주제** 개요 학습  

### 9.2 다음 단계 학습 방향

#### 추천 학습 경로
1. **실제 하드웨어 타겟팅** (라즈베리파이, BeagleBone 등)
2. **BSP(Board Support Package) 개발**
3. **멀티미디어 및 그래픽 스택** 통합
4. **실시간 시스템** 구성
5. **보안 강화** 및 **업데이트 시스템** 구축

#### 유용한 리소스
- 📚 [Yocto Project 공식 문서](https://docs.yoctoproject.org/)
- 🌐 [OpenEmbedded Layer Index](https://layers.openembedded.org/)
- 💬 [Yocto Project 메일링 리스트](https://lists.yoctoproject.org/)
- 🐛 [Bugzilla 이슈 트래커](https://bugzilla.yoctoproject.org/)

### 9.3 실습 환경 유지

강의 후에도 계속 학습하실 수 있도록:

```bash
# 컨테이너 중지 (데이터는 보존됨)
docker compose down

# 나중에 다시 시작
docker compose run --rm yocto-lecture

# 빌드 캐시 확인
ls -la yocto-workspace/
```

### 9.4 Q&A 세션

**자주 묻는 질문들:**

**Q: 빌드 시간을 더 줄일 수 있는 방법은?**
A: sstate-cache와 DL_DIR을 공유하고, BB_NUMBER_THREADS와 PARALLEL_MAKE를 시스템에 맞게 조정하세요.

**Q: 상용 제품에 Yocto를 적용할 때 주의사항은?**
A: 라이선스 관리, 보안 업데이트 계획, 장기 지원(LTS) 버전 사용을 고려하세요.

**Q: 기존 패키지를 Yocto에 포팅하는 방법은?**
A: recipetool을 사용하여 자동 생성하거나, devtool을 활용한 점진적 개발을 추천합니다.

**Q: ARM64와 x86_64 동시 지원 방법은?**
A: MACHINE 변수를 통한 멀티플랫폼 설정과 교차 컴파일 툴체인을 활용하세요.

---

## 📚 부록

### A.1 유용한 BitBake 명령어

```bash
# 레시피 검색
bitbake -s | grep <pattern>

# 레시피 정보 확인
bitbake -e <recipe>

# 의존성 그래프 생성
bitbake -g <recipe>

# 특정 태스크 실행
bitbake -c <task> <recipe>

# 패키지 내용 확인
oe-pkgdata-util list-pkg-files <package>
```

### A.2 디버깅 팁

```bash
# 빌드 로그 확인
bitbake -v <recipe>

# 작업 디렉토리 확인
bitbake -c devshell <recipe>

# 패키지 의존성 문제 해결
bitbake -k <recipe>

# 캐시 정리
bitbake -c cleanall <recipe>
```

### A.3 성능 튜닝

```bash
# local.conf 최적화 설정
BB_NUMBER_THREADS = "8"
PARALLEL_MAKE = "-j 8"
BB_HASHBASE_WHITELIST:append = " BB_NUMBER_THREADS PARALLEL_MAKE"

# 디스크 I/O 최적화
SSTATE_DIR = "/fast-storage/sstate-cache"
DL_DIR = "/fast-storage/downloads"
```

---

**강의 자료 끝**

이 자료는 KEA Yocto Project 강의를 위해 제작되었습니다.  
문의사항이 있으시면 언제든지 질문해주세요! 🚀 