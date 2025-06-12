# 빌드된 이미지 실행하기

## QEMU를 사용한 이미지 실행

### 기본 실행

```bash
# QEMU에서 이미지 실행
runqemu qemux86-64 core-image-minimal

# 네트워크 포함 실행 (인터넷 연결)
runqemu qemux86-64 core-image-minimal slirp

# 그래픽 없이 터미널에서 실행
runqemu qemux86-64 core-image-minimal nographic
```

!!! tip "runqemu 옵션들"
    - **slirp**: 호스트 네트워크를 통한 인터넷 연결
    - **nographic**: VNC 대신 터미널에서 직접 실행
    - **kvm**: 하드웨어 가상화 활용 (Linux 호스트에서)
    - **serial**: 시리얼 콘솔 활성화

### 다양한 실행 방법

```bash
# 1. VNC로 그래픽 인터페이스 실행
runqemu qemux86-64 core-image-minimal

# 2. 터미널에서 직접 실행 (추천)
runqemu qemux86-64 core-image-minimal nographic

# 3. 네트워크와 KVM 가속 활용
runqemu qemux86-64 core-image-minimal slirp kvm

# 4. 메모리 크기 지정
runqemu qemux86-64 core-image-minimal qemuparams="-m 1024"
```

## 가상 머신 내부 탐색

### 시스템 정보 확인

QEMU가 실행되면 다음을 확인해보세요:

```bash
# 시스템 정보 확인
uname -a
cat /etc/os-release

# 커널 정보
cat /proc/version

# CPU 정보  
cat /proc/cpuinfo

# 메모리 정보
cat /proc/meminfo
free -h
```

### 설치된 패키지 확인

```bash
# 설치된 패키지 목록
opkg list-installed

# 특정 패키지 검색
opkg list-installed | grep busybox

# 사용 가능한 패키지 (네트워크 연결 시)
opkg update
opkg list
```

### 파일시스템 구조 탐색

```bash
# 디스크 사용량 확인
df -h

# 디렉토리 구조 확인
ls -la /
tree / | head -30

# 시스템 디렉토리들
ls -la /bin /sbin /usr/bin /usr/sbin

# 설정 파일들
ls -la /etc/
```

### 프로세스 및 서비스 확인

```bash
# 실행 중인 프로세스
ps aux

# 시스템 서비스 (systemd 기반)
systemctl status

# 활성화된 서비스만 확인
systemctl list-units --type=service --state=active

# 네트워크 서비스
systemctl status networking
```

## 네트워크 및 연결 테스트

### 네트워크 설정 확인

```bash
# 네트워크 인터페이스 확인
ip addr show
ifconfig

# 라우팅 테이블
ip route show
route -n

# DNS 설정
cat /etc/resolv.conf
```

### 인터넷 연결 테스트 (slirp 모드에서)

```bash
# 기본 연결 테스트
ping -c 3 8.8.8.8

# DNS 해결 테스트
ping -c 3 google.com

# HTTP 테스트 (wget이 있는 경우)
wget -O - http://httpbin.org/ip 2>/dev/null
```

### SSH 접속 설정

```bash
# SSH 데몬 시작 (이미지에 포함된 경우)
systemctl start ssh
systemctl enable ssh

# SSH 포트 확인
netstat -tlnp | grep :22
```

**호스트에서 SSH 접속:**
```bash
# QEMU의 SSH 포트로 연결 (보통 2222)
ssh -p 2222 root@localhost

# 또는 특정 IP로 연결
ssh root@192.168.7.2
```

## 시스템 로그 및 디버깅

### 시스템 로그 확인

```bash
# 시스템 부팅 로그
dmesg | head -50
dmesg | tail -20

# systemd 저널 (지원하는 경우)
journalctl -n 50

# 시스템 로그 파일들
ls -la /var/log/
tail /var/log/messages
```

### 성능 및 리소스 모니터링

```bash
# CPU 및 메모리 사용량 (htop이 있는 경우)
htop

# 또는 기본 top
top

# 디스크 I/O
iostat 1 5

# 시스템 업타임
uptime
```

## 애플리케이션 테스트

### 기본 도구들 테스트

```bash
# 파일 편집 (vi는 거의 항상 있음)
vi /tmp/test.txt

# 네트워크 도구 (busybox 기반)
wget --help
nc --help

# 시스템 유틸리티
which busybox
busybox --help
```

### 개발 도구 테스트 (포함된 경우)

```bash
# 컴파일러 확인
gcc --version
g++ --version

# Python 확인
python3 --version
python3 -c "print('Hello from Yocto!')"

# 패키지 관리
pip3 --version
```

## QEMU 종료 및 관리

### 정상 종료

```bash
# QEMU 내부에서 시스템 종료
poweroff
shutdown -h now

# 또는 reboot으로 재시작
reboot
```

### 강제 종료

```bash
# QEMU 모니터 콘솔에서 (Ctrl+Alt+2)
(qemu) quit

# 또는 터미널에서 강제 종료
Ctrl+A, X  # nographic 모드에서

# 호스트에서 프로세스 종료
pkill qemu
```

### QEMU 디버깅 모드

```bash
# 디버그 정보와 함께 실행
runqemu qemux86-64 core-image-minimal nographic qemuparams="-d int,pcall"

# 시리얼 콘솔 로그 저장
runqemu qemux86-64 core-image-minimal nographic qemuparams="-serial file:qemu-console.log"
```

## 고급 QEMU 사용법

### 스냅샷 및 백업

```bash
# QEMU 모니터에서 스냅샷 생성
(qemu) savevm snapshot1

# 스냅샷 복원
(qemu) loadvm snapshot1

# 스냅샷 목록 확인
(qemu) info snapshots
```

### 파일 공유

```bash
# 호스트 디렉토리를 게스트와 공유
runqemu qemux86-64 core-image-minimal qemuparams="-virtfs local,path=/host/share,mount_tag=host0,security_model=passthrough"

# 게스트에서 마운트
mkdir /mnt/host
mount -t 9p -o trans=virtio,version=9p2000.L host0 /mnt/host
```

## 문제 해결

### 일반적인 문제들

!!! warning "QEMU가 시작되지 않는 경우"
    ```bash
    # 이미지 파일 확인
    ls -la tmp/deploy/images/qemux86-64/
    
    # runqemu 경로 확인
    which runqemu
    
    # 상세 로그로 실행
    runqemu qemux86-64 core-image-minimal nographic debug
    ```

!!! danger "부팅이 멈추는 경우"
    ```bash
    # 커널 파라미터 추가
    runqemu qemux86-64 core-image-minimal nographic bootparams="debug"
    
    # 시리얼 콘솔 강제 활성화
    runqemu qemux86-64 core-image-minimal nographic bootparams="console=ttyS0"
    ```

!!! info "네트워크가 작동하지 않는 경우"
    ```bash
    # slirp 모드로 다시 실행
    runqemu qemux86-64 core-image-minimal slirp
    
    # 네트워크 설정 확인
    ip link show
    dhclient eth0
    ```

---

← [첫 빌드](first-build.md) | [이미지 커스터마이징](customize.md) → 