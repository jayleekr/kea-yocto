# KEA Yocto Project 5.0 LTS

Docker 기반 Yocto Project 개발 환경 및 강의 자료

---

## 🚀 빠른 시작

### 자동 스크립트로 시작하기

| 스크립트 | 용도 | 실행 시간 |
|----------|------|-----------|
| `test-basic.sh` | 기본 시스템 검증 | 1분 |
| `verify-system.sh` | 종합 시스템 검증 | 5분 |
| `fix-system.sh` | 자동 문제 해결 | 2분 |
| `test-html-formatting.py` | HTML 포맷팅 자동 테스트 및 수정 | 30초 |
| `quick-start.sh` | Yocto 환경 빠른 시작 | 3분 |

---

## 📦 Yocto 캐시 배포 시스템 ⭐ 

### 🌐 **GitHub 캐시 다운로드 (권장)** 

미리 빌드된 캐시를 다운로드하여 **80-90% 빌드 시간 단축**:

```bash
# 프로젝트 클론
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto

# 자동 캐시 다운로드 및 설정
./download-cache.sh
```

**다운로드 내용:**
- ✅ **6.7GB 완전한 빌드 캐시** (downloads + sstate)
- ✅ **88개 소스 패키지** 사전 다운로드
- ✅ **257개 빌드 상태** 캐시
- ✅ **검증된 무결성** (MD5/SHA256 체크섬)

### 🔧 **캐시 생성 및 업로드**

새로운 캐시를 생성하거나 기존 캐시를 업데이트:

```bash
# 전체 이미지 캐시 생성 (6.7GB)
./scripts/build-full-image-cache.sh

# 간단한 모듈 캐시 생성 (테스트용)
./scripts/build-simple-module.sh

# GitHub에 캐시 업로드 (자동 파일 분할)
./scripts/upload-split-cache-github.sh
```

### 📊 **캐시 시스템 특징**

| 기능 | 설명 | 성능 |
|------|------|------|
| **자동 분할** | 2GB GitHub 제한 자동 처리 | ✅ |
| **무결성 검증** | MD5/SHA256 체크섬 | ✅ |
| **재구성** | 분할 파일 자동 병합 | ✅ |
| **빌드 가속** | 80-90% 시간 단축 | 🚀 |
| **글로벌 배포** | GitHub Releases 기반 | 🌍 |

### 🧪 **캐시 테스트 도구**

```bash
# 캐시 효율성 테스트
./scripts/test-cache-efficiency.py

# 최소 캐시 테스트  
./scripts/test-minimal-cache.sh

# 업로드/다운로드 테스트
./scripts/test-cache-upload-download.sh
```

---

## 📚 강의 자료 생성

### 🌐 **온라인 강의 자료** ⭐

**GitHub Pages에서 바로 확인하기:**
- 📖 **온라인 강의 자료**: https://jayleekr.github.io/kea-yocto/
- 🔄 **자동 업데이트**: main 브랜치 push 시 자동 배포

### 🌐 **온라인 접근** ⭐

```bash
# 온라인 강의 자료는 GitHub Pages에서 확인
# https://jayleekr.github.io/kea-yocto/
```

### ✨ **특징**
- 🎯 **완벽한 Mermaid 다이어그램 지원** - 4개의 복잡한 다이어그램 완벽 렌더링
- 🎨 **GitHub 스타일 디자인** - 깔끔하고 전문적인 외관
- 📱 **반응형 디자인** - 모든 디바이스에서 최적화
- 🖨️ **PDF 변환 지원** - 브라우저에서 `Cmd+P` → "PDF로 저장"
- ⚡ **빠른 생성** - 10초 이내 완성
- 📖 **목차 자동 생성** - 탐색이 쉬운 구조

### 📄 **생성되는 파일**
- `materials/KEA-Yocto-Project-강의자료.html` - 완성된 강의 자료

### 📝 강의 자료 확인

```bash
# 온라인 강의 자료 확인
# GitHub Pages: https://jayleekr.github.io/kea-yocto/

# 로컬에서 markdown 파일 확인
ls docs/lecture/
```

**HTML 포맷팅 테스트 기능:**
- 🔍 **테이블 포맷팅**: 테이블이 올바르게 렌더링되는지 검사
- 📝 **텍스트 포맷팅**: 연결된 텍스트 항목을 자동 분리
- 🚀 **자동 수정**: 발견된 문제를 자동으로 수정
- 📊 **상세 리포트**: 문제 유형별 분류 및 수정 내역 제공

---

## 🛠️ 시스템 요구사항

### 필수 요구사항
- **Docker**: 20.10+ 
- **Git**: 2.30+


### 권장 환경
- **OS**: macOS (Apple Silicon/Intel), Ubuntu 22.04+
- **RAM**: 8GB+ (Yocto 빌드용)
- **Storage**: 50GB+ 여유 공간

