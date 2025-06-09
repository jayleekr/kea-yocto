# Yocto 5.0 LTS 강의 환경 Dockerfile
# 멀티 플랫폼 지원

ARG UBUNTU_VERSION=24.04
ARG TARGETPLATFORM=linux/amd64
FROM --platform=${TARGETPLATFORM} ubuntu:${UBUNTU_VERSION}

# 빌드 인수 설정
ARG YOCTO_VERSION=5.0

# 메타데이터
LABEL maintainer="Yocto Lecture Team"
LABEL description="Yocto Project 5.0 LTS 강의 환경 (x86_64 전용)"
LABEL version="1.0"
LABEL yocto.version="5.0-LTS"
LABEL platform="x86_64"

# 환경 변수 설정
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=Asia/Seoul
ENV YOCTO_USER=yocto
ENV YOCTO_HOME=/home/yocto
ENV POKY_DIR=/opt/poky

# 시스템 업데이트
RUN apt-get clean && apt-get update

# 기본 시스템 도구 설치
RUN apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    vim \
    nano \
    sudo \
    locales \
    tzdata \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Yocto 필수 패키지 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    gawk \
    git-core \
    diffstat \
    unzip \
    texinfo \
    gcc-multilib \
    build-essential \
    chrpath \
    socat \
    cpio \
    python3 \
    python3-pip \
    python3-pexpect \
    xz-utils \
    debianutils \
    iputils-ping \
    python3-git \
    python3-jinja2 \
    libegl1 \
    libsdl1.2-dev \
    xterm \
    && rm -rf /var/lib/apt/lists/*

# Python 도구 설치 (시스템 패키지로)
RUN apt-get update && apt-get install -y --no-install-recommends \
    pylint \
    && rm -rf /var/lib/apt/lists/*

# QEMU 및 개발 도구 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-system-arm \
    qemu-utils \
    tree \
    htop \
    screen \
    tmux \
    file \
    lz4 \
    zstd \
    && rm -rf /var/lib/apt/lists/*

# 로케일 설정
RUN locale-gen en_US.UTF-8

# 시간대 설정
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# yocto 사용자 생성
RUN useradd -m -s /bin/bash $YOCTO_USER && \
    echo "$YOCTO_USER:yocto" | chpasswd && \
    usermod -aG sudo $YOCTO_USER && \
    echo "$YOCTO_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Poky 저장소 클론 (아키텍처별 최적화)
RUN mkdir -p $POKY_DIR && \
    git clone -b scarthgap https://git.yoctoproject.org/poky $POKY_DIR && \
    chown -R $YOCTO_USER:$YOCTO_USER $POKY_DIR

# 작업 디렉토리 설정
RUN mkdir -p /workspace /opt/yocto/downloads /opt/yocto/sstate-cache && \
    chown -R $YOCTO_USER:$YOCTO_USER /workspace /opt/yocto

# 설정 파일 템플릿 복사
COPY --chown=$YOCTO_USER:$YOCTO_USER configs/ /opt/configs/

# 스크립트 복사 및 실행 권한 설정
COPY --chown=$YOCTO_USER:$YOCTO_USER scripts/ /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

# 환경 초기화 스크립트 생성
RUN echo '#!/bin/bash' > /etc/profile.d/yocto-env.sh && \
    echo 'export POKY_DIR=/opt/poky' >> /etc/profile.d/yocto-env.sh && \
    echo 'export YOCTO_USER=yocto' >> /etc/profile.d/yocto-env.sh && \
    echo 'export BB_ENV_PASSTHROUGH_ADDITIONS="$BB_ENV_PASSTHROUGH_ADDITIONS MACHINE DL_DIR SSTATE_DIR"' >> /etc/profile.d/yocto-env.sh && \
    echo '' >> /etc/profile.d/yocto-env.sh && \
    echo '# x86_64 타겟 설정' >> /etc/profile.d/yocto-env.sh && \
    echo 'export MACHINE="qemux86-64"' >> /etc/profile.d/yocto-env.sh && \
    echo '' >> /etc/profile.d/yocto-env.sh && \
    echo '# 편의 함수 정의' >> /etc/profile.d/yocto-env.sh && \
    echo 'yocto_init() {' >> /etc/profile.d/yocto-env.sh && \
    echo '    if [ -d "$POKY_DIR" ]; then' >> /etc/profile.d/yocto-env.sh && \
    echo '        source $POKY_DIR/oe-init-build-env ${1:-/workspace/build}' >> /etc/profile.d/yocto-env.sh && \
    echo '    else' >> /etc/profile.d/yocto-env.sh && \
    echo '        echo "Error: Poky directory not found at $POKY_DIR"' >> /etc/profile.d/yocto-env.sh && \
    echo '    fi' >> /etc/profile.d/yocto-env.sh && \
    echo '}' >> /etc/profile.d/yocto-env.sh && \
    echo '' >> /etc/profile.d/yocto-env.sh && \
    echo 'yocto_quick_build() {' >> /etc/profile.d/yocto-env.sh && \
    echo '    echo "Starting quick build for core-image-minimal..."' >> /etc/profile.d/yocto-env.sh && \
    echo '    bitbake core-image-minimal' >> /etc/profile.d/yocto-env.sh && \
    echo '}' >> /etc/profile.d/yocto-env.sh && \
    echo '' >> /etc/profile.d/yocto-env.sh && \
    echo 'yocto_run_qemu() {' >> /etc/profile.d/yocto-env.sh && \
    echo '    echo "Starting QEMU with core-image-minimal..."' >> /etc/profile.d/yocto-env.sh && \
    echo '    runqemu ${MACHINE} core-image-minimal' >> /etc/profile.d/yocto-env.sh && \
    echo '}' >> /etc/profile.d/yocto-env.sh && \
    echo '' >> /etc/profile.d/yocto-env.sh && \
    echo 'alias ll="ls -la"' >> /etc/profile.d/yocto-env.sh && \
    echo 'alias bb="bitbake"' >> /etc/profile.d/yocto-env.sh && \
    echo 'alias bbl="bitbake-layers"' >> /etc/profile.d/yocto-env.sh && \
    chmod +x /etc/profile.d/yocto-env.sh

# 사용자 전환
USER $YOCTO_USER
WORKDIR $YOCTO_HOME

# 사용자 환경 설정
RUN echo 'source /etc/profile.d/yocto-env.sh' >> ~/.bashrc && \
    echo 'export PS1="\[\033[01;32m\]\u@yocto-lecture\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc

# 기본 빌드 환경 설정 (백그라운드에서 준비)
RUN /bin/bash -c 'source $POKY_DIR/oe-init-build-env /tmp/prebuild && \
    cp /opt/configs/local.conf.template conf/local.conf 2>/dev/null || true && \
    cp /opt/configs/bblayers.conf.template conf/bblayers.conf 2>/dev/null || true'

# 포트 노출 (QEMU 네트워킹용)
EXPOSE 2222 5555 8080

# 볼륨 마운트 포인트
VOLUME ["/workspace", "/opt/yocto/downloads", "/opt/yocto/sstate-cache"]

# 헬스체크 추가
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD bitbake --version || exit 1

# 시작 스크립트
CMD ["/bin/bash", "-l"] 