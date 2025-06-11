# KEA Yocto Project 강의 자료

이 디렉토리는 **KEA Yocto Project 8시간 강의**를 위한 모든 자료를 포함하고 있습니다.

## 📁 파일 구조

```
materials/
├── README.md                    # 이 파일 (사용법 가이드)
├── lecture-materials.md         # 강의 자료 본문 (833라인)
├── pandoc-template.yaml         # PDF 변환 템플릿 설정
├── generate-pdf.sh              # PDF 생성 스크립트 (자동 버전 관리)
├── version.txt                  # 현재 버전 정보
├── KEA-Yocto-Project-강의자료-v1.0.1.pdf # 버전별 PDF 파일들
├── KEA-Yocto-Project-강의자료-v1.0.2.pdf
└── KEA-Yocto-Project-강의자료-latest.pdf # 최신 버전 심볼릭 링크
```

## 🚀 사용법

### 방법 1: Docker 컨테이너 사용 (권장 ⭐)

별도 소프트웨어 설치 없이 Docker만 있으면 PDF를 생성할 수 있습니다:

```bash
# 프로젝트 루트 디렉토리에서 실행
./scripts/generate-pdf-docker.sh

# 상세 모드로 생성
./scripts/generate-pdf-docker.sh --verbose

# 컨테이너 재빌드 후 생성 (최초 실행 시)
./scripts/generate-pdf-docker.sh --rebuild

# 생성 결과:
# - materials/KEA-Yocto-Project-강의자료-v1.0.X.pdf (새 버전)
# - materials/KEA-Yocto-Project-강의자료-latest.pdf (최신 링크)
```

### 방법 2: 로컬 환경 사용

로컬에 pandoc이 설치된 경우:

```bash
# materials 디렉토리로 이동
cd materials

# PDF 생성 스크립트 실행 (버전 자동 증가)
./generate-pdf.sh

# 생성 결과:
# - KEA-Yocto-Project-강의자료-v1.0.X.pdf (새 버전)
# - KEA-Yocto-Project-강의자료-latest.pdf (최신 링크)
```

### 1. 버전 관리

```bash
# 현재 버전 확인
cat version.txt

# 생성된 모든 버전 확인
ls -la KEA-Yocto-Project-강의자료-v*.pdf

# 특정 버전으로 수동 설정 (필요시)
echo "2.0.0" > version.txt
```

### 2. 강의 자료 수정하기

```bash
# 마크다운 파일 편집
vi lecture-materials.md

# 수정 후 PDF 재생성 (새 버전 생성)
./generate-pdf.sh
```

### 3. 템플릿 커스터마이징

```bash
# Pandoc 템플릿 설정 수정
vi pandoc-template.yaml

# 폰트, 레이아웃, 스타일 등을 변경할 수 있습니다
```

## 📋 의존성

### Docker 사용 시 (권장)
- Docker 20.10+ 
- Docker Compose v2.0+

### 로컬 환경 사용 시

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install pandoc texlive-xetex texlive-fonts-extra
```

### macOS
```bash
brew install pandoc basictex
# LaTeX 패키지 업데이트
sudo tlmgr update --self
sudo tlmgr install xetex
```

### Mermaid 다이어그램 지원 (선택사항)
```bash
# Node.js 기반 Mermaid CLI
npm install -g @mermaid-js/mermaid-cli

# Python 기반 Pandoc 필터
pip install pandoc-mermaid-filter
```

## 🎯 강의 구성

이 자료는 **8시간 집중 강의**를 위해 설계되었습니다:

| 시간 | 내용 | 유형 | 비중 |
|------|------|------|------|
| 09:00-09:30 | 강의 소개 및 개요 | 이론 | 30분 |
| 09:30-10:30 | Yocto 기본 구조 및 아키텍처 | 이론 | 60분 |
| 10:45-11:30 | Yocto 빌드 환경 설정 | 실습 | 45분 |
| 11:30-12:30 | 첫 빌드: 코어 이미지 및 빌드 프로세스 | 실습+이론 | 60분 |
| 13:30-14:00 | 빌드된 이미지 실행하기 | 실습 | 30분 |
| 14:00-14:30 | 이미지 커스터마이징: 패키지 추가 | 실습 | 30분 |
| 14:45-16:00 | 커스텀 레이어 및 레시피 생성 | 실습 | 75분 |
| 16:00-16:30 | Yocto 고급 주제 개요 | 이론 | 30분 |
| 16:30-17:00 | 마무리 및 Q&A | 토론 | 30분 |

**총 구성 비율**: 이론 30% + 실습 60% + 토론 10%

## 🎨 포함된 다이어그램

강의 자료에는 **5개의 Mermaid 다이어그램**이 포함되어 있습니다:

1. **시스템 아키텍처**: Host → Docker → Yocto Container 구조
2. **빌드 프로세스**: BitBake → Recipe → Package → Image 흐름
3. **레이어 구조**: meta-* 레이어들의 계층 관계
4. **Docker 환경 설정**: 실습 가이드용 플로우
5. **강의 타임라인**: 8시간 일정 간트 차트

## 🔧 문제해결

### PDF 생성 실패 시
```bash
# 의존성 확인
pandoc --version
xelatex --version

# 권한 확인
chmod +x generate-pdf.sh

# 수동 실행
pandoc lecture-materials.md -o output.pdf --pdf-engine=xelatex
```

### 한글 폰트 문제 시
```bash
# 시스템 폰트 확인
fc-list :lang=ko

# Noto Sans CJK 설치 (Ubuntu)
sudo apt install fonts-noto-cjk

# 템플릿에서 폰트 변경
vi pandoc-template.yaml
# mainfont: "원하는 폰트명"으로 수정
```

## 📞 지원

문제가 발생하면 다음을 확인해주세요:

1. **의존성 설치 상태**
2. **파일 권한** (`chmod +x generate-pdf.sh`)
3. **한글 폰트 설치** 상태
4. **네트워크 연결** (LaTeX 패키지 다운로드용)

---

이 자료는 **KEA Yocto Project 강의**를 위해 제작되었습니다.  
Docker 기반 Yocto 5.0 LTS 환경에서 임베디드 리눅스 시스템 개발을 학습합니다. 🚀 