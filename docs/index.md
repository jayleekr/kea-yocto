# KEA Yocto Project 5.0 LTS 강의

<div align="center">
  <h2>🏗️ Yocto Project</h2>
  <p><em>Custom Linux Distribution Builder</em></p>
</div>

**강의명**: Yocto Project를 활용한 임베디드 리눅스 시스템 개발  
**대상**: 임베디드 시스템 개발자, 리눅스 시스템 엔지니어  
**시간**: 8시간 (휴식 포함)  
**환경**: Docker 기반 Yocto 5.0 LTS (Scarthgap)  

---

## 🎯 강의 목표

!!! info "학습 목표"
    이 강의를 통해 다음을 학습합니다:

    ✅ Yocto Project의 기본 개념과 아키텍처 이해  
    ✅ Docker 환경에서 Yocto 빌드 환경 구축  
    ✅ 커스텀 리눅스 이미지 생성 및 실행  
    ✅ 패키지 추가 및 이미지 커스터마이징  
    ✅ 커스텀 레이어와 레시피 작성  
    ✅ 실제 프로젝트 적용 가능한 실무 지식 습득  

## 📋 강의 목차

| 시간 | 내용 | 유형 | 비고 |
|------|------|------|------|
| 09:00-09:30 | [강의 소개 및 개요](lecture/intro.md) | 이론 | 30분 |
| 09:30-10:30 | [Yocto 기본 구조 및 아키텍처](lecture/architecture.md) | 이론 | 60분 |
| 10:45-11:30 | [Yocto 빌드 환경 설정](lecture/setup.md) | 실습 | 45분 |
| 11:30-12:30 | [첫 빌드: 코어 이미지 및 빌드 프로세스](lecture/first-build.md) | 실습+이론 | 60분 |
| 13:30-14:00 | [빌드된 이미지 실행하기](lecture/run-image.md) | 실습 | 30분 |
| 14:00-14:30 | [이미지 커스터마이징: 패키지 추가](lecture/customize.md) | 실습 | 30분 |
| 14:45-16:00 | [커스텀 레이어 및 레시피 생성](lecture/custom-layer.md) | 실습 | 75분 |
| 16:00-16:30 | [Yocto 고급 주제 개요](lecture/advanced.md) | 이론 | 30분 |
| 16:30-17:00 | [마무리 및 Q&A](lecture/conclusion.md) | 토론 | 30분 |

## 🚀 빠른 시작

!!! tip "실습 환경 준비"
    ```bash
    # 프로젝트 클론
    git clone https://github.com/jayleekr/kea-yocto.git
    cd kea-yocto
    
    # Docker 환경 시작
    ./scripts/quick-start.sh
    ```

## 📚 주요 특징

=== "🐋 Docker 기반"
    - 일관된 개발 환경 제공
    - 호스트 시스템 영향 최소화
    - 빠른 환경 구축

=== "⚡ 최적화된 빌드"
    - 웹 캐시 활용으로 빌드 시간 단축
    - 효율적인 리소스 사용
    - 병렬 빌드 지원

=== "🎓 실습 중심"
    - 단계별 실습 가이드
    - 실제 사용 사례 기반
    - 문제 해결 중심 학습

## 🔗 유용한 링크

- [Yocto Project 공식 문서](https://docs.yoctoproject.org/5.0/)
- [OpenEmbedded Layer Index](https://layers.openembedded.org/)
- [BitBake 사용자 매뉴얼](https://docs.yoctoproject.org/bitbake/)
- [Yocto Project Quick Build](https://docs.yoctoproject.org/brief-yoctoprojectqs/)

---

!!! warning "시스템 요구사항"
    - **CPU**: 4코어 이상
    - **RAM**: 8GB (권장 16GB)
    - **Storage**: 50GB 여유 공간
    - **Docker**: 20.10 이상 