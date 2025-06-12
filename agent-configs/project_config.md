# Project Configuration: Yocto 강의 프로젝트

## 프로젝트 개요

8시간 Yocto 강의를 위한 Docker 기반 환경과 자료를 제공하는 프로젝트입니다.

## 목표
- 임베디드 시스템 개발자들에게 Yocto 프로젝트 실무 지식 전달
- 실습 중심의 체계적인 학습 경험 제공
- Docker 기반 일관된 개발 환경 제공

## 기술 스택
- **컨테이너**: Docker, Docker Compose
- **빌드 시스템**: Yocto Project 5.0 LTS (Scarthgap)
- **가상화**: QEMU
- **문서화**: MkDocs, Markdown

## 현재 진행상황
- ✅ Docker 환경 설정 완료
- ✅ Yocto 5.0 LTS 빌드 환경 구축
- ✅ 강의 자료 작성 완료
- ✅ MkDocs 웹 서버 설정
- ✅ GitHub 배포 완료

## 주요 구성요소

### 1. Docker 환경
- **기본 이미지**: Ubuntu 24.04
- **Yocto 버전**: 5.0 LTS (Scarthgap)
- **타겟 아키텍처**: x86_64 (QEMU)

### 2. 강의 자료
- 833라인 마크다운 강의 자료
- 5개 섹션으로 구성된 체계적 커리큘럼
- 이론과 실습의 균형있는 구성

### 3. 실습 환경
- Docker 컨테이너 기반 격리된 환경
- 사전 설정된 Yocto 빌드 도구
- QEMU를 통한 이미지 테스트 환경

### 4. 성능 최적화
- ccache를 통한 빌드 속도 향상
- sstate-cache 공유를 통한 효율성 증대
- Docker 볼륨을 통한 데이터 지속성

## 사용자 대상
- 임베디드 시스템 개발자
- Linux 커널/드라이버 개발자
- 시스템 엔지니어
- DevOps 엔지니어

## 학습 성과
강의 완료 후 학습자는 다음을 할 수 있습니다:
- Yocto 기반 커스텀 Linux 배포판 생성
- BitBake 레시피 작성 및 수정
- 임베디드 시스템 개발 워크플로우 구축
- Docker 기반 개발 환경 활용

## 라이선스
이 프로젝트는 교육 목적으로 제작되었으며, 자유롭게 사용 및 수정 가능합니다.
