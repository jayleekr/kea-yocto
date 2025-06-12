# Yocto 강의 자료

강의용 Yocto 빌드 환경과 학습 자료를 제공합니다.

## 파일 구조

```
materials/
├── lecture-materials.md          # 강의 자료 (마크다운)
└── README.md                     # 이 파일
```

## 빠른 시작

### 1. 웹 서버로 실행

강의 자료를 웹 서버를 통해 확인하려면:

```bash
# mkdocs 설치
pip install mkdocs mkdocs-material

# 웹 서버 실행
cd ..
mkdocs serve
```

브라우저에서 http://127.0.0.1:8000 으로 접속하여 확인할 수 있습니다.

### 2. 강의 자료 읽기

강의 내용은 다음과 같습니다:

1. **Yocto 프로젝트 소개** - 개념과 구조 이해
2. **개발 환경 설정** - Docker 기반 빌드 환경
3. **첫 번째 빌드** - core-image-minimal 빌드
4. **이미지 커스터마이징** - 패키지 추가 및 설정
5. **커스텀 레이어 생성** - 자신만의 레이어 개발

## 강의 진행 방법

### 실습 진행

각 섹션별로 단계적 실습을 진행합니다:

1. 이론 설명 (15분)
2. 실습 진행 (30분)
3. 질문 및 문제해결 (15분)

### 학습 목표

- Yocto 프로젝트의 기본 개념 이해
- 커스텀 Linux 배포판 생성 능력
- 임베디드 시스템 개발 워크플로우 습득

## 문제 해결

### 일반적인 문제들

1. **빌드 오류**: 로그 파일 확인 및 의존성 문제 해결
2. **디스크 용량**: 최소 100GB 여유 공간 필요
3. **메모리 부족**: 최소 8GB RAM 권장

### 도움 받기

- 강사에게 질문
- 공식 Yocto 문서 참조
- 커뮤니티 포럼 활용

## 추가 리소스

- [Yocto Project 공식 사이트](https://www.yoctoproject.org/)
- [OpenEmbedded 레이어 인덱스](https://layers.openembedded.org/)
- [Bitbake 매뉴얼](https://docs.yoctoproject.org/bitbake/)

## 라이선스

이 자료는 교육 목적으로 제작되었습니다. 