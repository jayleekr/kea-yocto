# 📄 PDF 생성 가이드

이 문서는 Yocto 강의 자료를 PDF로 변환하는 여러 가지 방법을 안내합니다.

## 🎯 개요

MkDocs로 생성된 Yocto 강의 문서를 PDF 형태로 변환하여 오프라인에서도 학습할 수 있도록 도와드립니다.

## 🚀 빠른 시작 (권장)

### 방법 1: 수동 PDF 생성 (가장 안정적)

```bash
# 1. 로컬 서버 시작 및 브라우저 자동 열기
chmod +x scripts/generate-pdf-manual.sh
./scripts/generate-pdf-manual.sh
```

브라우저에서 각 페이지를 방문하여 `Cmd+P` (macOS) 또는 `Ctrl+P` (Windows/Linux)로 PDF 저장

### 방법 2: 자동 PDF 생성 (실험적)

```bash
# Node.js 의존성 설치
npm install

# 전체 PDF 생성 시도
node scripts/generate-pdf.js --base-url http://localhost:8000
```

> ⚠️ **주의**: macOS에서 Puppeteer WebSocket 연결 문제가 발생할 수 있습니다.

## 📋 상세 가이드

### 🔧 사전 준비

1. **MkDocs 사이트 빌드**
   ```bash
   # Python 가상환경 활성화
   source venv/bin/activate
   
   # 의존성 설치
   pip install -r requirements.txt
   
   # 사이트 빌드
   mkdocs build
   ```

2. **PDF 출력 디렉토리 생성**
   ```bash
   mkdir -p pdf-output
   ```

### 방법별 상세 안내

#### 📖 방법 1: 브라우저 수동 생성

**장점**: 가장 안정적, 모든 스타일 보존, 한국어 폰트 완벽 지원

**과정**:
1. 로컬 서버 시작: `./scripts/generate-pdf-manual.sh`
2. 브라우저에서 각 페이지 방문
3. 인쇄 설정:
   - 대상: PDF로 저장
   - 배경 그래픽: 체크
   - 여백: 최소
   - 용지 크기: A4

**생성할 PDF 목록**:
- `Yocto강의-홈페이지.pdf`
- `Yocto강의-강의소개.pdf`
- `Yocto강의-아키텍처.pdf`
- `Yocto강의-환경설정.pdf`
- `Yocto강의-첫빌드.pdf`
- `Yocto강의-이미지실행.pdf`
- `Yocto강의-커스터마이징.pdf`
- `Yocto강의-커스텀레이어.pdf`
- `Yocto강의-고급주제.pdf`
- `Yocto강의-마무리.pdf`

#### 🤖 방법 2: Puppeteer 자동 생성

**장점**: 완전 자동화, 일관된 품질

**단점**: macOS에서 WebSocket 연결 문제 발생 가능

```bash
# 의존성 설치
npm install

# 개별 강의 PDF 생성
node scripts/generate-pdf.js --chapters

# 전체 통합 PDF 생성
node scripts/generate-pdf.js --single

# 모든 PDF 생성
node scripts/generate-pdf.js
```

#### 🔄 방법 3: GitHub Actions 자동 배포

GitHub에 푸시하면 자동으로 PDF가 생성되어 GitHub Pages에 배포됩니다.

```yaml
# .github/workflows/docs-with-pdf.yml이 자동 실행
# 결과: https://your-username.github.io/yocto-lecture/downloads/
```

## 📊 방법별 비교

| 방법 | 안정성 | 자동화 | 품질 | 추천도 |
|------|---------|---------|------|--------|
| 브라우저 수동 | ⭐⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ | 🏆 **권장** |
| Puppeteer | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 🔧 환경따라 |
| GitHub Actions | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 🚀 배포용 |

## 🛠️ 문제 해결

### Puppeteer WebSocket 오류

```bash
Error: socket hang up
```

**해결책**:
1. 수동 생성 방법 사용: `./scripts/generate-pdf-manual.sh`
2. 다른 브라우저 엔진 시도
3. Docker 환경에서 실행

### 한국어 폰트 문제

**증상**: PDF에서 한국어가 깨져 보임

**해결책**:
1. 브라우저 인쇄 설정에서 "배경 그래픽" 체크
2. 시스템 한국어 폰트 설치 확인
3. CSS 폰트 설정 확인

### 스타일 손실 문제

**증상**: Material Design 스타일이 PDF에 반영되지 않음

**해결책**:
1. 인쇄 미리보기에서 확인 후 생성
2. "배경 그래픽" 옵션 활성화
3. CSS `@media print` 규칙 확인

## 📚 추가 자료

### PDF 품질 최적화 팁

1. **A4 용지 기준으로 최적화**
   - 여백: 20px
   - 폰트 크기: 적절한 크기 유지

2. **코드 블록 처리**
   - 긴 코드는 여러 페이지로 분할
   - 구문 강조 색상 유지

3. **이미지 및 다이어그램**
   - Mermaid 다이어그램 완전 렌더링 대기
   - 고해상도 이미지 사용

### 자동화 스크립트 커스터마이징

```javascript
// scripts/generate-pdf.js 수정 예시
const CONFIG = {
  pdfOptions: {
    format: 'A4',
    printBackground: true,
    margin: { top: '20px', bottom: '20px' }
  }
};
```

## 🎉 완료!

PDF 생성이 완료되면 `pdf-output/` 디렉토리에서 다음 파일들을 확인할 수 있습니다:

- 📄 개별 강의 PDF 파일들
- 📖 통합 전체 PDF (옵션)
- 📁 다운로드 페이지 (GitHub Pages 배포 시)

---

💡 **팁**: 처음 시도하는 경우 수동 생성 방법(`./scripts/generate-pdf-manual.sh`)을 권장합니다! 