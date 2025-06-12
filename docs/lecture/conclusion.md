# 마무리 및 Q&A

## 강의 요약

오늘 강의에서 다룬 내용:

✅ **Yocto Project 기본 개념** 이해  
✅ **Docker 기반 개발 환경** 구축  
✅ **첫 번째 리눅스 이미지** 빌드 및 실행  
✅ **패키지 추가 및 커스터마이징** 실습  
✅ **커스텀 레이어 및 레시피** 생성  
✅ **고급 주제** 개요 학습  

## 다음 단계 학습 방향

### 추천 학습 경로

1. **실제 하드웨어 타겟팅** (라즈베리파이, BeagleBone 등)
2. **BSP(Board Support Package) 개발**
3. **멀티미디어 및 그래픽 스택** 통합
4. **실시간 시스템** 구성
5. **보안 강화** 및 **업데이트 시스템** 구축

## 유용한 리소스

- 📚 [Yocto Project 공식 문서](https://docs.yoctoproject.org/)
- 🌐 [OpenEmbedded Layer Index](https://layers.openembedded.org/)
- 💬 [Yocto Project 메일링 리스트](https://lists.yoctoproject.org/)

## 자주 묻는 질문

!!! question "Q: 빌드 시간을 더 줄일 수 있는 방법은?"
    A: sstate-cache와 DL_DIR을 공유하고, BB_NUMBER_THREADS와 PARALLEL_MAKE를 시스템에 맞게 조정하세요.

!!! question "Q: 상용 제품에 Yocto를 적용할 때 주의사항은?"
    A: 라이선스 관리, 보안 업데이트 계획, 장기 지원(LTS) 버전 사용을 고려하세요.

---

← [고급 주제](advanced.md) | [홈](../index.md) → 