---

## 🐳 Yocto 개발 환경

### 환경 설정
```bash
# 프로젝트 클론
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto

# 빠른 시작
./scripts/quick-start.sh
```

### Docker 컨테이너 사용
```bash
# 컨테이너 진입
docker compose exec yocto bash

# 빌드 환경 초기화
source /opt/poky/oe-init-build-env

# 이미지 빌드 (예시)
bitbake core-image-minimal
```

---

## 📋 주요 스크립트

### 🚀 시스템 및 환경 설정
| 스크립트 | 용도 | 실행 시간 |
|----------|------|-----------|
| `test-basic.sh` | 기본 시스템 검증 | 1분 |
| `verify-system.sh` | 종합 시스템 검증 | 5분 |
| `fix-system.sh` | 자동 문제 해결 | 2분 |
| `quick-start.sh` | Yocto 환경 빠른 시작 | 3분 |
| `scripts/vm-user-setup.sh` | VM 사용자 sudo 설정 (패스워드 없이) | 30초 |

### 📦 캐시 배포 시스템
| 스크립트 | 용도 | 크기/시간 |
|----------|------|-----------|
| `download-cache.sh` | GitHub 캐시 자동 다운로드 | 6.7GB / 15분 |
| `scripts/build-full-image-cache.sh` | 완전한 이미지 캐시 생성 | 6.7GB / 2시간 |
| `scripts/build-simple-module.sh` | 간단한 모듈 캐시 생성 | 40MB / 10분 |
| `scripts/upload-split-cache-github.sh` | GitHub 캐시 업로드 (분할) | - / 15분 |
| `scripts/test-cache-efficiency.py` | 캐시 효율성 분석 | - / 5분 |

### 📚 강의 자료 확인
| 리소스 | 용도 | 접근 방법 |
|----------|------|-----------|
| GitHub Pages | 온라인 강의 자료 | https://jayleekr.github.io/kea-yocto/ |
| `docs/lecture/` | 로컬 마크다운 파일 | 직접 읽기 |

---

## 🎯 주요 기능

### ✅ 완전 자동화된 검증 시스템
- 29가지 시스템 상태 검증
- 자동 문제 진단 및 해결
- 컬러풀한 진행상황 표시

### ✅ 강력한 강의 자료 시스템  
- Mermaid 다이어그램 완벽 지원
- 전문적인 GitHub 스타일 디자인
- 브라우저에서 바로 PDF 변환 가능

### ✅ 최적화된 Yocto 환경
- Docker 기반 일관된 환경
- 빠른 캐시 및 다운로드 최적화
- 멀티 플랫폼 지원 (x86/ARM64)

---

## 🔧 문제 해결

### 일반적인 문제
```bash
# Docker 관련 문제
docker system prune -a

# 권한 문제 (호스트)
sudo chown -R $USER:$USER .

# 스크립트 권한
chmod +x scripts/*.sh
```

### Docker 컨테이너 권한 문제

**가장 흔한 문제**: Docker 컨테이너에서 `/workspace/build` 디렉토리 생성 시 권한 에러

```bash
# 증상: Permission denied 에러
mkdir: cannot create directory '/workspace/build': Permission denied

# 해결책: 컨테이너 내부에서 권한 수정
docker compose exec yocto-lecture sudo chown -R yocto:yocto /workspace

# 또는 컨테이너 진입 시 자동 권한 수정
docker compose exec yocto-lecture bash -c "sudo chown -R yocto:yocto /workspace && bash"
```

### Ubuntu 24.04 User Namespace 문제

**증상**: BitBake 실행 시 user namespace 에러

```bash
ERROR: User namespaces are not usable by BitBake, possibly due to AppArmor.
```

**해결책**: 호스트에서 user namespace 제한 해제
```bash
# 임시 해결 (재부팅 시 리셋)
sudo sysctl kernel.apparmor_restrict_unprivileged_userns=0

# 영구 해결
echo 'kernel.apparmor_restrict_unprivileged_userns = 0' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 컨테이너 재시작
docker compose restart yocto-lecture
```

### 강의 자료 생성 문제
```bash
# 강의 자료는 이제 별도의 도구 없이 생성됩니다
# HTML 파일은 브라우저에서 직접 열 수 있습니다
```

---

## 📈 버전 정보

- **Yocto Project**: 5.0 LTS (Scarthgap)
- **Ubuntu Base**: 24.04 LTS
- **Docker**: 20.10+
- **강의 자료**: HTML 기반 v2.0

---

## 🤝 기여하기

프로젝트 개선에 참여해 주세요!

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

---

## 📞 지원

