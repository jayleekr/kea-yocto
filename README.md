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
| `generate-html.sh` | 강의 자료 HTML 생성 | 10초 |
| `test-html-formatting.py` | HTML 포맷팅 자동 테스트 및 수정 | 30초 |
| `quick-start.sh` | Yocto 환경 빠른 시작 | 3분 |

---

## 📚 강의 자료 생성

### 🌐 **HTML 버전 (완벽한 Mermaid 지원)** ⭐

```bash
# 강의 자료 HTML 생성
./scripts/generate-html.sh

# 브라우저에서 열기
open materials/KEA-Yocto-Project-강의자료.html
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

### 📝 강의 자료 HTML 생성

```bash
# HTML 자료 생성
cd materials && ../scripts/generate-html.sh

# 포맷팅 문제 자동 검사 및 수정
python3 scripts/test-html-formatting.py
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
- **Pandoc**: 3.0+ (강의 자료 생성용)

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

| 스크립트 | 용도 | 실행 시간 |
|----------|------|-----------|
| `test-basic.sh` | 기본 시스템 검증 | 1분 |
| `verify-system.sh` | 종합 시스템 검증 | 5분 |
| `fix-system.sh` | 자동 문제 해결 | 2분 |
| `generate-html.sh` | 강의 자료 HTML 생성 | 10초 |
| `test-html-formatting.py` | HTML 포맷팅 자동 테스트 및 수정 | 30초 |
| `quick-start.sh` | Yocto 환경 빠른 시작 | 3분 |

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

# 권한 문제
sudo chown -R $USER:$USER .

# 스크립트 권한
chmod +x scripts/*.sh
```

### 강의 자료 생성 문제
```bash
# Pandoc 설치 (macOS)
brew install pandoc

# Pandoc 설치 (Ubuntu)
sudo apt install pandoc
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

- 📧 이슈: [GitHub Issues](https://github.com/jayleekr/kea-yocto/issues)
- 📚 문서: [Wiki](https://github.com/jayleekr/kea-yocto/wiki)
- 💬 토론: [Discussions](https://github.com/jayleekr/kea-yocto/discussions)

---

**Happy Yocto Building! 🚀** 