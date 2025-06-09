# 🔧 문제 해결 가이드

## Docker Credential 문제

### 증상
```
error getting credentials - err: exec: "docker-credential-desktop": executable file not found in $PATH
```

### 해결 방법

#### 방법 1: Docker 설정 임시 수정 (권장)
```bash
# 기존 설정 백업
mv ~/.docker/config.json ~/.docker/config.json.backup

# 간단한 설정 생성
echo '{"auths": {}}' > ~/.docker/config.json

# 빌드 실행
docker build -t yocto-lecture:5.0-lts .

# 빌드 완료 후 설정 복원 (선택사항)
mv ~/.docker/config.json.backup ~/.docker/config.json
```

#### 방법 2: Docker Desktop 재시작
1. Docker Desktop 완전 종료
2. 몇 초 후 재시작
3. 다시 빌드 시도

#### 방법 3: Docker CLI 플러그인 재설치
```bash
# Docker Desktop 재설치를 통한 해결
# 또는 Homebrew로 Docker 재설치
brew reinstall docker
```

## 이미지 빌드 실패

### 증상
- `yocto-lecture:5.0-lts` 이미지를 찾을 수 없음
- `repository does not exist` 오류

### 해결 방법
1. **로컬 빌드 실행**:
   ```bash
   docker build -t yocto-lecture:5.0-lts .
   ```

2. **멀티 아키텍처 빌드** (Docker Hub 푸시용):
   ```bash
   ./scripts/build-multiarch.sh YOUR_DOCKER_USERNAME
   ```

3. **자동 빌드가 포함된 실행**:
   ```bash
   ./scripts/quick-start.sh
   # 이미지가 없으면 자동으로 빌드 옵션 제공
   ```

## Apple Silicon 관련 문제

### 증상
- x86_64 이미지 실행 시 성능 저하
- QEMU 에뮬레이션 오류

### 해결 방법
1. **아키텍처 확인**:
   ```bash
   uname -m  # arm64면 Apple Silicon
   ```

2. **x86_64 에뮬레이션 실행**:
   ```bash
   docker run --platform linux/amd64 -it yocto-lecture:5.0-lts
   ```

3. **네이티브 arm64 이미지 사용** (성능 우선시):
   ```bash
   docker run -it yocto-lecture:5.0-lts
   ```

## 빌드 속도 최적화

### Docker 빌드 캐시 활용
```bash
# 빌드 캐시 확인
docker system df

# 필요시 캐시 정리
docker builder prune
```

### 멀티 코어 활용
Dockerfile에서 BB_NUMBER_THREADS와 PARALLEL_MAKE 설정이 자동으로 최적화됩니다.

## 연락처
문제가 지속되면 프로젝트 이슈 트래커에 문의하세요. 