- 📖 **온라인 강의 자료**: [GitHub Pages](https://jayleekr.github.io/kea-yocto/)
- 📧 이슈: [GitHub Issues](https://github.com/jayleekr/kea-yocto/issues)
- 📚 문서: [Wiki](https://github.com/jayleekr/kea-yocto/wiki)
- 💬 토론: [Discussions](https://github.com/jayleekr/kea-yocto/discussions)

---

**Happy Yocto Building! 🚀**

# KEA Yocto Project 5.0 LTS 강의 문서

이 저장소는 KEA(한국전자기술연구원) Yocto Project 강의 자료와 문서화 시스템을 포함합니다.

## 📚 문서 구조

```
├── docs/                    # MkDocs 문서 소스
│   ├── index.md            # 홈페이지
│   ├── lecture/            # 강의 자료들
│   └── stylesheets/        # 커스텀 CSS
├── materials/              # 원본 강의 자료
├── mkdocs.yml             # MkDocs 설정
├── requirements.txt       # Python 의존성
└── build-docs.sh         # 문서 빌드 스크립트
```

## 🚀 빠른 시작

### 1. 문서 빌드하기

```bash
# 자동 빌드 (권장)
./build-docs.sh

# 또는 수동으로
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
mkdocs build
```

### 2. 로컬 개발 서버 실행

```bash
# 가상환경 활성화 후
mkdocs serve

# 브라우저에서 http://localhost:8000 접속
```

### 3. 문서 수정하기

1. `docs/` 디렉토리 내의 마크다운 파일 수정
2. `mkdocs serve`로 실시간 미리보기
3. 만족스러우면 `mkdocs build`로 최종 빌드

## 🎨 특징

### Material Design 테마

- 🌙 **다크/라이트 모드** 자동 전환
- 📱 **반응형 디자인** 모바일 최적화
- 🔍 **강력한 검색** 기능
- 📖 **목차 자동 생성**
- 🎯 **코드 복사** 버튼

### 고급 마크다운 기능

!!! tip "지원하는 확장 기능"
    - ✅ **Admonitions** (팁, 경고, 노트 박스)
    - ✅ **Mermaid 다이어그램**
    - ✅ **코드 하이라이팅**
    - ✅ **탭 그룹**
    - ✅ **작업 목록**
    - ✅ **이모지 지원**

### 예시: 탭 그룹

=== "Ubuntu/Debian"
    ```bash
    sudo apt update
    sudo apt install python3-pip
    ```

=== "macOS"
    ```bash
    brew install python3
    ```

=== "Windows"
    ```powershell
    python -m pip install --upgrade pip
    ```

## 📖 문서 작성 가이드

### Admonitions 사용법

```markdown
!!! note "제목"
    내용을 여기에 작성합니다.

!!! tip "팁"
    유용한 정보

!!! warning "주의"
    주의사항

!!! danger "위험"
    중요한 경고
```

### Mermaid 다이어그램

```markdown
```mermaid
graph TD
    A[시작] --> B[처리]
    B --> C[완료]
` ``
```

## 🚀 배포

### GitHub Pages

```bash
# gh-pages 브랜치에 배포
mkdocs gh-deploy
```

### 수동 배포

```bash
# site/ 디렉토리를 웹서버에 업로드
mkdocs build
rsync -av site/ user@server:/var/www/html/
```

## 🔧 커스터마이징

### 테마 설정

`mkdocs.yml`에서 다음을 수정:

```yaml
theme:
  name: material
  palette:
    primary: blue     # 기본 색상
    accent: blue      # 강조 색상
```

### 플러그인 추가

`requirements.txt`에 플러그인 추가 후:

```yaml
plugins:
  - search
  - minify
  - your-plugin
```

## 🆚 다른 도구들과 비교

| 도구 | 장점 | 단점 | 적합성 |
|------|------|------|--------|
| **MkDocs** | 간단, 빠름, 문서 특화 | 블로그 기능 제한 | ⭐⭐⭐⭐⭐ |
| Jekyll | GitHub Pages 공식 지원 | Ruby 의존성, 느림 | ⭐⭐⭐ |
| Hugo | 매우 빠름, 강력함 | 복잡한 설정 | ⭐⭐⭐⭐ |
| Sphinx | 전문적, 강력함 | 복잡함, 학습곡선 | ⭐⭐⭐ |

## 📞 도움말

- [MkDocs 공식 문서](https://www.mkdocs.org/)
- [Material 테마 문서](https://squidfunk.github.io/mkdocs-material/)
- [Mermaid 다이어그램 문법](https://mermaid.js.org/)

---

## 🎓 Yocto 강의 관련

실제 Yocto 강의 및 실습은 별도의 Docker 환경에서 진행됩니다:

```bash
git clone https://github.com/jayleekr/kea-yocto.git
cd kea-yocto
./scripts/quick-start.sh
```
